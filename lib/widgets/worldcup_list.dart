import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:my_worldcup_local/dto/worldcup_dao.dart';
import 'package:my_worldcup_local/tools/make_round.dart';
import 'package:my_worldcup_local/widgets/worldcup_list_item.dart';

import '../models/worldcup_model.dart';

class WorldCupList extends StatefulWidget {
  final List<WorldCupModel>? initialWorldCupList;

  const WorldCupList({this.initialWorldCupList, super.key});

  @override
  State<WorldCupList> createState() => WorldCupListState();
}

class WorldCupListState extends State<WorldCupList> {
  late List<WorldCupModel> worldCupList = widget.initialWorldCupList ?? [];

  @override
  void initState() {
    super.initState();
    refresh();
  }

  @override
  Widget build(BuildContext context) {
    if (worldCupList.isEmpty) {
      return Expanded(
        child: Container(
          alignment: Alignment.center,
          child: const Text(
            '오른쪽 상단의 + 버튼을 눌러 \n월드컵 게임을 추가해주세요',
            style: TextStyle(fontSize: 20),
            semanticsLabel: '항목이 비어있음',
          ),
        ),
      );
    }

    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 32),
        child: CoverFlowPager<WorldCupModel>(
          items: worldCupList,
          itemBuilder: (context, model, index) {
            return Card(
              margin: EdgeInsets.zero,
              clipBehavior: Clip.antiAlias,
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: WorldCupListItem(model),
            );
          },
          onCurrentItemTap: (context, model, index) {
            showDialogBeforeGameStart(context, model, refresh);
          },
          itemKey: (model) => model.idx,
          semanticLabelBuilder: (model, index) {
            final title = model.idx < 0 ? '(샘플) ${model.title}' : model.title;
            return '$title, 최대 라운드 ${makeMaxRound(model.maxRound)}강, '
                '${index + 1} / ${worldCupList.length}';
          },
        ),
      ),
    );
  }

  Future<void> refresh() async {
    final db = WorldCupDao();
    final newList = await db.getWorldCupList();
    if (!mounted) return;
    setState(() => worldCupList = newList);
  }
}

class CoverFlowPager<T> extends StatefulWidget {
  final List<T> items;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final void Function(BuildContext context, T item, int index)?
      onCurrentItemTap;
  final void Function(T item, int index)? onPageChanged;
  final Object Function(T item)? itemKey;
  final String Function(T item, int index)? semanticLabelBuilder;
  final int initialPage;
  final double cardAspectRatio;
  final double cardWidthFactor;
  final double horizontalSpacingFactor;
  final double sideScale;
  final double sideOpacity;
  final double sideTranslateY;
  final int visibleSideCount;
  final Duration scrollDuration;
  final Curve scrollCurve;

  const CoverFlowPager({
    required this.items,
    required this.itemBuilder,
    this.onCurrentItemTap,
    this.onPageChanged,
    this.itemKey,
    this.semanticLabelBuilder,
    this.initialPage = 0,
    this.cardAspectRatio = 3 / 4,
    this.cardWidthFactor = 0.72,
    this.horizontalSpacingFactor = 0.56,
    this.sideScale = 0.82,
    this.sideOpacity = 0.65,
    this.sideTranslateY = 16,
    this.visibleSideCount = 2,
    this.scrollDuration = const Duration(milliseconds: 350),
    this.scrollCurve = Curves.easeOutCubic,
    super.key,
  });

  @override
  State<CoverFlowPager<T>> createState() => _CoverFlowPagerState<T>();
}

class _CoverFlowPagerState<T> extends State<CoverFlowPager<T>> {
  late final PageController _pageController;
  Object? _currentItemKey;

