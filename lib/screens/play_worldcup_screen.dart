import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:worldcup_domain/worldcup_domain.dart';

import '../provider/worldcup_select_provider.dart';
import '../widgets/auto_scrolling_text.dart';
import '../widgets/worldcup_game.dart';
import '../di/providers.dart';

class PlayWorldCupScreen extends ConsumerStatefulWidget {
  final WorldCupModel worldCupModel;
  final int selectedRound;
  const PlayWorldCupScreen(this.worldCupModel, this.selectedRound, {super.key});

  @override
  ConsumerState<PlayWorldCupScreen> createState() => _PlayWorldCupScreenState();
}

class _PlayWorldCupScreenState extends ConsumerState<PlayWorldCupScreen> {
  late final dao = ref.read(worldCupRepositoryProvider);
  List<WorldCupItemModel>? itemList;

  @override
  void initState() {
    super.initState();
    getItemList();
  }

  Future<void> getItemList() async {
    final value = await dao.items(widget.worldCupModel.idx);
    if (!mounted) return;
    setState(() => itemList = value);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _showExitGameDialog();
      },
      child: Scaffold(
        appBar: AppBar(
          title: AutoScrollingText(
            widget.worldCupModel.title,
            semanticsLabel: '${widget.worldCupModel.title} 게임 화면',
          ),
          systemOverlayStyle: SystemUiOverlayStyle.dark,
        ),
        body: ChangeNotifierProvider(
          create: (context) => WorldCupSelectProvider(),
          child: itemList != null
              ? WorldCupGame(
                  widget.worldCupModel,
                  itemList!,
                  widget.selectedRound,
                )
              : const ColoredBox(color: Colors.black),
        ),
      ),
    );
  }

  // 게임 진행 중 뒤로가기 시 종료 확인
  void _showExitGameDialog() {
    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('게임 종료'),
          content: const Text('게임을 종료하시겠습니까?\n진행 상황은 저장되지 않습니다.'),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
                textStyle: Theme.of(dialogContext).textTheme.labelLarge,
              ),
              child: const Text('아니오'),
              onPressed: () => Navigator.pop(dialogContext),
            ),
            TextButton(
              style: TextButton.styleFrom(
                textStyle: Theme.of(dialogContext).textTheme.labelLarge,
              ),
              child: const Text('네'),
              onPressed: () {
                Navigator.pop(dialogContext); // 다이얼로그 닫기
                Navigator.of(context).pop(); // 게임 화면 닫기
              },
            ),
          ],
        );
      },
    );
  }
}
