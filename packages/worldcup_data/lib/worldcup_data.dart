/// worldcup_data 공개 API.
///
/// worldcup_domain이 선언한 포트의 구현체를 제공한다.
/// 앱 셸(DI)만 이 패키지에 의존한다. feature 패키지는 의존하지 않는다.
library;

export 'src/adapters/admob_ad_units.dart';
export 'src/adapters/firebase_feature_flags.dart';
export 'src/adapters/imgbb_image_uploader.dart';
export 'src/adapters/kakao_share_adapter.dart';
export 'src/database/app_database.dart';
export 'src/dto/worldcup_row.dart';
export 'src/repositories/sqlite_worldcup_repository.dart';
export 'src/repositories/worldcup_package_repository.dart';
export 'src/seed/sample_worldcup_seeder.dart';
export 'src/seed/test_worldcup_seeder.dart';
