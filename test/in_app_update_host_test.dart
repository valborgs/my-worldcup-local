import 'package:worldcup_ui_kit/worldcup_ui_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_worldcup_local/update/in_app_update_host.dart';

void main() {
  testWidgets('일본어 필수 업데이트 안내는 작은 화면과 큰 글자에서 표시된다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ja'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
          child: RequiredUpdateOverlay(onUpdate: () {}),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('アップデートが必要です'), findsOneWidget);
    expect(find.text('アップデート'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('의존성을 만들지 못해도 앱 화면은 그대로 뜬다', (tester) async {
    // featureFlagProvider는 override 되지 않으면 던진다. main()이 Firebase
    // 초기화 실패를 잡고 앱을 계속 띄운 뒤 이 포트를 만들 때와 같은 상황이다.
    // 이 위젯은 라우터 위에 있어서, 여기서 새어 나간 예외는 화면 전체를 날린다.
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: Text('본문')),
        ),
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => InAppUpdateHost(child: child!),
          home: const Scaffold(body: Text('본문')),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('본문'), findsOneWidget);
  });

  testWidgets('막는 화면은 아래 화면으로 가는 터치를 삼킨다', (tester) async {
    var underlyingTaps = 0;
    var updates = 0;

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
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
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: RequiredUpdateOverlay(onUpdate: () => updates++),
      ),
    );

    expect(find.text('업데이트가 필요합니다'), findsOneWidget);

    await tester.tap(find.text('업데이트'));
    await tester.pump();

    expect(updates, 1);
  });
}
