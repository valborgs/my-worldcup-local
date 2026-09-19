import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:image/image.dart' as img;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:worldcup_core/worldcup_core.dart';
import 'package:worldcup_domain/worldcup_domain.dart';

/// 사진을 픽셀만 남기고 다시 인코딩해 EXIF / XMP / IPTC / PNG 텍스트
/// 청크 같은 메타데이터를 모두 버리는 [ImageMetadataPort] 구현.
///
/// 메타데이터 블록만 골라 지우는 방식은 쓰지 않는다. 형식마다 숨을 곳이
/// 많아(JPEG APPn, PNG tEXt/iTXt/eXIf, WebP EXIF/XMP 청크 …) 하나라도
/// 빠뜨리면 위치 정보가 그대로 나간다. 디코드한 픽셀로 새 파일을 쓰면
/// 원본에 무엇이 있었든 남지 않는다.
///
/// 디코드는 엔진 코덱(`dart:ui`)에 맡긴다. 플랫폼이 읽는 형식(HEIC 포함)을
/// 모두 받고, EXIF 회전값을 적용한 픽셀을 돌려주므로 회전 정보를 버려도
/// 사진이 눕지 않는다. GIF만은 애니메이션을 지키려고 `image` 패키지로
/// 프레임째 다시 쓴다.
class ImageMetadataStripper implements ImageMetadataPort {
  static const String _directoryName = 'worldcup_images';
  static const int _jpegQuality = 90;
  static int _sequence = 0;

  final Future<Directory> Function() _documentsDirectoryProvider;

  /// [documentsDirectoryProvider]는 테스트에서 임시 경로를 끼우기 위한 훅이다.
  ImageMetadataStripper({
    Future<Directory> Function()? documentsDirectoryProvider,
  }) : _documentsDirectoryProvider =
           documentsDirectoryProvider ?? getApplicationDocumentsDirectory;

  @override
  Future<String> stripMetadata(String sourcePath) async {
    try {
      final directory = Directory(
        path.join((await _documentsDirectoryProvider()).path, _directoryName),
      );
      if (path.isWithin(directory.path, sourcePath)) return sourcePath;

      final source = await File(sourcePath).readAsBytes();
      final encoded = _isGif(source)
          ? await Isolate.run(() => _reencodeGif(source))
          : await _reencodeWithEngineCodec(source);

      await directory.create(recursive: true);
      final output = File(
        path.join(
          directory.path,
          '${DateTime.now().microsecondsSinceEpoch}_${_sequence++}'
          '${encoded.extension}',
        ),
      );
      await output.writeAsBytes(encoded.bytes, flush: true);
      return output.path;
    } catch (error, stackTrace) {
      throw StorageFailure(
        '사진의 메타데이터를 제거하지 못했습니다.',
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }

  static bool _isGif(Uint8List bytes) =>
      bytes.length >= 6 &&
      bytes[0] == 0x47 && // G
      bytes[1] == 0x49 && // I
      bytes[2] == 0x46 && // F
      bytes[3] == 0x38; // 8

  static bool _isPng(Uint8List bytes) =>
      bytes.length >= 8 &&
      bytes[0] == 0x89 &&
      bytes[1] == 0x50 &&
      bytes[2] == 0x4E &&
      bytes[3] == 0x47;

  static _EncodedImage _reencodeGif(Uint8List source) {
    final decoded = img.decodeGif(source);
    if (decoded == null) throw const FormatException('GIF를 읽지 못했습니다.');
    return _EncodedImage(img.encodeGif(decoded), '.gif');
  }

  static Future<_EncodedImage> _reencodeWithEngineCodec(
    Uint8List source,
  ) async {
    final codec = await ui.instantiateImageCodec(source);
    final ui.Image frame;
    try {
      frame = (await codec.getNextFrame()).image;
    } finally {
      codec.dispose();
    }
    final int width;
    final int height;
    final ByteData? pixels;
    try {
      width = frame.width;
      height = frame.height;
      // 알파를 미리 곱하지 않은 값이어야 인코더가 색을 그대로 쓴다.
      pixels = await frame.toByteData(
        format: ui.ImageByteFormat.rawStraightRgba,
      );
    } finally {
      frame.dispose();
    }
    if (pixels == null) throw const FormatException('픽셀을 읽지 못했습니다.');

    // 수십 MB짜리 픽셀 버퍼를 복사하지 않고 넘긴다.
    final transferable = TransferableTypedData.fromList([
      pixels.buffer.asUint8List(pixels.offsetInBytes, pixels.lengthInBytes),
    ]);
    final keepPng = _isPng(source);
    return Isolate.run(
      () => _encodeRgba(
        transferable.materialize(),
        width: width,
        height: height,
        keepPng: keepPng,
      ),
    );
  }

  /// PNG 원본이나 투명한 픽셀이 있는 이미지는 PNG로, 나머지는 JPEG로 쓴다.
  static _EncodedImage _encodeRgba(
    ByteBuffer rgba, {
    required int width,
    required int height,
    required bool keepPng,
  }) {
    final image = img.Image.fromBytes(
      width: width,
      height: height,
      bytes: rgba,
      numChannels: 4,
    );
    if (keepPng || _hasTransparency(rgba.asUint8List())) {
      return _EncodedImage(img.encodePng(image), '.png');
    }
    return _EncodedImage(img.encodeJpg(image, quality: _jpegQuality), '.jpg');
  }

  static bool _hasTransparency(Uint8List rgba) {
    for (var i = 3; i < rgba.length; i += 4) {
      if (rgba[i] != 0xFF) return true;
    }
    return false;
  }
}

class _EncodedImage {
  final Uint8List bytes;
  final String extension;

  const _EncodedImage(this.bytes, this.extension);
}
