import 'dart:async';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:feature_worldcup_support/feature_worldcup_support.dart';
import 'package:worldcup_domain/worldcup_domain.dart';

class ScreenApi implements SupportPort {
  final calls = <int>[];
  int submitted = 0;
  Future<NoticePage> Function(int)? onFetch;
  Future<InquiryReceipt> Function()? onSubmit;
  @override
  Future<NoticePage> fetchNotices(int page) async {
    calls.add(page);
    if (onFetch != null) return onFetch!(page);
    return NoticePage(
      count: 11,
      hasNext: page == 1,
      notices: [
        Notice(
          id: page,
          title: '공지 $page',
          content: '본문 $page\n줄바꿈',
          publishedAt: DateTime.utc(2026, 9, 9),
          updatedAt: DateTime.utc(2026, 9, 9),
        ),
      ],
    );
  }

  @override
  Future<InquiryReceipt> submitInquiry({
    required String content,
    String? email,
    String? screenshotUrl,
  }) async {
    submitted++;
    return onSubmit != null
        ? onSubmit!()
        : InquiryReceipt(id: 104, createdAt: DateTime.utc(2026));
  }
}

class NoUpload implements InquiryImageUploadPort {
  @override
  Future<String> uploadScreenshot(Uint8List bytes) async =>
      throw StateError('Unexpected upload');
}

class PendingPicker extends FilePicker {
  final result = Completer<FilePickerResult?>();
  @override
  Future<FilePickerResult?> pickFiles({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    bool allowCompression = false,
    int compressionQuality = 0,
    bool allowMultiple = false,
    bool withData = false,
    bool withReadStream = false,
    bool lockParentWindow = false,
    bool readSequential = false,
  }) => result.future;
}

Widget app(ScreenApi api, Widget screen) => ProviderScope(
  overrides: [
    supportProvider.overrideWithValue(api),
    inquiryImageUploadProvider.overrideWithValue(NoUpload()),
  ],
  child: MaterialApp(home: screen),
);

Future<void> send(WidgetTester tester) async {
  await tester.scrollUntilVisible(
    find.widgetWithText(FilledButton, '문의 등록'),
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await Scrollable.ensureVisible(
    tester.element(find.widgetWithText(FilledButton, '문의 등록')),
    alignment: 0.5,
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('문의 등록'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'a pending file picker does not trap the screen and late result is ignored',
    (tester) async {
      final picker = PendingPicker();
      FilePicker.platform = picker;
      addTearDown(() => FilePicker.platform = PendingPicker());
      await tester.pumpWidget(
        app(
          ScreenApi(),
          Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const InquiryScreen(),
                  ),
                ),
                child: const Text('열기'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('열기'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('스크린샷 첨부 (선택)'));
      await tester.tap(find.text('스크린샷 첨부 (선택)'));
      await tester.pumpAndSettle();
      expect(find.text('이미지 선택 중…'), findsOneWidget);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text('열기'), findsOneWidget);
      picker.result.complete(null);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'emoji counter uses the same trimmed code point limit as validation',
    (tester) async {
      final api = ScreenApi();
      await tester.pumpWidget(app(api, const InquiryScreen()));
      await tester.enterText(
        find.byType(TextFormField).last,
        '  ${'👨‍👩‍👧' * 1001}  ',
      );
      await tester.pump();
      expect(find.text('5005 / 5000'), findsOneWidget);
      await send(tester);
      expect(api.submitted, 0);
      expect(find.text('문의 내용은 5,000자까지 입력할 수 있습니다.'), findsOneWidget);
    },
  );
  testWidgets('notice expansion, next/previous pagination, refresh', (
    tester,
  ) async {
    final api = ScreenApi();
    await tester.pumpWidget(app(api, const NoticesScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('공지 1'));
    await tester.pumpAndSettle();
    expect(find.text('본문 1\n줄바꿈'), findsOneWidget);
    await tester.tap(find.text('다음'));
    await tester.pumpAndSettle();
    expect(find.text('공지 2'), findsOneWidget);
    expect(find.text('2 페이지'), findsOneWidget);
    expect(
      tester
          .widget<TextButton>(find.widgetWithText(TextButton, '다음'))
          .onPressed,
      isNull,
    );
    await tester.tap(find.text('이전'));
    await tester.pumpAndSettle();
    expect(api.calls, [1, 2, 1]);
    await tester.drag(find.byType(ListView), const Offset(0, 400));
    await tester.pumpAndSettle();
    expect(api.calls, [1, 2, 1, 1]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('notice failure can retry to empty state', (tester) async {
    final api = ScreenApi()
      ..onFetch = (_) async => throw const SupportFailure('network', '연결 실패');
    await tester.pumpWidget(app(api, const NoticesScreen()));
    await tester.pumpAndSettle();
    expect(find.text('연결 실패'), findsOneWidget);
    api.onFetch = (_) async =>
        NoticePage(notices: [], count: 0, hasNext: false);
    await tester.tap(find.text('다시 불러오기'));
    await tester.pumpAndSettle();
    expect(find.text('등록된 공지사항이 없습니다.'), findsOneWidget);
  });

  testWidgets(
    'inquiry validates then displays receipt without navigating away',
    (tester) async {
      final api = ScreenApi();
      await tester.pumpWidget(app(api, const InquiryScreen()));
      await send(tester);
      expect(api.submitted, 0);
      expect(find.text('문의 내용을 입력해 주세요.'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField).last, '내용입니다.');
      await send(tester);
      expect(api.submitted, 1);
      expect(find.text('문의가 접수되었습니다.'), findsOneWidget);
      expect(find.text('접수 번호: 104'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('uncertain response preserves draft and asks before resending', (
    tester,
  ) async {
    final api = ScreenApi()
      ..onSubmit = () async => throw const SupportFailure(
        'network',
        '응답 없음',
        deliveryUncertain: true,
      );
    await tester.pumpWidget(app(api, const InquiryScreen()));
    await tester.enterText(find.byType(TextFormField).last, '보존할 내용');
    await send(tester);
    expect(find.text('보존할 내용'), findsOneWidget);
    await send(tester);
    expect(find.text('문의를 다시 전송할까요?'), findsOneWidget);
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();
    expect(api.submitted, 1);
    await send(tester);
    api.onSubmit = null;
    await tester.tap(find.text('다시 전송'));
    await tester.pumpAndSettle();
    expect(api.submitted, 2);
    expect(find.text('문의가 접수되었습니다.'), findsOneWidget);
  });

  testWidgets('back with draft confirms discard', (tester) async {
    await tester.pumpWidget(app(ScreenApi(), const InquiryScreen()));
    await tester.enterText(find.byType(TextFormField).last, '작성 중');
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('작성을 그만둘까요?'), findsOneWidget);
    await tester.tap(find.text('계속 작성'));
    await tester.pumpAndSettle();
    expect(find.text('작성 중'), findsOneWidget);
  });
}
