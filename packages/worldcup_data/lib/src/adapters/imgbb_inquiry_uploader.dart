import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show compute;
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
    final http.Response response;
    try {
      final encoded = await compute(base64Encode, bytes);
      final request =
          http.Request('POST', Uri.https('api.imgbb.com', '/1/upload'))
            ..followRedirects = false
            ..bodyFields = {
              'key': apiKey,
              'image': encoded,
              'expiration': '259200',
            };
      response = await _client
          .send(request)
          .then(http.Response.fromStream)
          .timeout(timeout);
      if (response.statusCode != 200) throw const FormatException();
    } catch (_) {
      throw const SupportFailure(
        'image_upload',
        '스크린샷을 업로드하지 못했습니다. 다시 시도하거나 첨부를 제거해 주세요.',
      );
    }
    try {
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
        'image_response',
        '업로드된 이미지 주소를 문의에 사용할 수 없습니다. 첨부를 제거하고 문의해 주세요.',
      );
    }
  }
}
