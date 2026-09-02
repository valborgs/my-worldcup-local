import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:my_worldcup_local/models/worldcup_model.dart';
import 'package:my_worldcup_local/widgets/worldcup_select_dialog.dart';

void main() {
  testWidgets('게임 시작 다이얼로그는 내용에 따라 커지고 화면을 넘으면 전체 본문이 스크롤된다', (tester) async {
    final longTitle = List.filled(7, '가나다라마바사아자차카타파하').join();
    final model = WorldCupModel(
      1,
      longTitle,
      List.filled(7, '가나다라마바사아자차카타파하').join(),
      DateTime(2026),
      '',
      4,
    );

    await tester.binding.setSurfaceSize(const Size(751, 469));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WorldCupSelectDialog(model, onChanged: () {}),
        ),
      ),
    );

    final titleFinder = find.byWidgetPredicate(
      (widget) => widget is Text && widget.semanticsLabel == '월드컵 제목',
    );
    final descriptionFinder = find.byWidgetPredicate(
      (widget) => widget is Text && widget.semanticsLabel == '월드컵 설명',
    );
    final title = tester.widget<Text>(titleFinder);
    final scrollViewFinder = find.byType(SingleChildScrollView);

    expect(title.data, longTitle);
    expect(title.maxLines, isNull);
    expect(title.overflow, isNull);
    expect(tester.getSize(titleFinder).height, greaterThan(50));
    expect(
      tester.getSize(find.byKey(const Key('worldCupDialogContent'))).height,
      greaterThanOrEqualTo(200),
    );
    expect(scrollViewFinder, findsOneWidget);
    expect(
      find.descendant(of: scrollViewFinder, matching: titleFinder),
      findsOneWidget,
    );
    expect(
      find.descendant(of: scrollViewFinder, matching: descriptionFinder),
      findsOneWidget,
    );
    final scrollableFinder = find.descendant(
      of: scrollViewFinder,
      matching: find.byType(Scrollable),
    );
    expect(
        tester
            .state<ScrollableState>(scrollableFinder.first)
            .position
            .maxScrollExtent,
        greaterThan(0));
    expect(tester.takeException(), isNull);
  });
}
