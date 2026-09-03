import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_worldcup_local/models/worldcup_model.dart';
import 'package:my_worldcup_local/services/nearby_worldcup_transfer_controller.dart';
import 'package:my_worldcup_local/services/worldcup_package_service.dart';
import 'package:worldcup_nearby_transfer/worldcup_nearby_transfer.dart';

void main() {
  late Directory temporaryDirectory;

  setUp(() async {
    temporaryDirectory =
        await Directory.systemTemp.createTemp('nearby_controller_test_');
  });

  tearDown(() async {
    if (await temporaryDirectory.exists()) {
      await temporaryDirectory.delete(recursive: true);
    }
  });

  test('발견 기기 목록, 인증 코드, 수락 상태와 중복 전송 방지를 관리한다', () async {
    final gateway = _FakeNearbyGateway();
    final packageGateway = _FakePackageGateway(temporaryDirectory);
    final controller = NearbyWorldCupTransferController.sender(
      gateway: gateway,
      packageGateway: packageGateway,
      worldCup: _worldCup,
      displayNameProvider: () => '보내는 기기',
    );
    addTearDown(controller.dispose);

    await controller.start();
    expect(controller.phase, NearbyTransferPhase.discovering);

    gateway.add(
        const NearbyEndpointFound(NearbyEndpoint(id: 'b', name: 'iPhone')));
    gateway.add(
        const NearbyEndpointFound(NearbyEndpoint(id: 'a', name: 'Android')));
    await _flush();
    expect(
        controller.endpoints.map((item) => item.name), ['Android', 'iPhone']);

    await controller.connect(controller.endpoints.first);
    expect(gateway.connectionRequests, 1);
    gateway.add(const NearbyVerificationCode(
      endpointId: 'a',
      endpointName: 'Android',
      code: '1234',
    ));
    await _flush();
    expect(controller.phase, NearbyTransferPhase.verifying);
    expect(controller.verificationCode, '1234');

    await controller.acceptConnection();
    expect(gateway.accepts, 1);
    gateway.add(const NearbyConnectionChanged(
      endpointId: 'a',
      state: NearbyConnectionState.connected,
    ));
    gateway.add(const NearbyConnectionChanged(
      endpointId: 'a',
      state: NearbyConnectionState.connected,
    ));
    await _flush();
    await _flush();

    expect(packageGateway.createCalls, 1);
    expect(gateway.sendCalls, 1, reason: '연결 이벤트가 중복되어도 파일은 한 번만 보낸다.');

    gateway.add(const NearbyTransferProgress(
      endpointId: 'a',
      payloadId: '7',
      direction: NearbyTransferDirection.sending,
      status: NearbyTransferStatus.inProgress,
      bytesTransferred: 50,
      totalBytes: 100,
    ));
    await _flush();
    expect(controller.progress, .5);
    expect(controller.phase, NearbyTransferPhase.transferring);
  });

  test('연결 요청을 명시적으로 거절하고 리소스를 정리한다', () async {
    final gateway = _FakeNearbyGateway();
    final controller = NearbyWorldCupTransferController.receiver(
      gateway: gateway,
      packageGateway: _FakePackageGateway(temporaryDirectory),
      displayNameProvider: () => '받는 기기',
    );
    addTearDown(controller.dispose);
    await controller.start();

    gateway.add(const NearbyConnectionRequest(
      endpoint: NearbyEndpoint(id: 'sender', name: 'Pixel'),
      incoming: true,
    ));
    await _flush();
    expect(controller.phase, NearbyTransferPhase.connectionRequest);
    expect(controller.peer?.name, 'Pixel');

    await controller.rejectConnection();
    expect(gateway.rejects, 1);
    expect(gateway.disposeCalls, 1);
    expect(controller.phase, NearbyTransferPhase.canceled);
  });

  test('수신 파일 완료 후 자동 import와 목록 갱신 콜백을 호출한다', () async {
    final file = File('${temporaryDirectory.path}/received.myworldcup');
    await file.writeAsBytes([1, 2, 3, 4], flush: true);
    final gateway = _FakeNearbyGateway();
    final packageGateway = _FakePackageGateway(temporaryDirectory);
    var refreshCalls = 0;
    final controller = NearbyWorldCupTransferController.receiver(
      gateway: gateway,
      packageGateway: packageGateway,
      displayNameProvider: () => '받는 기기',
      onImported: (_) async => refreshCalls++,
    );
    addTearDown(controller.dispose);
    await controller.start();

    gateway.add(NearbyFileReceived(
      endpointId: 'sender',
      payloadId: '8',
      path: file.path,
      name: '테스트.myworldcup',
      size: 4,
    ));
    await _flush();
    await _flush();

    expect(packageGateway.importCalls, 1);
    expect(refreshCalls, 1);
    expect(controller.phase, NearbyTransferPhase.success);
    expect(controller.message, '"받은 월드컵" 월드컵을 받았습니다.');
    expect(await file.exists(), isFalse);
  });

  test('가져오기 실패 시 임시 파일을 지우고 원인을 표시한다', () async {
    final file = File('${temporaryDirectory.path}/broken.myworldcup');
    await file.writeAsBytes([1, 2], flush: true);
    final gateway = _FakeNearbyGateway();
    final packageGateway = _FakePackageGateway(temporaryDirectory)
      ..importError = const WorldCupPackageException('손상된 패키지입니다.');
    final controller = NearbyWorldCupTransferController.receiver(
      gateway: gateway,
      packageGateway: packageGateway,
      displayNameProvider: () => '받는 기기',
    );
    addTearDown(controller.dispose);
    await controller.start();

    gateway.add(NearbyFileReceived(
      endpointId: 'sender',
      payloadId: '9',
      path: file.path,
      name: 'broken.myworldcup',
      size: 2,
    ));
    await _flush();
    await _flush();

    expect(controller.phase, NearbyTransferPhase.error);
    expect(controller.message, '손상된 패키지입니다.');
    expect(await file.exists(), isFalse);
    expect(gateway.disposeCalls, 1);
  });

  test('취소, 연결 끊김, dispose에서 네이티브 정리를 호출한다', () async {
    final cancelGateway = _FakeNearbyGateway();
    final cancelController = NearbyWorldCupTransferController.receiver(
      gateway: cancelGateway,
      packageGateway: _FakePackageGateway(temporaryDirectory),
      displayNameProvider: () => '받는 기기',
    );
    await cancelController.start();
    await cancelController.cancel();
    expect(cancelGateway.cancelCalls, 1);
    expect(cancelGateway.disposeCalls, 1);
    cancelController.dispose();

    final disconnectGateway = _FakeNearbyGateway();
    final disconnectController = NearbyWorldCupTransferController.receiver(
      gateway: disconnectGateway,
      packageGateway: _FakePackageGateway(temporaryDirectory),
      displayNameProvider: () => '받는 기기',
    );
    await disconnectController.start();
    disconnectGateway.add(const NearbyConnectionChanged(
      endpointId: 'sender',
      state: NearbyConnectionState.disconnected,
    ));
    await _flush();
    expect(disconnectController.phase, NearbyTransferPhase.error);
    disconnectController.dispose();
    await _flush();
    expect(disconnectGateway.disposeCalls, greaterThanOrEqualTo(1));
  });
}

