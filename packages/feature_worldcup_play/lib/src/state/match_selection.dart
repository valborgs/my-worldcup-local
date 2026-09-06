import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worldcup_domain/worldcup_domain.dart';

/// 한 대결에서의 선택 상태.
class MatchSelection {
  /// 사용자가 고른 쪽. 아직 안 골랐으면 [SelectedItemPosition.none].
  final SelectedItemPosition position;

  /// 고른 항목. 아직 안 골랐으면 `null`.
  final WorldCupItemModel? item;

  const MatchSelection({this.position = SelectedItemPosition.none, this.item});

  /// 이번 대결에서 이미 선택했는지 여부.
  ///
  /// GameItem의 탭 가능 여부를 판단하는 유일한 기준이다. 위젯의 로컬 State로
  /// 판단하면, 직전 대결에서 이긴 항목이 같은 위치에 다시 배치돼 State가
  /// 재사용될 때 탭이 먹지 않는다.
  bool get hasSelected => position != SelectedItemPosition.none;

  @override
  bool operator ==(Object other) =>
      other is MatchSelection &&
      other.position == position &&
      other.item == item;

  @override
  int get hashCode => Object.hash(position, item);
}

/// 진행 중인 대결의 선택 상태를 들고 있는다.
class MatchSelectionNotifier extends Notifier<MatchSelection> {
  @override
  MatchSelection build() => const MatchSelection();

  void select(SelectedItemPosition position, WorldCupItemModel item) {
    state = MatchSelection(position: position, item: item);
  }

  /// 다음 대결을 위해 선택을 비운다.
  ///
  /// 예전 ChangeNotifier 구현은 여기서 일부러 notifyListeners를 부르지
  /// 않았다. 알림이 가면 두 항목 모두 "선택되지 않음"으로 보여 화면 밖으로
  /// 밀려나는 애니메이션이 잘못 재생됐기 때문이다.
  ///
  /// Riverpod에서는 상태가 바뀌면 알림을 막을 수 없으므로, 대신 듣는 쪽이
  /// [MatchSelection.hasSelected]가 false인 알림을 무시한다.
  /// 숨은 "알리지 않는다" 규칙 대신 명시적인 조건이라 더 안전하다.
  void resetForNextMatch() {
    state = const MatchSelection();
  }
}

/// 대결 선택 상태.
///
/// 게임 한 판 동안만 의미가 있으며, 매 대결 시작 시
/// [MatchSelectionNotifier.resetForNextMatch]로 초기화된다.
final matchSelectionProvider =
    NotifierProvider<MatchSelectionNotifier, MatchSelection>(
      MatchSelectionNotifier.new,
    );
