import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
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
    expect(controller.phase, NearbyTransferPhase.connecting);
    expect(controller.needsConnectionDecision, isFalse,
        reason: '인증 코드 없이 연결을 수락할 수 없어야 한다.');

    gateway.add(const NearbyVerificationCode(
      endpointId: 'sender',
      endpointName: 'Pixel',
      code: '5678',
    ));
    await _flush();
    expect(controller.phase, NearbyTransferPhase.verifying);
    expect(controller.needsConnectionDecision, isTrue);
    expect(controller.peer?.name, 'Pixel');

    await controller.rejectConnection();
    expect(gateway.rejects, 1);
    expect(gateway.disposeCalls, 1);
    expect(controller.phase, NearbyTransferPhase.canceled);
  });

  test('수신 파일 완료 후 자동 import와 목록 갱신 콜백을 호출한다', () async {
    final nativeDirectory = Directory('${temporaryDirectory.path}/native')
      ..createSync();
    final file = File('${nativeDirectory.path}/received.myworldcup');
    await file.writeAsBytes([1, 2, 3, 4], flush: true);
    final gateway = _FakeNearbyGateway();
    final packageGateway = _FakePackageGateway(temporaryDirectory);
    var refreshCalls = 0;
    final controller = NearbyWorldCupTransferController.receiver(
      gateway: gateway,
      packageGateway: packageGateway,
      displayNameProvider: () => '받는 기기',
      temporaryDirectoryProvider: () async => temporaryDirectory,
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
    final nativeDirectory = Directory('${temporaryDirectory.path}/native')
      ..createSync();
    final file = File('${nativeDirectory.path}/broken.myworldcup');
    await file.writeAsBytes([1, 2], flush: true);
    final gateway = _FakeNearbyGateway();
    final packageGateway = _FakePackageGateway(temporaryDirectory)
      ..importError = const WorldCupPackageException('손상된 패키지입니다.');
    final controller = NearbyWorldCupTransferController.receiver(
      gateway: gateway,
      packageGateway: packageGateway,
      displayNameProvider: () => '받는 기기',
      temporaryDirectoryProvider: () async => temporaryDirectory,
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

  test('알 수 없는 가져오기 실패는 재전송 가능한 안내를 표시한다', () async {
    final nativeDirectory = Directory('${temporaryDirectory.path}/native')
      ..createSync();
    final file = File('${nativeDirectory.path}/unknown.myworldcup');
    await file.writeAsBytes([1, 2], flush: true);
    final gateway = _FakeNearbyGateway();
    final packageGateway = _FakePackageGateway(temporaryDirectory)
      ..importError = StateError('internal import detail');
    final controller = NearbyWorldCupTransferController.receiver(
      gateway: gateway,
      packageGateway: packageGateway,
      displayNameProvider: () => '받는 기기',
      temporaryDirectoryProvider: () async => temporaryDirectory,
    );
    addTearDown(controller.dispose);
    await controller.start();

    gateway.add(NearbyFileReceived(
      endpointId: 'sender',
      payloadId: 'unknown-error',
      path: file.path,
      name: 'unknown.myworldcup',
      size: 2,
    ));
    await _flush();
    await _flush();

    expect(controller.phase, NearbyTransferPhase.error);
    expect(
      controller.message,
      '받은 월드컵을 등록하지 못했습니다. 보내는 기기에서 다시 보내주세요.',
    );
    expect(controller.message, isNot(contains('파일을 확인')));
    expect(await file.exists(), isFalse);
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

  test('검색 실패의 네이티브 상세 정보는 사용자 메시지에 노출하지 않는다', () async {
    final gateway = _FakeNearbyGateway()
      ..startDiscoveryError = PlatformException(
        code: 'unavailable',
        message: '주변 기기 검색을 시작할 수 없습니다.',
        details: const {
          'nativeStatusCode': 8032,
          'nativeStatus': 'MISSING_PERMISSION_ACCESS_WIFI_STATE',
        },
      );
    final controller = NearbyWorldCupTransferController.sender(
      gateway: gateway,
      packageGateway: _FakePackageGateway(temporaryDirectory),
      worldCup: _worldCup,
      displayNameProvider: () => '보내는 기기',
    );
    addTearDown(controller.dispose);

    await controller.start();

    expect(controller.phase, NearbyTransferPhase.error);
    expect(controller.message, '주변 기기 검색을 시작할 수 없습니다.');
    expect(controller.message, isNot(contains('8032')));
    expect(controller.message, isNot(contains('MISSING_PERMISSION')));

    await controller.cancel();
    expect(controller.phase, NearbyTransferPhase.error,
        reason: '설정 화면 이동으로 lifecycle pause가 발생해도 기존 오류를 보존해야 한다.');
    expect(gateway.cancelCalls, 0);
  });

  test('수신 완료 뒤 연결이 끊겨도 파일 소유권 이전과 import를 끝낸다', () async {
    final nativeDirectory = Directory('${temporaryDirectory.path}/native')
      ..createSync();
    final file = File('${nativeDirectory.path}/received.myworldcup');
    await file.writeAsBytes([1, 2, 3, 4], flush: true);
    final gateway = _FakeNearbyGateway();
    final packageGateway = _FakePackageGateway(temporaryDirectory)
      ..importCompleter = Completer<ImportedWorldCup>();
    final controller = NearbyWorldCupTransferController.receiver(
      gateway: gateway,
      packageGateway: packageGateway,
      displayNameProvider: () => '받는 기기',
      temporaryDirectoryProvider: () async => temporaryDirectory,
    );
    addTearDown(controller.dispose);
    await controller.start();

    gateway.add(const NearbyTransferProgress(
      endpointId: 'sender',
      payloadId: '10',
      direction: NearbyTransferDirection.receiving,
      status: NearbyTransferStatus.success,
      bytesTransferred: 4,
      totalBytes: 4,
    ));
    gateway.add(const NearbyConnectionChanged(
      endpointId: 'sender',
      state: NearbyConnectionState.disconnected,
    ));
    await _flush();

    expect(controller.phase, NearbyTransferPhase.transferring);
    expect(gateway.disposeCalls, 0);

    gateway.add(NearbyFileReceived(
      endpointId: 'sender',
      payloadId: '10',
      path: file.path,
      name: 'received.myworldcup',
      size: 4,
    ));
    await _flush();
    expect(controller.phase, NearbyTransferPhase.importing);
    expect(await file.exists(), isFalse,
        reason: 'import 전에 네이티브 정리와 분리된 앱 임시 경로로 이동해야 한다.');

    await controller.cancel();
    expect(controller.phase, NearbyTransferPhase.importing,
        reason: '앱 lifecycle pause가 import를 취소해서는 안 된다.');

    gateway.add(const NearbyConnectionChanged(
      endpointId: 'sender',
      state: NearbyConnectionState.disconnected,
    ));
    await _flush();
    expect(controller.phase, NearbyTransferPhase.importing);
    expect(gateway.disposeCalls, 0);

    packageGateway.importCompleter!.complete(
      const ImportedWorldCup(idx: 99, title: '레이스 방지'),
    );
    await _flush();
    await _flush();

    expect(controller.phase, NearbyTransferPhase.success);
    expect(gateway.disposeCalls, 1);
  });

  test('패키지 생성 중 취소하면 생성 완료 후 전송을 다시 시작하지 않는다', () async {
    final gateway = _FakeNearbyGateway();
    final packageGateway = _FakePackageGateway(temporaryDirectory)
      ..createCompleter = Completer<File>();
    final controller = NearbyWorldCupTransferController.sender(
      gateway: gateway,
      packageGateway: packageGateway,
      worldCup: _worldCup,
      displayNameProvider: () => '보내는 기기',
    );
    addTearDown(controller.dispose);
    await controller.start();
    gateway.add(
      const NearbyEndpointFound(NearbyEndpoint(id: 'peer', name: '받는 기기')),
    );
    await _flush();
    await controller.connect(controller.endpoints.single);
    gateway.add(const NearbyConnectionChanged(
      endpointId: 'peer',
      state: NearbyConnectionState.connected,
    ));
    await _flush();
    expect(controller.phase, NearbyTransferPhase.preparing);

    await controller.cancel();
    final package = File('${temporaryDirectory.path}/late.myworldcup');
    await package.writeAsBytes([1, 2, 3], flush: true);
    packageGateway.createCompleter!.complete(package);
    await _flush();

    expect(controller.phase, NearbyTransferPhase.canceled);
    expect(gateway.sendCalls, 0);
    expect(await package.exists(), isFalse);
  });

  test('주변 기기 검색에는 무한 대기를 막는 timeout이 적용된다', () async {
    final gateway = _FakeNearbyGateway();
    final controller = NearbyWorldCupTransferController.sender(
      gateway: gateway,
      packageGateway: _FakePackageGateway(temporaryDirectory),
      worldCup: _worldCup,
      displayNameProvider: () => '보내는 기기',
      timeouts: const NearbyTransferTimeouts(
        discovery: Duration(milliseconds: 30),
      ),
    );
    addTearDown(controller.dispose);

    await controller.start();
    await Future<void>.delayed(const Duration(milliseconds: 80));

    expect(controller.phase, NearbyTransferPhase.error);
    expect(controller.message, contains('주변 기기를 찾지 못했습니다'));
    expect(gateway.disposeCalls, 1);
  });

  test('payload 완료 후 파일 이벤트가 오지 않으면 timeout으로 정리한다', () async {
    final gateway = _FakeNearbyGateway();
    final controller = NearbyWorldCupTransferController.receiver(
      gateway: gateway,
      packageGateway: _FakePackageGateway(temporaryDirectory),
      displayNameProvider: () => '받는 기기',
      timeouts: const NearbyTransferTimeouts(
        finalization: Duration(milliseconds: 30),
      ),
    );
    addTearDown(controller.dispose);
    await controller.start();
    gateway.add(const NearbyConnectionChanged(
      endpointId: 'sender',
      state: NearbyConnectionState.connected,
    ));
    gateway.add(const NearbyTransferProgress(
      endpointId: 'sender',
      payloadId: 'missing-metadata',
      direction: NearbyTransferDirection.receiving,
      status: NearbyTransferStatus.success,
      bytesTransferred: 4,
      totalBytes: 4,
    ));
    await Future<void>.delayed(const Duration(milliseconds: 80));

    expect(controller.phase, NearbyTransferPhase.error);
    expect(controller.message, contains('수신 파일 확인 시간이 초과되었습니다'));
    expect(gateway.cancelCalls, 1);
    expect(gateway.disposeCalls, 1);
  });

  test('기본 표시 이름은 개인정보 대신 한 세션 동안 동일한 익명 별칭을 사용한다', () async {
    final gateway = _FakeNearbyGateway();
    final controller = NearbyWorldCupTransferController.sender(
      gateway: gateway,
      packageGateway: _FakePackageGateway(temporaryDirectory),
      worldCup: _worldCup,
    );
    addTearDown(controller.dispose);

    await controller.start();
    gateway.add(
      const NearbyEndpointFound(NearbyEndpoint(id: 'peer', name: '받는 기기')),
    );
    await _flush();
    await controller.connect(controller.endpoints.single);

    expect(gateway.discoveryDisplayName, matches(RegExp(r'^월드컵 기기 \d{4}$')));
    expect(controller.displayName, gateway.discoveryDisplayName);
    expect(gateway.connectionDisplayName, gateway.discoveryDisplayName);
    expect(gateway.discoveryDisplayName, isNot('localhost'));

    final nextController = NearbyWorldCupTransferController.receiver(
      gateway: _FakeNearbyGateway(),
      packageGateway: _FakePackageGateway(temporaryDirectory),
    );
    addTearDown(nextController.dispose);
    expect(nextController.displayName, controller.displayName,
        reason: '화면을 다시 열어도 앱 실행 중에는 같은 익명 별칭을 사용해야 한다.');
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
  Object? startDiscoveryError;
  String? discoveryDisplayName;
  String? connectionDisplayName;

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
  }) async {
    connectionRequests++;
    connectionDisplayName = displayName;
  }

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
  Future<void> startDiscovery({required String displayName}) async {
    discoveryDisplayName = displayName;
    final error = startDiscoveryError;
    if (error != null) throw error;
  }

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
  Completer<File>? createCompleter;
  Completer<ImportedWorldCup>? importCompleter;

  _FakePackageGateway(this.directory);

  @override
  Future<File> createPackage(WorldCupModel model) async {
    createCalls++;
    final completer = createCompleter;
    if (completer != null) return completer.future;
    return File('${directory.path}/send.myworldcup')
      ..writeAsBytesSync([1, 2, 3]);
  }

  @override
  Future<ImportedWorldCup> importPackage(String packagePath) async {
    importCalls++;
    final completer = importCompleter;
    if (completer != null) return completer.future;
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
