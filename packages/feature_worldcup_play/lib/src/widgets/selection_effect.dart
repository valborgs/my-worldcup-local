import 'package:flutter/material.dart';
import 'package:worldcup_ui_kit/worldcup_ui_kit.dart';

import '../state/animation_settings.dart';

const _advanceAccent = Color(0xFFB388FF);
const _finalAccent = Color(0xFFFFD166);
const _badgeReveal = Interval(0.35, 0.55, curve: Curves.easeOut);

/// The visual layer of every non-classic selection animation. The image
/// remains a cached child while effects tick.
class SelectionEffect extends StatelessWidget {
  // GameItem이 항목을 옮기는 구간. 여기서 같은 구간에 맞춰 회전/확대하므로
  // 두 곳이 같은 값을 써야 한다.
  static const option3Fall = Interval(0.1, 0.75, curve: Curves.easeInQuad);
  static const option4Move = Interval(0.35, 0.85, curve: Curves.easeInOutCubic);

  final Animation<double> animation;
  final SelectionAnimation style;
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
    this.style = SelectionAnimation.option1,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;
    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, image) {
        final t = animation.value;
        return switch (style) {
          SelectionAnimation.classic => image!,
          SelectionAnimation.option1 => _option1(context, t, image!),
          SelectionAnimation.option2 => _badged(
            context,
            // 효과가 짧아 배지를 읽을 시간이 모자라므로 더 일찍 띄운다.
            const Interval(0.1, 0.4, curve: Curves.easeOut).transform(t),
            _option2(t, image!),
          ),
          SelectionAnimation.option3 => _badged(
            context,
            _badgeReveal.transform(t),
            _option3(t, image!),
          ),
          SelectionAnimation.option4 => _badged(
            context,
            _badgeReveal.transform(t),
            _option4(t, image!),
          ),
        };
      },
    );
  }

  Widget _option1(BuildContext context, double t, Widget image) {
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
    final reveal = _badgeReveal.transform(t);
    return Opacity(
      opacity: winner ? 1 : 1 - exit,
      child: Transform.scale(
        scale: winner ? pop : 1 - exit * 0.16,
        child: Stack(
          fit: StackFit.expand,
          children: [
            image,
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
            if (winner) _badge(context, reveal),
          ],
        ),
      ),
    );
  }

  // 선택한 쪽 위에 진출/우승 배지를 얹는다. 탈락한 쪽은 그대로 둔다.
  Widget _badged(BuildContext context, double reveal, Widget effect) {
    if (!winner) return effect;
    return Stack(
      fit: StackFit.expand,
      children: [effect, _badge(context, reveal)],
    );
  }

  Widget _badge(BuildContext context, double reveal) {
    final strings = AppLocalizations.of(context);
    return Align(
      alignment: const Alignment(0, 0.65),
      child: Opacity(
        opacity: reveal,
        child: Transform.scale(
          scale: 0.7 + 0.3 * Curves.easeOutBack.transform(reveal),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: isFinal ? _finalAccent : _advanceAccent,
              borderRadius: BorderRadius.circular(32),
              boxShadow: const [
                BoxShadow(color: Colors.black38, blurRadius: 16),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isFinal ? Icons.emoji_events : Icons.check_circle,
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
    );
  }

  // 빠른 진행: 탈락한 쪽만 바로 사라지고, 선택한 쪽은 테두리와 배지로 표시한다.
  Widget _option2(double t, Widget image) {
    final exit = const Interval(0, 0.45, curve: Curves.easeOut).transform(t);
    final flash = const Interval(0, 0.3, curve: Curves.easeOut).transform(t);
    final accent = isFinal ? _finalAccent : _advanceAccent;
    return Opacity(
      opacity: winner ? 1 : 1 - exit,
      child: DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          border: Border.all(
            color: accent.withValues(alpha: winner ? flash : 0),
            width: 4,
          ),
        ),
        child: image,
      ),
    );
  }

  // KO: 탈락한 쪽은 기울며 떨어지고(이동은 GameItem), 선택한 쪽은 한 번 튄다.
  Widget _option3(double t, Widget image) {
    if (!winner) {
      final fall = option3Fall.transform(t);
      final fade = const Interval(0.5, 0.75).transform(t);
      return Opacity(
        opacity: 1 - fade,
        child: Transform.rotate(angle: 0.35 * fall, child: image),
      );
    }
    final peak = isFinal ? 1.1 : 1.06;
    final bounce = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1, end: 0.96), weight: 10),
      TweenSequenceItem(
        tween: Tween(
          begin: 0.96,
          end: peak,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: peak,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.bounceOut)),
        weight: 35,
      ),
      TweenSequenceItem(tween: ConstantTween(1), weight: 30),
    ]).transform(t);
    return Transform.scale(scale: bounce, child: image);
  }

  // 스포트라이트: 탈락한 쪽이 흑백으로 사라진 뒤, 선택한 쪽이 중앙으로
  // 오면서(이동은 GameItem) 확대된다. 두 항목이 겹치지 않도록 탈락한 쪽이
  // 다 사라진 다음에 이동을 시작한다.
  Widget _option4(double t, Widget image) {
    if (!winner) {
      final drain = const Interval(0, 0.3, curve: Curves.easeOut).transform(t);
      final fade = const Interval(0.2, 0.4).transform(t);
      return Opacity(
        opacity: 1 - fade,
        child: ColorFiltered(
          colorFilter: _drained(
            saturation: 1 - drain,
            brightness: 1 - 0.5 * drain,
          ),
          child: image,
        ),
      );
    }
    final zoom = option4Move.transform(t);
    return Transform.scale(
      scale: 1 + (isFinal ? 0.3 : 0.15) * zoom,
      child: image,
    );
  }
}

ColorFilter _drained({required double saturation, required double brightness}) {
  const lr = 0.2126, lg = 0.7152, lb = 0.0722;
  final s = saturation;
  final b = brightness;
  return ColorFilter.matrix(<double>[
    (lr + (1 - lr) * s) * b, lg * (1 - s) * b, lb * (1 - s) * b, 0, 0, //
    lr * (1 - s) * b, (lg + (1 - lg) * s) * b, lb * (1 - s) * b, 0, 0, //
    lr * (1 - s) * b, lg * (1 - s) * b, (lb + (1 - lb) * s) * b, 0, 0, //
    0, 0, 0, 1, 0, //
  ]);
}
