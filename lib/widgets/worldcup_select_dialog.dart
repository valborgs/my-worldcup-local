import 'package:flutter/material.dart';

import '../dto/worldcup_dao.dart';
import '../models/worldcup_model.dart';
import '../screens/play_worldcup_screen.dart';
import '../screens/add_worldcup_screen.dart';
import '../tools/make_round.dart';
import 'outlined_icon_button.dart';

class WorldCupSelectDialog extends StatefulWidget {
  final WorldCupModel model;
  final VoidCallback onChanged;
  const WorldCupSelectDialog(this.model, {required this.onChanged, super.key});

  @override
  State<WorldCupSelectDialog> createState() => _WorldCupSelectDialogState();
}

class _WorldCupSelectDialogState extends State<WorldCupSelectDialog> {
  @override
  Widget build(BuildContext context) {
    // 선택된 라운드
    int selectedRound = makeMaxRound(widget.model.maxRound);

    return AlertDialog(
      title: Container(
        constraints: const BoxConstraints(maxHeight: 50),
        child: SingleChildScrollView(
            child: Text(
          widget.model.title,
          semanticsLabel: "월드컵 제목",
        )),
      ),
      content: SizedBox(
        height: 200,
        child: Column(
          children: [
            const Spacer(),
            Container(
              constraints: const BoxConstraints(maxHeight: 100),
              child: SingleChildScrollView(
                  child: Text(
                widget.model.info,
                semanticsLabel: "월드컵 설명",
              )),
            ),
            const Spacer(),
            const Padding(padding: EdgeInsets.only(top: 5)),
            const Text("- 라운드 수를 선택해주세요- "),
            const Padding(padding: EdgeInsets.only(top: 5)),
            DropdownMenu(
              initialSelection: makeMaxRound(widget.model.maxRound),
              menuStyle: const MenuStyle(
                  padding: WidgetStatePropertyAll(EdgeInsets.all(0))),
              dropdownMenuEntries: makeRoundList(widget.model.maxRound)
                  .map<DropdownMenuEntry<int>>((int value) {
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
                builder: (context) =>
                    PlayWorldCupScreen(widget.model, selectedRound),
              ),
            );
          },
        ),
        // 월드컵 수정 (샘플 월드컵이 아닌 경우에만 표시)
        if (widget.model.idx > 0)
          IconOutlinedButton(
            "수정",
            Icons.edit,
            Colors.orange,
            onPressed: () {
              Navigator.of(context)
                  .pushReplacement(
                    MaterialPageRoute(
                      builder: (context) =>
                          AddWorldCupScreen(editModel: widget.model),
                    ),
                  )
                  .then((_) => widget.onChanged());
            },
          ),
        // 월드컵 삭제
        IconOutlinedButton(
          "삭제",
          Icons.delete,
          Colors.red,
          onPressed: () {
            deleteWorldCup(context, widget.model.idx, widget.onChanged);
          },
        ),
      ],
    );
  }
}

// 월드컵 삭제
Future<void> deleteWorldCup(
  BuildContext context,
  int idx,
  VoidCallback onChanged,
) async {
  final dao = WorldCupDao();

  try {
    await dao.deleteWorldCup(idx);
  } catch (error) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("데이터를 삭제할 수 없습니다. 잠시후에 다시 시도해주세요.")));
    return;
  }

  if (!context.mounted) return;
  onChanged();
  Navigator.of(context).pop();
}
