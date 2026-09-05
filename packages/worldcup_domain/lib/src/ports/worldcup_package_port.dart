import 'package:worldcup_core/worldcup_core.dart';

import '../entities/worldcup_model.dart';

/// 가져오기에 성공한 월드컵의 요약.
class ImportedWorldCup {
  final int idx;
  final String title;

  const ImportedWorldCup({required this.idx, required this.title});
}

/// 월드컵을 하나의 `.myworldcup` 파일로 묶고 푸는 포트.
///
/// 실패는 `PackageFailure`로 던진다. 파일은 경로(String)로 주고받는다.
/// `dart:io`의 `File`을 노출하면 도메인이 파일 시스템에 묶인다.
abstract interface class WorldCupPackagePort {
  /// 시스템 공유 시트로 내보낸다.
  ///
  /// [origin]은 iPad에서 팝오버를 띄울 화면상 위치다.
  Future<void> share(WorldCupModel model, {ShareOrigin? origin});

  /// 패키지 파일을 만들고 그 경로를 돌려준다.
  Future<String> createPackage(WorldCupModel model);

  /// 패키지 파일을 읽어 저장소에 넣는다.
  Future<ImportedWorldCup> importPackage(String packagePath);
}

/// `.myworldcup` 공유 파일의 형식 상수.
///
/// 파일 선택기의 확장자 필터처럼 UI에서도 필요하므로 도메인에 둔다.
/// feature 패키지는 데이터 레이어에 의존하지 않기 때문이다.
abstract final class WorldCupPackageFormat {
  static const String fileExtension = 'myworldcup';
  static const String mimeType = 'application/vnd.org.comon.my-worldcup+zip';
}
