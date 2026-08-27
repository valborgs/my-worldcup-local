import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:my_worldcup_local/dto/worldcup_dao.dart';
import 'package:my_worldcup_local/models/worldcup_item_model.dart';
import 'package:my_worldcup_local/models/worldcup_model.dart';
import 'package:provider/provider.dart';

import '../provider/worldcup_select_provider.dart';
import '../widgets/worldcup_game.dart';

class PlayWorldCupScreen extends StatefulWidget {
  final WorldCupModel worldCupModel;
  final int selectedRound;
  const PlayWorldCupScreen(this.worldCupModel, this.selectedRound, {super.key});

  @override
  State<PlayWorldCupScreen> createState() => _PlayWorldCupScreenState();
}

class _PlayWorldCupScreenState extends State<PlayWorldCupScreen> {
  final dao = WorldCupDao();
  List<WorldCupItemModel>? itemList;

  @override
  void initState() {
    super.initState();
    getItemList();
  }

  Future<void> getItemList() async {
    final value = await dao.getWorldCupItemList(widget.worldCupModel.idx);
    if (!mounted) return;
    setState(() => itemList = value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.worldCupModel.title),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      body: ChangeNotifierProvider(
        create: (context) => WorldCupSelectProvider(),
        child: itemList != null
            ? WorldCupGame(widget.worldCupModel, itemList!, widget.selectedRound)
            : const ColoredBox(color: Colors.black),
      ),
    );
  }
}
