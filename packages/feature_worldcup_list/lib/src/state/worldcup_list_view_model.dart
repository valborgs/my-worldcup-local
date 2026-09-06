import 'package:flutter/foundation.dart';
import 'package:worldcup_domain/worldcup_domain.dart';

/// 목록 화면의 페이징 / 검색 상태.
///
/// 위젯에서 이 로직을 걷어내는 것이 핵심이다. 예전에는 페이저 로딩, 시트
/// 무한 스크롤, 검색이 모두 한 State 안의 플래그로 얽혀 있어, 페이저를
/// 고치는 사람과 검색을 고치는 사람이 반드시 충돌했다.
///
/// 위젯 생명주기(스크롤 컨트롤러, 포커스, 페이저 애니메이션)는 여기 없다.
/// 순수 Dart 객체이므로 위젯을 띄우지 않고 단위 테스트할 수 있다.
class WorldCupListViewModel extends ChangeNotifier {
  /// 한 번에 불러오는 항목 수.
  static const int pageSize = 10;

  final WorldCupRepository _repository;

  WorldCupListViewModel(this._repository, {List<WorldCupModel>? initialItems})
    : _pagerItems = List.of(initialItems ?? const []),
      _sheetItems = List.of(initialItems ?? const []);

  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  /// 이미 dispose 됐으면 알리지 않는다.
  ///
  /// 화면을 닫으면 ViewModel도 곧바로 dispose되는데, 그때 DB 조회가 아직
  /// 진행 중일 수 있다. 응답이 돌아와 그대로 알리면 ChangeNotifier가
  /// "used after being disposed"로 던진다. 위젯 시절의 mounted 검사가
  /// 하던 역할이다.
  void _notify() {
    if (_disposed) return;
    notifyListeners();
  }

  // --- 페이저 ---
  List<WorldCupModel> _pagerItems;
  int _pagerOffset = 0;
  bool _isLoadingPagerPage = false;

  /// 페이저가 들고 있는 항목. 전체가 아니라 선택 지점 주변의 창일 수 있다.
  List<WorldCupModel> get pagerItems => List.unmodifiable(_pagerItems);

  /// [pagerItems]의 첫 항목이 전체 목록에서 몇 번째인지.
  int get pagerOffset => _pagerOffset;

  // --- 시트 ---
  List<WorldCupModel> _sheetItems;
  int _totalCount = 0;
  bool _isLoadingSheetPage = false;

  /// 전체 월드컵 개수.
  int get totalCount => _totalCount;

  // --- 검색 ---
  bool _isSearching = false;
  String _query = '';
  List<WorldCupModel> _searchResults = [];
  int _searchTotalCount = 0;
  bool _isLoadingSearchPage = false;

  /// 검색 결과가 뒤늦게 도착해 최신 질의를 덮어쓰는 것을 막는 세대 번호.
  int _queryGeneration = 0;

  /// 검색 모드 여부. 시트가 무엇을 보여줄지 결정한다.
  bool get isSearching => _isSearching;

  String get query => _query;

  /// 시트에 보여줄 항목. 검색 중이면 검색 결과다.
  List<WorldCupModel> get sheetItems =>
      List.unmodifiable(_isSearching ? _searchResults : _sheetItems);

  /// 시트 헤더에 표시할 총 개수. 검색 중이면 검색 결과 총 개수다.
  int get sheetTotalCount => _isSearching ? _searchTotalCount : _totalCount;

  /// 목록이 완전히 비어 있는지(검색 결과 없음과는 구분된다).
  bool get isEmpty => _totalCount == 0 && _pagerItems.isEmpty && _query.isEmpty;

  // --- 조회 ---

