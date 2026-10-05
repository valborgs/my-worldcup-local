import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:worldcup_data/worldcup_data.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  late AppDatabase database;
  var image = 'original.jpg';

  Future<void> sync() => SampleWorldCupSeeder(
    database: database,
    manifestLoader: () async => jsonEncode({
      'worldCups': [
        for (final id in [-1, -2])
          {
            'idx': id,
            'title': 'sample $id',
            'info': '',
            'titleImage': image,
            'maxRound': 4,
            'items': [
              {'image': image, 'info': ''},
            ],
          },
      ],
    }),
  ).sync();

  Future<void> restart() async {
    await database.close();
    database = AppDatabase();
    await sync();
  }

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('sample_persistence_');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (_) async => directory.path,
        );
    database = AppDatabase();
    image = 'original.jpg';
  });

  tearDown(() async {
    await database.close();
    await directory.delete(recursive: true);
  });

  test(
    'deleted samples stay deleted after reopening, others refresh',
    () async {
      await sync();
      final db = await database.database;
      await db.insert(AppDatabase.worldCupTable, {'idx': 1, 'title': 'user'});
      await SqliteWorldCupRepository(database).delete(-1);
      image = 'updated.jpg';
      await restart();
      final reopened = await database.database;
      final rows = await reopened.query(
        AppDatabase.worldCupTable,
        orderBy: 'idx',
      );
      expect(rows.map((row) => row['idx']), [-2, 1]);
      expect(rows.first['titleImageSrc'], 'updated.jpg');
      expect(rows.last['title'], 'user');
      final items = await reopened.query(AppDatabase.worldCupItemTable);
      expect(items, hasLength(1));
      expect(items.single['worldCupIdx'], -2);
      expect(items.single['imagePath'], 'updated.jpg');
      await SqliteWorldCupRepository(database).delete(-2);
      await restart();
      expect(await SqliteWorldCupRepository(database).count(), 1);
    },
  );

  test('failed deletion rolls back the deletion record', () async {
    await sync();
    final db = await database.database;
    await db.execute(
      'CREATE TRIGGER fail_delete BEFORE DELETE ON worldcup_table '
      "BEGIN SELECT RAISE(ABORT, 'test failure'); END",
    );
    await expectLater(
      SqliteWorldCupRepository(database).delete(-1),
      throwsException,
    );
    expect(await db.query(AppDatabase.deletedSampleTable), isEmpty);
    expect(await db.query(AppDatabase.worldCupItemTable), hasLength(2));
    await db.execute('DROP TRIGGER fail_delete');
    await restart();
    expect(await SqliteWorldCupRepository(database).count(), 2);
  });

  test(
    'localized matches preserve count, paging, duplicates and deletion',
    () async {
      await sync();
      final repository = SqliteWorldCupRepository(database);
      final db = await database.database;
      await db.insert(AppDatabase.worldCupTable, {
        'idx': 1,
        'title': 'Idol user',
        'info': '',
        'date': 0,
        'titleImageSrc': '',
        'maxRound': 4,
      });
      expect(
        await repository.count(searchQuery: 'Idol', matchingIds: [-1, -2]),
        3,
      );
      expect(
        (await repository.page(
          limit: 2,
          offset: 0,
          searchQuery: 'Idol',
          matchingIds: [-1, -2],
        )).map((m) => m.idx),
        [1, -1],
      );
      expect(
        (await repository.page(
          limit: 2,
          offset: 2,
          searchQuery: 'Idol',
          matchingIds: [-1, -2],
        )).map((m) => m.idx),
        [-2],
      );
      expect(
        await repository.count(searchQuery: 'sample', matchingIds: [-1, -2]),
        2,
      );
      await repository.delete(-1);
      expect(
        await repository.count(searchQuery: 'Idol', matchingIds: [-1, -2]),
        2,
      );
      expect(
        (await repository.page(
          limit: 10,
          offset: 0,
          searchQuery: 'Idol',
          matchingIds: [-1, -2],
        )).map((m) => m.idx),
        [1, -2],
      );
      expect(
        await repository.count(searchQuery: "' OR 1=1 --", matchingIds: []),
        0,
      );
      expect(await repository.count(matchingIds: [-1]), 2);
    },
  );

  test(
    'debug paging deletions do not create sample deletion records',
    () async {
      await sync();
      await TestWorldCupSeeder(database).seed();
      final repository = SqliteWorldCupRepository(database);
      for (final id in [-1019, -1005, -1000]) {
        await repository.delete(id);
        expect(await repository.findById(id), isNull);
      }
      final db = await database.database;
      expect(await db.query(AppDatabase.deletedSampleTable), isEmpty);
      await repository.delete(-1);
      await restart();
      await TestWorldCupSeeder(database).seed();
      final restartedRepository = SqliteWorldCupRepository(database);
      expect(await restartedRepository.findById(-1), isNull);
      for (final id in [-1019, -1005, -1000]) {
        expect(await restartedRepository.findById(id), isNotNull);
      }
    },
  );

  test('fresh database restores samples after app data is removed', () async {
    await sync();
    await SqliteWorldCupRepository(database).delete(-1);
    await database.close();
    await databaseFactory.deleteDatabase(
      '${directory.path}/${AppDatabase.defaultFileName}',
    );
    database = AppDatabase();
    await sync();
    expect(await SqliteWorldCupRepository(database).count(), 2);
  });

  // 이슈 #44: Android 자동 백업은 재설치 때 DB를 통째로 복원하므로 삭제
  // 기록까지 따라온다. 백업되지 않는 설치 표식이 없으면 새 설치로 본다.
  group('reinstall with a restored backup', () {
    late Directory noBackup;

    Future<void> launch() async {
      await database.close();
      database = AppDatabase();
      await SampleWorldCupSeeder(
        database: database,
        manifestLoader: () async => jsonEncode({
          'worldCups': [
            for (final id in [-1, -2])
              {
                'idx': id,
                'title': 'sample $id',
                'info': '',
                'titleImage': image,
                'maxRound': 4,
                'items': [
                  {'image': image, 'info': ''},
                ],
              },
          ],
        }),
        noBackupDirectoryProvider: () async => noBackup,
      ).sync();
    }

    setUp(() => noBackup = Directory('${directory.path}/no_backup'));

    test('deleted samples stay deleted across restarts', () async {
      await launch();
      await SqliteWorldCupRepository(database).delete(-1);
      await launch();
      await launch();
      expect(await SqliteWorldCupRepository(database).findById(-1), isNull);
    });

    test('deleted samples come back, user data stays', () async {
      await launch();
      final db = await database.database;
      await db.insert(AppDatabase.worldCupTable, {'idx': 1, 'title': 'user'});
      await SqliteWorldCupRepository(database).delete(-2);
      await launch();

      // 재설치: DB 파일은 백업에서 돌아오고, 백업 제외 디렉터리는 비어 있다.
      await noBackup.delete(recursive: true);
      await launch();

      final restored = await database.database;
      final rows = await restored.query(
        AppDatabase.worldCupTable,
        orderBy: 'idx',
      );
      expect(rows.map((row) => row['idx']), [-2, -1, 1]);
      expect(await restored.query(AppDatabase.deletedSampleTable), isEmpty);

      // 복원 뒤의 삭제는 다시 평소처럼 유지된다.
      await SqliteWorldCupRepository(database).delete(-2);
      await launch();
      expect(await SqliteWorldCupRepository(database).findById(-2), isNull);
    });
  });

  test('v1 database upgrades without losing user data', () async {
    final legacy = await databaseFactory.openDatabase(
      '${directory.path}/${AppDatabase.defaultFileName}',
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, _) async {
          await db.execute(
            'CREATE TABLE worldcup_table ('
            'idx INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT, info TEXT, '
            'date INTEGER, titleImageSrc TEXT, maxRound INTEGER)',
          );
          await db.execute(
            'CREATE TABLE worldcup_item_table ('
            'idx INTEGER PRIMARY KEY AUTOINCREMENT, imagePath TEXT, '
            'imageInfo TEXT, worldCupIdx INTEGER)',
          );
          await db.insert(AppDatabase.worldCupTable, {
            'idx': 1,
            'title': 'user',
          });
        },
      ),
    );
    await legacy.close();
    await sync();
    await SqliteWorldCupRepository(database).delete(-1);
    await restart();
    final db = await database.database;
    expect(await db.getVersion(), 2);
    expect(await SqliteWorldCupRepository(database).count(), 2);
    expect(await db.query(AppDatabase.deletedSampleTable), [
      {'idx': -1},
    ]);
  });
}
