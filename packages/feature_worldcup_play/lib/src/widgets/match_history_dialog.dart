import 'package:flutter/material.dart';
import 'package:worldcup_ui_kit/worldcup_ui_kit.dart';

import '../state/match_history.dart';
import 'match_history_bracket.dart';
import 'match_history_list.dart';

enum _HistoryView { bracket, list }

/// 게임 시작부터 우승까지의 선택 과정을 전체 화면으로 보여준다.
Future<void> showMatchHistoryDialog(
  BuildContext context,
  MatchHistory history,
) {
  return showDialog<void>(
    context: context,
    builder: (context) => MatchHistoryDialog(history),
  );
}

class MatchHistoryDialog extends StatefulWidget {
  final MatchHistory history;

  const MatchHistoryDialog(this.history, {super.key});

  @override
  State<MatchHistoryDialog> createState() => _MatchHistoryDialogState();
}

class _MatchHistoryDialogState extends State<MatchHistoryDialog> {
  _HistoryView _view = _HistoryView.bracket;
  late final BracketNode? _bracket = widget.history.bracket();
  late final List<MatchStage> _stages = widget.history.stagesFromFinal();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bracket = _bracket;
    return Dialog.fullscreen(
      child: Scaffold(
        appBar: AppBar(
          leading: const CloseButton(),
          title: Text(l10n.resultHistory),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: SegmentedButton<_HistoryView>(
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment(
                      value: _HistoryView.bracket,
                      icon: const Icon(Icons.account_tree_outlined),
                      label: Text(l10n.resultHistoryBracketView),
                    ),
                    ButtonSegment(
                      value: _HistoryView.list,
                      icon: const Icon(Icons.format_list_bulleted),
                      label: Text(l10n.resultHistoryListView),
                    ),
                  ],
                  selected: {_view},
                  onSelectionChanged: (selection) {
                    setState(() => _view = selection.first);
                  },
                ),
              ),
              Expanded(
                // 보기를 바꿨다 돌아와도 보던 위치가 남도록 둘 다 살려둔다.
                child: IndexedStack(
                  index: _view.index,
                  sizing: StackFit.expand,
                  children: [
                    if (bracket == null)
                      const SizedBox.shrink()
                    else
                      MatchHistoryBracket(bracket),
                    MatchHistoryList(_stages),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
