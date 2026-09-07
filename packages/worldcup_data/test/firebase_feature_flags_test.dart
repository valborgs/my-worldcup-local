import 'package:flutter_test/flutter_test.dart';
import 'package:worldcup_core/worldcup_core.dart';
import 'package:worldcup_data/worldcup_data.dart';
import 'package:worldcup_domain/worldcup_domain.dart';

/// 실패를 기록만 하고 넘어가는지 확인하기 위한 로거.
class _RecordingLogger implements AppLogger {
  final List<String> messages = <String>[];

  @override
  void debug(String message, {Object? error, StackTrace? stackTrace}) =>
      messages.add(message);

  @override
  void error(String message, {Object? error, StackTrace? stackTrace}) =>
      messages.add(message);
}

void main() {
  // 이 테스트는 Firebase를 초기화하지 않는다. `main()`이 Firebase 초기화
  // 실패를 잡고 앱을 계속 띄우는 경로와 같은 상황이다.
  group('Firebase가 초기화되지 않았을 때', () {
    test('생성만으로는 던지지 않는다', () {
      // 예전에는 생성자가 FirebaseRemoteConfig.instance를 바로 잡아서,
      // 이 포트를 만드는 것만으로 앱이 죽었다.
      expect(
        () => FirebaseFeatureFlags(minimumFetchInterval: Duration.zero),
        returnsNormally,
      );
    });

    test('getBool은 던지지 않고 기본값을 돌려준다', () async {
      final logger = _RecordingLogger();
      final flags = FirebaseFeatureFlags(
        minimumFetchInterval: Duration.zero,
        logger: logger,
      );

      expect(await flags.getBool('anyKey', defaultValue: true), isTrue);
      expect(logger.messages, isNotEmpty);
    });

    test('getInt는 던지지 않고 기본값을 돌려준다', () async {
      final flags = FirebaseFeatureFlags(
        minimumFetchInterval: Duration.zero,
        logger: _RecordingLogger(),
      );

      expect(
        await flags.getInt(
          FeatureFlags.minRequiredVersionCode,
          defaultValue: FeatureFlags.minRequiredVersionCodeDefault,
        ),
        FeatureFlags.minRequiredVersionCodeDefault,
      );
    });
  });
}
