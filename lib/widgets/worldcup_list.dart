import 'package:flutter/material.dart';
import 'package:my_worldcup_local/dto/worldcup_dao.dart';
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

    return Expanded(
        child: ListView.builder(
          itemBuilder: (context, index) => WorldCupListItem(worldCupList[index]),
          itemCount: worldCupList.length,
        ),
    );
  }

  void _loadWorldCupList() async {
    var db = WorldCupDao();
    List<WorldCupModel> newList = await db.getWorldCupList();
    setState(() {
      worldCupList = newList;
    });
  }

}
