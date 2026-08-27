// 결승전에서 bottom 아이템이 선택되지 않던 버그의 회귀 테스트.
//
// 원인: GameItem은 위젯 key로 WorldCupItemModel.idx만 사용한다. 새 라운드가
// 시작될 때 이전 라운드에서 승리(탭)한 항목이 "같은 위치(top 또는 bottom)"에
// 다시 배치되면, Flutter의 위젯 트리 재조정(reconciliation)이 idx가 같은
// 이전 State를 그대로 재사용한다. 예전에는 탭 가능 여부를 GameItem의 로컬
// State(_isTouchable)로 관리했기 때문에, 재사용된 State는 이미 탭 완료
// 상태였고 다시 탭해도 반응하지 않았다.
//
// 수정: 탭 가능 여부의 단일 기준을 WorldCupSelectProvider(hasSelected)로
// 옮기고, WorldCupGame.setGame()이 매 대결 시작 시점에 명시적으로
// resetSelection()을 호출하도록 했다. 이제 탭 가능 여부가 특정 GameItem
// 위젯 인스턴스의 생존 여부(Flutter의 key 재사용 여부)에 더 이상 좌우되지
// 않는다.
//
// itemModel.worldCupIdx(샘플 vs 사용자 등록 데이터 구분)와 무관하게 동일한
// key/상태 로직이 사용되므로, 샘플 항목(Image.asset)과 사용자 등록(파일
// 기반, Image.file) 항목을 섞어서 검증한다.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:my_worldcup_local/models/worldcup_item_model.dart';
import 'package:my_worldcup_local/models/worldcup_model.dart';
import 'package:my_worldcup_local/provider/worldcup_select_provider.dart';
import 'package:my_worldcup_local/widgets/game_item.dart';
import 'package:my_worldcup_local/widgets/worldcup_game.dart';

