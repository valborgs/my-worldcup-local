import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:worldcup_core/worldcup_core.dart';
import 'package:worldcup_domain/worldcup_domain.dart';

/// Firebase Remote Config 기반 [FeatureFlagPort] 구현.
///
/// 어떤 단계에서 실패하든 예외를 밖으로 내보내지 않고 기본값을 돌려준다.
/// 플래그를 못 가져왔다는 이유로 앱이 뜨지 못하면 안 된다.
class FirebaseFeatureFlags implements FeatureFlagPort {
  final FirebaseRemoteConfig? _injectedRemoteConfig;
  final Duration _fetchTimeout;
  final Duration _minimumFetchInterval;
  final AppLogger _logger;

  FirebaseFeatureFlags({
    FirebaseRemoteConfig? remoteConfig,
    this._fetchTimeout = const Duration(seconds: 10),
    required this._minimumFetchInterval,
    this._logger = const DeveloperLogger('remote_config'),
  }) : _injectedRemoteConfig = remoteConfig;

  FirebaseRemoteConfig? _remoteConfigCache;

  /// `FirebaseRemoteConfig.instance`는 기본 Firebase 앱이 없으면 던진다.
  ///
  /// 생성자에서 미리 잡아 두면 그 예외가 이 클래스 밖으로 새어 나가, 위에
  /// 적어 둔 "절대 던지지 않는다"는 약속이 깨진다. `main()`은 Firebase 초기화
  /// 실패를 잡고 앱을 계속 띄우는데, 그 뒤에 이 포트를 만들기만 해도 앱이
  /// 죽어 버렸다. 그래서 실제로 쓸 때 try 안에서 늦게 만든다.
  FirebaseRemoteConfig get _remoteConfig => _remoteConfigCache ??=
      _injectedRemoteConfig ?? FirebaseRemoteConfig.instance;

  bool _fetched = false;

  /// 지금까지 조회한 키의 기본값. `setDefaults`는 기존 맵을 대체하므로,
  /// 키가 늘 때마다 이 맵 전체를 다시 넘겨야 앞서 등록한 기본값이 살아남는다.
  final Map<String, Object?> _defaults = <String, Object?>{};

  // read 인자를 `_remoteConfig.getBool` 같은 티어오프로 넘기면 _read의 try
  // 밖에서 _remoteConfig가 평가된다. 클로저로 감싸 try 안에서 풀리게 한다.
  @override
  Future<bool> getBool(String key, {required bool defaultValue}) async {
    return _read(
      key,
      defaultValue: defaultValue,
      read: (key) => _remoteConfig.getBool(key),
    );
  }

  @override
  Future<int> getInt(String key, {required int defaultValue}) async {
    return _read(
      key,
      defaultValue: defaultValue,
      read: (key) => _remoteConfig.getInt(key),
    );
  }

  Future<T> _read<T extends Object>(
    String key, {
    required T defaultValue,
    required T Function(String key) read,
  }) async {
    try {
      await _ensureReady(key, defaultValue);
      return read(key);
    } catch (error, stackTrace) {
      _logger.error(
        'Remote Config를 읽지 못해 기본값을 사용합니다: $key',
        error: error,
        stackTrace: stackTrace,
      );
      return defaultValue;
    }
  }

  Future<void> _ensureReady(String key, Object value) async {
    if (_defaults[key] != value) {
      _defaults[key] = value;
      await _remoteConfig.setDefaults(Map<String, Object?>.from(_defaults));
    }
    if (_fetched) return;

    await _remoteConfig.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: _fetchTimeout,
        minimumFetchInterval: _minimumFetchInterval,
      ),
    );
    try {
      await _remoteConfig.fetchAndActivate();
    } catch (error, stackTrace) {
      // 네트워크가 없어도 캐시된 값이나 기본값으로 계속 진행한다.
      _logger.debug(
        'Remote Config를 가져오지 못해 캐시 또는 기본값을 사용합니다.',
        error: error,
        stackTrace: stackTrace,
      );
    }
    _fetched = true;
  }
}
