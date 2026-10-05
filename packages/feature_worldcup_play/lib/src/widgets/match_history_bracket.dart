import 'dart:math';

import 'package:flutter/material.dart';
import 'package:worldcup_ui_kit/worldcup_ui_kit.dart';

import '../state/match_history.dart';
import 'match_history_entry.dart';

const double _avatarSize = 48;
const double _nodeWidth = 84;
// 아래로 펼친 대진표의 맨 아래 줄에서 항목 하나가 차지하는 폭.
const double _slotWidth = 92;
// 옆으로 눕힌 대진표에서 위아래로 놓인 칸 사이의 틈.
const double _sidewaysNodeGap = 8;
const double _rowGap = 32;
const double _padding = 16;
const double _spacing = 4;
const double _nameFontSize = 12;
const double _nameLineHeight = 1.25;
const double _maxScale = 2.5;

/// 대진표가 뻗는 방향.
enum _BracketDirection {
  /// 우승 항목이 꼭대기에 있고 아래로 갈라진다. 가로로 길다.
  down,

  /// 우승 항목이 오른쪽 끝에 있고 왼쪽으로 갈라진다. 세로로 길다.
  sideways,
}

/// 우승 항목에서 시작해 첫 '강'까지 갈라지는 대진표.
///
/// 첫 '강'의 줄은 항목 수만큼 길어지므로 화면에 다 들어오지 않는다. 끌어서
/// 움직이고, 두 손가락으로 전체가 한 화면에 들어올 때까지 축소할 수 있다.
/// 오른쪽 위의 버튼으로 가로로 긴 배치와 세로로 긴 배치를 오간다.
class MatchHistoryBracket extends StatefulWidget {
  final BracketNode root;

  const MatchHistoryBracket(this.root, {super.key});

  @override
  State<MatchHistoryBracket> createState() => _MatchHistoryBracketState();
}

class _MatchHistoryBracketState extends State<MatchHistoryBracket> {
  _BracketDirection _direction = _BracketDirection.down;

