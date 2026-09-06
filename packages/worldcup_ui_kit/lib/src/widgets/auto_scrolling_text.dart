import 'dart:async';

import 'package:flutter/material.dart';

/// 한 줄 텍스트가 가로 공간을 넘을 때 끝까지 자동으로 스크롤합니다.
///
/// 가로 크기가 제한된 부모 안에서 사용해야 합니다.
class AutoScrollingText extends StatefulWidget {
  final String text;
  final String? semanticsLabel;
  final TextStyle? style;

  const AutoScrollingText(
    this.text, {
    this.semanticsLabel,
    this.style,
    super.key,
  });

  @override
  State<AutoScrollingText> createState() => _AutoScrollingTextState();
}

class _AutoScrollingTextState extends State<AutoScrollingText> {
  static const _startDelay = Duration(seconds: 1);
  static const _endDelay = Duration(seconds: 1);
  static const _returnDuration = Duration(milliseconds: 500);
  static const _preferredPixelsPerSecond = 30.0;
  static const _minimumScrollDuration = Duration(seconds: 1);
  static const _maximumScrollDuration = Duration(seconds: 12);

  final ScrollController _scrollController = ScrollController();
  Timer? _pauseTimer;
  double? _viewportWidth;
  bool _restartScheduled = false;
  int _generation = 0;

  @override
  void didUpdateWidget(covariant AutoScrollingText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text || oldWidget.style != widget.style) {
      _scheduleRestart();
    }
  }

  @override
  void dispose() {
    _generation++;
    _pauseTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.semanticsLabel ?? widget.text,
      child: ExcludeSemantics(
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (_viewportWidth != constraints.maxWidth) {
              _viewportWidth = constraints.maxWidth;
              _scheduleRestart();
            }

            return SingleChildScrollView(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              child: Text(
                widget.text,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.visible,
                style: widget.style,
              ),
            );
          },
        ),
      ),
    );
  }

  void _scheduleRestart() {
    if (_restartScheduled) return;
    _restartScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _restartScheduled = false;
      if (mounted) _restart();
    });
  }

  void _restart() {
    final generation = ++_generation;
    _pauseTimer?.cancel();
    if (!_scrollController.hasClients) return;

    _scrollController.jumpTo(0);
    if (_scrollController.position.maxScrollExtent <= 0) return;

    _pauseTimer = Timer(_startDelay, () => unawaited(_scrollToEnd(generation)));
  }

  Future<void> _scrollToEnd(int generation) async {
    if (!_isActive(generation)) return;

    final distance = _scrollController.position.maxScrollExtent;
    final duration = _scrollDurationFor(distance);
    await _scrollController.animateTo(
      distance,
      duration: duration,
      curve: Curves.linear,
    );
    if (!_isActive(generation)) return;

    _pauseTimer = Timer(_endDelay, () => unawaited(_scrollToStart(generation)));
  }

  Future<void> _scrollToStart(int generation) async {
    if (!_isActive(generation)) return;

    await _scrollController.animateTo(
      0,
      duration: _returnDuration,
      curve: Curves.easeOut,
    );
    if (!_isActive(generation)) return;

    _pauseTimer = Timer(_startDelay, () => unawaited(_scrollToEnd(generation)));
  }

  bool _isActive(int generation) {
    return mounted && generation == _generation && _scrollController.hasClients;
  }

  Duration _scrollDurationFor(double distance) {
    // 일반적인 제목은 선호 속도로 이동하되, 너무 짧거나 긴 제목도 사용자가
    // 움직임을 인지하고 합리적인 시간 안에 끝을 확인할 수 있도록 범위를 제한한다.
    final milliseconds = (distance / _preferredPixelsPerSecond * 1000)
        .round()
        .clamp(
          _minimumScrollDuration.inMilliseconds,
          _maximumScrollDuration.inMilliseconds,
        );
    return Duration(milliseconds: milliseconds);
  }
}
