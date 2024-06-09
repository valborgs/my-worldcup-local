import 'package:flutter/material.dart';
import 'package:my_worldcup_local/dto/worldcup_dao.dart';
import 'package:my_worldcup_local/models/worldcup_item_model.dart';
import 'package:my_worldcup_local/models/worldcup_model.dart';
import 'package:provider/provider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../provider/worldcup_select_provider.dart';
import '../widgets/worldcup_game.dart';

class PlayWorldCupScreen extends StatefulWidget {
  WorldCupModel worldCupModel;
  int selectedRound;
  PlayWorldCupScreen(this.worldCupModel, this.selectedRound, {super.key});

  @override
  State<PlayWorldCupScreen> createState() => _PlayWorldCupScreenState();
}

class _PlayWorldCupScreenState extends State<PlayWorldCupScreen> {
  var dao = WorldCupDao();
  List<WorldCupItemModel>? itemList;
  String? title;

  @override
  void initState() {
    super.initState();
    title = widget.worldCupModel.title;
    getItemList();
  }

  Future<void> getItemList() async {
    await dao.getWorldCupItemList(widget.worldCupModel.idx).then((value) {
      setState(() {
        itemList = value;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return
      ChangeNotifierProvider(
      create: (context) => WorldCupSelectProvider(),
      child: itemList != null
          ? WorldCupGame(title, itemList!, widget.selectedRound)
          : const AnimatedSmoothIndicator(activeIndex: 1, count: 1),
    );
  }
}
