import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_worldcup_local/update/in_app_update_controller.dart';
import 'package:worldcup_domain/worldcup_domain.dart';
import 'package:worldcup_in_app_update/worldcup_in_app_update.dart';

const _installedVersionCode = 30;

InAppUpdateInfo _info({
  InAppUpdateAvailability availability = InAppUpdateAvailability.available,
  InAppUpdateInstallStatus installStatus = InAppUpdateInstallStatus.unknown,
  bool flexibleAllowed = true,
  bool immediateAllowed = true,
  int? installedVersionCode = _installedVersionCode,
}) {
  return InAppUpdateInfo(
    availability: availability,
    installStatus: installStatus,
    flexibleAllowed: flexibleAllowed,
    immediateAllowed: immediateAllowed,
    availableVersionCode: 31,
    installedVersionCode: installedVersionCode,
    clientVersionStalenessDays: null,
    updatePriority: 0,
  );
}

InAppUpdateInstallState _state(
  InAppUpdateInstallStatus status, {
  int bytesDownloaded = 0,
  int totalBytesToDownload = 0,
}) {
  return InAppUpdateInstallState(
    status: status,
    bytesDownloaded: bytesDownloaded,
    totalBytesToDownload: totalBytesToDownload,
    errorCode: 0,
  );
}

/// 이벤트 시점을 테스트가 직접 정할 수 있는 가짜 게이트웨이.
class _FakeGateway implements InAppUpdateGateway {
  final StreamController<InAppUpdateInstallState> states =
      StreamController<InAppUpdateInstallState>.broadcast();
  final List<String> calls = <String>[];

  InAppUpdateInfo info = _info();

  /// 값을 넣으면 조회가 이 future를 그대로 돌려준다. 늦게 오는 응답을 흉내낸다.
  Completer<InAppUpdateInfo>? pendingCheck;

  /// 값을 넣으면 Play 창이 열린 채로 멈춘다.
  Completer<InAppUpdateFlowResult>? pendingFlow;

  InAppUpdateFlowResult flowResult = InAppUpdateFlowResult.accepted;
  InAppUpdateFlowResult immediateResult = InAppUpdateFlowResult.accepted;
  Object? checkError;
  Object? completeError;

  /// 네이티브가 흐름 직전에 다시 조회하다 실패하는 경우를 흉내낸다.
  Object? startError;

  @override
  Stream<InAppUpdateInstallState> get installStates => states.stream;

  @override
  Future<InAppUpdateInfo> checkForUpdate() {
    calls.add('check');
    if (checkError != null) return Future<InAppUpdateInfo>.error(checkError!);
    final pending = pendingCheck;
    if (pending != null) return pending.future;
    return Future<InAppUpdateInfo>.value(info);
  }

  @override
  Future<InAppUpdateFlowResult> startFlexibleUpdate() {
    calls.add('flexible');
    final pending = pendingFlow;
    if (pending != null) return pending.future;
    return Future<InAppUpdateFlowResult>.value(flowResult);
  }

  @override
  Future<InAppUpdateFlowResult> startImmediateUpdate() {
    calls.add('immediate');
    if (startError != null) {
      return Future<InAppUpdateFlowResult>.error(startError!);
    }
    final pending = pendingFlow;
    if (pending != null) return pending.future;
    return Future<InAppUpdateFlowResult>.value(immediateResult);
  }

  @override
  Future<void> completeUpdate() {
    calls.add('complete');
    if (completeError != null) return Future<void>.error(completeError!);
    return Future<void>.value();
  }
}

/// Remote Config 자리를 대신한다. 실제 포트처럼 예외를 던지지 않는다.
class _FakeFeatureFlags implements FeatureFlagPort {
  /// 0은 "아무도 강제하지 않는다". 각 테스트가 필요할 때 올려 쓴다.
  int minRequiredVersionCode = 0;
  int reads = 0;

