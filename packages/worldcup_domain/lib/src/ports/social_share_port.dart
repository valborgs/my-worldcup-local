/// 소셜 메신저로 결과를 공유하는 포트.
///
/// 메신저 SDK의 템플릿 타입이 UI까지 새어나오지 않도록, 필요한 값만
/// 평범한 문자열로 받는다.
abstract interface class SocialSharePort {
  /// 공유를 실행하고 실제로 공유 화면이 열렸는지 돌려준다.
  Future<bool> shareFeed({
    required String title,
    required String description,
    required String imageUrl,
    required String linkUrl,
  });
}
