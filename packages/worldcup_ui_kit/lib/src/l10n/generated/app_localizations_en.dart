// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String onboardingProgress(int current, int total) {
    return 'Page $current of $total';
  }

  @override
  String get appTitle => 'My Custom World Cup';

  @override
  String get worldCupAddMenu => 'Add a World Cup';

  @override
  String get worldCupAddMethodTitle => 'How would you like to add a World Cup?';

  @override
  String get worldCupCreate => 'Create a new World Cup';

  @override
  String get worldCupCreateDescription =>
      'Choose photos to make your own World Cup';

  @override
  String get worldCupReceiveNearby => 'Receive from a nearby device';

  @override
  String get worldCupReceiveNearbyDescription =>
      'Receive directly with Nearby Connections, no internet needed';

  @override
  String get worldCupImportFile => 'Import from a file';

  @override
  String get worldCupImportFileDescription =>
      'Choose a .myworldcup file to import';

  @override
  String get commonYes => 'Yes';

  @override
  String get commonNo => 'No';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonConfirm => 'Confirm';

  @override
  String get commonNext => 'Next';

  @override
  String get commonPrevious => 'Previous';

  @override
  String get commonClose => 'Close';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonEdit => 'Edit';

  @override
  String get commonAdd => 'Add';

  @override
  String get commonStart => 'Start';

  @override
  String get commonShare => 'Share';

  @override
  String get commonDescription => 'Description';

  @override
  String get commonInfo => 'Information';

  @override
  String get commonRetry => 'Reload';

  @override
  String get onboardingWelcome => 'Thanks for using the app!';

  @override
  String get onboardingCreateOneTitle => 'Create a World Cup: Step 1';

  @override
  String get onboardingCreateOneBody =>
      'Tap the add button at the top\nto create your own World Cup';

  @override
  String get onboardingCreateTwoTitle => 'Create a World Cup: Step 2';

  @override
  String get onboardingCreateTwoBody =>
      'Choose photos you have taken\nand add them to your list';

  @override
  String get onboardingPlayTitle => 'Play a World Cup';

  @override
  String get onboardingPlayBody => 'Choose your favorite from two photos';

  @override
  String get onboardingWinnerTitle => 'The World Cup Winner';

  @override
  String get onboardingWinnerBody => 'Let’s find your World Cup winner!';

  @override
  String get onboardingSemantics => 'Help and introduction screen';

  @override
  String get onboardingSkip => 'Skip';

  @override
  String get onboardingStart => 'Get started';

  @override
  String get updateInstallFailed =>
      'Could not start installing the update. Please try again later.';

  @override
  String get updateReady =>
      'The new version has been downloaded. Restart to apply it.';

  @override
  String get updateRestart => 'Restart';

  @override
  String get updateRequiredSemantics => 'Update required';

  @override
  String get updateRequiredTitle => 'An update is required';

  @override
  String get updateAction => 'Update';

  @override
  String get editorEditTitle => 'Edit World Cup';

  @override
  String get editorCreateTitle => 'Create World Cup';

  @override
  String get editorEditSemantics => 'Edit World Cup screen';

  @override
  String get editorCreateSemantics => 'Create World Cup screen';

  @override
  String get editorTitleLabel => 'Title';

  @override
  String get editorTitleHint => 'Enter a title for your World Cup.';

  @override
  String get editorDescriptionHint =>
      'Enter a short description of your World Cup.';

  @override
  String get editorSingleImage => 'Add one';

  @override
  String get editorPickImage => 'Choose image';

  @override
  String get editorMultipleImages => 'Add multiple';

  @override
  String get editorPickMultiple => 'Choose multiple';

  @override
  String get editorTitleRequired => 'Please enter a title.';

  @override
  String get editorDescriptionRequired => 'Please enter a description.';

  @override
  String get editorDeleteImageConfirmation => 'Delete this image?';

  @override
  String get editorCancelEditTitle => 'Cancel editing';

  @override
  String get editorCancelCreateTitle => 'Cancel creation';

  @override
  String get editorCancelEditBody => 'Discard your changes?';

  @override
  String get editorCancelCreateBody => 'Stop creating this World Cup?';

  @override
  String get editorSaveFailed =>
      'Could not save the data. Please try again later.';

  @override
  String get editorStillLoading =>
      'World Cup details are still loading. Please try again shortly.';

  @override
  String get editorUpdateFailed =>
      'Could not update the data. Please try again later.';

  @override
  String get editorEditPhoto => 'Edit photo';

  @override
  String get editorAddPhoto => 'Add photo';

  @override
  String get editorCamera => 'Camera';

  @override
  String get editorAlbum => 'Gallery';

  @override
  String get editorPhotoRequired => 'Please add a photo';

  @override
  String get editorPhotoDescription => 'Photo description';

  @override
  String get editorPhotoDescriptionRequired =>
      'Please enter a photo description.';

  @override
  String get editorImageDescription => 'Image description';

  @override
  String get editorImageDescriptionHint => 'Enter a description for this image';

  @override
  String get listHelpMenu => 'Help and feedback menu';

  @override
  String get listHelp => 'Help';

  @override
  String get noticesTitle => 'Announcements';

  @override
  String get inquiryTitle => 'Contact us';

  @override
  String get listScreenSemantics => 'My Custom World Cup screen';

  @override
  String get listExitTitle => 'Exit app';

  @override
  String get listExitBody => 'Exit My Custom World Cup?';

  @override
  String get listReadFileFailed => 'Could not read the selected file.';

  @override
  String get listImportFailed =>
      'Could not import the World Cup. Please try again later.';

  @override
  String get listEmptyBody =>
      'Tap the + button at the top right\nto add a World Cup';

  @override
  String get listEmptySemantics => 'No items';

  @override
  String get listFirst => 'First';

  @override
  String get listMiddle => 'Middle';

  @override
  String get listLast => 'Last';

  @override
  String get listNoSearchResults => 'No results found';

  @override
  String get listLoadFailed => 'Could not load World Cups. Please try again.';

  @override
  String get listOpenAll => 'Open all World Cups';

  @override
  String get listCloseSearch => 'Close search';

  @override
  String get listSearch => 'Search World Cups';

  @override
  String get listSearchHint => 'Search by title or description';

  @override
  String get listClearSearch => 'Clear search';

  @override
  String get listPagerHint =>
      'Double-tap to open this World Cup, or swipe up or down';

  @override
  String get listTitleSemantics => 'World Cup title';

  @override
  String get listMaxRoundSemantics => 'World Cup maximum round';

  @override
  String get worldCupTitleSemantics => 'World Cup title';

  @override
  String get worldCupDescriptionSemantics => 'World Cup description';

  @override
  String get worldCupChooseRound => 'Choose a starting round';

  @override
  String get sharePreparing => 'Preparing file to share…';

  @override
  String get shareChooseMethod => 'Choose how to share';

  @override
  String get shareNearby => 'Send to a nearby device';

  @override
  String get shareNearbyDescription =>
      'Send directly with Nearby Connections, no internet needed';

  @override
  String get shareOtherApp => 'Share with another app';

  @override
  String get shareOtherAppDescription =>
      'Use Quick Share, AirDrop, or an installed app';

  @override
  String get sharePackageFailed =>
      'Could not share the World Cup. Please try again later.';

  @override
  String get listDeleteFailed =>
      'Could not delete the data. Please try again later.';

  @override
  String get playExitTitle => 'Exit game';

  @override
  String get playExitBody =>
      'Exit this game?\nYour progress will not be saved.';

  @override
  String get playFinal => 'Final';

  @override
  String get playItemSemantics => 'Contestant name';

  @override
  String get resultScreenSemantics => 'World Cup winner screen';

  @override
  String get resultCongratulations => 'Congratulations!';

  @override
  String get resultCongratulationsSemantics => 'Congratulatory message';

  @override
  String get resultCelebrationSemantics => 'Celebration';

  @override
  String get resultWinnerName => 'Winner’s name';

  @override
  String get resultReplayIcon => 'Play again';

  @override
  String get resultReplay => 'Play again';

  @override
  String get resultReplaySemantics => 'Play again button';

  @override
  String get resultShareFailed => 'Could not share. Please try again later.';

  @override
  String get commonSelectButton => 'Select button';

  @override
  String get inquiryResendTitle => 'Send your message again?';

  @override
  String get inquiryResendBody =>
      'Your previous message may already have been received. Sending it again could create a duplicate.';

  @override
  String get inquiryResend => 'Send again';

  @override
  String get inquiryLeaveTitle => 'Discard your message?';

  @override
  String get inquiryLeaveBody => 'Your draft will not be saved.';

  @override
  String get inquiryKeepWriting => 'Keep writing';

  @override
  String get inquiryLeave => 'Leave';

  @override
  String get inquirySuccess => 'Your message has been received.';

  @override
  String get inquiryHeading => 'We’d like to hear from you';

  @override
  String get inquiryIntroduction =>
      'Tell us about a problem or share a suggestion.';

  @override
  String get inquiryEmailLabel => 'Email (optional)';

  @override
  String get inquiryEmailHint =>
      'Enter your email address if you’d like a reply.';

  @override
  String get inquiryContentLabel => 'Message';

  @override
  String get inquiryContentHint => 'Please describe what happened in detail.';

  @override
  String get inquiryPickingImage => 'Choosing image…';

  @override
  String get inquiryAttachScreenshot => 'Attach screenshot (optional)';

  @override
  String get inquiryChangeScreenshot => 'Change screenshot';

  @override
  String get inquiryImageLimit => 'PNG, JPG, WEBP · Up to 10 MB · 1 image';

  @override
  String get inquirySelectedScreenshot => 'Selected screenshot';

  @override
  String get inquiryImageDisplayFailed =>
      'Could not display the image. Please choose another file.';

  @override
  String get inquiryScreenshot => 'Screenshot';

  @override
  String get inquiryRemoveAttachment => 'Remove attachment';

  @override
  String get inquiryImageNotice =>
      'Attachments are uploaded to an external image hosting service and expire after 3 days. Please make sure no personal information is visible.';

  @override
  String get inquiryDeliveryUncertain =>
      'Your message may already have been received. Sending it again could create a duplicate.';

  @override
  String get inquiryUploading => 'Uploading screenshot…';

  @override
  String get inquirySubmitting => 'Sending message…';

  @override
  String get inquirySubmit => 'Send message';

  @override
  String get noticesEmpty => 'No announcements yet.';

  @override
  String get noticesImageSemantics => 'Announcement attachment';

  @override
  String get noticesImageFailed => 'Could not load the attached image.';

  @override
  String get nearbySendIntroduction =>
      'Open “Receive a World Cup” on the receiving device first.';

  @override
  String get nearbyReceiveTitle => 'Receive a World Cup';

  @override
  String get nearbyCancelSemantics => 'Cancel nearby transfer';

  @override
  String get nearbyCancel => 'Cancel transfer';

  @override
  String get nearbyOpenSettings => 'Open app settings';

  @override
  String get nearbyStatus => 'Transfer status';

  @override
  String get nearbyFoundDevices => 'Devices found';

  @override
  String get nearbySearching => 'Searching for nearby devices.';

  @override
  String get nearbyTapToConnect => 'Tap to connect';

  @override
  String get nearbyPeer => 'Other device';

  @override
  String get nearbyVerifyIntroduction =>
      'Make sure both devices display the same verification code below.';

  @override
  String get nearbyVerifyWarning => 'Do not connect if the codes do not match.';

  @override
  String get nearbyReject => 'Reject';

  @override
  String get nearbyAccept => 'Codes match · Accept';

  @override
  String get editorConfirmSemantics => 'Confirm button';

  @override
  String get editorSingleButtonSemantics => 'Add one image button';

  @override
  String get editorMultipleButtonSemantics => 'Add multiple images button';

  @override
  String get editorTakePhoto => 'Take a photo';

  @override
  String get editorFromAlbum => 'Choose a photo from your gallery';

  @override
  String editorItemCount(int count) {
    return 'Contestants added: $count';
  }

  @override
  String worldCupSampleTitle(String title) {
    return '(Sample) $title';
  }

  @override
  String worldCupMaxRound(int round) {
    return 'Maximum round: Round of $round';
  }

  @override
  String worldCupRoundOption(int round) {
    return 'Round of $round';
  }

  @override
  String listPagerPosition(int current, int total) {
    return 'World Cup $current of $total';
  }

  @override
  String listAllCount(int count) {
    return 'All World Cups ($count)';
  }

  @override
  String listSearchCount(int count) {
    return 'Search results ($count)';
  }

  @override
  String listImported(String title) {
    return 'Imported World Cup “$title”.';
  }

  @override
  String playScreenSemantics(String title) {
    return '$title game screen';
  }

  @override
  String resultTitle(String title) {
    return '$title winner';
  }

  @override
  String resultShareDescription(String title, String winner) {
    return '$title winner: $winner';
  }

  @override
  String playMatchProgress(int current, int total) {
    return '$current / $total';
  }

  @override
  String inquiryReceipt(int id) {
    return 'Reference number: $id';
  }

  @override
  String inquiryContentCounter(int count) {
    return '$count / 5000';
  }

  @override
  String supportRetryAfter(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: '$seconds seconds',
      one: '1 second',
    );
    return 'Please try again in $_temp0.';
  }

  @override
  String noticesPage(int page) {
    return 'Page $page';
  }

  @override
  String supportErrorSemantics(String message) {
    return 'Error: $message';
  }

  @override
  String nearbyVerificationCode(String code) {
    return 'Verification code $code';
  }

  @override
  String nearbyReceiveIntroduction(String name) {
    return 'This device’s name: $name\n\nTurn on Bluetooth and Wi-Fi. You do not need the same Wi-Fi router or an internet connection.';
  }

  @override
  String get updateRequiredBody =>
      'You can no longer use this version of the app.\nPlease update to the latest version.';

  @override
  String get unexpectedError => 'Something went wrong. Please try again later.';

  @override
  String get packageTooFewItems =>
      'There are not enough contestants to share this World Cup.';

  @override
  String get packageTooManyItems =>
      'There are too many contestants to share this World Cup.';

  @override
  String packageImageTooLarge(String detail) {
    return 'The image file is too large: $detail';
  }

  @override
  String packageImageMissing(String detail) {
    return 'Could not find the image file: $detail';
  }

  @override
  String get packageResourceTooLarge => 'The image resources are too large.';

  @override
  String get packageCreateFailed =>
      'Could not create the World Cup sharing file.';

  @override
  String get packageMissing => 'Could not find the sharing file.';

  @override
  String get packageTooLarge => 'The sharing file is too large.';

  @override
  String get packageInvalid => 'This is not a valid World Cup sharing file.';

  @override
  String get packageDuplicateResource =>
      'The sharing file contains duplicate resources.';

  @override
  String get packageManifestMissing =>
      'The World Cup details are missing or damaged.';

  @override
  String get packageManifestUnreadable =>
      'Could not read the World Cup details.';

  @override
  String get packageUnsafePath => 'The file contains an unsafe resource path.';

  @override
  String get packageDuplicateImage =>
      'The file contains duplicate image resource paths.';

  @override
  String get packageImageDamaged => 'An image resource is missing or damaged.';

  @override
  String get packageImageUnreadable => 'Could not read an image resource.';

  @override
  String get packageImportFailed =>
      'Could not import the World Cup sharing file.';

  @override
  String get packageUnsupported =>
      'This World Cup sharing file is not supported.';

  @override
  String get packageManifestDamaged => 'The World Cup details are damaged.';

  @override
  String get packageItemDamaged =>
      'The World Cup contestant details are damaged.';

  @override
  String get packageIncomplete => 'The received file was not fully saved.';

  @override
  String get supportConfiguration =>
      'The service connection has not been configured.';

  @override
  String get supportAddress => 'Please check the service address.';

  @override
  String get supportNetwork =>
      'Could not connect to the server. Please check your network connection.';

  @override
  String get supportEmailInvalid => 'Please enter a valid email address.';

  @override
  String get supportContentInvalid =>
      'Your message must contain 1–5,000 characters, excluding whitespace.';

  @override
  String get supportScreenshotInvalid =>
      'Please attach the screenshot again or remove it.';

  @override
  String get supportValidation => 'Please check your entries.';

  @override
  String get supportAuthentication =>
      'Service authentication failed. Please try again later.';

  @override
  String get supportNotFound =>
      'Could not find the requested information. Please reload.';

  @override
  String get supportThrottled => 'Too many requests. Please wait a moment.';

  @override
  String get supportServer =>
      'Could not process your request. Please try again later.';

  @override
  String get supportInvalidResponse => 'Could not verify the server response.';

  @override
  String get supportNoticesResponse =>
      'Could not verify the announcements response.';

  @override
  String get supportReceiptResponse =>
      'Could not confirm whether your message was received.';

  @override
  String get supportImageConfiguration =>
      'Image uploads have not been configured.';

  @override
  String get supportImageUpload =>
      'Could not upload the screenshot. Please try again or remove the attachment.';

  @override
  String get supportImageResponse =>
      'The uploaded image address cannot be used. Please remove the attachment and send your message again.';

  @override
  String get supportNoticesFailed => 'Could not load announcements.';

  @override
  String get supportContentRequired => 'Please enter a message.';

  @override
  String get supportContentTooLong =>
      'Your message can contain up to 5,000 characters.';

  @override
  String get supportImageSize => 'Please choose an image no larger than 10 MB.';

  @override
  String get supportImageSelection =>
      'Could not open the image. Please choose another file.';

  @override
  String get supportImageEmpty => 'You cannot attach an empty file.';

  @override
  String get supportInquiryFailed => 'Could not submit your message.';

  @override
  String get nearbyPreparing => 'Preparing.';

  @override
  String get nearbyDiscovering => 'Looking for a receiving device.';

  @override
  String get nearbyDiscoveryTimeout =>
      'No nearby devices found. Open “Receive a World Cup” on the receiving device and try again.';

  @override
  String get nearbyReady => 'Ready to receive a World Cup.';

  @override
  String nearbyRequestingConnection(String detail) {
    return 'Requesting a connection to $detail.';
  }

  @override
  String get nearbyConnectionTimeout =>
      'The connection timed out. Please try again.';

  @override
  String get nearbyWaitingForPeer =>
      'Waiting for confirmation on the other device.';

  @override
  String get nearbyVerificationTimeout =>
      'Connection verification timed out. Please try again.';

  @override
  String get nearbyRejectedLocally => 'Connection request rejected.';

  @override
  String get nearbySendCanceled => 'Sending canceled.';

  @override
  String get nearbyReceiveCanceled => 'Receiving canceled.';

  @override
  String nearbyPreparingCode(String detail) {
    return 'Preparing a verification code for $detail.';
  }

  @override
  String get nearbyVerifyCode =>
      'Make sure the verification codes on both devices match.';

  @override
  String get nearbySecuringConnection => 'Establishing a secure connection.';

  @override
  String nearbyConnected(String detail) {
    return 'Connected to $detail.';
  }

  @override
  String get nearbyReceiveTimeout =>
      'File reception timed out. Please try again.';

  @override
  String get nearbyRejectedByPeer =>
      'The other device rejected the connection.';

  @override
  String get nearbyFinalizingDisconnected =>
      'The connection ended. Checking the received file.';

  @override
  String get nearbyFinalizationTimeout =>
      'Checking the received file timed out. Please try again.';

  @override
  String get nearbyDisconnected =>
      'The connection was lost. Move the devices closer and try again.';

  @override
  String get nearbySending => 'Sending the World Cup.';

  @override
  String get nearbyReceiving => 'Receiving the World Cup.';

  @override
  String get nearbySendTimeout => 'File sending timed out. Please try again.';

  @override
  String get nearbySendSuccess => 'World Cup sent successfully.';

  @override
  String get nearbyCheckingFile => 'Checking the received file.';

  @override
  String get nearbyTransferCanceled => 'File transfer canceled.';

  @override
  String get nearbyTransferFailed => 'File transfer failed. Please try again.';

  @override
  String get nearbyCreatingFile => 'Creating the World Cup sharing file.';

  @override
  String get nearbyPreparationTimeout =>
      'Preparing the sharing file timed out. Please try again.';

  @override
  String get nearbyImporting => 'Adding the received World Cup automatically.';

  @override
  String nearbyReceiveSuccess(String detail) {
    return 'Received World Cup “$detail”.';
  }

  @override
  String get nearbyUnsupported =>
      'Nearby Connections is not available on this device.';

  @override
  String get nearbyPermissionBlocked =>
      'Nearby devices permission is blocked. Please allow it in app settings.';

  @override
  String get nearbyPermissionRequired =>
      'Nearby devices permission is required.';

  @override
  String get nearbyRadiosDisabled =>
      'Turn on Bluetooth and Wi-Fi, then try again.';

  @override
  String get nearbyStartFailed => 'Could not start Nearby Connections.';

  @override
  String get nearbyImportFailed =>
      'Could not add the received World Cup. Please send it again from the other device.';

  @override
  String get nearbyError =>
      'An error occurred during nearby transfer. Please try again.';

  @override
  String listCardSemantics(String title, int round, int current, int total) {
    return '$title, maximum round: Round of $round, $current of $total';
  }

  @override
  String nearbyStatusSemantics(String message, String progress) {
    return 'Transfer status $message$progress';
  }

  @override
  String nearbyProgressPercent(int percent) {
    return '$percent%';
  }

  @override
  String get resultShareButton => 'Play My Custom World Cup';

  @override
  String shareFileTitle(String title) {
    return 'Share $title World Cup';
  }

  @override
  String shareFileSubject(String title) {
    return '$title World Cup';
  }

  @override
  String get sampleFemaleTitle => 'Female Idol World Cup';

  @override
  String get sampleFemaleInfo => 'Choose your favorite female idol';

  @override
  String get sampleItemAespaCarina => 'aespa Karina';

  @override
  String get sampleItemHearts2Ian => 'Hearts2Hearts Ian';

  @override
  String get sampleItemNmixSul => 'NMIXX Sullyoon';

  @override
  String get sampleItemIveJang => 'IVE Jang Wonyoung';

  @override
  String get sampleItemBabymonAhyun => 'BABYMONSTER Ahyeon';

  @override
  String get sampleItemPromiseSong => 'fromis_9 Song Hayoung';

  @override
  String get sampleItemIlitWonhee => 'ILLIT Wonhee';

  @override
  String get sampleItemNewjeansHaerin => 'NewJeans Haerin';

  @override
  String get sampleItemItzyYuna => 'ITZY Yuna';

  @override
  String get sampleItemResceneWon => 'RESCENE Woni';

  @override
  String get sampleItemMeovvAnna => 'MEOVV Anna';

  @override
  String get sampleItemTriplesChaewon => 'tripleS Kim Chaewon';

  @override
  String get sampleItemChu => 'Chuu';

  @override
  String get sampleItemIzoneHyewon => 'Kang Hyewon';

  @override
  String get sampleItemIdleMiyeon => 'i-dle Miyeon';

  @override
  String get sampleItemLesserafimKimchaewon => 'LE SSERAFIM Kim Chaewon';

  @override
  String get sampleMaleTitle => 'Male Idol World Cup';

  @override
  String get sampleMaleInfo => 'Choose your favorite male idol';

  @override
  String get sampleItemParkJiHun => 'Park Jihoon';

  @override
  String get sampleItemCortisGunho => 'CORTIS Keonho';

  @override
  String get sampleItemNct127Jaehyun => 'NCT 127 Jaehyun';

  @override
  String get sampleItemTwsDohun => 'TWS Dohoon';

  @override
  String get sampleItemAnd2BleYujin => 'AND2BLE Han Yujin';

  @override
  String get sampleItemBndMyung => 'BOYNEXTDOOR Myung Jaehyun';

  @override
  String get sampleItemBtsV => 'BTS V';

  @override
  String get sampleItemTxtYun => 'TXT Yeonjun';

  @override
  String get sampleItemTheboyzJuyeon => 'THE BOYZ Juyeon';

  @override
  String get sampleItemRiizeWonbin => 'RIIZE Wonbin';

  @override
  String get sampleItemNctwishRiku => 'NCT WISH Riku';

  @override
  String get sampleItemBtobYuk => 'BTOB Yook Sungjae';

  @override
  String get sampleItemEnhyphenSunwoo => 'ENHYPEN Sunoo';

  @override
  String get sampleItemTxtTaehyun => 'TXT Taehyun';

  @override
  String get sampleItemAstroCha => 'ASTRO Cha Eunwoo';

  @override
  String get sampleItemGot7Jinyoung => 'GOT7 Jinyoung';

  @override
  String get nativeBluetoothPermission =>
      'Bluetooth is used to send and receive World Cup files directly with nearby devices.';

  @override
  String get nativeLocalNetworkPermission =>
      'The local network is used to transfer World Cup files directly between nearby devices without the internet.';

  @override
  String get nativeCameraPermission =>
      'The camera is used to take photos for your World Cups.';

  @override
  String get nativePhotosPermission =>
      'The photo library is used to choose photos for your World Cups.';

  @override
  String noticesDate(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return '$dateString';
  }

  @override
  String get listAdvertisementSemantics => 'Banner ad';

  @override
  String nearbyDeviceName(int suffix) {
    return 'World Cup device $suffix';
  }

  @override
  String get nearbyAlreadyBusy =>
      'Another nearby device operation is in progress. Finish it and try again.';

  @override
  String get nearbyInvalidState =>
      'This action is not available in the current state. Reopen the transfer screen.';

  @override
  String get nearbyConnectionFailed =>
      'Could not connect to the device. Move the devices closer together and try again.';
}
