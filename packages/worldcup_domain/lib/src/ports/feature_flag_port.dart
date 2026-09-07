/// 원격 기능 플래그 포트.
///
/// 원격 설정을 가져오지 못하면 예외를 던지지 않고 [defaultValue]를 돌려준다.
/// 플래그 조회 실패로 앱이 뜨지 못하는 상황을 막기 위해서다.
abstract interface class FeatureFlagPort {
  Future<bool> getBool(String key, {required bool defaultValue});

  Future<int> getInt(String key, {required int defaultValue});
}

/// 앱에서 쓰는 플래그 키.
abstract final class FeatureFlags {
  /// 바텀시트에서 항목을 고를 때 페이저 전환 애니메이션을 쓸지 여부.
  static const bottomSheetSelectionPagerTransition =
      'enableBottomSheetSelectionPagerTransition';
  static const bottomSheetSelectionPagerTransitionDefault = true;

  /// 이 versionCode 미만으로 설치된 앱은 즉시(강제) 업데이트로 올린다.
  ///
  /// Play의 `updatePriority`는 Play Console 화면에서 넣을 수 없고 Publishing
  /// API로만 지정할 수 있으며, 한 번 롤아웃하면 바꾸지도 못한다. 이 앱은
  /// aab를 손으로 올리므로 그 값이 늘 0으로 내려온다. 그래서 "이 버전은
  /// 중요하다"는 판단을 Remote Config로 따로 내려준다.
  ///
  /// 릴리스한 뒤에 마음을 바꿀 수 있는 것도 이 방식의 이점이다.
  /// 심각한 버그가 배포 다음 날 드러나는 쪽이 더 흔하다.
  ///
  /// 기본값 0은 "아무도 강제하지 않는다"는 뜻이다. 원격 설정을 못 읽었을 때
  /// 사용자를 잠그지 않도록 일부러 안전한 쪽으로 열어 둔다.
  static const minRequiredVersionCode = 'minRequiredVersionCode';
  static const minRequiredVersionCodeDefault = 0;
}
