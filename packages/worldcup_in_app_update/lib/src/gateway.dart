import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'models.dart';
import 'protocol.dart';

/// Play In-App Update(유연한 업데이트)를 감싸는 포트.
///
/// 화면과 뷰모델은 이 인터페이스에만 의존하므로 테스트에서 가짜 구현으로
/// 바꿔 끼울 수 있다.
abstract interface class InAppUpdateGateway {
  /// 내려받기/설치 진행 상황. 안드로이드가 아니면 아무것도 흘리지 않는다.
  Stream<InAppUpdateInstallState> get installStates;

  /// Play에 새 버전이 있는지 묻는다. 실패하면 예외 대신 [InAppUpdateInfo.unsupported]다.
  Future<InAppUpdateInfo> checkForUpdate();

  /// 유연한 업데이트 동의 화면을 띄운다.
  /// 사용자가 선택을 끝낸 뒤에 완료된다.
  Future<InAppUpdateFlowResult> startFlexibleUpdate();

  /// 내려받아 둔 업데이트를 설치한다. 성공하면 Play가 앱을 재시작한다.
  Future<void> completeUpdate();
}

class MethodChannelInAppUpdateGateway implements InAppUpdateGateway {
  final MethodChannel _methods;
  final EventChannel _eventChannel;

  /// 인앱 업데이트는 Play 스토어가 배포한 안드로이드 앱에서만 동작한다.
  /// 그 외 플랫폼에서는 채널을 아예 건드리지 않는다.
  final bool _supported;

  Stream<InAppUpdateInstallState>? _installStates;

  MethodChannelInAppUpdateGateway({
    MethodChannel? methods,
    EventChannel? eventChannel,
    bool? isSupportedPlatform,
  }) : _methods =
           methods ?? const MethodChannel(InAppUpdateProtocol.methodChannel),
       _eventChannel =
           eventChannel ?? const EventChannel(InAppUpdateProtocol.eventChannel),
       _supported =
           isSupportedPlatform ??
           (!kIsWeb && defaultTargetPlatform == TargetPlatform.android);

  Map<String, Object> get _arguments => <String, Object>{
    'version': InAppUpdateProtocol.version,
  };

  @override
  Stream<InAppUpdateInstallState> get installStates {
    if (!_supported) return const Stream<InAppUpdateInstallState>.empty();
    return _installStates ??= _eventChannel
        .receiveBroadcastStream(_arguments)
        .map(InAppUpdateInstallState.fromMap);
  }

  @override
  Future<InAppUpdateInfo> checkForUpdate() async {
    if (!_supported) return InAppUpdateInfo.unsupported;
    final result = await _methods.invokeMethod<Object>(
      InAppUpdateProtocol.checkForUpdate,
      _arguments,
    );
    return InAppUpdateInfo.fromMap(result);
  }

  @override
  Future<InAppUpdateFlowResult> startFlexibleUpdate() async {
    if (!_supported) return InAppUpdateFlowResult.unavailable;
    final result = await _methods.invokeMethod<String>(
      InAppUpdateProtocol.startFlexibleUpdate,
      _arguments,
    );
    for (final value in InAppUpdateFlowResult.values) {
      if (value.name == result) return value;
    }
    return InAppUpdateFlowResult.failed;
  }

  @override
  Future<void> completeUpdate() async {
    if (!_supported) return;
    await _methods.invokeMethod<void>(
      InAppUpdateProtocol.completeUpdate,
      _arguments,
    );
  }
}
