import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:worldcup_nearby_transfer/worldcup_nearby_transfer.dart';

import '../models/worldcup_model.dart';
import 'worldcup_package_service.dart';

enum NearbyTransferMode { send, receive }

enum NearbyTransferPhase {
  preparing,
  discovering,
  advertising,
  connectionRequest,
  verifying,
  connecting,
  connected,
  transferring,
  importing,
  success,
  canceled,
  error,
}

class NearbyWorldCupTransferController extends ChangeNotifier {
  final NearbyTransferMode mode;
  final NearbyTransferGateway gateway;
  final WorldCupPackageGateway packageGateway;
  final WorldCupModel? worldCup;
  final Future<void> Function(ImportedWorldCup imported)? onImported;
  final String Function() _displayNameProvider;

  NearbyTransferPhase phase = NearbyTransferPhase.preparing;
  NearbyAvailability? availability;
  final Map<String, NearbyEndpoint> _endpoints = {};
  NearbyEndpoint? peer;
  String? verificationCode;
  double? progress;
  String message = '준비 중입니다.';
  bool canOpenSettings = false;

  StreamSubscription<NearbyEvent>? _subscription;
  File? _outgoingPackage;
  bool _started = false;
  bool _connectionActionInFlight = false;
  bool _sendStarted = false;
  bool _importStarted = false;
  bool _disposed = false;

  NearbyWorldCupTransferController.sender({
    required this.gateway,
    required this.packageGateway,
    required this.worldCup,
    String Function()? displayNameProvider,
  })  : mode = NearbyTransferMode.send,
        onImported = null,
        _displayNameProvider = displayNameProvider ?? _defaultDisplayName;

  NearbyWorldCupTransferController.receiver({
    required this.gateway,
    required this.packageGateway,
    this.onImported,
    String Function()? displayNameProvider,
  })  : mode = NearbyTransferMode.receive,
        worldCup = null,
        _displayNameProvider = displayNameProvider ?? _defaultDisplayName;

  List<NearbyEndpoint> get endpoints =>
      _endpoints.values.toList(growable: false)
        ..sort((a, b) => a.name.compareTo(b.name));

  bool get busy =>
      _connectionActionInFlight ||
      phase == NearbyTransferPhase.transferring ||
      phase == NearbyTransferPhase.importing;

  bool get finished =>
      phase == NearbyTransferPhase.success ||
      phase == NearbyTransferPhase.canceled;

  bool get needsConnectionDecision =>
      phase == NearbyTransferPhase.connectionRequest ||
      phase == NearbyTransferPhase.verifying;

  Future<void> start() async {
    if (_started || _disposed) return;
    _started = true;
    _subscription = gateway.events.listen(
      _handleEvent,
      onError: (Object error, StackTrace stackTrace) {
        _fail(_messageFor(error));
        unawaited(_deleteOutgoingPackage());
        unawaited(_cleanupNative());
      },
    );
    try {
      availability = await gateway.requestPermissions();
      if (_disposed) return;
      canOpenSettings = availability!.canOpenSettings;
      if (!availability!.ready) {
        _fail(_availabilityMessage(availability!));
        await _cleanupNative();
        return;
      }
      final displayName = _displayNameProvider();
      if (mode == NearbyTransferMode.send) {
        await gateway.startDiscovery(displayName: displayName);
        if (_disposed) return;
        phase = NearbyTransferPhase.discovering;
        message = '받는 기기를 찾고 있습니다.';
      } else {
        await gateway.startAdvertising(displayName: displayName);
        if (_disposed) return;
        phase = NearbyTransferPhase.advertising;
        message = '월드컵을 받을 준비가 되었습니다.';
      }
      _notify();
    } catch (error) {
      _fail(_messageFor(error));
      await _deleteOutgoingPackage();
      await _cleanupNative();
    }
  }

  Future<void> connect(NearbyEndpoint endpoint) async {
    if (_disposed ||
        mode != NearbyTransferMode.send ||
        phase != NearbyTransferPhase.discovering ||
        _connectionActionInFlight) {
      return;
    }
    _connectionActionInFlight = true;
    peer = endpoint;
    phase = NearbyTransferPhase.connecting;
    message = '${endpoint.name}에 연결을 요청하고 있습니다.';
    _notify();
    try {
      await gateway.requestConnection(
        endpointId: endpoint.id,
        displayName: _displayNameProvider(),
      );
    } catch (error) {
      _fail(_messageFor(error));
      await _cleanupNative();
    } finally {
      _connectionActionInFlight = false;
      _notify();
    }
  }

