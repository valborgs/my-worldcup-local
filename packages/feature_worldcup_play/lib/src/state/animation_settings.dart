import 'package:flutter_riverpod/flutter_riverpod.dart';

enum SelectionAnimation { classic, option2 }

const selectionAnimationPreferenceKey = 'selectionAnimation';

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
