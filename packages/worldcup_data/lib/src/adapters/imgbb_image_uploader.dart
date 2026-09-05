import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:worldcup_core/worldcup_core.dart';
import 'package:worldcup_domain/worldcup_domain.dart';

/// ImgBB 기반 [ImageUploadPort] 구현.
///
/// API 키를 dotenv에서 직접 읽지 않고 생성자로 받는다. 그래야 테스트에서
/// 환경 파일 없이 쓸 수 있고, 키를 어디서 가져올지는 앱이 정한다.
class ImgbbImageUploader implements ImageUploadPort {
  /// 업로드한 이미지의 보관 기간(초). 3일.
  static const String _expiration = '259200';

  final String apiKey;
  final http.Client _client;

  ImgbbImageUploader({required this.apiKey, http.Client? client})
    : _client = client ?? http.Client();

  @override
  Future<String?> uploadItemImage(WorldCupItemModel item) async {
    return _upload(base64Encode(await _readBytes(item)));
  }

  /// 샘플 항목은 에셋에서, 사용자 항목은 파일에서 읽는다.
  Future<List<int>> _readBytes(WorldCupItemModel item) async {
    try {
      if (item.isSample) {
        final data = await rootBundle.load(item.imagePath);
        return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      }
      return await File(item.imagePath).readAsBytes();
    } catch (error, stackTrace) {
      throw StorageFailure(
        '이미지를 읽지 못했습니다.',
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<String?> _upload(String base64Image) async {
    final http.Response response;
    try {
      response = await _client.post(
        Uri.https('api.imgbb.com', '1/upload'),
        body: {'key': apiKey, 'image': base64Image, 'expiration': _expiration},
      );
    } catch (error, stackTrace) {
      throw NetworkFailure(
        '이미지를 업로드하지 못했습니다. 잠시 후 다시 시도해주세요.',
        cause: error,
        stackTrace: stackTrace,
      );
    }

    if (response.statusCode != 200) {
      throw NetworkFailure(
        '이미지를 업로드하지 못했습니다. 잠시 후 다시 시도해주세요.',
        cause: 'HTTP ${response.statusCode}',
      );
    }

    try {
      final decoded = jsonDecode(response.body) as Map<String, Object?>;
      final data = decoded['data'] as Map<String, Object?>?;
      final thumb = data?['thumb'] as Map<String, Object?>?;
      return thumb?['url'] as String?;
    } catch (error, stackTrace) {
      throw NetworkFailure(
        '이미지 업로드 응답을 해석하지 못했습니다.',
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }
}
