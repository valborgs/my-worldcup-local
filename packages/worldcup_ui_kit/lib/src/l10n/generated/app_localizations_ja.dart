// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String onboardingProgress(int current, int total) {
    return '全$totalページ中$currentページ目';
  }

  @override
  String get appTitle => '推しバト';

  @override
  String get worldCupAddMenu => 'ワールドカップ追加メニュー';

  @override
  String get worldCupAddMethodTitle => '追加方法を選択';

  @override
  String get worldCupCreate => '新しいワールドカップを作る';

  @override
  String get worldCupCreateDescription => '写真を選んで自分だけのワールドカップを作成';

  @override
  String get worldCupReceiveNearby => '近くのデバイスから受信';

  @override
  String get worldCupReceiveNearbyDescription =>
      'インターネット不要で Nearby Connections から直接受信';

  @override
  String get worldCupImportFile => 'ファイルからインポート';

  @override
  String get worldCupImportFileDescription => '.myworldcup ファイルを選択してインポート';

  @override
  String get commonYes => 'はい';

  @override
  String get commonNo => 'いいえ';

  @override
  String get commonCancel => 'キャンセル';

  @override
  String get commonConfirm => '確認';

  @override
  String get commonNext => '次へ';

  @override
  String get commonPrevious => '前へ';

  @override
  String get commonClose => '閉じる';

  @override
  String get commonDelete => '削除';

  @override
  String get commonEdit => '編集';

  @override
  String get commonAdd => '追加';

  @override
  String get commonStart => '開始';

  @override
  String get commonShare => '共有';

  @override
  String get commonDescription => '説明';

  @override
  String get commonInfo => 'ご案内';

  @override
  String get commonRetry => '再読み込み';

  @override
  String get onboardingWelcome => 'アプリをご利用いただきありがとうございます！';

  @override
  String get onboardingCreateOneTitle => 'ワールドカップの作り方 1';

  @override
  String get onboardingCreateOneBody => '画面上部の追加ボタンを押して\nワールドカップを作ってみましょう';

  @override
  String get onboardingCreateTwoTitle => 'ワールドカップの作り方 2';

  @override
  String get onboardingCreateTwoBody => '自分で撮った写真を選んで\nリストに追加してみましょう';

  @override
  String get onboardingPlayTitle => 'ワールドカップで遊ぶ';

  @override
  String get onboardingPlayBody => '2枚の写真から好きな方を選びましょう';

  @override
  String get onboardingWinnerTitle => 'ワールドカップの優勝者';

  @override
  String get onboardingWinnerBody => 'ワールドカップの優勝者を決めましょう！';

  @override
  String get onboardingSemantics => 'ヘルプ、アプリ紹介画面';

  @override
  String get onboardingSkip => 'スキップ';

  @override
  String get onboardingStart => 'はじめる';

  @override
  String get updateInstallFailed =>
      'アップデートのインストールを開始できませんでした。しばらくしてからもう一度お試しください。';

  @override
  String get updateReady => '新しいバージョンのダウンロードが完了しました。再起動すると適用されます。';

  @override
  String get updateRestart => '再起動';

  @override
  String get updateRequiredSemantics => 'アップデートが必要です';

  @override
  String get updateRequiredTitle => 'アップデートが必要です';

  @override
  String get updateAction => 'アップデート';

  @override
  String get editorEditTitle => 'ワールドカップを編集';

  @override
  String get editorCreateTitle => 'ワールドカップを作成';

  @override
  String get editorEditSemantics => 'ワールドカップ編集画面';

  @override
  String get editorCreateSemantics => 'ワールドカップ作成画面';

  @override
  String get editorTitleLabel => 'タイトル';

  @override
  String get editorTitleHint => '作成するワールドカップのタイトルを入力してください。';

  @override
  String get editorDescriptionHint => '作成するワールドカップの説明を簡単に入力してください。';

  @override
  String get editorSingleImage => '1枚追加';

  @override
  String get editorPickImage => '画像を選択';

  @override
  String get editorMultipleImages => '複数追加';

  @override
  String get editorPickMultiple => '複数選択';

  @override
  String get editorTitleRequired => 'タイトルを入力してください。';

  @override
  String get editorDescriptionRequired => '説明を入力してください。';

  @override
  String get editorDeleteImageConfirmation => 'この画像を削除しますか？';

  @override
  String get editorCancelEditTitle => '編集をキャンセル';

  @override
  String get editorCancelCreateTitle => '作成をキャンセル';

  @override
  String get editorCancelEditBody => '編集をキャンセルしますか？';

  @override
  String get editorCancelCreateBody => '作成をキャンセルしますか？';

  @override
  String get editorSaveFailed => 'データを保存できません。しばらくしてからもう一度お試しください。';

  @override
  String get editorStillLoading => 'ワールドカップの情報を読み込んでいます。しばらくしてからもう一度お試しください。';

  @override
  String get editorUpdateFailed => 'データを更新できません。しばらくしてからもう一度お試しください。';

  @override
  String get editorEditPhoto => '写真を編集';

  @override
  String get editorAddPhoto => '写真を追加';

  @override
  String get editorCamera => 'カメラ';

  @override
  String get editorAlbum => 'アルバム';

  @override
  String get editorPhotoRequired => '写真を追加してください';

  @override
  String get editorPhotoDescription => '写真の説明';

  @override
  String get editorPhotoDescriptionRequired => '写真の説明を入力してください。';

  @override
  String get editorImageDescription => '画像の説明';

  @override
  String get editorImageDescriptionHint => '画像の説明を入力してください';

  @override
  String get listHelpMenu => 'ヘルプ・お問い合わせメニュー';

  @override
  String get listHelp => 'ヘルプ';

  @override
  String get noticesTitle => 'お知らせ';

  @override
  String get inquiryTitle => 'お問い合わせ';

  @override
  String get listScreenSemantics => '自分で作るワールドカップ画面';

  @override
  String get listExitTitle => 'アプリを終了';

  @override
  String get listExitBody => '自分で作るワールドカップを終了しますか？';

  @override
  String get listReadFileFailed => '選択したファイルを読み込めません。';

  @override
  String get listImportFailed => 'ワールドカップをインポートできません。しばらくしてからもう一度お試しください。';

  @override
  String get listEmptyBody => '右上の＋ボタンを押して\nワールドカップを追加してください';

  @override
  String get listEmptySemantics => '項目がありません';

  @override
  String get listFirst => '先頭';

  @override
  String get listMiddle => '中央';

  @override
  String get listLast => '末尾';

  @override
  String get listNoSearchResults => '検索結果がありません';

  @override
  String get listLoadFailed => 'ワールドカップを読み込めませんでした。もう一度お試しください。';

  @override
  String get listOpenAll => 'すべてのワールドカップを表示';

  @override
  String get listCloseSearch => '検索を閉じる';

  @override
  String get listSearch => 'ワールドカップを検索';

  @override
  String get listSearchHint => 'タイトルまたは説明で検索';

  @override
  String get listClearSearch => '検索キーワードを消去';

  @override
  String get listPagerHint => 'ダブルタップで現在のワールドカップを開くか、上下にスワイプしてください';

  @override
  String get listTitleSemantics => 'ワールドカップのタイトル';

  @override
  String get listMaxRoundSemantics => 'ワールドカップの最大ラウンド';

  @override
  String get worldCupTitleSemantics => 'ワールドカップのタイトル';

  @override
  String get worldCupDescriptionSemantics => 'ワールドカップの説明';

  @override
  String get worldCupChooseRound => 'ラウンドを選択してください';

  @override
  String get sharePreparing => '共有ファイルを準備中…';

  @override
  String get shareChooseMethod => '共有方法を選択';

  @override
  String get shareNearby => '近くのデバイスに送信';

  @override
  String get shareNearbyDescription => 'インターネット不要で Nearby Connections から直接送信';

  @override
  String get shareOtherApp => '他のアプリで共有';

  @override
  String get shareOtherAppDescription =>
      'Quick Share、AirDrop、またはインストール済みのアプリを使用';

  @override
  String get sharePackageFailed => 'ワールドカップを共有できません。しばらくしてからもう一度お試しください。';

  @override
  String get listDeleteFailed => 'データを削除できません。しばらくしてからもう一度お試しください。';

  @override
  String get playExitTitle => 'ゲームを終了';

  @override
  String get playExitBody => 'ゲームを終了しますか？\n進行状況は保存されません。';

  @override
  String get playFinal => '決勝';

  @override
  String get playItemSemantics => '候補の名前';

  @override
  String get resultScreenSemantics => 'ワールドカップ優勝者画面';

  @override
  String get resultCongratulations => 'おめでとうございます！';

  @override
  String get resultCongratulationsSemantics => 'お祝いのメッセージ';

  @override
  String get resultCelebrationSemantics => 'お祝い';

  @override
  String get resultWinnerName => '優勝者の名前';

  @override
  String get resultReplayIcon => 'もう一度遊ぶ';

  @override
  String get resultReplay => 'もう一度遊ぶ';

  @override
  String get resultReplaySemantics => 'もう一度遊ぶボタン';

  @override
  String get resultShareFailed => '共有できません。しばらくしてからもう一度お試しください。';

  @override
  String get commonSelectButton => '選択ボタン';

  @override
  String get inquiryResendTitle => 'お問い合わせを再送信しますか？';

  @override
  String get inquiryResendBody =>
      '前のお問い合わせはすでに受け付けられている可能性があります。再送信すると、同じお問い合わせが重複して送信される場合があります。';

  @override
  String get inquiryResend => '再送信';

  @override
  String get inquiryLeaveTitle => '入力をやめますか？';

  @override
  String get inquiryLeaveBody => '入力中のお問い合わせは保存されません。';

  @override
  String get inquiryKeepWriting => '入力を続ける';

  @override
  String get inquiryLeave => '戻る';

  @override
  String get inquirySuccess => 'お問い合わせを受け付けました。';

  @override
  String get inquiryHeading => 'ご意見をお聞かせください';

  @override
  String get inquiryIntroduction => 'お困りのことやご提案をお寄せください。';

  @override
  String get inquiryEmailLabel => 'メールアドレス（任意）';

  @override
  String get inquiryEmailHint => '返信先のメールアドレスを入力してください。';

  @override
  String get inquiryContentLabel => 'お問い合わせ内容';

  @override
  String get inquiryContentHint => '問題が発生した状況を詳しくお知らせください。';

  @override
  String get inquiryPickingImage => '画像を選択中…';

  @override
  String get inquiryAttachScreenshot => 'スクリーンショットを添付（任意）';

  @override
  String get inquiryChangeScreenshot => 'スクリーンショットを変更';

  @override
  String get inquiryImageLimit => 'PNG、JPG、WEBP · 最大10MB · 1枚';

  @override
  String get inquirySelectedScreenshot => '選択したスクリーンショット';

  @override
  String get inquiryImageDisplayFailed => '画像を表示できません。別のファイルを選択してください。';

  @override
  String get inquiryScreenshot => 'スクリーンショット';

  @override
  String get inquiryRemoveAttachment => '添付を削除';

  @override
  String get inquiryImageNotice =>
      '添付画像は外部の画像ホスティングサービスにアップロードされ、3日後に期限切れになります。個人情報が写っていないことをご確認ください。';

  @override
  String get inquiryDeliveryUncertain =>
      'すでに受け付けられている可能性があります。再送信する場合は重複にご注意ください。';

  @override
  String get inquiryUploading => 'スクリーンショットをアップロード中…';

  @override
  String get inquirySubmitting => 'お問い合わせを送信中…';

  @override
  String get inquirySubmit => '送信';

  @override
  String get noticesEmpty => 'お知らせはありません。';

  @override
  String get noticesImageSemantics => 'お知らせの添付画像';

  @override
  String get noticesImageFailed => '添付画像を読み込めません。';

  @override
  String get nearbySendIntroduction => '受信するデバイスで、先に「ワールドカップを受信」を開いてください。';

  @override
  String get nearbyReceiveTitle => 'ワールドカップを受信';

  @override
  String get nearbyCancelSemantics => '近くのデバイスへの転送をキャンセル';

  @override
  String get nearbyCancel => '転送をキャンセル';

  @override
  String get nearbyOpenSettings => 'アプリの設定を開く';

  @override
  String get nearbyStatus => '転送状況';

  @override
  String get nearbyFoundDevices => '見つかったデバイス';

  @override
  String get nearbySearching => '近くのデバイスを検索しています。';

  @override
  String get nearbyTapToConnect => 'タップして接続';

  @override
  String get nearbyPeer => '相手のデバイス';

  @override
  String get nearbyVerifyIntroduction => '両方のデバイスに同じ認証コードが表示されていることを確認してください。';

  @override
  String get nearbyVerifyWarning => 'コードが異なる場合は接続しないでください。';

  @override
  String get nearbyReject => '拒否';

  @override
  String get nearbyAccept => 'コード一致・許可';

  @override
  String get editorConfirmSemantics => '確認ボタン';

  @override
  String get editorSingleButtonSemantics => '画像を1枚追加するボタン';

  @override
  String get editorMultipleButtonSemantics => '画像を複数追加するボタン';

  @override
  String get editorTakePhoto => '写真を撮る';

  @override
  String get editorFromAlbum => 'アルバムから写真を選択';

  @override
  String editorItemCount(int count) {
    return '登録した候補：$count件';
  }

  @override
  String worldCupSampleTitle(String title) {
    return '（サンプル）$title';
  }

  @override
  String worldCupMaxRound(int round) {
    return '最大ラウンド：ベスト$round';
  }

  @override
  String worldCupRoundOption(int round) {
    return 'ベスト$round';
  }

  @override
  String listPagerPosition(int current, int total) {
    return 'ワールドカップ $current / $total';
  }

  @override
  String listAllCount(int count) {
    return 'すべてのワールドカップ（$count件）';
  }

  @override
  String listSearchCount(int count) {
    return '検索結果（$count件）';
  }

  @override
  String listImported(String title) {
    return 'ワールドカップ「$title」をインポートしました。';
  }

  @override
  String playScreenSemantics(String title) {
    return '$titleのゲーム画面';
  }

  @override
  String resultTitle(String title) {
    return '$titleの優勝者';
  }

  @override
  String resultShareDescription(String title, String winner) {
    return '$titleの優勝者：$winner';
  }

  @override
  String playMatchProgress(int current, int total) {
    return '$current / $total';
  }

  @override
  String inquiryReceipt(int id) {
    return '受付番号：$id';
  }

  @override
  String inquiryContentCounter(int count) {
    return '$count / 5000';
  }

  @override
  String supportRetryAfter(int seconds) {
    return '$seconds秒後にもう一度お試しください。';
  }

  @override
  String noticesPage(int page) {
    return '$pageページ';
  }

  @override
  String supportErrorSemantics(String message) {
    return 'エラー：$message';
  }

  @override
  String nearbyVerificationCode(String code) {
    return '認証コード $code';
  }

  @override
  String nearbyReceiveIntroduction(String name) {
    return 'このデバイスの名前：$name\n\nBluetooth と Wi-Fi をオンにしてください。同じ Wi-Fi ルーターやインターネットへの接続は不要です。';
  }

  @override
  String get updateRequiredBody =>
      'このバージョンではアプリを引き続きご利用いただけません。\n最新バージョンにアップデートしてください。';

  @override
  String get unexpectedError => '処理できませんでした。しばらくしてからもう一度お試しください。';

  @override
  String get packageTooFewItems => '共有するワールドカップの候補が不足しています。';

  @override
  String get packageTooManyItems => '候補が多すぎるため共有できません。';

  @override
  String packageImageTooLarge(String detail) {
    return '画像ファイルが大きすぎます：$detail';
  }

  @override
  String packageImageMissing(String detail) {
    return '画像ファイルが見つかりません：$detail';
  }

  @override
  String get packageResourceTooLarge => '画像リソースのサイズが大きすぎます。';

  @override
  String get packageCreateFailed => 'ワールドカップの共有ファイルを作成できませんでした。';

  @override
  String get packageMissing => '共有ファイルが見つかりません。';

  @override
  String get packageTooLarge => '共有ファイルが大きすぎます。';

  @override
  String get packageInvalid => '有効なワールドカップの共有ファイルではありません。';

  @override
  String get packageDuplicateResource => '共有ファイルに重複したリソースが含まれています。';

  @override
  String get packageManifestMissing => 'ワールドカップの情報が見つからないか、破損しています。';

  @override
  String get packageManifestUnreadable => 'ワールドカップの情報を読み込めません。';

  @override
  String get packageUnsafePath => '安全でないリソースパスが含まれています。';

  @override
  String get packageDuplicateImage => '重複した画像リソースパスが含まれています。';

  @override
  String get packageImageDamaged => '画像リソースが見つからないか、破損しています。';

  @override
  String get packageImageUnreadable => '画像リソースを読み込めません。';

  @override
  String get packageImportFailed => 'ワールドカップの共有ファイルをインポートできませんでした。';

  @override
  String get packageUnsupported => 'このワールドカップの共有ファイルには対応していません。';

  @override
  String get packageManifestDamaged => 'ワールドカップの情報が破損しています。';

  @override
  String get packageItemDamaged => 'ワールドカップの候補情報が破損しています。';

  @override
  String get packageIncomplete => '受信したファイルが完全に保存されていません。';

  @override
  String get supportConfiguration => 'サービスの接続設定が完了していません。';

  @override
  String get supportAddress => 'サービスのアドレスを確認してください。';

  @override
  String get supportNetwork => 'サーバーに接続できませんでした。ネットワークを確認してください。';

  @override
  String get supportEmailInvalid => '有効なメールアドレスを入力してください。';

  @override
  String get supportContentInvalid => 'お問い合わせ内容は空白を除いて1～5,000文字で入力してください。';

  @override
  String get supportScreenshotInvalid => 'スクリーンショットを添付し直すか、削除してください。';

  @override
  String get supportValidation => '入力内容を確認してください。';

  @override
  String get supportAuthentication => 'サービスの認証に失敗しました。しばらくしてからもう一度お試しください。';

  @override
  String get supportNotFound => 'リクエストされた情報が見つかりません。再読み込みしてください。';

  @override
  String get supportThrottled => 'リクエストが多いため、しばらくお待ちください。';

  @override
  String get supportServer => 'リクエストを処理できませんでした。しばらくしてからもう一度お試しください。';

  @override
  String get supportInvalidResponse => 'サーバーの応答を確認できませんでした。';

  @override
  String get supportNoticesResponse => 'お知らせの応答を確認できませんでした。';

  @override
  String get supportReceiptResponse => '受付結果を確認できませんでした。';

  @override
  String get supportImageConfiguration => '画像のアップロード設定が完了していません。';

  @override
  String get supportImageUpload =>
      'スクリーンショットをアップロードできませんでした。もう一度お試しいただくか、添付を削除してください。';

  @override
  String get supportImageResponse =>
      'アップロードした画像のアドレスをお問い合わせに使用できません。添付を削除して送信してください。';

  @override
  String get supportNoticesFailed => 'お知らせを読み込めませんでした。';

  @override
  String get supportContentRequired => 'お問い合わせ内容を入力してください。';

  @override
  String get supportContentTooLong => 'お問い合わせ内容は5,000文字まで入力できます。';

  @override
  String get supportImageSize => '10MB以下の画像を選択してください。';

  @override
  String get supportImageSelection => '画像を開けませんでした。別のファイルを選択してください。';

  @override
  String get supportImageEmpty => '空のファイルは添付できません。';

  @override
  String get supportInquiryFailed => 'お問い合わせの受付を完了できませんでした。';

  @override
  String get nearbyPreparing => '準備しています。';

  @override
  String get nearbyDiscovering => '受信するデバイスを検索しています。';

  @override
  String get nearbyDiscoveryTimeout =>
      '近くのデバイスが見つかりませんでした。受信するデバイスで「ワールドカップを受信」を開いて、もう一度お試しください。';

  @override
  String get nearbyReady => 'ワールドカップを受信する準備ができました。';

  @override
  String nearbyRequestingConnection(String detail) {
    return '$detailに接続をリクエストしています。';
  }

  @override
  String get nearbyConnectionTimeout => 'デバイスの接続がタイムアウトしました。もう一度お試しください。';

  @override
  String get nearbyWaitingForPeer => '相手のデバイスでの確認を待っています。';

  @override
  String get nearbyVerificationTimeout => '接続の確認がタイムアウトしました。もう一度お試しください。';

  @override
  String get nearbyRejectedLocally => '接続リクエストを拒否しました。';

  @override
  String get nearbySendCanceled => '送信をキャンセルしました。';

  @override
  String get nearbyReceiveCanceled => '受信をキャンセルしました。';

  @override
  String nearbyPreparingCode(String detail) {
    return '$detailの認証コードを準備しています。';
  }

  @override
  String get nearbyVerifyCode => '両方のデバイスの認証コードが同じか確認してください。';

  @override
  String get nearbySecuringConnection => '安全な接続を確立しています。';

  @override
  String nearbyConnected(String detail) {
    return '$detailに接続しました。';
  }

  @override
  String get nearbyReceiveTimeout => 'ファイルの受信がタイムアウトしました。もう一度お試しください。';

  @override
  String get nearbyRejectedByPeer => '相手のデバイスが接続を拒否しました。';

  @override
  String get nearbyFinalizingDisconnected => '接続が終了したため、受信したファイルを確認しています。';

  @override
  String get nearbyFinalizationTimeout => '受信したファイルの確認がタイムアウトしました。もう一度お試しください。';

  @override
  String get nearbyDisconnected => 'デバイスとの接続が切れました。近くでもう一度お試しください。';

  @override
  String get nearbySending => 'ワールドカップを送信しています。';

  @override
  String get nearbyReceiving => 'ワールドカップを受信しています。';

  @override
  String get nearbySendTimeout => 'ファイルの送信がタイムアウトしました。もう一度お試しください。';

  @override
  String get nearbySendSuccess => 'ワールドカップの送信が完了しました。';

  @override
  String get nearbyCheckingFile => '受信したファイルを確認しています。';

  @override
  String get nearbyTransferCanceled => 'ファイルの転送がキャンセルされました。';

  @override
  String get nearbyTransferFailed => 'ファイルの転送に失敗しました。もう一度お試しください。';

  @override
  String get nearbyCreatingFile => 'ワールドカップの共有ファイルを作成しています。';

  @override
  String get nearbyPreparationTimeout => '共有ファイルの準備がタイムアウトしました。もう一度お試しください。';

  @override
  String get nearbyImporting => '受信したワールドカップを自動登録しています。';

  @override
  String nearbyReceiveSuccess(String detail) {
    return 'ワールドカップ「$detail」を受信しました。';
  }

  @override
  String get nearbyUnsupported => 'このデバイスでは Nearby Connections を利用できません。';

  @override
  String get nearbyPermissionBlocked =>
      '付近のデバイスへのアクセスがブロックされています。アプリの設定で権限を許可してください。';

  @override
  String get nearbyPermissionRequired => '付近のデバイスへのアクセス権限が必要です。';

  @override
  String get nearbyRadiosDisabled => 'Bluetooth と Wi-Fi をオンにしてから、もう一度お試しください。';

  @override
  String get nearbyStartFailed => 'Nearby Connections を開始できません。';

  @override
  String get nearbyImportFailed =>
      '受信したワールドカップを登録できませんでした。送信側のデバイスからもう一度送信してください。';

  @override
  String get nearbyError => '近くのデバイスとの転送中にエラーが発生しました。もう一度お試しください。';

  @override
  String listCardSemantics(String title, int round, int current, int total) {
    return '$title、最大ラウンドはベスト$round、$current / $total';
  }

  @override
  String nearbyStatusSemantics(String message, String progress) {
    return '転送状況 $message$progress';
  }

  @override
  String nearbyProgressPercent(int percent) {
    return '$percent%';
  }

  @override
  String get resultShareButton => '自分で作るワールドカップで遊ぶ';

  @override
  String shareFileTitle(String title) {
    return '$titleのワールドカップを共有';
  }

  @override
  String shareFileSubject(String title) {
    return '$titleのワールドカップ';
  }

  @override
  String get sampleFemaleTitle => '女性アイドルワールドカップ';

  @override
  String get sampleFemaleInfo => '最高の女性アイドルを選ぼう';

  @override
  String get sampleItemAespaCarina => 'エスパ カリナ';

  @override
  String get sampleItemHearts2Ian => 'ハーツトゥハーツ イアン';

  @override
  String get sampleItemNmixSul => 'エンミックス ソリュン';

  @override
  String get sampleItemIveJang => 'アイヴ チャン・ウォニョン';

  @override
  String get sampleItemBabymonAhyun => 'ベイビーモンスター アヒョン';

  @override
  String get sampleItemPromiseSong => 'プロミスナイン ソン・ハヨン';

  @override
  String get sampleItemIlitWonhee => 'アイリット ウォンヒ';

  @override
  String get sampleItemNewjeansHaerin => 'ニュージーンズ ヘリン';

  @override
  String get sampleItemItzyYuna => 'イッチ ユナ';

  @override
  String get sampleItemResceneWon => 'リセンヌ ウォニ';

  @override
  String get sampleItemMeovvAnna => 'ミヤオ アンナ';

  @override
  String get sampleItemTriplesChaewon => 'トリプルエス キム・チェウォン';

  @override
  String get sampleItemChu => 'チュウ';

  @override
  String get sampleItemIzoneHyewon => 'カン・ヘウォン';

  @override
  String get sampleItemIdleMiyeon => 'アイドゥル ミヨン';

  @override
  String get sampleItemLesserafimKimchaewon => 'ル・セラフィム キム・チェウォン';

  @override
  String get sampleMaleTitle => '男性アイドルワールドカップ';

  @override
  String get sampleMaleInfo => '最高の男性アイドルを選ぼう';

  @override
  String get sampleItemParkJiHun => 'パク・ジフン';

  @override
  String get sampleItemCortisGunho => 'コルティス ゴンホ';

  @override
  String get sampleItemNct127Jaehyun => 'エヌシーティー127 ジェヒョン';

  @override
  String get sampleItemTwsDohun => 'トゥアス ドフン';

  @override
  String get sampleItemAnd2BleYujin => 'アンダブル ハン・ユジン';

  @override
  String get sampleItemBndMyung => 'ボーイネクストドア ミョン・ジェヒョン';

  @override
  String get sampleItemBtsV => 'ビーティーエス ヴィ';

  @override
  String get sampleItemTxtYun => 'トゥモロー・バイ・トゥギャザー ヨンジュン';

  @override
  String get sampleItemTheboyzJuyeon => 'ザ・ボーイズ ジュヨン';

  @override
  String get sampleItemRiizeWonbin => 'ライズ ウォンビン';

  @override
  String get sampleItemNctwishRiku => 'エヌシーティーウィッシュ リク';

  @override
  String get sampleItemBtobYuk => 'ビートゥービー ユク・ソンジェ';

  @override
  String get sampleItemEnhyphenSunwoo => 'エンハイプン ソヌ';

  @override
  String get sampleItemTxtTaehyun => 'トゥモロー・バイ・トゥギャザー テヒョン';

  @override
  String get sampleItemAstroCha => 'アストロ チャ・ウヌ';

  @override
  String get sampleItemGot7Jinyoung => 'ガットセブン ジニョン';

  @override
  String get nativeBluetoothPermission =>
      '近くのデバイスとワールドカップのファイルを直接送受信するために Bluetooth を使用します。';

  @override
  String get nativeLocalNetworkPermission =>
      'インターネットを使わずに近くのデバイスとワールドカップのファイルを直接転送するために、ローカルネットワークを使用します。';

  @override
  String get nativeCameraPermission => 'ワールドカップに使用する写真を撮影するためにカメラを使用します。';

  @override
  String get nativePhotosPermission => 'ワールドカップに使用する写真を選択するために写真ライブラリを使用します。';

  @override
  String noticesDate(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return '$dateString';
  }

  @override
  String get listAdvertisementSemantics => 'バナー広告';

  @override
  String nearbyDeviceName(int suffix) {
    return 'ワールドカップ端末 $suffix';
  }

  @override
  String get nearbyAlreadyBusy => '別の近くのデバイス操作が進行中です。操作を終了してからもう一度お試しください。';

  @override
  String get nearbyInvalidState => '現在の状態ではこの操作を実行できません。転送画面を開き直してください。';

  @override
  String get nearbyConnectionFailed =>
      'デバイスに接続できませんでした。2台のデバイスを近づけて、もう一度お試しください。';
}
