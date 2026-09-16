import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_worldcup_local/screens/help_screen.dart';
import 'package:worldcup_ui_kit/worldcup_ui_kit.dart';
import 'package:worldcup_ui_kit/src/l10n/generated/app_localizations_ko.dart';

void main() {
  testWidgets('열린 온보딩은 언어가 바뀌면 제목, 본문, 버튼과 다음 페이지를 갱신한다', (tester) async {
    Widget app(Locale locale) => MaterialApp(
      locale: locale,
      supportedLocales: const [Locale('ko'), Locale('en')],
      localizationsDelegates: const [
        _PreviewDelegate(),
        ...AppLocalizations.localizationsDelegates,
      ],
      home: const HelpScreen(
        false,
        enableBottomSheetSelectionPagerTransition: true,
      ),
    );
    await tester.pumpWidget(app(const Locale('ko')));
    await tester.pumpAndSettle();
    expect(find.text('앱을 실행해주셔서 감사합니다!'), findsOneWidget);

    final previousState = tester.state(find.byType(HelpScreen));
    await tester.pumpWidget(app(const Locale('en')));
    await tester.pumpAndSettle();
    expect(tester.state(find.byType(HelpScreen)), same(previousState));
    expect(find.text('Preview welcome'), findsOneWidget);
    expect(find.text('Preview skip'), findsOneWidget);
    await tester.tap(find.text('Preview next'));
    await tester.pumpAndSettle();
    expect(find.text('Preview create'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('이미지 이외의 기본 샘플 문구는 한국어 리소스와 일치한다', () async {
    final l10n = AppLocalizationsKo();
    final manifest = jsonDecode(
      await rootBundle.loadString('assets/sample/sample_worldcups.json'),
    ) as Map<String, dynamic>;
    for (final cup in manifest['worldCups'] as List) {
      final id = cup['idx'] as int;
      // Empty fallbacks ensure the test catches missing sample mappings.
      expect(l10n.worldCupTitle(id, ''), cup['title']);
      expect(l10n.worldCupInfo(id, ''), cup['info']);
      for (final item in cup['items'] as List) {
        expect(
          l10n.worldCupItemInfo(id, item['image'] as String, ''),
          item['info'],
        );
      }
    }
    expect(l10n.worldCupTitle(1, '사용자 제목'), '사용자 제목');
    expect(l10n.worldCupInfo(1, '사용자 설명'), '사용자 설명');
    expect(
      l10n.worldCupItemInfo(1, 'assets/sample/female/aespa_carina.jpg', '내 후보'),
      '내 후보',
    );
  });

  test('화면 소스에 한국어 표시 문구를 다시 하드코딩하지 않는다', () {
    final files = <File>[
      File('lib/app_router.dart'),
      File('lib/update/in_app_update_host.dart'),
      ...Directory('lib/screens').listSync().whereType<File>(),
      for (final package in Directory(
        'packages',
      ).listSync().whereType<Directory>())
        for (final folder in ['screens', 'widgets'])
          if (Directory('${package.path}/lib/src/$folder').existsSync())
            ...Directory('${package.path}/lib/src/$folder')
                .listSync()
                .whereType<File>(),
    ];
    final tokens = RegExp(
      r'''//[^\n]*|/\*[\s\S]*?\*/|'(?:\\.|[^'\\])*'|"(?:\\.|[^"\\])*"''',
    );
    final hangul = RegExp('[가-힣]');
    final failures = <String>[];
    for (final file in files.where((file) => file.path.endsWith('.dart'))) {
      for (final match in tokens.allMatches(file.readAsStringSync())) {
        final token = match.group(0)!;
        if (!token.startsWith('/') && hangul.hasMatch(token)) {
          failures.add('${file.path}: $token');
        }
      }
    }
    expect(failures, isEmpty, reason: failures.join('\n'));
  });
}

// Test-only language: proves wiring without advertising unfinished translations.
class _PreviewEnglish extends AppLocalizationsKo {
  _PreviewEnglish() : super('en');
  @override
  String get onboardingWelcome => 'Preview welcome';
  @override
  String get onboardingSkip => 'Preview skip';
  @override
  String get commonNext => 'Preview next';
  @override
  String get onboardingCreateOneTitle => 'Preview create';
}

class _PreviewDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _PreviewDelegate();
  @override
  bool isSupported(Locale locale) => ['ko', 'en'].contains(locale.languageCode);
  @override
  Future<AppLocalizations> load(Locale locale) => SynchronousFuture(
    locale.languageCode == 'en' ? _PreviewEnglish() : AppLocalizationsKo(),
  );
  @override
  bool shouldReload(_PreviewDelegate old) => false;
}
