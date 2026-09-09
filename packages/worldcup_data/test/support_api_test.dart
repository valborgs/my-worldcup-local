import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:worldcup_data/worldcup_data.dart';
import 'package:worldcup_domain/worldcup_domain.dart';

http.Response jsonResponse(
  Object json,
  int status, {
  Map<String, String>? headers,
}) => http.Response(
  jsonEncode(json),
  status,
  headers: {'content-type': 'application/json; charset=utf-8', ...?headers},
);

void main() {
  test('notice request uses namespace/key/page and decodes Korean, image, dates', () async {
    final api = SupportApi(
      baseUrl: 'https://api.example/api/v1/my-worldcup/',
      apiKey: 'test-key',
      client: MockClient((request) async {
        expect(request.method, 'GET');
        expect(
          request.url.toString(),
          'https://api.example/api/v1/my-worldcup/notices/?page=2',
        );
        expect(request.headers['X-My-Worldcup-Api-Key'], 'test-key');
        return jsonResponse({
          'count': 21,
          'next': 'https://untrusted.example/?page=3',
          'previous': null,
          'results': [
            {
              'id': 12,
              'title': '공지',
              'content': '본문\n둘째 줄',
              'image_url': null,
              'published_at': '2026-09-09T04:00:00Z',
              'updated_at': '2026-09-09T04:00:00Z',
            },
          ],
        }, 200);
      }),
    );
    final result = await api.fetchNotices(2);
    expect(result.hasNext, true);
    expect(result.notices.single.content, '본문\n둘째 줄');
    expect(result.notices.single.publishedAt.isUtc, true);
    // Pagination links never become request destinations carrying our API key.
    addTearDown(api.close);
  });

  test('inquiry JSON normalization and receipt', () async {
    final api = SupportApi(
      baseUrl: 'https://api.example/api/v1/my-worldcup/',
      apiKey: 'key',
      client: MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/api/v1/my-worldcup/inquiries/');
        expect(request.headers['content-type'], contains('application/json'));
        expect(jsonDecode(request.body), {
          'content': '문의',
          'email': null,
          'screenshot_url': 'https://i.ibb.co/a/full.png',
        });
        return jsonResponse({
          'id': 104,
          'created_at': '2026-09-09T04:15:00Z',
        }, 201);
      }),
    );
    expect(
      (await api.submitInquiry(
        content: ' 문의 ',
        email: ' ',
        screenshotUrl: 'https://i.ibb.co/a/full.png',
      )).id,
      104,
    );
    addTearDown(api.close);
  });

  for (final status in [400, 401, 404, 429, 500]) {
    test('structured failure $status, fields and retry header', () async {
      final api = SupportApi(
        baseUrl: 'https://api.example/api/v1/my-worldcup/',
        apiKey: 'key',
        client: MockClient(
          (_) async => jsonResponse(
            {
              'error': {
                'code': 'test_error',
                'message': '서버 안내',
                'fields': {
                  'email': ['이메일 확인'],
                },
              },
            },
            status,
            headers: {'retry-after': '60'},
          ),
        ),
      );
      await expectLater(
        api.submitInquiry(content: '내용'),
        throwsA(
          isA<SupportFailure>()
              .having((e) => e.code, 'code', isNot('test_error'))
              .having(
                (e) => e.fields['email'],
                'fields',
                status == 400 ? ['올바른 이메일 주소를 입력해 주세요.'] : null,
              )
              .having((e) => e.retryAfterSeconds, 'retry', 60)
              .having((e) => e.deliveryUncertain, 'uncertain', status >= 500),
        ),
      );
      addTearDown(api.close);
    });
  }

  test('missing config fails without sending a request', () async {
    var calls = 0;
    final api = SupportApi(
      baseUrl: 'https://api.example/api/v1/my-worldcup/',
      apiKey: '',
      client: MockClient((_) async {
        calls++;
        return http.Response('', 200);
      }),
    );
    await expectLater(api.fetchNotices(1), throwsA(isA<SupportFailure>()));
    expect(calls, 0);
    addTearDown(api.close);
  });

  test('timeout never retries POST and marks delivery uncertain', () async {
    var calls = 0;
    final pending = Completer<http.Response>();
    final api = SupportApi(
      baseUrl: 'https://api.example/api/v1/my-worldcup/',
      apiKey: 'key',
      timeout: const Duration(milliseconds: 1),
      client: MockClient((_) {
        calls++;
        return pending.future;
      }),
    );
    await expectLater(
      api.submitInquiry(content: '내용'),
      throwsA(
        isA<SupportFailure>().having(
          (e) => e.deliveryUncertain,
          'uncertain',
          true,
        ),
      ),
    );
    expect(calls, 1);
    pending.complete(http.Response('{}', 201));
    addTearDown(api.close);
  });

  test(
    'invalid success JSON and non-JSON proxy errors are safe failures',
    () async {
      for (final status in [201, 502]) {
        final api = SupportApi(
          baseUrl: 'https://api.example/api/v1/my-worldcup/',
          apiKey: 'key',
          client: MockClient((_) async => http.Response('<private>', status)),
        );
        await expectLater(
          api.submitInquiry(content: '내용'),
          throwsA(
            isA<SupportFailure>()
                .having((e) => e.deliveryUncertain, 'uncertain', true)
                .having(
                  (e) => e.message.contains('private'),
                  'raw response hidden',
                  false,
                ),
          ),
        );
        api.close();
      }
    },
  );

  test('screenshot uses full image with three-day expiration', () async {
    final uploader = ImgbbInquiryUploader(
      apiKey: 'image-key',
      client: MockClient((request) async {
        expect(request.url.host, 'api.imgbb.com');
        expect(request.bodyFields['expiration'], '259200');
        expect(request.bodyFields['image'], base64Encode([1, 2, 3]));
        return jsonResponse({
          'data': {
            'url': 'https://i.ibb.co/full.png',
            'thumb': {'url': 'https://i.ibb.co/thumb.png'},
          },
        }, 200);
      }),
    );
    expect(
      await uploader.uploadScreenshot(Uint8List.fromList([1, 2, 3])),
      'https://i.ibb.co/full.png',
    );
    addTearDown(uploader.close);
  });

  for (final url in [
    'http://i.ibb.co/a.png',
    'https://i.ibb.co.evil.test/a.png',
    'https://ibb.co/view',
  ]) {
    test('reject screenshot URL $url', () async {
      final uploader = ImgbbInquiryUploader(
        apiKey: 'key',
        client: MockClient(
          (_) async => jsonResponse({
            'data': {'url': url},
          }, 200),
        ),
      );
      await expectLater(
        uploader.uploadScreenshot(Uint8List.fromList([1])),
        throwsA(isA<SupportFailure>()),
      );
      addTearDown(uploader.close);
    });
  }
}
