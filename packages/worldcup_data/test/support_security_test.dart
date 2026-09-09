import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:worldcup_data/worldcup_data.dart';
import 'package:worldcup_domain/worldcup_domain.dart';
import 'package:worldcup_core/worldcup_core.dart';

class RecordingClient extends http.BaseClient {
  final int status;
  final Object body;
  final requests = <http.BaseRequest>[];
  RecordingClient(this.status, this.body);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    requests.add(request);
    return http.StreamedResponse(
      Stream.value(utf8.encode(jsonEncode(body))),
      status,
      headers: {'location': 'https://other.example/collect'},
    );
  }
}

void main() {
  test(
    'existing tournament uploader also blocks credential redirects',
    () async {
      final folder = await Directory.systemTemp.createTemp(
        'worldcup-upload-test-',
      );
      final file = await File('${folder.path}/image.png').writeAsBytes([1]);
      addTearDown(() => folder.delete(recursive: true));
      final client = RecordingClient(307, {});
      final uploader = ImgbbImageUploader(apiKey: 'key', client: client);
      await expectLater(
        uploader.uploadItemImage(WorldCupItemModel(1, file.path, '', 1)),
        throwsA(isA<NetworkFailure>()),
      );
      expect(client.requests.single.followRedirects, false);
    },
  );

  test(
    'unsafe notice image URLs are omitted while preserving the notice',
    () async {
      for (final url in [
        'http://image.example/a.png',
        'https://user:password@image.example/a.png',
      ]) {
        final api = SupportApi(
          apiKey: 'key',
          baseUrl: 'https://api.example/v1/',
          client: RecordingClient(200, {
            'count': 1,
            'next': null,
            'results': [
              {
                'id': 1,
                'title': '공지',
                'content': '내용',
                'image_url': url,
                'published_at': '2026-09-09T04:00:00Z',
                'updated_at': '2026-09-09T04:00:00Z',
              },
            ],
          }),
        );
        expect((await api.fetchNotices(1)).notices.single.imageUrl, isNull);
      }
    },
  );
  for (final url in [
    '',
    'http://api.example/v1/',
    'https://user:password@api.example/v1/',
    'https://api.example/v1/?token=private',
    'https://api.example/v1/#fragment',
  ]) {
    test('reject unsafe/missing base URL before sending: $url', () async {
      final client = RecordingClient(200, {
        'count': 0,
        'next': null,
        'results': [],
      });
      final api = SupportApi(apiKey: 'key', baseUrl: url, client: client);
      await expectLater(
        api.fetchNotices(1),
        throwsA(
          isA<SupportFailure>().having((e) => e.code, 'code', 'configuration'),
        ),
      );
      expect(client.requests, isEmpty);
    });
  }

  test(
    'API and image upload never follow redirects carrying credentials',
    () async {
      for (final status in [301, 302, 307, 308]) {
        final apiClient = RecordingClient(status, {});
        final api = SupportApi(
          apiKey: 'key',
          baseUrl: 'https://api.example/v1/',
          client: apiClient,
        );
        await expectLater(
          api.submitInquiry(content: 'private'),
          throwsA(isA<SupportFailure>()),
        );
        expect(apiClient.requests.single.followRedirects, false);
        final imageClient = RecordingClient(status, {});
        final uploader = ImgbbInquiryUploader(
          apiKey: 'image-key',
          client: imageClient,
        );
        await expectLater(
          uploader.uploadScreenshot(Uint8List.fromList([1])),
          throwsA(isA<SupportFailure>()),
        );
        expect(imageClient.requests.single.followRedirects, false);
      }
    },
  );

  test(
    'server error messages and unrecognized fields never reach the UI',
    () async {
      for (final status in [400, 401, 500]) {
        final api = SupportApi(
          apiKey: 'key',
          baseUrl: 'https://api.example/v1/',
          client: RecordingClient(status, {
            'error': {
              'code': 'private',
              'message': 'private',
              'fields': {
                'email': ['private'],
                'debug': ['private'],
              },
            },
          }),
        );
        await expectLater(
          api.submitInquiry(content: 'content'),
          throwsA(
            isA<SupportFailure>()
                .having(
                  (e) => '${e.code} ${e.message} ${e.fields}',
                  'sanitized failure',
                  isNot(contains('private')),
                )
                .having(
                  (e) => e.fields.containsKey('debug'),
                  'debug removed',
                  false,
                ),
          ),
        );
      }
    },
  );
}
