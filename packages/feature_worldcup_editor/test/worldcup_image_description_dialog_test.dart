import 'dart:convert';
import 'dart:io';

import 'package:feature_worldcup_editor/src/widgets/worldcup_image_description_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// 1x1 투명 PNG. `Image.file`이 실제로 디코딩할 수 있어야 위젯 테스트가
/// 이미지 로드 실패 예외 없이 돈다.
const String _onePixelPngBase64 =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==';

void main() {
  late Directory tempDir;
  late File imageFile;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('worldcup_desc_dialog');
    imageFile = File('${tempDir.path}/sample.png')
      ..writeAsBytesSync(base64Decode(_onePixelPngBase64));
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  /// 다이얼로그를 띄우고 pop 결과를 담아두는 하네스.
  Future<List<String?>> pumpDialog(WidgetTester tester) async {
    final List<String?> results = [];
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              results.add(
                await showDialog<String>(
                  context: context,
                  builder: (context) =>
                      WorldCupImageDescriptionDialog(imagePath: imageFile.path),
                ),
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return results;
  }

  testWidgets('설명을 입력하고 확인하면 예외 없이 그 값을 돌려준다', (tester) async {
    // 컨트롤러를 호출부가 await 직후 해제하던 시절에는, 아직 퇴장 애니메이션
    // 중이던 TextFormField가 해제된 컨트롤러를 써서 트리 해제가 중단되고
    // `_dependents.isEmpty` 어설션으로 앱 전체가 에러 화면이 되었다.
    final results = await pumpDialog(tester);

    await tester.enterText(find.byType(TextFormField), '사진 설명');
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(WorldCupImageDescriptionDialog), findsNothing);
    expect(results, ['사진 설명']);
  });

  testWidgets('설명이 비어 있으면 닫히지 않고 오류를 보여준다', (tester) async {
    final results = await pumpDialog(tester);

    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();

    expect(find.text('사진 설명을 입력해주세요.'), findsOneWidget);
    expect(find.byType(WorldCupImageDescriptionDialog), findsOneWidget);
    expect(results, isEmpty);
  });

  testWidgets('설명은 20자를 넘길 수 없다', (tester) async {
    final results = await pumpDialog(tester);

    await tester.enterText(find.byType(TextFormField), 'ㄱ' * 25);
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();

    expect(results.single, hasLength(20));
  });

  testWidgets('취소하면 null을 돌려준다', (tester) async {
    final results = await pumpDialog(tester);

    await tester.enterText(find.byType(TextFormField), '버려질 설명');
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(results, [null]);
  });
}
