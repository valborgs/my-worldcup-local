import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:worldcup_data/worldcup_data.dart';
import 'package:worldcup_domain/worldcup_domain.dart';

/// 월드컵을 지우거나 항목을 바꾸면 더는 쓰이지 않는 사진 파일도 지운다.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory root;
  late Directory appStorage;
  late Directory outside;
  late AppDatabase database;
  late SqliteWorldCupRepository repository;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    root = await Directory.systemTemp.createTemp('worldcup_cleanup_');
    appStorage = await Directory(path.join(root.path, 'app')).create();
    outside = await Directory(path.join(root.path, 'outside')).create();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (_) async => root.path,
        );
    database = AppDatabase(fileName: 'test.db');
    repository = SqliteWorldCupRepository(
      database,
      ownedImageDirectories: () async => [appStorage],
    );
  });

  tearDown(() async {
    await database.close();
    await root.delete(recursive: true);
  });

  Future<String> photo(Directory directory, String name) async {
    final file = File(path.join(directory.path, name));
    await file.writeAsBytes([1, 2, 3], flush: true);
    return file.path;
  }

  Future<int> addWorldCup(List<String> paths) => repository.add(
    WorldCupModel(0, '제목', '설명', DateTime(2026), paths.first, paths.length),
    [for (final p in paths) WorldCupItemModel(0, p, 'info', 0)],
  );

  test('월드컵을 지우면 앱 저장공간의 사진 파일도 지운다', () async {
    final paths = [
      for (var i = 0; i < 4; i++) await photo(appStorage, 'p$i.jpg'),
    ];
    final idx = await addWorldCup(paths);

    await repository.delete(idx);

    for (final p in paths) {
      expect(File(p).existsSync(), isFalse, reason: p);
    }
  });

  test('앱 저장공간 밖의 파일과 에셋 경로는 건드리지 않는다', () async {
    final external = await photo(outside, 'user_file.jpg');
    final idx = await addWorldCup([
      external,
      'assets/sample/female/chu.jpg',
      await photo(appStorage, 'a.jpg'),
      await photo(appStorage, 'b.jpg'),
    ]);

    await repository.delete(idx);

    expect(File(external).existsSync(), isTrue);
  });

  test('다른 월드컵이 같은 파일을 쓰고 있으면 지우지 않는다', () async {
    final shared = await photo(appStorage, 'shared.jpg');
    final first = await addWorldCup([
      shared,
      await photo(appStorage, 'a.jpg'),
      await photo(appStorage, 'b.jpg'),
      await photo(appStorage, 'c.jpg'),
    ]);
    await addWorldCup([
      shared,
      await photo(appStorage, 'd.jpg'),
      await photo(appStorage, 'e.jpg'),
      await photo(appStorage, 'f.jpg'),
    ]);

    await repository.delete(first);

    expect(File(shared).existsSync(), isTrue);
  });

  test('수정하면서 빠진 사진만 지우고 남은 사진은 유지한다', () async {
    final kept = await photo(appStorage, 'kept.jpg');
    final removed = await photo(appStorage, 'removed.jpg');
    final replacement = await photo(appStorage, 'new.jpg');
    final others = [
      await photo(appStorage, 'a.jpg'),
      await photo(appStorage, 'b.jpg'),
    ];
    final idx = await addWorldCup([kept, removed, ...others]);

    await repository.update(
      WorldCupModel(idx, '제목', '설명', DateTime(2026), kept, 4),
      [
        for (final p in [kept, replacement, ...others])
          WorldCupItemModel(0, p, 'info', idx),
      ],
    );

    expect(File(removed).existsSync(), isFalse);
    expect(File(kept).existsSync(), isTrue);
    expect(File(replacement).existsSync(), isTrue);
    for (final p in others) {
      expect(File(p).existsSync(), isTrue);
    }
  });

  test('파일을 지우지 못해도 월드컵 삭제는 성공한다', () async {
    final failing = SqliteWorldCupRepository(
      database,
      ownedImageDirectories: () async => throw StateError('no storage'),
    );
    final idx = await addWorldCup([
      for (var i = 0; i < 4; i++) await photo(appStorage, 'p$i.jpg'),
    ]);

    await failing.delete(idx);

    expect(await failing.findById(idx), isNull);
  });
}
