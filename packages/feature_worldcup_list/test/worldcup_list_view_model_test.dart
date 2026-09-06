import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:feature_worldcup_list/src/state/worldcup_list_view_model.dart';
import 'package:worldcup_domain/worldcup_domain.dart';

/// ViewModel은 위젯 없이 검증한다. 페이저 로딩 / 시트 무한 스크롤 / 검색이
/// 예전에는 한 State 안에서 얽혀 있어 위젯을 띄워야만 확인할 수 있었다.
void main() {
  List<WorldCupModel> models(int count, {int from = 1}) => [
    for (var i = from; i < from + count; i++)
      WorldCupModel(i, 'Game $i', '설명 $i', DateTime(2026), '', 4),
  ];

  group('검색', () {
    test('검색 모드에 들어가면 현재 시트 항목으로 미리 채운다', () async {
      final repo = _FakeRepository(models(20));
      final vm = WorldCupListViewModel(repo);
      addTearDown(vm.dispose);
      await vm.refresh();

      vm.startSearch();

      // 미리 채우지 않으면 검색창을 여는 순간 목록이 비었다가 다시 채워진다.
      expect(vm.isSearching, isTrue);
      expect(vm.sheetItems, isNotEmpty);
      expect(vm.sheetTotalCount, 20);
    });

    test('검색을 끝내면 전체 목록으로 돌아간다', () async {
      final repo = _FakeRepository(models(20));
      final vm = WorldCupListViewModel(repo);
      addTearDown(vm.dispose);
      await vm.refresh();
      vm.startSearch();
      vm.updateQuery('Game 1');
      await vm.runSearch();

      expect(vm.stopSearch(), isTrue);
      expect(vm.isSearching, isFalse);
      expect(vm.query, isEmpty);
      expect(vm.sheetTotalCount, 20);
    });

    test('검색 중이 아니면 stopSearch가 아무 일도 하지 않는다', () {
      final vm = WorldCupListViewModel(_FakeRepository(models(3)));
      addTearDown(vm.dispose);
      expect(vm.stopSearch(), isFalse);
    });

    test('뒤늦게 도착한 이전 검색 결과가 최신 결과를 덮어쓰지 않는다', () async {
      final repo = _FakeRepository(models(20));
      final vm = WorldCupListViewModel(repo);
      addTearDown(vm.dispose);
      vm.startSearch();

      // 첫 질의를 붙잡아 둔 채로 두 번째 질의를 시작한다.
      repo.blockNextPage();
      vm.updateQuery('오래된 질의');
      final stale = vm.runSearch();

      vm.updateQuery('최신 질의');
      await vm.runSearch();
      final latest = vm.sheetItems;

      repo.releaseBlocked();
      await stale;

      expect(vm.query, '최신 질의');
      expect(vm.sheetItems, latest, reason: '늦게 온 응답이 최신 결과를 덮어썼다');
    });

    test('검색을 닫았다 다시 열면 이전 검색 응답이 덮어쓰지 않는다', () async {
      // 닫기가 세대를 올리지 않으면, 다시 연 검색 화면을 이전 응답이 덮는다.
      final repo = _FakeRepository(models(20));
      final vm = WorldCupListViewModel(repo);
      addTearDown(vm.dispose);
      await vm.refresh();

      vm.startSearch();
      repo.blockNextPage();
      vm.updateQuery('오래된 질의');
      final stale = vm.runSearch();

      vm.stopSearch();
      vm.startSearch();
      final afterReopen = vm.sheetItems;

      repo.releaseBlocked();
      await stale;

      expect(
        vm.sheetItems,
        afterReopen,
        reason: '닫기 전에 보낸 검색 응답이 다시 연 화면을 덮어썼다',
      );
    });

    test('검색 결과 페이지를 이어 붙인다', () async {
      final repo = _FakeRepository(models(25));
      final vm = WorldCupListViewModel(repo);
      addTearDown(vm.dispose);
      vm.startSearch();
      vm.updateQuery('Game');
      await vm.runSearch();
      expect(vm.sheetItems, hasLength(WorldCupListViewModel.pageSize));

      await vm.loadNextSheetPage();

      expect(vm.sheetItems, hasLength(WorldCupListViewModel.pageSize * 2));
    });
  });

  group('페이저 페이징', () {
    test('다음 페이지를 이어 붙인다', () async {
      final vm = WorldCupListViewModel(_FakeRepository(models(25)));
      addTearDown(vm.dispose);
      await vm.refresh();
      expect(vm.pagerItems, hasLength(10));

      await vm.loadNextPagerPage();

      expect(vm.pagerItems, hasLength(20));
      expect(vm.pagerOffset, 0);
    });

    test('끝에 도달하면 더 부르지 않는다', () async {
      final repo = _FakeRepository(models(10));
      final vm = WorldCupListViewModel(repo);
      addTearDown(vm.dispose);
      await vm.refresh();
      final callsBefore = repo.pageCalls;

      await vm.loadNextPagerPage();

      expect(repo.pageCalls, callsBefore, reason: '끝인데 조회를 더 했다');
    });

    test('창이 맨 앞이면 이전 페이지를 부르지 않는다', () async {
      final repo = _FakeRepository(models(30));
      final vm = WorldCupListViewModel(repo);
      addTearDown(vm.dispose);
      await vm.refresh();
      final callsBefore = repo.pageCalls;

      await vm.loadPreviousPagerPage();

      expect(repo.pageCalls, callsBefore);
    });

    test('양방향으로 페이지를 불러도 페이저 창이 상한을 넘지 않는다', () async {
      final repo = _FakeRepository(models(100));
      final vm = WorldCupListViewModel(repo);
      addTearDown(vm.dispose);
      await vm.refresh();

      await vm.loadNextPagerPage();
      await vm.loadNextPagerPage();
      await vm.loadNextPagerPage();

      expect(vm.pagerItems, hasLength(WorldCupListViewModel.pagerWindowSize));
      expect(vm.pagerOffset, 10);
      expect(vm.pagerItems.first.idx, 11);
      expect(vm.pagerItems.last.idx, 40);

      await vm.loadPreviousPagerPage();

      expect(vm.pagerItems, hasLength(WorldCupListViewModel.pagerWindowSize));
      expect(vm.pagerOffset, 0);
      expect(vm.pagerItems.first.idx, 1);
      expect(vm.pagerItems.last.idx, 30);
      expect(
        repo.requestedOffsets.last,
        0,
        reason: '방향을 바꾸면 버린 이전 페이지를 다시 조회해야 한다',
      );
    });

    test('마지막 부분 페이지는 완전한 페이지가 될 때까지 잘라내지 않는다', () async {
      final vm = WorldCupListViewModel(_FakeRepository(models(31)));
      addTearDown(vm.dispose);
      await vm.refresh();

      await vm.loadNextPagerPage();
      await vm.loadNextPagerPage();
      await vm.loadNextPagerPage();

      expect(vm.pagerItems, hasLength(31));
      expect(vm.pagerOffset, 0);
      expect(vm.pagerItems.first.idx, 1);
      expect(vm.pagerItems.last.idx, 31);

      await vm.refresh();

      expect(vm.pagerItems, hasLength(31));
      expect(vm.pagerOffset, 0);
      expect(vm.pagerItems.last.idx, 31);
    });
  });

  group('페이저 위치 찾기', () {
    test('이미 들고 있는 항목이면 창을 바꾸지 않는다', () async {
      final vm = WorldCupListViewModel(_FakeRepository(models(30)));
      addTearDown(vm.dispose);
      await vm.refresh();

      final target = await vm.locateInPager(3);

      expect(target, isNotNull);
      expect(target!.replacedWindow, isFalse);
      expect(target.index, 2);
    });

    test('로드 범위 밖이면 그 주변 창으로 교체한다', () async {
      final vm = WorldCupListViewModel(_FakeRepository(models(30)));
      addTearDown(vm.dispose);
      await vm.refresh();

      final target = await vm.locateInPager(25);

      expect(target, isNotNull);
      expect(target!.replacedWindow, isTrue);
      expect(vm.pagerItems[target.index].idx, 25);
      // 찾은 항목이 창 가운데쯤에 오도록 자른다.
      expect(vm.pagerOffset, greaterThan(0));
    });

    test('없는 항목이면 null을 돌려준다', () async {
      final vm = WorldCupListViewModel(_FakeRepository(models(30)));
      addTearDown(vm.dispose);
      await vm.refresh();

      expect(await vm.locateInPager(9999), isNull);
    });
  });

  group('dispose 이후', () {
    test('진행 중이던 조회가 끝나도 알리지 않는다', () async {
      // 화면을 닫으면 ViewModel도 곧바로 dispose된다. 그때 DB 응답이 돌아오면
      // ChangeNotifier가 "used after being disposed" 로 던진다.
      final repo = _FakeRepository(models(20));
      final vm = WorldCupListViewModel(repo);
      var notified = 0;
      vm.addListener(() => notified++);

      repo.blockNextPage();
      final pending = vm.refresh();
      vm.dispose();
      repo.releaseBlocked();

      await pending;

      expect(notified, 0);
    });
  });

  group('빈 목록', () {
    test('한 건도 없으면 비어 있다고 본다', () async {
      final vm = WorldCupListViewModel(_FakeRepository(const []));
      addTearDown(vm.dispose);
      await vm.refresh();

      expect(vm.isEmpty, isTrue);
    });

    test('검색 결과가 없는 것은 빈 목록이 아니다', () async {
      final vm = WorldCupListViewModel(_FakeRepository(models(5)));
      addTearDown(vm.dispose);
      await vm.refresh();
      vm.startSearch();
      vm.updateQuery('없는제목');
      await vm.runSearch();

      expect(vm.sheetItems, isEmpty);
      expect(vm.isEmpty, isFalse, reason: '검색 결과 없음을 빈 목록으로 오인했다');
    });
  });
}

