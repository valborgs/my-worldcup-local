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
        child: Column(
          children: [
            // 옵션이 화면보다 길어져도 보이도록 목록 밖, 고정된 자리에 둔다.
            SizedBox(
              height: 4,
              child: _saving ? const LinearProgressIndicator() : null,
            ),
            Expanded(
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
                        title: Text(switch (option) {
                          SelectionAnimation.classic =>
                            strings.animationClassic,
                          SelectionAnimation.option1 =>
                            strings.animationOption1,
                          SelectionAnimation.option2 =>
                            strings.animationOption2,
                          SelectionAnimation.option3 =>
                            strings.animationOption3,
                          SelectionAnimation.option4 =>
                            strings.animationOption4,
                        }),
                        subtitle: switch (option) {
                          SelectionAnimation.classic => null,
                          SelectionAnimation.option1 => Text(
                            strings.animationOption1Description,
                          ),
                          SelectionAnimation.option2 => Text(
                            strings.animationOption2Description,
                          ),
                          SelectionAnimation.option3 => Text(
                            strings.animationOption3Description,
                          ),
                          SelectionAnimation.option4 => Text(
                            strings.animationOption4Description,
                          ),
                        },
                        onTap: () => _select(option),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
