# 다국어 리소스 관리

이슈 #29의 1단계: Flutter 공식 `gen-l10n`과 언어별 ARB로 다국어 기반을 구성한다.
한국어가 원본이자 기본 언어다. 현재 지원 언어는 한국어(`ko`), 일본어(`ja`), 영어(`en`)다.

## 파일 위치

- `packages/worldcup_ui_kit/lib/l10n/app_ko.arb`: 직접 편집하는 한국어 원본.
- 같은 폴더의 `app_<언어 코드>.arb`: 이후 추가할 언어별 번역.
- `packages/worldcup_ui_kit/l10n.yaml`: 생성 설정. `template-arb-file`과
  `preferred-supported-locales: [ko]`는 한국어 기준으로 유지한다.
- `packages/worldcup_ui_kit/lib/src/l10n/generated/`: 자동 생성 Dart 코드.
  직접 수정하지 않고 ARB 변경과 함께 커밋한다. CI가 재생성 후 차이를 검사한다.

공용 UI 패키지는 앱과 모든 feature에서 참조하므로 번역을 쓰기 위해
feature 사이의 의존성을 추가할 필요가 없다. 순수 Dart인 core/domain 및
데이터 계층에는 Flutter 번역 API를 넣지 않는다. 오류 코드나 결과를 UI에서
번역하며, 비동기 처리 후에는 mounted 확인 뒤 최신 context에서 번역을 읽는다.

## 문구 추가 및 사용

한국어 ARB에 의미를 나타내는 camelCase 키와 `@키.description`을 추가한다.
기능별 접두사(예: `worldCup`, `editor`, `play`, `support`)로 찾기 쉽게 관리한다.
문장을 조각내서 합치지 말고 변수는 ICU placeholder로 표현한다. 예:

```json
"editorItemCount": "후보 {count}개",
"@editorItemCount": {
  "description": "편집 중인 월드컵의 후보 수",
  "placeholders": { "count": { "type": "int", "example": "16" } }
}
```

저장소 루트에서 의존성을 설치한 뒤 공용 UI 패키지에서 생성한다.
아래 명령은 PowerShell과 일반 셸 모두에서 사용할 수 있다.

```sh
flutter pub get
cd packages/worldcup_ui_kit
flutter gen-l10n
cd ../..
dart run tool/generate_native_localizations.dart
flutter analyze
flutter test
flutter test packages/worldcup_ui_kit
```

```dart
import 'package:worldcup_ui_kit/worldcup_ui_kit.dart';

final l10n = AppLocalizations.of(context);
Text(l10n.worldCupCreate);
Text(l10n.editorItemCount(16));
```

독립적인 위젯 테스트의 `MaterialApp`에도 아래 설정이 필요하다.
번역 API는 이 MaterialApp 아래의 context에서 사용한다.

```dart
localizationsDelegates: AppLocalizations.localizationsDelegates,
supportedLocales: AppLocalizations.supportedLocales,
```

## 언어 선택과 번역 추가

앱은 기기의 선호 언어 목록을 Flutter 표준 규칙으로 매칭한다. 지원되는 언어가
없으면 지원 목록의 첫 언어인 한국어로 열린다. 일본어 기기에서는 일본어로,
영어 기기에서는 영어로 표시된다. 프랑스어 등 미지원 언어만 설정된 기기는
한국어로 표시된다. 영어는 지역 공통 `en` 리소스를 사용한다.
앱 내부 언어 선택/저장은 제공하지 않는다.

현재 온보딩, 목록/검색, 편집, 경기/결과, 공유/수신, 공지/문의, 업데이트 안내,
공용 버튼의 표시 문구·검증 오류·접근성 레이블을 모두 리소스로 연결했다.
기본 샘플의 제목·설명·후보 이름과 외부 공유 카드의 문구도 포함한다.
이미지 안의 글자는 대상이 아니다. 사용자 작성 내용과 서버 공지 본문,
외부에서 받은 기기 이름은 콘텐츠이므로 자동 번역하지 않는다.
개발용 페이징 시드 데이터와 로그·진단 문자열도 번역 대상에서 제외한다.
외부 광고 콘텐츠와 광고 SDK의 자체 버튼은 해당 공급자가 관리한다.

1. 새 언어는 `app_<언어 코드>.arb`를 만들고 `@@locale`을 해당 코드로 지정한다. 한국어와 동일한 키로
   번역하고 placeholder 이름과 타입을 유지한다. 지원 언어 등록은 ARB에서 자동
   생성되므로 Dart의 supportedLocales를 수동 수정하지 않는다.
