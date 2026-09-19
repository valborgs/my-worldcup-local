import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as path;
import 'package:worldcup_core/worldcup_core.dart';
import 'package:worldcup_data/worldcup_data.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory testDirectory;
  late ImageMetadataStripper stripper;

  setUp(() async {
    testDirectory = await Directory.systemTemp.createTemp(
      'my_worldcup_metadata_test_',
    );
    stripper = ImageMetadataStripper(
      documentsDirectoryProvider: () async => testDirectory,
    );
  });

  tearDown(() async {
    if (await testDirectory.exists()) {
      await testDirectory.delete(recursive: true);
    }
  });

  Future<String> writeSource(String name, List<int> bytes) async {
    final file = File(path.join(testDirectory.path, name));
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  test('JPEG의 GPS 등 EXIF를 지우고 회전값은 픽셀에 반영한다', () async {
    // 가로 40 x 세로 20으로 저장됐지만 "시계 방향 90도 회전"으로 보여야 하는 사진.
    final source = img.Image(width: 40, height: 20)
      ..exif.imageIfd.orientation = 6
      ..exif.imageIfd['Make'] = img.IfdValueAscii('SecretPhone')
      ..exif.gpsIfd['GPSLatitudeRef'] = img.IfdValueAscii('N')
      ..exif.gpsIfd['GPSLatitude'] = img.IfdValueRational(37, 1);
    final original = img.encodeJpg(source);
    expect(img.decodeJpg(original)!.exif.gpsIfd.isEmpty, isFalse);
    final sourcePath = await writeSource('camera.jpg', original);

    final strippedPath = await stripper.stripMetadata(sourcePath);

    expect(strippedPath, isNot(sourcePath));
    expect(strippedPath, endsWith('.jpg'));
    final bytes = await File(strippedPath).readAsBytes();
    final decoded = img.decodeJpg(bytes)!;
    expect(decoded.exif.gpsIfd.isEmpty, isTrue);
    expect(decoded.exif.imageIfd.isEmpty, isTrue);
    expect(String.fromCharCodes(bytes).contains('SecretPhone'), isFalse);
    expect(
      (decoded.width, decoded.height),
      (20, 40),
      reason: '회전 정보를 버렸으므로 픽셀이 이미 돌아가 있어야 한다.',
    );
  });

  test('PNG 텍스트 청크를 지우고 투명도는 유지한다', () async {
    final source = img.Image(width: 8, height: 8, numChannels: 4)
      ..clear(img.ColorRgba8(10, 20, 30, 128))
      ..addTextData({'Location': '37.56N 126.97E'});
    final sourcePath = await writeSource(
      'screenshot.png',
      img.encodePng(source),
    );

    final strippedPath = await stripper.stripMetadata(sourcePath);

    expect(strippedPath, endsWith('.png'));
    final bytes = await File(strippedPath).readAsBytes();
    expect(String.fromCharCodes(bytes).contains('37.56N'), isFalse);
    final decoded = img.decodePng(bytes)!;
    expect(decoded.textData, isNull);
    expect(decoded.getPixel(0, 0).a, 128);
  });

  test('GIF는 모든 프레임을 유지한 채 다시 쓴다', () async {
    final first = img.Image(width: 4, height: 4)
      ..clear(img.ColorRgb8(255, 0, 0));
    final second = img.Image(width: 4, height: 4)
      ..clear(img.ColorRgb8(0, 0, 255));
    first.addFrame(second);
    final sourcePath = await writeSource('moving.gif', img.encodeGif(first));

    final strippedPath = await stripper.stripMetadata(sourcePath);

    expect(strippedPath, endsWith('.gif'));
    final decoded = img.decodeGif(await File(strippedPath).readAsBytes())!;
    expect(decoded.numFrames, 2);
  });

  test('이미 메타데이터를 제거한 사본은 다시 만들지 않는다', () async {
    final sourcePath = await writeSource(
      'plain.jpg',
      img.encodeJpg(img.Image(width: 4, height: 4)),
    );
    final strippedPath = await stripper.stripMetadata(sourcePath);

    expect(await stripper.stripMetadata(strippedPath), strippedPath);
  });

  test('이미지가 아니면 원본 경로를 돌려주지 않고 실패한다', () async {
    final sourcePath = await writeSource(
      'note.jpg',
      Uint8List.fromList('not an image'.codeUnits),
    );

    await expectLater(
      stripper.stripMetadata(sourcePath),
      throwsA(isA<StorageFailure>()),
    );
  });
}
