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

    test('2의 거듭제곱이 아니면 그 이하의 가장 큰 2의 거듭제곱이다', () {
      // 예전에는 4의 배수로만 내려서 12 / 20 을 돌려줬고, 그 값으로 게임을
      // 시작하면 라운드 도중 항목이 홀수가 되어 앱이 죽었다.
      expect(TournamentRounds.defaultRound(12), 8);
      expect(TournamentRounds.defaultRound(15), 8);
      expect(TournamentRounds.defaultRound(20), 16);
      expect(TournamentRounds.defaultRound(31), 16);
    });

    test('언제나 고를 수 있는 값이어야 한다', () {
      // 이것이 지켜지지 않으면 사용자가 드롭다운에 없는 라운드로 게임을
      // 시작하게 된다. 두 함수가 어긋나는 것을 막는 핵심 불변식이다.
      for (var count = 4; count <= 200; count++) {
        expect(
          TournamentRounds.available(count),
          contains(TournamentRounds.defaultRound(count)),
          reason: '항목 $count개의 기본값이 선택 목록에 없다',
        );
      }
    });

    test('언제나 2의 거듭제곱이어야 한다', () {
      // 2의 거듭제곱이 아니면 대진표를 끝까지 반으로 나눌 수 없다.
      for (var count = 4; count <= 200; count++) {
        final round = TournamentRounds.defaultRound(count);
        expect(
          round & (round - 1),
          0,
          reason: '항목 $count개의 기본값 $round 이(가) 2의 거듭제곱이 아니다',
        );
      }
    });

    test('항목 개수를 넘지 않는다', () {
      for (var count = 4; count <= 200; count++) {
        expect(
          TournamentRounds.defaultRound(count),
          lessThanOrEqualTo(count),
          reason: '항목 $count개보다 큰 라운드를 기본값으로 잡았다',
        );
      }
    });
  });

  group('대진표가 끝까지 진행된다', () {
    // 기본 라운드로 시작했을 때 WorldCupGame의 라운드 축소가 항상 1까지
    // 내려가야 한다. 홀수가 되는 순간 게임 화면이 남은 항목을 꺼내다 죽는다.
    test('기본 라운드는 반씩 나눠 결승까지 도달한다', () {
      for (var count = 4; count <= 200; count++) {
        var remaining = TournamentRounds.defaultRound(count);
        while (remaining > 1) {
          expect(
            remaining.isEven,
            isTrue,
            reason: '항목 $count개: 라운드가 $remaining 에서 홀수가 됐다',
          );
          remaining = remaining ~/ 2;
        }
        expect(remaining, 1, reason: '항목 $count개: 결승에 도달하지 못했다');
      }
    });
  });
}
