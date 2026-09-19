import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worldcup_domain/worldcup_domain.dart';

import 'package:worldcup_core/worldcup_core.dart';
import 'package:worldcup_ui_kit/worldcup_ui_kit.dart';

class WorldCupSelectDialog extends ConsumerStatefulWidget {
  final WorldCupModel model;
  final VoidCallback onChanged;
  final WorldCupPackagePort? packageGateway;

  const WorldCupSelectDialog(
    this.model, {
    required this.onChanged,
    this.packageGateway,
    super.key,
  });

  @override
  ConsumerState<WorldCupSelectDialog> createState() =>
      _WorldCupSelectDialogState();
}

class _WorldCupSelectDialogState extends ConsumerState<WorldCupSelectDialog> {
  late int _selectedRound;
  bool _isSharing = false;

  @override
  void initState() {
    super.initState();
    _selectedRound = TournamentRounds.defaultRound(widget.model.maxRound);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      title: Text(
        AppLocalizations.of(context)
            .worldCupTitle(widget.model.idx, widget.model.title),
        semanticsLabel: AppLocalizations.of(context).worldCupTitleSemantics,
      ),
      content: Text(
        AppLocalizations.of(context)
            .worldCupInfo(widget.model.idx, widget.model.info),
        semanticsLabel: AppLocalizations.of(context)
            .worldCupDescriptionSemantics,
      ),
      actions: [
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              AppLocalizations.of(context).worldCupChooseRound,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 5),
            Center(
              child: DropdownMenu(
                initialSelection: TournamentRounds.defaultRound(
                  widget.model.maxRound,
                ),
                menuStyle: const MenuStyle(
                  padding: WidgetStatePropertyAll(EdgeInsets.all(0)),
                ),
                dropdownMenuEntries:
                    TournamentRounds.available(widget.model.maxRound)
                        .map<DropdownMenuEntry<int>>((int value) {
                          return DropdownMenuEntry<int>(
                            value: value,
                            label: AppLocalizations.of(context)
                                .worldCupRoundOption(value),
                          );
                        })
                        .toList(),
                onSelected: (value) {
                  if (value != null) _selectedRound = value;
                },
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              runSpacing: 8,
              children: [
                // 월드컵 게임 시작
                IconOutlinedButton(
                  AppLocalizations.of(context).commonStart,
                  Icons.play_arrow,
                  Colors.deepPurpleAccent,
                  onPressed: () {
                    Navigator.of(context).pushReplacementNamed(
                      AppRoutes.play,
                      arguments: PlayArgs(
                        worldCupId: widget.model.idx,
                        round: _selectedRound,
                      ),
                    );
                  },
                ),
                // 월드컵 수정 (샘플 월드컵이 아닌 경우에만 표시)
                if (widget.model.idx > 0)
                  IconOutlinedButton(
                    AppLocalizations.of(context).commonEdit,
                    Icons.edit,
                    Colors.orange,
                    onPressed: () {
                      Navigator.of(context)
                          .pushReplacementNamed(
                            AppRoutes.editor,
                            arguments: EditorArgs(worldCupId: widget.model.idx),
                          )
                          .then((_) => widget.onChanged());
                    },
                  ),
                // 월드컵 삭제
                IconOutlinedButton(
                  AppLocalizations.of(context).commonDelete,
                  Icons.delete,
                  Colors.red,
                  onPressed: () {
                    deleteWorldCup(
                      context,
                      ref.read(worldCupRepositoryProvider),
                      widget.model.idx,
                      widget.onChanged,
                    );
                  },
                ),
              ],
            ),
            if (widget.model.idx > 0) const Divider(height: 24),
            // 사용자가 만든 월드컵만 실제 데이터와 이미지를 공유한다.
            if (widget.model.idx > 0)
              Builder(
                builder: (buttonContext) => _isSharing
                    ? OutlinedButton(
                        onPressed: null,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            const SizedBox(width: 10),
                            Text(AppLocalizations.of(context).sharePreparing),
                          ],
                        ),
                      )
                    : IconOutlinedButton(
                        AppLocalizations.of(context).commonShare,
                        Icons.share,
                        Colors.blue,
                        onPressed: () => _showShareOptions(buttonContext),
                      ),
              ),
          ],
        ),
      ],
    );
  }

  Future<void> _showShareOptions(BuildContext buttonContext) async {
    final renderObject = buttonContext.findRenderObject();
    final sharePositionOrigin = renderObject is RenderBox
        ? renderObject.localToGlobal(Offset.zero) & renderObject.size
        : null;
    final choice = await showModalBottomSheet<_ShareChoice>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                AppLocalizations.of(context).shareChooseMethod,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.devices_other),
                title: Text(AppLocalizations.of(context).shareNearby),
                subtitle: Text(
                  AppLocalizations.of(context).shareNearbyDescription,
                ),
                onTap: () => Navigator.pop(context, _ShareChoice.nearby),
              ),
              ListTile(
                leading: const Icon(Icons.ios_share),
                title: Text(AppLocalizations.of(context).shareOtherApp),
                subtitle: Text(
                  AppLocalizations.of(context).shareOtherAppDescription,
                ),
                onTap: () => Navigator.pop(context, _ShareChoice.otherApp),
              ),
            ],
          ),
        ),
      ),
    );
    if (!mounted || choice == null) return;
    if (choice == _ShareChoice.nearby) {
      await Navigator.of(context).pushNamed<void>(
        AppRoutes.nearbySend,
        arguments: NearbySendArgs(worldCupId: widget.model.idx),
      );
      return;
    }
    await _shareWorldCup(sharePositionOrigin);
  }

  Future<void> _shareWorldCup(Rect? sharePositionOrigin) async {
    final WorldCupPackagePort packagePort =
        widget.packageGateway ?? ref.read(worldCupPackageProvider);
    setState(() => _isSharing = true);
    try {
      await packagePort.share(
        widget.model,
        title: AppLocalizations.of(context).shareFileTitle(
          AppLocalizations.of(context)
              .worldCupTitle(widget.model.idx, widget.model.title),
        ),
        subject: AppLocalizations.of(context).shareFileSubject(
          AppLocalizations.of(context)
              .worldCupTitle(widget.model.idx, widget.model.title),
        ),
        origin: sharePositionOrigin == null
            ? null
            : ShareOrigin(
                left: sharePositionOrigin.left,
                top: sharePositionOrigin.top,
                width: sharePositionOrigin.width,
                height: sharePositionOrigin.height,
              ),
      );
    } catch (error, stackTrace) {
      log(
        'Failed to share world cup package',
        error: error,
        stackTrace: stackTrace,
        name: 'worldcup_select_dialog',
      );
      if (!mounted) return;
      final message = error is Failure
          ? AppLocalizations.of(context).message(error.userMessage)
          : AppLocalizations.of(context).sharePackageFailed;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }
}

enum _ShareChoice { nearby, otherApp }

// 월드컵 삭제
Future<void> deleteWorldCup(
  BuildContext context,
  WorldCupRepository dao,
  int idx,
  VoidCallback onChanged,
) async {
  try {
    await dao.delete(idx);
  } catch (error) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).listDeleteFailed)),
    );
    return;
  }

  if (!context.mounted) return;
  onChanged();
  Navigator.of(context).pop();
}
