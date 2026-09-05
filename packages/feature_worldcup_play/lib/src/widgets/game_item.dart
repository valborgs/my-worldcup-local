import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worldcup_domain/worldcup_domain.dart';

import '../state/match_selection.dart';

// 게임 화면에서 대결하는 항목 하나를 표시하는 위젯.
// 기존 ItemTop / ItemBottom을 통합한 것으로, position으로 위/아래(또는 좌/우) 역할을,
// axis로 배치 방향(세로: 위/아래, 가로: 좌/우)을 구분한다.
class GameItem extends ConsumerStatefulWidget {
  final WorldCupItemModel itemModel;
  final SelectedItemPosition position;
  final Axis axis;
  final int matchId;

  const GameItem(
    this.itemModel, {
    required this.position,
    required this.axis,
    required this.matchId,
    super.key,
  });

  @override
  ConsumerState<GameItem> createState() => _GameItemState();
}

class _GameItemState extends ConsumerState<GameItem>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Tween<Offset> _tween;
  late Animation<Offset> _animation;

  void _initializeAnimation() {
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _tween = Tween<Offset>(begin: const Offset(0, 0), end: const Offset(0, 0));
    _animation = _tween.animate(
      CurvedAnimation(parent: _controller, curve: Curves.decelerate),
    );
  }

  @override
  void initState() {
    super.initState();
    _initializeAnimation();

    // 선택 변화에 애니메이션으로만 반응한다. 위젯을 다시 그리지는 않으므로
    // watch가 아니라 명령형 구독을 쓴다. 구독은 dispose에서 자동 해제된다.
    ref.listenManual<MatchSelection>(
      matchSelectionProvider,
      (previous, next) => _onSelectionChanged(next),
    );
  }

  @override
  void didUpdateWidget(covariant GameItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.matchId != widget.matchId || oldWidget.axis != widget.axis) {
      // 같은 승자가 다음 대결에서도 같은 key/위치로 배치되면 State가 재사용된다.
      // matchId로 실제 대결 전환을 구분해 직전 애니메이션만 초기화한다.
      _controller.reset();
      _tween.begin = Offset.zero;
      _tween.end = Offset.zero;
    }
  }

  void _onSelectionChanged(MatchSelection selection) {
    // 다음 대결을 위한 초기화 알림은 무시한다. 여기서 반응하면 두 항목 모두
    // "선택되지 않음"으로 보여 화면 밖으로 밀려나는 애니메이션이 잘못
    // 재생된다.
    if (!selection.hasSelected) return;

    // position 기준 부호: top(위/좌) 방향이 양수, bottom(아래/우) 방향이 음수
    final sign = (widget.position == SelectedItemPosition.top) ? 1.0 : -1.0;
    // 자신이 선택되었으면 살짝 안쪽으로, 아니면 화면 밖으로 밀려난다.
    final value = (selection.position == widget.position)
        ? 0.5 * sign
        : -1.1 * sign;

    _tween.end = (widget.axis == Axis.vertical)
        ? Offset(0, value)
        : Offset(value, 0);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: SlideTransition(
        position: _animation,
        child: InkWell(
          onTap: () {
            // 중복 탭 방지 (한 대결에 한 번만 선택 가능).
            // 탭 가능 여부는 라운드 전환 시점에 WorldCupGame.setGame()이
            // 초기화하는 선택 상태를 기준으로 판단한다.
            if (!ref.read(matchSelectionProvider).hasSelected) {
              ref
                  .read(matchSelectionProvider.notifier)
                  .select(widget.position, widget.itemModel);
            }
          },
          child: Container(
            color: Colors.black,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final shortestSide = constraints.biggest.shortestSide;
                final fontSize = (shortestSide * 0.06).clamp(18.0, 34.0);
                final bottomInset = shortestSide * 0.08;
                // BoxFit.contain 기준으로 가로/세로 중 어느 쪽이 제약이 될지 알 수 없으므로
                // 박스의 긴 변을 기준으로 캐시 크기를 잡아 화질 저하 없이 상한만 둔다.
                final cacheDimension =
                    (constraints.biggest.longestSide *
                            MediaQuery.of(context).devicePixelRatio)
                        .round();

                return Stack(
                  alignment: Alignment.center,
                  children: [
                    widget.itemModel.worldCupIdx < 0
                        ? Image.asset(
                            widget.itemModel.imagePath,
                            fit: BoxFit.contain,
                            cacheWidth: cacheDimension,
                          )
                        : Image.file(
                            File(widget.itemModel.imagePath),
                            fit: BoxFit.contain,
                            cacheWidth: cacheDimension,
                          ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: EdgeInsets.only(
                          bottom: bottomInset,
                          left: 12,
                          right: 12,
                        ),
                        child: Text(
                          widget.itemModel.imageInfo,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: fontSize,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            backgroundColor: Colors.grey.withValues(alpha: 0.5),
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
