import 'package:flutter/foundation.dart';
import 'package:worldcup_domain/worldcup_domain.dart';

SupportFailure? _cooldownFailure(DateTime? retryAt) {
  if (retryAt == null) return null;
  final millis = retryAt.difference(DateTime.now()).inMilliseconds;
  if (millis <= 0) return null;
  return SupportFailure(
    'throttled',
    '요청이 많아 잠시 기다려야 합니다.',
    retryAfterSeconds: (millis / 1000).ceil(),
  );
}

class NoticesViewModel extends ChangeNotifier {
  final SupportPort _api;
  NoticesViewModel(this._api);

  List<Notice> notices = const [];
  int page = 1;
  int requestedPage = 1;
  bool hasNext = false;
  bool loading = false;
  bool loaded = false;
  SupportFailure? error;
  DateTime? retryAt;
  int _generation = 0;
  bool _disposed = false;

  Future<void> load(int target) async {
    if (_disposed || target < 1) {
      return;
    }
    final cooldown = _cooldownFailure(retryAt);
    if (cooldown != null) {
      error = cooldown;
      notifyListeners();
      return;
    }
    final generation = ++_generation;
    requestedPage = target;
    loading = true;
    error = null;
    notifyListeners();
    try {
      final result = await _api.fetchNotices(target);
      if (_disposed || generation != _generation) return;
      notices = result.notices;
      hasNext = result.hasNext;
      page = target;
      loaded = true;
      retryAt = null;
    } catch (failure) {
      if (_disposed || generation != _generation) return;
      error = failure is SupportFailure
          ? failure
          : const SupportFailure('unknown', '공지사항을 불러오지 못했습니다.');
      final seconds = error?.retryAfterSeconds;
      if (seconds != null && seconds > 0) {
        retryAt = DateTime.now().add(Duration(seconds: seconds));
      }
    } finally {
      if (!_disposed && generation == _generation) {
        loading = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    super.dispose();
  }
}

class InquiryViewModel extends ChangeNotifier {
  final SupportPort _api;
  final InquiryImageUploadPort _uploader;
  InquiryViewModel(this._api, this._uploader);

  static const maxImageBytes = 10 * 1024 * 1024;
  Uint8List? screenshot;
  String? screenshotName;
  String? _uploadedUrl;
  DateTime? _uploadedAt;
  bool busy = false;
  bool uploading = false;
  bool deliveryUncertain = false;
  SupportFailure? error;
  InquiryReceipt? receipt;
  DateTime? retryAt;
  bool _disposed = false;

  static String? validateContent(String value) {
    final length = value.trim().runes.length;
    if (length == 0) return '문의 내용을 입력해 주세요.';
    if (length > 5000) return '문의 내용은 5,000자까지 입력할 수 있습니다.';
    return null;
  }

  static String? validateEmail(String value) {
    final email = value.trim();
    if (email.isEmpty) return null;
    if (email.length > 254 ||
        !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      return '올바른 이메일 주소를 입력해 주세요.';
    }
    return null;
  }

  void setScreenshot(Uint8List? bytes, String? name) {
    if (_disposed || busy || receipt != null) return;
    if (bytes != null && (bytes.isEmpty || bytes.length > maxImageBytes)) {
      error = const SupportFailure('image_size', '10MB 이하의 이미지를 선택해 주세요.');
    } else {
      screenshot = bytes;
      screenshotName = name;
      _uploadedUrl = null;
      _uploadedAt = null;
      error = null;
    }
    notifyListeners();
  }

  void selectionFailed() {
    if (_disposed) return;
    error = const SupportFailure(
      'image_selection',
      '이미지를 열지 못했습니다. 다른 파일을 선택해 주세요.',
    );
    notifyListeners();
  }

  void attachmentFailed(SupportFailure failure) {
    if (_disposed) return;
    error = failure;
    notifyListeners();
  }

  /// Read in bounded chunks even when the picker reports an unknown file size.
  static Future<Uint8List> readScreenshot(Stream<List<int>> stream) async {
    final chunks = <List<int>>[];
    var length = 0;
    await for (final chunk in stream) {
      length += chunk.length;
      if (length > maxImageBytes) {
        throw const SupportFailure('image_size', '10MB 이하의 이미지를 선택해 주세요.');
      }
      chunks.add(chunk);
    }
    if (length == 0) {
      throw const SupportFailure('image_size', '비어 있는 파일은 첨부할 수 없습니다.');
    }
    final bytes = Uint8List(length);
    var offset = 0;
    for (final chunk in chunks) {
      bytes.setRange(offset, offset + chunk.length, chunk);
      offset += chunk.length;
    }
    return bytes;
  }

  Future<void> submit({
    required String content,
    required String email,
    bool confirmResend = false,
  }) async {
    if (_disposed ||
        busy ||
        receipt != null ||
        (deliveryUncertain && !confirmResend)) {
      return;
    }
    final cooldown = _cooldownFailure(retryAt);
    if (cooldown != null) {
      error = cooldown;
      notifyListeners();
      return;
    }
    final fields = <String, List<String>>{};
    final contentError = validateContent(content);
    final emailError = validateEmail(email);
    if (contentError != null) fields['content'] = [contentError];
    if (emailError != null) fields['email'] = [emailError];
    if (fields.isNotEmpty) {
      error = SupportFailure(
        'validation_error',
        '입력 내용을 확인해 주세요.',
        fields: fields,
      );
      notifyListeners();
      return;
    }
    busy = true;
    error = null;
    notifyListeners();
    try {
      if (_uploadedAt != null &&
          DateTime.now().difference(_uploadedAt!).inDays >= 2) {
        _uploadedUrl = null;
      }
      if (screenshot != null && _uploadedUrl == null) {
        uploading = true;
        notifyListeners();
        _uploadedUrl = await _uploader.uploadScreenshot(screenshot!);
        if (_disposed) return;
        _uploadedAt = DateTime.now();
        uploading = false;
        notifyListeners();
      }
      final result = await _api.submitInquiry(
        content: content.trim(),
        email: email.trim().isEmpty ? null : email.trim(),
        screenshotUrl: _uploadedUrl,
      );
      if (_disposed) return;
      receipt = result;
      deliveryUncertain = false;
    } catch (failure) {
      if (_disposed) return;
      error = failure is SupportFailure
          ? failure
          : SupportFailure(
              'unknown',
              '문의 접수를 완료하지 못했습니다.',
              deliveryUncertain: !uploading,
            );
      deliveryUncertain = deliveryUncertain || error!.deliveryUncertain;
      if (error!.fields.containsKey('screenshot_url')) _uploadedUrl = null;
      final seconds = error!.retryAfterSeconds;
      if (seconds != null && seconds > 0) {
        retryAt = DateTime.now().add(Duration(seconds: seconds));
      }
    } finally {
      if (!_disposed) {
        busy = false;
        uploading = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
