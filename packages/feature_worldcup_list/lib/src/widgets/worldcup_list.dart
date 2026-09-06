import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/worldcup_list_view_model.dart';
import 'cover_flow_pager.dart';
import 'worldcup_sheet.dart';
import 'worldcup_list_item.dart';

import 'package:worldcup_domain/worldcup_domain.dart';

class WorldCupList extends ConsumerStatefulWidget {
  final List<WorldCupModel>? initialWorldCupList;
  final bool enableBottomSheetSelectionPagerTransition;

  /// 테스트에서 저장소를 갈아끼우기 위한 훅.
  /// 비워두면 DI(`worldCupRepositoryProvider`)에서 받는다.
  final WorldCupRepository? repository;

  const WorldCupList({
    this.initialWorldCupList,
    required this.enableBottomSheetSelectionPagerTransition,
    this.repository,
    super.key,
  });

  @override
  ConsumerState<WorldCupList> createState() => WorldCupListState();
}

class WorldCupListState extends ConsumerState<WorldCupList> {
  static const _sheetHeaderHeight = 64.0;

  /// 페이징 / 검색 상태. 조회와 관련된 모든 결정은 여기서 한다.
  late final WorldCupListViewModel _vm = WorldCupListViewModel(
    widget.repository ?? ref.read(worldCupRepositoryProvider),
    initialItems: widget.initialWorldCupList,
  );

  // 아래는 위젯 생명주기에 묶인 것들이라 ViewModel로 옮기지 않는다.
  final _pagerKey = GlobalKey<CoverFlowPagerState<WorldCupModel>>();
  final _sheetController = DraggableScrollableController();
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  Timer? _searchDebounce;
  bool _isSearchCloseScheduled = false;
  bool _isHandlingSheetItemTap = false;
  bool _isPagerTransitionInFlight = false;
  int _pagerNavigationRequest = 0;
  int? _pagerTargetPage;
  double _collapsedSheetSize = 0.1;

  // ViewModel 상태를 기존 이름으로 읽는 통로. build()가 그대로 쓰인다.
  List<WorldCupModel> get worldCupList => _vm.pagerItems;
  int get _allTotalCount => _vm.totalCount;
  int get _pagerOffset => _vm.pagerOffset;
  String get _searchQuery => _vm.query;
  bool get _isSearchMode => _vm.isSearching;
  List<WorldCupModel> get _sheetItems => _vm.sheetItems;
  int get _sheetTotalCount => _vm.sheetTotalCount;

  @override
  void initState() {
    super.initState();
    _vm.addListener(_onViewModelChanged);
    _sheetController.addListener(_onSheetSizeChanged);
    refresh();
  }

