import 'package:feature_worldcup_editor/src/state/worldcup_editor_view_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worldcup_domain/worldcup_domain.dart';

/// 편집 화면에는 원래 테스트가 없었다. 항목 목록과 저장 규칙을 ViewModel로
/// 옮기면서 위젯 없이 검증할 수 있게 됐다.
void main() {
  EditorItem item(String name) =>
      EditorItem(imagePath: '/img/$name.jpg', imageInfo: name);

  List<EditorItem> items(int count) => [
    for (var i = 1; i <= count; i++) item('항목$i'),
  ];

  group('항목 목록', () {
    test('추가하면 순서대로 쌓인다', () {
      final vm = WorldCupEditorViewModel(_FakeRepository());
      addTearDown(vm.dispose);

      vm.addItem(item('가'));
      vm.addItem(item('나'));

      expect(vm.items.map((e) => e.imageInfo), ['가', '나']);
    });

    test('교체는 해당 자리만 바꾼다', () {
      final vm = WorldCupEditorViewModel(_FakeRepository());
      addTearDown(vm.dispose);
      for (final e in items(3)) {
        vm.addItem(e);
      }

      vm.replaceItem(1, item('바뀜'));

      expect(vm.items.map((e) => e.imageInfo), ['항목1', '바뀜', '항목3']);
    });

    test('삭제하면 경로와 설명이 함께 빠진다', () {
      // 예전에는 경로 목록과 설명 목록이 따로 있어 한쪽만 지우면 어긋났다.
      final vm = WorldCupEditorViewModel(_FakeRepository());
      addTearDown(vm.dispose);
      for (final e in items(3)) {
        vm.addItem(e);
      }

      vm.removeItemAt(1);

      expect(vm.items.map((e) => e.imageInfo), ['항목1', '항목3']);
      expect(vm.items.map((e) => e.imagePath), [
        '/img/항목1.jpg',
        '/img/항목3.jpg',
      ]);
    });

    test('범위를 벗어난 인덱스는 무시한다', () {
      final vm = WorldCupEditorViewModel(_FakeRepository());
      addTearDown(vm.dispose);
      vm.addItem(item('하나'));

      vm.removeItemAt(5);
      vm.replaceItem(-1, item('무시'));

      expect(vm.items, hasLength(1));
    });

    test('항목이 바뀌면 리스너에게 알린다', () {
      final vm = WorldCupEditorViewModel(_FakeRepository());
      addTearDown(vm.dispose);
      var notified = 0;
      vm.addListener(() => notified++);

      vm.addItem(item('가'));
      vm.replaceItem(0, item('나'));
      vm.removeItemAt(0);

      expect(notified, 3);
    });
  });

  group('저장 가능 여부', () {
    test('4개 미만이면 저장할 수 없다', () async {
      final repo = _FakeRepository();
      final vm = WorldCupEditorViewModel(repo);
      addTearDown(vm.dispose);
      for (final e in items(3)) {
        vm.addItem(e);
      }

      expect(vm.hasEnoughItems, isFalse);
      expect(await vm.save(title: '제목', info: '설명'), isNull);
      expect(repo.added, isEmpty, reason: '항목이 모자란데 저장했다');
    });

    test('4개면 저장한다', () async {
      final repo = _FakeRepository();
      final vm = WorldCupEditorViewModel(repo);
      addTearDown(vm.dispose);
      for (final e in items(4)) {
        vm.addItem(e);
      }

      expect(await vm.save(title: '제목', info: '설명'), 42);
      expect(repo.added, hasLength(1));
    });
  });

  group('새로 만들기', () {
    test('첫 항목의 이미지를 대표 이미지로 쓰고 개수를 maxRound로 넣는다', () async {
      final repo = _FakeRepository();
      final vm = WorldCupEditorViewModel(repo);
      addTearDown(vm.dispose);
      for (final e in items(5)) {
        vm.addItem(e);
      }

      await vm.save(title: '내 월드컵', info: '설명');

      final saved = repo.added.single;
      expect(saved.model.title, '내 월드컵');
      expect(saved.model.titleImageSrc, '/img/항목1.jpg');
      expect(saved.model.maxRound, 5);
      expect(saved.items, hasLength(5));
    });
  });

  group('수정 모드', () {
    test('원본과 항목을 불러온다', () async {
      final repo = _FakeRepository()
        ..worldCups[7] = WorldCupModel(
          7,
          '원래 제목',
          '원래 설명',
          DateTime(2026, 3, 1),
          '/img/항목1.jpg',
          4,
        )
        ..itemsById[7] = [
          for (var i = 1; i <= 4; i++)
            WorldCupItemModel(i, '/img/항목$i.jpg', '항목$i', 7),
        ];
      final vm = WorldCupEditorViewModel(repo, editWorldCupId: 7);
      addTearDown(vm.dispose);

      await vm.load();

      expect(vm.isEditMode, isTrue);
      expect(vm.isReady, isTrue);
      expect(vm.originalTitle, '원래 제목');
      expect(vm.originalInfo, '원래 설명');
      expect(vm.items, hasLength(4));
    });

    test('등록일은 원본 것을 유지한다', () async {
      final originalDate = DateTime(2026, 3, 1);
      final repo = _FakeRepository()
        ..worldCups[7] = WorldCupModel(7, 't', 'i', originalDate, 'p', 4)
        ..itemsById[7] = [
          for (var i = 1; i <= 4; i++)
            WorldCupItemModel(i, '/img/항목$i.jpg', '항목$i', 7),
        ];
      final vm = WorldCupEditorViewModel(repo, editWorldCupId: 7);
      addTearDown(vm.dispose);
      await vm.load();

      await vm.update(title: '새 제목', info: '새 설명');

      final updated = repo.updated.single;
      expect(updated.model.idx, 7);
      expect(updated.model.date, originalDate);
      expect(updated.model.title, '새 제목');
    });

    test('원본을 못 불러왔으면 수정하지 않는다', () async {
      // 화면 진입 직후 사용자가 바로 확인을 누르면 이 상태가 될 수 있다.
      final repo = _FakeRepository();
      final vm = WorldCupEditorViewModel(repo, editWorldCupId: 99);
      addTearDown(vm.dispose);
      for (final e in items(4)) {
        vm.addItem(e);
      }

      expect(await vm.update(title: 't', info: 'i'), isFalse);
      expect(repo.updated, isEmpty);
      expect(vm.isReady, isFalse);
    });

    test('새로 만드는 중이면 load가 아무 일도 하지 않는다', () async {
      final repo = _FakeRepository();
      final vm = WorldCupEditorViewModel(repo);
      addTearDown(vm.dispose);

      await vm.load();

      expect(vm.isReady, isTrue);
      expect(repo.findCalls, 0);
    });
  });
}