  @override
  Future<bool> getBool(String key, {required bool defaultValue}) async =>
      defaultValue;

  @override
  Future<int> getInt(String key, {required int defaultValue}) async {
    if (key != FeatureFlags.minRequiredVersionCode) return defaultValue;
    reads++;
    return minRequiredVersionCode;
  }
}

Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  late _FakeGateway gateway;
  late _FakeFeatureFlags featureFlags;
  late InAppUpdateController controller;

  setUp(() {
    gateway = _FakeGateway();
    featureFlags = _FakeFeatureFlags();
    controller = InAppUpdateController(
      gateway: gateway,
      featureFlags: featureFlags,
    );
  });

  tearDown(() {
    controller.dispose();
    gateway.states.close();
  });

  group('유연한 업데이트', () {
    test('새 버전이 있으면 동의 창을 띄우고, 수락하면 조용히 내려받는다', () async {
      await controller.start();

      expect(gateway.calls, <String>['check', 'flexible']);
      expect(controller.phase, InAppUpdatePhase.downloading);
      expect(controller.shouldPromptInstall, isFalse);
      expect(controller.isUpdateRequired, isFalse);
    });

    test('업데이트가 없으면 아무것도 하지 않는다', () async {
      gateway.info = _info(availability: InAppUpdateAvailability.notAvailable);

      await controller.start();

      expect(gateway.calls, <String>['check']);
      expect(controller.phase, InAppUpdatePhase.idle);
    });

    test('유연한 업데이트가 허용되지 않으면 동의 창을 띄우지 않는다', () async {
      gateway.info = _info(flexibleAllowed: false);

      await controller.start();

      expect(gateway.calls, <String>['check']);
      expect(controller.phase, InAppUpdatePhase.idle);
    });

    test('조회가 실패해도 앱은 멀쩡하다', () async {
      gateway.checkError = Exception('Play 스토어로 설치한 앱이 아닙니다');

      await controller.start();

      expect(controller.phase, InAppUpdatePhase.idle);
    });

    test('사용자가 동의 창을 닫으면 이번 실행에서는 다시 묻지 않는다', () async {
      gateway.flowResult = InAppUpdateFlowResult.canceled;

      await controller.start();
      expect(controller.phase, InAppUpdatePhase.available);

      await controller.resume();

      expect(gateway.calls, <String>['check', 'flexible', 'check']);
      expect(controller.phase, InAppUpdatePhase.available);
    });

    test('이미 받아 둔 업데이트가 있으면 곧바로 재시작을 권한다', () async {
      gateway.info = _info(installStatus: InAppUpdateInstallStatus.downloaded);

      await controller.start();

      expect(gateway.calls, <String>['check']);
      expect(controller.phase, InAppUpdatePhase.readyToInstall);
      expect(controller.shouldPromptInstall, isTrue);
    });

    test('내려받는 동안에는 진행률만 갱신한다', () async {
      await controller.start();

      gateway.states.add(
        _state(
          InAppUpdateInstallStatus.downloading,
          bytesDownloaded: 30,
          totalBytesToDownload: 120,
        ),
      );
      await _settle();

      expect(controller.phase, InAppUpdatePhase.downloading);
      expect(controller.downloadProgress, 0.25);
      expect(controller.shouldPromptInstall, isFalse);
    });

    test('내려받기가 끝나면 재시작을 권한다', () async {
      await controller.start();

      gateway.states.add(_state(InAppUpdateInstallStatus.downloaded));
      await _settle();

      expect(controller.phase, InAppUpdatePhase.readyToInstall);
      expect(controller.shouldPromptInstall, isTrue);
    });

    test('안내를 닫으면 사라지지만, 앱에 돌아오면 다시 권한다', () async {
      gateway.info = _info(installStatus: InAppUpdateInstallStatus.downloaded);
      await controller.start();

      controller.dismissInstallPrompt();
      expect(controller.shouldPromptInstall, isFalse);
      expect(controller.phase, InAppUpdatePhase.readyToInstall);

      await controller.resume();

      expect(controller.shouldPromptInstall, isTrue);
    });

    test('재시작을 누르면 설치를 시작한다', () async {
      gateway.info = _info(installStatus: InAppUpdateInstallStatus.downloaded);
      await controller.start();

      await controller.installNow();

      expect(gateway.calls.last, 'complete');
      expect(controller.phase, InAppUpdatePhase.installing);
      expect(controller.shouldPromptInstall, isFalse);
    });

    test('설치가 실패하면 한 번만 알리고 다시 받아 둔 상태로 돌아간다', () async {
      gateway.info = _info(installStatus: InAppUpdateInstallStatus.downloaded);
      gateway.completeError = Exception('Play 서비스 오류');
      await controller.start();

      await controller.installNow();

      expect(controller.phase, InAppUpdatePhase.readyToInstall);
      expect(controller.hasUnseenInstallFailure, isTrue);

      controller.acknowledgeInstallFailure();
      expect(controller.hasUnseenInstallFailure, isFalse);
      // 실패 직후 같은 안내를 다시 띄워 아무 일도 없었던 것처럼 보이게 하지 않는다.
      expect(controller.shouldPromptInstall, isFalse);
    });

    test('Play 창이 떠 있는 동안 앱에 돌아와도 사용자의 선택을 놓치지 않는다', () async {
      // Play 창이 뜨면 앱이 잠깐 백그라운드로 내려갔다가 복귀한다.
      // 이때 조회를 새로 시작하면 세대 번호가 올라가 결과가 버려진다.
      gateway.pendingFlow = Completer<InAppUpdateFlowResult>();

      unawaited(controller.start());
      await _settle();
      expect(gateway.calls, <String>['check', 'flexible']);

      await controller.resume();
      expect(gateway.calls, <String>['check', 'flexible']);

      gateway.pendingFlow!.complete(InAppUpdateFlowResult.accepted);
      await _settle();

      expect(controller.phase, InAppUpdatePhase.downloading);
    });

    test('늦게 온 조회 응답이 내려받기 완료를 되돌리지 않는다', () async {
      await controller.start();
      expect(controller.phase, InAppUpdatePhase.downloading);

      // 복귀 조회를 띄워 둔 상태에서 내려받기가 끝난다.
      gateway.pendingCheck = Completer<InAppUpdateInfo>();
      unawaited(controller.resume());
      await _settle();

      gateway.states.add(_state(InAppUpdateInstallStatus.downloaded));
      await _settle();
      expect(controller.shouldPromptInstall, isTrue);

      // 그제서야 도착한 조회 스냅샷은 아직 '받는 중'을 말한다.
      gateway.pendingCheck!.complete(
        _info(installStatus: InAppUpdateInstallStatus.downloading),
      );
      await _settle();

      expect(controller.phase, InAppUpdatePhase.readyToInstall);
      expect(controller.shouldPromptInstall, isTrue);
    });

    test('늦게 온 동의 결과가 내려받기 완료를 되돌리지 않는다', () async {
      gateway.pendingFlow = Completer<InAppUpdateFlowResult>();
      unawaited(controller.start());
      await _settle();

      gateway.states.add(_state(InAppUpdateInstallStatus.downloaded));
      await _settle();
      expect(controller.shouldPromptInstall, isTrue);

      gateway.pendingFlow!.complete(InAppUpdateFlowResult.accepted);
      await _settle();

      expect(controller.phase, InAppUpdatePhase.readyToInstall);
      expect(controller.shouldPromptInstall, isTrue);
    });

    test('늦게 온 거절 결과는 상태를 되돌리지 않되 거절은 기억한다', () async {
      gateway.pendingFlow = Completer<InAppUpdateFlowResult>();
      unawaited(controller.start());
      await _settle();

      gateway.states.add(_state(InAppUpdateInstallStatus.downloaded));
      await _settle();

      gateway.pendingFlow!.complete(InAppUpdateFlowResult.canceled);
      await _settle();
      expect(controller.shouldPromptInstall, isTrue);

      // 거절 기록은 남아 있어야 한다. 복귀해도 동의 창을 다시 띄우지 않는다.
      gateway.pendingFlow = null;
      gateway.info = _info();
      await controller.resume();

      expect(gateway.calls.where((call) => call == 'flexible').length, 1);
    });

    test('dispose 뒤에 도착한 조회 응답은 무시한다', () async {
      gateway.pendingCheck = Completer<InAppUpdateInfo>();

      unawaited(controller.start());
      await _settle();

      controller.dispose();
      gateway.pendingCheck!.complete(_info());
      await _settle();

      expect(controller.phase, InAppUpdatePhase.idle);
      // tearDown의 두 번째 dispose가 터지지 않도록 새 컨트롤러로 바꿔 둔다.
      controller = InAppUpdateController(
        gateway: gateway,
        featureFlags: featureFlags,
      );
    });
  });

  group('강제 업데이트', () {
    test('최소 요구 버전에 못 미치면 유연한 흐름 대신 즉시 업데이트를 띄운다', () async {
      featureFlags.minRequiredVersionCode = _installedVersionCode + 1;

      await controller.start();

      expect(gateway.calls, <String>['check', 'immediate']);
      expect(controller.phase, InAppUpdatePhase.installing);
    });

    test('기본값 0이면 아무도 강제하지 않는다', () async {
      // Remote Config를 못 읽었을 때도 이 경로로 떨어진다.
      featureFlags.minRequiredVersionCode = 0;

      await controller.start();

      expect(gateway.calls, <String>['check', 'flexible']);
    });

    test('최소 요구 버전을 이미 만족하면 평소대로 유연한 흐름을 쓴다', () async {
      featureFlags.minRequiredVersionCode = _installedVersionCode;

      await controller.start();

      expect(gateway.calls, <String>['check', 'flexible']);
    });

    test('Play가 즉시 업데이트를 줄 수 없으면 앱을 막지 않는다', () async {
      // 막아 놓고 업데이트도 못 하면 사용자가 빠져나갈 길이 없다.
      featureFlags.minRequiredVersionCode = _installedVersionCode + 1;
      gateway.info = _info(immediateAllowed: false);

      await controller.start();

      expect(gateway.calls, <String>['check', 'flexible']);
      expect(controller.isUpdateRequired, isFalse);
    });

    test('설치된 버전을 모르면 앱을 막지 않는다', () async {
      featureFlags.minRequiredVersionCode = 999;
      gateway.info = _info(installedVersionCode: null);

      await controller.start();

      expect(gateway.calls, <String>['check', 'flexible']);
      expect(controller.isUpdateRequired, isFalse);
    });

    test('사용자가 즉시 업데이트를 닫으면 앱을 막는다', () async {
      featureFlags.minRequiredVersionCode = _installedVersionCode + 1;
      gateway.immediateResult = InAppUpdateFlowResult.canceled;

      await controller.start();

      expect(controller.isUpdateRequired, isTrue);
      expect(controller.shouldPromptInstall, isFalse);
    });

    test('막힌 상태에서 앱에 돌아오면 다시 요구한다', () async {
      featureFlags.minRequiredVersionCode = _installedVersionCode + 1;
      gateway.immediateResult = InAppUpdateFlowResult.canceled;
      await controller.start();
      expect(controller.isUpdateRequired, isTrue);

      await controller.resume();

      // 유연한 흐름과 달리 복귀할 때마다 다시 띄운다.
      expect(gateway.calls, <String>[
        'check',
        'immediate',
        'check',
        'immediate',
      ]);
      expect(controller.isUpdateRequired, isTrue);
    });

    test('막힌 화면에서 업데이트를 다시 누르면 Play 창을 다시 띄운다', () async {
      featureFlags.minRequiredVersionCode = _installedVersionCode + 1;
      gateway.immediateResult = InAppUpdateFlowResult.canceled;
      await controller.start();

      gateway.immediateResult = InAppUpdateFlowResult.accepted;
      await controller.retryRequiredUpdate();

      expect(gateway.calls, <String>['check', 'immediate', 'immediate']);
      expect(controller.phase, InAppUpdatePhase.installing);
    });

    test('강제 업데이트 중에는 재시작 스낵바를 띄우지 않는다', () async {
      // Play의 전체 화면이 진행 상황을 맡는다. 막아 둔 화면 뒤에서
      // "재시작하시겠어요?"가 올라오면 안 된다.
      featureFlags.minRequiredVersionCode = _installedVersionCode + 1;
      gateway.immediateResult = InAppUpdateFlowResult.canceled;
      await controller.start();

      gateway.states.add(_state(InAppUpdateInstallStatus.downloaded));
      await _settle();

      expect(controller.shouldPromptInstall, isFalse);
      expect(controller.isUpdateRequired, isTrue);
    });

    test('Play가 올릴 게 없다고 하면 막지 않고 풀어 준다', () async {
      featureFlags.minRequiredVersionCode = _installedVersionCode + 1;
      gateway.immediateResult = InAppUpdateFlowResult.unavailable;

      await controller.start();

      expect(controller.isUpdateRequired, isFalse);
      expect(controller.phase, InAppUpdatePhase.idle);
    });

    test('흐름 시작 중 조회 오류가 나면 앱을 막지 않는다', () async {
      // 네이티브는 흐름을 띄우기 직전에 appUpdateInfo를 다시 조회한다.
      // 그 두 번째 조회가 실패하면 사용자가 창을 보기도 전에 예외가 온다.
      // 업데이트를 실제로 줄 수 있는지 확인하지 못한 상태이므로 막으면 안 된다.
      featureFlags.minRequiredVersionCode = _installedVersionCode + 1;
      gateway.startError = PlatformException(code: 'update_check_failed');

      await controller.start();

      expect(controller.isUpdateRequired, isFalse);
      expect(controller.phase, InAppUpdatePhase.available);
    });

    test('창을 띄우지 못한 실패는 사용자 거절과 다르게 다룬다', () async {
      // RESULT_IN_APP_UPDATE_FAILED 등 기술적 실패. 막아 놓고 올릴 방법도
      // 없으면 사용자가 빠져나갈 길이 없다.
      featureFlags.minRequiredVersionCode = _installedVersionCode + 1;
      gateway.immediateResult = InAppUpdateFlowResult.failed;

      await controller.start();

      expect(controller.isUpdateRequired, isFalse);
      expect(controller.phase, InAppUpdatePhase.available);
    });

    test('조회 오류로 풀린 뒤 앱에 돌아오면 다시 시도한다', () async {
      featureFlags.minRequiredVersionCode = _installedVersionCode + 1;
      gateway.startError = PlatformException(code: 'update_check_failed');
      await controller.start();
      expect(controller.isUpdateRequired, isFalse);

      // 일시적인 오류였다면 복귀 시 정상적으로 강제할 수 있어야 한다.
      gateway.startError = null;
      gateway.immediateResult = InAppUpdateFlowResult.canceled;
      await controller.resume();

      expect(controller.isUpdateRequired, isTrue);
    });

    test('최소 요구 버전은 한 번만 읽는다', () async {
      featureFlags.minRequiredVersionCode = _installedVersionCode + 1;
      gateway.immediateResult = InAppUpdateFlowResult.canceled;

      await controller.start();
      await controller.resume();
      await controller.resume();

      expect(featureFlags.reads, 1);
    });
  });
}
