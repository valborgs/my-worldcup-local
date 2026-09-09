import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:worldcup_domain/worldcup_domain.dart';

class SupportApi implements SupportPort {
  final String baseUrl;
  final String apiKey;
  final http.Client _client;
  final Duration timeout;

  SupportApi({
    required this.apiKey,
    required this.baseUrl,
    http.Client? client,
    this.timeout = const Duration(seconds: 20),
  }) : _client = client ?? http.Client();

  void close() => _client.close();

  Future<Map<String, dynamic>> _request(
    String path, {
    int? page,
    Map<String, Object?>? body,
  }) async {
    if (apiKey.trim().isEmpty || baseUrl.trim().isEmpty) {
      throw const SupportFailure('configuration', '서비스 연결 설정이 준비되지 않았습니다.');
    }
    final base = Uri.tryParse(baseUrl.trim());
    if (base == null ||
        !base.hasAuthority ||
        base.host.isEmpty ||
        base.scheme != 'https' ||
        base.userInfo.isNotEmpty ||
        base.hasQuery ||
        base.hasFragment) {
      throw const SupportFailure('configuration', '서비스 주소를 확인해 주세요.');
    }
    final uri = base.replace(
      path: '${base.path.endsWith('/') ? base.path : '${base.path}/'}$path',
      queryParameters: page == null ? null : {'page': '$page'},
    );
    final headers = {
      'X-My-Worldcup-Api-Key': apiKey,
      'Accept': 'application/json',
      'Content-Type': 'application/json; charset=utf-8',
    };
    final http.Response response;
    try {
      // No automatic POST retries: a lost response may already be persisted.
      final request = http.Request(body == null ? 'GET' : 'POST', uri)
        ..followRedirects = false
        ..headers.addAll(headers);
      if (body != null) request.body = jsonEncode(body);
      response = await _client
          .send(request)
          .then(http.Response.fromStream)
          .timeout(timeout);
    } catch (_) {
      throw SupportFailure(
        'network',
        '서버에 연결하지 못했습니다. 네트워크를 확인해 주세요.',
        deliveryUncertain: body != null,
      );
    }
    final succeeded = response.statusCode >= 200 && response.statusCode < 300;
    Map<String, dynamic>? json;
    try {
      json =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    } catch (_) {
      // Reverse proxies can return non-JSON errors. Do not expose their body.
    }
    if (!succeeded) {
      final rawError = json?['error'];
      final error = rawError is Map ? rawError : const {};
      final fields = <String, List<String>>{};
      final rawFields = error['fields'];
      // Error bodies may contain echoed input, internal URLs or debug details.
      // Use only known field names, with messages owned by the app.
      if (response.statusCode == 400 && rawFields is Map) {
        const fieldMessages = {
          'email': '올바른 이메일 주소를 입력해 주세요.',
          'content': '문의 내용은 공백을 제외하고 1~5,000자로 입력해 주세요.',
          'screenshot_url': '스크린샷을 다시 첨부하거나 제거해 주세요.',
        };
        for (final entry in fieldMessages.entries) {
          if (rawFields.containsKey(entry.key)) {
            fields[entry.key] = [entry.value];
          }
        }
      }
      final (code, message) = switch (response.statusCode) {
        400 => ('validation_error', '입력 내용을 확인해 주세요.'),
        401 || 403 => ('authentication', '서비스 인증에 실패했습니다. 잠시 후 다시 시도해 주세요.'),
        404 => ('not_found', '요청한 정보를 찾을 수 없습니다. 다시 불러와 주세요.'),
        429 => ('throttled', '요청이 많아 잠시 기다려야 합니다.'),
        _ => ('server', '요청을 처리하지 못했습니다. 잠시 후 다시 시도해 주세요.'),
      };
      throw SupportFailure(
        code,
        message,
        fields: fields,
        retryAfterSeconds: response.statusCode == 429
            ? int.tryParse(response.headers['retry-after'] ?? '')
            : null,
        deliveryUncertain: body != null && response.statusCode >= 500,
      );
    }
    if (json == null) {
      throw SupportFailure(
        'invalid_response',
        '서버 응답을 확인하지 못했습니다.',
        deliveryUncertain: body != null,
      );
    }
    return json;
  }

  @override
  Future<NoticePage> fetchNotices(int page) async {
    final json = await _request('notices/', page: page);
    try {
      return NoticePage(
        count: json['count'] as int,
        hasNext: json['next'] != null,
        notices: (json['results'] as List).map((value) {
          final item = value as Map<String, dynamic>;
          return Notice(
            id: item['id'] as int,
            title: item['title'] as String,
            content: item['content'] as String,
            imageUrl: _noticeImageUrl(item['image_url'] as String?),
            publishedAt: DateTime.parse(item['published_at'] as String),
            updatedAt: DateTime.parse(item['updated_at'] as String),
          );
        }).toList(),
      );
    } catch (_) {
      throw const SupportFailure('invalid_response', '공지사항 응답을 확인하지 못했습니다.');
    }
  }

  String? _noticeImageUrl(String? value) {
    if (value == null) return null;
    final uri = Uri.tryParse(value);
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty) {
      return null;
    }
    return value;
  }

  @override
  Future<InquiryReceipt> submitInquiry({
    required String content,
    String? email,
    String? screenshotUrl,
  }) async {
    String? optional(String? value) =>
        value == null || value.trim().isEmpty ? null : value.trim();
    final json = await _request(
      'inquiries/',
      body: {
        'content': content.trim(),
        'email': optional(email),
        'screenshot_url': optional(screenshotUrl),
      },
    );
    try {
      return InquiryReceipt(
        id: json['id'] as int,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
    } catch (_) {
      throw const SupportFailure(
        'invalid_response',
        '접수 결과를 확인하지 못했습니다.',
        deliveryUncertain: true,
      );
    }
  }
}
