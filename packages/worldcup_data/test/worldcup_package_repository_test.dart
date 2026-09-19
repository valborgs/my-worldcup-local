import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive_io.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worldcup_domain/worldcup_domain.dart';
import 'package:worldcup_data/worldcup_data.dart';
import 'package:worldcup_core/worldcup_core.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('월드컵 정보와 이미지를 패키지로 내보낸 뒤 새 월드컵으로 복원한다', () async {
    final testDirectory = await Directory.systemTemp.createTemp(
      'my_worldcup_package_test_',
    );
    addTearDown(() async {
      if (await testDirectory.exists()) {
        await testDirectory.delete(recursive: true);
      }
    });

    final sourceItems = <WorldCupItemModel>[
      const WorldCupItemModel(
        1,
        'assets/sample/female/aespa_carina.jpg',
        '카리나',
        10,
      ),
      const WorldCupItemModel(
        2,
        'assets/sample/female/babymon_ahyun.jpg',
        '아현',
        10,
      ),
      const WorldCupItemModel(3, 'assets/sample/female/chu.jpg', '츄', 10),
      const WorldCupItemModel(
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
    final service = WorldCupPackageRepository(
      repository: dao,
      temporaryDirectoryProvider: () async => testDirectory,
      documentsDirectoryProvider: () async => testDirectory,
    );

    final packagePath = await service.createPackage(sourceModel);
    final imported = await service.importPackage(packagePath);

    expect(packagePath, endsWith('.myworldcup'));
    expect(await File(packagePath).length(), greaterThan(0));
    expect(imported.idx, 77);
    expect(imported.title, sourceModel.title);
    expect(dao.addedModel.title, sourceModel.title);
    expect(dao.addedModel.info, sourceModel.info);
    expect(dao.addedModel.date, sourceModel.date);
    expect(dao.addedModel.maxRound, sourceItems.length);
    expect(
      dao.addedItems.map((item) => item.imageInfo),
      sourceItems.map((item) => item.imageInfo),
    );
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
    final testDirectory = await Directory.systemTemp.createTemp(
      'my_worldcup_manifest_test_',
    );
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
        isA<PackageFailure>().having(
          (error) => error.message,
          'message',
          '월드컵 정보가 손상되었습니다.',
        ),
      ),
    );
  });

  test('여러 항목이 같은 이미지 archive 경로를 참조하면 명시적으로 거부한다', () async {
    final testDirectory = await Directory.systemTemp.createTemp(
      'my_worldcup_duplicate_test_',
    );
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
        isA<PackageFailure>().having(
          (error) => error.message,
          'message',
          '중복된 이미지 리소스 경로가 포함되었습니다.',
        ),
      ),
    );
  });

  test('헤더에 적힌 크기보다 크게 풀리는 이미지 항목은 거부한다', () async {
    final testDirectory = await Directory.systemTemp.createTemp(
      'my_worldcup_zip_bomb_test_',
    );
    addTearDown(() async {
      if (await testDirectory.exists()) {
        await testDirectory.delete(recursive: true);
      }
    });
    final service = _importService(testDirectory);
    // 압축하면 수십 KB지만 풀면 20MB가 되는 항목의 크기 필드를 1KB로 속인다.
    final bomb = Uint8List(20 * 1024 * 1024)..setAll(0, _pngSignature);
    final package = await _writePackage(
      testDirectory,
      images: const [
        'images/0000.png',
        'images/0001.png',
        'images/0002.png',
        'images/0003.png',
      ],
      maxRound: 4,
      imageBytes: {'images/0000.png': bomb},
      declaredSizes: {'images/0000.png': 1024},
    );

    await expectLater(
      service.importPackage(package.path),
      throwsA(isA<PackageFailure>()),
    );
    expect(
      await _importedImageCount(testDirectory),
      0,
      reason: '거부된 패키지의 이미지가 남아 있으면 안 된다.',
    );
  });

  test('이미지 형식이 아닌 리소스는 거부한다', () async {
    final testDirectory = await Directory.systemTemp.createTemp(
      'my_worldcup_signature_test_',
    );
    addTearDown(() async {
      if (await testDirectory.exists()) {
        await testDirectory.delete(recursive: true);
      }
    });
    final service = _importService(testDirectory);
    final package = await _writePackage(
      testDirectory,
      images: const [
        'images/0000.png',
        'images/0001.png',
        'images/0002.png',
        'images/0003.png',
      ],
      maxRound: 4,
      imageBytes: {
        'images/0002.png': Uint8List.fromList(utf8.encode('<html></html>')),
      },
    );

    await expectLater(
      service.importPackage(package.path),
      throwsA(
        isA<PackageFailure>().having(
          (error) => error.userMessage.id,
          'userMessage',
          AppMessageId.packageImageDamaged,
        ),
      ),
    );
  });

  test('암호화된 항목이 있는 패키지는 거부한다', () async {
    final testDirectory = await Directory.systemTemp.createTemp(
      'my_worldcup_encrypted_test_',
    );
    addTearDown(() async {
      if (await testDirectory.exists()) {
        await testDirectory.delete(recursive: true);
      }
    });
    final service = _importService(testDirectory);
    final package = await _writePackage(
      testDirectory,
      images: const [
        'images/0000.png',
        'images/0001.png',
        'images/0002.png',
        'images/0003.png',
      ],
      maxRound: 4,
      password: 'secret',
    );

    await expectLater(
      service.importPackage(package.path),
      throwsA(isA<PackageFailure>()),
    );
  });

  test('올바른 PNG 리소스만 있는 패키지는 가져온다', () async {
    final testDirectory = await Directory.systemTemp.createTemp(
      'my_worldcup_valid_png_test_',
    );
    addTearDown(() async {
      if (await testDirectory.exists()) {
        await testDirectory.delete(recursive: true);
      }
    });
    final dao = _FakeWorldCupDao(const []);
    final service = WorldCupPackageRepository(
      repository: dao,
      temporaryDirectoryProvider: () async => testDirectory,
      documentsDirectoryProvider: () async => testDirectory,
    );
    final package = await _writePackage(
      testDirectory,
      images: const [
        'images/0000.png',
        'images/0001.png',
        'images/0002.png',
        'images/0003.png',
      ],
      maxRound: 4,
    );

    final imported = await service.importPackage(package.path);

    expect(imported.idx, 77);
    for (final item in dao.addedItems) {
      final bytes = await File(item.imagePath).readAsBytes();
      expect(bytes.take(_pngSignature.length), _pngSignature);
    }
  });
}

