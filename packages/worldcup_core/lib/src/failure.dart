/// 앱 전역에서 쓰는 실패 타입.
///
/// 각 레이어는 하위 라이브러리(sqflite, http, archive 등)의 예외를 그대로
/// 흘려보내지 않고 이 타입으로 감싼다. UI는 [message]를 그대로 사용자에게
/// 보여줄 수 있어야 하므로, 메시지는 한국어 완결 문장으로 작성한다.
sealed class Failure implements Exception {
  /// 사용자에게 그대로 노출 가능한 메시지.
  final String message;

  /// 원인이 된 하위 레이어의 예외. 로깅 용도이며 UI에 노출하지 않는다.
  final Object? cause;

  final StackTrace? stackTrace;

  const Failure(this.message, {this.cause, this.stackTrace});

  @override
  String toString() => '$runtimeType: $message';
}

/// 로컬 저장소(SQLite, 파일 시스템) 처리 실패.
final class StorageFailure extends Failure {
  const StorageFailure(super.message, {super.cause, super.stackTrace});
}

/// 네트워크 호출 실패.
final class NetworkFailure extends Failure {
  const NetworkFailure(super.message, {super.cause, super.stackTrace});
}

/// `.myworldcup` 패키지 파일의 생성 / 읽기 / 검증 실패.
final class PackageFailure extends Failure {
  const PackageFailure(super.message, {super.cause, super.stackTrace});
}

/// 주변 기기 전송(Nearby) 실패.
final class TransferFailure extends Failure {
  const TransferFailure(super.message, {super.cause, super.stackTrace});
}
