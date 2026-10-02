import 'package:feature_worldcup_play/src/state/match_history.dart';
import 'package:feature_worldcup_play/src/widgets/match_history_bracket.dart';
import 'package:feature_worldcup_play/src/widgets/match_history_dialog.dart';
import 'package:feature_worldcup_play/src/widgets/match_history_entry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worldcup_domain/worldcup_domain.dart';
import 'package:worldcup_ui_kit/worldcup_ui_kit.dart';

/// [count]강 게임을 끝까지 진행한 기록. 매 대결에서 먼저 놓인 항목이 이기고,
/// 실제 게임처럼 강이 바뀔 때 순서가 바뀐다.
MatchHistory playedHistory(int count) {
  // 사용자 항목(양수 worldCupIdx)이라 이름이 번역 없이 그대로 표시된다.
  var remaining = [
    for (var i = 1; i <= count; i++)
      WorldCupItemModel(i, 'missing/$i.jpg', 'item$i', 1),
  ];
  final records = <MatchRecord>[];
  while (remaining.length > 1) {
    final winners = <WorldCupItemModel>[];
    for (var i = 0; i < remaining.length; i += 2) {
      records.add(
        MatchRecord(
          stage: remaining.length,
          order: i ~/ 2 + 1,
          first: remaining[i],
          second: remaining[i + 1],
          winner: remaining[i],
        ),
      );
      winners.add(remaining[i]);
    }
    remaining = winners.reversed.toList();
  }
  return MatchHistory(records);
}

Widget host(MatchHistory history, {double textScale = 1}) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: TextScaler.linear(textScale)),
      child: child!,
    ),
    home: Builder(
      builder: (context) => Scaffold(
        body: TextButton(
          onPressed: () => showMatchHistoryDialog(context, history),
          child: const Text('open'),
        ),
      ),
    ),
  );
}

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  void useLocale(String code) {
    binding.platformDispatcher.localesTestValue = [Locale(code)];
  }

  setUp(() => useLocale('ko'));
  tearDown(binding.platformDispatcher.clearLocalesTestValue);

  testWidgets('대진표로 열리고 토글로 목록과 오갈 수 있으며 닫기로 닫힌다', (tester) async {
    await tester.pumpWidget(host(playedHistory(4)));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('진행 기록'), findsOneWidget);
    // 대진표: 꼭대기의 우승 1칸, 결승 2칸, 4강 4칸.
    expect(find.text('우승'), findsOneWidget);
    expect(find.text('진출'), findsNWidgets(3));
    expect(find.text('탈락'), findsNWidgets(3));
    // 4강에서 이긴 1번과 3번이 순서가 바뀌어 결승에서 3번 vs 1번으로 만난다.
    // 우승한 3번은 꼭대기, 결승, 4강 줄에 한 번씩 나온다.
    expect(find.text('item3'), findsNWidgets(3));
    expect(find.text('item1'), findsNWidgets(2));
    expect(find.text('item2'), findsOneWidget);
    expect(find.text('결승전'), findsNothing);

    await tester.tap(find.text('목록'));
    await tester.pumpAndSettle();

    expect(find.text('결승전'), findsOneWidget);
    expect(find.text('4강'), findsOneWidget);
    expect(find.text('A조'), findsOneWidget);
    expect(find.text('B조'), findsOneWidget);
    // 목록에서는 결승의 승자가 우승으로 표시된다.
    expect(find.text('우승'), findsOneWidget);
    expect(find.text('진출'), findsNWidgets(2));
    expect(find.text('탈락'), findsNWidgets(3));

    await tester.tap(find.text('대진표'));
    await tester.pumpAndSettle();
    expect(find.text('결승전'), findsNothing);
    expect(find.text('진출'), findsNWidgets(3));

    await tester.tap(find.byType(CloseButton));
    await tester.pumpAndSettle();
    expect(find.text('진행 기록'), findsNothing);
    expect(find.text('open'), findsOneWidget);
  });

  testWidgets('목록은 결승이 맨 위에 오고 스크롤해 첫 강까지 볼 수 있다', (tester) async {
    await tester.pumpWidget(host(playedHistory(16)));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('목록'));
    await tester.pumpAndSettle();

    expect(find.text('결승전'), findsOneWidget);
    expect(find.text('16강'), findsNothing);

    await tester.scrollUntilVisible(
      find.text('16강'),
      300,
      scrollable: find.byType(Scrollable),
    );
    expect(find.text('16강'), findsOneWidget);
  });

  // 넓은 대진표와 큰 글자, 긴 영어 문구에서도 칸이 넘치지 않아야 한다.
  // 넘치면 RenderFlex overflow가 테스트 실패로 보고된다.
  for (final locale in ['ko', 'en', 'ja']) {
    testWidgets('32강 기록을 큰 글자로 열어도 두 보기 모두 넘치지 않는다 $locale', (tester) async {
      useLocale(locale);
      await tester.pumpWidget(host(playedHistory(32), textScale: 2));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      // 꼭대기 1칸 + 결승부터 32강까지 2, 4, 8, 16, 32칸.
      expect(
        find.descendant(
          of: find.byType(MatchHistoryBracket),
          matching: find.byType(MatchHistoryAvatar),
        ),
        findsNWidgets(63),
      );

      await tester.tap(find.byIcon(Icons.format_list_bulleted));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(Scrollable), const Offset(0, -3000));
      await tester.pumpAndSettle();
    });
  }
}
