import 'dart:io';

import 'package:flutter/material.dart';
import 'package:my_worldcup_local/models/worldcup_model.dart';
import 'package:my_worldcup_local/tools/make_round.dart';
import 'package:my_worldcup_local/widgets/worldcup_select_dialog.dart';

class WorldCupListItem extends StatelessWidget {
  final WorldCupModel worldCupModel;
  final VoidCallback onChanged;
  const WorldCupListItem(this.worldCupModel,
      {required this.onChanged, super.key});

  @override
  Widget build(BuildContext context) {
    // ListTile leading은 보통 56dp 정도의 작은 정사각형 영역이므로,
    // 그 크기 이상으로 원본 해상도를 디코딩할 필요가 없다.
    final cacheDimension =
        (56 * MediaQuery.of(context).devicePixelRatio).round();
    return ListTile(
      contentPadding: const EdgeInsets.all(5),
      leading: worldCupModel.titleImageSrc != ""
          ? (worldCupModel.idx < 0
              ? Image.asset(worldCupModel.titleImageSrc,
                  fit: BoxFit.cover, cacheWidth: cacheDimension)
              : Image.file(File(worldCupModel.titleImageSrc),
                  fit: BoxFit.cover, cacheWidth: cacheDimension))
          : Image.asset("assets/images/free_character.png"),
      title: Text(
        worldCupModel.idx < 0
            ? "(샘플) ${worldCupModel.title}"
            : worldCupModel.title,
        semanticsLabel: "월드컵 게임 타이틀",
      ),
      subtitle: Text(
        "최대 라운드 : ${makeMaxRound(worldCupModel.maxRound)}강",
        semanticsLabel: "월드컵 최대 라운드",
      ),
      isThreeLine: true,
      onTap: () {
        // 선택한 월드컵 다이얼로그를 띄운다.
        showDialogBeforeGameStart(context, worldCupModel, onChanged);
      },
    );
  }
}

Future<void> showDialogBeforeGameStart(
  BuildContext context,
  WorldCupModel model,
  VoidCallback onChanged,
) async {
  await showDialog<void>(
    context: context,
    builder: (context) {
      return WorldCupSelectDialog(model, onChanged: onChanged);
    },
  );
}
