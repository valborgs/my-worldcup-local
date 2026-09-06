import 'protocol.dart';

enum NearbyPermissionState { granted, denied, permanentlyDenied, unknown }

enum NearbyRadioState { enabled, disabled, unavailable, unknown }

enum NearbyConnectionState { connecting, connected, rejected, disconnected }

enum NearbyTransferDirection { sending, receiving }

enum NearbyTransferStatus { inProgress, success, canceled, failure }

enum NearbyErrorCode {
  permissionDenied,
  permissionPermanentlyDenied,
  unavailable,
  radioOff,
  alreadyBusy,
  invalidState,
  connectionFailed,
  transferFailed,
  io,
  protocol,
  canceled,
  unknown,
}

class NearbyAvailability {
  final bool supported;
  final NearbyPermissionState permission;
  final NearbyRadioState bluetooth;
  final NearbyRadioState wifi;
  final bool canOpenSettings;
  final String? message;

  const NearbyAvailability({
    required this.supported,
    required this.permission,
    required this.bluetooth,
    required this.wifi,
    required this.canOpenSettings,
    this.message,
  });

  factory NearbyAvailability.fromMap(Object? value) {
    final map = _map(value, context: 'availability');
    _requireVersion(map);
    return NearbyAvailability(
      supported: _bool(map, 'supported'),
      permission: _enumByName(
        NearbyPermissionState.values,
        _string(map, 'permission'),
        NearbyPermissionState.unknown,
      ),
      bluetooth: _enumByName(
        NearbyRadioState.values,
        _string(map, 'bluetooth'),
        NearbyRadioState.unknown,
      ),
      wifi: _enumByName(
        NearbyRadioState.values,
        _string(map, 'wifi'),
        NearbyRadioState.unknown,
      ),
      canOpenSettings: _bool(map, 'canOpenSettings'),
      message: map['message'] as String?,
    );
  }

  bool get ready =>
      supported &&
      permission != NearbyPermissionState.denied &&
      permission != NearbyPermissionState.permanentlyDenied &&
      bluetooth != NearbyRadioState.disabled &&
      bluetooth != NearbyRadioState.unavailable &&
      wifi != NearbyRadioState.disabled &&
      wifi != NearbyRadioState.unavailable;
}

class NearbyEndpoint {
  final String id;
  final String name;

  const NearbyEndpoint({required this.id, required this.name});

  @override
  bool operator ==(Object other) =>
      other is NearbyEndpoint && other.id == id && other.name == name;

  @override
  int get hashCode => Object.hash(id, name);
}

sealed class NearbyEvent {
  final int protocolVersion;

  const NearbyEvent() : protocolVersion = NearbyProtocol.version;

  factory NearbyEvent.fromMap(Object? value) {
    final map = _map(value, context: 'event');
    _requireVersion(map);
    switch (_string(map, 'type')) {
      case 'endpointFound':
        return NearbyEndpointFound(
          NearbyEndpoint(
            id: _string(map, 'endpointId'),
            name: _string(map, 'endpointName'),
          ),
        );
      case 'endpointLost':
        return NearbyEndpointLost(_string(map, 'endpointId'));
      case 'connectionRequest':
        return NearbyConnectionRequest(
          endpoint: NearbyEndpoint(
            id: _string(map, 'endpointId'),
            name: _string(map, 'endpointName'),
          ),
          incoming: _bool(map, 'incoming'),
        );
      case 'verificationCode':
        return NearbyVerificationCode(
          endpointId: _string(map, 'endpointId'),
          endpointName: _string(map, 'endpointName'),
          code: _string(map, 'code'),
        );
      case 'connectionState':
        return NearbyConnectionChanged(
          endpointId: _string(map, 'endpointId'),
          state: _requiredEnum(
            NearbyConnectionState.values,
            _string(map, 'state'),
            'connection state',
          ),
        );
      case 'transferProgress':
        return NearbyTransferProgress(
          endpointId: _string(map, 'endpointId'),
          payloadId: _string(map, 'payloadId'),
          direction: _requiredEnum(
            NearbyTransferDirection.values,
            _string(map, 'direction'),
            'transfer direction',
          ),
          status: _requiredEnum(
            NearbyTransferStatus.values,
            _string(map, 'status'),
            'transfer status',
          ),
          bytesTransferred: _int(map, 'bytesTransferred'),
          totalBytes: _int(map, 'totalBytes'),
        );
      case 'fileReceived':
        return NearbyFileReceived(
          endpointId: _string(map, 'endpointId'),
          payloadId: _string(map, 'payloadId'),
          path: _string(map, 'path'),
          name: _string(map, 'name'),
          size: _int(map, 'size'),
        );
      case 'error':
        return NearbyError(
          code: _enumByName(
            NearbyErrorCode.values,
            _string(map, 'code'),
            NearbyErrorCode.unknown,
          ),
          message: _string(map, 'message'),
          recoverable: _bool(map, 'recoverable'),
        );
      default:
        throw const NearbyProtocolException('알 수 없는 Nearby 이벤트입니다.');
    }
  }
}

