import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_worldcup_local/app_router.dart';
import 'package:worldcup_core/worldcup_core.dart';

/// 라우팅 계약이 화면 간 직접 참조를 대신하므로, 이름 하나가 빠지면
/// 런타임에야 드러난다. 여기서 계약을 지킨다.
void main() {
  const router = AppRouter(enableBottomSheetSelectionPagerTransition: true);

  Route<dynamic>? generate(String name, [Object? arguments]) {
    return router.onGenerateRoute(
      RouteSettings(name: name, arguments: arguments),
    );
  }

  test('선언된 모든 라우트 이름이 화면을 만든다', () {
    final cases = <String, Object?>{
      AppRoutes.list: null,
      AppRoutes.help: null,
      AppRoutes.editor: const EditorArgs(),
      AppRoutes.play: const PlayArgs(worldCupId: 1, round: 8),
      AppRoutes.nearbySend: const NearbySendArgs(worldCupId: 1),
      AppRoutes.nearbyReceive: null,
    };

    for (final entry in cases.entries) {
      expect(
        generate(entry.key, entry.value),
        isNotNull,
        reason: '${entry.key} 라우트가 처리되지 않았다',
      );
    }
  });

  test('모르는 이름은 null을 돌려준다', () {
    expect(generate('/이런건-없다'), isNull);
  });

  test('편집기는 인자 없이도 새로 만들기로 열린다', () {
    // 목록 화면의 "추가"는 EditorArgs()를, 다이얼로그의 "수정"은
    // worldCupId를 넘긴다. 둘 다 같은 라우트를 쓴다.
    expect(generate(AppRoutes.editor), isNotNull);
    expect(
      generate(AppRoutes.editor, const EditorArgs(worldCupId: 7)),
      isNotNull,
    );
  });

  test('편집기 라우트는 새 월드컵 id(int)를 결과로 돌려준다', () {
    // 목록 화면이 pushNamed<int>로 받아 새 항목으로 스크롤한다.
    expect(generate(AppRoutes.editor), isA<Route<int>>());
  });

  test('라우트가 원래 settings를 유지한다', () {
    // popUntil이나 라우트 관찰에서 이름으로 식별할 수 있어야 한다.
    final route = generate(
      AppRoutes.play,
      const PlayArgs(worldCupId: 3, round: 4),
    );
    expect(route!.settings.name, AppRoutes.play);
  });

  test('전체 화면 다이얼로그로 열려야 하는 라우트', () {
    for (final name in [
      AppRoutes.help,
      AppRoutes.nearbySend,
      AppRoutes.nearbyReceive,
    ]) {
      final route = generate(
        name,
        name == AppRoutes.nearbySend
            ? const NearbySendArgs(worldCupId: 1)
            : null,
      );
      expect(
        (route! as MaterialPageRoute).fullscreenDialog,
        isTrue,
        reason: '$name 은 전체 화면 다이얼로그여야 한다',
      );
    }
  });
}
