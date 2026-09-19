import 'dart:convert';
import 'dart:io';

import 'package:feature_worldcup_editor/src/widgets/worldcup_add_picture_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worldcup_ui_kit/worldcup_ui_kit.dart';

/// 1x1 투명 PNG.
const String _onePixelPngBase64 =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==';

/// 플레이스홀더 이미지(`assets/images/free_character.png`)는 앱 패키지의
/// 에셋이라 이 패키지에서 테스트를 돌리면 로드에 실패한다. PNG 요청에만
/// 1x1 PNG를 돌려주고, 매니페스트 등 나머지는 실제 번들에 맡긴다.
class _FakeAssetBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async => key.endsWith('.png')
      ? ByteData.sublistView(base64Decode(_onePixelPngBase64))
      : rootBundle.load(key);
}

Widget _harness({
  double scale = 1.0,
  bool asRoute = false,
  String? existingImagePath,
}) {
  return DefaultAssetBundle(
    bundle: _FakeAssetBundle(),
    child: MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: asRoute
          // 실제 앱처럼 showDialog로 띄워야 키보드 인셋을 그대로 받는다.
          ? Builder(
              builder: (context) => TextButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => WorldCupAddPictureDialog(
                    isEditMode: existingImagePath != null,
                    existingImagePath: existingImagePath,
                  ),
                ),
                child: const Text('open'),
              ),
            )
          : const Scaffold(body: WorldCupAddPictureDialog()),
    ),
  );
}

void main() {
  for (final scale in [1.0, 1.5]) {
    testWidgets('English photo actions fit a narrow screen at $scale', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(320, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(_harness(scale: scale));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('Add'));
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();
      expect(find.text('Please add a photo'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('키보드가 올라와도 버튼은 스크롤 없이 누를 수 있다', (tester) async {
    // 버튼이 content 안에 있던 시절에는 입력창에 포커스가 가면 입력창만 보일
    // 만큼 스크롤되어 그 아래 버튼이 키보드 위로 잘려 나갔다.
    tester.view.devicePixelRatio = 2.625;
    tester.view.physicalSize = const Size(1080, 2340);
    addTearDown(tester.view.reset);
    // 미리보기(200dp)가 있어야 키보드 위 공간이 모자란다. 편집 모드로 기존
    // 사진을 넘겨 사진을 고른 상태를 만든다.
    final Directory tempDir = Directory.systemTemp.createTempSync('add_pic');
    addTearDown(() => tempDir.deleteSync(recursive: true));
    final File image = File('${tempDir.path}/sample.png')
      ..writeAsBytesSync(base64Decode(_onePixelPngBase64));

    await tester.pumpWidget(
      _harness(asRoute: true, existingImagePath: image.path),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(TextFormField));
    tester.view.viewInsets = const FakeViewPadding(bottom: 1150);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    // 키보드 위로 남은 영역 안에 두 버튼이 온전히 들어와 있어야 한다.
    const double visibleBottom = (2340 - 1150) / 2.625;
    for (final label in ['Cancel', 'Edit']) {
      final Rect rect = tester.getRect(find.text(label));
      expect(rect.top, greaterThanOrEqualTo(0), reason: label);
      expect(rect.bottom, lessThanOrEqualTo(visibleBottom), reason: label);
    }
  });
}
