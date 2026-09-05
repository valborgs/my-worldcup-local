import 'package:worldcup_domain/worldcup_domain.dart';

import '../db/sqlite.dart';
import 'worldcup_row.dart';

class WorldCupDao {
  final dbProvider = SqliteProvider();
  final worldCupTable = 'worldcup_table';
  final worldCupItemTable = 'worldcup_item_table';

  // db에 저장된 월드컵 전체 리스트를 불러온다.
  Future<List<WorldCupModel>> getWorldCupList() async {
    List<WorldCupModel> modelList = [];

    try {
      final db = await dbProvider.database;

      List<Map<String, dynamic>> dbList = await db.query(worldCupTable);

      if (dbList.isNotEmpty) {
        for (Map<String, dynamic> item in dbList) {
          modelList.add(worldCupFromRow(item));
        }
      }
    } catch (e) {
      rethrow;
    }

    return modelList;
  }

  Future<int> getWorldCupCount({String searchQuery = ''}) async {
    final db = await dbProvider.database;
    final query = searchQuery.trim();
    final whereClause = query.isEmpty ? '' : ' WHERE title LIKE ? OR info LIKE ?';
    final whereArgs = query.isEmpty ? <Object?>[] : ['%$query%', '%$query%'];
    final result = await db.rawQuery(
      'SELECT COUNT(*) AS count FROM $worldCupTable$whereClause',
      whereArgs,
    );
    return (result.first['count'] as num?)?.toInt() ?? 0;
  }

