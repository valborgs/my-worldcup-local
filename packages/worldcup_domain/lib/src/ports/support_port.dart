import 'dart:typed_data';

class Notice {
  final int id;
  final String title;
  final String content;
  final String? imageUrl;
  final DateTime publishedAt;
  final DateTime updatedAt;

  const Notice({
    required this.id,
    required this.title,
    required this.content,
    this.imageUrl,
    required this.publishedAt,
    required this.updatedAt,
  });
}

class NoticePage {
  final List<Notice> notices;
  final int count;
  final bool hasNext;

  NoticePage({
    required List<Notice> notices,
    required this.count,
    required this.hasNext,
  }) : notices = List.unmodifiable(notices);
}

class InquiryReceipt {
  final int id;
  final DateTime createdAt;
  const InquiryReceipt({required this.id, required this.createdAt});
}

/// A structured server failure; never contains a raw request or response body.
class SupportFailure implements Exception {
  final String code;
  final String message;
  final Map<String, List<String>> fields;
  final int? retryAfterSeconds;

  /// The server may have accepted the POST before the connection failed.
  final bool deliveryUncertain;

  const SupportFailure(
    this.code,
    this.message, {
    this.fields = const {},
    this.retryAfterSeconds,
    this.deliveryUncertain = false,
  });
}

abstract interface class SupportPort {
  Future<NoticePage> fetchNotices(int page);
  Future<InquiryReceipt> submitInquiry({
    required String content,
    String? email,
    String? screenshotUrl,
  });
}

abstract interface class InquiryImageUploadPort {
  /// Uploads a readable image, independent of tournament thumbnails.
  Future<String> uploadScreenshot(Uint8List bytes);
}
