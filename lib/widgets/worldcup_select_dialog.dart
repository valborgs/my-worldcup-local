import 'package:flutter/material.dart';

import '../dto/worldcup_dao.dart';
import '../models/worldcup_model.dart';
import '../screens/play_worldcup_screen.dart';
import '../tools/make_round.dart';
import 'outlined_icon_button.dart';

class WorldCupSelectDialog extends StatefulWidget {
  WorldCupModel model;
  WorldCupSelectDialog(this.model, {super.key});

  @override
  State<WorldCupSelectDialog> createState() => _WorldCupSelectDialogState();
}

class _WorldCupSelectDialogState extends State<WorldCupSelectDialog> {

  // 선택된 라운드
  int selectedRound = 0;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.model.title),
      content: SizedBox(
        height: 200,
        child: Column(
          children: [
            const Spacer(),
            Text(widget.model.info),
            const Spacer(),
            const Padding(padding: EdgeInsets.only(top: 5)),
            const Text("- 라운드 수를 선택해주세요- "),
            const Padding(padding: EdgeInsets.only(top: 5)),
            DropdownMenu(
              initialSelection: makeMaxRound(widget.model.maxRound),
              menuStyle: const MenuStyle(padding: WidgetStatePropertyAll(EdgeInsets.all(0))),
              dropdownMenuEntries: makeRoundList(widget.model.maxRound)
                  .map<DropdownMenuEntry<int>>((int value){
                return DropdownMenuEntry<int>(value: value, label: '$value 강');
              }).toList(),
              onSelected: (value) {
                selectedRound = value as int;
              },
            ),
            const Spacer(),
          ],
        ),
      ),
      actions: [
        // 월드컵 게임 시작
        IconOutlinedButton(
          "시작",
          Icons.play_arrow,
          Colors.deepPurpleAccent,
          onPressed: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => PlayWorldCupScreen(widget.model, selectedRound),
              ),
            );
          },
        ),
        // 월드컵 삭제
        IconOutlinedButton(
          "삭제",
          Icons.delete,
          Colors.red,
          onPressed: () {
            deleteWorldCup(context, widget.model.idx);
          },
        ),
      ],
    );
  }
}


// 월드컵 삭제
void deleteWorldCup(BuildContext context, int idx) {
  WorldCupDao? dao = WorldCupDao();

  // 삭제
  dao.deleteWorldCupByIdx(idx)
      .catchError((error) => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("데이터를 삭제할 수 없습니다. 잠시후에 다시 시도해주세요."))))
      .then((value) => Navigator.of(context).pop());

  dao = null;
}