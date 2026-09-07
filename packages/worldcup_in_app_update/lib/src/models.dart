import 'protocol.dart';

/// Play Core `UpdateAvailability`에 대응한다.
enum InAppUpdateAvailability {
  unknown,
  notAvailable,
  available,

  /// 개발자가 시작한 업데이트가 아직 진행 중이다.
  inProgress,
}

/// Play Core `InstallStatus`에 대응한다.
enum InAppUpdateInstallStatus {
  unknown,
  requiresUiIntent,
  pending,
  downloading,

  /// 내려받기가 끝났고 설치(재시작)만 남았다. 유연한 업데이트의 핵심 상태다.
  downloaded,
  installing,
  installed,
  failed,
  canceled,
}

/// Play가 띄운 동의 화면에서 사용자가 내린 결정.
enum InAppUpdateFlowResult {
  accepted,
  canceled,

  /// 동의 화면을 띄우지 못했거나 Play가 실패를 돌려줬다.
  failed,

  /// 인앱 업데이트를 쓸 수 없는 환경(Play 스토어 밖, iOS 등)이다.
  unavailable,
}

/// 한 번의 업데이트 조회 결과.
class InAppUpdateInfo {
  final InAppUpdateAvailability availability;
  final InAppUpdateInstallStatus installStatus;

  /// 이 기기에서 유연한 업데이트가 허용되는지. Play가 판단한다.
  final bool flexibleAllowed;

  final int? availableVersionCode;

  /// 업데이트가 Play에 올라온 뒤 지난 일수. Play가 모르면 null이다.
  final int? clientVersionStalenessDays;

  /// 개발자가 Play Console에서 지정한 우선순위(0~5).
  final int updatePriority;

  const InAppUpdateInfo({
    required this.availability,
    required this.installStatus,
    required this.flexibleAllowed,
    required this.availableVersionCode,
    required this.clientVersionStalenessDays,
    required this.updatePriority,
  });

  /// 인앱 업데이트를 쓸 수 없는 환경에서 돌려주는 값.
  static const InAppUpdateInfo unsupported = InAppUpdateInfo(
    availability: InAppUpdateAvailability.unknown,
    installStatus: InAppUpdateInstallStatus.unknown,
    flexibleAllowed: false,
    availableVersionCode: null,
    clientVersionStalenessDays: null,
    updatePriority: 0,
  );

  factory InAppUpdateInfo.fromMap(Object? value) {
    final map = _map(value, context: '업데이트 정보');
    _requireVersion(map);
    return InAppUpdateInfo(
      availability: _enumByName(
        InAppUpdateAvailability.values,
        _string(map, 'availability'),
        InAppUpdateAvailability.unknown,
      ),
      installStatus: _enumByName(
        InAppUpdateInstallStatus.values,
        _string(map, 'installStatus'),
        InAppUpdateInstallStatus.unknown,
      ),
      flexibleAllowed: _bool(map, 'flexibleAllowed'),
      availableVersionCode: _optionalInt(map, 'availableVersionCode'),
      clientVersionStalenessDays: _optionalInt(
        map,
        'clientVersionStalenessDays',
      ),
      updatePriority: _optionalInt(map, 'updatePriority') ?? 0,
    );
  }

  /// 지금 유연한 업데이트 흐름을 시작할 수 있는 상태인지.
  bool get canStartFlexibleUpdate =>
      availability == InAppUpdateAvailability.available && flexibleAllowed;

  /// 이미 받아둔 업데이트가 있어 재시작만 하면 되는 상태인지.
  bool get isDownloaded => installStatus == InAppUpdateInstallStatus.downloaded;
}

/// 내려받기/설치 진행 상황. Play의 `InstallState`를 옮긴 값이다.
class InAppUpdateInstallState {
  final InAppUpdateInstallStatus status;
  final int bytesDownloaded;
  final int totalBytesToDownload;

  /// Play Core `InstallErrorCode`. 오류가 없으면 0이다.
  final int errorCode;

  const InAppUpdateInstallState({
    required this.status,
    required this.bytesDownloaded,
    required this.totalBytesToDownload,
    required this.errorCode,
  });

  factory InAppUpdateInstallState.fromMap(Object? value) {
    final map = _map(value, context: '설치 상태');
    _requireVersion(map);
    return InAppUpdateInstallState(
      status: _enumByName(
        InAppUpdateInstallStatus.values,
        _string(map, 'status'),
        InAppUpdateInstallStatus.unknown,
      ),
      bytesDownloaded: _optionalInt(map, 'bytesDownloaded') ?? 0,
      totalBytesToDownload: _optionalInt(map, 'totalBytesToDownload') ?? 0,
      errorCode: _optionalInt(map, 'errorCode') ?? 0,
    );
  }

  /// 0.0~1.0. 전체 크기를 아직 모르면 null이라 불확정 인디케이터를 쓸 수 있다.
  double? get progress {
    if (totalBytesToDownload <= 0) return null;
    final ratio = bytesDownloaded / totalBytesToDownload;
    return ratio.clamp(0.0, 1.0).toDouble();
  }
}

class InAppUpdateProtocolException implements Exception {
  final String message;

  const InAppUpdateProtocolException(this.message);

  @override
  String toString() => message;
}

Map<Object?, Object?> _map(Object? value, {required String context}) {
  if (value is! Map) {
    throw InAppUpdateProtocolException('잘못된 인앱 업데이트 $context 메시지입니다.');
  }
  return value.cast<Object?, Object?>();
}

void _requireVersion(Map<Object?, Object?> map) {
  if (map['version'] != InAppUpdateProtocol.version) {
    throw const InAppUpdateProtocolException('지원하지 않는 인앱 업데이트 프로토콜 버전입니다.');
  }
}

String _string(Map<Object?, Object?> map, String key) {
  final value = map[key];
  if (value is! String || value.isEmpty) {
    throw InAppUpdateProtocolException('인앱 업데이트 메시지의 $key 값이 잘못되었습니다.');
  }
  return value;
}

bool _bool(Map<Object?, Object?> map, String key) {
  final value = map[key];
  if (value is! bool) {
    throw InAppUpdateProtocolException('인앱 업데이트 메시지의 $key 값이 잘못되었습니다.');
  }
  return value;
}

int? _optionalInt(Map<Object?, Object?> map, String key) {
  final value = map[key];
  if (value == null) return null;
  if (value is! num) {
    throw InAppUpdateProtocolException('인앱 업데이트 메시지의 $key 값이 잘못되었습니다.');
  }
  return value.toInt();
}

T _enumByName<T extends Enum>(List<T> values, String name, T fallback) {
  for (final value in values) {
    if (value.name == name) return value;
  }
  return fallback;
}
