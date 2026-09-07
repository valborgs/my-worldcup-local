/// Dart와 안드로이드 네이티브가 함께 지키는 채널 계약.
///
/// 모든 요청과 이벤트에 [version]을 실어 보내고 양쪽에서 검사한다.
/// 버전이 어긋난 채로 조용히 다른 뜻으로 해석되는 일을 막기 위해서다.
abstract final class InAppUpdateProtocol {
  static const int version = 1;

  static const String methodChannel =
      'org.comon.my_worldcup_local/in_app_update/methods';
  static const String eventChannel =
      'org.comon.my_worldcup_local/in_app_update/events';

  /// 업데이트 상태를 조회한다. 반환값은 [InAppUpdateInfo] 맵이다.
  static const String checkForUpdate = 'checkForUpdate';

  /// 유연한(Flexible) 업데이트 동의 흐름을 띄운다.
  /// 사용자가 선택을 끝낸 뒤에야 완료되고, 결과는 [InAppUpdateFlowResult]다.
  static const String startFlexibleUpdate = 'startFlexibleUpdate';

  /// 내려받기가 끝난 업데이트를 설치하고 앱을 재시작한다.
  static const String completeUpdate = 'completeUpdate';
}