class _FakeRepository implements WorldCupRepository {
  List<WorldCupModel> models;
  int pageCalls = 0;
  final List<int> requestedOffsets = [];
  Completer<void>? _gate;
  bool _gateArmed = false;

  _FakeRepository(this.models);

  /// 다음 page() 호출을 [releaseBlocked]가 불릴 때까지 붙잡아 둔다.
  void blockNextPage() {
    _gate = Completer<void>();
    _gateArmed = true;
  }

  /// 붙잡아 둔 호출을 풀어준다. 참조를 지우지 않아야 풀 수 있다.
  void releaseBlocked() {
    final gate = _gate;
    if (gate != null && !gate.isCompleted) gate.complete();
  }

  List<WorldCupModel> _matching(String query) => query.isEmpty
      ? models
      : models
            .where((m) => m.title.contains(query) || m.info.contains(query))
            .toList();

  @override
  Future<int> count({String searchQuery = ''}) async =>
      _matching(searchQuery).length;

  @override
  Future<List<WorldCupModel>> page({
    required int limit,
    required int offset,
    String searchQuery = '',
  }) async {
    pageCalls++;
    requestedOffsets.add(offset);
    if (_gateArmed) {
      // 한 번만 붙잡는다. 이후 호출은 그대로 통과시킨다.
      _gateArmed = false;
      await _gate!.future;
    }
    return _matching(searchQuery).skip(offset).take(limit).toList();
  }

  @override
  Future<int> indexOf(int idx) async => models.where((m) => m.idx < idx).length;

  @override
  Future<WorldCupModel?> findById(int idx) async {
    final matches = models.where((m) => m.idx == idx);
    return matches.isEmpty ? null : matches.first;
  }

  @override
  Future<List<WorldCupItemModel>> items(int worldCupIdx) async => const [];

  @override
  Future<int> add(WorldCupModel model, List<WorldCupItemModel> items) =>
      throw UnimplementedError();

  @override
  Future<void> update(WorldCupModel model, List<WorldCupItemModel> items) =>
      throw UnimplementedError();

  @override
  Future<void> delete(int idx) => throw UnimplementedError();
}
