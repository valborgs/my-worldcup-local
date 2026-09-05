import 'package:worldcup_domain/worldcup_domain.dart';

/// AdMob 광고 단위 id를 제공하는 [AdUnitPort] 구현.
///
/// 예전 `AdHelper`는 static 게터에서 `Platform.isAndroid`와 `kReleaseMode`,
/// dotenv를 직접 읽어 테스트가 불가능했다. 지금은 필요한 값을 전부 생성자로
/// 받으므로 어떤 조합이든 테스트에서 만들 수 있다.
class AdMobAdUnits implements AdUnitPort {
  /// 구글이 공개한 테스트 광고 단위. 실제 id를 못 찾으면 이 값으로 떨어진다.
  static const String testBannerAndroid =
      'ca-app-pub-3940256099942544/9214589741';
  static const String testBannerIos = 'ca-app-pub-3940256099942544/2435281174';
  static const String testInterstitialAndroid =
      'ca-app-pub-3940256099942544/1033173712';
  static const String testInterstitialIos =
      'ca-app-pub-3940256099942544/4411468910';

  @override
  final String bannerAdUnitId;

  @override
  final String interstitialAdUnitId;

  const AdMobAdUnits({
    required this.bannerAdUnitId,
    required this.interstitialAdUnitId,
  });

  /// 플랫폼과 빌드 모드에 맞는 id를 [config]에서 고른다.
  ///
  /// [config]는 보통 dotenv에서 온다. 값이 없으면 구글 테스트 id를 쓴다.
  factory AdMobAdUnits.resolve({
    required bool isAndroid,
    required bool isRelease,
    required String? Function(String key) config,
  }) {
    final platform = isAndroid ? 'aos' : 'ios';
    final mode = isRelease ? 'release' : 'debug';

    final banner = config('admob_${platform}_${mode}UnitId');
    final interstitial = config('admob_interstitial_${platform}_${mode}UnitId');

    return AdMobAdUnits(
      bannerAdUnitId: banner ?? (isAndroid ? testBannerAndroid : testBannerIos),
      interstitialAdUnitId:
          interstitial ??
          (isAndroid ? testInterstitialAndroid : testInterstitialIos),
    );
  }
}
