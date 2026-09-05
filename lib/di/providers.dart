/// 앱의 유일한 조립 지점.
///
/// 도메인 포트를 데이터 레이어 구현에 묶는 일은 여기서만 한다. 화면과 위젯은
/// 구현체를 직접 만들지 않고 이 provider들을 통해 받는다. 테스트는
/// `ProviderScope(overrides: [...])`로 원하는 구현을 끼운다.
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

final worldCupRepositoryProvider = Provider<WorldCupRepository>((ref) {
  return SqliteWorldCupRepository(ref.watch(appDatabaseProvider));
});

final worldCupPackageProvider = Provider<WorldCupPackagePort>((ref) {
  return WorldCupPackageRepository(
    repository: ref.watch(worldCupRepositoryProvider),
  );
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

final imageUploadProvider = Provider<ImageUploadPort>((ref) {
  return ImgbbImageUploader(apiKey: dotenv.env['imgbb_apiKey'] ?? '');
});

final socialShareProvider = Provider<SocialSharePort>((ref) {
  return const KakaoShareAdapter();
});

final adUnitProvider = Provider<AdUnitPort>((ref) {
  return AdMobAdUnits.resolve(
    isAndroid: defaultTargetPlatform == TargetPlatform.android,
    isRelease: kReleaseMode,
    config: (key) => dotenv.env[key],
  );
});

final featureFlagProvider = Provider<FeatureFlagPort>((ref) {
  return FirebaseFeatureFlags(
    // 디버그에서는 플래그 변경을 빨리 확인할 수 있게 간격을 줄인다.
    minimumFetchInterval: kDebugMode
        ? const Duration(minutes: 5)
        : const Duration(hours: 12),
  );
});

/// 결과 화면에서 공유 링크로 쓰는 플레이스토어 주소.
final playStoreUrlProvider = Provider<String>((ref) {
  return dotenv.env['playstore_url'] ?? '';
});