final class NearbyEndpointFound extends NearbyEvent {
  final NearbyEndpoint endpoint;

  const NearbyEndpointFound(this.endpoint);
}

final class NearbyEndpointLost extends NearbyEvent {
  final String endpointId;

  const NearbyEndpointLost(this.endpointId);
}

final class NearbyConnectionRequest extends NearbyEvent {
  final NearbyEndpoint endpoint;
  final bool incoming;

  const NearbyConnectionRequest({
    required this.endpoint,
    required this.incoming,
  });
}

final class NearbyVerificationCode extends NearbyEvent {
  final String endpointId;
  final String endpointName;
  final String code;

  const NearbyVerificationCode({
    required this.endpointId,
    required this.endpointName,
    required this.code,
  });
}

final class NearbyConnectionChanged extends NearbyEvent {
  final String endpointId;
  final NearbyConnectionState state;

  const NearbyConnectionChanged({
    required this.endpointId,
    required this.state,
  });
}

final class NearbyTransferProgress extends NearbyEvent {
  final String endpointId;
  final String payloadId;
  final NearbyTransferDirection direction;
  final NearbyTransferStatus status;
  final int bytesTransferred;
  final int totalBytes;

  const NearbyTransferProgress({
    required this.endpointId,
    required this.payloadId,
    required this.direction,
    required this.status,
    required this.bytesTransferred,
    required this.totalBytes,
  });

  double? get fraction =>
      totalBytes <= 0 ? null : (bytesTransferred / totalBytes).clamp(0.0, 1.0);
}

final class NearbyFileReceived extends NearbyEvent {
  final String endpointId;
  final String payloadId;
  final String path;
  final String name;
  final int size;

  const NearbyFileReceived({
    required this.endpointId,
    required this.payloadId,
    required this.path,
    required this.name,
    required this.size,
  });
}

final class NearbyError extends NearbyEvent {
  final NearbyErrorCode code;
  final String message;
  final bool recoverable;

  const NearbyError({
    required this.code,
    required this.message,
    required this.recoverable,
  });
}

class NearbyProtocolException implements Exception {
  final String message;

  const NearbyProtocolException(this.message);

  @override
  String toString() => message;
}

Map<Object?, Object?> _map(Object? value, {required String context}) {
  if (value is! Map) {
    throw NearbyProtocolException('잘못된 Nearby $context 메시지입니다.');
  }
  return value.cast<Object?, Object?>();
}

void _requireVersion(Map<Object?, Object?> map) {
  if (map['version'] != NearbyProtocol.version) {
    throw const NearbyProtocolException('지원하지 않는 Nearby 프로토콜 버전입니다.');
  }
}

String _string(Map<Object?, Object?> map, String key) {
  final value = map[key];
  if (value is! String || value.isEmpty) {
    throw NearbyProtocolException('Nearby 메시지의 $key 값이 잘못되었습니다.');
  }
  return value;
}

bool _bool(Map<Object?, Object?> map, String key) {
  final value = map[key];
  if (value is! bool) {
    throw NearbyProtocolException('Nearby 메시지의 $key 값이 잘못되었습니다.');
  }
  return value;
}

int _int(Map<Object?, Object?> map, String key) {
  final value = map[key];
  if (value is! num) {
    throw NearbyProtocolException('Nearby 메시지의 $key 값이 잘못되었습니다.');
  }
  return value.toInt();
}

T _enumByName<T extends Enum>(List<T> values, String name, T fallback) {
  return values.where((value) => value.name == name).firstOrNull ?? fallback;
}

T _requiredEnum<T extends Enum>(List<T> values, String name, String context) {
  for (final value in values) {
    if (value.name == name) return value;
  }
  throw NearbyProtocolException('알 수 없는 $context 값입니다.');
}

extension<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    return iterator.moveNext() ? iterator.current : null;
  }
}
