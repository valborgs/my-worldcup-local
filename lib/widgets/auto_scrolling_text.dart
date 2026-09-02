import 'dart:async';

import 'package:flutter/material.dart';

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
  static const _pixelsPerSecond = 30.0;

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
    return LayoutBuilder(
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
            semanticsLabel: widget.semanticsLabel,
            style: widget.style,
          ),
        );
      },
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

    _pauseTimer = Timer(
      _startDelay,
      () => unawaited(_scrollToEnd(generation)),
    );
  }

  Future<void> _scrollToEnd(int generation) async {
    if (!_isActive(generation)) return;

    final distance = _scrollController.position.maxScrollExtent;
    final duration = Duration(
      milliseconds:
          (distance / _pixelsPerSecond * 1000).round().clamp(1000, 12000),
    );
    await _scrollController.animateTo(
      distance,
      duration: duration,
      curve: Curves.linear,
    );
    if (!_isActive(generation)) return;

    _pauseTimer = Timer(
      _endDelay,
      () => unawaited(_scrollToStart(generation)),
    );
  }

  Future<void> _scrollToStart(int generation) async {
    if (!_isActive(generation)) return;

    await _scrollController.animateTo(
      0,
      duration: _returnDuration,
      curve: Curves.easeOut,
    );
    if (!_isActive(generation)) return;

    _pauseTimer = Timer(
      _startDelay,
      () => unawaited(_scrollToEnd(generation)),
    );
  }

  bool _isActive(int generation) {
    return mounted && generation == _generation && _scrollController.hasClients;
  }
}
