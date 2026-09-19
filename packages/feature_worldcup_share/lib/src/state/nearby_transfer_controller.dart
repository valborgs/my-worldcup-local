import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:worldcup_nearby_transfer/worldcup_nearby_transfer.dart';
import 'package:worldcup_core/worldcup_core.dart';
import 'package:worldcup_domain/worldcup_domain.dart';

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
  final WorldCupPackagePort packageGateway;
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
  AppMessage message = const AppMessage(AppMessageId.nearbyPreparing);
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
  }) : mode = NearbyTransferMode.send,
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
  }) : mode = NearbyTransferMode.receive,
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
        message = const AppMessage(AppMessageId.nearbyDiscovering);
        _armTimeout(
          _timeouts.discovery,
          const AppMessage(AppMessageId.nearbyDiscoveryTimeout),
        );
      } else {
        await gateway.startAdvertising(displayName: _displayName);
        if (_disposed || finished) {
          await _cleanupNative(cancelTransfer: true);
          return;
        }
        phase = NearbyTransferPhase.advertising;
        message = const AppMessage(AppMessageId.nearbyReady);
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
    message = AppMessage(
      AppMessageId.nearbyRequestingConnection,
      detail: endpoint.name,
    );
    _armTimeout(
      _timeouts.connection,
      const AppMessage(AppMessageId.nearbyConnectionTimeout),
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
    message = const AppMessage(AppMessageId.nearbyWaitingForPeer);
    _armTimeout(
      _timeouts.connection,
      const AppMessage(AppMessageId.nearbyVerificationTimeout),
    );
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
      message = const AppMessage(AppMessageId.nearbyRejectedLocally);
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
    message = mode == NearbyTransferMode.send
        ? const AppMessage(AppMessageId.nearbySendCanceled)
        : const AppMessage(AppMessageId.nearbyReceiveCanceled);
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
            const AppMessage(AppMessageId.nearbyDiscoveryTimeout),
          );
        }
      case NearbyConnectionRequest(:final endpoint, :final incoming):
        if (incoming != (mode == NearbyTransferMode.receive)) return;
        if (peer != null && peer!.id != endpoint.id) return;
        peer = endpoint;
        verificationCode = null;
        phase = NearbyTransferPhase.connecting;
        message = AppMessage(
          AppMessageId.nearbyPreparingCode,
          detail: endpoint.name,
        );
        _armTimeout(
          _timeouts.connection,
          const AppMessage(AppMessageId.nearbyVerificationTimeout),
        );
      case NearbyVerificationCode(
        :final endpointId,
        :final endpointName,
        :final code,
      ):
        if (peer != null && peer!.id != endpointId) return;
        peer = NearbyEndpoint(id: endpointId, name: endpointName);
        verificationCode = code;
        phase = NearbyTransferPhase.verifying;
        message = const AppMessage(AppMessageId.nearbyVerifyCode);
        _armTimeout(
          _timeouts.connection,
          const AppMessage(AppMessageId.nearbyVerificationTimeout),
        );
      case NearbyConnectionChanged(:final endpointId, :final state):
        if (peer != null && peer!.id != endpointId) return;
        switch (state) {
          case NearbyConnectionState.connecting:
            phase = NearbyTransferPhase.connecting;
            message = const AppMessage(AppMessageId.nearbySecuringConnection);
            _armTimeout(
              _timeouts.connection,
              const AppMessage(AppMessageId.nearbyConnectionTimeout),
            );
          case NearbyConnectionState.connected:
            phase = NearbyTransferPhase.connected;
            message = AppMessage(
              AppMessageId.nearbyConnected,
              detail: peer?.name,
            );
            if (mode == NearbyTransferMode.send) {
              unawaited(_beginSending());
            } else {
              _armTimeout(
                _timeouts.transferIdle,
                const AppMessage(AppMessageId.nearbyReceiveTimeout),
              );
            }
          case NearbyConnectionState.rejected:
            _fail(const AppMessage(AppMessageId.nearbyRejectedByPeer));
            unawaited(_deleteOutgoingPackage());
            unawaited(_cleanupNative());
          case NearbyConnectionState.disconnected:
            final canFinishReceivedFile =
                mode == NearbyTransferMode.receive &&
                (_receivingPayloadStarted ||
                    _receivedPayloadComplete ||
                    phase == NearbyTransferPhase.importing);
            if (canFinishReceivedFile) {
              if (phase != NearbyTransferPhase.importing) {
                message = const AppMessage(
                  AppMessageId.nearbyFinalizingDisconnected,
                );
                _armTimeout(
                  _timeouts.finalization,
                  const AppMessage(AppMessageId.nearbyFinalizationTimeout),
                );
              }
            } else {
              _fail(const AppMessage(AppMessageId.nearbyDisconnected));
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
              ? const AppMessage(AppMessageId.nearbySending)
              : const AppMessage(AppMessageId.nearbyReceiving);
          _armTimeout(
            _timeouts.transferIdle,
            mode == NearbyTransferMode.send
                ? const AppMessage(AppMessageId.nearbySendTimeout)
                : const AppMessage(AppMessageId.nearbyReceiveTimeout),
          );
        } else if (status == NearbyTransferStatus.success &&
            mode == NearbyTransferMode.send) {
          _cancelTimeout();
          phase = NearbyTransferPhase.success;
          progress = 1;
          message = const AppMessage(AppMessageId.nearbySendSuccess);
          unawaited(_deleteOutgoingPackage());
          unawaited(_cleanupNative());
        } else if (status == NearbyTransferStatus.success) {
          _receivingPayloadStarted = true;
          _receivedPayloadComplete = true;
          phase = NearbyTransferPhase.transferring;
          progress = 1;
          message = const AppMessage(AppMessageId.nearbyCheckingFile);
          _armTimeout(
            _timeouts.finalization,
            const AppMessage(AppMessageId.nearbyFinalizationTimeout),
          );
        } else if (status == NearbyTransferStatus.canceled) {
          _cancelTimeout();
          phase = NearbyTransferPhase.canceled;
          message = const AppMessage(AppMessageId.nearbyTransferCanceled);
          unawaited(_deleteOutgoingPackage());
          unawaited(_cleanupNative());
        } else if (status == NearbyTransferStatus.failure) {
          _fail(const AppMessage(AppMessageId.nearbyTransferFailed));
          unawaited(_deleteOutgoingPackage());
          unawaited(_cleanupNative());
        }
      case NearbyFileReceived(:final path, :final size):
        if (mode == NearbyTransferMode.receive && !_importStarted) {
          _cancelTimeout();
          unawaited(_importReceivedFile(path, size));
        }
      case NearbyError(:final code):
        if (phase == NearbyTransferPhase.importing) return;
        _fail(_nativeErrorMessage(code.name));
        unawaited(_deleteOutgoingPackage());
        unawaited(_cleanupNative());
    }
    _notify();
  }

  Future<void> _beginSending() async {
    if (_disposed || _sendStarted || peer == null || worldCup == null) return;
    _sendStarted = true;
    phase = NearbyTransferPhase.preparing;
    message = const AppMessage(AppMessageId.nearbyCreatingFile);
    _armTimeout(
      _timeouts.preparation,
      const AppMessage(AppMessageId.nearbyPreparationTimeout),
    );
    _notify();
    try {
      final package = File(await packageGateway.createPackage(worldCup!));
      if (_disposed || finished) {
        if (await package.exists()) await package.delete();
        return;
      }
      _outgoingPackage = package;
      phase = NearbyTransferPhase.transferring;
      progress = 0;
      message = const AppMessage(AppMessageId.nearbySending);
      _armTimeout(
        _timeouts.transferIdle,
        const AppMessage(AppMessageId.nearbySendTimeout),
      );
      _notify();
      await gateway.sendFile(
        endpointId: peer!.id,
        path: package.path,
        name: '${worldCup!.title}.${WorldCupPackageFormat.fileExtension}',
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
    message = const AppMessage(AppMessageId.nearbyImporting);
    _cancelTimeout();
    _notify();
    try {
      if (!await sourceFile.exists() ||
          !await sourceFile.absolute.exists() ||
          await sourceFile.length() != expectedSize ||
          expectedSize <= 0) {
        throw const PackageFailure(
          '수신 파일이 완전히 저장되지 않았습니다.',
          userMessage: AppMessage(AppMessageId.packageIncomplete),
        );
      }
      importFile = await _takeOwnershipOfReceivedFile(sourceFile);
      if (_disposed) return;
      final imported = await packageGateway.importPackage(importFile.path);
      final callback = onImported;
      if (callback != null) await callback(imported);
      if (_disposed) return;
      phase = NearbyTransferPhase.success;
      progress = 1;
      message = AppMessage(
        AppMessageId.nearbyReceiveSuccess,
        detail: imported.title,
      );
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

  AppMessage _availabilityMessage(NearbyAvailability value) {
    if (!value.supported) {
      return const AppMessage(AppMessageId.nearbyUnsupported);
    }
    if (value.permission == NearbyPermissionState.permanentlyDenied) {
      return const AppMessage(AppMessageId.nearbyPermissionBlocked);
    }
    if (value.permission == NearbyPermissionState.denied) {
      return const AppMessage(AppMessageId.nearbyPermissionRequired);
    }
    if (value.bluetooth == NearbyRadioState.disabled ||
        value.wifi == NearbyRadioState.disabled) {
      return const AppMessage(AppMessageId.nearbyRadiosDisabled);
    }
    return const AppMessage(AppMessageId.nearbyStartFailed);
  }

  AppMessage _messageFor(Object error, {bool importFailure = false}) {
    if (error is Failure) return error.userMessage;
    if (error is PlatformException) return _nativeErrorMessage(error.code);
    return importFailure
        ? const AppMessage(AppMessageId.nearbyImportFailed)
        : const AppMessage(AppMessageId.nearbyError);
  }

  AppMessage _nativeErrorMessage(String code) => AppMessage(switch (code) {
    'denied' || 'permissionDenied' => AppMessageId.nearbyPermissionRequired,
    'permanentlyDenied' ||
    'permissionPermanentlyDenied' => AppMessageId.nearbyPermissionBlocked,
    'alreadyBusy' => AppMessageId.nearbyAlreadyBusy,
    'invalidState' => AppMessageId.nearbyInvalidState,
    'connectionFailed' => AppMessageId.nearbyConnectionFailed,
    'radioOff' => AppMessageId.nearbyRadiosDisabled,
    'unavailable' => AppMessageId.nearbyStartFailed,
    'transferFailed' || 'io' => AppMessageId.nearbyTransferFailed,
    'canceled' => AppMessageId.nearbyTransferCanceled,
    _ => AppMessageId.nearbyError,
  });

  void _fail(AppMessage value) {
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
        '${DateTime.now().microsecondsSinceEpoch}_${math.Random.secure().nextInt(1 << 32)}.${WorldCupPackageFormat.fileExtension}',
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

  void _armTimeout(Duration duration, AppMessage timeoutMessage) {
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

  // Stable for this process. The UI supplies the localized name when starting
  // a session; injected/headless callers can provide any transport identity.
  static final int displayNameSuffix =
      1000 + math.Random.secure().nextInt(9000);

  static String _defaultDisplayName() => 'World Cup $displayNameSuffix';

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
