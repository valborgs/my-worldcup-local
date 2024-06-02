import 'dart:io';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

class SqliteProvider{
  static final SqliteProvider _provider = SqliteProvider._();
  static Database? _database;

  SqliteProvider._();

  factory SqliteProvider() => _provider;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await createDatabase();
    return _database!;
  }

  createDatabase() async {
    Directory docsDir = await getApplicationDocumentsDirectory();
    String path = join(docsDir.path, "myworldcup.db");

    var database = await openDatabase(path, version: 1, onCreate: initDB, onUpgrade: onUpgrade);
    return database;
  }

  void onUpgrade(Database database, int oldVersion, int newVersion) {
    if (newVersion > oldVersion) {
      // TODO :: Migration
    }
  }

  initDB(Database database, int version) async {
    await database.execute("CREATE TABLE worldcup_table ("
        "idx INTEGER PRIMARY KEY, "
        "title TEXT, "
        "info TEXT, "
        "date INTEGER, "
        "titleImageSrc TEXT, "
        "maxRound INTEGER "
        ")");

    await database.execute("CREATE TABLE worldcup_item_table ("
        "idx INTEGER PRIMARY KEY, "
        "imagePath TEXT, "
        "imageInfo TEXT, "
        "worldCupIdx INTEGER"
        ")");
  }


}