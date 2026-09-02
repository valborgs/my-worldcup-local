import 'package:my_worldcup_local/db/sqlite.dart';

/// 무한 스크롤 UI를 확인하기 위한 개발 전용 테스트 데이터 생성기입니다.
///
/// 테스트 데이터가 더 이상 필요하지 않으면 `main.dart`의 호출과 이 파일만
/// 삭제하면 됩니다. 사용 범위가 분리되어 있어 사용자가 만든 데이터에는
/// 영향을 주지 않습니다.
abstract final class TestWorldCupSeeder {
  static const int _firstWorldCupIdx = -1019;
  static const int _lastWorldCupIdx = -1000;
  static const int _worldCupCount = 20;

  static const List<String> _sampleImages = [
    'assets/sample/female/aespa_carina.jpg',
    'assets/sample/female/hearts2_ian.jpg',
    'assets/sample/female/nmix_sul.jpg',
    'assets/sample/female/ive_jang.jpg',
  ];

  /// 기존 테스트 데이터만 제거한 뒤 20개를 다시 생성합니다.
  static Future<void> seed() async {
    final db = await SqliteProvider().database;
    await db.transaction((txn) async {
      await txn.delete(
        'worldcup_item_table',
        where: 'worldCupIdx BETWEEN ? AND ?',
        whereArgs: [_firstWorldCupIdx, _lastWorldCupIdx],
      );
      await txn.delete(
        'worldcup_table',
        where: 'idx BETWEEN ? AND ?',
        whereArgs: [_firstWorldCupIdx, _lastWorldCupIdx],
      );

      for (var index = 0; index < _worldCupCount; index++) {
        final worldCupIdx = _lastWorldCupIdx - index;
        await txn.insert('worldcup_table', {
          'idx': worldCupIdx,
          'title': '페이징 테스트 월드컵 ${index + 1}',
          'info': '10개 단위 무한 스크롤 테스트 데이터',
          'date': DateTime(2026, 1, index + 1).millisecondsSinceEpoch,
          'titleImageSrc': _sampleImages[index % _sampleImages.length],
          'maxRound': _sampleImages.length,
        });

        final batch = txn.batch();
        for (var itemIndex = 0;
            itemIndex < _sampleImages.length;
            itemIndex++) {
          batch.insert('worldcup_item_table', {
            'imagePath': _sampleImages[itemIndex],
            'imageInfo': '테스트 후보 ${itemIndex + 1}',
            'worldCupIdx': worldCupIdx,
          });
        }
        await batch.commit(noResult: true);
      }
    });
  }
}
