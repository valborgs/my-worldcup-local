import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../tool/generate_native_localizations.dart' as generator;

void main() {
  test('Android 앱 이름의 XML 및 Android 특수문자를 보존한다', () {
    final previous = Directory.current;
    final temp = Directory.systemTemp.createTempSync('native_l10n_');
    addTearDown(() {
      Directory.current = previous;
      temp.deleteSync(recursive: true);
    });
    Directory.current = temp;
    final source = File('packages/worldcup_ui_kit/lib/l10n/app_ko.arb');
    source.parent.createSync(recursive: true);
    for (final entry in {
      'Let\'s "Cup" & <Fun> \\': r'''Let\'s \"Cup\" &amp; &lt;Fun&gt; \\''',
      '@cup': r'\@cup',
      '?cup': r'\?cup',
    }.entries) {
      source.writeAsStringSync(
        jsonEncode({
          '@@locale': 'ko',
          'appTitle': entry.key,
          'nativeBluetoothPermission': 'Bluetooth',
          'nativeLocalNetworkPermission': 'Network',
          'nativeCameraPermission': 'Camera',
          'nativePhotosPermission': 'Photos',
        }),
      );
      generator.main();
      expect(
        File('android/app/src/main/res/values/strings.xml').readAsStringSync(),
        contains('<string name="app_name">${entry.value}</string>'),
      );
    }
  });
}
