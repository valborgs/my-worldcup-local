import 'dart:async';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:worldcup_in_app_update/worldcup_in_app_update.dart';

/// 인앱 업데이트 화면 상태.
///
/// 유연한(Flexible) 업데이트는 내려받는 동안 앱을 계속 쓸 수 있어야 하므로,
/// 사용자에게 무언가를 보여 주는 단계는 [readyToInstall] 하나뿐이다.
enum InAppUpdatePhase {
  /// 받을 업데이트가 없거나, 이미 설치가 끝났다.
  idle,

  /// 새 버전이 있지만 이번 실행에서는 동의 창을 띄우지 않는다.
  /// (사용자가 이미 닫았거나, 앱 복귀 시점이라 다시 묻지 않는 경우)
  available,

  /// Play가 백그라운드에서 내려받는 중. 사용자를 방해하지 않는다.
  downloading,

  /// 내려받기가 끝났다. 재시작만 하면 적용된다.
  readyToInstall,

  /// 설치를 시작했다. 곧 Play가 앱을 재시작한다.
  installing,

  /// 내려받기나 설치가 실패했다.
  failed,
}

/// Play In-App Update(유연한 업데이트)를 이끄는 뷰모델.
///
/// 위젯을 모르므로 가짜 [InAppUpdateGateway]만으로 단위 테스트할 수 있다.
class InAppUpdateController extends ChangeNotifier {
  final InAppUpdateGateway _gateway;

  InAppUpdatePhase _phase = InAppUpdatePhase.idle;

  /// 0.0~1.0. 전체 크기를 아직 모르면 null이다.
  double? _downloadProgress;

  /// 사용자가 직접 누른 설치가 실패했을 때만 세운다. 화면이 한 번 보여 주고 내린다.
  bool _installFailureUnseen = false;

  /// 이번 실행에서 사용자가 Play 동의 창을 닫았다. 같은 실행에서 다시 묻지 않는다.
  bool _declinedThisSession = false;

  /// 재시작 안내를 사용자가 닫았다. 앱에 다시 돌아오면 초기화된다.
  bool _installPromptDismissed = false;

  /// Play 동의 창이 떠 있는 동안 세워 둔다. 이때 앱이 잠깐 백그라운드로
  /// 내려가는데, 복귀 시 다시 조회하면 동의 결과를 놓치므로 막는다.
  bool _consentInFlight = false;

  bool _started = false;
  bool _disposed = false;

  /// 진행 중인 조회를 무효로 만드는 세대 번호.
  /// 응답이 늦게 도착한 조회가 최신 상태를 덮어쓰지 못하게 한다.
  int _generation = 0;

  StreamSubscription<InAppUpdateInstallState>? _subscription;

  InAppUpdateController({required this._gateway});

  InAppUpdatePhase get phase => _phase;

  double? get downloadProgress => _downloadProgress;

  /// 재시작 안내를 지금 보여 줘야 하는지.
  bool get shouldPromptInstall =>
      _phase == InAppUpdatePhase.readyToInstall && !_installPromptDismissed;

  /// 설치 실패를 아직 알리지 않았는지. 화면이 보여 준 뒤 [acknowledgeInstallFailure]를 부른다.
  bool get hasUnseenInstallFailure => _installFailureUnseen;

  /// 첫 조회. 새 버전이 있으면 Play 동의 창까지 띄운다.
  Future<void> start() async {
    if (_started || _disposed) return;
    _started = true;
    _subscription = _gateway.installStates.listen(
      _onInstallState,
      onError: (Object error, StackTrace stackTrace) => log(
        '인앱 업데이트 상태를 받지 못했습니다.',
        error: error,
        stackTrace: stackTrace,
        name: 'in_app_update',
      ),
    );
    await _check(allowConsentPrompt: true);
  }

  /// 앱으로 돌아왔을 때 다시 확인한다.
  ///
  /// 동의 창은 다시 띄우지 않는다. 여기서 노리는 것은 지난번에 받아 두고
  /// 아직 설치하지 않은 업데이트를 찾아내는 일이다.
  Future<void> resume() async {
    if (!_started || _disposed) return;
    if (_consentInFlight) return;
    if (_phase == InAppUpdatePhase.installing) return;
    _installPromptDismissed = false;
    await _check(allowConsentPrompt: false);
  }

  /// 재시작 안내를 사용자가 닫았다.
  void dismissInstallPrompt() {
    if (_installPromptDismissed) return;
    _installPromptDismissed = true;
    _notify();
  }

  void acknowledgeInstallFailure() {
    if (!_installFailureUnseen) return;
    _installFailureUnseen = false;
    _notify();
  }

