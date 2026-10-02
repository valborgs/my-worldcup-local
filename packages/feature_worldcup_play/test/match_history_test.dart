import 'package:feature_worldcup_play/src/state/match_history.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worldcup_domain/worldcup_domain.dart';

void main() {
  const a = WorldCupItemModel(1, 'a.jpg', 'A', 1);
  const b = WorldCupItemModel(2, 'b.jpg', 'B', 1);
  const c = WorldCupItemModel(3, 'c.jpg', 'C', 1);
  const d = WorldCupItemModel(4, 'd.jpg', 'D', 1);

  // 4강: A vs B → B, C vs D → C. 결승은 순서가 섞여 C vs B → B.
  const semi1 = MatchRecord(stage: 4, order: 1, first: a, second: b, winner: b);
  const semi2 = MatchRecord(stage: 4, order: 2, first: c, second: d, winner: c);
  const finalMatch = MatchRecord(
    stage: 2,
    order: 1,
    first: c,
    second: b,
    winner: b,
  );
  final history = MatchHistory([semi1, semi2, finalMatch]);

  test('결승의 승자는 우승, 그 전 대결의 승자는 진출, 패자는 탈락이다', () {
    expect(finalMatch.outcomeOf(b), MatchOutcome.champion);
    expect(finalMatch.outcomeOf(c), MatchOutcome.eliminated);
    expect(semi1.outcomeOf(b), MatchOutcome.advanced);
    expect(semi1.outcomeOf(a), MatchOutcome.eliminated);
  });

  test('조 이름은 Z 다음에 AA로 이어진다', () {
    String label(int order) => MatchRecord(
      stage: 128,
      order: order,
      first: a,
      second: b,
      winner: a,
    ).groupLabel;

    expect(label(1), 'A');
    expect(label(26), 'Z');
    expect(label(27), 'AA');
    expect(label(28), 'AB');
    expect(label(52), 'AZ');
    expect(label(53), 'BA');
  });

  test('목록은 결승부터 첫 강까지 거슬러 올라가고 강 안에서는 진행 순서를 지킨다', () {
    final stages = history.stagesFromFinal();

    expect(stages.map((stage) => stage.stage), [2, 4]);
    expect(stages.first.isFinal, isTrue);
    expect(stages.first.matches, [finalMatch]);
    expect(stages.last.matches, [semi1, semi2]);
  });

  test('대진표는 우승 항목 아래로 각 항목이 이기고 올라온 대결을 매단다', () {
    final root = history.bracket()!;

    expect(root.item, b);
    expect(root.outcome, MatchOutcome.champion);
    expect(root.leafCount, 4);
    expect(root.depth, 3);

    // 결승의 두 항목. 자리는 결승 화면에 놓였던 순서를 따른다.
    final [loser, winner] = root.children;
    expect(loser.item, c);
    expect(loser.outcome, MatchOutcome.eliminated);
    expect(winner.item, b);
    expect(winner.outcome, MatchOutcome.advanced);

    // 결승에서 진 C도 4강에서는 D를 이기고 올라왔다.
    expect(loser.children.map((node) => node.item), [c, d]);
    expect(loser.children.map((node) => node.outcome), [
      MatchOutcome.advanced,
      MatchOutcome.eliminated,
    ]);
    expect(winner.children.map((node) => node.item), [a, b]);
    expect(winner.children.map((node) => node.outcome), [
      MatchOutcome.eliminated,
      MatchOutcome.advanced,
    ]);
    expect(winner.children.every((node) => node.children.isEmpty), isTrue);
  });

  test('기록이 없으면 대진표도 목록도 비어 있다', () {
    final empty = MatchHistory(const []);

    expect(empty.isEmpty, isTrue);
    expect(empty.bracket(), isNull);
    expect(empty.stagesFromFinal(), isEmpty);
  });
}
