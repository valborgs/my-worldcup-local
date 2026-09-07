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

  /// 이 기기에서 즉시(강제) 업데이트가 허용되는지. Play가 판단한다.
  final bool immediateAllowed;

  final int? availableVersionCode;

  /// 지금 기기에 깔려 있는 앱의 versionCode.
  ///
  /// Play가 주는 값이 아니라 PackageManager에서 읽어 같은 응답에 실어 보낸다.
  /// "지금 버전이 최소 요구 버전에 못 미치는가"를 판단하려면 이 값이
  /// 필요한데, 그것만을 위해 왕복을 한 번 더 하거나 패키지를 하나 더 넣을
  /// 이유가 없다.
  final int? installedVersionCode;

  /// 업데이트가 Play에 올라온 뒤 지난 일수. Play가 모르면 null이다.
  final int? clientVersionStalenessDays;

  /// 개발자가 Play Console에서 지정한 우선순위(0~5).
  final int updatePriority;

  const InAppUpdateInfo({
    required this.availability,
    required this.installStatus,
    required this.flexibleAllowed,
    required this.immediateAllowed,
    required this.availableVersionCode,
    required this.installedVersionCode,
    required this.clientVersionStalenessDays,
    required this.updatePriority,
  });

  /// 인앱 업데이트를 쓸 수 없는 환경에서 돌려주는 값.
  static const InAppUpdateInfo unsupported = InAppUpdateInfo(
    availability: InAppUpdateAvailability.unknown,
    installStatus: InAppUpdateInstallStatus.unknown,
    flexibleAllowed: false,
    immediateAllowed: false,
    availableVersionCode: null,
    installedVersionCode: null,
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
      immediateAllowed: _bool(map, 'immediateAllowed'),
      availableVersionCode: _optionalInt(map, 'availableVersionCode'),
      installedVersionCode: _optionalInt(map, 'installedVersionCode'),
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

  /// 지금 즉시(강제) 업데이트 흐름을 띄울 수 있는 상태인지.
  ///
  /// 시작해 둔 즉시 업데이트가 멈춘 채로 남은 경우도 포함한다. 안드로이드
  /// 가이드가 앱 복귀 시 그 상태를 다시 띄우라고 안내하는 경우다.
  bool get canStartImmediateUpdate =>
      (availability == InAppUpdateAvailability.available && immediateAllowed) ||
      availability == InAppUpdateAvailability.inProgress;

  /// 이미 받아둔 업데이트가 있어 재시작만 하면 되는 상태인지.
  bool get isDownloaded => installStatus == InAppUpdateInstallStatus.downloaded;

  /// 깔려 있는 버전이 [minRequiredVersionCode]에 못 미치는지.
  ///
  /// 설치된 버전을 모르면(안드로이드가 아니거나 조회 실패) false다.
  /// 판단 근거가 없을 때 사용자를 잠그지 않기 위해서다.
  bool isBelowRequiredVersion(int minRequiredVersionCode) {
    final installed = installedVersionCode;
    if (installed == null) return false;
    return installed < minRequiredVersionCode;
  }
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