  Future<int> getWorldCupIndex(int idx) async {
    final db = await dbProvider.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) AS itemIndex FROM $worldCupTable WHERE idx < ?',
      [idx],
    );
    return (result.first['itemIndex'] as num?)?.toInt() ?? 0;
  }

  Future<List<WorldCupModel>> getWorldCupPage({
    required int limit,
    required int offset,
    String searchQuery = '',
  }) async {
    final db = await dbProvider.database;
    final query = searchQuery.trim();
    final dbList = await db.query(
      worldCupTable,
      where: query.isEmpty ? null : 'title LIKE ? OR info LIKE ?',
      whereArgs: query.isEmpty ? null : ['%$query%', '%$query%'],
      orderBy: 'idx ASC',
      limit: limit,
      offset: offset,
    );
    return dbList.map(worldCupFromRow).toList();
  }

  Future<int> addWorldCupWithItems(
    WorldCupModel model,
    List<WorldCupItemModel> items,
  ) async {
    final db = await dbProvider.database;
    return db.transaction((txn) async {
      final worldCupIdx = await txn.insert(worldCupTable, model.toRow());
      final batch = txn.batch();
      for (final item in items) {
        final itemMap = item.toRow()..['worldCupIdx'] = worldCupIdx;
        batch.insert(worldCupItemTable, itemMap);
      }
      await batch.commit(noResult: true);
      return worldCupIdx;
    });
  }

  Future<void> updateWorldCupWithItems(
    WorldCupModel model,
    List<WorldCupItemModel> items,
  ) async {
    final db = await dbProvider.database;
    await db.transaction((txn) async {
      await txn.update(
        worldCupTable,
        model.toRow(),
        where: 'idx = ?',
        whereArgs: [model.idx],
      );
      await txn.delete(
        worldCupItemTable,
        where: 'worldCupIdx = ?',
        whereArgs: [model.idx],
      );
      final batch = txn.batch();
      for (final item in items) {
        batch.insert(worldCupItemTable, item.toRow());
      }
      await batch.commit(noResult: true);
    });
  }

  // 앱 시작 시마다 샘플 월드컵 데이터를 최신 상태로 동기화한다.
  // 기존 샘플 데이터(idx -1, -2)를 지우고 다시 넣어서,
  // 샘플 이미지 에셋이 교체/리네임되어도 로컬 db에 남아있던 예전 경로를 참조하지 않도록 한다.
  Future<void> syncSampleWorldCup() async {
    String rootDirectory = "assets/sample";

    List<WorldCupModel> newList = [
      WorldCupModel(-1, "여자 아이돌 월드컵", "최고의 여자 아이돌", DateTime(0),
          "$rootDirectory/female/aespa_carina.jpg", 16),
      WorldCupModel(-2, "남자 아이돌 월드컵", "최고의 남자 아이돌", DateTime(0),
          "$rootDirectory/male/astro_cha.jpg", 16)
    ];

    List<WorldCupItemModel> itemList1 = [
      WorldCupItemModel(
          1, "$rootDirectory/female/aespa_carina.jpg", "에스파 카리나", -1),
      WorldCupItemModel(
          2, "$rootDirectory/female/hearts2_ian.jpg", "하츠투하츠 이안", -1),
      WorldCupItemModel(3, "$rootDirectory/female/nmix_sul.jpg", "엔믹스 설윤", -1),
      WorldCupItemModel(4, "$rootDirectory/female/ive_jang.jpg", "아이브 장원영", -1),
      WorldCupItemModel(
          5, "$rootDirectory/female/babymon_ahyun.jpg", "베이비몬스터 아현", -1),
      WorldCupItemModel(
          6, "$rootDirectory/female/promise_song.jpg", "프로미스나인 송하영", -1),
      WorldCupItemModel(
          7, "$rootDirectory/female/ilit_wonhee.jpg", "아일릿 원희", -1),
      WorldCupItemModel(
          8, "$rootDirectory/female/newjeans_haerin.jpg", "뉴진스 해린", -1),
      WorldCupItemModel(9, "$rootDirectory/female/itzy_yuna.jpg", "있지 유나", -1),
      WorldCupItemModel(
          10, "$rootDirectory/female/rescene_won.jpg", "리센느 원이", -1),
      WorldCupItemModel(
          11, "$rootDirectory/female/meovv_anna.jpg", "미야오 안나", -1),
      WorldCupItemModel(
          12, "$rootDirectory/female/triples_chaewon.jpg", "트리플에스 김채원", -1),
      WorldCupItemModel(13, "$rootDirectory/female/chu.jpg", "츄", -1),
      WorldCupItemModel(
          14, "$rootDirectory/female/izone_hyewon.jpg", "강혜원", -1),
      WorldCupItemModel(
          15, "$rootDirectory/female/idle_miyeon.jpg", "아이들 미연", -1),
      WorldCupItemModel(16, "$rootDirectory/female/lesserafim_kimchaewon.jpg",
          "르세라핌 김채원", -1),
    ];

    List<WorldCupItemModel> itemList2 = [
      WorldCupItemModel(1, "$rootDirectory/male/park_ji_hun.jpg", "박지훈", -2),
      WorldCupItemModel(
          2, "$rootDirectory/male/cortis_gunho.jpg", "코르티스 건호", -2),
      WorldCupItemModel(
          3, "$rootDirectory/male/nct127_jaehyun.jpg", "NCT 127 재현", -2),
      WorldCupItemModel(4, "$rootDirectory/male/tws_dohun.jpg", "투어스 도훈", -2),
      WorldCupItemModel(
          5, "$rootDirectory/male/and2ble_yujin.jpg", "앤더블 한유진", -2),
      WorldCupItemModel(6, "$rootDirectory/male/bnd_myung.jpg", "보넥도 명재현", -2),
      WorldCupItemModel(7, "$rootDirectory/male/bts_v.jpg", "방탄 뷔", -2),
      WorldCupItemModel(8, "$rootDirectory/male/txt_yun.jpg", "TXT 연준", -2),
      WorldCupItemModel(
          9, "$rootDirectory/male/theboyz_juyeon.jpg", "더보이즈 주연", -2),
      WorldCupItemModel(
          10, "$rootDirectory/male/riize_wonbin.jpg", "라이즈 원빈", -2),
      WorldCupItemModel(
          11, "$rootDirectory/male/nctwish_riku.jpg", "NCT WISH 리쿠", -2),
      WorldCupItemModel(12, "$rootDirectory/male/btob_yuk.jpg", "비투비 육성재", -2),
      WorldCupItemModel(
          13, "$rootDirectory/male/enhyphen_sunwoo.jpg", "엔하이픈 선우", -2),
      WorldCupItemModel(
          14, "$rootDirectory/male/txt_taehyun.jpg", "TXT 태현", -2),
      WorldCupItemModel(
          15, "$rootDirectory/male/astro_cha.jpg", "아스트로 차은우", -2),
      WorldCupItemModel(
          16, "$rootDirectory/male/got7_jinyoung.jpg", "갓세븐 진영", -2),
    ];

    try {
      final db = await dbProvider.database;

      await db.transaction((txn) async {
        // 예전에 저장됐던 샘플 월드컵/아이템 데이터를 모두 지운다.
        await txn.delete(worldCupItemTable, where: "worldCupIdx < 0");
        await txn.delete(worldCupTable, where: "idx < 0");

        // 최신 샘플 월드컵 데이터를 다시 저장한다.
        for (int i = 0; i < newList.length; i++) {
          await txn.insert(worldCupTable, newList[i].toRow());
        }

        // 최신 샘플 월드컵 아이템 데이터를 다시 저장한다.
        for (int i = 0; i < itemList1.length; i++) {
          await txn.insert(worldCupItemTable, itemList1[i].toRow());
          await txn.insert(worldCupItemTable, itemList2[i].toRow());
        }
      });
    } catch (e) {
      rethrow;
    }
  }

  // 월드컵 idx에 해당되는 아이템을 전부 불러온다.
  Future<List<WorldCupItemModel>> getWorldCupItemList(int worldCupIdx) async {
    List<WorldCupItemModel> itemList = [];

    try {
      final db = await dbProvider.database;

      List<Map<String, dynamic>> dbList = await db.query(worldCupItemTable,
          where: "worldCupIdx = ?", whereArgs: [worldCupIdx]);

      if (dbList.isNotEmpty) {
        for (Map<String, dynamic> item in dbList) {
          itemList.add(worldCupItemFromRow(item));
        }
      }
    } catch (e) {
      rethrow;
    }

    return itemList;
  }

  Future<void> deleteWorldCup(int idx) async {
    final db = await dbProvider.database;
    await db.transaction((txn) async {
      await txn.delete(
        worldCupItemTable,
        where: 'worldCupIdx = ?',
        whereArgs: [idx],
      );
      await txn.delete(worldCupTable, where: 'idx = ?', whereArgs: [idx]);
    });
  }
}
