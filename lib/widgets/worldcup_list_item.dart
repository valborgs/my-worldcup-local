import 'dart:io';

import 'package:flutter/material.dart';
import 'package:my_worldcup_local/models/worldcup_model.dart';
import 'package:my_worldcup_local/tools/make_round.dart';
import 'package:my_worldcup_local/widgets/worldcup_select_dialog.dart';

class WorldCupListItem extends StatelessWidget {
  WorldCupModel worldCupModel;
  WorldCupListItem(this.worldCupModel, {super.key});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.all(5),
      leading:
      worldCupModel.titleImageSrc!="" ? (
          worldCupModel.idx<0
              ? Image.asset(worldCupModel.titleImageSrc, fit: BoxFit.cover)
              : Image.file(File(worldCupModel.titleImageSrc), fit: BoxFit.cover)
      ) : Image.asset("assets/images/free_character.png"),
      title: Text(worldCupModel.title, semanticsLabel: "월드컵 게임 타이틀",),
      subtitle: Text("최대 라운드 : ${makeMaxRound(worldCupModel.maxRound)}강", semanticsLabel: "월드컵 최대 라운드",),
      isThreeLine: true,
      onTap: () {
        // 선택한 월드컵 다이얼로그를 띄운다.
        showDialogBeforeGameStart(context, worldCupModel);
      },
    );
  }
}


Future<void> showDialogBeforeGameStart(BuildContext context, WorldCupModel model) async {
  showDialog(
    context: context,
    builder: (context) {
      return WorldCupSelectDialog(model);
    },
  );
}
