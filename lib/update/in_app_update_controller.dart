import 'dart:async';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:worldcup_domain/worldcup_domain.dart';
import 'package:worldcup_in_app_update/worldcup_in_app_update.dart';

/// 인앱 업데이트 화면 상태.
///
/// 유연한(Flexible) 업데이트는 내려받는 동안 앱을 계속 쓸 수 있어야 하므로,
/// 사용자에게 무언가를 보여 주는 단계는 [readyToInstall] 하나뿐이다.
/// [updateRequired]만 예외로, 앱을 막고 업데이트를 요구한다.
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

  /// 반드시 올려야 하는 버전인데 사용자가 즉시 업데이트 창을 닫았다.
  /// 앱을 막고 다시 업데이트를 권해야 한다.
  updateRequired,

  /// 내려받기나 설치가 실패했다.
  failed,
}

/// Play In-App Update를 이끄는 뷰모델.
///
/// 평소에는 유연한 업데이트만 쓴다. Remote Config가 내려준 최소 요구
/// versionCode에 못 미치는 경우에만 즉시(강제) 업데이트로 올린다.
///
/// 위젯을 모르므로 가짜 [InAppUpdateGateway]와 [FeatureFlagPort]만으로
/// 단위 테스트할 수 있다.
class InAppUpdateController extends ChangeNotifier {
  final InAppUpdateGateway _gateway;
  final FeatureFlagPort _featureFlags;

  InAppUpdatePhase _phase = InAppUpdatePhase.idle;

  /// 0.0~1.0. 전체 크기를 아직 모르면 null이다.
  double? _downloadProgress;

  /// 사용자가 직접 누른 설치가 실패했을 때만 세운다. 화면이 한 번 보여 주고 내린다.
  bool _installFailureUnseen = false;

  /// 이번 실행에서 사용자가 Play 동의 창을 닫았다. 같은 실행에서 다시 묻지 않는다.
  /// 강제 업데이트에는 적용되지 않는다.
  bool _declinedThisSession = false;

  /// 재시작 안내를 사용자가 닫았다. 앱에 다시 돌아오면 초기화된다.
  bool _installPromptDismissed = false;

  /// Play 창이 떠 있는 동안 세워 둔다. 이때 앱이 잠깐 백그라운드로
  /// 내려가는데, 복귀 시 다시 조회하면 사용자의 선택을 놓치므로 막는다.
  bool _updateFlowInFlight = false;

  /// 강제 업데이트가 필요하다고 판단한 상태.
  ///
  /// 이때 진행 상황은 Play의 전체 화면이 보여 준다. 같은 시간에 흘러 들어오는
  /// 설치 상태를 유연한 흐름처럼 처리하면, 막아 둔 화면 뒤에서 "재시작하시겠어요?"
  /// 스낵바가 올라오는 이상한 상태가 된다.
  bool _forcedUpdate = false;

  /// Remote Config가 내려준 최소 요구 versionCode. 한 번만 읽어 캐시한다.
  /// 원격 설정은 fetch 간격이 있어 앱이 떠 있는 동안 값이 바뀌지 않는다.
  int? _minRequiredVersionCode;

  bool _started = false;
  bool _disposed = false;

  /// 진행 중인 조회를 무효로 만드는 세대 번호.
  /// 응답이 늦게 도착한 조회가 최신 상태를 덮어쓰지 못하게 한다.
  int _generation = 0;

  /// 설치 이벤트가 상태를 바꿀 때마다 오른다.
  ///
  /// 세대 번호는 조회끼리만 비교하므로, 조회를 기다리는 사이에 도착한 설치
  /// 이벤트는 막지 못한다. 그 사이 `downloaded`가 들어와 재시작 안내를 띄웠는데
  /// 늦게 온 조회 스냅샷이 `downloading`을 말하면 안내가 사라져 버린다.
  /// 이벤트가 언제나 더 최신이므로, 응답을 적용하기 전에 이 값이 그대로인지 본다.
  int _installRevision = 0;

  StreamSubscription<InAppUpdateInstallState>? _subscription;

  InAppUpdateController({required this._gateway, required this._featureFlags});

  InAppUpdatePhase get phase => _phase;

  double? get downloadProgress => _downloadProgress;

  /// 재시작 안내를 지금 보여 줘야 하는지.
  bool get shouldPromptInstall =>
      _phase == InAppUpdatePhase.readyToInstall && !_installPromptDismissed;

