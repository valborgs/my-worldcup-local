// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String onboardingProgress(int current, int total) {
    return '전체 $total페이지 중 $current페이지';
  }

  @override
  String get appTitle => '내가 만든 월드컵';

  @override
  String get worldCupAddMenu => '월드컵 추가 메뉴';

  @override
  String get worldCupAddMethodTitle => '월드컵 추가 방법 선택';

  @override
  String get worldCupCreate => '새 월드컵 만들기';

  @override
  String get worldCupCreateDescription => '사진을 골라 나만의 월드컵 만들기';

  @override
  String get worldCupReceiveNearby => '주변 기기에서 받기';

  @override
  String get worldCupReceiveNearbyDescription =>
      '인터넷 없이 Nearby Connections로 직접 받기';

  @override
  String get worldCupImportFile => '파일에서 가져오기';

  @override
  String get worldCupImportFileDescription => '.myworldcup 파일을 직접 선택하여 가져오기';

  @override
  String get commonYes => '네';

  @override
  String get commonNo => '아니오';

  @override
  String get commonCancel => '취소';

  @override
  String get commonConfirm => '확인';

  @override
  String get commonNext => '다음';

  @override
  String get commonPrevious => '이전';

  @override
  String get commonClose => '닫기';

  @override
  String get commonDelete => '삭제';

  @override
  String get commonEdit => '수정';

  @override
  String get commonAdd => '추가';

  @override
  String get commonStart => '시작';

  @override
  String get commonShare => '공유하기';

  @override
  String get commonDescription => '설명';

  @override
  String get commonInfo => '안내';

  @override
  String get commonRetry => '다시 불러오기';

  @override
  String get onboardingWelcome => '앱을 실행해주셔서 감사합니다!';

  @override
  String get onboardingCreateOneTitle => '월드컵 만들기 1';

  @override
  String get onboardingCreateOneBody => '상단의 추가 버튼을 눌러 \n월드컵을 만들어보세요';

  @override
  String get onboardingCreateTwoTitle => '월드컵 만들기 2';

  @override
  String get onboardingCreateTwoBody => '내가 직접 찍은 사진을 골라 \n리스트에 추가해보세요';

  @override
  String get onboardingPlayTitle => '월드컵 게임 진행';

  @override
  String get onboardingPlayBody => '2개의 사진 중 마음에 든 사진을 선택해보세요';

  @override
  String get onboardingWinnerTitle => '월드컵 게임 우승자';

  @override
  String get onboardingWinnerBody => '월드컵 우승자를 가려봅시다!';

  @override
  String get onboardingSemantics => '도움말, 소개 화면';

  @override
  String get onboardingSkip => '스킵하기';

  @override
  String get onboardingStart => '시작하기';

  @override
  String get updateInstallFailed => '업데이트 설치를 시작하지 못했습니다. 잠시 후 다시 시도해 주세요.';

  @override
  String get updateReady => '새 버전을 모두 받았습니다. 재시작하면 적용됩니다.';

  @override
  String get updateRestart => '재시작';

  @override
  String get updateRequiredSemantics => '업데이트 필요';

  @override
  String get updateRequiredTitle => '업데이트가 필요합니다';

  @override
  String get updateAction => '업데이트';

  @override
  String get editorEditTitle => '월드컵 수정';

  @override
  String get editorCreateTitle => '월드컵 등록';

  @override
  String get editorEditSemantics => '월드컵 수정 화면';

  @override
  String get editorCreateSemantics => '월드컵 등록 화면';

  @override
  String get editorTitleLabel => '제목';

  @override
  String get editorTitleHint => '만드실 월드컵의 제목을 입력해주세요.';

  @override
  String get editorDescriptionHint => '만드실 월드컵의 설명을 간단히 입력해주세요.';

  @override
  String get editorSingleImage => '단일 추가';

  @override
  String get editorPickImage => '이미지 선택';

  @override
  String get editorMultipleImages => '복수 추가';

  @override
  String get editorPickMultiple => '여러개 선택';

  @override
  String get editorTitleRequired => '제목을 입력해주세요.';

  @override
  String get editorDescriptionRequired => '설명을 입력해주세요.';

  @override
  String get editorDeleteImageConfirmation => '해당 이미지를 삭제하시겠습니까?';

  @override
  String get editorCancelEditTitle => '수정 취소';

  @override
  String get editorCancelCreateTitle => '등록 취소';

  @override
  String get editorCancelEditBody => '수정을 취소하시겠습니까?';

  @override
  String get editorCancelCreateBody => '등록을 취소하시겠습니까?';

  @override
  String get editorSaveFailed => '데이터를 저장할 수 없습니다. 잠시후에 다시 시도해주세요.';

  @override
  String get editorStillLoading => '월드컵 정보를 아직 불러오는 중입니다. 잠시 후 다시 시도해주세요.';

  @override
  String get editorUpdateFailed => '데이터를 업데이트할 수 없습니다. 잠시후에 다시 시도해주세요.';

  @override
  String get editorEditPhoto => '사진 수정';

  @override
  String get editorAddPhoto => '사진 추가';

  @override
  String get editorCamera => '카메라';

  @override
  String get editorAlbum => '앨범';

  @override
  String get editorPhotoRequired => '사진을 추가해주세요';

  @override
  String get editorPhotoDescription => '사진 설명';

  @override
  String get editorPhotoDescriptionRequired => '사진 설명을 입력해주세요.';

  @override
  String get editorImageDescription => '이미지 설명';

  @override
  String get editorImageDescriptionHint => '이미지에 대한 설명을 입력하세요';

  @override
  String get listHelpMenu => '도움말 및 소통 메뉴';

  @override
  String get listHelp => '도움말';

  @override
  String get noticesTitle => '공지사항';

  @override
  String get inquiryTitle => '문의함';

  @override
  String get listScreenSemantics => '내가 만든 월드컵 화면';

  @override
  String get listExitTitle => '앱 종료';

  @override
  String get listExitBody => '내가 만든 월드컵을 종료하시겠습니까?';

  @override
  String get listReadFileFailed => '선택한 파일을 읽을 수 없습니다.';

  @override
  String get listImportFailed => '월드컵을 가져올 수 없습니다. 잠시 후 다시 시도해주세요.';

  @override
  String get listEmptyBody => '오른쪽 상단의 + 버튼을 눌러 \n월드컵 게임을 추가해주세요';

  @override
  String get listEmptySemantics => '항목이 비어있음';

  @override
  String get listFirst => '맨 앞';

  @override
  String get listMiddle => '중간';

  @override
  String get listLast => '맨 뒤';

  @override
  String get listNoSearchResults => '검색 결과가 없습니다';

  @override
  String get listLoadFailed => '월드컵을 불러오지 못했습니다. 다시 시도해주세요.';

  @override
  String get listOpenAll => '전체 월드컵 목록 열기';

  @override
  String get listCloseSearch => '검색 닫기';

  @override
  String get listSearch => '월드컵 검색';

  @override
  String get listSearchHint => '월드컵 제목 또는 설명 검색';

  @override
  String get listClearSearch => '검색어 지우기';

  @override
  String get listPagerHint => '두 번 탭하여 현재 월드컵을 열거나 위아래로 쓸어 넘기세요';

  @override
  String get listTitleSemantics => '월드컵 게임 타이틀';

  @override
  String get listMaxRoundSemantics => '월드컵 최대 라운드';

  @override
  String get worldCupTitleSemantics => '월드컵 제목';

  @override
  String get worldCupDescriptionSemantics => '월드컵 설명';

  @override
  String get worldCupChooseRound => '- 라운드 수를 선택해주세요- ';

  @override
  String get sharePreparing => '공유 파일 준비 중...';

  @override
  String get shareChooseMethod => '공유 방법 선택';

  @override
  String get shareNearby => '주변 기기로 보내기';

  @override
  String get shareNearbyDescription => '인터넷 없이 Nearby Connections로 직접 전송';

  @override
  String get shareOtherApp => '다른 앱으로 공유하기';

  @override
  String get shareOtherAppDescription => 'Quick Share, AirDrop 또는 설치된 앱 사용';

  @override
  String get shareConfirmBody =>
      '이 월드컵의 모든 사진과 설명이 다른 사람에게 전달됩니다.\n민감한 내용의 사진이 있는지 한 번 더 확인해주세요.';

  @override
  String get sharePackageFailed => '월드컵을 공유할 수 없습니다. 잠시 후 다시 시도해주세요.';

  @override
  String get listDeleteFailed => '데이터를 삭제할 수 없습니다. 잠시후에 다시 시도해주세요.';

  @override
  String get playExitTitle => '게임 종료';

  @override
  String get playExitBody => '게임을 종료하시겠습니까?\n진행 상황은 저장되지 않습니다.';

  @override
  String get playFinal => '결승';

  @override
  String get playItemSemantics => '항목 이름';

  @override
  String get resultScreenSemantics => '월드컵 우승자 화면';

  @override
  String get resultCongratulations => '축하합니다!';

  @override
  String get resultCongratulationsSemantics => '축하 문구';

  @override
  String get resultCelebrationSemantics => '축하';

  @override
  String get resultWinnerName => '우승자 이름';

  @override
  String get resultReplayIcon => '다시하기';

  @override
  String get resultReplay => '다시 하기';

  @override
  String get resultReplaySemantics => '다시 하기 버튼';

  @override
  String get resultShareFailed => '공유할 수 없습니다. 잠시 후 다시 시도해주세요.';

  @override
  String get editorImageProcessing => '사진의 위치 정보 등을 지우는 중…';

  @override
  String get editorImageProcessFailed => '사진을 처리하지 못했습니다. 다른 사진을 선택해 주세요.';

  @override
  String editorImageProcessingProgress(int done, int total) {
    return '사진 처리 중 $done/$total';
  }

  @override
  String editorImagesProcessFailed(int count) {
    return '사진 $count장을 처리하지 못해 제외했습니다.';
  }

  @override
  String get resultShareConfirmBody =>
      '해당 사진을 다른 사람과 공유하시겠습니까?\n민감한 내용이 없는지 한 번 더 확인해주세요.';

  @override
  String get commonSelectButton => '선택 버튼';

  @override
  String get inquiryResendTitle => '문의를 다시 전송할까요?';

  @override
  String get inquiryResendBody =>
      '이전 문의가 이미 접수되었을 수 있습니다. 다시 전송하면 같은 문의가 중복 접수될 수 있습니다.';

  @override
  String get inquiryResend => '다시 전송';

  @override
  String get inquiryLeaveTitle => '작성을 그만둘까요?';

  @override
  String get inquiryLeaveBody => '작성 중인 문의는 저장되지 않습니다.';

  @override
  String get inquiryKeepWriting => '계속 작성';

  @override
  String get inquiryLeave => '나가기';

  @override
  String get inquirySuccess => '문의가 접수되었습니다.';

  @override
  String get inquiryHeading => '의견을 들려주세요';

  @override
  String get inquiryIntroduction => '불편한 점이나 제안하고 싶은 내용을 남겨 주세요.';

  @override
  String get inquiryEmailLabel => '이메일 (선택)';

  @override
  String get inquiryEmailHint => '답변받을 이메일을 남겨 주세요.';

  @override
  String get inquiryContentLabel => '문의 내용';

  @override
  String get inquiryContentHint => '문제가 발생한 상황을 자세히 알려 주세요.';

  @override
  String get inquiryPickingImage => '이미지 선택 중…';

  @override
  String get inquiryAttachScreenshot => '스크린샷 첨부 (선택)';

  @override
  String get inquiryChangeScreenshot => '스크린샷 변경';

  @override
  String get inquiryImageLimit => 'PNG, JPG, WEBP · 최대 10MB · 1장';

  @override
  String get inquirySelectedScreenshot => '선택한 스크린샷';

  @override
  String get inquiryImageDisplayFailed => '이미지를 표시할 수 없습니다. 다른 파일을 선택해 주세요.';

  @override
  String get inquiryScreenshot => '스크린샷';

  @override
  String get inquiryRemoveAttachment => '첨부 제거';

  @override
  String get inquiryImageNotice =>
      '첨부 이미지는 외부 이미지 호스팅에 업로드되며 3일 후 만료됩니다. 개인정보가 보이지 않도록 확인해 주세요.';

  @override
  String get inquiryDeliveryUncertain =>
      '이미 접수되었을 수 있습니다. 재전송 시 중복 접수에 유의해 주세요.';

  @override
  String get inquiryUploading => '스크린샷 업로드 중…';

  @override
  String get inquirySubmitting => '문의 접수 중…';

  @override
  String get inquirySubmit => '문의 등록';

  @override
  String get noticesEmpty => '등록된 공지사항이 없습니다.';

  @override
  String get noticesImageSemantics => '공지 첨부 이미지';

  @override
  String get noticesImageFailed => '첨부 이미지를 불러올 수 없습니다.';

  @override
  String get nearbySendIntroduction => '받는 기기에서 먼저 ‘월드컵 받기’를 열어주세요.';

  @override
  String get nearbyReceiveTitle => '월드컵 받기';

  @override
  String get nearbyCancelSemantics => '주변 기기 전송 취소';

  @override
  String get nearbyCancel => '전송 취소';

  @override
  String get nearbyOpenSettings => '앱 설정 열기';

  @override
  String get nearbyStatus => '전송 상태';

  @override
  String get nearbyFoundDevices => '발견된 기기';

  @override
  String get nearbySearching => '주변 기기를 검색하고 있습니다.';

  @override
  String get nearbyTapToConnect => '탭하여 연결';

  @override
  String get nearbyPeer => '상대 기기';

  @override
  String get nearbyVerifyIntroduction => '양쪽 기기에 아래 인증 코드가 동일하게 표시되는지 확인하세요.';

  @override
  String get nearbyVerifyWarning => '코드가 다르면 연결하지 마세요.';

  @override
  String get nearbyReject => '거절';

  @override
  String get nearbyAccept => '코드 일치 · 수락';

  @override
  String get editorConfirmSemantics => '확인 버튼';

  @override
  String get editorSingleButtonSemantics => '이미지 한 장 추가 버튼';

  @override
  String get editorMultipleButtonSemantics => '여러 이미지 추가 버튼';

  @override
  String get editorTakePhoto => '사진 찍기';

  @override
  String get editorFromAlbum => '앨범에서 사진 선택';

  @override
  String editorItemCount(int count) {
    return '등록된 항목 개수 : $count개';
  }

  @override
  String worldCupSampleTitle(String title) {
    return '(샘플) $title';
  }

  @override
  String worldCupMaxRound(int round) {
    return '최대 라운드 : $round강';
  }

  @override
  String worldCupRoundOption(int round) {
    return '$round 강';
  }

  @override
  String listPagerPosition(int current, int total) {
    return '월드컵 $current / $total';
  }

  @override
  String listAllCount(int count) {
    return '전체 목록 ($count)';
  }

  @override
  String listSearchCount(int count) {
    return '검색 결과 ($count)';
  }

  @override
  String listImported(String title) {
    return '\"$title\" 월드컵을 가져왔습니다.';
  }

  @override
  String playScreenSemantics(String title) {
    return '$title 게임 화면';
  }

  @override
  String resultTitle(String title) {
    return '$title 우승자';
  }

  @override
  String resultShareDescription(String title, String winner) {
    return '$title 우승자 : $winner';
  }

  @override
  String playMatchProgress(int current, int total) {
    return '$current / $total';
  }

  @override
  String inquiryReceipt(int id) {
    return '접수 번호: $id';
  }

  @override
  String inquiryContentCounter(int count) {
    return '$count / 5000';
  }

  @override
  String supportRetryAfter(int seconds) {
    return '$seconds초 후 다시 시도해 주세요.';
  }

  @override
  String noticesPage(int page) {
    return '$page 페이지';
  }

  @override
  String supportErrorSemantics(String message) {
    return '오류: $message';
  }

  @override
  String nearbyVerificationCode(String code) {
    return '인증 코드 $code';
  }

  @override
  String nearbyReceiveIntroduction(String name) {
    return '이 기기의 이름: $name\n\nBluetooth와 Wi-Fi를 켜주세요. 같은 Wi-Fi 공유기나 인터넷 연결은 필요하지 않습니다.';
  }

  @override
  String get updateRequiredBody =>
      '이 버전에서는 앱을 계속 사용할 수 없습니다.\n최신 버전으로 업데이트해 주세요.';

  @override
  String get unexpectedError => '처리하지 못했습니다. 잠시 후 다시 시도해 주세요.';

  @override
  String get packageTooFewItems => '공유할 월드컵 항목이 부족합니다.';

  @override
  String get packageTooManyItems => '항목이 너무 많아 공유할 수 없습니다.';

  @override
  String packageImageTooLarge(String detail) {
    return '이미지 파일이 너무 큽니다: $detail';
  }

  @override
  String packageImageMissing(String detail) {
    return '이미지 파일을 찾을 수 없습니다: $detail';
  }

  @override
  String get packageResourceTooLarge => '이미지 리소스의 크기가 너무 큽니다.';

  @override
  String get packageCreateFailed => '월드컵 공유 파일을 만들지 못했습니다.';

  @override
  String get packageMissing => '공유 파일을 찾을 수 없습니다.';

  @override
  String get packageTooLarge => '공유 파일이 너무 큽니다.';

  @override
  String get packageInvalid => '올바른 월드컵 공유 파일이 아닙니다.';

  @override
  String get packageDuplicateResource => '중복된 리소스가 있는 공유 파일입니다.';

  @override
  String get packageManifestMissing => '월드컵 정보가 없거나 손상되었습니다.';

  @override
  String get packageManifestUnreadable => '월드컵 정보를 읽을 수 없습니다.';

  @override
  String get packageUnsafePath => '안전하지 않은 리소스 경로가 포함되었습니다.';

  @override
  String get packageDuplicateImage => '중복된 이미지 리소스 경로가 포함되었습니다.';

  @override
  String get packageImageDamaged => '이미지 리소스가 없거나 손상되었습니다.';

  @override
  String get packageImageUnreadable => '이미지 리소스를 읽을 수 없습니다.';

  @override
  String get packageImportFailed => '월드컵 공유 파일을 가져오지 못했습니다.';

  @override
  String get packageUnsupported => '지원하지 않는 월드컵 공유 파일입니다.';

  @override
  String get packageManifestDamaged => '월드컵 정보가 손상되었습니다.';

  @override
  String get packageItemDamaged => '월드컵 항목 정보가 손상되었습니다.';

  @override
  String get packageIncomplete => '수신 파일이 완전히 저장되지 않았습니다.';

  @override
  String get supportConfiguration => '서비스 연결 설정이 준비되지 않았습니다.';

  @override
  String get supportAddress => '서비스 주소를 확인해 주세요.';

  @override
  String get supportNetwork => '서버에 연결하지 못했습니다. 네트워크를 확인해 주세요.';

  @override
  String get supportEmailInvalid => '올바른 이메일 주소를 입력해 주세요.';

  @override
  String get supportContentInvalid => '문의 내용은 공백을 제외하고 1~5,000자로 입력해 주세요.';

  @override
  String get supportScreenshotInvalid => '스크린샷을 다시 첨부하거나 제거해 주세요.';

  @override
  String get supportValidation => '입력 내용을 확인해 주세요.';

  @override
  String get supportAuthentication => '서비스 인증에 실패했습니다. 잠시 후 다시 시도해 주세요.';

  @override
  String get supportNotFound => '요청한 정보를 찾을 수 없습니다. 다시 불러와 주세요.';

  @override
  String get supportThrottled => '요청이 많아 잠시 기다려야 합니다.';

  @override
  String get supportServer => '요청을 처리하지 못했습니다. 잠시 후 다시 시도해 주세요.';

  @override
  String get supportInvalidResponse => '서버 응답을 확인하지 못했습니다.';

  @override
  String get supportNoticesResponse => '공지사항 응답을 확인하지 못했습니다.';

  @override
  String get supportReceiptResponse => '접수 결과를 확인하지 못했습니다.';

  @override
  String get supportImageConfiguration => '이미지 업로드 설정이 준비되지 않았습니다.';

  @override
  String get supportImageUpload => '스크린샷을 업로드하지 못했습니다. 다시 시도하거나 첨부를 제거해 주세요.';

  @override
  String get supportImageResponse =>
      '업로드된 이미지 주소를 문의에 사용할 수 없습니다. 첨부를 제거하고 문의해 주세요.';

  @override
  String get supportNoticesFailed => '공지사항을 불러오지 못했습니다.';

  @override
  String get supportContentRequired => '문의 내용을 입력해 주세요.';

  @override
  String get supportContentTooLong => '문의 내용은 5,000자까지 입력할 수 있습니다.';

  @override
  String get supportImageSize => '10MB 이하의 이미지를 선택해 주세요.';

  @override
  String get supportImageSelection => '이미지를 열지 못했습니다. 다른 파일을 선택해 주세요.';

  @override
  String get supportImageEmpty => '비어 있는 파일은 첨부할 수 없습니다.';

  @override
  String get supportInquiryFailed => '문의 접수를 완료하지 못했습니다.';

  @override
  String get nearbyPreparing => '준비 중입니다.';

  @override
  String get nearbyDiscovering => '받는 기기를 찾고 있습니다.';

  @override
  String get nearbyDiscoveryTimeout =>
      '주변 기기를 찾지 못했습니다. 받는 기기에서 월드컵 받기를 열고 다시 시도해주세요.';

  @override
  String get nearbyReady => '월드컵을 받을 준비가 되었습니다.';

  @override
  String nearbyRequestingConnection(String detail) {
    return '$detail에 연결을 요청하고 있습니다.';
  }

  @override
  String get nearbyConnectionTimeout => '기기 연결 시간이 초과되었습니다. 다시 시도해주세요.';

  @override
  String get nearbyWaitingForPeer => '상대 기기의 확인을 기다리고 있습니다.';

  @override
  String get nearbyVerificationTimeout => '연결 확인 시간이 초과되었습니다. 다시 시도해주세요.';

  @override
  String get nearbyRejectedLocally => '연결 요청을 거절했습니다.';

  @override
  String get nearbySendCanceled => '전송을 취소했습니다.';

  @override
  String get nearbyReceiveCanceled => '받기를 취소했습니다.';

  @override
  String nearbyPreparingCode(String detail) {
    return '$detail의 인증 코드를 준비하고 있습니다.';
  }

  @override
  String get nearbyVerifyCode => '양쪽 기기의 인증 코드가 같은지 확인하세요.';

  @override
  String get nearbySecuringConnection => '안전한 연결을 설정하고 있습니다.';

  @override
  String nearbyConnected(String detail) {
    return '$detail와 연결되었습니다.';
  }

  @override
  String get nearbyReceiveTimeout => '파일 수신 시간이 초과되었습니다. 다시 시도해주세요.';

  @override
  String get nearbyRejectedByPeer => '상대 기기에서 연결을 거절했습니다.';

  @override
  String get nearbyFinalizingDisconnected => '연결이 종료되어 받은 파일을 확인하고 있습니다.';

  @override
  String get nearbyFinalizationTimeout => '수신 파일 확인 시간이 초과되었습니다. 다시 시도해주세요.';

  @override
  String get nearbyDisconnected => '기기 연결이 끊겼습니다. 가까운 거리에서 다시 시도해주세요.';

  @override
  String get nearbySending => '월드컵을 보내고 있습니다.';

  @override
  String get nearbyReceiving => '월드컵을 받고 있습니다.';

  @override
  String get nearbySendTimeout => '파일 전송 시간이 초과되었습니다. 다시 시도해주세요.';

  @override
  String get nearbySendSuccess => '월드컵 전송을 완료했습니다.';

  @override
  String get nearbyCheckingFile => '수신 파일을 확인하고 있습니다.';

  @override
  String get nearbyTransferCanceled => '파일 전송이 취소되었습니다.';

  @override
  String get nearbyTransferFailed => '파일 전송에 실패했습니다. 다시 시도해주세요.';

  @override
  String get nearbyCreatingFile => '월드컵 공유 파일을 만들고 있습니다.';

  @override
  String get nearbyPreparationTimeout => '공유 파일 준비 시간이 초과되었습니다. 다시 시도해주세요.';

  @override
  String get nearbyImporting => '받은 월드컵을 자동 등록하고 있습니다.';

  @override
  String nearbyReceiveSuccess(String detail) {
    return '\"$detail\" 월드컵을 받았습니다.';
  }

  @override
  String get nearbyUnsupported => '이 기기에서는 Nearby Connections를 사용할 수 없습니다.';

  @override
  String get nearbyPermissionBlocked => '주변 기기 권한이 차단되었습니다. 앱 설정에서 권한을 허용해주세요.';

  @override
  String get nearbyPermissionRequired => '주변 기기 권한이 필요합니다.';

  @override
  String get nearbyRadiosDisabled => 'Bluetooth와 Wi-Fi를 켠 뒤 다시 시도해주세요.';

  @override
  String get nearbyStartFailed => 'Nearby Connections를 시작할 수 없습니다.';

  @override
  String get nearbyImportFailed => '받은 월드컵을 등록하지 못했습니다. 보내는 기기에서 다시 보내주세요.';

  @override
  String get nearbyError => '주변 기기 전송 중 오류가 발생했습니다. 다시 시도해주세요.';

  @override
  String listCardSemantics(String title, int round, int current, int total) {
    return '$title, 최대 라운드 $round강, $current / $total';
  }

  @override
  String nearbyStatusSemantics(String message, String progress) {
    return '전송 상태 $message$progress';
  }

  @override
  String nearbyProgressPercent(int percent) {
    return '$percent%';
  }

  @override
  String get resultShareButton => '내가 만든 월드컵 게임 체험하기';

  @override
  String shareFileTitle(String title) {
    return '$title 월드컵 공유';
  }

  @override
  String shareFileSubject(String title) {
    return '$title 월드컵';
  }

  @override
  String get sampleFemaleTitle => '여자 아이돌 월드컵';

  @override
  String get sampleFemaleInfo => '최고의 여자 아이돌';

  @override
  String get sampleItemAespaCarina => '에스파 카리나';

  @override
  String get sampleItemHearts2Ian => '하츠투하츠 이안';

  @override
  String get sampleItemNmixSul => '엔믹스 설윤';

  @override
  String get sampleItemIveJang => '아이브 장원영';

  @override
  String get sampleItemBabymonAhyun => '베이비몬스터 아현';

  @override
  String get sampleItemPromiseSong => '프로미스나인 송하영';

  @override
  String get sampleItemIlitWonhee => '아일릿 원희';

  @override
  String get sampleItemNewjeansHaerin => '뉴진스 해린';

  @override
  String get sampleItemItzyYuna => '있지 유나';

  @override
  String get sampleItemResceneWon => '리센느 원이';

  @override
  String get sampleItemMeovvAnna => '미야오 안나';

  @override
  String get sampleItemTriplesChaewon => '트리플에스 김채원';

  @override
  String get sampleItemChu => '츄';

  @override
  String get sampleItemIzoneHyewon => '강혜원';

  @override
  String get sampleItemIdleMiyeon => '아이들 미연';

  @override
  String get sampleItemLesserafimKimchaewon => '르세라핌 김채원';

  @override
  String get sampleMaleTitle => '남자 아이돌 월드컵';

  @override
  String get sampleMaleInfo => '최고의 남자 아이돌';

  @override
  String get sampleItemParkJiHun => '박지훈';

  @override
  String get sampleItemCortisGunho => '코르티스 건호';

  @override
  String get sampleItemNct127Jaehyun => 'NCT 127 재현';

  @override
  String get sampleItemTwsDohun => '투어스 도훈';

  @override
  String get sampleItemAnd2BleYujin => '앤더블 한유진';

  @override
  String get sampleItemBndMyung => '보넥도 명재현';

  @override
  String get sampleItemBtsV => '방탄 뷔';

  @override
  String get sampleItemTxtYun => 'TXT 연준';

  @override
  String get sampleItemTheboyzJuyeon => '더보이즈 주연';

  @override
  String get sampleItemRiizeWonbin => '라이즈 원빈';

  @override
  String get sampleItemNctwishRiku => 'NCT WISH 리쿠';

  @override
  String get sampleItemBtobYuk => '비투비 육성재';

  @override
  String get sampleItemEnhyphenSunwoo => '엔하이픈 선우';

  @override
  String get sampleItemTxtTaehyun => 'TXT 태현';

  @override
  String get sampleItemAstroCha => '아스트로 차은우';

  @override
  String get sampleItemGot7Jinyoung => '갓세븐 진영';

  @override
  String get nativeBluetoothPermission =>
      '주변 기기와 월드컵 파일을 직접 주고받기 위해 Bluetooth를 사용합니다.';

  @override
  String get nativeLocalNetworkPermission =>
      '인터넷 없이 주변 기기와 월드컵 파일을 직접 전송하기 위해 로컬 네트워크를 사용합니다.';

  @override
  String get nativeCameraPermission => '월드컵에 사용할 사진을 찍기 위해 카메라를 사용합니다.';

  @override
  String get nativePhotosPermission => '월드컵에 사용할 사진을 선택하기 위해 사진 보관함을 사용합니다.';

  @override
  String noticesDate(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return '$dateString';
  }

  @override
  String get listAdvertisementSemantics => '배너 광고';

  @override
  String nearbyDeviceName(int suffix) {
    return '월드컵 기기 $suffix';
  }

  @override
  String get nearbyAlreadyBusy => '다른 주변 기기 작업이 진행 중입니다. 작업을 종료한 뒤 다시 시도해주세요.';

  @override
  String get nearbyInvalidState =>
      '현재 상태에서는 이 작업을 진행할 수 없습니다. 전송 화면을 다시 열어주세요.';

  @override
  String get nearbyConnectionFailed =>
      '기기에 연결하지 못했습니다. 두 기기를 가까이 두고 다시 시도해주세요.';
}
