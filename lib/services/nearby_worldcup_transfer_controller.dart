import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:worldcup_nearby_transfer/worldcup_nearby_transfer.dart';

import '../models/worldcup_model.dart';
import 'worldcup_package_service.dart';

enum NearbyTransferMode { send, receive }

enum NearbyTransferPhase {
  preparing,
  discovering,
  advertising,
  verifying,
  connecting,
  connected,
  transferring,
  importing,
  success,
  canceled,
  error,
}

class NearbyTransferTimeouts {
  final Duration discovery;
  final Duration connection;
  final Duration preparation;
  final Duration transferIdle;
  final Duration finalization;

  const NearbyTransferTimeouts({
    this.discovery = const Duration(seconds: 90),
    this.connection = const Duration(seconds: 45),
    this.preparation = const Duration(minutes: 2),
    this.transferIdle = const Duration(seconds: 60),
    this.finalization = const Duration(seconds: 60),
  });
}

class NearbyWorldCupTransferController extends ChangeNotifier {
  final NearbyTransferMode mode;
  final NearbyTransferGateway gateway;
  final WorldCupPackageGateway packageGateway;
  final WorldCupModel? worldCup;
  final Future<void> Function(ImportedWorldCup imported)? onImported;
  final NearbyTransferTimeouts _timeouts;
  final Future<Directory> Function() _temporaryDirectoryProvider;
  final String _displayName;

  NearbyTransferPhase phase = NearbyTransferPhase.preparing;
  NearbyAvailability? availability;
  final Map<String, NearbyEndpoint> _endpoints = {};
  NearbyEndpoint? peer;
  String? verificationCode;
  double? progress;
  String message = '준비 중입니다.';
  bool canOpenSettings = false;

  StreamSubscription<NearbyEvent>? _subscription;
  Timer? _timeoutTimer;
  File? _outgoingPackage;
  bool _started = false;
  bool _connectionActionInFlight = false;
  bool _sendStarted = false;
  bool _importStarted = false;
  bool _receivingPayloadStarted = false;
  bool _receivedPayloadComplete = false;
  bool _disposed = false;

  NearbyWorldCupTransferController.sender({
    required this.gateway,
    required this.packageGateway,
    required this.worldCup,
    String Function()? displayNameProvider,
    Future<Directory> Function()? temporaryDirectoryProvider,
    this._timeouts = const NearbyTransferTimeouts(),
  })  : mode = NearbyTransferMode.send,
        onImported = null,
        _temporaryDirectoryProvider =
            temporaryDirectoryProvider ?? getTemporaryDirectory,
        _displayName = (displayNameProvider ?? _defaultDisplayName)();

  NearbyWorldCupTransferController.receiver({
    required this.gateway,
    required this.packageGateway,
    this.onImported,
    String Function()? displayNameProvider,
    Future<Directory> Function()? temporaryDirectoryProvider,
    this._timeouts = const NearbyTransferTimeouts(),
  })  : mode = NearbyTransferMode.receive,
        worldCup = null,
        _temporaryDirectoryProvider =
            temporaryDirectoryProvider ?? getTemporaryDirectory,
        _displayName = (displayNameProvider ?? _defaultDisplayName)();

  List<NearbyEndpoint> get endpoints =>
      _endpoints.values.toList(growable: false)
        ..sort((a, b) => a.name.compareTo(b.name));

  String get displayName => _displayName;

  bool get busy =>
      _connectionActionInFlight ||
      phase == NearbyTransferPhase.transferring ||
      phase == NearbyTransferPhase.importing;

  bool get finished =>
      phase == NearbyTransferPhase.success ||
      phase == NearbyTransferPhase.canceled ||
      phase == NearbyTransferPhase.error;

  bool get needsConnectionDecision =>
      phase == NearbyTransferPhase.verifying && verificationCode != null;