void main() {
  // idx < 0 : 샘플 월드컵 항목 (Image.asset 경로)
  // idx >= 0 : 사용자가 직접 추가한(실제) 월드컵 항목 (Image.file 경로).
  // 테스트는 저장소 루트에서 실행되므로 아래 상대경로의 실제 파일이 존재한다.
  final itemA =
      WorldCupItemModel(1, 'assets/sample/female/aespa_carina.jpg', 'A', -1);
  final itemB =
      WorldCupItemModel(2, 'assets/sample/female/babymon_ahyun.jpg', 'B', 101);
  final itemC = WorldCupItemModel(3, 'assets/sample/female/chu.jpg', 'C', -1);

  test('WorldCupModel은 DB 저장 후 날짜를 밀리초 정밀도로 복원한다', () {
    final date = DateTime(2026, 8, 26, 12, 34, 56, 789);
    final original = WorldCupModel(1, '제목', '설명', date, 'image.jpg', 16);
    final dbRow = <String, dynamic>{'idx': 1, ...original.toMap()};

    final restored = WorldCupModel.fromDB(dbRow);

    expect(restored.date, date);
  });

  testWidgets(
    '직전 대결에서 탭했던 항목이 같은 위치(top/bottom)로 다음 대결에 재배치되어도 '
    '(GameItem State가 재사용되어도) 다시 정상적으로 선택할 수 있다',
    (WidgetTester tester) async {
      final selectProvider = WorldCupSelectProvider();

      Widget buildRound(WorldCupItemModel top, WorldCupItemModel bottom) {
        return MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider<WorldCupSelectProvider>.value(
              value: selectProvider,
              // WorldCupGame.build와 동일한 구조: Flex 안에 top/bottom GameItem을
              // idx 기반 ValueKey로 배치한다.
              child: Row(
                children: [
                  GameItem(top,
                      key: ValueKey(top.idx),
                      position: SelectedItemPosition.top,
                      axis: Axis.horizontal,
                      matchId: top.idx),
                  GameItem(bottom,
                      key: ValueKey(bottom.idx),
                      position: SelectedItemPosition.bottom,
                      axis: Axis.horizontal,
                      matchId: top.idx),
                ],
              ),
            ),
          ),
        );
      }

      // --- 대결 1: top=itemA, bottom=itemB ---
      await tester.pumpWidget(buildRound(itemA, itemB));

      await tester.tap(find.byKey(ValueKey(itemB.idx)));
      await tester.pump();

      expect(selectProvider.selectedModel.idx, itemB.idx);
      expect(selectProvider.hasSelected, isTrue);

      // WorldCupGame.setGame()이 매 대결 시작 시 수행하는 것과 동일하게,
      // 다음 대결을 시작하기 전에 선택 상태를 초기화한다.
      selectProvider.resetSelection();

      // --- 대결 2("결승"): top=itemC(새 항목), bottom=itemB(직전 승자, 같은 슬롯 재배치) ---
      // 실제 게임에서는 nowList.removeLast() 두 번으로 이 배치가 결정되며,
      // 셔플 결과에 따라 직전 승자가 다시 bottom 슬롯에 놓이는 경우가 흔히 발생한다.
      // GameItem의 key(idx=2)가 직전 대결과 동일하므로 Flutter는 이전 State를
      // 재사용하지만, 탭 가능 여부는 더 이상 그 State에 저장되어 있지 않다.
      await tester.pumpWidget(buildRound(itemC, itemB));
      await tester.pump();

      await tester.tap(find.byKey(ValueKey(itemB.idx)));
      await tester.pump();

      expect(
        selectProvider.hasSelected,
        isTrue,
        reason: '이전에는 재사용된 GameItem State의 _isTouchable이 false로 남아있어 '
            '이 탭이 무시되었다(버그 재현 조건). 수정 후에는 정상적으로 선택되어야 한다.',
      );
      expect(selectProvider.selectedModel.idx, itemB.idx);
    },
  );

  testWidgets(
    '실제 WorldCupGame 위젯에서 여러 라운드에 걸쳐 매 대결마다 탭이 정상 동작한다 '
    '(setGame()이 매번 선택 상태를 초기화하는지 확인)',
    (WidgetTester tester) async {
      // 8강으로 시작해서 4강까지, 즉 실제 결승(2강) 진입 직전까지 총 6번의
      // 대결을 정상적으로 진행할 수 있는지 확인한다. 결승 탭까지 진행하면
      // 결과 화면으로 네비게이션되며 광고 플러그인 호출이 발생하므로
      // (테스트 환경에서 목킹되어 있지 않음) 여기서는 그 직전까지만 검증한다.
      final items = [
        itemA,
        itemB,
        itemC,
        WorldCupItemModel(4, 'assets/sample/male/and2ble_yujin.jpg', 'D', 102),
        WorldCupItemModel(5, 'assets/sample/male/astro_cha.jpg', 'E', -1),
        WorldCupItemModel(6, 'assets/sample/male/bnd_myung.jpg', 'F', 103),
        WorldCupItemModel(7, 'assets/sample/female/aespa_carina.jpg', 'G', -1),
        WorldCupItemModel(
            8, 'assets/sample/female/babymon_ahyun.jpg', 'H', 104),
      ];
      final worldCupModel =
          WorldCupModel(1, '테스트 월드컵', '', DateTime(2026, 1, 1), '', 8);
      final selectProvider = WorldCupSelectProvider();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider<WorldCupSelectProvider>.value(
              value: selectProvider,
              child: WorldCupGame(worldCupModel, items, 8),
            ),
          ),
        ),
      );

      // 8강(4경기) + 4강(2경기) = 총 6경기를 진행한다. 이후 2강(결승) 직전에서 멈춘다.
      for (var match = 0; match < 6; match++) {
        final bottomFinder = find.byWidgetPredicate(
          (w) => w is GameItem && w.position == SelectedItemPosition.bottom,
        );
        expect(bottomFinder, findsOneWidget,
            reason: 'match $match: bottom 항목을 찾을 수 없다');

        await tester.tap(bottomFinder);
        await tester.pump();

        expect(
          selectProvider.hasSelected,
          isTrue,
          reason: 'match $match: bottom 항목을 탭했지만 선택이 등록되지 않았다',
        );

        final inputBlockerFinder = find.byWidgetPredicate(
          (widget) => widget is IgnorePointer && widget.child is Flex,
        );
        final inputBlocker = tester.widget<IgnorePointer>(inputBlockerFinder);
        expect(
          inputBlocker.ignoring,
          isTrue,
          reason: 'match $match: 선택 직후 추가 포인터 입력을 차단해야 한다',
        );

        // 전환 대기 중 빠르게 다시 탭해도 새 제스처가 처리되지 않아야 한다.
        await tester.tap(bottomFinder, warnIfMissed: false);
        await tester.tap(bottomFinder, warnIfMissed: false);
        await tester.pump();

        // 3초 지연 후 다음 대결(setGame)로 넘어간다.
        await tester.pump(const Duration(seconds: 4));

        expect(
          tester.widget<IgnorePointer>(inputBlockerFinder).ignoring,
          isFalse,
          reason: 'match $match: 다음 대결에서는 입력 잠금을 해제해야 한다',
        );

        // 직전 승자가 동일한 key와 위치로 재사용되더라도 선택 애니메이션의
        // 이동값이 결승을 포함한 다음 대결에 남아 있으면 안 된다.
        final transitions = tester.widgetList<SlideTransition>(
          find.byType(SlideTransition),
        );
        expect(
          transitions
              .every((transition) => transition.position.value == Offset.zero),
          isTrue,
          reason: 'match $match: 다음 대결에 직전 슬라이드 offset이 남아 있다',
        );
      }
    },
  );
}
