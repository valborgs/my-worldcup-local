/// 한 대결에서 사용자가 고른 쪽.
///
/// 원래 `lib/widgets/worldcup_game.dart`에 있었으나, 상태 관리 코드가 이 enum
/// 하나 때문에 위젯 파일을 import 하는 역방향 의존이 생겨 도메인으로 옮겼다.
enum SelectedItemPosition {
  /// 아직 아무것도 고르지 않음.
  none,
  top,
  bottom,
}