  Future<void> acceptConnection() async {
    final endpoint = peer;
    if (_disposed ||
        endpoint == null ||
        !needsConnectionDecision ||
        _connectionActionInFlight) {
      return;
    }
    _connectionActionInFlight = true;
    final wasVerifying = verificationCode != null;
    phase = NearbyTransferPhase.connecting;
    message = wasVerifying ? '상대 기기의 확인을 기다리고 있습니다.' : '인증 코드를 준비하고 있습니다.';
    _notify();
    try {
      await gateway.acceptConnection(endpoint.id);
    } catch (error) {
      _fail(_messageFor(error));
      await _cleanupNative();
    } finally {
      _connectionActionInFlight = false;
      _notify();
    }
  }

  Future<void> rejectConnection() async {
    final endpoint = peer;
    if (_disposed || endpoint == null || _connectionActionInFlight) return;
    _connectionActionInFlight = true;
    try {
      await gateway.rejectConnection(endpoint.id);
      phase = NearbyTransferPhase.canceled;
      message = '연결 요청을 거절했습니다.';
      await _cleanupNative();
    } catch (error) {
      _fail(_messageFor(error));
      await _cleanupNative();
    } finally {
      _connectionActionInFlight = false;
      _notify();
    }
  }

  Future<void> cancel() async {
    if (_disposed || finished) return;
    phase = NearbyTransferPhase.canceled;
    message = mode == NearbyTransferMode.send ? '전송을 취소했습니다.' : '받기를 취소했습니다.';
    _notify();
    await _deleteOutgoingPackage();
    await _cleanupNative(cancelTransfer: true);
  }

  Future<void> openSettings() => gateway.openAppSettings();

  Future<void> _handleEvent(NearbyEvent event) async {
    if (_disposed) return;
    switch (event) {
      case NearbyEndpointFound(:final endpoint):
        if (mode == NearbyTransferMode.send &&
            phase == NearbyTransferPhase.discovering) {
          _endpoints[endpoint.id] = endpoint;
        }
      case NearbyEndpointLost(:final endpointId):
        _endpoints.remove(endpointId);
      case NearbyConnectionRequest(:final endpoint):
        if (peer != null && peer!.id != endpoint.id) return;
        peer = endpoint;
        verificationCode = null;
        phase = NearbyTransferPhase.connectionRequest;
        message = '${endpoint.name}의 연결 요청입니다.';
      case NearbyVerificationCode(
          :final endpointId,
          :final endpointName,
          :final code,
        ):
        if (peer != null && peer!.id != endpointId) return;
        peer = NearbyEndpoint(id: endpointId, name: endpointName);
        verificationCode = code;
        phase = NearbyTransferPhase.verifying;
        message = '양쪽 기기의 인증 코드가 같은지 확인하세요.';
      case NearbyConnectionChanged(:final endpointId, :final state):
        if (peer != null && peer!.id != endpointId) return;
        switch (state) {
          case NearbyConnectionState.connecting:
            phase = NearbyTransferPhase.connecting;
            message = '안전한 연결을 설정하고 있습니다.';
          case NearbyConnectionState.connected:
            phase = NearbyTransferPhase.connected;
            message = '${peer?.name ?? '상대 기기'}와 연결되었습니다.';
            if (mode == NearbyTransferMode.send) unawaited(_beginSending());
          case NearbyConnectionState.rejected:
            _fail('상대 기기에서 연결을 거절했습니다.');
            unawaited(_deleteOutgoingPackage());
            unawaited(_cleanupNative());
          case NearbyConnectionState.disconnected:
            if (!finished && phase != NearbyTransferPhase.error) {
              _fail('기기 연결이 끊겼습니다. 가까운 거리에서 다시 시도해주세요.');
              unawaited(_deleteOutgoingPackage());
              unawaited(_cleanupNative());
            }
        }
      case NearbyTransferProgress(
          :final direction,
          :final status,
          :final fraction,
        ):
        final expectedDirection = mode == NearbyTransferMode.send
            ? NearbyTransferDirection.sending
            : NearbyTransferDirection.receiving;
        if (direction != expectedDirection) return;
        progress = fraction;
        if (status == NearbyTransferStatus.inProgress) {
          phase = NearbyTransferPhase.transferring;
          message = mode == NearbyTransferMode.send
              ? '월드컵을 보내고 있습니다.'
              : '월드컵을 받고 있습니다.';
        } else if (status == NearbyTransferStatus.success &&
            mode == NearbyTransferMode.send) {
          phase = NearbyTransferPhase.success;
          progress = 1;
          message = '월드컵 전송을 완료했습니다.';
          unawaited(_deleteOutgoingPackage());
          unawaited(_cleanupNative());
        } else if (status == NearbyTransferStatus.canceled) {
          phase = NearbyTransferPhase.canceled;
          message = '파일 전송이 취소되었습니다.';
          unawaited(_deleteOutgoingPackage());
          unawaited(_cleanupNative());
        } else if (status == NearbyTransferStatus.failure) {
          _fail('파일 전송에 실패했습니다. 다시 시도해주세요.');
          unawaited(_deleteOutgoingPackage());
          unawaited(_cleanupNative());
        }
      case NearbyFileReceived(:final path, :final size):
        if (mode == NearbyTransferMode.receive && !_importStarted) {
          unawaited(_importReceivedFile(path, size));
        }
      case NearbyError(:final message):
        _fail(message);
        unawaited(_deleteOutgoingPackage());
        unawaited(_cleanupNative());
    }
    _notify();
  }

