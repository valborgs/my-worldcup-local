/// 사용자가 고른 사진에서 메타데이터를 걷어낸 사본을 만드는 포트.
///
/// 카메라나 갤러리 원본에는 촬영 위치(GPS), 기기 정보, 촬영 시각 같은
/// EXIF가 들어 있다. 월드컵 사진은 공유 파일(.myworldcup)에 담겨 다른
/// 사람에게 가고, 결과 공유 때는 외부 호스팅에도 올라간다. 그래서 앱에
/// 저장하기 전에 한 번 걸러 둔다.
abstract interface class ImageMetadataPort {
  /// [sourcePath] 이미지를 다시 인코딩해 메타데이터가 없는 사본을 앱
  /// 저장공간에 만들고 그 경로를 돌려준다.
  ///
  /// 이미 이 포트가 만든 사본이면 그대로 돌려준다.
  /// 읽거나 변환하지 못하면 `StorageFailure`를 던진다. 원본을 대신
  /// 돌려주지 않는다. 메타데이터가 남은 사진이 조용히 저장되면 안 된다.
  Future<String> stripMetadata(String sourcePath);

  /// [stripMetadata]가 만든 사본 [path]를 지운다.
  ///
  /// 항목에 쓰이지 않게 된 사본을 바로 정리할 때 쓴다. 이 포트가 만든
  /// 사본이 아니면 아무것도 하지 않으며, 지우지 못해도 던지지 않는다.
  Future<void> discard(String path);
}
