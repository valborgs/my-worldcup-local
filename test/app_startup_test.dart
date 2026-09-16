import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_worldcup_local/main.dart';
import 'package:worldcup_core/worldcup_core.dart';
import 'package:worldcup_ui_kit/worldcup_ui_kit.dart';

/// 첫 화면을 무엇으로 띄우는지에 대한 계약.
///
/// 여기서 지키는 것은 한 가지다. `MaterialApp.home`을 쓰면 `WidgetsApp`이
/// '/'를 그 위젯으로 가로채고 앱의 `onGenerateRoute`를 부르지 않는다.
/// `AppRoutes.list`가 '/'라서, 온보딩이 끝나며 그 이름으로 replace 해도
/// 온보딩이 다시 열린다. 첫 실행에서 앱을 쓸 수 없게 되는 버그였다.
void main() {
  // Keep Korean regression expectations independent of supported device locales.
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    binding.platformDispatcher.localesTestValue = [const Locale('ko')];
  });
  tearDown(binding.platformDispatcher.clearLocalesTestValue);
  Widget app({required bool? isAlreadyShownHelp}) {
    return ProviderScope(
      child: MyWorldCup(
        isAlreadyShownHelp,
        const [],
        enableBottomSheetSelectionPagerTransition: true,
      ),
    );
  }

  MaterialApp findApp(WidgetTester tester) =>
      tester.widget<MaterialApp>(find.byType(MaterialApp));

  for (final locale in [const Locale('ko', 'KR'), const Locale('fr', 'FR')]) {
    testWidgets('$locale 기기에서 한국어 앱 및 기본 위젯 리소스를 사용한다', (tester) async {
      tester.binding.platformDispatcher.localesTestValue = [locale];
      addTearDown(tester.binding.platformDispatcher.clearLocalesTestValue);

      await tester.pumpWidget(app(isAlreadyShownHelp: null));
      await tester.pumpAndSettle();

      final context = tester.element(find.text('스킵하기'));
      expect(Localizations.localeOf(context), const Locale('ko'));
      expect(AppLocalizations.of(context).appTitle, '내가 만든 월드컵');
      expect(MaterialLocalizations.of(context).cancelButtonLabel, '취소');
      expect(findApp(tester).onGenerateTitle!(context), '내가 만든 월드컵');
      expect(findApp(tester).supportedLocales.first, const Locale('ko'));
      expect(tester.takeException(), isNull);
    });
  }

  for (final locale in [const Locale('en', 'US'), const Locale('en', 'GB')]) {
    testWidgets('$locale 기기에서는 영어 앱과 기본 위젯 리소스를 사용한다', (tester) async {
      tester.binding.platformDispatcher.localesTestValue = [locale];
      addTearDown(tester.binding.platformDispatcher.clearLocalesTestValue);
      await tester.pumpWidget(app(isAlreadyShownHelp: null));
      await tester.pumpAndSettle();
      final context = tester.element(find.text('Skip'));
      expect(Localizations.localeOf(context), const Locale('en'));
      expect(AppLocalizations.of(context).appTitle, 'My Custom World Cup');
      expect(MaterialLocalizations.of(context).cancelButtonLabel, 'Cancel');
      expect(findApp(tester).onGenerateTitle!(context), 'My Custom World Cup');
      expect(findApp(tester).supportedLocales.first, const Locale('ko'));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('일본어 기기에서 앱과 기본 위젯이 일본어로 표시된다', (tester) async {
    tester.binding.platformDispatcher.localesTestValue = [
      const Locale('ja', 'JP'),
    ];
    addTearDown(tester.binding.platformDispatcher.clearLocalesTestValue);
    await tester.pumpWidget(app(isAlreadyShownHelp: null));
    await tester.pumpAndSettle();
    final context = tester.element(find.text('スキップ'));
    expect(Localizations.localeOf(context), const Locale('ja'));
    expect(AppLocalizations.of(context).appTitle, '自分で作るワールドカップ');
    expect(MaterialLocalizations.of(context).cancelButtonLabel, 'キャンセル');
    expect(findApp(tester).onGenerateTitle!(context), '自分で作るワールドカップ');
    expect(findApp(tester).supportedLocales.first, const Locale('ko'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('첫 화면도 라우터를 거친다', (tester) async {
    await tester.pumpWidget(app(isAlreadyShownHelp: null));

    expect(
      findApp(tester).home,
      isNull,
      reason:
          'home을 두면 WidgetsApp이 "/"를 가로채 AppRoutes.list가 라우터에 닿지 '
          '않는다. 온보딩이 끝나도 빠져나갈 수 없게 된다.',
    );
  });

  testWidgets('처음 실행하면 온보딩만 쌓고 시작한다', (tester) async {
    await tester.pumpWidget(app(isAlreadyShownHelp: null));

    expect(findApp(tester).initialRoute, AppRoutes.onboarding);
    expect(find.text('스킵하기'), findsOneWidget);
  });

  // 시작 라우트 선택은 화면을 만들지 않고 본다. 목록 화면은 저장소와 광고
  // 의존성을 끌고 와서, 여기서 확인하려는 것과 상관없는 준비물이 필요하다.
  test('온보딩을 이미 봤으면 목록으로, 아니면 온보딩으로 연다', () {
    expect(startRouteFor(isAlreadyShownHelp: true), AppRoutes.list);
    expect(startRouteFor(isAlreadyShownHelp: false), AppRoutes.onboarding);
    // 값을 못 읽었으면 아직 본 적 없다고 본다.
    expect(startRouteFor(isAlreadyShownHelp: null), AppRoutes.onboarding);
  });

  test('온보딩 라우트와 목록 라우트는 서로 다른 이름이다', () {
    // 같은 이름이면 온보딩이 자기 자신으로 replace 된다.
    expect(AppRoutes.onboarding, isNot(AppRoutes.list));
  });
}
