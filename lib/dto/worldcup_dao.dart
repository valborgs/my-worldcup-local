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
  Future<int> addWorldCup(WorldCupModel model) async {
    try{
      final db = await dbProvider.database;

      // 작성한 월드컵 데이터를 db에 저장한다.
      int idx = await db.insert(worldCupTable, model.toMap());

      return idx;
    }catch(e){
      rethrow;
    }
  }
  
  // db에 샘플 월드컵을 저장한다.
  Future<void> addSampleWorldCup() async {

    String rootDirectory = "assets/sample";
    
    List<WorldCupModel> newList = [
      WorldCupModel(-1, "여자 아이돌 월드컵", "최고의 여자 아이돌", DateTime(0), "${rootDirectory}/female/espa_carina.jpg", 16),
      WorldCupModel(-2, "남자 아이돌 월드컵", "최고의 남자 아이돌", DateTime(0), "${rootDirectory}/male/astro_cha.jpg", 16)
    ];
    
    List<WorldCupItemModel> itemList1 = [
      WorldCupItemModel(1, "${rootDirectory}/female/blackpink_jisoo.jpg", "블랙핑크 지수", -1),
      WorldCupItemModel(2, "${rootDirectory}/female/espa_carina.jpg", "에스파 카리나", -1),
      WorldCupItemModel(3, "${rootDirectory}/female/espa_jijel.jpg", "에스파 지젤", -1),
      WorldCupItemModel(4, "${rootDirectory}/female/espa_ningning.jpg", "에스파 닝닝", -1),
      WorldCupItemModel(5, "${rootDirectory}/female/espa_winter.jpg", "에스파 윈터", -1),
      WorldCupItemModel(6, "${rootDirectory}/female/ive_liz.jpg", "아이브 리즈", -1),
      WorldCupItemModel(7, "${rootDirectory}/female/ive_wonyoung.jpg", "아이브 장원영", -1),
      WorldCupItemModel(8, "${rootDirectory}/female/ive_yiseo.jpg", "아이브 이서", -1),
      WorldCupItemModel(9, "${rootDirectory}/female/newjeans_hani.jpg", "뉴진스 하니", -1),
      WorldCupItemModel(10, "${rootDirectory}/female/newjeans_helin.jpg", "뉴진스 해린", -1),
      WorldCupItemModel(11, "${rootDirectory}/female/newjeans_minji.jpg", "뉴진스 민지", -1),
      WorldCupItemModel(12, "${rootDirectory}/female/nmix_jiwoo.jpg", "엔믹스 지우", -1),
      WorldCupItemModel(13, "${rootDirectory}/female/nmix_yujin.jpg", "엔믹스 유진", -1),
      WorldCupItemModel(14, "${rootDirectory}/female/nmix_yun.jpg", "엔믹스 설윤", -1),
      WorldCupItemModel(15, "${rootDirectory}/female/suji.jpg", "미스에이 수지", -1),
      WorldCupItemModel(16, "${rootDirectory}/female/twice_sana.jpg", "트와이스 사나", -1),
    ];

    List<WorldCupItemModel> itemList2 = [
      WorldCupItemModel(1, "${rootDirectory}/male/astro_cha.jpg", "아스트로 차은우", -2),
      WorldCupItemModel(2, "${rootDirectory}/male/boys_juyeon.jpg", "더보이즈 주연", -2),
      WorldCupItemModel(3, "${rootDirectory}/male/btob_yuk.jpg", "비투비 육성재", -2),
      WorldCupItemModel(4, "${rootDirectory}/male/bts_jin.jpg", "BTS 진", -2),
      WorldCupItemModel(5, "${rootDirectory}/male/bts_jung.jpg", "BTS 정국", -2),
      WorldCupItemModel(6, "${rootDirectory}/male/bts_vi.jpg", "BTS 뷔", -2),
      WorldCupItemModel(7, "${rootDirectory}/male/daysix_pil.jpg", "데이식스 원필", -2),
      WorldCupItemModel(8, "${rootDirectory}/male/nct_jaehyun.jpg", "NCT 127 재현", -2),
      WorldCupItemModel(9, "${rootDirectory}/male/nct_jungwoo.jpg", "NCT 127 정우", -2),
      WorldCupItemModel(10, "${rootDirectory}/male/rise_bin.jpg", "라이즈 원빈", -2),
      WorldCupItemModel(11, "${rootDirectory}/male/rise_chan.jpg", "라이즈 성찬", -2),
      WorldCupItemModel(12, "${rootDirectory}/male/seventeen_minkyu.jpg", "세븐틴 민규", -2),
      WorldCupItemModel(13, "${rootDirectory}/male/seventeen_wonu.jpg", "세븐틴 원우", -2),
      WorldCupItemModel(14, "${rootDirectory}/male/tours_shiinyu.jpg", "투어즈 신유", -2),
      WorldCupItemModel(15, "${rootDirectory}/male/txt_yun.jpg", "TXT 연준", -2),
      WorldCupItemModel(16, "${rootDirectory}/male/zerobaseone_yujin.jpg", "제로베이스원 한유진", -2),
    ];
    
    try{
      final db = await dbProvider.database;

      // 작성한 월드컵 데이터를 db에 저장한다.
      for(int i=0; i<newList.length; i++){
        db.insert(worldCupTable, newList[i].toMap());
      }

      // 작성한 월드컵 아이템 데이터를 db에 저장한다.
      for(int i=0; i<itemList1.length; i++){
        db.insert(worldCupItemTable, itemList1[i].toMap());
        db.insert(worldCupItemTable, itemList2[i].toMap());
      }
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
      await db.insert(worldCupItemTable, model.toMap());
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

  // idx에 해당되는 월드컵 아이템을 DB에서 삭제한다.
  Future<void> deleteWorldCupItemByIdx(int idx) async {
    try{
      final db = await dbProvider.database;

      await db.delete(worldCupItemTable, where: "worldCupIdx = ?", whereArgs: [idx] );
    }catch(e){
      rethrow;
    }
  }

}