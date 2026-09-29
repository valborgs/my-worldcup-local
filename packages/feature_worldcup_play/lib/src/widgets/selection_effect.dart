import 'package:flutter/material.dart';
import 'package:worldcup_ui_kit/worldcup_ui_kit.dart';

/// Option 2's visual layer. The image remains a cached child while effects tick.
class SelectionEffect extends StatelessWidget {
  final Animation<double> animation;
  final bool enabled;
  final bool winner;
  final bool isFinal;
  final Widget child;

  const SelectionEffect({
    required this.animation,
    required this.enabled,
    required this.winner,
    required this.isFinal,
    required this.child,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;
    final strings = AppLocalizations.of(context);
    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, image) {
        final t = animation.value;
        final exit = const Interval(
          0.08,
          0.48,
          curve: Curves.easeInCubic,
        ).transform(t);
        final pop = TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 1, end: 0.96), weight: 12),
          TweenSequenceItem(
            tween: Tween(
              begin: 0.96,
              end: isFinal ? 1.08 : 1.04,
            ).chain(CurveTween(curve: Curves.easeOutBack)),
            weight: 43,
          ),
          TweenSequenceItem(
            tween: ConstantTween(isFinal ? 1.08 : 1.04),
            weight: 45,
          ),
        ]).transform(t);
        final reveal = const Interval(
          0.35,
          0.55,
          curve: Curves.easeOut,
        ).transform(t);
        final accent = isFinal
            ? const Color(0xFFFFD166)
            : const Color(0xFFB388FF);
        return Opacity(
          opacity: winner ? 1 : 1 - exit,
          child: Transform.scale(
            scale: winner ? pop : 1 - exit * 0.16,
            child: Stack(
              fit: StackFit.expand,
              children: [
                image!,
                if (winner && isFinal) ...[
                  IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.65 * reveal),
                          ],
                          radius: 0.85,
                        ),
                      ),
                    ),
                  ),
                ],
                if (winner)
                  Align(
                    alignment: const Alignment(0, 0.65),
                    child: Opacity(
                      opacity: reveal,
                      child: Transform.scale(
                        scale: 0.7 + 0.3 * Curves.easeOutBack.transform(reveal),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: accent,
                            borderRadius: BorderRadius.circular(32),
                            boxShadow: const [
                              BoxShadow(color: Colors.black38, blurRadius: 16),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isFinal
                                      ? Icons.emoji_events
                                      : Icons.check_circle,
                                  color: Colors.black,
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    isFinal
                                        ? strings.animationChampion
                                        : strings.animationAdvance,
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontSize: 24,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
