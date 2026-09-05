/// 도메인 포트를 데이터 레이어 구현에 묶는 유일한 곳.
///
/// 포트 provider의 **선언**은 worldcup_domain에 있다. feature 패키지가
/// 앱 패키지를 import 하지 않고도 의존성을 받으려면 선언이 공통 계층에
/// 있어야 하기 때문이다. 여기서는 그 선언들을 실제 구현으로 override 한다.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worldcup_data/worldcup_data.dart';
import 'package:worldcup_domain/worldcup_domain.dart';

/// 샘플 월드컵 시드 JSON의 에셋 경로.
///
/// 에셋은 앱 패키지에 남겨둔다. 패키지로 옮기면 참조 경로가
/// `packages/worldcup_data/...`로 바뀌는데, 이 경로 문자열이 사용자 기기의
/// SQLite에 그대로 저장되어 있어 건드리면 위험하다.
const String _sampleManifestAsset = 'assets/sample/sample_worldcups.json';

/// SQLite 연결. 앱 전체에서 하나만 존재한다.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(database.close);
  return database;
});

final sampleWorldCupSeederProvider = Provider<SampleWorldCupSeeder>((ref) {
  return SampleWorldCupSeeder(
    database: ref.watch(appDatabaseProvider),
    manifestLoader: () => rootBundle.loadString(_sampleManifestAsset),
  );
});

/// 페이징 UI 확인용 개발 전용 시더. 릴리스 빌드에서는 호출하지 않는다.
final testWorldCupSeederProvider = Provider<TestWorldCupSeeder>((ref) {
  return TestWorldCupSeeder(ref.watch(appDatabaseProvider));
});

/// 도메인 포트 -> 데이터 레이어 구현 바인딩.
///
/// `ProviderScope`(또는 `ProviderContainer`)의 `overrides`에 그대로 넘긴다.
///
/// 반환 타입을 적지 않고 추론에 맡긴다. Riverpod 3은 `Override` 타입을
/// 공개 export 하지 않아 이름으로 쓸 수 없다.
final portOverrides = [
  worldCupRepositoryProvider.overrideWith(
    (ref) => SqliteWorldCupRepository(ref.watch(appDatabaseProvider)),
  ),
  worldCupPackageProvider.overrideWith(
    (ref) => WorldCupPackageRepository(
      repository: ref.watch(worldCupRepositoryProvider),
    ),
  ),
  imageUploadProvider.overrideWith(
    (ref) => ImgbbImageUploader(apiKey: dotenv.env['imgbb_apiKey'] ?? ''),
  ),
  socialShareProvider.overrideWith(
    (ref) => KakaoShareAdapter(linkUrl: dotenv.env['playstore_url'] ?? ''),
  ),
  adUnitProvider.overrideWith(
    (ref) => AdMobAdUnits.resolve(
      isAndroid: defaultTargetPlatform == TargetPlatform.android,
      isRelease: kReleaseMode,
      config: (key) => dotenv.env[key],
    ),
  ),
  featureFlagProvider.overrideWith(
    (ref) => FirebaseFeatureFlags(
      // 디버그에서는 플래그 변경을 빨리 확인할 수 있게 간격을 줄인다.
      minimumFetchInterval: kDebugMode
          ? const Duration(minutes: 5)
          : const Duration(hours: 12),
    ),
  ),
];

/// 원격 기능 플래그. 앱 부팅에서만 쓰이므로 앱 계층에 둔다.
final featureFlagProvider = Provider<FeatureFlagPort>((ref) {
  throw UnimplementedError('buildPortOverrides()로 override 해야 합니다.');
});