  Future<void> start() async {
    if (_started || _disposed) return;
    _started = true;
    _subscription = gateway.events.listen(
      _handleEvent,
      onError: (Object error, StackTrace stackTrace) {
        if (finished) return;
        _fail(_messageFor(error));
        unawaited(_deleteOutgoingPackage());
        unawaited(_cleanupNative());
      },
    );
    try {
      availability = await gateway.requestPermissions();
      if (_disposed || finished) return;
      canOpenSettings = availability!.canOpenSettings;
      if (!availability!.ready) {
        _fail(_availabilityMessage(availability!));
        await _cleanupNative();
        return;
      }
      if (mode == NearbyTransferMode.send) {
        await gateway.startDiscovery(displayName: _displayName);
        if (_disposed || finished) {
          await _cleanupNative(cancelTransfer: true);
          return;
        }
        phase = NearbyTransferPhase.discovering;
        message = '받는 기기를 찾고 있습니다.';
        _armTimeout(
          _timeouts.discovery,
          '주변 기기를 찾지 못했습니다. 받는 기기에서 월드컵 받기를 열고 다시 시도해주세요.',
        );
      } else {
        await gateway.startAdvertising(displayName: _displayName);
        if (_disposed || finished) {
          await _cleanupNative(cancelTransfer: true);
          return;
        }
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
    _cancelTimeout();
    peer = endpoint;
    phase = NearbyTransferPhase.connecting;
    message = '${endpoint.name}에 연결을 요청하고 있습니다.';
    _armTimeout(
      _timeouts.connection,
      '기기 연결 시간이 초과되었습니다. 다시 시도해주세요.',
    );
    _notify();
    try {
      await gateway.requestConnection(
        endpointId: endpoint.id,
        displayName: _displayName,
      );
      if (finished) await _cleanupNative(cancelTransfer: true);
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
    phase = NearbyTransferPhase.connecting;
    message = '상대 기기의 확인을 기다리고 있습니다.';
    _armTimeout(_timeouts.connection, '연결 확인 시간이 초과되었습니다. 다시 시도해주세요.');
    _notify();
    try {
      await gateway.acceptConnection(endpoint.id);
      if (finished) await _cleanupNative(cancelTransfer: true);
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
      _cancelTimeout();
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
    if (_disposed ||
        finished ||
        phase == NearbyTransferPhase.importing ||
        _receivedPayloadComplete) {
      return;
    }
    _cancelTimeout();
    phase = NearbyTransferPhase.canceled;
    message = mode == NearbyTransferMode.send ? '전송을 취소했습니다.' : '받기를 취소했습니다.';
    _notify();
    await _deleteOutgoingPackage();
    await _cleanupNative(cancelTransfer: true);
  }

  Future<void> openSettings() => gateway.openAppSettings();

  Future<void> _handleEvent(NearbyEvent event) async {
    if (_disposed || finished) return;
    switch (event) {
      case NearbyEndpointFound(:final endpoint):
        if (mode == NearbyTransferMode.send &&
            phase == NearbyTransferPhase.discovering) {
          _endpoints[endpoint.id] = endpoint;
          _cancelTimeout();
        }
      case NearbyEndpointLost(:final endpointId):
        _endpoints.remove(endpointId);
        if (mode == NearbyTransferMode.send &&
            phase == NearbyTransferPhase.discovering &&
            _endpoints.isEmpty) {
          _armTimeout(
            _timeouts.discovery,
            '주변 기기를 찾지 못했습니다. 받는 기기에서 월드컵 받기를 열고 다시 시도해주세요.',
          );
        }
      case NearbyConnectionRequest(:final endpoint, :final incoming):
        if (incoming != (mode == NearbyTransferMode.receive)) return;
        if (peer != null && peer!.id != endpoint.id) return;
        peer = endpoint;
        verificationCode = null;
        phase = NearbyTransferPhase.connecting;
        message = '${endpoint.name}의 인증 코드를 준비하고 있습니다.';
        _armTimeout(_timeouts.connection, '연결 확인 시간이 초과되었습니다. 다시 시도해주세요.');
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
        _armTimeout(_timeouts.connection, '연결 확인 시간이 초과되었습니다. 다시 시도해주세요.');
      case NearbyConnectionChanged(:final endpointId, :final state):
        if (peer != null && peer!.id != endpointId) return;
        switch (state) {
          case NearbyConnectionState.connecting:
            phase = NearbyTransferPhase.connecting;
            message = '안전한 연결을 설정하고 있습니다.';
            _armTimeout(
              _timeouts.connection,
              '기기 연결 시간이 초과되었습니다. 다시 시도해주세요.',
            );
          case NearbyConnectionState.connected:
            phase = NearbyTransferPhase.connected;
            message = '${peer?.name ?? '상대 기기'}와 연결되었습니다.';
            if (mode == NearbyTransferMode.send) {
              unawaited(_beginSending());
            } else {
              _armTimeout(
                _timeouts.transferIdle,
                '파일 수신 시간이 초과되었습니다. 다시 시도해주세요.',
              );
            }
          case NearbyConnectionState.rejected:
            _fail('상대 기기에서 연결을 거절했습니다.');
            unawaited(_deleteOutgoingPackage());
            unawaited(_cleanupNative());
          case NearbyConnectionState.disconnected:
            final canFinishReceivedFile = mode == NearbyTransferMode.receive &&
                (_receivingPayloadStarted ||
                    _receivedPayloadComplete ||
                    phase == NearbyTransferPhase.importing);
            if (canFinishReceivedFile) {
              if (phase != NearbyTransferPhase.importing) {
                message = '연결이 종료되어 받은 파일을 확인하고 있습니다.';
                _armTimeout(
                  _timeouts.finalization,
                  '수신 파일 확인 시간이 초과되었습니다. 다시 시도해주세요.',
                );
              }
            } else {
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
          if (mode == NearbyTransferMode.receive) {
            _receivingPayloadStarted = true;
          }
          phase = NearbyTransferPhase.transferring;
          message = mode == NearbyTransferMode.send
              ? '월드컵을 보내고 있습니다.'
              : '월드컵을 받고 있습니다.';
          _armTimeout(
            _timeouts.transferIdle,
            mode == NearbyTransferMode.send
                ? '파일 전송 시간이 초과되었습니다. 다시 시도해주세요.'
                : '파일 수신 시간이 초과되었습니다. 다시 시도해주세요.',
          );
        } else if (status == NearbyTransferStatus.success &&
            mode == NearbyTransferMode.send) {
          _cancelTimeout();
          phase = NearbyTransferPhase.success;
          progress = 1;
          message = '월드컵 전송을 완료했습니다.';
          unawaited(_deleteOutgoingPackage());
          unawaited(_cleanupNative());
        } else if (status == NearbyTransferStatus.success) {
          _receivingPayloadStarted = true;
          _receivedPayloadComplete = true;
          phase = NearbyTransferPhase.transferring;
          progress = 1;
          message = '수신 파일을 확인하고 있습니다.';
          _armTimeout(
            _timeouts.finalization,
            '수신 파일 확인 시간이 초과되었습니다. 다시 시도해주세요.',
          );
        } else if (status == NearbyTransferStatus.canceled) {
          _cancelTimeout();
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
          _cancelTimeout();
          unawaited(_importReceivedFile(path, size));
        }
      case NearbyError(:final message):
        if (phase == NearbyTransferPhase.importing) return;
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
    _armTimeout(_timeouts.preparation, '공유 파일 준비 시간이 초과되었습니다. 다시 시도해주세요.');
    _notify();
    try {
      final package = await packageGateway.createPackage(worldCup!);
      if (_disposed || finished) {
        if (await package.exists()) await package.delete();
        return;
      }
      _outgoingPackage = package;
      phase = NearbyTransferPhase.transferring;
      progress = 0;
      message = '월드컵을 보내고 있습니다.';
      _armTimeout(_timeouts.transferIdle, '파일 전송 시간이 초과되었습니다. 다시 시도해주세요.');
      _notify();
      await gateway.sendFile(
        endpointId: peer!.id,
        path: package.path,
        name: '${worldCup!.title}.${WorldCupPackageService.fileExtension}',
      );
      if (finished) await _cleanupNative(cancelTransfer: true);
    } catch (error) {
      _fail(_messageFor(error));
      await _deleteOutgoingPackage();
      await _cleanupNative();
    }
  }

  Future<void> _importReceivedFile(String path, int expectedSize) async {
    if (_disposed || _importStarted) return;
    _importStarted = true;
    final sourceFile = File(path);
    var importFile = sourceFile;
    phase = NearbyTransferPhase.importing;
    message = '받은 월드컵을 자동 등록하고 있습니다.';
    _cancelTimeout();
    _notify();
    try {
      if (!await sourceFile.exists() ||
          !await sourceFile.absolute.exists() ||
          await sourceFile.length() != expectedSize ||
          expectedSize <= 0) {
        throw const WorldCupPackageException('수신 파일이 완전히 저장되지 않았습니다.');
      }
      importFile = await _takeOwnershipOfReceivedFile(sourceFile);
      if (_disposed) return;
      final imported = await packageGateway.importPackage(importFile.path);
      final callback = onImported;
      if (callback != null) await callback(imported);
      if (_disposed) return;
      phase = NearbyTransferPhase.success;
      progress = 1;
      message = '"${imported.title}" 월드컵을 받았습니다.';
    } catch (error) {
      _fail(_messageFor(error, importFailure: true));
    } finally {
      if (await importFile.exists()) await importFile.delete();
      if (importFile.path != sourceFile.path && await sourceFile.exists()) {
        await sourceFile.delete();
      }
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
        ? '받은 월드컵을 등록하지 못했습니다. 보내는 기기에서 다시 보내주세요.'
        : '주변 기기 전송 중 오류가 발생했습니다. 다시 시도해주세요.';
  }

  void _fail(String value) {
    if (_disposed || finished) return;
    _cancelTimeout();
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

  Future<File> _takeOwnershipOfReceivedFile(File source) async {
    final temporaryDirectory = await _temporaryDirectoryProvider();
    final importDirectory = Directory(
      path.join(temporaryDirectory.path, 'worldcup_pending_imports'),
    );
    await importDirectory.create(recursive: true);
    final destination = File(
      path.join(
        importDirectory.path,
        '${DateTime.now().microsecondsSinceEpoch}_${math.Random.secure().nextInt(1 << 32)}.${WorldCupPackageService.fileExtension}',
      ),
    );
    try {
      return await source.rename(destination.path);
    } on FileSystemException {
      try {
        await source.copy(destination.path);
        await source.delete();
        return destination;
      } catch (_) {
        if (await destination.exists()) await destination.delete();
        rethrow;
      }
    }
  }

  void _armTimeout(Duration duration, String timeoutMessage) {
    _timeoutTimer?.cancel();
    _timeoutTimer = Timer(duration, () {
      if (_disposed || finished || phase == NearbyTransferPhase.importing) {
        return;
      }
      _fail(timeoutMessage);
      unawaited(_deleteOutgoingPackage());
      unawaited(_cleanupNative(cancelTransfer: true));
    });
  }

  void _cancelTimeout() {
    _timeoutTimer?.cancel();
    _timeoutTimer = null;
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  static final String _anonymousDisplayName = _createAnonymousDisplayName();

  static String _defaultDisplayName() => _anonymousDisplayName;

  static String _createAnonymousDisplayName() {
    final suffix = 1000 + math.Random.secure().nextInt(9000);
    return '월드컵 기기 $suffix';
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _cancelTimeout();
    unawaited(_subscription?.cancel());
    unawaited(_deleteOutgoingPackage());
    unawaited(_cleanupNative(cancelTransfer: true));
    super.dispose();
  }
}
