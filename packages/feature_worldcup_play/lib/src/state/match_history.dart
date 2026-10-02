import 'package:worldcup_domain/worldcup_domain.dart';

/// 대결에서 한 항목이 받은 결과.
enum MatchOutcome { champion, advanced, eliminated }

/// 대결 한 번의 기록.
class MatchRecord {
  /// 이 대결이 속한 '강'. 그 강을 시작할 때 남아 있던 항목 수이며 결승은 2다.
  final int stage;

  /// '강' 안에서 몇 번째 대결인지. 1부터 센다.
  final int order;

  final WorldCupItemModel first;
  final WorldCupItemModel second;
  final WorldCupItemModel winner;

  const MatchRecord({
    required this.stage,
    required this.order,
    required this.first,
    required this.second,
    required this.winner,
  });

  bool get isFinal => stage == 2;

  bool isWinner(WorldCupItemModel item) => item.idx == winner.idx;

  MatchOutcome outcomeOf(WorldCupItemModel item) {
    if (!isWinner(item)) return MatchOutcome.eliminated;
    return isFinal ? MatchOutcome.champion : MatchOutcome.advanced;
  }

  /// 조 이름. A, B, ..., Z 다음은 AA, AB로 이어진다.
  /// 64강부터는 한 강의 대결이 26개를 넘는다.
  String get groupLabel {
    final buffer = StringBuffer();
    var n = order;
    while (n > 0) {
      n--;
      buffer.write(String.fromCharCode(0x41 + n % 26));
      n ~/= 26;
    }
    return buffer.toString().split('').reversed.join();
  }
}

/// 한 '강'에서 치른 대결 묶음.
class MatchStage {
  final int stage;
  final List<MatchRecord> matches;

  const MatchStage(this.stage, this.matches);

  bool get isFinal => stage == 2;
}

/// 대진표의 한 칸. [children]은 이 항목이 여기까지 올라오며 이긴 직전 대결의
/// 두 항목이고, 첫 '강'의 항목이면 비어 있다.
class BracketNode {
  final WorldCupItemModel item;
  final MatchOutcome outcome;
  final List<BracketNode> children;

  const BracketNode(this.item, this.outcome, [this.children = const []]);

  int get leafCount => children.isEmpty
      ? 1
      : children.fold(0, (sum, child) => sum + child.leafCount);

  /// 이 칸을 포함해 맨 아래 칸까지의 줄 수.
  int get depth => children.isEmpty
      ? 1
      : 1 +
            children
                .map((child) => child.depth)
                .reduce((a, b) => a > b ? a : b);
}

/// 게임 시작부터 우승까지의 선택 과정.
class MatchHistory {
  /// 진행한 순서대로 담긴 대결 기록. 마지막이 결승이다.
  final List<MatchRecord> matches;

  MatchHistory(Iterable<MatchRecord> matches)
    : matches = List.unmodifiable(matches);

  bool get isEmpty => matches.isEmpty;

  /// 결승부터 첫 '강'까지 거슬러 올라가는 순서로 묶는다.
  List<MatchStage> stagesFromFinal() {
    final stages = <MatchStage>[];
    for (final match in matches) {
      if (stages.isEmpty || stages.last.stage != match.stage) {
        stages.add(MatchStage(match.stage, [match]));
      } else {
        stages.last.matches.add(match);
      }
    }
    return stages.reversed.toList();
  }

  /// 우승 항목을 꼭대기로 하는 대진표. 기록이 없으면 null.
  BracketNode? bracket() {
    if (matches.isEmpty) return null;
    final finalIndex = matches.length - 1;
    final finalMatch = matches[finalIndex];
    return BracketNode(finalMatch.winner, MatchOutcome.champion, [
      _node(finalMatch.first, finalIndex),
      _node(finalMatch.second, finalIndex),
    ]);
  }

  BracketNode _node(WorldCupItemModel item, int matchIndex) {
    final match = matches[matchIndex];
    // 강이 바뀔 때마다 순서를 다시 섞으므로 직전 대결은 자리로 찾을 수 없다.
    // 이 항목이 이긴 가장 가까운 이전 대결이 곧 이 항목을 올려 보낸 대결이다.
    var feeder = matchIndex - 1;
    while (feeder >= 0 && !matches[feeder].isWinner(item)) {
      feeder--;
    }
    return BracketNode(
      item,
      match.isWinner(item) ? MatchOutcome.advanced : MatchOutcome.eliminated,
      feeder < 0
          ? const []
          : [
              _node(matches[feeder].first, feeder),
              _node(matches[feeder].second, feeder),
            ],
    );
  }
}
