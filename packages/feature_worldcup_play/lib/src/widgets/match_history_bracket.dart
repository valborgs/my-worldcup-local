import 'dart:math';

import 'package:flutter/material.dart';
import 'package:worldcup_ui_kit/worldcup_ui_kit.dart';

import '../state/match_history.dart';
import 'match_history_entry.dart';

const double _avatarSize = 48;
const double _nodeWidth = 84;
// 맨 아래 줄에서 항목 하나가 차지하는 폭.
const double _slotWidth = 92;
const double _rowGap = 32;
const double _padding = 16;
const double _spacing = 4;
const double _nameFontSize = 12;
const double _nameLineHeight = 1.25;

/// 우승 항목을 꼭대기에 두고 아래로 갈라지는 대진표.
///
/// 맨 아래 줄은 시작한 '강'의 항목 수만큼 넓어지므로 화면에 다 들어오지
/// 않는다. 끌어서 가로/세로로 움직이고 두 손가락으로 확대·축소한다.
class MatchHistoryBracket extends StatefulWidget {
  final BracketNode root;

  const MatchHistoryBracket(this.root, {super.key});

  @override
  State<MatchHistoryBracket> createState() => _MatchHistoryBracketState();
}

class _MatchHistoryBracketState extends State<MatchHistoryBracket> {
  TransformationController? _controller;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
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
    final rowHeight = nodeHeight + _rowGap;

    return LayoutBuilder(
      builder: (context, constraints) {
        final root = widget.root;
        // 대진표가 화면보다 좁으면 화면 폭에 맞춰 펼쳐 가운데에 오게 한다.
        final width = max(
          root.leafCount * _slotWidth + _padding * 2,
          constraints.maxWidth,
        );
        final height = root.depth * rowHeight - _rowGap + _padding * 2;
        final slot = (width - _padding * 2) / root.leafCount;

        final placed = <_Placed>[];
        _place(root, 0, slot, placed, _LeafCounter());

        // 처음에는 우승 항목이 보이도록 가로 가운데에서 시작한다. 왼쪽 끝에서
        // 시작하면 넓은 대진표에서는 빈 모서리만 보인다.
        _controller ??= TransformationController(
          Matrix4.translationValues(-(width - constraints.maxWidth) / 2, 0, 0),
        );

        return InteractiveViewer(
          transformationController: _controller,
          constrained: false,
          minScale: 0.3,
          maxScale: 2.5,
          child: SizedBox(
            width: width,
            height: height,
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _ConnectorPainter(
                      placed: placed,
                      nodeHeight: nodeHeight,
                      rowHeight: rowHeight,
                      winnerColor: colors.primary,
                      loserColor: colors.outlineVariant,
                    ),
                  ),
                ),
                for (final entry in placed)
                  Positioned(
                    left: entry.centerX - _nodeWidth / 2,
                    top: _padding + entry.row * rowHeight,
                    width: _nodeWidth,
                    height: nodeHeight,
                    child: _BracketNodeView(entry.node),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 맨 아래 항목을 왼쪽부터 한 칸씩 놓고, 위 칸은 두 아래 칸의 가운데에 둔다.
  _Placed _place(
    BracketNode node,
    int row,
    double slot,
    List<_Placed> out,
    _LeafCounter leaves,
  ) {
    final children = [
      for (final child in node.children)
        _place(child, row + 1, slot, out, leaves),
    ];
    final centerX = children.isEmpty
        ? _padding + (leaves.next++ + 0.5) * slot
        : (children.first.centerX + children.last.centerX) / 2;
    final placed = _Placed(node, centerX, row, children);
    out.add(placed);
    return placed;
  }
}

class _LeafCounter {
  int next = 0;
}

class _Placed {
  final BracketNode node;
  final double centerX;
  final int row;
  final List<_Placed> children;

  const _Placed(this.node, this.centerX, this.row, this.children);
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
  final List<_Placed> placed;
  final double nodeHeight;
  final double rowHeight;
  final Color winnerColor;
  final Color loserColor;

  const _ConnectorPainter({
    required this.placed,
    required this.nodeHeight,
    required this.rowHeight,
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

    // 이긴 쪽 선이 진 쪽 선에 덮이지 않도록 나중에 그린다.
    for (final highlight in [false, true]) {
      for (final parent in placed) {
        final bottom = _padding + parent.row * rowHeight + nodeHeight;
        final middle = bottom + _rowGap / 2;
        for (final child in parent.children) {
          final won = child.node.outcome != MatchOutcome.eliminated;
          if (won != highlight) continue;
          final path = Path()
            ..moveTo(parent.centerX, bottom)
            ..lineTo(parent.centerX, middle)
            ..lineTo(child.centerX, middle)
            ..lineTo(child.centerX, bottom + _rowGap);
          canvas.drawPath(path, won ? winnerPaint : loserPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(_ConnectorPainter oldDelegate) {
    return oldDelegate.placed != placed ||
        oldDelegate.nodeHeight != nodeHeight ||
        oldDelegate.rowHeight != rowHeight ||
        oldDelegate.winnerColor != winnerColor ||
        oldDelegate.loserColor != loserColor;
  }
}
