import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_worldcup_local/update/in_app_update_controller.dart';
import 'package:worldcup_in_app_update/worldcup_in_app_update.dart';

InAppUpdateInfo _info({
  InAppUpdateAvailability availability = InAppUpdateAvailability.available,
  InAppUpdateInstallStatus installStatus = InAppUpdateInstallStatus.unknown,
  bool flexibleAllowed = true,
}) {
  return InAppUpdateInfo(
    availability: availability,
    installStatus: installStatus,
    flexibleAllowed: flexibleAllowed,
    availableVersionCode: 31,
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

  /// 값을 넣으면 동의 창이 열린 채로 멈춘다.
  Completer<InAppUpdateFlowResult>? pendingFlow;

  InAppUpdateFlowResult flowResult = InAppUpdateFlowResult.accepted;
  Object? checkError;
  Object? completeError;

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
    calls.add('start');
    final pending = pendingFlow;
    if (pending != null) return pending.future;
    return Future<InAppUpdateFlowResult>.value(flowResult);
  }

  @override
  Future<void> completeUpdate() {
    calls.add('complete');
    if (completeError != null) return Future<void>.error(completeError!);
    return Future<void>.value();
  }
}

Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  late _FakeGateway gateway;
  late InAppUpdateController controller;

  setUp(() {
    gateway = _FakeGateway();
    controller = InAppUpdateController(gateway: gateway);
  });

  tearDown(() {
    controller.dispose();
    gateway.states.close();
  });

  test('새 버전이 있으면 동의 창을 띄우고, 수락하면 조용히 내려받는다', () async {
    await controller.start();

    expect(gateway.calls, <String>['check', 'start']);
    expect(controller.phase, InAppUpdatePhase.downloading);
    expect(controller.shouldPromptInstall, isFalse);
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

    expect(gateway.calls, <String>['check', 'start', 'check']);
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

  test('동의 창이 떠 있는 동안 앱에 돌아와도 사용자의 선택을 놓치지 않는다', () async {
    // Play 동의 창이 뜨면 앱이 잠깐 백그라운드로 내려갔다가 복귀한다.
    // 이때 조회를 새로 시작하면 세대 번호가 올라가 동의 결과가 버려진다.
    gateway.pendingFlow = Completer<InAppUpdateFlowResult>();

    unawaited(controller.start());
    await _settle();
    expect(gateway.calls, <String>['check', 'start']);

    await controller.resume();
    expect(gateway.calls, <String>['check', 'start']);

    gateway.pendingFlow!.complete(InAppUpdateFlowResult.accepted);
    await _settle();

    expect(controller.phase, InAppUpdatePhase.downloading);
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
    controller = InAppUpdateController(gateway: gateway);
  });
}