  /// 전체를 다시 불러온다.
  ///
  /// 페이저가 보고 있던 위치를 최대한 유지한다. 항목을 추가한 직후에도
  /// 보던 카드가 그대로 있어야 하기 때문이다.
  Future<void> refresh() async {
    final sheetLimit = _sheetItems.length < pageSize
        ? pageSize
        : _sheetItems.length;
    final pagerLimit = _pagerItems.length < pageSize
        ? pageSize
        : _pagerItems.length;
    // 페이저가 첫 페이지를 보고 있고 더 많이 필요하면 한 번의 조회로 합친다.
    final firstPageLimit = _pagerOffset == 0 && pagerLimit > sheetLimit
        ? pagerLimit
        : sheetLimit;

    final results = await Future.wait([
      _repository.count(),
      _repository.page(limit: firstPageLimit, offset: 0),
    ]);
    if (_disposed) return;

    final totalCount = results[0] as int;
    final firstPageItems = results[1] as List<WorldCupModel>;

    final maxPagerOffset = totalCount > pagerLimit
        ? totalCount - pagerLimit
        : 0;
    final refreshedPagerOffset = _pagerOffset.clamp(0, maxPagerOffset);
    final refreshedPagerItems =
        refreshedPagerOffset == 0 && firstPageLimit >= pagerLimit
        ? firstPageItems.take(pagerLimit).toList()
        : await _repository.page(
            limit: pagerLimit,
            offset: refreshedPagerOffset,
          );

    if (_disposed) return;

    _totalCount = totalCount;
    _pagerOffset = refreshedPagerOffset;
    _pagerItems = refreshedPagerItems;
    _sheetItems = firstPageItems.take(sheetLimit).toList();
    _clearSearchState();
    _notify();
  }

  /// [worldCupIdx]가 페이저의 어느 자리인지 찾는다. 없으면 그 주변 창을
  /// 새로 불러와 교체한다.
  ///
  /// 창을 교체했으면 [PagerTarget.replacedWindow]가 참이다. 호출부는 그때
  /// 애니메이션 없이 곧바로 이동해야 한다.
  Future<PagerTarget?> locateInPager(int worldCupIdx) async {
    var targetIndex = _pagerItems.indexWhere((m) => m.idx == worldCupIdx);
    if (targetIndex >= 0) {
      return PagerTarget(targetIndex, replacedWindow: false);
    }

    final resolvedIndex = await _repository.indexOf(worldCupIdx);
    final maxWindowOffset = _totalCount > pageSize ? _totalCount - pageSize : 0;
    // 찾은 항목이 창 가운데 오도록 한다.
    final windowOffset = (resolvedIndex - (pageSize ~/ 2)).clamp(
      0,
      maxWindowOffset,
    );
    final window = await _repository.page(
      limit: pageSize,
      offset: windowOffset,
    );
    if (_disposed) return null;
    targetIndex = window.indexWhere((m) => m.idx == worldCupIdx);
    if (targetIndex < 0) return null;

    _pagerOffset = windowOffset;
    _pagerItems = window;
    _notify();
    return PagerTarget(targetIndex, replacedWindow: true);
  }

  /// 페이저의 다음 페이지를 이어 붙인다.
  Future<void> loadNextPagerPage() async {
    final offset = _pagerOffset + _pagerItems.length;
    if (_isLoadingPagerPage || offset >= _totalCount) return;
    _isLoadingPagerPage = true;
    // 조회 중에 창이 교체되면 결과를 버린다.
    final pagerOffset = _pagerOffset;
    final loadedCount = _pagerItems.length;
    try {
      final nextPage = await _repository.page(limit: pageSize, offset: offset);
      if (!_disposed &&
          _pagerOffset == pagerOffset &&
          _pagerItems.length == loadedCount) {
        _pagerItems = [..._pagerItems, ...nextPage];
        _notify();
      }
    } finally {
      _isLoadingPagerPage = false;
    }
  }

  /// 페이저 앞쪽 페이지를 앞에 붙인다. 창이 뒤로 밀려 있을 때만 의미가 있다.
  Future<void> loadPreviousPagerPage() async {
    if (_isLoadingPagerPage || _pagerOffset <= 0) return;
    _isLoadingPagerPage = true;
    final pagerOffset = _pagerOffset;
    final previousOffset = pagerOffset > pageSize ? pagerOffset - pageSize : 0;
    try {
      final previousPage = await _repository.page(
        limit: pagerOffset - previousOffset,
        offset: previousOffset,
      );
      if (!_disposed && _pagerOffset == pagerOffset) {
        _pagerOffset = previousOffset;
        _pagerItems = [...previousPage, ..._pagerItems];
        _notify();
      }
    } finally {
      _isLoadingPagerPage = false;
    }
  }

