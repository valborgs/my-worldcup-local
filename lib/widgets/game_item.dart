import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/worldcup_item_model.dart';
import '../provider/worldcup_select_provider.dart';
import 'worldcup_game.dart';

// 게임 화면에서 대결하는 항목 하나를 표시하는 위젯.
// 기존 ItemTop / ItemBottom을 통합한 것으로, position으로 위/아래(또는 좌/우) 역할을,
// axis로 배치 방향(세로: 위/아래, 가로: 좌/우)을 구분한다.
class GameItem extends StatefulWidget {
  final WorldCupItemModel itemModel;
  final SelectedItemPosition position;
  final Axis axis;

  const GameItem(
    this.itemModel, {
    required this.position,
    required this.axis,
    super.key,
  });

  @override
  State<GameItem> createState() => _GameItemState();
}

class _GameItemState extends State<GameItem> with TickerProviderStateMixin {
  late AnimationController _controller;
  late Tween<Offset> _tween;
  late Animation<Offset> _animation;

  // 중복 탭 방지 (한 라운드에 한 번만 선택 가능)
  var _isTouchable = true;

  late WorldCupSelectProvider _selectProvider;

  void _resetController() {
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 1));
    _tween = Tween<Offset>(begin: const Offset(0, 0), end: const Offset(0, 0));
    _animation = _tween.animate(CurvedAnimation(parent: _controller, curve: Curves.decelerate));
  }

  @override
  void initState() {
    super.initState();
    _resetController();

    _selectProvider = Provider.of<WorldCupSelectProvider>(context, listen: false);
    _selectProvider.addListener(_onSelectionChanged);
  }

  void _onSelectionChanged() {
    // position 기준 부호: top(위/좌) 방향이 양수, bottom(아래/우) 방향이 음수
    final sign = (widget.position == SelectedItemPosition.top) ? 1.0 : -1.0;
    // 자신이 선택되었으면 살짝 안쪽으로, 아니면 화면 밖으로 밀려난다.
    final value = (_selectProvider.selectedItemPosition == widget.position) ? 0.5 * sign : -1.1 * sign;

    _tween.end = (widget.axis == Axis.vertical) ? Offset(0, value) : Offset(value, 0);
    _controller.forward();
  }

  @override
  void dispose() {
    _selectProvider.removeListener(_onSelectionChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_animation.status == AnimationStatus.completed) {
      _controller.reset();
      _resetController();
    }

    return Expanded(
      child: SlideTransition(
        position: _animation,
        child: InkWell(
          onTap: () {
            if (_isTouchable) {
              _isTouchable = false;
              _selectProvider.setSelectedItem(widget.position, widget.itemModel);
            }
          },
          child: Container(
            color: Colors.black,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final shortestSide = constraints.biggest.shortestSide;
                final fontSize = (shortestSide * 0.06).clamp(18.0, 34.0);
                final bottomInset = shortestSide * 0.08;

                return Stack(
                  alignment: Alignment.center,
                  children: [
                    widget.itemModel.worldCupIdx < 0
                        ? Image.asset(
                            widget.itemModel.imagePath,
                            fit: BoxFit.contain,
                          )
                        : Image.file(
                            File(widget.itemModel.imagePath),
                            fit: BoxFit.contain,
                          ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: EdgeInsets.only(bottom: bottomInset, left: 12, right: 12),
                        child: Text(
                          widget.itemModel.imageInfo,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: fontSize,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            backgroundColor: Colors.grey.withOpacity(0.5),
                          ),
                          semanticsLabel: "항목 이름",
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
