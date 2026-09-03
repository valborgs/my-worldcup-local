import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_worldcup_local/models/worldcup_model.dart';
import 'package:my_worldcup_local/screens/nearby_worldcup_transfer_screen.dart';
import 'package:my_worldcup_local/services/nearby_worldcup_transfer_controller.dart';
import 'package:my_worldcup_local/services/worldcup_package_service.dart';
import 'package:worldcup_nearby_transfer/worldcup_nearby_transfer.dart';

void main() {
  testWidgets('받기 화면은 상대 이름, 인증 코드, 수락/거절과 진행률을 표시하고 dispose한다',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 480));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final gateway = _ScreenFakeGateway();
    final controller = NearbyWorldCupTransferController.receiver(
      gateway: gateway,
      packageGateway: _UnusedPackageGateway(),
      displayNameProvider: () => '받는 기기',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 480),
            textScaler: TextScaler.linear(1.8),
          ),
          child: NearbyWorldCupReceiveScreen(controller: controller),
        ),
      ),
    );
    await tester.pumpAndSettle();

    gateway.add(const NearbyConnectionRequest(
      endpoint: NearbyEndpoint(
        id: 'sender',
        name: '매우 긴 이름을 가진 상대방의 스마트폰 기기',
      ),
      incoming: true,
    ));
    gateway.add(const NearbyVerificationCode(
      endpointId: 'sender',
      endpointName: '매우 긴 이름을 가진 상대방의 스마트폰 기기',
      code: '4821',
    ));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('4821'),
      160,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('4821'), findsOneWidget);
    expect(find.text('코드 일치 · 수락'), findsOneWidget);
    expect(find.text('거절'), findsOneWidget);
    expect(tester.takeException(), isNull);

    gateway.add(const NearbyTransferProgress(
      endpointId: 'sender',
      payloadId: '1',
      direction: NearbyTransferDirection.receiving,
      status: NearbyTransferStatus.inProgress,
      bytesTransferred: 40,
      totalBytes: 100,
    ));
    await tester.pump();

    await tester.scrollUntilVisible(
      find.text('40%'),
      -160,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('40%'), findsOneWidget);
    expect(
      tester
          .widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator))
          .value,
      .4,
    );
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    await tester.pump();
    expect(gateway.disposeCalls, greaterThanOrEqualTo(1));
  });
}

class _ScreenFakeGateway implements NearbyTransferGateway {
  final _events = StreamController<NearbyEvent>.broadcast();
  int disposeCalls = 0;

  void add(NearbyEvent event) => _events.add(event);

  @override
  Stream<NearbyEvent> get events => _events.stream;

  @override
  Future<void> acceptConnection(String endpointId) async {}

  @override
  Future<NearbyAvailability> checkAvailability() async => _availability;

  @override
  Future<void> cancelTransfer() async {}

  @override
  Future<void> disconnect() async {}

  @override
  Future<void> dispose() async => disposeCalls++;

  @override
  Future<void> openAppSettings() async {}

  @override
  Future<void> rejectConnection(String endpointId) async {}

  @override
  Future<void> requestConnection({
    required String endpointId,
    required String displayName,
  }) async {}

  @override
  Future<NearbyAvailability> requestPermissions() async => _availability;

  @override
  Future<void> sendFile({
    required String endpointId,
    required String path,
    required String name,
  }) async {}

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

class _UnusedPackageGateway implements WorldCupPackageGateway {
  @override
  Future<File> createPackage(WorldCupModel model) => throw UnimplementedError();

  @override
  Future<ImportedWorldCup> importPackage(String packagePath) =>
      throw UnimplementedError();

  @override
  Future<void> shareWorldCup(
    WorldCupModel model, {
    Rect? sharePositionOrigin,
  }) =>
      throw UnimplementedError();
}
