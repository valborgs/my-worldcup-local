import 'package:flutter_riverpod/flutter_riverpod.dart';

// 값 이름은 그대로 설정에 저장되므로, 이미 있는 값의 이름은 바꾸지 않는다.
enum SelectionAnimation {
  classic,
  option1,
  option2,
  option3,
  option4;

  // 선택 효과 한 번의 길이.
  Duration effectDuration({required bool isFinal}) => switch (this) {
    classic => const Duration(seconds: 1),
    option1 => Duration(milliseconds: isFinal ? 1800 : 900),
    option2 => Duration(milliseconds: isFinal ? 600 : 350),
    option3 => Duration(milliseconds: isFinal ? 1200 : 800),
    option4 => Duration(milliseconds: isFinal ? 1800 : 1100),
  };

  // 선택한 뒤 다음 대결(또는 결과 화면)로 넘어가기까지 기다리는 시간.
  // 효과가 끝나기 전에 넘어가지 않도록 effectDuration보다 짧아서는 안 된다.
  Duration matchDelay({required bool isFinal}) => switch (this) {
    classic => const Duration(seconds: 3),
    _ => effectDuration(isFinal: isFinal),
  };
}

const selectionAnimationPreferenceKey = 'selectionAnimation';

// 저장된 값이 없거나 알 수 없는 이름이면 기본값으로 돌아간다.
SelectionAnimation selectionAnimationFromName(String? name) =>
    SelectionAnimation.values.asNameMap()[name] ?? SelectionAnimation.classic;

final initialSelectionAnimationProvider = Provider<SelectionAnimation>(
  (ref) => SelectionAnimation.classic,
);

final saveSelectionAnimationProvider =
    Provider<Future<void> Function(SelectionAnimation)>((ref) {
      return (_) async => throw StateError('Animation persistence not bound');
    });

final selectionAnimationProvider =
    NotifierProvider<SelectionAnimationNotifier, SelectionAnimation>(
      SelectionAnimationNotifier.new,
    );

class SelectionAnimationNotifier extends Notifier<SelectionAnimation> {
  @override
  SelectionAnimation build() => ref.watch(initialSelectionAnimationProvider);

  Future<void> select(SelectionAnimation value) async {
    await ref.read(saveSelectionAnimationProvider)(value);
    if (ref.mounted) state = value;
  }
}
