import 'package:my_worldcup_local/models/worldcup_item_model.dart';
import 'package:my_worldcup_local/models/worldcup_model.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite/sqflite.dart';

import '../db/sqlite.dart';

class WorldCupDao{

  final dbProvider = SqliteProvider();
  final worldCupTable = 'worldcup_table';
  final worldCupItemTable = 'worldcup_item_table';

  // db에 저장된 월드컵 전체 리스트를 불러온다.
  Future<List<WorldCupModel>> getWorldCupList() async {

    List<WorldCupModel> modelList = [];

    try{
      final db = await dbProvider.database;

      List<Map<String, dynamic>> dbList = await db.query(worldCupTable);

      if(dbList.isNotEmpty){
        for(Map<String, dynamic> item in dbList){
          modelList.add(WorldCupModel.fromDB(item));
        }
      }
    }catch(e){
      rethrow;
    }

    return modelList;
  }

  // db에 월드컵을 저장한다.
  Future<void> addWorldCup(WorldCupModel model) async {
    try{
      final db = await dbProvider.database;

      // 작성한 월드컵 데이터를 db에 저장한다.
      await db.insert(worldCupTable, model.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    }catch(e){
      rethrow;
    }

  }

  // 월드컵 idx에 해당되는 아이템을 전부 불러온다.
  Future<List<WorldCupItemModel>> getWorldCupItemList(int worldCupIdx) async {

    List<WorldCupItemModel> itemList = [];

    try{
      final db = await dbProvider.database;

      List<Map<String, dynamic>> dbList =
      await db.query(
          worldCupItemTable,
          where: "worldCupIdx = ?",
          whereArgs: [worldCupIdx]
      );

      if(dbList.isNotEmpty){
        for(Map<String, dynamic> item in dbList){
          itemList.add(WorldCupItemModel.fromDB(item));
        }
      }
    }catch(e){
      rethrow;
    }

    return itemList;
  }

  // db에 월드컵 아이템을 저장한다.
  Future<void> addWorldCupItem(WorldCupItemModel model) async {
    try{
      final db = await dbProvider.database;

      // 작성한 월드컵 데이터를 db에 저장한다.
      await db.insert(worldCupItemTable, model.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    }catch(e){
      rethrow;
    }
  }

  // idx에 해당되는 월드컵을 DB에서 삭제한다.
  Future<void> deleteWorldCupByIdx(int idx) async {
    try{
      final db = await dbProvider.database;

      await db.delete(worldCupTable, where: "idx = ?", whereArgs: [idx] );
    }catch(e){
      rethrow;
    }
  }

}