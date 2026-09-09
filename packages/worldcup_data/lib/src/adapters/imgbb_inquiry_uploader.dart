import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:worldcup_domain/worldcup_domain.dart';

class ImgbbInquiryUploader implements InquiryImageUploadPort {
  final String apiKey;
  final http.Client _client;
  final Duration timeout;
  ImgbbInquiryUploader({
    required this.apiKey,
    http.Client? client,
    this.timeout = const Duration(seconds: 45),
  }) : _client = client ?? http.Client();

  void close() => _client.close();

  @override
  Future<String> uploadScreenshot(Uint8List bytes) async {
    if (apiKey.trim().isEmpty) {
      throw const SupportFailure(
        'image_configuration',
        '이미지 업로드 설정이 준비되지 않았습니다.',
      );
    }
    try {
      final request =
          http.Request('POST', Uri.https('api.imgbb.com', '/1/upload'))
            ..followRedirects = false
            ..bodyFields = {
              'key': apiKey,
              'image': base64Encode(bytes),
              'expiration': '259200',
            };
      final response = await _client
          .send(request)
          .then(http.Response.fromStream)
          .timeout(timeout);
      if (response.statusCode != 200) throw const FormatException();
      final json =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      // Full image rather than data.thumb.url, so text in screenshots is readable.
      final url = (json['data'] as Map<String, dynamic>)['url'] as String;
      final uri = Uri.parse(url);
      if (url.length > 2048 ||
          uri.scheme != 'https' ||
          uri.host != 'i.ibb.co' ||
          uri.userInfo.isNotEmpty ||
          (uri.hasPort && uri.port != 443)) {
        throw const FormatException();
      }
      return url;
    } catch (_) {
      throw const SupportFailure(
        'image_upload',
        '스크린샷을 업로드하지 못했습니다. 다시 시도하거나 첨부를 제거해 주세요.',
      );
    }
  }
}