  /// 받아 둔 업데이트를 설치한다. 성공하면 Play가 앱을 재시작한다.
  Future<void> installNow() async {
    if (_disposed || _phase != InAppUpdatePhase.readyToInstall) return;
    _installPromptDismissed = true;
    _apply(InAppUpdatePhase.installing);
    try {
      await _gateway.completeUpdate();
    } catch (error, stackTrace) {
      log(
        '업데이트 설치를 시작하지 못했습니다.',
        error: error,
        stackTrace: stackTrace,
        name: 'in_app_update',
      );
      if (_disposed) return;
      _installFailureUnseen = true;
      _apply(InAppUpdatePhase.readyToInstall);
    }
  }

  Future<void> _check({required bool allowConsentPrompt}) async {
    final generation = ++_generation;

    final InAppUpdateInfo info;
    try {
      info = await _gateway.checkForUpdate();
    } catch (error, stackTrace) {
      // Play 스토어로 설치한 앱이 아니면 여기서 실패한다(디버그 빌드 등).
      // 업데이트를 못 알릴 뿐 앱은 멀쩡하므로 조용히 넘어간다.
      log(
        '인앱 업데이트 정보를 가져오지 못했습니다.',
        error: error,
        stackTrace: stackTrace,
        name: 'in_app_update',
      );
      return;
    }
    if (_disposed || generation != _generation) return;

    if (info.isDownloaded) {
      _downloadProgress = 1;
      _apply(InAppUpdatePhase.readyToInstall);
      return;
    }

    if (info.availability == InAppUpdateAvailability.inProgress ||
        info.installStatus == InAppUpdateInstallStatus.downloading ||
        info.installStatus == InAppUpdateInstallStatus.pending) {
      _apply(InAppUpdatePhase.downloading);
      return;
    }

    if (!info.canStartFlexibleUpdate) {
      _apply(InAppUpdatePhase.idle);
      return;
    }

    if (!allowConsentPrompt || _declinedThisSession) {
      _apply(InAppUpdatePhase.available);
      return;
    }

    await _requestConsent(generation);
  }

  Future<void> _requestConsent(int generation) async {
    _consentInFlight = true;
    final InAppUpdateFlowResult result;
    try {
      result = await _gateway.startFlexibleUpdate();
    } catch (error, stackTrace) {
      log(
        '업데이트 동의 창을 띄우지 못했습니다.',
        error: error,
        stackTrace: stackTrace,
        name: 'in_app_update',
      );
      _consentInFlight = false;
      if (_disposed || generation != _generation) return;
      _apply(InAppUpdatePhase.available);
      return;
    }
    _consentInFlight = false;
    if (_disposed || generation != _generation) return;

    switch (result) {
      case InAppUpdateFlowResult.accepted:
        _apply(InAppUpdatePhase.downloading);
      case InAppUpdateFlowResult.canceled:
        _declinedThisSession = true;
        _apply(InAppUpdatePhase.available);
      case InAppUpdateFlowResult.failed:
        _apply(InAppUpdatePhase.available);
      case InAppUpdateFlowResult.unavailable:
        _apply(InAppUpdatePhase.idle);
    }
  }

  void _onInstallState(InAppUpdateInstallState state) {
    if (_disposed) return;
    switch (state.status) {
      case InAppUpdateInstallStatus.pending:
        _apply(InAppUpdatePhase.downloading);
      case InAppUpdateInstallStatus.downloading:
        _downloadProgress = state.progress;
        _apply(InAppUpdatePhase.downloading);
      case InAppUpdateInstallStatus.downloaded:
        _downloadProgress = 1;
        // 새로 받아 놓은 업데이트다. 이전에 닫은 안내와는 별개로 다시 알린다.
        _installPromptDismissed = false;
        _apply(InAppUpdatePhase.readyToInstall);
      case InAppUpdateInstallStatus.installing:
        _apply(InAppUpdatePhase.installing);
      case InAppUpdateInstallStatus.installed:
        _apply(InAppUpdatePhase.idle);
      case InAppUpdateInstallStatus.canceled:
        _downloadProgress = null;
        _apply(InAppUpdatePhase.idle);
      case InAppUpdateInstallStatus.failed:
        _downloadProgress = null;
        _apply(InAppUpdatePhase.failed);
      case InAppUpdateInstallStatus.requiresUiIntent:
      case InAppUpdateInstallStatus.unknown:
        break;
    }
  }

  void _apply(InAppUpdatePhase phase) {
    _phase = phase;
    _notify();
  }

  /// dispose 뒤에 도착한 응답이 notifyListeners를 부르지 않게 감싼다.
  void _notify() {
    if (_disposed) return;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    unawaited(_subscription?.cancel());
    _subscription = null;
    super.dispose();
  }
}
