import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_worldcup_local/dto/worldcup_dao.dart';
import 'package:my_worldcup_local/models/worldcup_item_model.dart';
import 'package:my_worldcup_local/models/worldcup_model.dart';
import 'package:my_worldcup_local/services/worldcup_package_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('월드컵 정보와 이미지를 패키지로 내보낸 뒤 새 월드컵으로 복원한다', () async {
    final testDirectory =
        await Directory.systemTemp.createTemp('my_worldcup_package_test_');
    addTearDown(() async {
      if (await testDirectory.exists()) {
        await testDirectory.delete(recursive: true);
      }
    });

    final sourceItems = <WorldCupItemModel>[
      WorldCupItemModel(
        1,
        'assets/sample/female/aespa_carina.jpg',
        '카리나',
        10,
      ),
      WorldCupItemModel(
        2,
        'assets/sample/female/babymon_ahyun.jpg',
        '아현',
        10,
      ),
      WorldCupItemModel(
        3,
        'assets/sample/female/chu.jpg',
        '츄',
        10,
      ),
      WorldCupItemModel(
        4,
        'assets/sample/female/idle_miyeon.jpg',
        '미연',
        10,
      ),
    ];
    final sourceModel = WorldCupModel(
      10,
      '공유 테스트',
      '설명',
      DateTime(2026, 9, 3, 12, 34, 56),
      sourceItems[1].imagePath,
      sourceItems.length,
    );
    final dao = _FakeWorldCupDao(sourceItems);
    final service = WorldCupPackageService(
      dao: dao,
      temporaryDirectoryProvider: () async => testDirectory,
      documentsDirectoryProvider: () async => testDirectory,
    );

    final packageFile = await service.createPackage(sourceModel);
    final imported = await service.importPackage(packageFile.path);

    expect(packageFile.path, endsWith('.myworldcup'));
    expect(await packageFile.length(), greaterThan(0));
    expect(imported.idx, 77);
    expect(imported.title, sourceModel.title);
    expect(dao.addedModel.title, sourceModel.title);
    expect(dao.addedModel.info, sourceModel.info);
    expect(dao.addedModel.date, sourceModel.date);
    expect(dao.addedModel.maxRound, sourceItems.length);
    expect(dao.addedItems.map((item) => item.imageInfo),
        sourceItems.map((item) => item.imageInfo));
    expect(
      dao.addedModel.titleImageSrc,
      dao.addedItems[1].imagePath,
      reason: '대표 이미지의 항목 위치도 함께 복원되어야 한다.',
    );
    for (final item in dao.addedItems) {
      expect(await File(item.imagePath).exists(), isTrue);
      expect(await File(item.imagePath).length(), greaterThan(0));
    }
  });

  test('manifest의 maxRound가 항목 수와 다르면 가져오기를 거부한다', () async {
    final testDirectory =
        await Directory.systemTemp.createTemp('my_worldcup_manifest_test_');
    addTearDown(() async {
      if (await testDirectory.exists()) {
        await testDirectory.delete(recursive: true);
      }
    });
    final service = _importService(testDirectory);
    final package = await _writePackage(
      testDirectory,
      images: const [
        'images/0000.jpg',
        'images/0001.jpg',
        'images/0002.jpg',
        'images/0003.jpg',
      ],
      maxRound: 8,
    );

    await expectLater(
      service.importPackage(package.path),
      throwsA(
        isA<WorldCupPackageException>().having(
          (error) => error.message,
          'message',
          '월드컵 정보가 손상되었습니다.',
        ),
      ),
    );
  });

  test('여러 항목이 같은 이미지 archive 경로를 참조하면 명시적으로 거부한다', () async {
    final testDirectory =
        await Directory.systemTemp.createTemp('my_worldcup_duplicate_test_');
    addTearDown(() async {
      if (await testDirectory.exists()) {
        await testDirectory.delete(recursive: true);
      }
    });
    final service = _importService(testDirectory);
    final package = await _writePackage(
      testDirectory,
      images: const [
        'images/shared.jpg',
        'images/shared.jpg',
        'images/0002.jpg',
        'images/0003.jpg',
      ],
      maxRound: 4,
    );

    await expectLater(
      service.importPackage(package.path),
      throwsA(
        isA<WorldCupPackageException>().having(
          (error) => error.message,
          'message',
          '중복된 이미지 리소스 경로가 포함되었습니다.',
        ),
      ),
    );
  });
}

WorldCupPackageService _importService(Directory directory) {
  return WorldCupPackageService(
    dao: _FakeWorldCupDao(const []),
    temporaryDirectoryProvider: () async => directory,
    documentsDirectoryProvider: () async => directory,
  );
}

Future<File> _writePackage(
  Directory directory, {
  required List<String> images,
  required int maxRound,
}) async {
  final manifest = <String, Object>{
    'format': 'my-worldcup',
    'version': 1,
    'title': '검증 테스트',
    'info': '',
    'createdAt': DateTime(2026).toIso8601String(),
    'maxRound': maxRound,
    'titleImageIndex': 0,
    'items': [
      for (final image in images) <String, String>{'image': image, 'info': ''},
    ],
  };
  final archive = Archive()
    ..addFile(ArchiveFile.string('manifest.json', jsonEncode(manifest)));
  for (final image in images.toSet()) {
    archive.addFile(ArchiveFile.string(image, 'image'));
  }
  final encoded = ZipEncoder().encode(archive);
  final package = File(
    '${directory.path}/validation_${DateTime.now().microsecondsSinceEpoch}.myworldcup',
  );
  await package.writeAsBytes(encoded, flush: true);
  return package;
}

class _FakeWorldCupDao extends WorldCupDao {
  final List<WorldCupItemModel> sourceItems;
  late WorldCupModel addedModel;
  late List<WorldCupItemModel> addedItems;

  _FakeWorldCupDao(this.sourceItems);

  @override
  Future<List<WorldCupItemModel>> getWorldCupItemList(int worldCupIdx) async {
    return sourceItems;
  }

  @override
  Future<int> addWorldCupWithItems(
    WorldCupModel model,
    List<WorldCupItemModel> items,
  ) async {
    addedModel = model;
    addedItems = items;
    return 77;
  }
}
