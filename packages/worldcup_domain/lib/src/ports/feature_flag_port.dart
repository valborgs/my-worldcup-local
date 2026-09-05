/// 원격 기능 플래그 포트.
///
/// 원격 설정을 가져오지 못하면 예외를 던지지 않고 [defaultValue]를 돌려준다.
/// 플래그 조회 실패로 앱이 뜨지 못하는 상황을 막기 위해서다.
abstract interface class FeatureFlagPort {
  Future<bool> getBool(String key, {required bool defaultValue});
}

/// 앱에서 쓰는 플래그 키.
abstract final class FeatureFlags {
  /// 바텀시트에서 항목을 고를 때 페이저 전환 애니메이션을 쓸지 여부.
  static const bottomSheetSelectionPagerTransition =
      'enableBottomSheetSelectionPagerTransition';
  static const bottomSheetSelectionPagerTransitionDefault = true;
}
