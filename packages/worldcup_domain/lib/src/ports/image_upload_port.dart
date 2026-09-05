import '../entities/worldcup_item_model.dart';

/// 항목 이미지를 외부 호스팅에 올리고 공개 URL을 얻는 포트.
///
/// 결과 공유용 썸네일을 만들 때 쓴다.
///
/// 이미지가 에셋인지 파일인지 판별하고, 읽어서 인코딩하는 일까지 전부 구현
/// 쪽에 둔다. 그래야 UI가 `dart:io`나 `rootBundle`을 알 필요가 없고, feature
/// 패키지가 데이터 레이어에 의존하지 않아도 된다.
abstract interface class ImageUploadPort {
  /// 항목 이미지를 올리고 썸네일 URL을 돌려준다.
  ///
  /// 업로드는 됐지만 URL을 얻지 못하면 `null`을 돌려준다.
  /// 실패하면 `NetworkFailure`를 던진다.
  Future<String?> uploadItemImage(WorldCupItemModel item);
}
