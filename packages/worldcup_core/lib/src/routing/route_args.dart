/// 라우트 인자 타입.
///
/// 인자는 도메인 엔티티가 아니라 **식별자**로 주고받는다. 엔티티를 그대로
/// 넘기면 라우트 계약이 엔티티 구조에 묶여, 결국 화면끼리 다시 결합된다.
/// 도착 화면이 id로 필요한 데이터를 직접 조회한다.
///
/// 게이트웨이나 컨트롤러 같은 테스트 시밈은 라우트 인자로 넘기지 않는다.
/// 그것들은 DI(Riverpod)로 주입한다.
library;

/// [AppRoutes.editor] 인자.
class EditorArgs {
  /// 수정할 월드컵 id. `null`이면 신규 생성.
  final int? worldCupId;

  const EditorArgs({this.worldCupId});

  bool get isNew => worldCupId == null;
}

/// [AppRoutes.play] 인자.
class PlayArgs {
  final int worldCupId;

  /// 사용자가 고른 시작 라운드 (예: 16강이면 16).
  final int round;

  const PlayArgs({required this.worldCupId, required this.round});
}

/// [AppRoutes.result] 인자.
class ResultArgs {
  final int worldCupId;

  /// 우승한 항목의 id.
  final int winnerItemId;

  /// 이 게임을 시작한 라운드. "다시 하기"에서 같은 라운드로 재시작할 때 쓴다.
  final int round;

  const ResultArgs({
    required this.worldCupId,
    required this.winnerItemId,
    required this.round,
  });
}

/// [AppRoutes.nearbySend] 인자.
class NearbySendArgs {
  final int worldCupId;

  const NearbySendArgs({required this.worldCupId});
}
