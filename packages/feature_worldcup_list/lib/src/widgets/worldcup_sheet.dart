/// 목록 하단 바텀시트를 이루는 조각들.
///
/// 시트의 스크롤 / 검색 상태는 목록 화면이 들고 있고, 여기 있는 위젯들은
/// 받은 값만 그린다.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:worldcup_domain/worldcup_domain.dart';

class SheetHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double extent;

  const SheetHeaderDelegate({required this.child, required this.extent});

  @override
  double get minExtent => extent;

  @override
  double get maxExtent => extent;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return child;
  }

  @override
  bool shouldRebuild(covariant SheetHeaderDelegate oldDelegate) =>
      oldDelegate.child != child || oldDelegate.extent != extent;
}

class WorldCupSheetItem extends StatelessWidget {
  /// 창 트리밍 시 스크롤 오프셋을 정확히 보정할 항목 높이.
  ///
  /// 84는 기본 배율에서 64px leading과 여백이 만드는 최소 높이다.
  /// 글꼴 배율이 커지면 제목과 부제의 실제 한 줄 높이를 기준으로
  /// 항목도 함께 늘린다.
  static double extentFor(BuildContext context) {
    final theme = Theme.of(context);
    final tileTheme = ListTileTheme.of(context);
    final scaler = MediaQuery.textScalerOf(context);
    final textDirection = Directionality.of(context);

    double lineHeight(TextStyle? style) {
      final painter = TextPainter(
        text: TextSpan(text: 'Ag', style: style),
        maxLines: 1,
        textScaler: scaler,
        textDirection: textDirection,
      )..layout();
      return painter.height;
    }

    final titleHeight = lineHeight(
      tileTheme.titleTextStyle ?? theme.textTheme.bodyLarge,
    );
    final subtitleHeight = lineHeight(
      tileTheme.subtitleTextStyle ?? theme.textTheme.bodyMedium,
    );
    final textDrivenExtent = titleHeight + subtitleHeight + 28;
    return textDrivenExtent > 84 ? textDrivenExtent : 84;
  }

  final WorldCupModel model;
  final double itemExtent;
  final VoidCallback onTap;

  const WorldCupSheetItem({
    super.key,
    required this.model,
    required this.itemExtent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final image = model.titleImageSrc.isEmpty
        ? Image.asset('assets/images/free_character.png', fit: BoxFit.cover)
        : model.idx < 0
        ? Image.asset(model.titleImageSrc, fit: BoxFit.cover)
        : Image.file(File(model.titleImageSrc), fit: BoxFit.cover);
    return SizedBox(
      height: itemExtent,
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(width: 64, height: 64, child: image),
        ),
        title: Text(
          model.idx < 0 ? '(샘플) ${model.title}' : model.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '최대 라운드 : ${TournamentRounds.defaultRound(model.maxRound)}강',
        ),
      ),
    );
  }
}
