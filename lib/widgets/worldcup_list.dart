import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:my_worldcup_local/dto/worldcup_dao.dart';
import 'package:my_worldcup_local/widgets/worldcup_game.dart';
import 'package:my_worldcup_local/widgets/worldcup_list_item.dart';

import '../models/worldcup_model.dart';

class WorldCupList extends StatefulWidget {
  const WorldCupList({super.key});

  @override
  State<WorldCupList> createState() => _WorldCupListState();

}

class _WorldCupListState extends State<WorldCupList> {

  List<WorldCupModel> worldCupList = [];

  @override
  Widget build(BuildContext context) {

    _loadWorldCupList();

    return worldCupList.isEmpty
        ? Expanded(
            child: Container(
              alignment: Alignment.center,
              child: const Text(
                "오른쪽 상단의 + 버튼을 눌러 \n월드컵 게임을 추가해주세요",
                style: TextStyle(fontSize: 20),
                semanticsLabel: "항목이 비어있음",
              ),
            )
          )
        : Expanded(
        child: ListView.builder(
          itemBuilder: (context, index) => WorldCupListItem(worldCupList[index]),
          itemCount: worldCupList.length,
        ),
    );
  }

  void _loadWorldCupList() async {
    var db = WorldCupDao();
    List<WorldCupModel> newList = [
      WorldCupModel(-1, "여자 아이돌 월드컵", "최고의 여자 아이돌", DateTime(0), "assets/sample/female/espa_carina.jpg", 16),
      WorldCupModel(-2, "남자 아이돌 월드컵", "최고의 남자 아이돌", DateTime(0), "assets/sample/male/astro_cha.jpg", 16)
    ];
    newList.addAll((await db.getWorldCupList()));
    setState(() {
      worldCupList = newList;
    });
  }

}
