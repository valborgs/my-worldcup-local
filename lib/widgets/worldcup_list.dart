import 'dart:async';
import 'dart:io';

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
  static const _pageSize = 10;
  static const _sheetHeaderHeight = 64.0;

  late List<WorldCupModel> worldCupList = widget.initialWorldCupList ?? [];
  final _sheetController = DraggableScrollableController();
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  Timer? _searchDebounce;
  int _allTotalCount = 0;
  int _totalCount = 0;
  bool _isLoadingPage = false;
  bool _isSearchMode = false;
  String _searchQuery = '';
  int _queryGeneration = 0;
  List<WorldCupModel> _itemsBeforeSearch = [];
  int _countBeforeSearch = 0;
  double _collapsedSheetSize = 0.1;

  @override
  void initState() {
    super.initState();
    _sheetController.addListener(_onSheetSizeChanged);
    refresh();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _sheetController.removeListener(_onSheetSizeChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    _sheetController.dispose();
    super.dispose();
  }

  void _onSheetSizeChanged() {
    if (!_sheetController.isAttached ||
        _sheetController.size > _collapsedSheetSize + 0.02) {
      return;
    }
    if (_isSearchMode) {
      closeSearchMode();
    } else if (_searchFocusNode.hasFocus) {
      _searchFocusNode.unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_allTotalCount == 0 && worldCupList.isEmpty && _searchQuery.isEmpty) {
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final hasSheet = _allTotalCount > 5;
          final minSheetSize = hasSheet
              ? (_sheetHeaderHeight / constraints.maxHeight).clamp(0.05, 0.25)
              : 0.0;
          _collapsedSheetSize = minSheetSize;
          return Stack(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                  0,
                  32,
                  0,
                  hasSheet ? _sheetHeaderHeight + 16 : 32,
                ),
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
                  onPageChanged: (_, index) {
                    if (index >= worldCupList.length - 3) _loadNextPage();
                  },
                  itemKey: (model) => model.idx,
                  semanticLabelBuilder: (model, index) {
                    final title =
                        model.idx < 0 ? '(샘플) ${model.title}' : model.title;
                    return '$title, 최대 라운드 ${makeMaxRound(model.maxRound)}강, '
                        '${index + 1} / $_totalCount';
                  },
                ),
              ),
              if (hasSheet)
                DraggableScrollableSheet(
                  controller: _sheetController,
                  initialChildSize: minSheetSize,
                  minChildSize: minSheetSize,
                  maxChildSize: 0.92,
                  snap: true,
                  snapSizes: [minSheetSize, 0.92],
                  builder: (context, scrollController) {
                    return Material(
                      elevation: 16,
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: NotificationListener<ScrollNotification>(
                        onNotification: (notification) {
                          if (notification.metrics.extentAfter < 240) {
                            _loadNextPage();
                          }
                          return false;
                        },
                        child: CustomScrollView(
                          controller: scrollController,
                          slivers: [
                            SliverPersistentHeader(
                              pinned: true,
                              delegate: _SheetHeaderDelegate(
                                extent: _isSearchMode
                                    ? _sheetHeaderHeight * 2
                                    : _sheetHeaderHeight,
                                child: ColoredBox(
                                  color: Theme.of(context).colorScheme.surface,
                                  child: Column(
                                    children: [
                                      _buildSheetHeader(minSheetSize),
                                      if (_isSearchMode)
                                        SizedBox(
                                          height: _sheetHeaderHeight,
                                          child: _buildSearchField(),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            if (worldCupList.isEmpty)
                              const SliverFillRemaining(
                                hasScrollBody: false,
                                child: Center(child: Text('검색 결과가 없습니다')),
                              )
                            else
                              SliverList.builder(
                                itemCount: worldCupList.length,
                                itemBuilder: (context, index) {
                                  return _WorldCupSheetItem(
                                    model: worldCupList[index],
                                    onTap: () => showDialogBeforeGameStart(
                                      context,
                                      worldCupList[index],
                                      refresh,
                                    ),
                                  );
                                },
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSheetHeader(double minSheetSize) {
    return Semantics(
      button: true,
      label: '전체 월드컵 목록 열기',
      child: InkWell(
        onTap: () {
          final isCollapsed = !_sheetController.isAttached ||
              _sheetController.size <= minSheetSize + 0.05;
          _sheetController.animateTo(
            isCollapsed ? 0.92 : minSheetSize,
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutCubic,
          );
        },
        child: SizedBox(
          width: double.infinity,
          height: _sheetHeaderHeight,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _searchQuery.isEmpty
                        ? '전체 목록 ($_totalCount)'
                        : '검색 결과 ($_totalCount)',
                  ),
                ],
              ),
              Positioned(
                right: 8,
                child: IconButton(
                  tooltip: _isSearchMode ? '검색 닫기' : '월드컵 검색',
                  onPressed: _isSearchMode
                      ? closeSearchMode
                      : () => _openSearch(minSheetSize),
                  icon: Icon(_isSearchMode ? Icons.close : Icons.search),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return ColoredBox(
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
        child: TextField(
          controller: _searchController,
          focusNode: _searchFocusNode,
          textInputAction: TextInputAction.search,
          onChanged: _onSearchChanged,
          decoration: InputDecoration(
            hintText: '월드컵 제목 또는 설명 검색',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _searchQuery.isEmpty
                ? null
                : IconButton(
                    tooltip: '검색어 지우기',
                    onPressed: () {
                      _searchController.clear();
                      _onSearchChanged('');
                    },
                    icon: const Icon(Icons.clear),
                  ),
            border: const OutlineInputBorder(),
            isDense: true,
          ),
        ),
      ),
    );
  }

  Future<void> _openSearch(double minSheetSize) async {
    _itemsBeforeSearch = List.of(worldCupList);
    _countBeforeSearch = _totalCount;
    setState(() => _isSearchMode = true);
    if (_sheetController.isAttached &&
        _sheetController.size <= minSheetSize + 0.05) {
      await _sheetController.animateTo(
        0.92,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    }
    if (mounted) _searchFocusNode.requestFocus();
  }

  bool closeSearchMode() {
    if (!_isSearchMode) return false;
    _searchDebounce?.cancel();
    _queryGeneration++;
    _searchFocusNode.unfocus();
    _searchController.clear();
    setState(() {
      _isSearchMode = false;
      _searchQuery = '';
      _totalCount = _countBeforeSearch;
      worldCupList = List.of(_itemsBeforeSearch);
    });
    return true;
  }

  bool handleBack() {
    if (closeSearchMode()) return true;
    if (!_sheetController.isAttached ||
        _sheetController.size <= _collapsedSheetSize + 0.01) {
      return false;
    }
    unawaited(
      _sheetController.animateTo(
        _collapsedSheetSize,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      ),
    );
    return true;
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    setState(() => _searchQuery = value.trim());
    _searchDebounce = Timer(
      const Duration(milliseconds: 300),
      () => _loadFirstPageForQuery(_searchQuery),
    );
  }

  Future<void> refresh() async {
    final db = WorldCupDao();
    final results = await Future.wait([
      db.getWorldCupCount(),
      db.getWorldCupPage(limit: _pageSize, offset: 0),
    ]);
    if (!mounted) return;
    setState(() {
      _allTotalCount = results[0] as int;
      _totalCount = _allTotalCount;
      worldCupList = results[1] as List<WorldCupModel>;
      _searchController.clear();
      _isSearchMode = false;
      _searchQuery = '';
    });
  }

  Future<void> _loadFirstPageForQuery(String query) async {
    final generation = ++_queryGeneration;
    final db = WorldCupDao();
    final results = await Future.wait([
      db.getWorldCupCount(searchQuery: query),
      db.getWorldCupPage(
        limit: _pageSize,
        offset: 0,
        searchQuery: query,
      ),
    ]);
    if (!mounted || generation != _queryGeneration) return;
    setState(() {
      _totalCount = results[0] as int;
      worldCupList = results[1] as List<WorldCupModel>;
    });
  }

  Future<void> _loadNextPage() async {
    if (_isLoadingPage || worldCupList.length >= _totalCount) return;
    _isLoadingPage = true;
    final generation = _queryGeneration;
    final query = _searchQuery;
    try {
      final nextPage = await WorldCupDao().getWorldCupPage(
        limit: _pageSize,
        offset: worldCupList.length,
        searchQuery: query,
      );
      if (mounted && generation == _queryGeneration && query == _searchQuery) {
        setState(() => worldCupList.addAll(nextPage));
      }
    } finally {
      _isLoadingPage = false;
    }
  }
}

class _SheetHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double extent;

  const _SheetHeaderDelegate({required this.child, required this.extent});

  @override
  double get minExtent => extent;

  @override
  double get maxExtent => extent;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  bool shouldRebuild(covariant _SheetHeaderDelegate oldDelegate) =>
      oldDelegate.child != child || oldDelegate.extent != extent;
}

class _WorldCupSheetItem extends StatelessWidget {
  final WorldCupModel model;
  final VoidCallback onTap;

  const _WorldCupSheetItem({required this.model, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final image = model.titleImageSrc.isEmpty
        ? Image.asset('assets/images/free_character.png', fit: BoxFit.cover)
        : model.idx < 0
            ? Image.asset(model.titleImageSrc, fit: BoxFit.cover)
            : Image.file(File(model.titleImageSrc), fit: BoxFit.cover);
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(width: 64, height: 64, child: image),
      ),
      title: Text(
        model.idx < 0 ? '(샘플) ${model.title}' : model.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text('최대 라운드 : ${makeMaxRound(model.maxRound)}강'),
    );
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
  late PageController _pageController;
  late int _currentPageIndex;
  Object? _currentItemKey;

  int get _safeInitialPage {
    if (widget.items.isEmpty) return 0;
    return widget.initialPage.clamp(0, widget.items.length - 1);
  }

  @override
  void initState() {
    super.initState();
    _currentPageIndex = _safeInitialPage;
    _pageController = PageController(initialPage: _currentPageIndex);
    _currentItemKey = _keyAt(_currentPageIndex);
  }

  @override
  void didUpdateWidget(covariant CoverFlowPager<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.items.isEmpty) return;
    final currentPage = _pageController.hasClients
        ? (_pageController.page ?? _currentPageIndex.toDouble()).round()
        : _currentPageIndex;
    final keyedIndex = _indexOfKey(_currentItemKey);
    final currentItemWasRemoved = widget.itemKey != null &&
        _currentItemKey != null &&
        keyedIndex < 0;
    final targetPage = keyedIndex >= 0
        ? keyedIndex
        : currentPage.clamp(0, widget.items.length - 1);
    _currentPageIndex = targetPage;
    _currentItemKey = _keyAt(targetPage);
    if (currentItemWasRemoved || targetPage != currentPage) {
      final previousController = _pageController;
      _pageController = PageController(
        initialPage: targetPage,
        keepPage: false,
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        previousController.dispose();
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
                  setState(() {
                    _currentPageIndex = index;
                    _currentItemKey = _keyAt(index);
                  });
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
    if (!_pageController.hasClients) return _currentPageIndex.toDouble();
    return _pageController.page ?? _currentPageIndex.toDouble();
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
