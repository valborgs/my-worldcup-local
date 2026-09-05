import '../entities/worldcup_item_model.dart';
import '../entities/worldcup_model.dart';

/// 월드컵 저장소 포트.
///
/// 도메인은 이 인터페이스에만 의존하고, 구현(SQLite)은 데이터 레이어가
/// 제공한다. 실패는 `worldcup_core`의 `StorageFailure`로 감싸서 던진다.
abstract interface class WorldCupRepository {
  /// 검색어에 걸리는 월드컵의 총 개수. 페이징에서 전체 길이를 알 때 쓴다.
  Future<int> count({String searchQuery = ''});

  /// 전체 목록에서 [idx] 월드컵이 몇 번째인지. 페이저 위치 계산용이다.
  Future<int> indexOf(int idx);

  /// `idx` 오름차순 한 페이지.
  Future<List<WorldCupModel>> page({
    required int limit,
    required int offset,
    String searchQuery = '',
  });

  /// id로 월드컵 한 건. 없으면 `null`.
  ///
  /// 화면 이동 인자가 엔티티가 아니라 id이므로, 도착 화면이 이걸로 조회한다.
  Future<WorldCupModel?> findById(int idx);

  /// [worldCupIdx]에 속한 항목 전체.
  Future<List<WorldCupItemModel>> items(int worldCupIdx);

  /// 월드컵과 항목을 한 트랜잭션으로 저장하고, 새로 만들어진 id를 돌려준다.
  Future<int> add(WorldCupModel model, List<WorldCupItemModel> items);

  /// 월드컵과 항목을 한 트랜잭션으로 갱신한다. 기존 항목은 모두 교체된다.
  Future<void> update(WorldCupModel model, List<WorldCupItemModel> items);

  /// 월드컵과 그에 속한 항목을 한 트랜잭션으로 삭제한다.
  Future<void> delete(int idx);
}
