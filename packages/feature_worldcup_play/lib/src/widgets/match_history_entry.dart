import 'dart:io';

import 'package:flutter/material.dart';
import 'package:worldcup_domain/worldcup_domain.dart';
import 'package:worldcup_ui_kit/worldcup_ui_kit.dart';

import '../state/match_history.dart';

// 진행 기록의 대진표와 목록이 함께 쓰는 조각들.

const double _chipFontSize = 11;
const double _chipLineHeight = 1.2;
const double _chipVerticalPadding = 2;

String matchHistoryItemName(AppLocalizations l10n, WorldCupItemModel item) {
  return l10n.worldCupItemInfo(
    item.worldCupIdx,
    item.imagePath,
    item.imageInfo,
  );
}

/// 항목의 원형 사진.
class MatchHistoryAvatar extends StatelessWidget {
  final WorldCupItemModel item;
  final double size;

  /// 탈락한 항목을 흐리게 보여준다.
  final bool dimmed;

  /// 우승 항목에 테두리를 두른다.
  final bool highlighted;

  const MatchHistoryAvatar(
    this.item, {
    required this.size,
    this.dimmed = false,
    this.highlighted = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    // 원 안을 채우도록 잘라 쓰므로 가로가 긴 사진도 흐려지지 않게 여유를 둔다.
    final cacheWidth = (size * 2 * MediaQuery.devicePixelRatioOf(context))
        .round();
    // 사용자가 원본 사진을 지웠어도 기록 화면은 열려야 한다.
    Widget onError(BuildContext context, Object error, StackTrace? stack) {
      return ColoredBox(
        color: colors.surfaceContainerHighest,
        child: Icon(
          Icons.image_not_supported_outlined,
          size: size / 2,
          color: colors.onSurfaceVariant,
        ),
      );
    }

    // 이름이 바로 옆에 글자로 나오므로 사진은 읽어주지 않는다.
    final image = item.isSample
        ? Image.asset(
            item.imagePath,
            fit: BoxFit.cover,
            cacheWidth: cacheWidth,
            excludeFromSemantics: true,
            errorBuilder: onError,
          )
        : Image.file(
            File(item.imagePath),
            fit: BoxFit.cover,
            cacheWidth: cacheWidth,
            excludeFromSemantics: true,
            errorBuilder: onError,
          );

    return Opacity(
      opacity: dimmed ? 0.45 : 1,
      child: Container(
        width: size,
        height: size,
        foregroundDecoration: highlighted
            ? BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: colors.primary, width: 3),
              )
            : null,
        child: ClipOval(child: image),
      ),
    );
  }
}

/// 우승 / 진출 / 탈락 표시.
class MatchOutcomeChip extends StatelessWidget {
  final MatchOutcome outcome;

  const MatchOutcomeChip(this.outcome, {super.key});

  /// 글자 크기 설정을 반영한 칩의 높이. 대진표가 칸 높이를 미리 계산할 때 쓴다.
  static double heightFor(TextScaler scaler) {
    return scaler.scale(_chipFontSize) * _chipLineHeight +
        _chipVerticalPadding * 2;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final (label, background, foreground) = switch (outcome) {
      MatchOutcome.champion => (
        l10n.resultHistoryChampion,
        colors.primary,
        colors.onPrimary,
      ),
      MatchOutcome.advanced => (
        l10n.resultHistoryAdvanced,
        colors.primaryContainer,
        colors.onPrimaryContainer,
      ),
      MatchOutcome.eliminated => (
        l10n.resultHistoryEliminated,
        colors.surfaceContainerHighest,
        colors.onSurfaceVariant,
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: _chipVerticalPadding,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        strutStyle: const StrutStyle(
          fontSize: _chipFontSize,
          height: _chipLineHeight,
          forceStrutHeight: true,
        ),
        style: TextStyle(
          fontSize: _chipFontSize,
          height: _chipLineHeight,
          fontWeight: FontWeight.w600,
          color: foreground,
        ),
      ),
    );
  }
}