  Future<void> _beginSending() async {
    if (_disposed || _sendStarted || peer == null || worldCup == null) return;
    _sendStarted = true;
    phase = NearbyTransferPhase.preparing;
    message = '월드컵 공유 파일을 만들고 있습니다.';
    _notify();
    try {
      final package = await packageGateway.createPackage(worldCup!);
      if (_disposed) {
        if (await package.exists()) await package.delete();
        return;
      }
      _outgoingPackage = package;
      phase = NearbyTransferPhase.transferring;
      progress = 0;
      message = '월드컵을 보내고 있습니다.';
      _notify();
      await gateway.sendFile(
        endpointId: peer!.id,
        path: package.path,
        name: '${worldCup!.title}.${WorldCupPackageService.fileExtension}',
      );
    } catch (error) {
      _fail(_messageFor(error));
      await _deleteOutgoingPackage();
      await _cleanupNative();
    }
  }

  Future<void> _importReceivedFile(String path, int expectedSize) async {
    if (_disposed || _importStarted) return;
    _importStarted = true;
    final file = File(path);
    phase = NearbyTransferPhase.importing;
    message = '받은 월드컵을 자동 등록하고 있습니다.';
    _notify();
    try {
      if (!await file.exists() ||
          !await file.absolute.exists() ||
          await file.length() != expectedSize ||
          expectedSize <= 0) {
        throw const WorldCupPackageException('수신 파일이 완전히 저장되지 않았습니다.');
      }
      final imported = await packageGateway.importPackage(file.path);
      final callback = onImported;
      if (callback != null) await callback(imported);
      if (_disposed) return;
      phase = NearbyTransferPhase.success;
      progress = 1;
      message = '"${imported.title}" 월드컵을 받았습니다.';
    } catch (error) {
      _fail(_messageFor(error, importFailure: true));
    } finally {
      if (await file.exists()) await file.delete();
      await _cleanupNative();
      _notify();
    }
  }

  String _availabilityMessage(NearbyAvailability value) {
    if (!value.supported) {
      return value.message ?? '이 기기에서는 Nearby Connections를 사용할 수 없습니다.';
    }
    if (value.permission == NearbyPermissionState.permanentlyDenied) {
      return '주변 기기 권한이 차단되었습니다. 앱 설정에서 권한을 허용해주세요.';
    }
    if (value.permission == NearbyPermissionState.denied) {
      return '주변 기기 권한이 필요합니다.';
    }
    if (value.bluetooth == NearbyRadioState.disabled ||
        value.wifi == NearbyRadioState.disabled) {
      return 'Bluetooth와 Wi-Fi를 켠 뒤 다시 시도해주세요.';
    }
    return value.message ?? 'Nearby Connections를 시작할 수 없습니다.';
  }

  String _messageFor(Object error, {bool importFailure = false}) {
    if (error is WorldCupPackageException) return error.message;
    if (error is PlatformException && error.message?.isNotEmpty == true) {
      return error.message!;
    }
    return importFailure
        ? '받은 월드컵을 등록하지 못했습니다. 파일을 확인해주세요.'
        : '주변 기기 전송 중 오류가 발생했습니다. 다시 시도해주세요.';
  }

  void _fail(String value) {
    if (_disposed || finished) return;
    phase = NearbyTransferPhase.error;
    message = value;
    _notify();
  }

  Future<void> _cleanupNative({bool cancelTransfer = false}) async {
    final actions = <Future<void> Function()>[
      if (cancelTransfer) gateway.cancelTransfer,
      gateway.stopDiscovery,
      gateway.stopAdvertising,
      gateway.disconnect,
      gateway.dispose,
    ];
    for (final action in actions) {
      try {
        await action();
      } catch (_) {
        // Keep releasing the remaining resources after an individual failure.
      }
    }
  }

  Future<void> _deleteOutgoingPackage() async {
    final package = _outgoingPackage;
    _outgoingPackage = null;
    if (package != null && await package.exists()) await package.delete();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  static String _defaultDisplayName() {
    try {
      final name = Platform.localHostname.trim();
      if (name.isEmpty) return '내 기기';
      return name.length <= 60 ? name : name.substring(0, 60);
    } catch (_) {
      return '내 기기';
    }
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    unawaited(_subscription?.cancel());
    unawaited(_deleteOutgoingPackage());
    unawaited(_cleanupNative(cancelTransfer: true));
    super.dispose();
  }
}
