import 'package:flutter/services.dart';

import 'models.dart';
import 'protocol.dart';

abstract interface class NearbyTransferGateway {
  Stream<NearbyEvent> get events;

  Future<NearbyAvailability> checkAvailability();

  Future<NearbyAvailability> requestPermissions();

  Future<void> openAppSettings();

  Future<void> startDiscovery({required String displayName});

  Future<void> stopDiscovery();

  Future<void> startAdvertising({required String displayName});

  Future<void> stopAdvertising();

  Future<void> requestConnection({
    required String endpointId,
    required String displayName,
  });

  Future<void> acceptConnection(String endpointId);

  Future<void> rejectConnection(String endpointId);

  Future<void> sendFile({
    required String endpointId,
    required String path,
    required String name,
  });

  Future<void> cancelTransfer();

  Future<void> disconnect();

  Future<void> dispose();
}

class MethodChannelNearbyTransferGateway implements NearbyTransferGateway {
  final MethodChannel _methods;
  final EventChannel _eventChannel;
  Stream<NearbyEvent>? _events;

  MethodChannelNearbyTransferGateway({
    MethodChannel? methods,
    EventChannel? eventChannel,
  })  : _methods = methods ?? const MethodChannel(NearbyProtocol.methodChannel),
        _eventChannel =
            eventChannel ?? const EventChannel(NearbyProtocol.eventChannel);

  @override
  Stream<NearbyEvent> get events =>
      _events ??= _eventChannel.receiveBroadcastStream(<String, Object>{
        'version': NearbyProtocol.version,
        'serviceId': NearbyProtocol.serviceId,
      }).map(NearbyEvent.fromMap);

  Map<String, Object> _arguments([Map<String, Object>? values]) =>
      <String, Object>{
        'version': NearbyProtocol.version,
        'serviceId': NearbyProtocol.serviceId,
        ...?values,
      };

  Future<T?> _invoke<T>(String method, [Map<String, Object>? values]) {
    return _methods.invokeMethod<T>(method, _arguments(values));
  }

  @override
  Future<NearbyAvailability> checkAvailability() async {
    return NearbyAvailability.fromMap(
        await _invoke<Object>('checkAvailability'));
  }

  @override
  Future<NearbyAvailability> requestPermissions() async {
    return NearbyAvailability.fromMap(
        await _invoke<Object>('requestPermissions'));
  }

  @override
  Future<void> openAppSettings() => _invoke<void>('openAppSettings');

  @override
  Future<void> startDiscovery({required String displayName}) =>
      _invoke<void>('startDiscovery', {'displayName': displayName});

  @override
  Future<void> stopDiscovery() => _invoke<void>('stopDiscovery');

  @override
  Future<void> startAdvertising({required String displayName}) =>
      _invoke<void>('startAdvertising', {'displayName': displayName});

  @override
  Future<void> stopAdvertising() => _invoke<void>('stopAdvertising');

  @override
  Future<void> requestConnection({
    required String endpointId,
    required String displayName,
  }) =>
      _invoke<void>('requestConnection', {
        'endpointId': endpointId,
        'displayName': displayName,
      });

  @override
  Future<void> acceptConnection(String endpointId) =>
      _invoke<void>('acceptConnection', {'endpointId': endpointId});

  @override
  Future<void> rejectConnection(String endpointId) =>
      _invoke<void>('rejectConnection', {'endpointId': endpointId});

  @override
  Future<void> sendFile({
    required String endpointId,
    required String path,
    required String name,
  }) =>
      _invoke<void>('sendFile', {
        'endpointId': endpointId,
        'path': path,
        'name': name,
      });

  @override
  Future<void> cancelTransfer() => _invoke<void>('cancelTransfer');

  @override
  Future<void> disconnect() => _invoke<void>('disconnect');

  @override
  Future<void> dispose() => _invoke<void>('dispose');
}
