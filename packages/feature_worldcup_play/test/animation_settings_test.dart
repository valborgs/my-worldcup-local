import 'dart:async';

import 'package:feature_worldcup_play/feature_worldcup_play.dart';
import 'package:feature_worldcup_play/src/widgets/selection_effect.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worldcup_ui_kit/worldcup_ui_kit.dart';

Widget app(Widget child) => MaterialApp(
  locale: const Locale('ko'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: child,
);

void main() {
  test('first launch uses classic; saved option is restored', () {
    final defaults = ProviderContainer();
    addTearDown(defaults.dispose);
    expect(
      defaults.read(selectionAnimationProvider),
      SelectionAnimation.classic,
    );
    final restored = ProviderContainer(
      overrides: [
        initialSelectionAnimationProvider.overrideWithValue(
          SelectionAnimation.option1,
        ),
      ],
    );
    addTearDown(restored.dispose);
    expect(
      restored.read(selectionAnimationProvider),
      SelectionAnimation.option1,
    );
  });

  test('saved name restores every option; unknown names fall back', () {
    for (final style in SelectionAnimation.values) {
      expect(selectionAnimationFromName(style.name), style);
    }
    expect(selectionAnimationFromName(null), SelectionAnimation.classic);
    expect(selectionAnimationFromName('removed'), SelectionAnimation.classic);
  });

  test('the next match never starts before the effect has finished', () {
    for (final style in SelectionAnimation.values) {
      for (final isFinal in [false, true]) {
        expect(
          style.matchDelay(isFinal: isFinal),
          greaterThanOrEqualTo(style.effectDuration(isFinal: isFinal)),
          reason: '${style.name} isFinal=$isFinal',
        );
      }
    }
  });

  testWidgets('every option is listed with its own title', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(child: app(const AnimationSettingsScreen())),
    );
    for (final title in ['기본값', '옵션 1', '옵션 2', '옵션 3', '옵션 4']) {
      expect(find.widgetWithText(ListTile, title), findsOneWidget);
    }
  });

  for (final style in [
    SelectionAnimation.option2,
    SelectionAnimation.option3,
    SelectionAnimation.option4,
  ]) {
    for (final winner in [false, true]) {
      testWidgets(
        '${style.name} ${winner ? 'winner' : 'loser'} effect renders through '
        'the whole animation',
        (tester) async {
          final controller = AnimationController(
            vsync: tester,
            duration: style.effectDuration(isFinal: false),
          );
          addTearDown(controller.dispose);
          await tester.pumpWidget(
            app(
              Scaffold(
                body: Center(
                  child: SizedBox(
                    width: 280,
                    height: 280,
                    child: SelectionEffect(
                      animation: controller,
                      style: style,
                      enabled: true,
                      winner: winner,
                      isFinal: false,
                      child: const ColoredBox(color: Colors.blue),
                    ),
                  ),
                ),
              ),
            ),
          );
          controller.forward();
          // 첫 pump는 ticker의 시작 시각만 잡으므로 가장 긴 효과(1100ms)보다
          // 넉넉히 돌린다.
          for (var i = 0; i < 14; i++) {
            await tester.pump(const Duration(milliseconds: 100));
            expect(tester.takeException(), isNull);
          }
          expect(controller.isCompleted, isTrue);
          // 진출 배지는 선택한 쪽에만 뜬다.
          expect(find.text('진출!'), winner ? findsOneWidget : findsNothing);
          expect(
            find.byIcon(Icons.check_circle),
            winner ? findsOneWidget : findsNothing,
          );
          // 탈락한 쪽은 끝날 때 완전히 사라져 있어야 한다.
          if (!winner) {
            final opacity = tester.widget<Opacity>(
              find.descendant(
                of: find.byType(SelectionEffect),
                matching: find.byType(Opacity),
              ),
            );
            expect(opacity.opacity, 0);
          }
        },
      );
    }
  }

  testWidgets(
    'selection waits for saving and persists across reopening the screen',
    (tester) async {
      final completion = Completer<void>();
      SelectionAnimation? saved;
      final container = ProviderContainer(
        overrides: [
          saveSelectionAnimationProvider.overrideWithValue((value) async {
            await completion.future;
            saved = value;
          }),
        ],
      );
      addTearDown(container.dispose);
      Widget settings() => UncontrolledProviderScope(
        container: container,
        child: app(const AnimationSettingsScreen()),
      );
      await tester.pumpWidget(settings());
      await tester.tap(find.text('옵션 1'));
      await tester.pump();
      expect(
        container.read(selectionAnimationProvider),
        SelectionAnimation.classic,
      );
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      completion.complete();
      await tester.pumpAndSettle();
      expect(saved, SelectionAnimation.option1);
      expect(
        container.read(selectionAnimationProvider),
        SelectionAnimation.option1,
      );
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(settings());
      expect(
        tester.widget<ListTile>(find.widgetWithText(ListTile, '옵션 1')).selected,
        isTrue,
      );
    },
  );

  testWidgets('failed save leaves previous choice and shows a retry message', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          saveSelectionAnimationProvider.overrideWithValue(
            (_) async => throw StateError('disk failure'),
          ),
        ],
        child: app(const AnimationSettingsScreen()),
      ),
    );
    await tester.tap(find.text('옵션 1'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<ListTile>(find.widgetWithText(ListTile, '기본값')).selected,
      isTrue,
    );
    expect(find.text('설정을 저장하지 못했습니다. 다시 시도해 주세요.'), findsOneWidget);
  });

  test(
    'late save after provider disposal does not update disposed state',
    () async {
      final completion = Completer<void>();
      final container = ProviderContainer(
        overrides: [
          saveSelectionAnimationProvider.overrideWithValue(
            (_) => completion.future,
          ),
        ],
      );
      final saving = container
          .read(selectionAnimationProvider.notifier)
          .select(SelectionAnimation.option1);
      container.dispose();
      completion.complete();
      await expectLater(saving, completes);
    },
  );

  for (final isFinal in [false, true]) {
    testWidgets(
      'option 1 ${isFinal ? 'champion spotlight' : 'advance badge'} renders',
      (tester) async {
        final controller = AnimationController(
          vsync: tester,
          duration: const Duration(seconds: 1),
        );
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          app(
            Scaffold(
              body: Center(
                child: SizedBox(
                  width: 280,
                  height: 280,
                  child: SelectionEffect(
                    animation: controller,
                    enabled: true,
                    winner: true,
                    isFinal: isFinal,
                    child: const ColoredBox(color: Colors.blue),
                  ),
                ),
              ),
            ),
          ),
        );
        controller.forward();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));
        expect(find.text(isFinal ? '우승!' : '진출!'), findsOneWidget);
        expect(
          find.byIcon(isFinal ? Icons.emoji_events : Icons.check_circle),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
        await tester.pumpAndSettle();
      },
    );
  }
}
