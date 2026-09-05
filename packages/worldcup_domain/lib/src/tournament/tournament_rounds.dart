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

  /// 기본으로 선택될 라운드. 항목이 4개 미만이면 0을 반환한다.
  ///
  /// 주의: 현재 구현은 [available]과 어긋날 수 있다. 항목 개수가 2의 거듭제곱이
  /// 아니고 12개 이상이면 2의 거듭제곱이 아닌 값을 돌려준다.
  /// 예를 들어 항목 20개면 [available]은 `[4, 8, 16]`인데 이 값은 20이다.
  ///
  /// 리팩토링 중 동작을 바꾸지 않기 위해 기존 계산식을 그대로 옮겼다.
  /// 이 불일치는 별도 PR에서 다룬다. 기대 동작은 "항목 개수 이하의 가장 큰
  /// 2의 거듭제곱"이다.
  // TODO(round-mismatch): available()과 일치하도록 수정할 것.
  static int defaultRound(int itemCount) {
    if (itemCount ~/ 4 == 0) return 0;
    return itemCount ~/ 4 * 4;
  }
}
