import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_worldcup_local/update/in_app_update_host.dart';

void main() {
  testWidgets('막는 화면은 아래 화면으로 가는 터치를 삼킨다', (tester) async {
    var underlyingTaps = 0;
    var updates = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Stack(
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => underlyingTaps++,
              child: const SizedBox.expand(),
            ),
            RequiredUpdateOverlay(onUpdate: () => updates++),
          ],
        ),
      ),
    );

    // 카드 바깥(막 위)을 눌러도 아래 화면에 닿지 않아야 한다.
    await tester.tapAt(const Offset(8, 8));
    await tester.pump();

    expect(underlyingTaps, 0);
    expect(updates, 0);
  });

  testWidgets('업데이트를 누르면 Play 창을 다시 띄우도록 알린다', (tester) async {
    var updates = 0;

    await tester.pumpWidget(
      MaterialApp(home: RequiredUpdateOverlay(onUpdate: () => updates++)),
    );

    expect(find.text('업데이트가 필요합니다'), findsOneWidget);

    await tester.tap(find.text('업데이트'));
    await tester.pump();

    expect(updates, 1);
  });
}
