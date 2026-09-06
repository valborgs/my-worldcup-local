import 'dart:developer' as developer;

/// 로깅 포트.
///
/// 도메인과 데이터 레이어는 이 인터페이스에만 의존한다. `print()`는 어디서도
/// 쓰지 않는다.
abstract interface class AppLogger {
  void debug(String message, {Object? error, StackTrace? stackTrace});

  void error(String message, {Object? error, StackTrace? stackTrace});
}

/// `dart:developer` 기반 기본 구현.
///
/// [name]은 로그 출처를 구분하는 태그로, 기존 코드에서 `log(..., name: 'xxx')`에
/// 넘기던 값과 같은 역할을 한다.
final class DeveloperLogger implements AppLogger {
  final String name;

  const DeveloperLogger(this.name);

  @override
  void debug(String message, {Object? error, StackTrace? stackTrace}) {
    developer.log(message, name: name, error: error, stackTrace: stackTrace);
  }

  @override
  void error(String message, {Object? error, StackTrace? stackTrace}) {
    developer.log(
      message,
      name: name,
      level: 1000,
      error: error,
      stackTrace: stackTrace,
    );
  }
}
