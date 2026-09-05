/// 광고 단위 id를 제공하는 포트.
///
/// 플랫폼 분기와 디버그 / 릴리스 분기를 어댑터 안에 가둔다.
abstract interface class AdUnitPort {
  String get bannerAdUnitId;

  String get interstitialAdUnitId;
}
