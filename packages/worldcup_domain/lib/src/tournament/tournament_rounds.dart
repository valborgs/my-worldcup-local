/// 항목 개수로부터 토너먼트 라운드를 계산한다.
///
/// 원래 `lib/tools/make_round.dart`의 `makeRoundList` / `makeMaxRound`였다.
/// 순수 계산이라 의존성이 없으므로 클래스 인스턴스 대신 정적 메서드로 둔다.
abstract final class TournamentRounds {
  /// 사용자가 고를 수 있는 라운드 목록. 항상 4강부터 시작한다.
  ///
  /// 예: 항목 16개 -> `[4, 8, 16]`, 항목 10개 -> `[4, 8]`.
  /// 항목이 4개 미만이면 빈 목록을 반환한다.
  static List<int> available(int itemCount) {
    final rounds = <int>[];
    var remaining = itemCount;
    var round = 4;
    while (remaining ~/ 4 != 0) {
      rounds.add(round);
      remaining = remaining ~/ 2;
      round *= 2;
    }
    return rounds;
  }

  /// 기본으로 선택될 라운드. 항목 개수 이하의 가장 큰 2의 거듭제곱이다.
  ///
  /// 항목이 4개 미만이면 0을 반환한다.
  ///
  /// [available]의 마지막 값을 그대로 쓴다. 두 함수가 규칙을 따로 갖고 있으면
  /// 어긋나기 때문이다. 예전 구현은 `itemCount ~/ 4 * 4`로 4의 배수까지만
  /// 내림했는데, 이는 2의 거듭제곱이 아니어서 고를 수 없는 값이 기본값으로
  /// 잡혔다. 항목 20개면 고를 수 있는 값은 `[4, 8, 16]`인데 기본값은 20이
  /// 되었고, 그대로 게임을 시작하면 라운드 도중 항목이 홀수가 되어 앱이
  /// 죽었다.
  static int defaultRound(int itemCount) {
    final rounds = available(itemCount);
    return rounds.isEmpty ? 0 : rounds.last;
  }
}