  void _onViewModelChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _vm.removeListener(_onViewModelChanged);
    _vm.dispose();
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
    if (_isHandlingSheetItemTap) return;
    if (_isSearchMode) {
      _scheduleCloseSearchMode();
    } else if (_searchFocusNode.hasFocus) {
      _searchFocusNode.unfocus();
    }
  }

  void _scheduleCloseSearchMode() {
    if (_isSearchCloseScheduled) return;
    _isSearchCloseScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _isSearchCloseScheduled = false;
      if (!mounted || _isHandlingSheetItemTap || !_isSearchMode) return;
      if (!_sheetController.isAttached ||
          _sheetController.size > _collapsedSheetSize + 0.02) {
        return;
      }
      closeSearchMode();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_vm.isEmpty) {
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
                  key: _pagerKey,
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
                    if (_isPagerTransitionInFlight) return;
                    _prefetchAroundPagerIndex(index);
                  },
                  onScrollEnd: _vm.trimDeferredPagerWindow,
                  itemKey: (model) => model.idx,
                  targetPage: _pagerTargetPage,
                  navigationRequest: _pagerNavigationRequest,
                  semanticLabelBuilder: (model, index) {
                    final title = model.idx < 0
                        ? '(샘플) ${model.title}'
                        : model.title;
                    return '$title, 최대 라운드 ${TournamentRounds.defaultRound(model.maxRound)}강, '
                        '${_pagerOffset + index + 1} / $_allTotalCount';
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
                            unawaited(_vm.loadNextSheetPage());
                          }
                          return false;
                        },
                        child: CustomScrollView(
                          controller: scrollController,
                          slivers: [
                            SliverPersistentHeader(
                              pinned: true,
                              delegate: SheetHeaderDelegate(
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
                            if (_sheetItems.isEmpty)
                              const SliverFillRemaining(
                                hasScrollBody: false,
                                child: Center(child: Text('검색 결과가 없습니다')),
                              )
                            else
                              SliverList.builder(
                                itemCount: _sheetItems.length,
                                itemBuilder: (context, index) {
                                  final model = _sheetItems[index];
                                  return WorldCupSheetItem(
                                    model: model,
                                    onTap: () =>
                                        unawaited(_handleSheetItemTap(model)),
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
          final isCollapsed =
              !_sheetController.isAttached ||
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
                        ? '전체 목록 ($_sheetTotalCount)'
                        : '검색 결과 ($_sheetTotalCount)',
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
    _vm.startSearch();
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
    if (!mounted || !_vm.isSearching) return false;
    _searchDebounce?.cancel();
    _searchFocusNode.unfocus();
    _searchController.clear();
    return _vm.stopSearch();
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

  Future<void> _handleSheetItemTap(WorldCupModel model) async {
    if (_isHandlingSheetItemTap) return;
    _isHandlingSheetItemTap = true;

    try {
      if (!widget.enableBottomSheetSelectionPagerTransition) {
        await showDialogBeforeGameStart(context, model, refresh);
        return;
      }

      _searchFocusNode.unfocus();
      if (_sheetController.isAttached &&
          _sheetController.size > _collapsedSheetSize + 0.01) {
        await _sheetController.animateTo(
          _collapsedSheetSize,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
        );
      }
      if (!mounted) return;

      final target = await _findOrLoadPagerIndex(model);
      if (!mounted || target == null) return;

      await _navigateToPagerTarget(target);
      if (target.replacedWindow) {
        await WidgetsBinding.instance.endOfFrame;
      }
      if (!mounted) return;
      await showDialogBeforeGameStart(context, model, refresh);
    } finally {
      _isHandlingSheetItemTap = false;
    }
  }

  Future<PagerTarget?> _findOrLoadPagerIndex(WorldCupModel selectedModel) =>
      _findOrLoadPagerIndexById(selectedModel.idx);

  Future<PagerTarget?> _findOrLoadPagerIndexById(int worldCupIdx) async {
    closeSearchMode();
    final target = await _vm.locateInPager(worldCupIdx);
    if (!mounted) return null;
    return target;
  }

  Future<void> refreshAndScrollTo(int worldCupIdx) async {
    await refresh();
    if (!mounted) return;

    final target = await _findOrLoadPagerIndexById(worldCupIdx);
    if (!mounted || target == null) return;

    await _navigateToPagerTarget(target);
  }

  Future<void> _navigateToPagerTarget(PagerTarget target) async {
    if (target.replacedWindow) {
      _movePagerToPage(target.index);
      return;
    }

    // A refresh may have rebuilt the existing window with a newly added item.
    // Wait until the pager sees that item before starting the transition.
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    _isPagerTransitionInFlight = true;
    try {
      await _pagerKey.currentState?.scrollToPage(target.index);
    } finally {
      _isPagerTransitionInFlight = false;
    }
    if (!mounted) return;
    final settledIndex = _pagerKey.currentState?.currentPageIndex ?? 0;
    _prefetchAroundPagerIndex(settledIndex);
  }

  void _prefetchAroundPagerIndex(int index) {
    if (index >= worldCupList.length - 3) {
      unawaited(_loadNextPagerPage());
    }
    if (index <= 2) {
      unawaited(_loadPreviousPagerPage());
    }
  }

  Future<void> _loadNextPagerPage() async {
    final deferTrim = _pagerKey.currentState?.isScrolling ?? false;
    await _vm.loadNextPagerPage(deferTrim: deferTrim);
    if (!mounted || (_pagerKey.currentState?.isScrolling ?? false)) return;
    _vm.trimDeferredPagerWindow();
  }

  Future<void> _loadPreviousPagerPage() async {
    final deferTrim = _pagerKey.currentState?.isScrolling ?? false;
    await _vm.loadPreviousPagerPage(deferTrim: deferTrim);
    if (!mounted || (_pagerKey.currentState?.isScrolling ?? false)) return;
    _vm.trimDeferredPagerWindow();
  }

  void _movePagerToPage(int targetIndex) {
    setState(() {
      _pagerTargetPage = targetIndex;
      _pagerNavigationRequest++;
    });
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _vm.updateQuery(value);
    // 타이핑마다 조회하지 않도록 잠시 기다린다.
    _searchDebounce = Timer(
      const Duration(milliseconds: 300),
      () => unawaited(_vm.runSearch()),
    );
  }

  Future<void> refresh() async {
    final currentPagerIndex = _pagerKey.currentState?.currentPageIndex ?? 0;
    await _vm.refresh();
    if (!mounted) return;
    // 검색 입력창은 위젯이 들고 있으므로 여기서 비운다.
    _searchController.clear();

    // 새로고침으로 목록 길이가 달라졌을 수 있어, 끝에 닿아 있으면 이어 불러온다.
    if (currentPagerIndex >= worldCupList.length - 3) {
      await _loadNextPagerPage();
    }
  }
}