  void _rotate() {
    setState(() {
      _direction = _direction == _BracketDirection.down
          ? _BracketDirection.sideways
          : _BracketDirection.down;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final scaler = MediaQuery.textScalerOf(context);
    final nodeHeight =
        _avatarSize +
        _spacing +
        scaler.scale(_nameFontSize) * _nameLineHeight +
        _spacing +
        MatchOutcomeChip.heightFor(scaler) +
        // 글자 높이의 소수점 반올림 여유.
        2;
    final layout = _BracketLayout(widget.root, _direction, nodeHeight);

    return Stack(
      children: [
        Positioned.fill(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final viewport = constraints.biggest;
              return _BracketViewport(
                // 방향이나 화면 크기가 바뀌면 축소 한계와 처음 위치가 달라지므로
                // 보던 위치를 버리고 새로 시작한다.
                key: ValueKey((_direction, viewport, layout.size)),
                viewport: viewport,
                content: layout.size,
                // 처음에는 우승 항목이 보이게 한다. 모서리에서 시작하면 넓은
                // 대진표에서는 첫 '강'의 끝자락만 보인다.
                focus: layout.root.rect.center,
                child: SizedBox.fromSize(
                  size: layout.size,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _ConnectorPainter(
                            layout: layout,
                            winnerColor: colors.primary,
                            loserColor: colors.outlineVariant,
                          ),
                        ),
                      ),
                      for (final entry in layout.placed)
                        Positioned.fromRect(
                          rect: entry.rect,
                          child: _BracketNodeView(entry.node),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        PositionedDirectional(
          top: 8,
          end: 8,
          child: IconButton.filledTonal(
            tooltip: AppLocalizations.of(context).resultHistoryRotateBracket,
            icon: const Icon(Icons.rotate_90_degrees_cw_outlined),
            onPressed: _rotate,
          ),
        ),
      ],
    );
  }
}

/// 대진표를 끌고 확대·축소하는 창.
///
/// [InteractiveViewer]의 경계는 내용이 화면을 덮는 배율 아래로는 축소를 막는다.
/// 대진표는 한쪽으로만 길어서, 짧은 쪽이 화면을 덮는 순간 긴 쪽이 다 들어오기
/// 전에 축소가 멈춘다. 그래서 그 경계를 끄고 움직일 수 있는 범위를 직접 잡는다.
class _BracketViewport extends StatefulWidget {
  final Size viewport;
  final Size content;

  /// 처음에 화면 가운데로 가져올 [content] 안의 지점.
  final Offset focus;
  final Widget child;

  const _BracketViewport({
    required this.viewport,
    required this.content,
    required this.focus,
    required this.child,
    super.key,
  });

  @override
  State<_BracketViewport> createState() => _BracketViewportState();
}

class _BracketViewportState extends State<_BracketViewport> {
  late final TransformationController _controller;

  /// 대진표 전체가 화면에 들어오는 배율. 이미 다 들어오면 더 줄이지 않는다.
  double get _minScale {
    final fit = min(
      widget.viewport.width / widget.content.width,
      widget.viewport.height / widget.content.height,
    );
    return fit.clamp(0.01, 1.0);
  }

  @override
  void initState() {
    super.initState();
    final viewport = widget.viewport;
    _controller = TransformationController(
      _bounded(
        Matrix4.translationValues(
          viewport.width / 2 - widget.focus.dx,
          viewport.height / 2 - widget.focus.dy,
          0,
        ),
      ),
    )..addListener(_keepInBounds);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _keepInBounds() {
    final value = _controller.value;
    final bounded = _bounded(value);
    final moved = bounded.getTranslation() - value.getTranslation();
    if (moved.length2 < 1e-9) return;
    _controller.value = bounded;
  }

  /// 화면보다 큰 방향은 빈 곳이 보이지 않게 가장자리에서 멈추고, 화면보다 작은
  /// 방향은 가운데에 둔다.
  Matrix4 _bounded(Matrix4 matrix) {
    final scale = matrix.getMaxScaleOnAxis();
    final translation = matrix.getTranslation();

    double along(double offset, double content, double viewport) {
      final scaled = content * scale;
      if (scaled <= viewport) return (viewport - scaled) / 2;
      return offset.clamp(viewport - scaled, 0.0);
    }

    return matrix.clone()..setTranslationRaw(
      along(translation.x, widget.content.width, widget.viewport.width),
      along(translation.y, widget.content.height, widget.viewport.height),
      0,
    );
  }

  @override
  Widget build(BuildContext context) {
    return InteractiveViewer(
      transformationController: _controller,
      constrained: false,
      boundaryMargin: const EdgeInsets.all(double.infinity),
      minScale: _minScale,
      maxScale: _maxScale,
      child: widget.child,
    );
  }
}

/// 방향에 맞춰 각 칸의 자리와 대진표 전체 크기를 정한다.
class _BracketLayout {
  final _BracketDirection direction;
  final Size size;
  final List<_Placed> placed;
  final _Placed root;

  const _BracketLayout._(this.direction, this.size, this.placed, this.root);

  factory _BracketLayout(
    BracketNode root,
    _BracketDirection direction,
    double nodeHeight,
  ) {
    final sideways = direction == _BracketDirection.sideways;
    // 첫 '강'의 항목이 늘어서는 방향으로 한 칸이 차지하는 길이.
    final slot = sideways ? nodeHeight + _sidewaysNodeGap : _slotWidth;
    // 한 '강'에서 다음 '강'까지의 거리.
    final step = (sideways ? _nodeWidth : nodeHeight) + _rowGap;
    final depth = root.depth;
    final placed = <_Placed>[];
    var nextLeaf = 0;

    // 첫 '강'의 항목을 차례로 한 칸씩 놓고, 그 위 칸은 두 아래 칸의 가운데에 둔다.
    _Placed place(BracketNode node, int level) {
      final children = [
        for (final child in node.children) place(child, level + 1),
      ];
      final along = children.isEmpty
          ? _padding + (nextLeaf++ + 0.5) * slot
          : (children.first.along + children.last.along) / 2;
      final rect = sideways
          ? Rect.fromLTWH(
              _padding + (depth - 1 - level) * step,
              along - nodeHeight / 2,
              _nodeWidth,
              nodeHeight,
            )
          : Rect.fromLTWH(
              along - _nodeWidth / 2,
              _padding + level * step,
              _nodeWidth,
              nodeHeight,
            );
      final entry = _Placed(node, rect, along, children);
      placed.add(entry);
      return entry;
    }

    final placedRoot = place(root, 0);
    final leavesExtent = root.leafCount * slot + _padding * 2;
    final depthExtent = depth * step - _rowGap + _padding * 2;
    return _BracketLayout._(
      direction,
      sideways
          ? Size(depthExtent, leavesExtent)
          : Size(leavesExtent, depthExtent),
      placed,
      placedRoot,
    );
  }
}

class _Placed {
  final BracketNode node;
  final Rect rect;

  /// 첫 '강'의 항목이 늘어서는 방향에서의 가운데 위치.
  final double along;
  final List<_Placed> children;

  const _Placed(this.node, this.rect, this.along, this.children);
}

class _BracketNodeView extends StatelessWidget {
  final BracketNode node;

  const _BracketNodeView(this.node);

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final eliminated = node.outcome == MatchOutcome.eliminated;
    return MergeSemantics(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          MatchHistoryAvatar(
            node.item,
            size: _avatarSize,
            dimmed: eliminated,
            highlighted: node.outcome == MatchOutcome.champion,
          ),
          const SizedBox(height: _spacing),
          Text(
            matchHistoryItemName(AppLocalizations.of(context), node.item),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            strutStyle: const StrutStyle(
              fontSize: _nameFontSize,
              height: _nameLineHeight,
              forceStrutHeight: true,
            ),
            style: TextStyle(
              fontSize: _nameFontSize,
              height: _nameLineHeight,
              color: eliminated ? colors.onSurfaceVariant : colors.onSurface,
            ),
          ),
          const SizedBox(height: _spacing),
          MatchOutcomeChip(node.outcome),
        ],
      ),
    );
  }
}

class _ConnectorPainter extends CustomPainter {
  final _BracketLayout layout;
  final Color winnerColor;
  final Color loserColor;

  const _ConnectorPainter({
    required this.layout,
    required this.winnerColor,
    required this.loserColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final loserPaint = Paint()
      ..color = loserColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final winnerPaint = Paint()
      ..color = winnerColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    final sideways = layout.direction == _BracketDirection.sideways;

    // 이긴 쪽 선이 진 쪽 선에 덮이지 않도록 나중에 그린다.
    for (final highlight in [false, true]) {
      for (final parent in layout.placed) {
        for (final child in parent.children) {
          final won = child.node.outcome != MatchOutcome.eliminated;
          if (won != highlight) continue;
          final Path path;
          if (sideways) {
            final from = parent.rect.centerLeft;
            final to = child.rect.centerRight;
            final middle = from.dx - _rowGap / 2;
            path = Path()
              ..moveTo(from.dx, from.dy)
              ..lineTo(middle, from.dy)
              ..lineTo(middle, to.dy)
              ..lineTo(to.dx, to.dy);
          } else {
            final from = parent.rect.bottomCenter;
            final to = child.rect.topCenter;
            final middle = from.dy + _rowGap / 2;
            path = Path()
              ..moveTo(from.dx, from.dy)
              ..lineTo(from.dx, middle)
              ..lineTo(to.dx, middle)
              ..lineTo(to.dx, to.dy);
          }
          canvas.drawPath(path, won ? winnerPaint : loserPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(_ConnectorPainter oldDelegate) {
    return oldDelegate.layout != layout ||
        oldDelegate.winnerColor != winnerColor ||
        oldDelegate.loserColor != loserColor;
  }
}
