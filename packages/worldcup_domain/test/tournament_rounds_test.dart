import 'package:flutter_test/flutter_test.dart';
import 'package:worldcup_domain/worldcup_domain.dart';

void main() {
  group('TournamentRounds.available', () {
    test('항목이 4개 미만이면 고를 수 있는 라운드가 없다', () {
      expect(TournamentRounds.available(0), isEmpty);
      expect(TournamentRounds.available(3), isEmpty);
    });

    test('항상 4강부터 시작해 2배씩 늘어난다', () {
      expect(TournamentRounds.available(4), [4]);
      expect(TournamentRounds.available(8), [4, 8]);
      expect(TournamentRounds.available(16), [4, 8, 16]);
      expect(TournamentRounds.available(32), [4, 8, 16, 32]);
    });

    test('2의 거듭제곱이 아니면 아래쪽 거듭제곱까지만 고를 수 있다', () {
      expect(TournamentRounds.available(7), [4]);
      expect(TournamentRounds.available(10), [4, 8]);
      expect(TournamentRounds.available(20), [4, 8, 16]);
    });
  });

  group('TournamentRounds.defaultRound', () {
    test('항목이 4개 미만이면 0이다', () {
      expect(TournamentRounds.defaultRound(3), 0);
    });

    test('2의 거듭제곱이면 항목 개수와 같다', () {
      expect(TournamentRounds.defaultRound(4), 4);
      expect(TournamentRounds.defaultRound(8), 8);
      expect(TournamentRounds.defaultRound(16), 16);
    });

    // 아래 두 테스트는 "옳은 동작"이 아니라 현재 동작을 박제한 것이다.
    // TODO(round-mismatch)를 해결할 때 이 테스트가 실패해야 하며,
    // 그때 기대값을 8 / 16으로 고친다.
    test('알려진 버그: 항목 12개 이상에서 available()에 없는 값을 돌려준다', () {
      expect(TournamentRounds.defaultRound(12), 12);
      expect(TournamentRounds.available(12), [4, 8]);
      expect(TournamentRounds.available(12), isNot(contains(12)));

      expect(TournamentRounds.defaultRound(20), 20);
      expect(TournamentRounds.available(20), [4, 8, 16]);
      expect(TournamentRounds.available(20), isNot(contains(20)));
    });

    test('11개 이하에서는 available()과 일치한다', () {
      for (var count = 4; count <= 11; count++) {
        expect(
          TournamentRounds.available(count),
          contains(TournamentRounds.defaultRound(count)),
          reason: '항목 $count개',
        );
      }
    });
  });
}
