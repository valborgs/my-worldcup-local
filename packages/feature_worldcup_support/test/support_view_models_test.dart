import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:worldcup_domain/worldcup_domain.dart';
import 'package:feature_worldcup_support/src/state/support_view_models.dart';

class FakeApi implements SupportPort {
  final pages = <int, Completer<NoticePage>>{};
  final submissions = <String?>[];
  Future<InquiryReceipt> Function()? onSubmit;
  @override
  Future<NoticePage> fetchNotices(int page) =>
      (pages[page] = Completer<NoticePage>()).future;
  @override
  Future<InquiryReceipt> submitInquiry({
    required String content,
    String? email,
    String? screenshotUrl,
  }) async {
    submissions.add(screenshotUrl);
    return onSubmit != null
        ? onSubmit!()
        : InquiryReceipt(id: 1, createdAt: DateTime.utc(2026));
  }
}

class FakeUploader implements InquiryImageUploadPort {
  int calls = 0;
  Future<String> Function()? onUpload;
  @override
  Future<String> uploadScreenshot(Uint8List bytes) async {
    calls++;
    return onUpload != null ? onUpload!() : 'https://i.ibb.co/full.png';
  }
}

NoticePage page(int id, {bool hasNext = false}) => NoticePage(
  count: 11,
  hasNext: hasNext,
  notices: [
    Notice(
      id: id,
      title: '공지',
      content: '내용',
      publishedAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
    ),
  ],
);

void main() {
  test(
    'attachment stream rejects empty/oversized files and preserves bytes',
    () async {
      expect(
        await InquiryViewModel.readScreenshot(
          Stream.fromIterable([
            [1, 2],
            [3],
          ]),
        ),
        [1, 2, 3],
      );
      await expectLater(
        InquiryViewModel.readScreenshot(const Stream.empty()),
        throwsA(isA<SupportFailure>()),
      );
      await expectLater(
        InquiryViewModel.readScreenshot(
          Stream.value(Uint8List(InquiryViewModel.maxImageBytes + 1)),
        ),
        throwsA(isA<SupportFailure>()),
      );
    },
  );
  test(
    'refresh wins over late page response; dispose ignores in-flight response',
    () async {
      final api = FakeApi();
      final vm = NoticesViewModel(api);
      final old = vm.load(2);
      final refresh = vm.load(1);
      api.pages[1]!.complete(page(10, hasNext: true));
      await refresh;
      api.pages[2]!.complete(page(2));
      await old;
      expect(vm.notices.single.id, 10);
      expect(vm.page, 1);
      expect(vm.hasNext, true);
      final pending = vm.load(2);
      vm.dispose();
      api.pages[2]!.complete(page(20));
      await pending;
      expect(vm.notices.single.id, 10);
    },
  );

  test('failed next page preserves current content and page', () async {
    final api = FakeApi();
    final vm = NoticesViewModel(api);
    final first = vm.load(1);
    api.pages[1]!.complete(page(1, hasNext: true));
    await first;
    final next = vm.load(2);
    api.pages[2]!.completeError(const SupportFailure('network', '오류'));
    await next;
    expect(vm.page, 1);
    expect(vm.notices.single.id, 1);
    expect(vm.loading, false);
    expect(vm.error, isNotNull);
    vm.dispose();
  });

  test('upload precedes POST; busy blocks duplicate submission and attachment changes', () async {
    final api = FakeApi();
    final upload = Completer<String>();
    final uploader = FakeUploader()..onUpload = () => upload.future;
    final vm = InquiryViewModel(api, uploader)
      ..setScreenshot(Uint8List.fromList([1]), 'a.png');
    final pending = vm.submit(content: '내용', email: '');
    await vm.submit(content: '내용', email: '');
    vm.setScreenshot(null, null);
    expect(vm.screenshot, isNotNull);
    expect(api.submissions, isEmpty);
    expect(uploader.calls, 1);
    upload.complete('https://i.ibb.co/full.png');
    await pending;
    expect(api.submissions, ['https://i.ibb.co/full.png']);
    expect(vm.receipt?.id, 1);
    await vm.submit(content: '내용', email: '');
    expect(api.submissions.length, 1);
    vm.dispose();
  });

  test('upload failure never submits; removing attachment allows text-only inquiry', () async {
    final api = FakeApi();
    final uploader = FakeUploader()
      ..onUpload = () async => throw const SupportFailure('image', '업로드 실패');
    final vm = InquiryViewModel(api, uploader)
      ..setScreenshot(Uint8List.fromList([1]), 'a.png');
    await vm.submit(content: '내용', email: '');
    expect(api.submissions, isEmpty);
    vm.setScreenshot(null, null);
    await vm.submit(content: '내용', email: '');
    expect(api.submissions, [null]);
    vm.dispose();
  });

  test(
    'uncertain delivery needs explicit resend, reuses uploaded image',
    () async {
      final api = FakeApi()
        ..onSubmit = () async => throw const SupportFailure(
          'network',
          '오류',
          deliveryUncertain: true,
        );
      final uploader = FakeUploader();
      final vm = InquiryViewModel(api, uploader)
        ..setScreenshot(Uint8List.fromList([1]), 'a.png');
      await vm.submit(content: '내용', email: '');
      await vm.submit(content: '내용', email: '');
      expect(api.submissions.length, 1);
      expect(vm.deliveryUncertain, true);
      api.onSubmit = null;
      await vm.submit(content: '내용', email: '', confirmResend: true);
      expect(api.submissions.length, 2);
      expect(uploader.calls, 1);
      expect(vm.receipt, isNotNull);
      vm.dispose();
    },
  );

  test('dispose during upload prevents later POST and notification', () async {
    final api = FakeApi();
    final upload = Completer<String>();
    final vm = InquiryViewModel(
      api,
      FakeUploader()..onUpload = () => upload.future,
    )..setScreenshot(Uint8List.fromList([1]), 'a.png');
    final pending = vm.submit(content: '내용', email: '');
    vm.dispose();
    upload.complete('https://i.ibb.co/full.png');
    await pending;
    expect(api.submissions, isEmpty);
  });

  test('dispose during POST ignores receipt', () async {
    final result = Completer<InquiryReceipt>();
    final vm = InquiryViewModel(
      FakeApi()..onSubmit = () => result.future,
      FakeUploader(),
    );
    final pending = vm.submit(content: '내용', email: '');
    vm.dispose();
    result.complete(InquiryReceipt(id: 1, createdAt: DateTime.utc(2026)));
    await pending;
    expect(vm.receipt, isNull);
  });

  test('validation boundaries and throttling prevent requests', () async {
    expect(InquiryViewModel.validateContent(' '), isNotNull);
    expect(InquiryViewModel.validateContent('가' * 5000), isNull);
    expect(InquiryViewModel.validateContent('가' * 5001), isNotNull);
    expect(InquiryViewModel.validateEmail(' '), isNull);
    expect(InquiryViewModel.validateEmail('invalid'), isNotNull);
    final api = FakeApi()
      ..onSubmit = () async => throw const SupportFailure(
        'throttled',
        '대기',
        retryAfterSeconds: 3600,
      );
    final vm = InquiryViewModel(api, FakeUploader());
    await vm.submit(content: ' ', email: 'bad');
    expect(api.submissions, isEmpty);
    expect(vm.error!.fields.keys, containsAll(['content', 'email']));
    await vm.submit(content: '내용', email: '');
    await vm.submit(content: '내용', email: '');
    expect(api.submissions.length, 1);
    vm.dispose();
  });
}
