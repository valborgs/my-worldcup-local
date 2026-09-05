/// 화면 이동 계약.
///
/// feature 패키지끼리는 서로를 import 하지 않는다. 대신 이 라우트 이름과
/// [route_args.dart]의 인자 타입만 공유하고, 실제 위젯 바인딩은 앱 셸의
/// `onGenerateRoute`가 소유한다. 덕분에 목록 화면이 게임 화면을 알지 못해도
/// 게임 화면으로 이동할 수 있다.
abstract final class AppRoutes {
  /// 월드컵 목록 (앱 시작 화면).
  static const list = '/';

  /// 앱 소개 / 도움말.
  static const help = '/help';

  /// 월드컵 생성 및 수정. 인자: [EditorArgs].
  static const editor = '/worldcup/editor';

  /// 월드컵 게임 진행. 인자: [PlayArgs].
  static const play = '/worldcup/play';

  /// 게임 결과. 인자: [ResultArgs].
  static const result = '/worldcup/result';

  /// 주변 기기로 보내기. 인자: [NearbySendArgs].
  static const nearbySend = '/share/nearby/send';

  /// 주변 기기에서 받기. 인자 없음.
  static const nearbyReceive = '/share/nearby/receive';
}