  /// 앱을 막고 업데이트를 요구해야 하는지.
  bool get isUpdateRequired => _phase == InAppUpdatePhase.updateRequired;

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
  /// 유연한 업데이트의 동의 창은 다시 띄우지 않는다. 여기서 노리는 것은
  /// 지난번에 받아 두고 아직 설치하지 않은 업데이트를 찾아내는 일이다.
  /// 강제 업데이트는 예외로, 매번 다시 띄운다.
  Future<void> resume() async {
    if (!_started || _disposed) return;
    if (_updateFlowInFlight) return;
    if (_phase == InAppUpdatePhase.installing) return;
    _installPromptDismissed = false;
    await _check(allowConsentPrompt: false);
  }

  /// 막힌 화면에서 사용자가 다시 업데이트를 누른 경우.
  Future<void> retryRequiredUpdate() async {
    if (_disposed || _updateFlowInFlight) return;
    if (_phase != InAppUpdatePhase.updateRequired) return;
    await _startRequiredUpdate(++_generation);
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
    final installRevision = _installRevision;

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
      if (_disposed || generation != _generation) return;
      _releaseBlockOnCheckFailure();
      return;
    }
    if (_disposed || generation != _generation) return;

    // 강제 업데이트를 가장 먼저 본다. 이 조건에 걸리면 유연한 흐름은
    // 의미가 없다. allowConsentPrompt와 무관하게 매번 다시 띄우는 것도
    // 의도한 동작이다. 앱 복귀 때마다 요구해야 "강제"가 성립한다.
    if (await _isForcedUpdateNeeded(info)) {
      if (_disposed || generation != _generation) return;
      await _startRequiredUpdate(generation);
      return;
    }
    if (_disposed || generation != _generation) return;
    _forcedUpdate = false;

    // 조회를 기다리는 사이 설치 이벤트가 상태를 바꿨다면 그쪽이 더 최신이다.
    // 낡은 스냅샷으로 "받기 완료"를 "받는 중"으로 되돌리지 않는다.
    if (_installRevision != installRevision) return;

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

  /// 앱을 막아 둔 상태에서 조회가 실패하면 차단을 푼다.
  ///
  /// 조회가 실패했다는 것은 지금 올릴 수 있는 업데이트가 있는지조차 확인하지
  /// 못했다는 뜻이다. 확인할 수 없는 동안 계속 막아 두면 망이 불안정한
  /// 사용자는 앱에서 영영 빠져나갈 수 없다. 풀어 주고 다음 복귀에서 다시 본다.
  void _releaseBlockOnCheckFailure() {
    if (_phase != InAppUpdatePhase.updateRequired) return;
    _forcedUpdate = false;
    _apply(InAppUpdatePhase.idle);
  }

  /// 지금 깔린 버전이 최소 요구 버전에 못 미치고, 즉시 업데이트도 가능한지.
  ///
  /// 판단 근거가 하나라도 없으면 false다. Play가 업데이트를 못 준다고
  /// 하는데 앱만 막아 두면 사용자가 빠져나갈 길이 없기 때문이다.
  Future<bool> _isForcedUpdateNeeded(InAppUpdateInfo info) async {
    if (!info.canStartImmediateUpdate) return false;
    final minRequired = await _readMinRequiredVersionCode();
    if (minRequired <= 0) return false;
    return info.isBelowRequiredVersion(minRequired);
  }

  Future<int> _readMinRequiredVersionCode() async {
    final cached = _minRequiredVersionCode;
    if (cached != null) return cached;
    // FeatureFlagPort는 실패해도 예외 대신 기본값(0 = 강제하지 않음)을 준다.
    final value = await _featureFlags.getInt(
      FeatureFlags.minRequiredVersionCode,
      defaultValue: FeatureFlags.minRequiredVersionCodeDefault,
    );
    return _minRequiredVersionCode = value;
  }

  Future<void> _startRequiredUpdate(int generation) async {
    _forcedUpdate = true;
    // 리비전은 창을 띄우기 직전에 잡는다. 흐름보다 **먼저** 일어난 이벤트는
    // 이 흐름의 결과를 무효로 만들 근거가 아니다. 조회를 기다리는 사이 들어온
    // downloading 이벤트 때문에 사용자의 취소를 버리면 강제가 성립하지 않는다.
    final installRevision = _installRevision;
    final result = await _runUpdateFlow(
      generation,
      _gateway.startImmediateUpdate,
    );
    if (result == null) return;
    if (_installRevision != installRevision) return;

    switch (result) {
      case InAppUpdateFlowResult.accepted:
        // Play가 전체 화면을 덮고 설치까지 맡는다. 보통 곧 앱이 재시작된다.
        _apply(InAppUpdatePhase.installing);
      case InAppUpdateFlowResult.canceled:
        // 사용자가 직접 빠져나갔다. 이때만 앱을 막고 다시 권한다.
        _apply(InAppUpdatePhase.updateRequired);
      case InAppUpdateFlowResult.failed:
        // 창을 띄우지 못했다. 사용자의 거절이 아니라 기술적 실패다.
        // (네이티브가 흐름 직전에 다시 조회하는데, 그 조회가 실패하면 여기로 온다)
        // 업데이트를 실제로 줄 수 있는지 확인하지 못한 상태이므로 막지 않는다.
        // 막아 놓고 올릴 방법도 없으면 사용자가 빠져나갈 길이 없다.
        _forcedUpdate = false;
        _apply(InAppUpdatePhase.available);
      case InAppUpdateFlowResult.unavailable:
        // Play가 더 이상 올릴 게 없다고 한다. 막아 둘 이유가 없다.
        _forcedUpdate = false;
        _apply(InAppUpdatePhase.idle);
    }
  }

