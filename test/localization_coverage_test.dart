import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_worldcup_local/screens/help_screen.dart';
import 'package:worldcup_ui_kit/worldcup_ui_kit.dart';
import 'package:worldcup_ui_kit/src/l10n/generated/app_localizations_ko.dart';
import 'package:worldcup_ui_kit/src/l10n/generated/app_localizations_ja.dart';

void main() {
  testWidgets('열린 온보딩은 언어가 바뀌면 제목, 본문, 버튼과 다음 페이지를 갱신한다', (tester) async {
    final semantics = tester.ensureSemantics();
    Widget app(Locale locale) => MaterialApp(
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: const HelpScreen(
        false,
        enableBottomSheetSelectionPagerTransition: true,
      ),
    );
    await tester.pumpWidget(app(const Locale('ko')));
    await tester.pumpAndSettle();
    expect(find.text('앱을 실행해주셔서 감사합니다!'), findsOneWidget);

    final previousState = tester.state(find.byType(HelpScreen));
    await tester.pumpWidget(app(const Locale('ja')));
    await tester.pumpAndSettle();
    expect(tester.state(find.byType(HelpScreen)), same(previousState));
    expect(find.text('アプリをご利用いただきありがとうございます！'), findsOneWidget);
    expect(find.text('スキップ'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('全5ページ中1ページ目')), findsOneWidget);
    await tester.tap(find.text('次へ'));
    await tester.pumpAndSettle();
    expect(find.text('ワールドカップの作り方 1'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('全5ページ中2ページ目')), findsOneWidget);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  test('일본어 리소스에 누락, 한국어 잔류, placeholder 변경이 없다', () {
    Map<String, dynamic> read(String locale) => jsonDecode(
      File('packages/worldcup_ui_kit/lib/l10n/app_$locale.arb')
          .readAsStringSync(),
    ) as Map<String, dynamic>;
    final ko = read('ko');
    final ja = read('ja');
    final keys = ko.keys.where((key) => !key.startsWith('@')).toSet();
    expect(ja.keys.where((key) => !key.startsWith('@')).toSet(), keys);
    final placeholders = RegExp(r'\{(\w+)(?:\}|,)');
    for (final key in keys) {
      final text = ja[key] as String;
      expect(text.trim(), isNotEmpty, reason: key);
      expect(RegExp('[가-힣]').hasMatch(text), isFalse, reason: key);
      Set<String> variables(String value) =>
          placeholders.allMatches(value).map((match) => match[1]!).toSet();
      expect(variables(text), variables(ko[key] as String), reason: key);
      expect(
        ja['@$key']?['placeholders'],
        ko['@$key']?['placeholders'],
        reason: key,
      );
    }
  });

  test('일본어 샘플 매핑은 모든 후보를 번역하고 사용자 콘텐츠는 보존한다', () async {
    final ja = AppLocalizationsJa();
    final manifest = jsonDecode(
      await rootBundle.loadString('assets/sample/sample_worldcups.json'),
    ) as Map<String, dynamic>;
    for (final cup in manifest['worldCups'] as List) {
      final id = cup['idx'] as int;
      final texts = [
        ja.worldCupTitle(id, ''),
        ja.worldCupInfo(id, ''),
        for (final item in cup['items'] as List)
          ja.worldCupItemInfo(id, item['image'] as String, ''),
      ];
      for (final text in texts) {
        expect(text, isNotEmpty);
        expect(RegExp('[가-힣]').hasMatch(text), isFalse);
      }
    }
    expect(ja.worldCupTitle(1, '사용자 제목'), '사용자 제목');
    expect(
      ja.worldCupItemInfo(1, 'assets/sample/female/chu.jpg', '내 후보'),
      '내 후보',
    );
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
