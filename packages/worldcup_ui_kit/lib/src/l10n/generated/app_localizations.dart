import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ko'),
    Locale('en'),
    Locale('ja'),
  ];

  /// 온보딩 페이지 표시기의 접근성 안내
  ///
  /// In ko, this message translates to:
  /// **'전체 {total}페이지 중 {current}페이지'**
  String onboardingProgress(int current, int total);

  /// 앱의 표시 제목
  ///
  /// In ko, this message translates to:
  /// **'내가 만든 월드컵'**
  String get appTitle;

  /// 월드컵 추가 버튼의 툴팁과 접근성 레이블
  ///
  /// In ko, this message translates to:
  /// **'월드컵 추가 메뉴'**
  String get worldCupAddMenu;

  /// 월드컵 추가 방법 바텀시트 제목
  ///
  /// In ko, this message translates to:
  /// **'월드컵 추가 방법 선택'**
  String get worldCupAddMethodTitle;

  /// 새 월드컵 생성 메뉴
  ///
  /// In ko, this message translates to:
  /// **'새 월드컵 만들기'**
  String get worldCupCreate;

  /// 새 월드컵 생성 메뉴 설명
  ///
  /// In ko, this message translates to:
  /// **'사진을 골라 나만의 월드컵 만들기'**
  String get worldCupCreateDescription;

  /// 주변 기기 수신 메뉴
  ///
  /// In ko, this message translates to:
  /// **'주변 기기에서 받기'**
  String get worldCupReceiveNearby;

  /// 주변 기기 수신 설명. Nearby Connections는 서비스 이름
  ///
  /// In ko, this message translates to:
  /// **'인터넷 없이 Nearby Connections로 직접 받기'**
  String get worldCupReceiveNearbyDescription;

  /// 월드컵 파일 가져오기 메뉴
  ///
  /// In ko, this message translates to:
  /// **'파일에서 가져오기'**
  String get worldCupImportFile;

  /// 파일 가져오기 설명. .myworldcup 확장자는 번역하지 않음
  ///
  /// In ko, this message translates to:
  /// **'.myworldcup 파일을 직접 선택하여 가져오기'**
  String get worldCupImportFileDescription;

  /// 네
  ///
  /// In ko, this message translates to:
  /// **'네'**
  String get commonYes;

  /// 아니오
  ///
  /// In ko, this message translates to:
  /// **'아니오'**
  String get commonNo;

  /// 취소
  ///
  /// In ko, this message translates to:
  /// **'취소'**
  String get commonCancel;

  /// 확인
  ///
  /// In ko, this message translates to:
  /// **'확인'**
  String get commonConfirm;

  /// 다음
  ///
  /// In ko, this message translates to:
  /// **'다음'**
  String get commonNext;

  /// 이전
  ///
  /// In ko, this message translates to:
  /// **'이전'**
  String get commonPrevious;

  /// 닫기
  ///
  /// In ko, this message translates to:
  /// **'닫기'**
  String get commonClose;

  /// 삭제
  ///
  /// In ko, this message translates to:
  /// **'삭제'**
  String get commonDelete;

  /// 수정
  ///
  /// In ko, this message translates to:
  /// **'수정'**
  String get commonEdit;

  /// 추가
  ///
  /// In ko, this message translates to:
  /// **'추가'**
  String get commonAdd;

  /// 시작
  ///
  /// In ko, this message translates to:
  /// **'시작'**
  String get commonStart;

  /// 공유하기
  ///
  /// In ko, this message translates to:
  /// **'공유하기'**
  String get commonShare;

  /// 설명
  ///
  /// In ko, this message translates to:
  /// **'설명'**
  String get commonDescription;

  /// 안내
  ///
  /// In ko, this message translates to:
  /// **'안내'**
  String get commonInfo;

  /// 다시 불러오기
  ///
  /// In ko, this message translates to:
  /// **'다시 불러오기'**
  String get commonRetry;

  /// 앱을 실행해주셔서 감사합니다!
  ///
  /// In ko, this message translates to:
  /// **'앱을 실행해주셔서 감사합니다!'**
  String get onboardingWelcome;

  /// 월드컵 만들기 1
  ///
  /// In ko, this message translates to:
  /// **'월드컵 만들기 1'**
  String get onboardingCreateOneTitle;

  /// 상단의 추가 버튼을 눌러  월드컵을 만들어보세요
  ///
  /// In ko, this message translates to:
  /// **'상단의 추가 버튼을 눌러 \n월드컵을 만들어보세요'**
  String get onboardingCreateOneBody;

  /// 월드컵 만들기 2
  ///
  /// In ko, this message translates to:
  /// **'월드컵 만들기 2'**
  String get onboardingCreateTwoTitle;

  /// 내가 직접 찍은 사진을 골라  리스트에 추가해보세요
  ///
  /// In ko, this message translates to:
  /// **'내가 직접 찍은 사진을 골라 \n리스트에 추가해보세요'**
  String get onboardingCreateTwoBody;

  /// 월드컵 게임 진행
  ///
  /// In ko, this message translates to:
  /// **'월드컵 게임 진행'**
  String get onboardingPlayTitle;

  /// 2개의 사진 중 마음에 든 사진을 선택해보세요
  ///
  /// In ko, this message translates to:
  /// **'2개의 사진 중 마음에 든 사진을 선택해보세요'**
  String get onboardingPlayBody;

  /// 월드컵 게임 우승자
  ///
  /// In ko, this message translates to:
  /// **'월드컵 게임 우승자'**
  String get onboardingWinnerTitle;

  /// 월드컵 우승자를 가려봅시다!
  ///
  /// In ko, this message translates to:
  /// **'월드컵 우승자를 가려봅시다!'**
  String get onboardingWinnerBody;

  /// 도움말, 소개 화면
  ///
  /// In ko, this message translates to:
  /// **'도움말, 소개 화면'**
  String get onboardingSemantics;

  /// 스킵하기
  ///
  /// In ko, this message translates to:
  /// **'스킵하기'**
  String get onboardingSkip;

  /// 시작하기
  ///
  /// In ko, this message translates to:
  /// **'시작하기'**
  String get onboardingStart;

  /// 업데이트 설치를 시작하지 못했습니다. 잠시 후 다시 시도해 주세요.
  ///
  /// In ko, this message translates to:
  /// **'업데이트 설치를 시작하지 못했습니다. 잠시 후 다시 시도해 주세요.'**
  String get updateInstallFailed;

  /// 새 버전을 모두 받았습니다. 재시작하면 적용됩니다.
  ///
  /// In ko, this message translates to:
  /// **'새 버전을 모두 받았습니다. 재시작하면 적용됩니다.'**
  String get updateReady;

  /// 재시작
  ///
  /// In ko, this message translates to:
  /// **'재시작'**
  String get updateRestart;

  /// 업데이트 필요
  ///
  /// In ko, this message translates to:
  /// **'업데이트 필요'**
  String get updateRequiredSemantics;

  /// 업데이트가 필요합니다
  ///
  /// In ko, this message translates to:
  /// **'업데이트가 필요합니다'**
  String get updateRequiredTitle;

  /// 업데이트
  ///
  /// In ko, this message translates to:
  /// **'업데이트'**
  String get updateAction;

  /// 월드컵 수정
  ///
  /// In ko, this message translates to:
  /// **'월드컵 수정'**
  String get editorEditTitle;

  /// 월드컵 등록
  ///
  /// In ko, this message translates to:
  /// **'월드컵 등록'**
  String get editorCreateTitle;

  /// 월드컵 수정 화면
  ///
  /// In ko, this message translates to:
  /// **'월드컵 수정 화면'**
  String get editorEditSemantics;

  /// 월드컵 등록 화면
  ///
  /// In ko, this message translates to:
  /// **'월드컵 등록 화면'**
  String get editorCreateSemantics;

  /// 제목
  ///
  /// In ko, this message translates to:
  /// **'제목'**
  String get editorTitleLabel;

  /// 만드실 월드컵의 제목을 입력해주세요.
  ///
  /// In ko, this message translates to:
  /// **'만드실 월드컵의 제목을 입력해주세요.'**
  String get editorTitleHint;

  /// 만드실 월드컵의 설명을 간단히 입력해주세요.
  ///
  /// In ko, this message translates to:
  /// **'만드실 월드컵의 설명을 간단히 입력해주세요.'**
  String get editorDescriptionHint;

  /// 단일 추가
  ///
  /// In ko, this message translates to:
  /// **'단일 추가'**
  String get editorSingleImage;

  /// 이미지 선택
  ///
  /// In ko, this message translates to:
  /// **'이미지 선택'**
  String get editorPickImage;

  /// 복수 추가
  ///
  /// In ko, this message translates to:
  /// **'복수 추가'**
  String get editorMultipleImages;

  /// 여러개 선택
  ///
  /// In ko, this message translates to:
  /// **'여러개 선택'**
  String get editorPickMultiple;

  /// 제목을 입력해주세요.
  ///
  /// In ko, this message translates to:
  /// **'제목을 입력해주세요.'**
  String get editorTitleRequired;

  /// 설명을 입력해주세요.
  ///
  /// In ko, this message translates to:
  /// **'설명을 입력해주세요.'**
  String get editorDescriptionRequired;

  /// 해당 이미지를 삭제하시겠습니까?
  ///
  /// In ko, this message translates to:
  /// **'해당 이미지를 삭제하시겠습니까?'**
  String get editorDeleteImageConfirmation;

  /// 수정 취소
  ///
  /// In ko, this message translates to:
  /// **'수정 취소'**
  String get editorCancelEditTitle;

  /// 등록 취소
  ///
  /// In ko, this message translates to:
  /// **'등록 취소'**
  String get editorCancelCreateTitle;

  /// 수정을 취소하시겠습니까?
  ///
  /// In ko, this message translates to:
  /// **'수정을 취소하시겠습니까?'**
  String get editorCancelEditBody;

  /// 등록을 취소하시겠습니까?
  ///
  /// In ko, this message translates to:
  /// **'등록을 취소하시겠습니까?'**
  String get editorCancelCreateBody;

  /// 데이터를 저장할 수 없습니다. 잠시후에 다시 시도해주세요.
  ///
  /// In ko, this message translates to:
  /// **'데이터를 저장할 수 없습니다. 잠시후에 다시 시도해주세요.'**
  String get editorSaveFailed;

  /// 월드컵 정보를 아직 불러오는 중입니다. 잠시 후 다시 시도해주세요.
  ///
  /// In ko, this message translates to:
  /// **'월드컵 정보를 아직 불러오는 중입니다. 잠시 후 다시 시도해주세요.'**
  String get editorStillLoading;

  /// 데이터를 업데이트할 수 없습니다. 잠시후에 다시 시도해주세요.
  ///
  /// In ko, this message translates to:
  /// **'데이터를 업데이트할 수 없습니다. 잠시후에 다시 시도해주세요.'**
  String get editorUpdateFailed;

  /// 사진 수정
  ///
  /// In ko, this message translates to:
  /// **'사진 수정'**
  String get editorEditPhoto;

  /// 사진 추가
  ///
  /// In ko, this message translates to:
  /// **'사진 추가'**
  String get editorAddPhoto;

  /// 카메라
  ///
  /// In ko, this message translates to:
  /// **'카메라'**
  String get editorCamera;

  /// 앨범
  ///
  /// In ko, this message translates to:
  /// **'앨범'**
  String get editorAlbum;

  /// 사진을 추가해주세요
  ///
  /// In ko, this message translates to:
  /// **'사진을 추가해주세요'**
  String get editorPhotoRequired;

  /// 사진 설명
  ///
  /// In ko, this message translates to:
  /// **'사진 설명'**
  String get editorPhotoDescription;

  /// 사진 설명을 입력해주세요.
  ///
  /// In ko, this message translates to:
  /// **'사진 설명을 입력해주세요.'**
  String get editorPhotoDescriptionRequired;

  /// 이미지 설명
  ///
  /// In ko, this message translates to:
  /// **'이미지 설명'**
  String get editorImageDescription;

  /// 이미지에 대한 설명을 입력하세요
  ///
  /// In ko, this message translates to:
  /// **'이미지에 대한 설명을 입력하세요'**
  String get editorImageDescriptionHint;

  /// 도움말 및 소통 메뉴
  ///
  /// In ko, this message translates to:
  /// **'도움말 및 소통 메뉴'**
  String get listHelpMenu;

  /// 도움말
  ///
  /// In ko, this message translates to:
  /// **'도움말'**
  String get listHelp;

  /// 공지사항
  ///
  /// In ko, this message translates to:
  /// **'공지사항'**
  String get noticesTitle;

  /// 문의함
  ///
  /// In ko, this message translates to:
  /// **'문의함'**
  String get inquiryTitle;

  /// 내가 만든 월드컵 화면
  ///
  /// In ko, this message translates to:
  /// **'내가 만든 월드컵 화면'**
  String get listScreenSemantics;

  /// 앱 종료
  ///
  /// In ko, this message translates to:
  /// **'앱 종료'**
  String get listExitTitle;

  /// 내가 만든 월드컵을 종료하시겠습니까?
  ///
  /// In ko, this message translates to:
  /// **'내가 만든 월드컵을 종료하시겠습니까?'**
  String get listExitBody;

  /// 선택한 파일을 읽을 수 없습니다.
  ///
  /// In ko, this message translates to:
  /// **'선택한 파일을 읽을 수 없습니다.'**
  String get listReadFileFailed;

  /// 월드컵을 가져올 수 없습니다. 잠시 후 다시 시도해주세요.
  ///
  /// In ko, this message translates to:
  /// **'월드컵을 가져올 수 없습니다. 잠시 후 다시 시도해주세요.'**
  String get listImportFailed;

  /// 오른쪽 상단의 + 버튼을 눌러  월드컵 게임을 추가해주세요
  ///
  /// In ko, this message translates to:
  /// **'오른쪽 상단의 + 버튼을 눌러 \n월드컵 게임을 추가해주세요'**
  String get listEmptyBody;

  /// 항목이 비어있음
  ///
  /// In ko, this message translates to:
  /// **'항목이 비어있음'**
  String get listEmptySemantics;

  /// 맨 앞
  ///
  /// In ko, this message translates to:
  /// **'맨 앞'**
  String get listFirst;

  /// 중간
  ///
  /// In ko, this message translates to:
  /// **'중간'**
  String get listMiddle;

  /// 맨 뒤
  ///
  /// In ko, this message translates to:
  /// **'맨 뒤'**
  String get listLast;

  /// 검색 결과가 없습니다
  ///
  /// In ko, this message translates to:
  /// **'검색 결과가 없습니다'**
  String get listNoSearchResults;

  /// 월드컵을 불러오지 못했습니다. 다시 시도해주세요.
  ///
  /// In ko, this message translates to:
  /// **'월드컵을 불러오지 못했습니다. 다시 시도해주세요.'**
  String get listLoadFailed;

  /// 전체 월드컵 목록 열기
  ///
  /// In ko, this message translates to:
  /// **'전체 월드컵 목록 열기'**
  String get listOpenAll;

  /// 검색 닫기
  ///
  /// In ko, this message translates to:
  /// **'검색 닫기'**
  String get listCloseSearch;

  /// 월드컵 검색
  ///
  /// In ko, this message translates to:
  /// **'월드컵 검색'**
  String get listSearch;

  /// 월드컵 제목 또는 설명 검색
  ///
  /// In ko, this message translates to:
  /// **'월드컵 제목 또는 설명 검색'**
  String get listSearchHint;

  /// 검색어 지우기
  ///
  /// In ko, this message translates to:
  /// **'검색어 지우기'**
  String get listClearSearch;

  /// 두 번 탭하여 현재 월드컵을 열거나 위아래로 쓸어 넘기세요
  ///
  /// In ko, this message translates to:
  /// **'두 번 탭하여 현재 월드컵을 열거나 위아래로 쓸어 넘기세요'**
  String get listPagerHint;

  /// 월드컵 게임 타이틀
  ///
  /// In ko, this message translates to:
  /// **'월드컵 게임 타이틀'**
  String get listTitleSemantics;

  /// 월드컵 최대 라운드
  ///
  /// In ko, this message translates to:
  /// **'월드컵 최대 라운드'**
  String get listMaxRoundSemantics;

  /// 월드컵 제목
  ///
  /// In ko, this message translates to:
  /// **'월드컵 제목'**
  String get worldCupTitleSemantics;

  /// 월드컵 설명
  ///
  /// In ko, this message translates to:
  /// **'월드컵 설명'**
  String get worldCupDescriptionSemantics;

  /// - 라운드 수를 선택해주세요-
  ///
  /// In ko, this message translates to:
  /// **'- 라운드 수를 선택해주세요- '**
  String get worldCupChooseRound;

  /// 공유 파일 준비 중...
  ///
  /// In ko, this message translates to:
  /// **'공유 파일 준비 중...'**
  String get sharePreparing;

  /// 공유 방법 선택
  ///
  /// In ko, this message translates to:
  /// **'공유 방법 선택'**
  String get shareChooseMethod;

  /// 주변 기기로 보내기
  ///
  /// In ko, this message translates to:
  /// **'주변 기기로 보내기'**
  String get shareNearby;

  /// 인터넷 없이 Nearby Connections로 직접 전송
  ///
  /// In ko, this message translates to:
  /// **'인터넷 없이 Nearby Connections로 직접 전송'**
  String get shareNearbyDescription;

  /// 다른 앱으로 공유하기
  ///
  /// In ko, this message translates to:
  /// **'다른 앱으로 공유하기'**
  String get shareOtherApp;

  /// Quick Share, AirDrop 또는 설치된 앱 사용
  ///
  /// In ko, this message translates to:
  /// **'Quick Share, AirDrop 또는 설치된 앱 사용'**
  String get shareOtherAppDescription;

  /// 월드컵을 공유할 수 없습니다. 잠시 후 다시 시도해주세요.
  ///
  /// In ko, this message translates to:
  /// **'월드컵을 공유할 수 없습니다. 잠시 후 다시 시도해주세요.'**
  String get sharePackageFailed;

  /// 데이터를 삭제할 수 없습니다. 잠시후에 다시 시도해주세요.
  ///
  /// In ko, this message translates to:
  /// **'데이터를 삭제할 수 없습니다. 잠시후에 다시 시도해주세요.'**
  String get listDeleteFailed;

  /// 게임 종료
  ///
  /// In ko, this message translates to:
  /// **'게임 종료'**
  String get playExitTitle;

  /// 게임을 종료하시겠습니까? 진행 상황은 저장되지 않습니다.
  ///
  /// In ko, this message translates to:
  /// **'게임을 종료하시겠습니까?\n진행 상황은 저장되지 않습니다.'**
  String get playExitBody;

  /// 결승
  ///
  /// In ko, this message translates to:
  /// **'결승'**
  String get playFinal;

  /// 항목 이름
  ///
  /// In ko, this message translates to:
  /// **'항목 이름'**
  String get playItemSemantics;

  /// 월드컵 우승자 화면
  ///
  /// In ko, this message translates to:
  /// **'월드컵 우승자 화면'**
  String get resultScreenSemantics;

  /// 축하합니다!
  ///
  /// In ko, this message translates to:
  /// **'축하합니다!'**
  String get resultCongratulations;

  /// 축하 문구
  ///
  /// In ko, this message translates to:
  /// **'축하 문구'**
  String get resultCongratulationsSemantics;

  /// 축하
  ///
  /// In ko, this message translates to:
  /// **'축하'**
  String get resultCelebrationSemantics;

  /// 우승자 이름
  ///
  /// In ko, this message translates to:
  /// **'우승자 이름'**
  String get resultWinnerName;

  /// 다시하기
  ///
  /// In ko, this message translates to:
  /// **'다시하기'**
  String get resultReplayIcon;

  /// 다시 하기
  ///
  /// In ko, this message translates to:
  /// **'다시 하기'**
  String get resultReplay;

  /// 다시 하기 버튼
  ///
  /// In ko, this message translates to:
  /// **'다시 하기 버튼'**
  String get resultReplaySemantics;

  /// 공유할 수 없습니다. 잠시 후 다시 시도해주세요.
  ///
  /// In ko, this message translates to:
  /// **'공유할 수 없습니다. 잠시 후 다시 시도해주세요.'**
  String get resultShareFailed;

  /// 사진의 위치 정보 등을 지우는 중…
  ///
  /// In ko, this message translates to:
  /// **'사진의 위치 정보 등을 지우는 중…'**
  String get editorImageProcessing;

  /// 사진을 처리하지 못했습니다. 다른 사진을 선택해 주세요.
  ///
  /// In ko, this message translates to:
  /// **'사진을 처리하지 못했습니다. 다른 사진을 선택해 주세요.'**
  String get editorImageProcessFailed;

  /// 사진 처리 중 {done}/{total}
  ///
  /// In ko, this message translates to:
  /// **'사진 처리 중 {done}/{total}'**
  String editorImageProcessingProgress(int done, int total);

  /// 사진 {count}장을 처리하지 못해 제외했습니다.
  ///
  /// In ko, this message translates to:
  /// **'사진 {count}장을 처리하지 못해 제외했습니다.'**
  String editorImagesProcessFailed(int count);

  /// 해당 사진을 다른 사람과 공유하시겠습니까? 민감한 내용이 없는지 한 번 더 확인해주세요.
  ///
  /// In ko, this message translates to:
  /// **'해당 사진을 다른 사람과 공유하시겠습니까?\n민감한 내용이 없는지 한 번 더 확인해주세요.'**
  String get resultShareConfirmBody;

  /// 선택 버튼
  ///
  /// In ko, this message translates to:
  /// **'선택 버튼'**
  String get commonSelectButton;

  /// 문의를 다시 전송할까요?
  ///
  /// In ko, this message translates to:
  /// **'문의를 다시 전송할까요?'**
  String get inquiryResendTitle;

  /// 이전 문의가 이미 접수되었을 수 있습니다. 다시 전송하면 같은 문의가 중복 접수될 수 있습니다.
  ///
  /// In ko, this message translates to:
  /// **'이전 문의가 이미 접수되었을 수 있습니다. 다시 전송하면 같은 문의가 중복 접수될 수 있습니다.'**
  String get inquiryResendBody;

  /// 다시 전송
  ///
  /// In ko, this message translates to:
  /// **'다시 전송'**
  String get inquiryResend;

  /// 작성을 그만둘까요?
  ///
  /// In ko, this message translates to:
  /// **'작성을 그만둘까요?'**
  String get inquiryLeaveTitle;

  /// 작성 중인 문의는 저장되지 않습니다.
  ///
  /// In ko, this message translates to:
  /// **'작성 중인 문의는 저장되지 않습니다.'**
  String get inquiryLeaveBody;

  /// 계속 작성
  ///
  /// In ko, this message translates to:
  /// **'계속 작성'**
  String get inquiryKeepWriting;

  /// 나가기
  ///
  /// In ko, this message translates to:
  /// **'나가기'**
  String get inquiryLeave;

  /// 문의가 접수되었습니다.
  ///
  /// In ko, this message translates to:
  /// **'문의가 접수되었습니다.'**
  String get inquirySuccess;

  /// 의견을 들려주세요
  ///
  /// In ko, this message translates to:
  /// **'의견을 들려주세요'**
  String get inquiryHeading;

  /// 불편한 점이나 제안하고 싶은 내용을 남겨 주세요.
  ///
  /// In ko, this message translates to:
  /// **'불편한 점이나 제안하고 싶은 내용을 남겨 주세요.'**
  String get inquiryIntroduction;

  /// 이메일 (선택)
  ///
  /// In ko, this message translates to:
  /// **'이메일 (선택)'**
  String get inquiryEmailLabel;

  /// 답변받을 이메일을 남겨 주세요.
  ///
  /// In ko, this message translates to:
  /// **'답변받을 이메일을 남겨 주세요.'**
  String get inquiryEmailHint;

  /// 문의 내용
  ///
  /// In ko, this message translates to:
  /// **'문의 내용'**
  String get inquiryContentLabel;

  /// 문제가 발생한 상황을 자세히 알려 주세요.
  ///
  /// In ko, this message translates to:
  /// **'문제가 발생한 상황을 자세히 알려 주세요.'**
  String get inquiryContentHint;

  /// 이미지 선택 중…
  ///
  /// In ko, this message translates to:
  /// **'이미지 선택 중…'**
  String get inquiryPickingImage;

  /// 스크린샷 첨부 (선택)
  ///
  /// In ko, this message translates to:
  /// **'스크린샷 첨부 (선택)'**
  String get inquiryAttachScreenshot;

  /// 스크린샷 변경
  ///
  /// In ko, this message translates to:
  /// **'스크린샷 변경'**
  String get inquiryChangeScreenshot;

  /// PNG, JPG, WEBP · 최대 10MB · 1장
  ///
  /// In ko, this message translates to:
  /// **'PNG, JPG, WEBP · 최대 10MB · 1장'**
  String get inquiryImageLimit;

  /// 선택한 스크린샷
  ///
  /// In ko, this message translates to:
  /// **'선택한 스크린샷'**
  String get inquirySelectedScreenshot;

  /// 이미지를 표시할 수 없습니다. 다른 파일을 선택해 주세요.
  ///
  /// In ko, this message translates to:
  /// **'이미지를 표시할 수 없습니다. 다른 파일을 선택해 주세요.'**
  String get inquiryImageDisplayFailed;

  /// 스크린샷
  ///
  /// In ko, this message translates to:
  /// **'스크린샷'**
  String get inquiryScreenshot;

  /// 첨부 제거
  ///
  /// In ko, this message translates to:
  /// **'첨부 제거'**
  String get inquiryRemoveAttachment;

  /// 첨부 이미지는 외부 이미지 호스팅에 업로드되며 3일 후 만료됩니다. 개인정보가 보이지 않도록 확인해 주세요.
  ///
  /// In ko, this message translates to:
  /// **'첨부 이미지는 외부 이미지 호스팅에 업로드되며 3일 후 만료됩니다. 개인정보가 보이지 않도록 확인해 주세요.'**
  String get inquiryImageNotice;

  /// 이미 접수되었을 수 있습니다. 재전송 시 중복 접수에 유의해 주세요.
  ///
  /// In ko, this message translates to:
  /// **'이미 접수되었을 수 있습니다. 재전송 시 중복 접수에 유의해 주세요.'**
  String get inquiryDeliveryUncertain;

  /// 스크린샷 업로드 중…
  ///
  /// In ko, this message translates to:
  /// **'스크린샷 업로드 중…'**
  String get inquiryUploading;

  /// 문의 접수 중…
  ///
  /// In ko, this message translates to:
  /// **'문의 접수 중…'**
  String get inquirySubmitting;

  /// 문의 등록
  ///
  /// In ko, this message translates to:
  /// **'문의 등록'**
  String get inquirySubmit;

  /// 등록된 공지사항이 없습니다.
  ///
  /// In ko, this message translates to:
  /// **'등록된 공지사항이 없습니다.'**
  String get noticesEmpty;

  /// 공지 첨부 이미지
  ///
  /// In ko, this message translates to:
  /// **'공지 첨부 이미지'**
  String get noticesImageSemantics;

  /// 첨부 이미지를 불러올 수 없습니다.
  ///
  /// In ko, this message translates to:
  /// **'첨부 이미지를 불러올 수 없습니다.'**
  String get noticesImageFailed;

  /// 받는 기기에서 먼저 ‘월드컵 받기’를 열어주세요.
  ///
  /// In ko, this message translates to:
  /// **'받는 기기에서 먼저 ‘월드컵 받기’를 열어주세요.'**
  String get nearbySendIntroduction;

  /// 월드컵 받기
  ///
  /// In ko, this message translates to:
  /// **'월드컵 받기'**
  String get nearbyReceiveTitle;

  /// 주변 기기 전송 취소
  ///
  /// In ko, this message translates to:
  /// **'주변 기기 전송 취소'**
  String get nearbyCancelSemantics;

  /// 전송 취소
  ///
  /// In ko, this message translates to:
  /// **'전송 취소'**
  String get nearbyCancel;

  /// 앱 설정 열기
  ///
  /// In ko, this message translates to:
  /// **'앱 설정 열기'**
  String get nearbyOpenSettings;

  /// 전송 상태
  ///
  /// In ko, this message translates to:
  /// **'전송 상태'**
  String get nearbyStatus;

  /// 발견된 기기
  ///
  /// In ko, this message translates to:
  /// **'발견된 기기'**
  String get nearbyFoundDevices;

  /// 주변 기기를 검색하고 있습니다.
  ///
  /// In ko, this message translates to:
  /// **'주변 기기를 검색하고 있습니다.'**
  String get nearbySearching;

  /// 탭하여 연결
  ///
  /// In ko, this message translates to:
  /// **'탭하여 연결'**
  String get nearbyTapToConnect;

  /// 상대 기기
  ///
  /// In ko, this message translates to:
  /// **'상대 기기'**
  String get nearbyPeer;

  /// 양쪽 기기에 아래 인증 코드가 동일하게 표시되는지 확인하세요.
  ///
  /// In ko, this message translates to:
  /// **'양쪽 기기에 아래 인증 코드가 동일하게 표시되는지 확인하세요.'**
  String get nearbyVerifyIntroduction;

  /// 코드가 다르면 연결하지 마세요.
  ///
  /// In ko, this message translates to:
  /// **'코드가 다르면 연결하지 마세요.'**
  String get nearbyVerifyWarning;

  /// 거절
  ///
  /// In ko, this message translates to:
  /// **'거절'**
  String get nearbyReject;

  /// 코드 일치 · 수락
  ///
  /// In ko, this message translates to:
  /// **'코드 일치 · 수락'**
  String get nearbyAccept;

  /// 확인 버튼
  ///
  /// In ko, this message translates to:
  /// **'확인 버튼'**
  String get editorConfirmSemantics;

  /// 이미지 한 장 추가 버튼
  ///
  /// In ko, this message translates to:
  /// **'이미지 한 장 추가 버튼'**
  String get editorSingleButtonSemantics;

  /// 여러 이미지 추가 버튼
  ///
  /// In ko, this message translates to:
  /// **'여러 이미지 추가 버튼'**
  String get editorMultipleButtonSemantics;

  /// 사진 찍기
  ///
  /// In ko, this message translates to:
  /// **'사진 찍기'**
  String get editorTakePhoto;

  /// 앨범에서 사진 선택
  ///
  /// In ko, this message translates to:
  /// **'앨범에서 사진 선택'**
  String get editorFromAlbum;

  /// 등록된 항목 개수 : {count}개
  ///
  /// In ko, this message translates to:
  /// **'등록된 항목 개수 : {count}개'**
  String editorItemCount(int count);

  /// (샘플) {title}
  ///
  /// In ko, this message translates to:
  /// **'(샘플) {title}'**
  String worldCupSampleTitle(String title);

  /// 최대 라운드 : {round}강
  ///
  /// In ko, this message translates to:
  /// **'최대 라운드 : {round}강'**
  String worldCupMaxRound(int round);

  /// {round} 강
  ///
  /// In ko, this message translates to:
  /// **'{round} 강'**
  String worldCupRoundOption(int round);

  /// 월드컵 {current} / {total}
  ///
  /// In ko, this message translates to:
  /// **'월드컵 {current} / {total}'**
  String listPagerPosition(int current, int total);

  /// 전체 목록 ({count})
  ///
  /// In ko, this message translates to:
  /// **'전체 목록 ({count})'**
  String listAllCount(int count);

  /// 검색 결과 ({count})
  ///
  /// In ko, this message translates to:
  /// **'검색 결과 ({count})'**
  String listSearchCount(int count);

  /// "{title}" 월드컵을 가져왔습니다.
  ///
  /// In ko, this message translates to:
  /// **'\"{title}\" 월드컵을 가져왔습니다.'**
  String listImported(String title);

  /// {title} 게임 화면
  ///
  /// In ko, this message translates to:
  /// **'{title} 게임 화면'**
  String playScreenSemantics(String title);

  /// {title} 우승자
  ///
  /// In ko, this message translates to:
  /// **'{title} 우승자'**
  String resultTitle(String title);

  /// {title} 우승자 : {winner}
  ///
  /// In ko, this message translates to:
  /// **'{title} 우승자 : {winner}'**
  String resultShareDescription(String title, String winner);

  /// {current} / {total}
  ///
  /// In ko, this message translates to:
  /// **'{current} / {total}'**
  String playMatchProgress(int current, int total);

  /// 접수 번호: {id}
  ///
  /// In ko, this message translates to:
  /// **'접수 번호: {id}'**
  String inquiryReceipt(int id);

  /// {count} / 5000
  ///
  /// In ko, this message translates to:
  /// **'{count} / 5000'**
  String inquiryContentCounter(int count);

  /// {seconds}초 후 다시 시도해 주세요.
  ///
  /// In ko, this message translates to:
  /// **'{seconds}초 후 다시 시도해 주세요.'**
  String supportRetryAfter(int seconds);

  /// {page} 페이지
  ///
  /// In ko, this message translates to:
  /// **'{page} 페이지'**
  String noticesPage(int page);

  /// 오류: {message}
  ///
  /// In ko, this message translates to:
  /// **'오류: {message}'**
  String supportErrorSemantics(String message);

  /// 인증 코드 {code}
  ///
  /// In ko, this message translates to:
  /// **'인증 코드 {code}'**
  String nearbyVerificationCode(String code);

  /// 이 기기의 이름: {name}  Bluetooth와 Wi-Fi를 켜주세요. 같은 Wi-Fi 공유기나 인터넷 연결은 필요하지 않습니다.
  ///
  /// In ko, this message translates to:
  /// **'이 기기의 이름: {name}\n\nBluetooth와 Wi-Fi를 켜주세요. 같은 Wi-Fi 공유기나 인터넷 연결은 필요하지 않습니다.'**
  String nearbyReceiveIntroduction(String name);

  /// 이 버전에서는 앱을 계속 사용할 수 없습니다. 최신 버전으로 업데이트해 주세요.
  ///
  /// In ko, this message translates to:
  /// **'이 버전에서는 앱을 계속 사용할 수 없습니다.\n최신 버전으로 업데이트해 주세요.'**
  String get updateRequiredBody;

  /// 처리하지 못했습니다. 잠시 후 다시 시도해 주세요.
  ///
  /// In ko, this message translates to:
  /// **'처리하지 못했습니다. 잠시 후 다시 시도해 주세요.'**
  String get unexpectedError;

  /// 공유할 월드컵 항목이 부족합니다.
  ///
  /// In ko, this message translates to:
  /// **'공유할 월드컵 항목이 부족합니다.'**
  String get packageTooFewItems;

  /// 항목이 너무 많아 공유할 수 없습니다.
  ///
  /// In ko, this message translates to:
  /// **'항목이 너무 많아 공유할 수 없습니다.'**
  String get packageTooManyItems;

  /// 이미지 파일이 너무 큽니다: {detail}
  ///
  /// In ko, this message translates to:
  /// **'이미지 파일이 너무 큽니다: {detail}'**
  String packageImageTooLarge(String detail);

  /// 이미지 파일을 찾을 수 없습니다: {detail}
  ///
  /// In ko, this message translates to:
  /// **'이미지 파일을 찾을 수 없습니다: {detail}'**
  String packageImageMissing(String detail);

  /// 이미지 리소스의 크기가 너무 큽니다.
  ///
  /// In ko, this message translates to:
  /// **'이미지 리소스의 크기가 너무 큽니다.'**
  String get packageResourceTooLarge;

  /// 월드컵 공유 파일을 만들지 못했습니다.
  ///
  /// In ko, this message translates to:
  /// **'월드컵 공유 파일을 만들지 못했습니다.'**
  String get packageCreateFailed;

  /// 공유 파일을 찾을 수 없습니다.
  ///
  /// In ko, this message translates to:
  /// **'공유 파일을 찾을 수 없습니다.'**
  String get packageMissing;

  /// 공유 파일이 너무 큽니다.
  ///
  /// In ko, this message translates to:
  /// **'공유 파일이 너무 큽니다.'**
  String get packageTooLarge;

  /// 올바른 월드컵 공유 파일이 아닙니다.
  ///
  /// In ko, this message translates to:
  /// **'올바른 월드컵 공유 파일이 아닙니다.'**
  String get packageInvalid;

  /// 중복된 리소스가 있는 공유 파일입니다.
  ///
  /// In ko, this message translates to:
  /// **'중복된 리소스가 있는 공유 파일입니다.'**
  String get packageDuplicateResource;

  /// 월드컵 정보가 없거나 손상되었습니다.
  ///
  /// In ko, this message translates to:
  /// **'월드컵 정보가 없거나 손상되었습니다.'**
  String get packageManifestMissing;

  /// 월드컵 정보를 읽을 수 없습니다.
  ///
  /// In ko, this message translates to:
  /// **'월드컵 정보를 읽을 수 없습니다.'**
  String get packageManifestUnreadable;

  /// 안전하지 않은 리소스 경로가 포함되었습니다.
  ///
  /// In ko, this message translates to:
  /// **'안전하지 않은 리소스 경로가 포함되었습니다.'**
  String get packageUnsafePath;

  /// 중복된 이미지 리소스 경로가 포함되었습니다.
  ///
  /// In ko, this message translates to:
  /// **'중복된 이미지 리소스 경로가 포함되었습니다.'**
  String get packageDuplicateImage;

  /// 이미지 리소스가 없거나 손상되었습니다.
  ///
  /// In ko, this message translates to:
  /// **'이미지 리소스가 없거나 손상되었습니다.'**
  String get packageImageDamaged;

  /// 이미지 리소스를 읽을 수 없습니다.
  ///
  /// In ko, this message translates to:
  /// **'이미지 리소스를 읽을 수 없습니다.'**
  String get packageImageUnreadable;

  /// 월드컵 공유 파일을 가져오지 못했습니다.
  ///
  /// In ko, this message translates to:
  /// **'월드컵 공유 파일을 가져오지 못했습니다.'**
  String get packageImportFailed;

  /// 지원하지 않는 월드컵 공유 파일입니다.
  ///
  /// In ko, this message translates to:
  /// **'지원하지 않는 월드컵 공유 파일입니다.'**
  String get packageUnsupported;

  /// 월드컵 정보가 손상되었습니다.
  ///
  /// In ko, this message translates to:
  /// **'월드컵 정보가 손상되었습니다.'**
  String get packageManifestDamaged;

  /// 월드컵 항목 정보가 손상되었습니다.
  ///
  /// In ko, this message translates to:
  /// **'월드컵 항목 정보가 손상되었습니다.'**
  String get packageItemDamaged;

  /// 수신 파일이 완전히 저장되지 않았습니다.
  ///
  /// In ko, this message translates to:
  /// **'수신 파일이 완전히 저장되지 않았습니다.'**
  String get packageIncomplete;

  /// 서비스 연결 설정이 준비되지 않았습니다.
  ///
  /// In ko, this message translates to:
  /// **'서비스 연결 설정이 준비되지 않았습니다.'**
  String get supportConfiguration;

  /// 서비스 주소를 확인해 주세요.
  ///
  /// In ko, this message translates to:
  /// **'서비스 주소를 확인해 주세요.'**
  String get supportAddress;

  /// 서버에 연결하지 못했습니다. 네트워크를 확인해 주세요.
  ///
  /// In ko, this message translates to:
  /// **'서버에 연결하지 못했습니다. 네트워크를 확인해 주세요.'**
  String get supportNetwork;

  /// 올바른 이메일 주소를 입력해 주세요.
  ///
  /// In ko, this message translates to:
  /// **'올바른 이메일 주소를 입력해 주세요.'**
  String get supportEmailInvalid;

  /// 문의 내용은 공백을 제외하고 1~5,000자로 입력해 주세요.
  ///
  /// In ko, this message translates to:
  /// **'문의 내용은 공백을 제외하고 1~5,000자로 입력해 주세요.'**
  String get supportContentInvalid;

  /// 스크린샷을 다시 첨부하거나 제거해 주세요.
  ///
  /// In ko, this message translates to:
  /// **'스크린샷을 다시 첨부하거나 제거해 주세요.'**
  String get supportScreenshotInvalid;

  /// 입력 내용을 확인해 주세요.
  ///
  /// In ko, this message translates to:
  /// **'입력 내용을 확인해 주세요.'**
  String get supportValidation;

  /// 서비스 인증에 실패했습니다. 잠시 후 다시 시도해 주세요.
  ///
  /// In ko, this message translates to:
  /// **'서비스 인증에 실패했습니다. 잠시 후 다시 시도해 주세요.'**
  String get supportAuthentication;

  /// 요청한 정보를 찾을 수 없습니다. 다시 불러와 주세요.
  ///
  /// In ko, this message translates to:
  /// **'요청한 정보를 찾을 수 없습니다. 다시 불러와 주세요.'**
  String get supportNotFound;

  /// 요청이 많아 잠시 기다려야 합니다.
  ///
  /// In ko, this message translates to:
  /// **'요청이 많아 잠시 기다려야 합니다.'**
  String get supportThrottled;

  /// 요청을 처리하지 못했습니다. 잠시 후 다시 시도해 주세요.
  ///
  /// In ko, this message translates to:
  /// **'요청을 처리하지 못했습니다. 잠시 후 다시 시도해 주세요.'**
  String get supportServer;

  /// 서버 응답을 확인하지 못했습니다.
  ///
  /// In ko, this message translates to:
  /// **'서버 응답을 확인하지 못했습니다.'**
  String get supportInvalidResponse;

  /// 공지사항 응답을 확인하지 못했습니다.
  ///
  /// In ko, this message translates to:
  /// **'공지사항 응답을 확인하지 못했습니다.'**
  String get supportNoticesResponse;

  /// 접수 결과를 확인하지 못했습니다.
  ///
  /// In ko, this message translates to:
  /// **'접수 결과를 확인하지 못했습니다.'**
  String get supportReceiptResponse;

  /// 이미지 업로드 설정이 준비되지 않았습니다.
  ///
  /// In ko, this message translates to:
  /// **'이미지 업로드 설정이 준비되지 않았습니다.'**
  String get supportImageConfiguration;

  /// 스크린샷을 업로드하지 못했습니다. 다시 시도하거나 첨부를 제거해 주세요.
  ///
  /// In ko, this message translates to:
  /// **'스크린샷을 업로드하지 못했습니다. 다시 시도하거나 첨부를 제거해 주세요.'**
  String get supportImageUpload;

  /// 업로드된 이미지 주소를 문의에 사용할 수 없습니다. 첨부를 제거하고 문의해 주세요.
  ///
  /// In ko, this message translates to:
  /// **'업로드된 이미지 주소를 문의에 사용할 수 없습니다. 첨부를 제거하고 문의해 주세요.'**
  String get supportImageResponse;

  /// 공지사항을 불러오지 못했습니다.
  ///
  /// In ko, this message translates to:
  /// **'공지사항을 불러오지 못했습니다.'**
  String get supportNoticesFailed;

  /// 문의 내용을 입력해 주세요.
  ///
  /// In ko, this message translates to:
  /// **'문의 내용을 입력해 주세요.'**
  String get supportContentRequired;

  /// 문의 내용은 5,000자까지 입력할 수 있습니다.
  ///
  /// In ko, this message translates to:
  /// **'문의 내용은 5,000자까지 입력할 수 있습니다.'**
  String get supportContentTooLong;

  /// 10MB 이하의 이미지를 선택해 주세요.
  ///
  /// In ko, this message translates to:
  /// **'10MB 이하의 이미지를 선택해 주세요.'**
  String get supportImageSize;

  /// 이미지를 열지 못했습니다. 다른 파일을 선택해 주세요.
  ///
  /// In ko, this message translates to:
  /// **'이미지를 열지 못했습니다. 다른 파일을 선택해 주세요.'**
  String get supportImageSelection;

  /// 비어 있는 파일은 첨부할 수 없습니다.
  ///
  /// In ko, this message translates to:
  /// **'비어 있는 파일은 첨부할 수 없습니다.'**
  String get supportImageEmpty;

  /// 문의 접수를 완료하지 못했습니다.
  ///
  /// In ko, this message translates to:
  /// **'문의 접수를 완료하지 못했습니다.'**
  String get supportInquiryFailed;

  /// 준비 중입니다.
  ///
  /// In ko, this message translates to:
  /// **'준비 중입니다.'**
  String get nearbyPreparing;

  /// 받는 기기를 찾고 있습니다.
  ///
  /// In ko, this message translates to:
  /// **'받는 기기를 찾고 있습니다.'**
  String get nearbyDiscovering;

  /// 주변 기기를 찾지 못했습니다. 받는 기기에서 월드컵 받기를 열고 다시 시도해주세요.
  ///
  /// In ko, this message translates to:
  /// **'주변 기기를 찾지 못했습니다. 받는 기기에서 월드컵 받기를 열고 다시 시도해주세요.'**
  String get nearbyDiscoveryTimeout;

  /// 월드컵을 받을 준비가 되었습니다.
  ///
  /// In ko, this message translates to:
  /// **'월드컵을 받을 준비가 되었습니다.'**
  String get nearbyReady;

  /// {detail}에 연결을 요청하고 있습니다.
  ///
  /// In ko, this message translates to:
  /// **'{detail}에 연결을 요청하고 있습니다.'**
  String nearbyRequestingConnection(String detail);

  /// 기기 연결 시간이 초과되었습니다. 다시 시도해주세요.
  ///
  /// In ko, this message translates to:
  /// **'기기 연결 시간이 초과되었습니다. 다시 시도해주세요.'**
  String get nearbyConnectionTimeout;

  /// 상대 기기의 확인을 기다리고 있습니다.
  ///
  /// In ko, this message translates to:
  /// **'상대 기기의 확인을 기다리고 있습니다.'**
  String get nearbyWaitingForPeer;

  /// 연결 확인 시간이 초과되었습니다. 다시 시도해주세요.
  ///
  /// In ko, this message translates to:
  /// **'연결 확인 시간이 초과되었습니다. 다시 시도해주세요.'**
  String get nearbyVerificationTimeout;

  /// 연결 요청을 거절했습니다.
  ///
  /// In ko, this message translates to:
  /// **'연결 요청을 거절했습니다.'**
  String get nearbyRejectedLocally;

  /// 전송을 취소했습니다.
  ///
  /// In ko, this message translates to:
  /// **'전송을 취소했습니다.'**
  String get nearbySendCanceled;

  /// 받기를 취소했습니다.
  ///
  /// In ko, this message translates to:
  /// **'받기를 취소했습니다.'**
  String get nearbyReceiveCanceled;

  /// {detail}의 인증 코드를 준비하고 있습니다.
  ///
  /// In ko, this message translates to:
  /// **'{detail}의 인증 코드를 준비하고 있습니다.'**
  String nearbyPreparingCode(String detail);

  /// 양쪽 기기의 인증 코드가 같은지 확인하세요.
  ///
  /// In ko, this message translates to:
  /// **'양쪽 기기의 인증 코드가 같은지 확인하세요.'**
  String get nearbyVerifyCode;

  /// 안전한 연결을 설정하고 있습니다.
  ///
  /// In ko, this message translates to:
  /// **'안전한 연결을 설정하고 있습니다.'**
  String get nearbySecuringConnection;

  /// {detail}와 연결되었습니다.
  ///
  /// In ko, this message translates to:
  /// **'{detail}와 연결되었습니다.'**
  String nearbyConnected(String detail);

  /// 파일 수신 시간이 초과되었습니다. 다시 시도해주세요.
  ///
  /// In ko, this message translates to:
  /// **'파일 수신 시간이 초과되었습니다. 다시 시도해주세요.'**
  String get nearbyReceiveTimeout;

  /// 상대 기기에서 연결을 거절했습니다.
  ///
  /// In ko, this message translates to:
  /// **'상대 기기에서 연결을 거절했습니다.'**
  String get nearbyRejectedByPeer;

  /// 연결이 종료되어 받은 파일을 확인하고 있습니다.
  ///
  /// In ko, this message translates to:
  /// **'연결이 종료되어 받은 파일을 확인하고 있습니다.'**
  String get nearbyFinalizingDisconnected;

  /// 수신 파일 확인 시간이 초과되었습니다. 다시 시도해주세요.
  ///
  /// In ko, this message translates to:
  /// **'수신 파일 확인 시간이 초과되었습니다. 다시 시도해주세요.'**
  String get nearbyFinalizationTimeout;

  /// 기기 연결이 끊겼습니다. 가까운 거리에서 다시 시도해주세요.
  ///
  /// In ko, this message translates to:
  /// **'기기 연결이 끊겼습니다. 가까운 거리에서 다시 시도해주세요.'**
  String get nearbyDisconnected;

  /// 월드컵을 보내고 있습니다.
  ///
  /// In ko, this message translates to:
  /// **'월드컵을 보내고 있습니다.'**
  String get nearbySending;

  /// 월드컵을 받고 있습니다.
  ///
  /// In ko, this message translates to:
  /// **'월드컵을 받고 있습니다.'**
  String get nearbyReceiving;

  /// 파일 전송 시간이 초과되었습니다. 다시 시도해주세요.
  ///
  /// In ko, this message translates to:
  /// **'파일 전송 시간이 초과되었습니다. 다시 시도해주세요.'**
  String get nearbySendTimeout;

  /// 월드컵 전송을 완료했습니다.
  ///
  /// In ko, this message translates to:
  /// **'월드컵 전송을 완료했습니다.'**
  String get nearbySendSuccess;

  /// 수신 파일을 확인하고 있습니다.
  ///
  /// In ko, this message translates to:
  /// **'수신 파일을 확인하고 있습니다.'**
  String get nearbyCheckingFile;

  /// 파일 전송이 취소되었습니다.
  ///
  /// In ko, this message translates to:
  /// **'파일 전송이 취소되었습니다.'**
  String get nearbyTransferCanceled;

  /// 파일 전송에 실패했습니다. 다시 시도해주세요.
  ///
  /// In ko, this message translates to:
  /// **'파일 전송에 실패했습니다. 다시 시도해주세요.'**
  String get nearbyTransferFailed;

  /// 월드컵 공유 파일을 만들고 있습니다.
  ///
  /// In ko, this message translates to:
  /// **'월드컵 공유 파일을 만들고 있습니다.'**
  String get nearbyCreatingFile;

  /// 공유 파일 준비 시간이 초과되었습니다. 다시 시도해주세요.
  ///
  /// In ko, this message translates to:
  /// **'공유 파일 준비 시간이 초과되었습니다. 다시 시도해주세요.'**
  String get nearbyPreparationTimeout;

  /// 받은 월드컵을 자동 등록하고 있습니다.
  ///
  /// In ko, this message translates to:
  /// **'받은 월드컵을 자동 등록하고 있습니다.'**
  String get nearbyImporting;

  /// "{detail}" 월드컵을 받았습니다.
  ///
  /// In ko, this message translates to:
  /// **'\"{detail}\" 월드컵을 받았습니다.'**
  String nearbyReceiveSuccess(String detail);

  /// 이 기기에서는 Nearby Connections를 사용할 수 없습니다.
  ///
  /// In ko, this message translates to:
  /// **'이 기기에서는 Nearby Connections를 사용할 수 없습니다.'**
  String get nearbyUnsupported;

  /// 주변 기기 권한이 차단되었습니다. 앱 설정에서 권한을 허용해주세요.
  ///
  /// In ko, this message translates to:
  /// **'주변 기기 권한이 차단되었습니다. 앱 설정에서 권한을 허용해주세요.'**
  String get nearbyPermissionBlocked;

  /// 주변 기기 권한이 필요합니다.
  ///
  /// In ko, this message translates to:
  /// **'주변 기기 권한이 필요합니다.'**
  String get nearbyPermissionRequired;

  /// Bluetooth와 Wi-Fi를 켠 뒤 다시 시도해주세요.
  ///
  /// In ko, this message translates to:
  /// **'Bluetooth와 Wi-Fi를 켠 뒤 다시 시도해주세요.'**
  String get nearbyRadiosDisabled;

  /// Nearby Connections를 시작할 수 없습니다.
  ///
  /// In ko, this message translates to:
  /// **'Nearby Connections를 시작할 수 없습니다.'**
  String get nearbyStartFailed;

  /// 받은 월드컵을 등록하지 못했습니다. 보내는 기기에서 다시 보내주세요.
  ///
  /// In ko, this message translates to:
  /// **'받은 월드컵을 등록하지 못했습니다. 보내는 기기에서 다시 보내주세요.'**
  String get nearbyImportFailed;

  /// 주변 기기 전송 중 오류가 발생했습니다. 다시 시도해주세요.
  ///
  /// In ko, this message translates to:
  /// **'주변 기기 전송 중 오류가 발생했습니다. 다시 시도해주세요.'**
  String get nearbyError;

  /// {title}, 최대 라운드 {round}강, {current} / {total}
  ///
  /// In ko, this message translates to:
  /// **'{title}, 최대 라운드 {round}강, {current} / {total}'**
  String listCardSemantics(String title, int round, int current, int total);

  /// 전송 상태 {message}{progress}
  ///
  /// In ko, this message translates to:
  /// **'전송 상태 {message}{progress}'**
  String nearbyStatusSemantics(String message, String progress);

  /// {percent}%
  ///
  /// In ko, this message translates to:
  /// **'{percent}%'**
  String nearbyProgressPercent(int percent);

  /// 내가 만든 월드컵 게임 체험하기
  ///
  /// In ko, this message translates to:
  /// **'내가 만든 월드컵 게임 체험하기'**
  String get resultShareButton;

  /// {title} 월드컵 공유
  ///
  /// In ko, this message translates to:
  /// **'{title} 월드컵 공유'**
  String shareFileTitle(String title);

  /// {title} 월드컵
  ///
  /// In ko, this message translates to:
  /// **'{title} 월드컵'**
  String shareFileSubject(String title);

  /// 기본 샘플 -1의 title
  ///
  /// In ko, this message translates to:
  /// **'여자 아이돌 월드컵'**
  String get sampleFemaleTitle;

  /// 기본 샘플 -1의 info
  ///
  /// In ko, this message translates to:
  /// **'최고의 여자 아이돌'**
  String get sampleFemaleInfo;

  /// 기본 샘플 후보 이름. 사용자 작성 내용에는 적용하지 않음
  ///
  /// In ko, this message translates to:
  /// **'에스파 카리나'**
  String get sampleItemAespaCarina;

  /// 기본 샘플 후보 이름. 사용자 작성 내용에는 적용하지 않음
  ///
  /// In ko, this message translates to:
  /// **'하츠투하츠 이안'**
  String get sampleItemHearts2Ian;

  /// 기본 샘플 후보 이름. 사용자 작성 내용에는 적용하지 않음
  ///
  /// In ko, this message translates to:
  /// **'엔믹스 설윤'**
  String get sampleItemNmixSul;

  /// 기본 샘플 후보 이름. 사용자 작성 내용에는 적용하지 않음
  ///
  /// In ko, this message translates to:
  /// **'아이브 장원영'**
  String get sampleItemIveJang;

  /// 기본 샘플 후보 이름. 사용자 작성 내용에는 적용하지 않음
  ///
  /// In ko, this message translates to:
  /// **'베이비몬스터 아현'**
  String get sampleItemBabymonAhyun;

  /// 기본 샘플 후보 이름. 사용자 작성 내용에는 적용하지 않음
  ///
  /// In ko, this message translates to:
  /// **'프로미스나인 송하영'**
  String get sampleItemPromiseSong;

  /// 기본 샘플 후보 이름. 사용자 작성 내용에는 적용하지 않음
  ///
  /// In ko, this message translates to:
  /// **'아일릿 원희'**
  String get sampleItemIlitWonhee;

  /// 기본 샘플 후보 이름. 사용자 작성 내용에는 적용하지 않음
  ///
  /// In ko, this message translates to:
  /// **'뉴진스 해린'**
  String get sampleItemNewjeansHaerin;

  /// 기본 샘플 후보 이름. 사용자 작성 내용에는 적용하지 않음
  ///
  /// In ko, this message translates to:
  /// **'있지 유나'**
  String get sampleItemItzyYuna;

  /// 기본 샘플 후보 이름. 사용자 작성 내용에는 적용하지 않음
  ///
  /// In ko, this message translates to:
  /// **'리센느 원이'**
  String get sampleItemResceneWon;

  /// 기본 샘플 후보 이름. 사용자 작성 내용에는 적용하지 않음
  ///
  /// In ko, this message translates to:
  /// **'미야오 안나'**
  String get sampleItemMeovvAnna;

  /// 기본 샘플 후보 이름. 사용자 작성 내용에는 적용하지 않음
  ///
  /// In ko, this message translates to:
  /// **'트리플에스 김채원'**
  String get sampleItemTriplesChaewon;

  /// 기본 샘플 후보 이름. 사용자 작성 내용에는 적용하지 않음
  ///
  /// In ko, this message translates to:
  /// **'츄'**
  String get sampleItemChu;

  /// 기본 샘플 후보 이름. 사용자 작성 내용에는 적용하지 않음
  ///
  /// In ko, this message translates to:
  /// **'강혜원'**
  String get sampleItemIzoneHyewon;

  /// 기본 샘플 후보 이름. 사용자 작성 내용에는 적용하지 않음
  ///
  /// In ko, this message translates to:
  /// **'아이들 미연'**
  String get sampleItemIdleMiyeon;

  /// 기본 샘플 후보 이름. 사용자 작성 내용에는 적용하지 않음
  ///
  /// In ko, this message translates to:
  /// **'르세라핌 김채원'**
  String get sampleItemLesserafimKimchaewon;

  /// 기본 샘플 -2의 title
  ///
  /// In ko, this message translates to:
  /// **'남자 아이돌 월드컵'**
  String get sampleMaleTitle;

  /// 기본 샘플 -2의 info
  ///
  /// In ko, this message translates to:
  /// **'최고의 남자 아이돌'**
  String get sampleMaleInfo;

  /// 기본 샘플 후보 이름. 사용자 작성 내용에는 적용하지 않음
  ///
  /// In ko, this message translates to:
  /// **'박지훈'**
  String get sampleItemParkJiHun;

  /// 기본 샘플 후보 이름. 사용자 작성 내용에는 적용하지 않음
  ///
  /// In ko, this message translates to:
  /// **'코르티스 건호'**
  String get sampleItemCortisGunho;

  /// 기본 샘플 후보 이름. 사용자 작성 내용에는 적용하지 않음
  ///
  /// In ko, this message translates to:
  /// **'NCT 127 재현'**
  String get sampleItemNct127Jaehyun;

  /// 기본 샘플 후보 이름. 사용자 작성 내용에는 적용하지 않음
  ///
  /// In ko, this message translates to:
  /// **'투어스 도훈'**
  String get sampleItemTwsDohun;

  /// 기본 샘플 후보 이름. 사용자 작성 내용에는 적용하지 않음
  ///
  /// In ko, this message translates to:
  /// **'앤더블 한유진'**
  String get sampleItemAnd2BleYujin;

  /// 기본 샘플 후보 이름. 사용자 작성 내용에는 적용하지 않음
  ///
  /// In ko, this message translates to:
  /// **'보넥도 명재현'**
  String get sampleItemBndMyung;

  /// 기본 샘플 후보 이름. 사용자 작성 내용에는 적용하지 않음
  ///
  /// In ko, this message translates to:
  /// **'방탄 뷔'**
  String get sampleItemBtsV;

  /// 기본 샘플 후보 이름. 사용자 작성 내용에는 적용하지 않음
  ///
  /// In ko, this message translates to:
  /// **'TXT 연준'**
  String get sampleItemTxtYun;

  /// 기본 샘플 후보 이름. 사용자 작성 내용에는 적용하지 않음
  ///
  /// In ko, this message translates to:
  /// **'더보이즈 주연'**
  String get sampleItemTheboyzJuyeon;

  /// 기본 샘플 후보 이름. 사용자 작성 내용에는 적용하지 않음
  ///
  /// In ko, this message translates to:
  /// **'라이즈 원빈'**
  String get sampleItemRiizeWonbin;

  /// 기본 샘플 후보 이름. 사용자 작성 내용에는 적용하지 않음
  ///
  /// In ko, this message translates to:
  /// **'NCT WISH 리쿠'**
  String get sampleItemNctwishRiku;

  /// 기본 샘플 후보 이름. 사용자 작성 내용에는 적용하지 않음
  ///
  /// In ko, this message translates to:
  /// **'비투비 육성재'**
  String get sampleItemBtobYuk;

  /// 기본 샘플 후보 이름. 사용자 작성 내용에는 적용하지 않음
  ///
  /// In ko, this message translates to:
  /// **'엔하이픈 선우'**
  String get sampleItemEnhyphenSunwoo;

  /// 기본 샘플 후보 이름. 사용자 작성 내용에는 적용하지 않음
  ///
  /// In ko, this message translates to:
  /// **'TXT 태현'**
  String get sampleItemTxtTaehyun;

  /// 기본 샘플 후보 이름. 사용자 작성 내용에는 적용하지 않음
  ///
  /// In ko, this message translates to:
  /// **'아스트로 차은우'**
  String get sampleItemAstroCha;

  /// 기본 샘플 후보 이름. 사용자 작성 내용에는 적용하지 않음
  ///
  /// In ko, this message translates to:
  /// **'갓세븐 진영'**
  String get sampleItemGot7Jinyoung;

  /// 주변 기기와 월드컵 파일을 직접 주고받기 위해 Bluetooth를 사용합니다.
  ///
  /// In ko, this message translates to:
  /// **'주변 기기와 월드컵 파일을 직접 주고받기 위해 Bluetooth를 사용합니다.'**
  String get nativeBluetoothPermission;

  /// 인터넷 없이 주변 기기와 월드컵 파일을 직접 전송하기 위해 로컬 네트워크를 사용합니다.
  ///
  /// In ko, this message translates to:
  /// **'인터넷 없이 주변 기기와 월드컵 파일을 직접 전송하기 위해 로컬 네트워크를 사용합니다.'**
  String get nativeLocalNetworkPermission;

  /// 월드컵에 사용할 사진을 찍기 위해 카메라를 사용합니다.
  ///
  /// In ko, this message translates to:
  /// **'월드컵에 사용할 사진을 찍기 위해 카메라를 사용합니다.'**
  String get nativeCameraPermission;

  /// 월드컵에 사용할 사진을 선택하기 위해 사진 보관함을 사용합니다.
  ///
  /// In ko, this message translates to:
  /// **'월드컵에 사용할 사진을 선택하기 위해 사진 보관함을 사용합니다.'**
  String get nativePhotosPermission;

  /// 공지 게시일. 언어별 날짜 형식
  ///
  /// In ko, this message translates to:
  /// **'{date}'**
  String noticesDate(DateTime date);

  /// 배너 광고
  ///
  /// In ko, this message translates to:
  /// **'배너 광고'**
  String get listAdvertisementSemantics;

  /// 월드컵 기기 {suffix}
  ///
  /// In ko, this message translates to:
  /// **'월드컵 기기 {suffix}'**
  String nearbyDeviceName(int suffix);

  /// 주변 기기 작업 중복 안내
  ///
  /// In ko, this message translates to:
  /// **'다른 주변 기기 작업이 진행 중입니다. 작업을 종료한 뒤 다시 시도해주세요.'**
  String get nearbyAlreadyBusy;

  /// 주변 기기 작업 상태 오류 안내
  ///
  /// In ko, this message translates to:
  /// **'현재 상태에서는 이 작업을 진행할 수 없습니다. 전송 화면을 다시 열어주세요.'**
  String get nearbyInvalidState;

  /// 주변 기기 연결 실패 안내
  ///
  /// In ko, this message translates to:
  /// **'기기에 연결하지 못했습니다. 두 기기를 가까이 두고 다시 시도해주세요.'**
  String get nearbyConnectionFailed;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ja', 'ko'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
