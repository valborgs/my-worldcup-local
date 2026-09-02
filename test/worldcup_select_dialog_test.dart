import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:my_worldcup_local/models/worldcup_model.dart';
import 'package:my_worldcup_local/widgets/worldcup_select_dialog.dart';

void main() {
  testWidgets('게임 시작 다이얼로그는 제한된 높이를 넘으면 전체 본문이 스크롤된다', (tester) async {
    final longTitle = List.filled(7, '가나다라마바사아자차카타파하').join();
    final model = WorldCupModel(
      1,
      longTitle,
      List.filled(7, '가나다라마바사아자차카타파하').join(),
      DateTime(2026),
      '',
      4,
    );

    // 본문의 최소 높이보다 작은 뷰포트로 스크롤을 결정적으로 유도한다.
    // 특정 기기의 해상도나 글꼴의 렌더링 높이에는 의존하지 않는다.
    await tester.binding.setSurfaceSize(const Size(400, 320));
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
    final shareButtonFinder = find.widgetWithText(OutlinedButton, '공유하기');

    expect(title.data, longTitle);
    expect(title.maxLines, isNull);
    expect(title.overflow, isNull);
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
    expect(shareButtonFinder, findsOneWidget);
    expect(
      tester.getCenter(shareButtonFinder).dy,
      greaterThan(
          tester.getCenter(find.widgetWithText(OutlinedButton, '삭제')).dy),
      reason: '실제 월드컵 공유 버튼은 다른 다이얼로그 작업 아래에 배치해야 한다.',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('샘플 월드컵에는 공유하기 버튼이 표시되지 않는다', (tester) async {
    final sampleModel = WorldCupModel(
      -1,
      '샘플 월드컵',
      '샘플 설명',
      DateTime(2026),
      'assets/sample/female/aespa_carina.jpg',
      16,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WorldCupSelectDialog(sampleModel, onChanged: () {}),
        ),
      ),
    );

    expect(find.widgetWithText(OutlinedButton, '공유하기'), findsNothing);
  });
}