  /// 시트(또는 검색 결과)의 다음 페이지를 이어 붙인다.
  Future<void> loadNextSheetPage() async {
    if (_isSearching) return _loadNextSearchPage();

    final offset = _sheetItems.length;
    if (_isLoadingSheetPage || offset >= _totalCount) return;
    _isLoadingSheetPage = true;
    try {
      final nextPage = await _repository.page(limit: pageSize, offset: offset);
      if (!_disposed && _sheetItems.length == offset) {
        _sheetItems = [..._sheetItems, ...nextPage];
        _notify();
      }
    } finally {
      _isLoadingSheetPage = false;
    }
  }

  Future<void> _loadNextSearchPage() async {
    final offset = _searchResults.length;
    if (_isLoadingSearchPage || offset >= _searchTotalCount) return;
    _isLoadingSearchPage = true;
    final generation = _queryGeneration;
    final query = _query;
    try {
      final nextPage = await _repository.page(
        limit: pageSize,
        offset: offset,
        searchQuery: query,
      );
      // 조회 중에 질의가 바뀌었으면 결과를 버린다.
      if (!_disposed &&
          _isSearching &&
          generation == _queryGeneration &&
          query == _query &&
          _searchResults.length == offset) {
        _searchResults = [..._searchResults, ...nextPage];
        _notify();
      }
    } finally {
      _isLoadingSearchPage = false;
    }
  }

  // --- 검색 ---

  /// 검색 모드로 들어간다.
  ///
  /// 검색 결과를 현재 시트 항목으로 미리 채운다. 그렇게 하지 않으면 검색창을
  /// 여는 순간 목록이 비었다가 첫 조회 후 다시 채워져 깜빡인다.
  void startSearch() {
    if (_isSearching) return;
    _isSearching = true;
    _searchResults = List.of(_sheetItems);
    _searchTotalCount = _totalCount;
    _notify();
  }

  /// 검색 모드를 끝낸다. 실제로 끝냈으면 참을 돌려준다.
  bool stopSearch() {
    if (!_isSearching) return false;
    _clearSearchState();
    _notify();
    return true;
  }

  /// 검색어가 바뀌었다. 실제 조회는 호출부가 디바운스한 뒤 [runSearch]로
  /// 시작한다.
  void updateQuery(String value) {
    final trimmed = value.trim();
    if (trimmed == _query) return;
    _query = trimmed;
    _notify();
  }

  /// 현재 검색어로 첫 페이지를 불러온다.
  Future<void> runSearch() async {
    final generation = ++_queryGeneration;
    final query = _query;
    final results = await Future.wait([
      _repository.count(searchQuery: query),
      _repository.page(limit: pageSize, offset: 0, searchQuery: query),
    ]);
    // 뒤늦게 도착한 응답이 최신 질의 결과를 덮어쓰지 않도록 한다.
    if (_disposed || !_isSearching || generation != _queryGeneration) return;
    _searchTotalCount = results[0] as int;
    _searchResults = results[1] as List<WorldCupModel>;
    _notify();
  }

  void _clearSearchState() {
    // 세대를 올려 진행 중인 검색 응답을 무효화한다. 올리지 않으면 검색을
    // 닫았다 다시 열었을 때 닫기 전 응답이 새 화면을 덮어쓴다.
    _queryGeneration++;
    _isSearching = false;
    _query = '';
    _searchResults = [];
    _searchTotalCount = 0;
  }
}

/// 페이저에서 어떤 카드로 갈지, 그리고 창을 교체했는지.
class PagerTarget {
  final int index;

  /// 참이면 페이저가 들고 있던 항목 목록 자체가 교체됐다는 뜻이다.
  /// 이때는 애니메이션 없이 곧바로 그 자리로 옮겨야 한다.
  final bool replacedWindow;

  const PagerTarget(this.index, {required this.replacedWindow});
}
