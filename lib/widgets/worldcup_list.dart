import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:my_worldcup_local/dto/worldcup_dao.dart';
import 'package:my_worldcup_local/widgets/worldcup_list_item.dart';

import '../models/worldcup_model.dart';

class WorldCupList extends StatefulWidget {
  final List<WorldCupModel>? initialWorldCupList;
  const WorldCupList({this.initialWorldCupList, super.key});

  @override
  State<WorldCupList> createState() => WorldCupListState();
}

class WorldCupListState extends State<WorldCupList> {
  late List<WorldCupModel> worldCupList = widget.initialWorldCupList ?? [];

  @override
  void initState() {
    super.initState();
    refresh();
  }

  @override
  Widget build(BuildContext context) {
    return worldCupList.isEmpty
        ? Expanded(
            child: Container(
            alignment: Alignment.center,
            child: const Text(
              "오른쪽 상단의 + 버튼을 눌러 \n월드컵 게임을 추가해주세요",
              style: TextStyle(fontSize: 20),
              semanticsLabel: "항목이 비어있음",
            ),
          ))
        : Expanded(
            child: ListView.builder(
              itemBuilder: (context, index) => WorldCupListItem(
                worldCupList[index],
                onChanged: refresh,
              ),
              itemCount: worldCupList.length,
            ),
          );
  }

  Future<void> refresh() async {
    final db = WorldCupDao();
    final newList = await db.getWorldCupList();
    if (!mounted) return;
    setState(() {
      worldCupList = newList;
    });
  }
}