const List<int> _pngSignature = [
  0x89,
  0x50,
  0x4E,
  0x47,
  0x0D,
  0x0A,
  0x1A,
  0x0A,
];

Future<int> _importedImageCount(Directory directory) async {
  final importRoot = Directory('${directory.path}/imported_worldcups');
  if (!await importRoot.exists()) return 0;
  return importRoot.list(recursive: true).where((e) => e is File).length;
}

/// ZIP 로컬 헤더와 중앙 디렉터리에 기록된 [name] 항목의 해제 크기를 바꾼다.
Uint8List _overrideDeclaredSize(Uint8List zip, String name, int size) {
  final data = ByteData.sublistView(zip);
  final nameBytes = utf8.encode(name);
  bool nameAt(int offset) {
    if (offset + nameBytes.length > zip.length) return false;
    for (var i = 0; i < nameBytes.length; i++) {
      if (zip[offset + i] != nameBytes[i]) return false;
    }
    return true;
  }

  var patched = 0;
  for (var offset = 0; offset + 46 <= zip.length; offset++) {
    final signature = data.getUint32(offset, Endian.little);
    if (signature == 0x04034b50 &&
        data.getUint16(offset + 26, Endian.little) == nameBytes.length &&
        nameAt(offset + 30)) {
      data.setUint32(offset + 22, size, Endian.little);
      patched++;
    } else if (signature == 0x02014b50 &&
        data.getUint16(offset + 28, Endian.little) == nameBytes.length &&
        nameAt(offset + 46)) {
      data.setUint32(offset + 24, size, Endian.little);
      patched++;
    }
  }
  if (patched != 2) throw StateError('ZIP 헤더를 찾지 못했습니다: $name');
  return zip;
}

WorldCupPackageRepository _importService(Directory directory) {
  return WorldCupPackageRepository(
    repository: _FakeWorldCupDao(const []),
    temporaryDirectoryProvider: () async => directory,
    documentsDirectoryProvider: () async => directory,
  );
}

Future<File> _writePackage(
  Directory directory, {
  required List<String> images,
  required int maxRound,
  Map<String, Uint8List> imageBytes = const {},
  Map<String, int> declaredSizes = const {},
  String? password,
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
    archive.addFile(
      ArchiveFile.bytes(
        image,
        imageBytes[image] ?? Uint8List.fromList([..._pngSignature, 0, 0]),
      ),
    );
  }
  var encoded = ZipEncoder(password: password).encodeBytes(archive);
  for (final entry in declaredSizes.entries) {
    encoded = _overrideDeclaredSize(encoded, entry.key, entry.value);
  }
  final package = File(
    '${directory.path}/validation_${DateTime.now().microsecondsSinceEpoch}.myworldcup',
  );
  await package.writeAsBytes(encoded, flush: true);
  return package;
}

class _FakeWorldCupDao implements WorldCupRepository {
  final List<WorldCupItemModel> sourceItems;
  late WorldCupModel addedModel;
  late List<WorldCupItemModel> addedItems;

  _FakeWorldCupDao(this.sourceItems);

  @override
  Future<List<WorldCupItemModel>> items(int worldCupIdx) async {
    return sourceItems;
  }

  @override
  Future<int> add(WorldCupModel model, List<WorldCupItemModel> items) async {
    addedModel = model;
    addedItems = items;
    return 77;
  }

  // 패키지 테스트에서 쓰지 않는 나머지 멤버.
  @override
  Future<int> count({
    String searchQuery = '',
    List<int> matchingIds = const [],
  }) => throw UnimplementedError();

  @override
  Future<WorldCupModel?> findById(int idx) => throw UnimplementedError();

  @override
  Future<int> indexOf(int idx) => throw UnimplementedError();

  @override
  Future<List<WorldCupModel>> page({
    required int limit,
    required int offset,
    String searchQuery = '',
    List<int> matchingIds = const [],
  }) => throw UnimplementedError();

  @override
  Future<void> update(WorldCupModel model, List<WorldCupItemModel> items) =>
      throw UnimplementedError();

  @override
  Future<void> delete(int idx) => throw UnimplementedError();
}