  Future<void> _requestConsent(int generation) async {
    final installRevision = _installRevision;
    final result = await _runUpdateFlow(
      generation,
      _gateway.startFlexibleUpdate,
    );
    if (result == null) return;

    // 거절 기록은 상태와 별개로 남긴다. 이 실행에서 다시 묻지 않기 위해서다.
    if (result == InAppUpdateFlowResult.canceled) _declinedThisSession = true;
    if (_installRevision != installRevision) return;

    switch (result) {
      case InAppUpdateFlowResult.accepted:
        _apply(InAppUpdatePhase.downloading);
      case InAppUpdateFlowResult.canceled:
      case InAppUpdateFlowResult.failed:
        _apply(InAppUpdatePhase.available);
      case InAppUpdateFlowResult.unavailable:
        _apply(InAppUpdatePhase.idle);
    }
  }

  /// Play 창을 띄우고 결과를 기다린다.
  ///
  /// 결과를 적용하면 안 되는 상황(dispose / 세대 교체)에서만 null이다.
  /// 채널 오류는 [InAppUpdateFlowResult.failed]로 옮긴다. "창을 띄우지 못했다"와
  /// 같은 뜻이고, 사용자의 거절과 구분되어야 하기 때문이다.
  Future<InAppUpdateFlowResult?> _runUpdateFlow(
    int generation,
    Future<InAppUpdateFlowResult> Function() start,
  ) async {
    _updateFlowInFlight = true;
    try {
      final result = await start();
      if (_disposed || generation != _generation) return null;
      return result;
    } catch (error, stackTrace) {
      log(
        '업데이트 창을 띄우지 못했습니다.',
        error: error,
        stackTrace: stackTrace,
        name: 'in_app_update',
      );
      if (_disposed || generation != _generation) return null;
      return InAppUpdateFlowResult.failed;
    } finally {
      _updateFlowInFlight = false;
    }
  }

  void _onInstallState(InAppUpdateInstallState state) {
    if (_disposed) return;
    // 강제 업데이트 중에는 Play의 전체 화면이 진행 상황을 맡는다.
    // 설치가 끝났다는 소식만 받아 막아 둔 화면을 푼다.
    if (_forcedUpdate && state.status != InAppUpdateInstallStatus.installed) {
      return;
    }
    switch (state.status) {
      case InAppUpdateInstallStatus.pending:
        _applyFromInstallState(InAppUpdatePhase.downloading);
      case InAppUpdateInstallStatus.downloading:
        _downloadProgress = state.progress;
        _applyFromInstallState(InAppUpdatePhase.downloading);
      case InAppUpdateInstallStatus.downloaded:
        _downloadProgress = 1;
        // 새로 받아 놓은 업데이트다. 이전에 닫은 안내와는 별개로 다시 알린다.
        _installPromptDismissed = false;
        _applyFromInstallState(InAppUpdatePhase.readyToInstall);
      case InAppUpdateInstallStatus.installing:
        _applyFromInstallState(InAppUpdatePhase.installing);
      case InAppUpdateInstallStatus.installed:
        _forcedUpdate = false;
        _applyFromInstallState(InAppUpdatePhase.idle);
      case InAppUpdateInstallStatus.canceled:
        _downloadProgress = null;
        _applyFromInstallState(InAppUpdatePhase.idle);
      case InAppUpdateInstallStatus.failed:
        _downloadProgress = null;
        _applyFromInstallState(InAppUpdatePhase.failed);
      case InAppUpdateInstallStatus.requiresUiIntent:
      case InAppUpdateInstallStatus.unknown:
        // 상태를 바꾸지 않으므로 리비전도 올리지 않는다.
        break;
    }
  }

  /// 설치 이벤트로 상태를 바꾼다.
  ///
  /// 리비전을 올려, 이 시점 이전에 시작된 조회나 Play 창의 응답이 뒤늦게
  /// 도착해 여기서 정한 상태를 되돌리지 못하게 한다.
  void _applyFromInstallState(InAppUpdatePhase phase) {
    _installRevision++;
    _apply(phase);
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
