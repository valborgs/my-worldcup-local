import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:worldcup_core/worldcup_core.dart';
import 'package:worldcup_domain/worldcup_domain.dart';

/// Firebase Remote Config 기반 [FeatureFlagPort] 구현.
///
/// 어떤 단계에서 실패하든 예외를 밖으로 내보내지 않고 기본값을 돌려준다.
/// 플래그를 못 가져왔다는 이유로 앱이 뜨지 못하면 안 된다.
class FirebaseFeatureFlags implements FeatureFlagPort {
  final FirebaseRemoteConfig _remoteConfig;
  final Duration _fetchTimeout;
  final Duration _minimumFetchInterval;
  final AppLogger _logger;

  FirebaseFeatureFlags({
    FirebaseRemoteConfig? remoteConfig,
    this._fetchTimeout = const Duration(seconds: 10),
    required this._minimumFetchInterval,
    this._logger = const DeveloperLogger('remote_config'),
  }) : _remoteConfig = remoteConfig ?? FirebaseRemoteConfig.instance;

  bool _initialized = false;

  @override
  Future<bool> getBool(String key, {required bool defaultValue}) async {
    try {
      await _ensureInitialized({key: defaultValue});
      return _remoteConfig.getBool(key);
    } catch (error, stackTrace) {
      _logger.error(
        'Remote Config를 읽지 못해 기본값을 사용합니다: $key',
        error: error,
        stackTrace: stackTrace,
      );
      return defaultValue;
    }
  }

  Future<void> _ensureInitialized(Map<String, Object?> defaults) async {
    if (_initialized) return;
    await _remoteConfig.setDefaults(defaults);
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
    _initialized = true;
  }
}
