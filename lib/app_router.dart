import 'package:flutter/material.dart';
import 'package:worldcup_core/worldcup_core.dart';
import 'package:feature_worldcup_editor/feature_worldcup_editor.dart';
import 'package:feature_worldcup_list/feature_worldcup_list.dart';
import 'package:feature_worldcup_play/feature_worldcup_play.dart';
import 'package:feature_worldcup_share/feature_worldcup_share.dart';
import 'package:worldcup_domain/worldcup_domain.dart';

import 'screens/help_screen.dart';

/// 라우트 이름을 실제 화면에 묶는 유일한 곳.
///
/// 화면들은 서로를 직접 생성하지 않고 `AppRoutes`의 이름으로만 이동한다.
/// 덕분에 목록 화면이 게임 화면을 몰라도 게임을 시작할 수 있고, 화면들이
/// 각자 다른 feature 패키지로 갈라져도 서로를 import 하지 않는다.
class AppRouter {
  /// 원격 설정으로 켜고 끄는 바텀시트 페이저 전환 애니메이션 여부.
  ///
  /// 아직 화면 생성자를 통해 내려보낸다. 이후 단계에서 DI로 옮긴다.
  final bool enableBottomSheetSelectionPagerTransition;

  const AppRouter({required this.enableBottomSheetSelectionPagerTransition});

  Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.list:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => MainWorldCupScreen(
            enableBottomSheetSelectionPagerTransition:
                enableBottomSheetSelectionPagerTransition,
          ),
        );

      case AppRoutes.help:
        return MaterialPageRoute<void>(
          settings: settings,
          fullscreenDialog: true,
          builder: (_) => HelpScreen(
            false,
            enableBottomSheetSelectionPagerTransition:
                enableBottomSheetSelectionPagerTransition,
          ),
        );

      case AppRoutes.editor:
        final args = settings.arguments as EditorArgs?;
        return MaterialPageRoute<int>(
          settings: settings,
          fullscreenDialog: args?.isNew ?? true,
          builder: (_) => AddWorldCupScreen(editWorldCupId: args?.worldCupId),
        );

      case AppRoutes.play:
        final args = settings.arguments as PlayArgs;
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => PlayWorldCupScreen(args.worldCupId, args.round),
        );

      case AppRoutes.nearbySend:
        final args = settings.arguments as NearbySendArgs;
        return MaterialPageRoute<void>(
          settings: settings,
          fullscreenDialog: true,
          builder: (_) => NearbyWorldCupSendScreen(worldCupId: args.worldCupId),
        );

      case AppRoutes.nearbyReceive:
        return MaterialPageRoute<ImportedWorldCup>(
          settings: settings,
          fullscreenDialog: true,
          builder: (_) => const NearbyWorldCupReceiveScreen(),
        );
    }
    return null;
  }
}
