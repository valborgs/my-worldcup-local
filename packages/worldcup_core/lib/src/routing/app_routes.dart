/// 화면 이동 계약.
///
/// feature 패키지끼리는 서로를 import 하지 않는다. 대신 이 라우트 이름과
/// [route_args.dart]의 인자 타입만 공유하고, 실제 위젯 바인딩은 앱 셸의
/// `onGenerateRoute`가 소유한다. 덕분에 목록 화면이 게임 화면을 알지 못해도
/// 게임 화면으로 이동할 수 있다.
abstract final class AppRoutes {
  /// 월드컵 목록 (앱 시작 화면).
  static const list = '/';

  /// 앱 소개 / 도움말. 목록 화면에서 다시 열어 보는 용도라 닫으면 pop 한다.
  static const help = '/help';

  /// 첫 실행 온보딩. [help]와 화면은 같지만 끝나면 [list]로 replace 한다.
  ///
  /// 온보딩을 [list]('/')의 `home`으로 두면 안 된다. `WidgetsApp`은 `home`이
  /// 있으면 '/'를 무조건 `home`으로 해석하고 앱의 `onGenerateRoute`를 거치지
  /// 않는다. 그러면 온보딩이 끝나며 '/'로 replace 해도 온보딩이 다시 열려
  /// 첫 실행에서 빠져나갈 수 없다.
  static const onboarding = '/onboarding';

  /// 월드컵 생성 및 수정. 인자: [EditorArgs].
  static const editor = '/worldcup/editor';

  /// 월드컵 게임 진행. 인자: [PlayArgs].
  static const play = '/worldcup/play';

  /// 주변 기기로 보내기. 인자: [NearbySendArgs].
  static const nearbySend = '/share/nearby/send';

  /// 주변 기기에서 받기. 인자 없음.
  static const nearbyReceive = '/share/nearby/receive';

  /// 선언된 모든 라우트 이름.
  ///
  /// 새 라우트를 추가하면 여기에도 넣는다. 앱의 라우터 테스트가 이 목록을
  /// 돌면서 전부 화면을 만드는지 확인하므로, 이름만 선언하고 라우터에
  /// 연결하지 않는 실수를 잡아준다.
  static const all = <String>[
    list,
    help,
    onboarding,
    editor,
    play,
    nearbySend,
    nearbyReceive,
  ];
}
