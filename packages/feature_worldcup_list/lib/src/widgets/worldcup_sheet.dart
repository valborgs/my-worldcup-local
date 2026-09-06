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
  /// 창 트리밍 시 스크롤 오프셋을 정확히 보정하기 위한 고정 높이.
  static const double extent = 84;

  final WorldCupModel model;
  final VoidCallback onTap;

  const WorldCupSheetItem({
    super.key,
    required this.model,
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
      height: extent,
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
