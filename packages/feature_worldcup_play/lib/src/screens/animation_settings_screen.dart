import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worldcup_ui_kit/worldcup_ui_kit.dart';

import '../state/animation_settings.dart';

class AnimationSettingsScreen extends ConsumerStatefulWidget {
  const AnimationSettingsScreen({super.key});

  @override
  ConsumerState<AnimationSettingsScreen> createState() =>
      _AnimationSettingsScreenState();
}

class _AnimationSettingsScreenState
    extends ConsumerState<AnimationSettingsScreen> {
  bool _saving = false;

  Future<void> _select(SelectionAnimation value) async {
    if (_saving || ref.read(selectionAnimationProvider) == value) return;
    setState(() => _saving = true);
    try {
      await ref.read(selectionAnimationProvider.notifier).select(value);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).animationSaveFailed),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final selected = ref.watch(selectionAnimationProvider);
    return Scaffold(
      appBar: AppBar(title: Text(strings.animationSettingsTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(strings.animationSettingsDescription),
            const SizedBox(height: 16),
            for (final option in SelectionAnimation.values)
              Card(
                child: ListTile(
                  enabled: !_saving,
                  selected: selected == option,
                  contentPadding: const EdgeInsets.all(16),
                  leading: Icon(
                    selected == option
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                  ),
                  title: Text(
                    option == SelectionAnimation.classic
                        ? strings.animationClassic
                        : strings.animationOption2,
                  ),
                  subtitle: option == SelectionAnimation.classic
                      ? null
                      : Text(strings.animationOption2Description),
                  onTap: () => _select(option),
                ),
              ),
            if (_saving) const LinearProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
