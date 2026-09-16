import 'package:flutter_test/flutter_test.dart';
import 'package:worldcup_core/worldcup_core.dart';
import 'package:worldcup_ui_kit/worldcup_ui_kit.dart';
import 'package:worldcup_ui_kit/src/l10n/generated/app_localizations_ko.dart';
import 'package:worldcup_ui_kit/src/l10n/generated/app_localizations_ja.dart';

void main() {
  final korean = AppLocalizationsKo();
  final japanese = AppLocalizationsJa();
  test('모든 상태 및 오류 식별자는 표시할 메시지를 가진다', () {
    for (final id in AppMessageId.values) {
      expect(korean.message(AppMessage(id)), isNotEmpty, reason: id.name);
      final translated = japanese.message(AppMessage(id, detail: 'テスト'));
      expect(translated, isNotEmpty, reason: id.name);
      expect(RegExp('[가-힣]').hasMatch(translated), isFalse, reason: id.name);
    }
  });
  test('상태는 번역문을 저장하지 않아 같은 상태도 현재 언어로 표시할 수 있다', () {
    const state = AppMessage(AppMessageId.nearbySending);
    expect(korean.message(state), '월드컵을 보내고 있습니다.');
    expect(japanese.message(state), 'ワールドカップを送信しています。');
  });
  test('동적 문장에 들어가는 사용자 내용과 진단 메시지를 구분한다', () {
    const title = '사용자 {title} 및 \$name';
    expect(korean.listImported(title), '"$title" 월드컵을 가져왔습니다.');
    expect(
      korean.message(
        const AppMessage(AppMessageId.packageImageMissing, detail: title),
      ),
      '이미지 파일을 찾을 수 없습니다: $title',
    );
    const error = PackageFailure('private internal details');
    expect(korean.message(error.userMessage), korean.unexpectedError);
    expect(korean.message(error.userMessage), isNot(contains(error.message)));
  });
}
