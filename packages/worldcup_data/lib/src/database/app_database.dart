import 'dart:async';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

/// SQLite 연결을 소유한다.
///
/// 예전 `SqliteProvider`는 전역 싱글톤이었다. 지금은 평범한 객체이고,
/// 앱 전체에서 하나만 쓰이도록 보장하는 일은 DI(Riverpod)가 맡는다.
/// 덕분에 테스트에서 [databaseFactoryOverride]로 인메모리 DB를 끼울 수 있다.
class AppDatabase {
  static const String defaultFileName = 'myworldcup.db';
  static const int schemaVersion = 1;

  static const String worldCupTable = 'worldcup_table';
  static const String worldCupItemTable = 'worldcup_item_table';

  final String fileName;

  /// 테스트에서 열기 동작을 갈아끼우기 위한 훅.
  final Future<Database> Function(String path)? databaseFactoryOverride;

  Future<Database>? _opening;

  AppDatabase({this.fileName = defaultFileName, this.databaseFactoryOverride});

  /// 열린 연결. 동시에 여러 번 호출해도 한 번만 연다.
  Future<Database> get database => _opening ??= _open();

  Future<Database> _open() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = p.join(directory.path, fileName);
    final override = databaseFactoryOverride;
    if (override != null) return override(path);

    return openDatabase(
      path,
      version: schemaVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> close() async {
    final opening = _opening;
    _opening = null;
    if (opening != null) await (await opening).close();
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute(
      'CREATE TABLE $worldCupTable ('
      'idx INTEGER PRIMARY KEY AUTOINCREMENT, '
      'title TEXT, '
      'info TEXT, '
      'date INTEGER, '
      'titleImageSrc TEXT, '
      'maxRound INTEGER '
      ')',
    );

    await db.execute(
      'CREATE TABLE $worldCupItemTable ('
      'idx INTEGER PRIMARY KEY AUTOINCREMENT, '
      'imagePath TEXT, '
      'imageInfo TEXT, '
      'worldCupIdx INTEGER'
      ')',
    );
  }

  static Future<void> _onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (newVersion > oldVersion) {
      // TODO(schema): 스키마를 바꿀 때 여기에 마이그레이션을 추가한다.
    }
  }
}
