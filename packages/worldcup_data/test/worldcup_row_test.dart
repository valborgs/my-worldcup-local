import 'package:flutter_test/flutter_test.dart';
import 'package:worldcup_data/worldcup_data.dart';
import 'package:worldcup_domain/worldcup_domain.dart';

/// 엔티티와 SQLite row 사이의 변환을 지킨다.
void main() {
  test('WorldCupModel은 DB 저장 후 날짜를 밀리초 정밀도로 복원한다', () {
    final date = DateTime(2026, 8, 26, 12, 34, 56, 789);
    final original = WorldCupModel(1, '제목', '설명', date, 'image.jpg', 16);
    // idx는 양수일 때 row에 담기지 않는다(AUTOINCREMENT). 읽기용으로 채워준다.
    final row = <String, Object?>{'idx': 1, ...original.toRow()};

    expect(worldCupFromRow(row).date, date);
  });

  test('사용자 월드컵의 idx는 row에 담기지 않는다', () {
    final row = WorldCupModel(7, 't', 'i', DateTime(2026), 'p', 8).toRow();
    expect(row.containsKey('idx'), isFalse);
  });

  test('샘플 월드컵의 idx는 row에 담긴다', () {
    // 샘플은 고정 id(-1, -2)로 지워지고 다시 심어지므로 id가 필요하다.
    final row = WorldCupModel(-1, 't', 'i', DateTime(2026), 'p', 8).toRow();
    expect(row['idx'], -1);
  });

  test('항목 row는 왕복 변환된다', () {
    const item = WorldCupItemModel(5, '/a/b.jpg', '이름', 3);
    final row = <String, Object?>{'idx': 5, ...item.toRow()};
    expect(worldCupItemFromRow(row), item);
  });
}