  int get _safeInitialPage {
    if (widget.items.isEmpty) return 0;
    return widget.initialPage.clamp(0, widget.items.length - 1);
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _safeInitialPage);
    _currentItemKey = _keyAt(_safeInitialPage);
  }

  @override
  void didUpdateWidget(covariant CoverFlowPager<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.items.isEmpty || !_pageController.hasClients) return;
    final currentPage = (_pageController.page ?? _safeInitialPage).round();
    final keyedIndex = _indexOfKey(_currentItemKey);
    final targetPage = keyedIndex >= 0
        ? keyedIndex
        : currentPage.clamp(0, widget.items.length - 1);
    _currentItemKey = _keyAt(targetPage);
    if (targetPage != currentPage) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_pageController.hasClients || widget.items.isEmpty) return;
        _pageController.jumpToPage(targetPage);
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            ExcludeSemantics(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _pageController,
                  builder: (context, child) {
                    return Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: _buildCards(
                        context: context,
                        currentPage: _currentPage,
                        availableWidth: constraints.maxWidth,
                        availableHeight: constraints.maxHeight,
                      ),
                    );
                  },
                ),
              ),
            ),
            ScrollConfiguration(
              behavior: const _CoverFlowScrollBehavior(),
              child: PageView.builder(
                key: const ValueKey('worldCupPager'),
                controller: _pageController,
                itemCount: widget.items.length,
                physics: const PageScrollPhysics(),
                onPageChanged: (index) {
                  setState(() => _currentItemKey = _keyAt(index));
                  widget.onPageChanged?.call(widget.items[index], index);
                },
                itemBuilder: (context, index) {
                  return GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTapUp: (details) => _handleTap(
                      context,
                      _viewportPosition(details.globalPosition),
                    ),
                    child: const SizedBox.expand(),
                  );
                },
              ),
            ),
            _buildAccessibilityControls(context),
          ],
        );
      },
    );
  }

  double get _currentPage {
    if (!_pageController.hasClients) return _safeInitialPage.toDouble();
    return _pageController.page ?? _safeInitialPage.toDouble();
  }

  List<Widget> _buildCards({
    required BuildContext context,
    required double currentPage,
    required double availableWidth,
    required double availableHeight,
  }) {
    final startIndex = (currentPage.floor() - widget.visibleSideCount)
        .clamp(0, widget.items.length - 1);
    final endIndex = (currentPage.ceil() + widget.visibleSideCount)
        .clamp(0, widget.items.length - 1);
    final indexes = [for (var i = startIndex; i <= endIndex; i++) i]
      ..sort((a, b) =>
          (b - currentPage).abs().compareTo((a - currentPage).abs()));

    return indexes.map((index) {
      final geometry = _cardGeometry(
        index: index,
        currentPage: currentPage,
        viewportSize: Size(availableWidth, availableHeight),
      );
      return Transform.translate(
        offset: geometry.translation,
        child: Transform.scale(
          scale: geometry.scale,
          child: Opacity(
            opacity: geometry.opacity,
            child: RepaintBoundary(
              child: SizedBox(
                key: ValueKey('coverFlowCard-$index'),
                width: geometry.unscaledSize.width,
                height: geometry.unscaledSize.height,
                child: widget.itemBuilder(context, widget.items[index], index),
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  void _handleTap(BuildContext context, Offset position) {
    if (this.context.size == null) return;
    final currentPage = _currentPage;
    final tappedIndex = _findTappedCard(position, currentPage);
    if (tappedIndex == null) return;

    final currentIndex = currentPage.round().clamp(0, widget.items.length - 1);
    if (tappedIndex == currentIndex) {
      if ((currentPage - currentIndex).abs() >= 0.01) {
        _scrollToPage(currentIndex);
        return;
      }
      widget.onCurrentItemTap
          ?.call(context, widget.items[currentIndex], currentIndex);
      return;
    }
    _scrollToPage(tappedIndex);
  }

  int? _findTappedCard(Offset position, double currentPage) {
    final size = context.size;
    if (size == null) return null;
    final startIndex = (currentPage.floor() - widget.visibleSideCount)
        .clamp(0, widget.items.length - 1);
    final endIndex = (currentPage.ceil() + widget.visibleSideCount)
        .clamp(0, widget.items.length - 1);
    final indexes = [for (var i = startIndex; i <= endIndex; i++) i]
      ..sort((a, b) =>
          (a - currentPage).abs().compareTo((b - currentPage).abs()));
    for (final index in indexes) {
      final geometry = _cardGeometry(
        index: index,
        currentPage: currentPage,
        viewportSize: size,
      );
      if (geometry.rect.contains(position)) return index;
    }
    return null;
  }

  Size _cardSize(double availableWidth, double availableHeight) {
    final double widthFromViewport =
        availableWidth * widget.cardWidthFactor;
    final double widthFromHeight = availableHeight * widget.cardAspectRatio;
    final double cardWidth = widthFromViewport < widthFromHeight
        ? widthFromViewport
        : widthFromHeight;
    return Size(cardWidth, cardWidth / widget.cardAspectRatio);
  }

  _CardGeometry _cardGeometry({
    required int index,
    required double currentPage,
    required Size viewportSize,
  }) {
    final difference = index - currentPage;
    final distance = difference.abs().clamp(0.0, 1.0);
    final scale = 1 - distance * (1 - widget.sideScale);
    final opacity = 1 - distance * (1 - widget.sideOpacity);
    final unscaledSize = _cardSize(viewportSize.width, viewportSize.height);
    final translation = Offset(
      difference * viewportSize.width * widget.horizontalSpacingFactor,
      distance * widget.sideTranslateY,
    );
    return _CardGeometry(
      unscaledSize: unscaledSize,
      translation: translation,
      scale: scale,
      opacity: opacity,
      viewportSize: viewportSize,
    );
  }

  Offset _viewportPosition(Offset globalPosition) {
    final renderObject = context.findRenderObject();
    if (renderObject is! RenderBox) return Offset.zero;
    return renderObject.globalToLocal(globalPosition);
  }

  Widget _buildAccessibilityControls(BuildContext context) {
    final currentIndex = _currentPage.round().clamp(0, widget.items.length - 1);
    final label = widget.semanticLabelBuilder
            ?.call(widget.items[currentIndex], currentIndex) ??
        '월드컵 ${currentIndex + 1} / ${widget.items.length}';
    return Semantics(
      container: true,
      button: true,
      label: label,
      hint: '두 번 탭하여 현재 월드컵을 열거나 위아래로 쓸어 넘기세요',
      onTap: () => widget.onCurrentItemTap
          ?.call(context, widget.items[currentIndex], currentIndex),
      onIncrease: currentIndex < widget.items.length - 1
          ? () => _scrollToPage(currentIndex + 1)
          : null,
      onDecrease:
          currentIndex > 0 ? () => _scrollToPage(currentIndex - 1) : null,
      child: const ExcludeSemantics(child: SizedBox.expand()),
    );
  }

  Object? _keyAt(int index) {
    if (widget.items.isEmpty || widget.itemKey == null) return null;
    return widget.itemKey!(widget.items[index]);
  }

  int _indexOfKey(Object? key) {
    if (key == null || widget.itemKey == null) return -1;
    return widget.items.indexWhere((item) => widget.itemKey!(item) == key);
  }

  Future<void> _scrollToPage(int index) async {
    if (!_pageController.hasClients) return;
    await _pageController.animateToPage(
      index.clamp(0, widget.items.length - 1),
      duration: widget.scrollDuration,
      curve: widget.scrollCurve,
    );
  }
}

class _CoverFlowScrollBehavior extends MaterialScrollBehavior {
  const _CoverFlowScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.stylus,
        PointerDeviceKind.trackpad,
      };
}

class _CardGeometry {
  final Size unscaledSize;
  final Offset translation;
  final double scale;
  final double opacity;
  final Size viewportSize;

  const _CardGeometry({
    required this.unscaledSize,
    required this.translation,
    required this.scale,
    required this.opacity,
    required this.viewportSize,
  });

  Rect get rect => Rect.fromCenter(
        center: viewportSize.center(Offset.zero) + translation,
        width: unscaledSize.width * scale,
        height: unscaledSize.height * scale,
      );
}
