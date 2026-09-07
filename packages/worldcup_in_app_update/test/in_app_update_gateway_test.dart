import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worldcup_in_app_update/worldcup_in_app_update.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const methods = MethodChannel(InAppUpdateProtocol.methodChannel);
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  final calls = <MethodCall>[];

  void mockMethods(Future<Object?> Function(MethodCall call) handler) {
    messenger.setMockMethodCallHandler(methods, (call) {
      calls.add(call);
      return handler(call);
    });
  }

  tearDown(() {
    calls.clear();
    messenger.setMockMethodCallHandler(methods, null);
  });

  group('MethodChannelInAppUpdateGateway', () {
    test('네이티브 응답을 InAppUpdateInfo로 옮긴다', () async {
      mockMethods(
        (call) async => <String, Object?>{
          'version': InAppUpdateProtocol.version,
          'availability': 'available',
          'installStatus': 'unknown',
          'flexibleAllowed': true,
          'immediateAllowed': true,
          'availableVersionCode': 31,
          'installedVersionCode': 30,
          'clientVersionStalenessDays': 4,
          'updatePriority': 3,
        },
      );

      final gateway = MethodChannelInAppUpdateGateway(
        isSupportedPlatform: true,
      );
      final info = await gateway.checkForUpdate();

      expect(info.availability, InAppUpdateAvailability.available);
      expect(info.flexibleAllowed, isTrue);
      expect(info.canStartFlexibleUpdate, isTrue);
      expect(info.canStartImmediateUpdate, isTrue);
      expect(info.availableVersionCode, 31);
      expect(info.installedVersionCode, 30);
      expect(info.clientVersionStalenessDays, 4);
      expect(info.updatePriority, 3);
      expect(calls.single.method, InAppUpdateProtocol.checkForUpdate);
      expect(
        (calls.single.arguments as Map)['version'],
        InAppUpdateProtocol.version,
      );
    });

    test('프로토콜 버전이 다르면 예외를 던진다', () async {
      mockMethods(
        (call) async => <String, Object?>{
          'version': InAppUpdateProtocol.version + 1,
          'availability': 'available',
          'installStatus': 'unknown',
          'flexibleAllowed': true,
          'immediateAllowed': true,
        },
      );

      final gateway = MethodChannelInAppUpdateGateway(
        isSupportedPlatform: true,
      );

      expect(
        gateway.checkForUpdate(),
        throwsA(isA<InAppUpdateProtocolException>()),
      );
    });

    test('모르는 결과 문자열은 실패로 본다', () async {
      mockMethods((call) async => 'something_new');

      final gateway = MethodChannelInAppUpdateGateway(
        isSupportedPlatform: true,
      );

      expect(await gateway.startFlexibleUpdate(), InAppUpdateFlowResult.failed);
    });

    test('사용자 결정을 그대로 옮긴다', () async {
      mockMethods((call) async => 'accepted');

      final gateway = MethodChannelInAppUpdateGateway(
        isSupportedPlatform: true,
      );

      expect(
        await gateway.startFlexibleUpdate(),
        InAppUpdateFlowResult.accepted,
      );
    });

    test('즉시 업데이트는 별도의 네이티브 메서드를 부른다', () async {
      mockMethods((call) async => 'accepted');

      final gateway = MethodChannelInAppUpdateGateway(
        isSupportedPlatform: true,
      );

      expect(
        await gateway.startImmediateUpdate(),
        InAppUpdateFlowResult.accepted,
      );
      expect(calls.single.method, InAppUpdateProtocol.startImmediateUpdate);
    });

    test('안드로이드가 아니면 채널을 건드리지 않는다', () async {
      mockMethods((call) async => fail('채널을 호출하면 안 된다'));

      final gateway = MethodChannelInAppUpdateGateway(
        isSupportedPlatform: false,
      );

      expect(await gateway.checkForUpdate(), same(InAppUpdateInfo.unsupported));
      expect(
        await gateway.startFlexibleUpdate(),
        InAppUpdateFlowResult.unavailable,
      );
      expect(
        await gateway.startImmediateUpdate(),
        InAppUpdateFlowResult.unavailable,
      );
      await gateway.completeUpdate();
      expect(await gateway.installStates.isEmpty, isTrue);
      expect(calls, isEmpty);
    });
  });

  group('InAppUpdateInfo', () {
    InAppUpdateInfo info({
      InAppUpdateAvailability availability = InAppUpdateAvailability.available,
      bool immediateAllowed = true,
      int? installedVersionCode = 30,
    }) {
      return InAppUpdateInfo(
        availability: availability,
        installStatus: InAppUpdateInstallStatus.unknown,
        flexibleAllowed: true,
        immediateAllowed: immediateAllowed,
        availableVersionCode: 31,
        installedVersionCode: installedVersionCode,
        clientVersionStalenessDays: null,
        updatePriority: 0,
      );
    }

    test('깔린 버전이 최소 요구 버전보다 낮으면 참이다', () {
      expect(info().isBelowRequiredVersion(31), isTrue);
    });

    test('최소 요구 버전과 같으면 거짓이다', () {
      expect(info().isBelowRequiredVersion(30), isFalse);
    });

    test('깔린 버전을 모르면 사용자를 막지 않는다', () {
      // 근거가 없을 때 앱을 잠그면 빠져나갈 길이 없다.
      expect(
        info(installedVersionCode: null).isBelowRequiredVersion(99),
        isFalse,
      );
    });

    test('멈춰 있는 즉시 업데이트는 다시 띄울 수 있다', () {
      // Play가 DEVELOPER_TRIGGERED_UPDATE_IN_PROGRESS를 돌려주는 경우.
      final stalled = info(
        availability: InAppUpdateAvailability.inProgress,
        immediateAllowed: false,
      );
      expect(stalled.canStartImmediateUpdate, isTrue);
      expect(stalled.canStartFlexibleUpdate, isFalse);
    });

    test('즉시 업데이트가 허용되지 않으면 띄우지 않는다', () {
      expect(info(immediateAllowed: false).canStartImmediateUpdate, isFalse);
    });
  });

  group('InAppUpdateInstallState', () {
    test('진행률을 계산한다', () {
      final state = InAppUpdateInstallState.fromMap(<String, Object?>{
        'version': InAppUpdateProtocol.version,
        'status': 'downloading',
        'bytesDownloaded': 50,
        'totalBytesToDownload': 200,
        'errorCode': 0,
      });

      expect(state.status, InAppUpdateInstallStatus.downloading);
      expect(state.progress, 0.25);
    });

    test('전체 크기를 모르면 진행률이 없다', () {
      final state = InAppUpdateInstallState.fromMap(<String, Object?>{
        'version': InAppUpdateProtocol.version,
        'status': 'pending',
        'bytesDownloaded': 0,
        'totalBytesToDownload': 0,
        'errorCode': 0,
      });

      expect(state.progress, isNull);
    });

    test('모르는 상태 이름은 unknown으로 떨어진다', () {
      final state = InAppUpdateInstallState.fromMap(<String, Object?>{
        'version': InAppUpdateProtocol.version,
        'status': 'teleporting',
        'bytesDownloaded': 0,
        'totalBytesToDownload': 0,
        'errorCode': 0,
      });

      expect(state.status, InAppUpdateInstallStatus.unknown);
    });
  });
}
