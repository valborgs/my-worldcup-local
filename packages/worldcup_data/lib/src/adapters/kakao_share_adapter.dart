import 'package:kakao_flutter_sdk_share/kakao_flutter_sdk_share.dart';
import 'package:worldcup_core/worldcup_core.dart';
import 'package:worldcup_domain/worldcup_domain.dart';

/// 카카오톡 기반 [SocialSharePort] 구현.
///
/// 카카오 SDK의 `FeedTemplate`이 UI로 새어나가지 않도록 이 어댑터 안에서만
/// 다룬다.
class KakaoShareAdapter implements SocialSharePort {
  static const String _buttonTitle = '내가 만든 월드컵 게임 체험하기';

  /// 공유 카드와 버튼이 여는 주소. 보통 스토어 링크다.
  final String linkUrl;

  final AppLogger _logger;

  const KakaoShareAdapter({
    required this.linkUrl,
    this._logger = const DeveloperLogger('kakao_share'),
  });

  @override
  Future<bool> shareFeed({
    required String title,
    required String description,
    required String imageUrl,
  }) async {
    final link = Link(
      webUrl: Uri.parse(linkUrl),
      mobileWebUrl: Uri.parse(linkUrl),
    );
    final template = FeedTemplate(
      content: Content(
        title: title,
        description: description,
        imageUrl: Uri.parse(imageUrl),
        link: link,
      ),
      buttons: [Button(title: _buttonTitle, link: link)],
    );

    // 카카오톡이 깔려 있으면 앱으로, 아니면 웹 공유로 넘어간다.
    final canShareViaApp = await ShareClient.instance
        .isKakaoTalkSharingAvailable();
    try {
      if (canShareViaApp) {
        final uri = await ShareClient.instance.shareDefault(template: template);
        await ShareClient.instance.launchKakaoTalk(uri);
      } else {
        final url = await WebSharerClient.instance.makeDefaultUrl(
          template: template,
        );
        await launchBrowserTab(url, popupOpen: true);
      }
      return true;
    } catch (error, stackTrace) {
      // 공유 실패는 앱을 멈출 이유가 아니다. 호출부가 false로 처리한다.
      _logger.error('카카오톡 공유 실패', error: error, stackTrace: stackTrace);
      return false;
    }
  }
}
