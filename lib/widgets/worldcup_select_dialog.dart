import 'dart:developer';

import 'package:flutter/material.dart';

import '../dto/worldcup_dao.dart';
import '../models/worldcup_model.dart';
import '../screens/play_worldcup_screen.dart';
import '../screens/add_worldcup_screen.dart';
import '../services/worldcup_package_service.dart';
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
  late int _selectedRound;
  bool _isSharing = false;

  @override
  void initState() {
    super.initState();
    _selectedRound = makeMaxRound(widget.model.maxRound);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      title: Text(
        widget.model.title,
        semanticsLabel: "월드컵 제목",
      ),
      content: ConstrainedBox(
        key: const Key('worldCupDialogContent'),
        constraints: const BoxConstraints(minHeight: 200),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Text(
              widget.model.info,
              semanticsLabel: "월드컵 설명",
            ),
            const SizedBox(height: 16),
            const Text("- 라운드 수를 선택해주세요- "),
            const SizedBox(height: 5),
            DropdownMenu(
              initialSelection: makeMaxRound(widget.model.maxRound),
              menuStyle: const MenuStyle(
                  padding: WidgetStatePropertyAll(EdgeInsets.all(0))),
              dropdownMenuEntries: makeRoundList(widget.model.maxRound)
                  .map<DropdownMenuEntry<int>>((int value) {
                return DropdownMenuEntry<int>(value: value, label: '$value 강');
              }).toList(),
              onSelected: (value) {
                if (value != null) _selectedRound = value;
              },
            ),
          ],
        ),
      ),
      actions: [
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              runSpacing: 8,
              children: [
                // 월드컵 게임 시작
                IconOutlinedButton(
                  "시작",
                  Icons.play_arrow,
                  Colors.deepPurpleAccent,
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => PlayWorldCupScreen(
                          widget.model,
                          _selectedRound,
                        ),
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
                    deleteWorldCup(
                      context,
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
                    ? const OutlinedButton(
                        onPressed: null,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 10),
                            Text('공유 파일 준비 중...'),
                          ],
                        ),
                      )
                    : IconOutlinedButton(
                        "공유하기",
                        Icons.share,
                        Colors.blue,
                        onPressed: () => _shareWorldCup(buttonContext),
                      ),
              ),
          ],
        ),
      ],
    );
  }

  Future<void> _shareWorldCup(BuildContext buttonContext) async {
    final renderObject = buttonContext.findRenderObject();
    final sharePositionOrigin = renderObject is RenderBox
        ? renderObject.localToGlobal(Offset.zero) & renderObject.size
        : null;

    setState(() => _isSharing = true);
    try {
      await WorldCupPackageService().shareWorldCup(
        widget.model,
        sharePositionOrigin: sharePositionOrigin,
      );
    } catch (error, stackTrace) {
      log(
        'Failed to share world cup package',
        error: error,
        stackTrace: stackTrace,
        name: 'worldcup_select_dialog',
      );
      if (!mounted) return;
      final message = error is WorldCupPackageException
          ? error.message
          : '월드컵을 공유할 수 없습니다. 잠시 후 다시 시도해주세요.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
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
