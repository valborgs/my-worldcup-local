import 'dart:ui' show SemanticsAction;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:feature_worldcup_list/src/state/worldcup_list_view_model.dart';
import 'package:feature_worldcup_list/src/widgets/cover_flow_pager.dart';
import 'package:feature_worldcup_list/src/widgets/worldcup_list.dart';
import 'package:worldcup_domain/worldcup_domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  Widget buildPager({
    required List<String> items,
    int initialPage = 0,
    ValueChanged<int>? onPageChanged,
    ValueChanged<int>? onCurrentItemTap,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: CoverFlowPager<String>(
          items: items,
          initialPage: initialPage,
          itemKey: (item) => item,
          itemBuilder: (context, item, index) => ColoredBox(
            color: Colors.blue,
            child: Center(child: Text(item)),
          ),
          onPageChanged: (item, index) => onPageChanged?.call(index),
          onCurrentItemTap: (context, item, index) {
            onCurrentItemTap?.call(index);
          },
        ),
      ),
    );
  }

  testWidgets('빈 목록이면 PageView를 만들지 않는다', (tester) async {
    await tester.pumpWidget(ProviderScope(child: buildPager(items: const [])));

    expect(find.byType(PageView), findsNothing);
  });

  testWidgets('옆 카드는 중앙으로 이동하고 중앙 카드는 콜백을 실행한다', (tester) async {
    var currentPage = 0;
    int? tappedIndex;
    await tester.pumpWidget(
      ProviderScope(
        child: buildPager(
          items: const ['A', 'B', 'C'],
          onPageChanged: (index) => currentPage = index,
          onCurrentItemTap: (index) => tappedIndex = index,
        ),
      ),
    );

    await tester.tapAt(const Offset(700, 300));
    await tester.pumpAndSettle();

    expect(currentPage, 1);
    expect(tappedIndex, isNull);

    await tester.tapAt(const Offset(400, 300));
    await tester.pump();

    expect(tappedIndex, 1);
  });

  testWidgets('현재 항목의 식별자를 유지하며 삭제 후 페이지를 보정한다', (tester) async {
    final hostKey = GlobalKey<_MutablePagerHostState>();
    await tester.pumpWidget(
      ProviderScope(child: _MutablePagerHost(key: hostKey)),
    );
    expect(find.bySemanticsLabel('월드컵 2 / 3'), findsOneWidget);

    hostKey.currentState!.removeFirst();
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('월드컵 1 / 2'), findsOneWidget);
  });

  testWidgets('현재 마지막 항목 삭제 후 남은 카드를 중앙에 표시한다', (tester) async {
    final hostKey = GlobalKey<_MutablePagerHostState>();
    await tester.pumpWidget(
      ProviderScope(
        child: _MutablePagerHost(
          key: hostKey,
          initialItems: const ['A', 'B'],
          initialPage: 1,
        ),
      ),
    );

    hostKey.currentState!.removeCurrent();
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('월드컵 1 / 1'), findsOneWidget);
    expect(
      tester.getCenter(find.byKey(const ValueKey('coverFlowCard-0'))),
      const Offset(400, 300),
    );
  });

  testWidgets('현재 카드에 접근성 탭 액션을 제공한다', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      ProviderScope(child: buildPager(items: const ['A', 'B'])),
    );

    final semantics = tester.getSemantics(find.bySemanticsLabel('월드컵 1 / 2'));
    final data = semantics.getSemanticsData();
    expect(data.hasAction(SemanticsAction.tap), isTrue);
    expect(data.hasAction(SemanticsAction.increase), isTrue);

    handle.dispose();
  });

  testWidgets('추가 후 새로고침해도 현재 페이지와 다음 항목을 유지한다', (tester) async {
    final dao = _FakeWorldCupDao(_models(20));
    final listKey = GlobalKey<WorldCupListState>();
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                WorldCupList(
                  key: listKey,
                  repository: dao,
                  enableBottomSheetSelectionPagerTransition: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    for (var index = 0; index < 9; index++) {
      await tester.drag(
        find.byKey(const ValueKey('worldCupPager')),
        const Offset(-500, 0),
      );
      await tester.pumpAndSettle();
    }
    expect(
      find.bySemanticsLabel('Game 10, 최대 라운드 4강, 10 / 20'),
      findsOneWidget,
    );

    dao.models = _models(21);
    await listKey.currentState!.refresh();
    await tester.pumpAndSettle();

    expect(
      find.bySemanticsLabel('Game 10, 최대 라운드 4강, 10 / 21'),
      findsOneWidget,
    );
    await tester.drag(
      find.byKey(const ValueKey('worldCupPager')),
      const Offset(-500, 0),
    );
    await tester.pumpAndSettle();
    expect(
      find.bySemanticsLabel('Game 11, 최대 라운드 4강, 11 / 21'),
      findsOneWidget,
    );
  });

  testWidgets('추가된 월드컵이 현재 로드 범위 밖이어도 해당 페이지로 이동한다', (tester) async {
    final dao = _FakeWorldCupDao(_models(20));
    final listKey = GlobalKey<WorldCupListState>();
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                WorldCupList(
                  key: listKey,
                  repository: dao,
                  enableBottomSheetSelectionPagerTransition: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    dao.models = _models(21);
    await listKey.currentState!.refreshAndScrollTo(21);
    await tester.pumpAndSettle();

    expect(listKey.currentState!.worldCupList, hasLength(10));
    expect(dao.requestedLimits, everyElement(lessThanOrEqualTo(10)));
    final pageView = tester.widget<PageView>(find.byType(PageView));
    expect(pageView.controller!.page, 9);
    expect(
      find.bySemanticsLabel('Game 21, 최대 라운드 4강, 21 / 21'),
      findsOneWidget,
    );

    await tester.drag(
      find.byKey(const ValueKey('worldCupPager')),
      const Offset(500, 0),
    );
    await tester.pumpAndSettle();
    expect(
      find.bySemanticsLabel('Game 20, 최대 라운드 4강, 20 / 21'),
      findsOneWidget,
    );
  });

  testWidgets('현재 로드 범위의 월드컵으로 이동할 때 애니메이션을 유지한다', (tester) async {
    final dao = _FakeWorldCupDao(_models(10));
    final listKey = GlobalKey<WorldCupListState>();
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                WorldCupList(
                  key: listKey,
                  repository: dao,
                  enableBottomSheetSelectionPagerTransition: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final navigation = listKey.currentState!.refreshAndScrollTo(4);
    await tester.pump();
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final pageView = tester.widget<PageView>(find.byType(PageView));
    expect(pageView.controller!.page, greaterThan(0));
    expect(pageView.controller!.page, lessThan(3));

    await tester.pumpAndSettle();
    await navigation;
    expect(pageView.controller!.page, 3);
  });

  testWidgets('뒤쪽 창의 앞 카드로 애니메이션한 뒤에도 선택 항목을 유지한다', (tester) async {
    final dao = _FakeWorldCupDao(_models(15));
    final listKey = GlobalKey<WorldCupListState>();
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                WorldCupList(
                  key: listKey,
                  repository: dao,
                  enableBottomSheetSelectionPagerTransition: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await listKey.currentState!.refreshAndScrollTo(15);
    await tester.pumpAndSettle();
    expect(
      find.bySemanticsLabel('Game 15, 최대 라운드 4강, 15 / 15'),
      findsOneWidget,
    );

    final navigation = listKey.currentState!.refreshAndScrollTo(6);
    await tester.pump();
    await tester.pump();
    await tester.pump();
    await tester.pumpAndSettle();
    await navigation;
    await tester.pumpAndSettle();

    expect(listKey.currentState!.worldCupList.first.idx, 1);
    expect(find.bySemanticsLabel('Game 6, 최대 라운드 4강, 6 / 15'), findsOneWidget);
  });

  // 위젯을 띄우지 않고 ViewModel만으로 검증한다. 새로고침의 조회 범위 계산은
  // 이제 위젯이 아니라 ViewModel의 책임이다.
  test('첫 페이지를 공유하는 새로고침은 가장 큰 범위를 한 번만 조회한다', () async {
    final dao = _FakeWorldCupDao(_models(30));
    // 페이저가 이미 30개를 들고 있는 상태에서 새로고침한다.
    final viewModel = WorldCupListViewModel(dao, initialItems: _models(30));
    addTearDown(viewModel.dispose);

    await viewModel.refresh();

    // 시트용 조회와 페이저용 조회를 하나로 합쳐 한 번만 물어봐야 한다.
    expect(dao.requestedLimits, [30]);
    expect(dao.requestedOffsets, [0]);
  });

  testWidgets('반복 새로고침해도 페이저 로드 범위가 계속 늘어나지 않는다', (tester) async {
    final dao = _FakeWorldCupDao(_models(200));
    final listKey = GlobalKey<WorldCupListState>();
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                WorldCupList(
                  key: listKey,
                  repository: dao,
                  enableBottomSheetSelectionPagerTransition: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    for (var count = 0; count < 5; count++) {
      await listKey.currentState!.refresh();
      await tester.pumpAndSettle();
    }

    expect(listKey.currentState!.worldCupList, hasLength(10));
  });

  testWidgets('페이저 창을 잘라내도 현재 카드를 유지하고 역방향 페이지를 다시 부른다', (tester) async {
    final dao = _FakeWorldCupDao(_models(100));
    final listKey = GlobalKey<WorldCupListState>();
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                WorldCupList(
                  key: listKey,
                  repository: dao,
                  enableBottomSheetSelectionPagerTransition: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 28번째 카드에 도달하면 4번째 페이지를 붙인 뒤 첫 페이지를 잘라낸다.
    for (var count = 0; count < 27; count++) {
      await tester.drag(
        find.byKey(const ValueKey('worldCupPager')),
        const Offset(-500, 0),
      );
      await tester.pumpAndSettle();
    }

    expect(
      listKey.currentState!.worldCupList,
      hasLength(WorldCupListViewModel.pagerWindowSize),
    );
    expect(
      find.bySemanticsLabel('Game 28, 최대 라운드 4강, 28 / 100'),
      findsOneWidget,
    );

    // 방향을 바꿔 앞쪽 경계로 돌아가면 버렸던 0~9 범위를 다시 조회한다.
    for (var count = 0; count < 15; count++) {
      await tester.drag(
        find.byKey(const ValueKey('worldCupPager')),
        const Offset(500, 0),
      );
      await tester.pumpAndSettle();
    }

    expect(dao.requestedOffsets.where((offset) => offset == 0), hasLength(2));
    expect(
      find.bySemanticsLabel('Game 13, 최대 라운드 4강, 13 / 100'),
      findsOneWidget,
    );
  });

  testWidgets('뒷쪽 페이지로 이동한 후 앞으로 넘기면 이전 페이지를 이어서 불러온다', (tester) async {
    final dao = _FakeWorldCupDao(_models(31));
    final listKey = GlobalKey<WorldCupListState>();
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                WorldCupList(
                  key: listKey,
                  repository: dao,
                  enableBottomSheetSelectionPagerTransition: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    dao.models = _models(32);
    await listKey.currentState!.refreshAndScrollTo(32);
    await tester.pumpAndSettle();

    for (var count = 0; count < 7; count++) {
      await tester.drag(
        find.byKey(const ValueKey('worldCupPager')),
        const Offset(500, 0),
      );
      await tester.pumpAndSettle();
    }

    expect(
      find.bySemanticsLabel('Game 25, 최대 라운드 4강, 25 / 32'),
      findsOneWidget,
    );
    await tester.drag(
      find.byKey(const ValueKey('worldCupPager')),
      const Offset(500, 0),
    );
    await tester.pumpAndSettle();
    expect(
      find.bySemanticsLabel('Game 24, 최대 라운드 4강, 24 / 32'),
      findsOneWidget,
    );
  });
}

List<WorldCupModel> _models(int count) => List.generate(
  count,
  (index) =>
      WorldCupModel(index + 1, 'Game ${index + 1}', '', DateTime(2026), '', 4),
);

class _FakeWorldCupDao implements WorldCupRepository {
  // WorldCupRepository.items(int)와 이름이 겹치지 않도록 models로 둔다.
  List<WorldCupModel> models;
  final List<int> requestedLimits = [];
  final List<int> requestedOffsets = [];

  _FakeWorldCupDao(this.models);

  @override
  Future<int> count({String searchQuery = ''}) async => models.length;

  @override
  Future<List<WorldCupModel>> page({
    required int limit,
    required int offset,
    String searchQuery = '',
  }) async {
    requestedLimits.add(limit);
    requestedOffsets.add(offset);
    return models.skip(offset).take(limit).toList();
  }

  @override
  Future<int> indexOf(int idx) async =>
      models.where((item) => item.idx < idx).length;

  // 페이저 테스트에서 쓰지 않는 나머지 멤버.
  @override
  Future<List<WorldCupItemModel>> items(int worldCupIdx) async => const [];

  @override
  Future<WorldCupModel?> findById(int idx) => throw UnimplementedError();

  @override
  Future<int> add(WorldCupModel model, List<WorldCupItemModel> items) =>
      throw UnimplementedError();

  @override
  Future<void> update(WorldCupModel model, List<WorldCupItemModel> items) =>
      throw UnimplementedError();

  @override
  Future<void> delete(int idx) => throw UnimplementedError();
}

class _MutablePagerHost extends StatefulWidget {
  final List<String> initialItems;
  final int initialPage;

  const _MutablePagerHost({
    this.initialItems = const ['A', 'B', 'C'],
    this.initialPage = 1,
    super.key,
  });

  @override
  State<_MutablePagerHost> createState() => _MutablePagerHostState();
}

class _MutablePagerHostState extends State<_MutablePagerHost> {
  late List<String> items = List.of(widget.initialItems);

  void removeFirst() {
    setState(() => items = items.sublist(1));
  }

  void removeCurrent() {
    setState(() => items.removeAt(widget.initialPage));
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: CoverFlowPager<String>(
          items: items,
          initialPage: widget.initialPage,
          itemKey: (item) => item,
          itemBuilder: (context, item, index) => Text(item),
        ),
      ),
    );
  }
}
