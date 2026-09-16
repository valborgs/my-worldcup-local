import 'dart:convert';
import 'dart:io';

// Run from the repository root after editing ARB files.
// Flutter renders in-app text; Android/iOS read their own resources before Dart
// starts. Generate both from the same language catalog to avoid duplicate edits.
void main() {
  final directory = Directory('packages/worldcup_ui_kit/lib/l10n');
  final korean = jsonDecode(
    File('${directory.path}/app_ko.arb').readAsStringSync(),
  ) as Map<String, dynamic>;
  final files =
      directory
          .listSync()
          .whereType<File>()
          .where((file) => file.path.endsWith('.arb'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));
  for (final file in files) {
    final messages =
        jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    final locale = messages['@@locale'] as String;
    String value(String key) => (messages[key] ?? korean[key]) as String;
    final qualifier = locale == 'ko'
        ? 'values'
        : 'values-b+${locale.replaceAll('_', '+')}';
    final android = File('android/app/src/main/res/$qualifier/strings.xml');
    android.parent.createSync(recursive: true);
    final appTitle = const HtmlEscape()
        .convert(value('appTitle'))
        .replaceAll("'", r"\'");
    android.writeAsStringSync('''<?xml version="1.0" encoding="utf-8"?>
<!-- Generated from app_$locale.arb. Do not edit. -->
<resources>
    <string name="app_name">$appTitle</string>
</resources>
''');
    final ios = File(
      'ios/Runner/${locale.replaceAll('_', '-')}.lproj/InfoPlist.strings',
    );
    ios.parent.createSync(recursive: true);
    final keys = {
      'CFBundleDisplayName': 'appTitle',
      'NSBluetoothAlwaysUsageDescription': 'nativeBluetoothPermission',
      'NSLocalNetworkUsageDescription': 'nativeLocalNetworkPermission',
      'NSCameraUsageDescription': 'nativeCameraPermission',
      'NSPhotoLibraryUsageDescription': 'nativePhotosPermission',
    };
    ios.writeAsStringSync(
      [
        '// Generated from app_$locale.arb. Do not edit.',
        for (final entry in keys.entries)
          '${jsonEncode(entry.key)} = ${jsonEncode(value(entry.value))};',
        '',
      ].join('\n'),
    );
  }
}