final _worldCup = WorldCupModel(1, '전송 테스트', '', DateTime(2026), '', 4);

Future<void> _flush() => Future<void>.delayed(const Duration(milliseconds: 20));

class _FakeNearbyGateway implements NearbyTransferGateway {
  final _events = StreamController<NearbyEvent>.broadcast();
  int connectionRequests = 0;
  int accepts = 0;
  int rejects = 0;
  int sendCalls = 0;
  int cancelCalls = 0;
  int disposeCalls = 0;

  void add(NearbyEvent event) => _events.add(event);

  @override
  Stream<NearbyEvent> get events => _events.stream;

  @override
  Future<void> acceptConnection(String endpointId) async => accepts++;

  @override
  Future<NearbyAvailability> checkAvailability() async => _availability;

  @override
  Future<void> cancelTransfer() async => cancelCalls++;

  @override
  Future<void> disconnect() async {}

  @override
  Future<void> dispose() async => disposeCalls++;

  @override
  Future<void> openAppSettings() async {}

  @override
  Future<void> rejectConnection(String endpointId) async => rejects++;

  @override
  Future<void> requestConnection({
    required String endpointId,
    required String displayName,
  }) async =>
      connectionRequests++;

  @override
  Future<NearbyAvailability> requestPermissions() async => _availability;

  @override
  Future<void> sendFile({
    required String endpointId,
    required String path,
    required String name,
  }) async =>
      sendCalls++;

  @override
  Future<void> startAdvertising({required String displayName}) async {}

  @override
  Future<void> startDiscovery({required String displayName}) async {}

  @override
  Future<void> stopAdvertising() async {}

  @override
  Future<void> stopDiscovery() async {}
}

const _availability = NearbyAvailability(
  supported: true,
  permission: NearbyPermissionState.granted,
  bluetooth: NearbyRadioState.enabled,
  wifi: NearbyRadioState.enabled,
  canOpenSettings: true,
);

class _FakePackageGateway implements WorldCupPackageGateway {
  final Directory directory;
  int createCalls = 0;
  int importCalls = 0;
  Object? importError;

  _FakePackageGateway(this.directory);

  @override
  Future<File> createPackage(WorldCupModel model) async {
    createCalls++;
    return File('${directory.path}/send.myworldcup')
      ..writeAsBytesSync([1, 2, 3]);
  }

  @override
  Future<ImportedWorldCup> importPackage(String packagePath) async {
    importCalls++;
    final error = importError;
    if (error != null) throw error;
    return const ImportedWorldCup(idx: 88, title: '받은 월드컵');
  }

  @override
  Future<void> shareWorldCup(
    WorldCupModel model, {
    Rect? sharePositionOrigin,
  }) async {}
}
