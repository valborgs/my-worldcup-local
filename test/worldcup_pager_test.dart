import 'dart:ui' show SemanticsAction;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_worldcup_local/widgets/worldcup_list.dart';

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
    await tester.pumpWidget(buildPager(items: const []));

    expect(find.byType(PageView), findsNothing);
  });

  testWidgets('옆 카드는 중앙으로 이동하고 중앙 카드는 콜백을 실행한다',
      (tester) async {
    var currentPage = 0;
    int? tappedIndex;
    await tester.pumpWidget(
      buildPager(
        items: const ['A', 'B', 'C'],
        onPageChanged: (index) => currentPage = index,
        onCurrentItemTap: (index) => tappedIndex = index,
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

  testWidgets('현재 항목의 식별자를 유지하며 삭제 후 페이지를 보정한다',
      (tester) async {
    final hostKey = GlobalKey<_MutablePagerHostState>();
    await tester.pumpWidget(_MutablePagerHost(key: hostKey));
    expect(find.bySemanticsLabel('월드컵 2 / 3'), findsOneWidget);

    hostKey.currentState!.removeFirst();
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('월드컵 1 / 2'), findsOneWidget);
  });

  testWidgets('현재 마지막 항목 삭제 후 남은 카드를 중앙에 표시한다',
      (tester) async {
    final hostKey = GlobalKey<_MutablePagerHostState>();
    await tester.pumpWidget(
      _MutablePagerHost(
        key: hostKey,
        initialItems: const ['A', 'B'],
        initialPage: 1,
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
    await tester.pumpWidget(buildPager(items: const ['A', 'B']));

    final semantics = tester.getSemantics(find.bySemanticsLabel('월드컵 1 / 2'));
    final data = semantics.getSemanticsData();
    expect(data.hasAction(SemanticsAction.tap), isTrue);
    expect(data.hasAction(SemanticsAction.increase), isTrue);

    handle.dispose();
  });
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
