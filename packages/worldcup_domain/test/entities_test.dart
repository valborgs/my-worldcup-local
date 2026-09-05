import 'package:flutter_test/flutter_test.dart';
import 'package:worldcup_domain/worldcup_domain.dart';

void main() {
  final date = DateTime.fromMillisecondsSinceEpoch(0);

  group('WorldCupModel', () {
    test('idx가 음수면 샘플 월드컵이다', () {
      expect(WorldCupModel(-1, 'a', 'b', date, 'p', 16).isSample, isTrue);
      expect(WorldCupModel(1, 'a', 'b', date, 'p', 16).isSample, isFalse);
    });

    test('copyWith는 지정한 필드만 바꾼다', () {
      final model = WorldCupModel(1, '제목', '설명', date, 'p', 16);
      final changed = model.copyWith(title: '새 제목');

      expect(changed.title, '새 제목');
      expect(changed.idx, model.idx);
      expect(changed.info, model.info);
      expect(changed.maxRound, model.maxRound);
    });

    test('모든 필드가 같으면 동등하다', () {
      expect(
        WorldCupModel(1, 'a', 'b', date, 'p', 16),
        WorldCupModel(1, 'a', 'b', date, 'p', 16),
      );
      expect(
        WorldCupModel(1, 'a', 'b', date, 'p', 16),
        isNot(WorldCupModel(2, 'a', 'b', date, 'p', 16)),
      );
    });
  });

  group('WorldCupItemModel', () {
    test('worldCupIdx가 음수면 샘플 항목이다', () {
      expect(const WorldCupItemModel(1, 'p', 'i', -1).isSample, isTrue);
      expect(const WorldCupItemModel(1, 'p', 'i', 1).isSample, isFalse);
    });

    test('모든 필드가 같으면 동등하다', () {
      expect(
        const WorldCupItemModel(1, 'p', 'i', 3),
        const WorldCupItemModel(1, 'p', 'i', 3),
      );
    });
  });
}
