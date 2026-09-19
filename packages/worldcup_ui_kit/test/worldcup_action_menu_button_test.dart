import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worldcup_ui_kit/worldcup_ui_kit.dart';

void main() {
  // Keep Korean regression expectations independent of supported device locales.
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    binding.platformDispatcher.localesTestValue = [const Locale('ko')];
  });
  tearDown(binding.platformDispatcher.clearLocalesTestValue);
  Widget buildMenu({
    required ValueChanged<WorldCupAction> onSelected,
    TextScaler? textScaler,
  }) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: textScaler == null
          ? null
          : (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaler: textScaler),
              child: child!,
            ),
      home: Scaffold(
        appBar: AppBar(
          actions: [
            WorldCupActionMenuButton(
              onCreate: () async => onSelected(WorldCupAction.create),
              onReceiveNearby: () async =>
                  onSelected(WorldCupAction.receiveNearby),
              onImportFile: () async => onSelected(WorldCupAction.importFile),
            ),
          ],
        ),
      ),
    );
  }

  testWidgets('AppBar에는 하나의 추가 버튼만 표시하고 세 기능을 시트에 제공한다', (tester) async {
    await tester.pumpWidget(buildMenu(onSelected: (_) {}));

    expect(find.byIcon(Icons.add), findsOneWidget);
    expect(find.byIcon(Icons.devices_other), findsNothing);
    expect(find.byIcon(Icons.file_download_outlined), findsNothing);
    expect(find.byTooltip('월드컵 추가 메뉴'), findsOneWidget);

    await tester.tap(find.byTooltip('월드컵 추가 메뉴'));
    await tester.pumpAndSettle();

    expect(find.text('월드컵 추가 방법 선택'), findsOneWidget);
    expect(find.text('새 월드컵 만들기'), findsOneWidget);
    expect(find.text('주변 기기에서 받기'), findsOneWidget);
    expect(find.text('파일에서 가져오기'), findsOneWidget);
  });

  testWidgets('바텀시트의 세 선택지는 각각 대응하는 기능을 실행한다', (tester) async {
    final selected = <WorldCupAction>[];
    await tester.pumpWidget(buildMenu(onSelected: selected.add));

    Future<void> select(String label) async {
      await tester.tap(find.byTooltip('월드컵 추가 메뉴'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
    }

    await select('새 월드컵 만들기');
    await select('주변 기기에서 받기');
    await select('파일에서 가져오기');

    expect(selected, const [
      WorldCupAction.create,
      WorldCupAction.receiveNearby,
      WorldCupAction.importFile,
    ]);
  });

  for (final locale in ['ko', 'en']) {
    testWidgets('$locale 큰 글자에서도 추가 메뉴의 모든 기능을 선택할 수 있다', (tester) async {
      binding.platformDispatcher.localesTestValue = [Locale(locale)];
      await tester.binding.setSurfaceSize(const Size(320, 480));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        buildMenu(onSelected: (_) {}, textScaler: const TextScaler.linear(2)),
      );

      await tester.tap(
        find.byTooltip(locale == 'ko' ? '월드컵 추가 메뉴' : 'Add a World Cup'),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ListView), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
