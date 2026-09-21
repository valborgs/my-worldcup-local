import 'package:worldcup_ui_kit/worldcup_ui_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:feature_worldcup_list/src/widgets/worldcup_select_dialog.dart';
import 'package:worldcup_domain/worldcup_domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worldcup_core/worldcup_core.dart';

void main() {
  // Keep Korean regression expectations independent of supported device locales.
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    binding.platformDispatcher.localesTestValue = [const Locale('ko')];
  });
  tearDown(binding.platformDispatcher.clearLocalesTestValue);
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

    // 긴 제목·설명과 고정된 하단 영역이 화면 높이를 넘는 조건을 만든다.
    await tester.binding.setSurfaceSize(const Size(400, 520));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: WorldCupSelectDialog(model, onChanged: () {})),
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
    final roundLabelFinder = find.text('- 라운드 수를 선택해주세요- ');
    final roundDropdownFinder = find.byType(DropdownMenu<int>);
    final startButtonFinder = find.widgetWithText(OutlinedButton, '시작');
    final shareButtonFinder = find.widgetWithText(OutlinedButton, '공유하기');

    expect(title.data, longTitle);
    expect(title.maxLines, isNull);
    expect(title.overflow, isNull);
    expect(scrollViewFinder, findsOneWidget);
    expect(
      find.descendant(of: scrollViewFinder, matching: titleFinder),
      findsOneWidget,
    );
    expect(
      find.descendant(of: scrollViewFinder, matching: descriptionFinder),
      findsOneWidget,
    );
    expect(
      find.descendant(of: scrollViewFinder, matching: roundLabelFinder),
      findsNothing,
    );
    expect(
      find.descendant(of: scrollViewFinder, matching: roundDropdownFinder),
      findsNothing,
    );
    expect(
      find.descendant(of: scrollViewFinder, matching: startButtonFinder),
      findsNothing,
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
      greaterThan(0),
    );
    final roundLabelCenter = tester.getCenter(roundLabelFinder);
    final startButtonCenter = tester.getCenter(startButtonFinder);
    await tester.drag(scrollViewFinder, const Offset(0, -100));
    await tester.pump();
    expect(tester.getCenter(roundLabelFinder), roundLabelCenter);
    expect(tester.getCenter(startButtonFinder), startButtonCenter);
    expect(shareButtonFinder, findsOneWidget);
    expect(
      tester.getCenter(shareButtonFinder).dy,
      greaterThan(
        tester.getCenter(find.widgetWithText(OutlinedButton, '삭제')).dy,
      ),
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
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: WorldCupSelectDialog(sampleModel, onChanged: () {}),
          ),
        ),
      ),
    );

    expect(find.widgetWithText(OutlinedButton, '공유하기'), findsNothing);
    final descriptionFinder = find.byWidgetPredicate(
      (widget) => widget is Text && widget.semanticsLabel == '월드컵 설명',
    );
    final scrollViewFinder = find.byType(SingleChildScrollView);
    final scrollableFinder = find.descendant(
      of: scrollViewFinder,
      matching: find.byType(Scrollable),
    );

    expect(tester.getSize(descriptionFinder).height, lessThan(200));
    expect(
      tester
          .state<ScrollableState>(scrollableFinder.first)
          .position
          .maxScrollExtent,
      0,
      reason: '짧은 제목과 설명은 남는 공간을 채우거나 스크롤되지 않아야 한다.',
    );
  });

  testWidgets('사용자 월드컵은 Nearby 공유와 기존 앱 공유를 선택할 수 있다', (tester) async {
    final model = WorldCupModel(5, '공유 월드컵', '설명', DateTime(2026), '', 4);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: WorldCupSelectDialog(model, onChanged: () {})),
        ),
      ),
    );

    await tester.tap(find.widgetWithText(OutlinedButton, '공유하기'));
    await tester.pumpAndSettle();

    expect(find.text('주변 기기로 보내기'), findsOneWidget);
    expect(find.text('다른 앱으로 공유하기'), findsOneWidget);
  });
  group('공유 전 민감한 사진 확인', () {
    const warning = '민감한 내용의 사진이 있는지 한 번 더 확인해주세요.';

    Future<List<String>> pumpShareDialog(
      WidgetTester tester,
      _FakePackagePort port,
    ) async {
      final pushedRoutes = <String>[];
      final model = WorldCupModel(5, '공유 월드컵', '설명', DateTime(2026), '', 4);
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: WorldCupSelectDialog(
                model,
                onChanged: () {},
                packageGateway: port,
              ),
            ),
            onGenerateRoute: (settings) {
              pushedRoutes.add(settings.name!);
              return MaterialPageRoute<void>(builder: (_) => const Text('전송'));
            },
          ),
        ),
      );
      return pushedRoutes;
    }

    Future<void> choose(WidgetTester tester, String method) async {
      await tester.tap(find.widgetWithText(OutlinedButton, '공유하기'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(method));
      await tester.pumpAndSettle();
    }

    testWidgets('다른 앱 공유는 확인을 눌러야 공유 파일을 보낸다', (tester) async {
      final port = _FakePackagePort();
      await pumpShareDialog(tester, port);

      await choose(tester, '다른 앱으로 공유하기');
      expect(find.textContaining(warning), findsOneWidget);
      await tester.tap(find.text('취소'));
      await tester.pumpAndSettle();
      expect(port.sharedCount, 0);

      await choose(tester, '다른 앱으로 공유하기');
      await tester.tap(find.text('확인'));
      await tester.pumpAndSettle();
      expect(port.sharedCount, 1);
    });

    testWidgets('주변 기기 전송도 확인을 눌러야 전송 화면으로 간다', (tester) async {
      final pushedRoutes = await pumpShareDialog(tester, _FakePackagePort());

      await choose(tester, '주변 기기로 보내기');
      expect(find.textContaining(warning), findsOneWidget);
      await tester.tap(find.text('취소'));
      await tester.pumpAndSettle();
      expect(pushedRoutes, isEmpty);

      await choose(tester, '주변 기기로 보내기');
      await tester.tap(find.text('확인'));
      await tester.pumpAndSettle();
      expect(pushedRoutes, [AppRoutes.nearbySend]);
    });
  });
}

class _FakePackagePort implements WorldCupPackagePort {
  int sharedCount = 0;

  @override
  Future<void> share(
    WorldCupModel model, {
    ShareOrigin? origin,
    required String title,
    required String subject,
  }) async {
    sharedCount++;
  }

  @override
  Future<String> createPackage(WorldCupModel model) =>
      throw UnimplementedError();

  @override
  Future<ImportedWorldCup> importPackage(String packagePath) =>
      throw UnimplementedError();
}
