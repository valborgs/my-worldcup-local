import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:worldcup_domain/worldcup_domain.dart';
import 'package:worldcup_ui_kit/worldcup_ui_kit.dart';

import '../widgets/worldcup_game.dart';
import '../state/match_selection.dart';

class PlayWorldCupScreen extends ConsumerStatefulWidget {
  /// 진행할 월드컵의 id.
  ///
  /// 라우트 인자가 엔티티가 아니라 id이므로 여기서 직접 조회한다.
  /// (라우트 계약은 worldcup_core에 있고, core는 도메인보다 아래에 있어
  ///  엔티티를 담을 수 없다)
  final int worldCupId;
  final int selectedRound;

  const PlayWorldCupScreen(this.worldCupId, this.selectedRound, {super.key});

  @override
  ConsumerState<PlayWorldCupScreen> createState() => _PlayWorldCupScreenState();
}

class _PlayWorldCupScreenState extends ConsumerState<PlayWorldCupScreen> {
  late final dao = ref.read(worldCupRepositoryProvider);
  WorldCupModel? worldCupModel;
  List<WorldCupItemModel>? itemList;

  @override
  void initState() {
    super.initState();
    getItemList();
  }

  Future<void> getItemList() async {
    // 월드컵과 항목을 함께 불러온다. 화면은 둘 다 준비될 때까지
    // 기존과 같은 검은 화면을 유지하므로 사용자 눈에 보이는 변화는 없다.
    final model = await dao.findById(widget.worldCupId);
    final value = await dao.items(widget.worldCupId);
    if (!mounted) return;

    // 새 게임은 항상 선택되지 않은 상태에서 시작해야 한다. 직전 게임의
    // 우승 항목이 provider에 남아 있을 수 있기 때문이다.
    // 비동기 콜백이라 위젯 빌드 중이 아니므로 여기서 바꿔도 안전하다.
    ref.read(matchSelectionProvider.notifier).resetForNextMatch();

    setState(() {
      worldCupModel = model;
      itemList = value;
    });
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
            worldCupModel?.title ?? '',
            semanticsLabel: '${worldCupModel?.title ?? ''} 게임 화면',
          ),
          systemOverlayStyle: SystemUiOverlayStyle.dark,
        ),
        body: (itemList != null && worldCupModel != null)
            ? WorldCupGame(worldCupModel!, itemList!, widget.selectedRound)
            : const ColoredBox(color: Colors.black),
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
