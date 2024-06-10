import 'package:kakao_flutter_sdk_share/kakao_flutter_sdk_share.dart';

// DefaultTemplate으로 메시지 만드는 함수
Future<FeedTemplate> makeFeedTemplate(String title, String description, String imageUrl, String linkUrl) async {

  return FeedTemplate(
    content: Content(
      title: title,
      description: description,
      imageUrl: await getUrlFromStorage(),
      link: Link(
          webUrl: Uri.parse(linkUrl),
          mobileWebUrl: Uri.parse(linkUrl)),
    ),
    buttons: [
      Button(
        title: '월드컵 게임 체험하기',
        link: Link(
          androidExecutionParams: {'key1': 'value1', 'key2': 'value2'},
          iosExecutionParams: {'key1': 'value1', 'key2': 'value2'},
        ),
      ),
    ],
  );
}

// 카카오톡 실행 가능 여부 확인 후 공유 실행
Future<bool> sendFeed(FeedTemplate myTemplate) async {
  var result = false;

  bool isKakaoTalkSharingAvailable = await ShareClient.instance.isKakaoTalkSharingAvailable();

  if (isKakaoTalkSharingAvailable) {
    try {
      Uri uri =
      await ShareClient.instance.shareDefault(template: myTemplate);
      await ShareClient.instance.launchKakaoTalk(uri);
      result = true;
    } catch (error) {
      print('카카오톡 공유 실패 $error');
      result = false;
    }
  } else {
    try {
      Uri shareUrl = await WebSharerClient.instance
          .makeDefaultUrl(template: myTemplate);
      await launchBrowserTab(shareUrl, popupOpen: true);
      result = true;
    } catch (error) {
      print('카카오톡 공유 실패 $error');
      result = false;
    }
  }

  return result;
}