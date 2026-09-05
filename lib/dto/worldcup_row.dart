import 'package:worldcup_domain/worldcup_domain.dart';

/// 도메인 엔티티와 SQLite row 사이의 변환.
///
/// 엔티티는 저장 방식을 알아서는 안 되므로, 예전에 모델에 있던
/// `toMap()` / `fromDB()`를 이 매퍼로 분리했다.
///
/// TODO(phase2): worldcup_data 패키지로 옮길 것.
extension WorldCupRow on WorldCupModel {
  /// `worldcup_table`에 넣을 row.
  ///
  /// `idx`는 음수일 때(샘플 월드컵)만 넣는다. 사용자가 만든 월드컵은
  /// AUTOINCREMENT에 맡긴다.
  Map<String, dynamic> toRow() {
    return <String, dynamic>{
      if (idx < 0) 'idx': idx,
      'title': title,
      'info': info,
      // millisecondsSinceEpoch로 저장한다. 컬럼 타입이 INTEGER다.
      'date': date.millisecondsSinceEpoch,
      'titleImageSrc': titleImageSrc,
      'maxRound': maxRound,
    };
  }
}

/// `worldcup_table` row를 엔티티로.
WorldCupModel worldCupFromRow(Map<String, dynamic> row) {
  return WorldCupModel(
    row['idx'] as int,
    row['title'] as String,
    row['info'] as String,
    DateTime.fromMillisecondsSinceEpoch(row['date'] as int),
    row['titleImageSrc'] as String,
    row['maxRound'] as int,
  );
}

extension WorldCupItemRow on WorldCupItemModel {
  /// `worldcup_item_table`에 넣을 row. `idx`는 항상 AUTOINCREMENT에 맡긴다.
  Map<String, dynamic> toRow() {
    return <String, dynamic>{
      'imagePath': imagePath,
      'imageInfo': imageInfo,
      'worldCupIdx': worldCupIdx,
    };
  }
}

/// `worldcup_item_table` row를 엔티티로.
WorldCupItemModel worldCupItemFromRow(Map<String, dynamic> row) {
  return WorldCupItemModel(
    row['idx'] as int,
    row['imagePath'] as String,
    row['imageInfo'] as String,
    row['worldCupIdx'] as int,
  );
}
