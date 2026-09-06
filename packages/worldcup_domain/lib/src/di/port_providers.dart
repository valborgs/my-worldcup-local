/// 도메인 포트를 가리키는 provider들.
///
/// 구현은 데이터 레이어에 있고, 둘을 잇는 일은 앱이 `ProviderScope`의
/// override로 한다. 선언이 도메인에 있어야 feature 패키지가 앱 패키지를
/// import 하지 않고도 의존성을 받을 수 있다.
///
/// 기본 구현은 일부러 예외를 던진다. override를 빠뜨리면 조용히 잘못
/// 동작하는 대신 즉시 드러나게 하기 위해서다.
library;

import 'package:riverpod/riverpod.dart';

import '../ports/ad_unit_port.dart';
import '../ports/image_upload_port.dart';
import '../ports/social_share_port.dart';
import '../ports/worldcup_package_port.dart';
import '../repositories/worldcup_repository.dart';

Never _missingOverride(String name) {
  throw UnimplementedError(
    '$name 이(가) override 되지 않았습니다. '
    '앱의 ProviderScope에서 데이터 레이어 구현으로 override 하세요.',
  );
}

final worldCupRepositoryProvider = Provider<WorldCupRepository>(
  (ref) => _missingOverride('worldCupRepositoryProvider'),
);

final worldCupPackageProvider = Provider<WorldCupPackagePort>(
  (ref) => _missingOverride('worldCupPackageProvider'),
);

final imageUploadProvider = Provider<ImageUploadPort>(
  (ref) => _missingOverride('imageUploadProvider'),
);

final socialShareProvider = Provider<SocialSharePort>(
  (ref) => _missingOverride('socialShareProvider'),
);

final adUnitProvider = Provider<AdUnitPort>(
  (ref) => _missingOverride('adUnitProvider'),
);