2. 생성기는 번역이 빠진 키를 한국어 원본으로 보완한다. 생성 경고를 확인하고
   출시 전 모든 키를 번역한다. 일본어·영어 키 누락은 테스트에서도 검사한다.
   한국어 fallback 순서는 그대로 유지한다.
3. 두 생성 명령을 실행한다. Android 앱 이름과 iOS 앱 이름·권한 안내는
   `tool/generate_native_localizations.dart`가 같은 ARB에서 생성한다.
   Android는 기본 `values/strings.xml`에 한국어를 두고 추가 언어는
   `values-b+ja/strings.xml` 같은 폴더로 생성한다.
4. iOS `ios/Runner/Info.plist`의 `CFBundleLocalizations`에 언어를 추가하고,
   Xcode에서 생성된 `<언어 코드>.lproj/InfoPlist.strings`를 기존 `InfoPlist.strings`
   언어 그룹 및 Runner 리소스에 등록한다. 일본어·영어는 이미 등록되어 있다.
   개발 언어는 `ko`로 유지한다.
5. 한국어 회귀 테스트와 일본어·영어 선택 테스트, 프랑스어 등 미지원 언어의 한국어
   fallback 검증을 유지하고 새 언어의 선택 테스트를 추가한다.
6. 긴 번역/큰 글자에서 줄바꿈과 잘림을 확인한다. 실제 Android/iOS 기기에서
   시스템 공유·권한 안내도 확인한다. 서드파티 OS UI 자체의 문구는 해당 SDK와
   운영체제가 관리한다.

## 상태, 오류, 기본 샘플

- `worldcup_core`의 `AppMessage`는 언어에 독립적인 `AppMessageId`와 선택적인
  동적 내용(`detail`)만 가진다. 전송 상태와 문의 검증도 이 타입을 사용한다.
  UI에서 `l10n.message(value)`로 표시하므로 상태가 유지된 채 언어가 바뀌어도
  새 언어를 사용한다. 상태/오류를 추가하면 ARB 키와 enum, UI의 exhaustive
  switch를 함께 추가한다.
- `Failure.message` 및 `SupportFailure.message`는 진단용이다. 화면에서 직접
  표시하지 않고 `userMessage`를 번역한다. 네이티브 오류는 코드로 매핑하며
  알 수 없는 오류는 공통 안내로 처리한다. 로그와 개발자 진단은 번역 대상이 아니다.
- 기본 샘플은 `sample_localizations.dart`에서 고정 id 및 이미지 경로로 번역을
  선택한다. 시드 JSON/DB를 번역문으로 덮어쓰지 않는다. 새 샘플을 넣으면
  `sample*` ARB 키와 이 매핑을 추가한다. 미등록 id와 사용자가 만든 콘텐츠는
  원문으로 표시한다. 검색은 원본 저장 데이터 기준이며, 번역된 샘플 이름 검색은
  별도 지원이 필요하다. 현재 일본어·영어로 번역된 샘플 제목을 검색해도 매칭되지 않는다.
- `native*` 키와 `appTitle`을 바꾸면 네이티브 생성 명령도 실행한다.
  생성된 Android XML 및 iOS strings도 커밋한다. CI는 두 생성 결과의 차이를 검사한다.

## 검증

앱 및 각 패키지 테스트를 모두 실행한다(CLAUDE.md 참고).
`test/localization_coverage_test.dart`는 온보딩의 실행 중 언어 변경,
샘플 리소스 누락 및 화면의 한국어 하드코딩 재발을 검사한다.
공용 UI 테스트는 모든 상태/오류 코드의 번역과 동적 내용 보존을 검사한다.
언어 변경 테스트는 실제 한국어·일본어·영어 delegate를 사용한다. 일본어·영어 ARB의 키,
placeholder 일치, 한국어 잔류 및 기본 샘플 매핑도 검사한다.
온보딩 패키지의 기본 영문 페이지 안내는 `progressSemantic`으로 번역한다.
한국어 문구를 검사하는 위젯 테스트는 기기 locale을 명시적으로 `ko`로 지정한다.
영어 지원 추가 후 테스트 런너의 기본 locale(`en`)에 의존하면 기대 언어가 바뀌기 때문이다.

참고: https://docs.flutter.dev/ui/internationalization