class _SavedWorldCup {
  final WorldCupModel model;
  final List<WorldCupItemModel> items;
  _SavedWorldCup(this.model, this.items);
}

class _FakeRepository implements WorldCupRepository {
  final Map<int, WorldCupModel> worldCups = {};
  final Map<int, List<WorldCupItemModel>> itemsById = {};
  final List<_SavedWorldCup> added = [];
  final List<_SavedWorldCup> updated = [];
  int findCalls = 0;

  @override
  Future<WorldCupModel?> findById(int idx) async {
    findCalls++;
    return worldCups[idx];
  }

  @override
  Future<List<WorldCupItemModel>> items(int worldCupIdx) async =>
      itemsById[worldCupIdx] ?? const [];

  @override
  Future<int> add(WorldCupModel model, List<WorldCupItemModel> items) async {
    added.add(_SavedWorldCup(model, items));
    return 42;
  }

  @override
  Future<void> update(
    WorldCupModel model,
    List<WorldCupItemModel> items,
  ) async {
    updated.add(_SavedWorldCup(model, items));
  }

  @override
  Future<int> count({String searchQuery = ''}) => throw UnimplementedError();

  @override
  Future<int> indexOf(int idx) => throw UnimplementedError();

  @override
  Future<List<WorldCupModel>> page({
    required int limit,
    required int offset,
    String searchQuery = '',
  }) => throw UnimplementedError();

  @override
  Future<void> delete(int idx) => throw UnimplementedError();
}
