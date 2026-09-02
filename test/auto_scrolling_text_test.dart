import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:my_worldcup_local/widgets/auto_scrolling_text.dart';

void main() {
  testWidgets('공간을 넘는 제목은 말줄임 없이 자동으로 끝까지 이동한다', (tester) async {
    const title = '가나다라마바사아자차카타파하가나다라마바사아자차카타파하';

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 120,
              child: AutoScrollingText(
                title,
                semanticsLabel: '월드컵 결과 제목',
              ),
            ),
          ),
        ),
      ),
    );

    final text = tester.widget<Text>(find.text(title));
    final scrollView = tester.widget<SingleChildScrollView>(
      find.byType(SingleChildScrollView),
    );

    expect(text.overflow, TextOverflow.visible);
    expect(text.maxLines, 1);
    expect(text.semanticsLabel, '월드컵 결과 제목');
    expect(scrollView.controller!.position.maxScrollExtent, greaterThan(0));
    expect(scrollView.controller!.offset, 0);

    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(milliseconds: 500));

    expect(scrollView.controller!.offset, greaterThan(0));

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('공간 안에 들어오는 짧은 제목은 움직이지 않는다', (tester) async {
    const title = '짧은 제목';

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 300,
            child: AutoScrollingText(title),
          ),
        ),
      ),
    );

    final scrollView = tester.widget<SingleChildScrollView>(
      find.byType(SingleChildScrollView),
    );
    await tester.pump(const Duration(seconds: 2));

    expect(scrollView.controller!.position.maxScrollExtent, 0);
    expect(scrollView.controller!.offset, 0);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
