import 'dart:async';

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
      final vm = WorldCupEditorViewModel(
        _FakeRepository(),
        imageMetadata: _FakeImageMetadata(),
      );
      addTearDown(vm.dispose);

      vm.addItem(item('가'));
      vm.addItem(item('나'));

      expect(vm.items.map((e) => e.imageInfo), ['가', '나']);
    });

    test('교체는 해당 자리만 바꾼다', () {
      final vm = WorldCupEditorViewModel(
        _FakeRepository(),
        imageMetadata: _FakeImageMetadata(),
      );
      addTearDown(vm.dispose);
      for (final e in items(3)) {
        vm.addItem(e);
      }

      vm.replaceItem(1, item('바뀜'));

      expect(vm.items.map((e) => e.imageInfo), ['항목1', '바뀜', '항목3']);
    });

    test('삭제하면 경로와 설명이 함께 빠진다', () {
      // 예전에는 경로 목록과 설명 목록이 따로 있어 한쪽만 지우면 어긋났다.
      final vm = WorldCupEditorViewModel(
        _FakeRepository(),
        imageMetadata: _FakeImageMetadata(),
      );
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
      final vm = WorldCupEditorViewModel(
        _FakeRepository(),
        imageMetadata: _FakeImageMetadata(),
      );
      addTearDown(vm.dispose);
      vm.addItem(item('하나'));

      vm.removeItemAt(5);
      vm.replaceItem(-1, item('무시'));

      expect(vm.items, hasLength(1));
    });

    test('항목이 바뀌면 리스너에게 알린다', () {
      final vm = WorldCupEditorViewModel(
        _FakeRepository(),
        imageMetadata: _FakeImageMetadata(),
      );
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
      final vm = WorldCupEditorViewModel(
        repo,
        imageMetadata: _FakeImageMetadata(),
      );
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
      final vm = WorldCupEditorViewModel(
        repo,
        imageMetadata: _FakeImageMetadata(),
      );
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
      final vm = WorldCupEditorViewModel(
        repo,
        imageMetadata: _FakeImageMetadata(),
      );
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
      final vm = WorldCupEditorViewModel(
        repo,
        imageMetadata: _FakeImageMetadata(),
        editWorldCupId: 7,
      );
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
      final vm = WorldCupEditorViewModel(
        repo,
        imageMetadata: _FakeImageMetadata(),
        editWorldCupId: 7,
      );
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
      final vm = WorldCupEditorViewModel(
        repo,
        imageMetadata: _FakeImageMetadata(),
        editWorldCupId: 99,
      );
      addTearDown(vm.dispose);
      for (final e in items(4)) {
        vm.addItem(e);
      }

      expect(await vm.update(title: 't', info: 'i'), isFalse);
      expect(repo.updated, isEmpty);
      expect(vm.isReady, isFalse);
    });

    test('dispose 이후 load 응답이 와도 알리지 않는다', () async {
      // 수정 화면에 들어가자마자 뒤로가기를 누르면 이 상황이 된다.
      final repo = _FakeRepository()
        ..worldCups[7] = WorldCupModel(7, 't', 'i', DateTime(2026), 'p', 4);
      final vm = WorldCupEditorViewModel(
        repo,
        imageMetadata: _FakeImageMetadata(),
        editWorldCupId: 7,
      );
      var notified = 0;
      vm.addListener(() => notified++);

      repo.blockNextRead();
      final pending = vm.load();
      final before = notified;
      vm.dispose();
      repo.releaseBlocked();

      await pending;

      expect(notified, before);
    });

    test('새로 만드는 중이면 load가 아무 일도 하지 않는다', () async {
      final repo = _FakeRepository();
      final vm = WorldCupEditorViewModel(
        repo,
        imageMetadata: _FakeImageMetadata(),
      );
      addTearDown(vm.dispose);

      await vm.load();

      expect(vm.isReady, isTrue);
      expect(repo.findCalls, 0);
    });
  });

  group('사진 메타데이터', () {
    test('고른 사진 대신 메타데이터를 지운 사본 경로를 돌려준다', () async {
      final metadata = _FakeImageMetadata();
      final vm = WorldCupEditorViewModel(
        _FakeRepository(),
        imageMetadata: metadata,
      );
      addTearDown(vm.dispose);
      final processing = <bool>[];
      vm.addListener(() => processing.add(vm.isProcessingImage));

      final path = await vm.prepareImage('/picker/cache/photo.jpg');

      expect(path, '/stripped/photo.jpg');
      expect(metadata.requested, ['/picker/cache/photo.jpg']);
      expect(processing, [true, false]);
    });

    test('메타데이터를 지우지 못하면 원본을 쓰지 않고 null을 돌려준다', () async {
      final vm = WorldCupEditorViewModel(
        _FakeRepository(),
        imageMetadata: _FakeImageMetadata(fail: true),
      );
      addTearDown(vm.dispose);

      final path = await vm.prepareImage('/picker/cache/photo.jpg');

      expect(path, isNull);
      expect(vm.isProcessingImage, isFalse);
    });

    test('여러 장은 순서대로 처리하며 몇 장째인지 알린다', () async {
      final vm = WorldCupEditorViewModel(
        _FakeRepository(),
        imageMetadata: _FakeImageMetadata(failing: {'/p/b.jpg'}),
      );
      addTearDown(vm.dispose);
      final progress = <(bool, int, int)>[];
      vm.addListener(
        () => progress.add((
          vm.isProcessingImage,
          vm.processedImageCount,
          vm.processingImageTotal,
        )),
      );

      final paths = await vm.prepareImages([
        '/p/a.jpg',
        '/p/b.jpg',
        '/p/c.jpg',
      ]);

      expect(paths, ['/stripped/a.jpg', null, '/stripped/c.jpg']);
      expect(progress, [
        (true, 0, 3),
        (true, 1, 3),
        (true, 2, 3),
        (true, 3, 3),
        (false, 0, 0),
      ]);
    });

    test('여러 장 처리 중에 화면이 닫히면 남은 사진은 처리하지 않는다', () async {
      final metadata = _FakeImageMetadata()..gate = Completer<void>();
      final vm = WorldCupEditorViewModel(
        _FakeRepository(),
        imageMetadata: metadata,
      );

      final pending = vm.prepareImages(['/p/a.jpg', '/p/b.jpg', '/p/c.jpg']);
      vm.dispose();
      metadata.gate!.complete();

      expect(await pending, [null, null, null]);
      expect(metadata.requested, ['/p/a.jpg']);
    });

    test('처리 중에 화면이 닫혀도 dispose 뒤에 알리지 않는다', () async {
      final metadata = _FakeImageMetadata()..gate = Completer<void>();
      final vm = WorldCupEditorViewModel(
        _FakeRepository(),
        imageMetadata: metadata,
      );

      final pending = vm.prepareImage('/picker/cache/photo.jpg');
      vm.dispose();
      metadata.gate!.complete();

      expect(await pending, isNull);
    });
  });
  group('쓰이지 않는 사본 정리', () {
    Future<(WorldCupEditorViewModel, _FakeImageMetadata)> vmWith({
      _FakeRepository? repository,
      int? editWorldCupId,
    }) async {
      final metadata = _FakeImageMetadata();
      final vm = WorldCupEditorViewModel(
        repository ?? _FakeRepository(),
        imageMetadata: metadata,
        editWorldCupId: editWorldCupId,
      );
      return (vm, metadata);
    }

    test('설명 입력을 취소한 사본은 바로 지운다', () async {
      final (vm, metadata) = await vmWith();
      addTearDown(vm.dispose);
      final path = await vm.prepareImage('/picker/a.jpg');

      await vm.discardPreparedImage(path!);

      expect(metadata.discarded, ['/stripped/a.jpg']);
    });

    test('추가했던 사본을 목록에서 빼거나 바꾸면 바로 지운다', () async {
      final (vm, metadata) = await vmWith();
      addTearDown(vm.dispose);
      for (final name in ['a', 'b']) {
        final path = await vm.prepareImage('/picker/$name.jpg');
        vm.addItem(EditorItem(imagePath: path!, imageInfo: name));
      }
      final replacement = await vm.prepareImage('/picker/c.jpg');

      vm.removeItemAt(0);
      vm.replaceItem(0, EditorItem(imagePath: replacement!, imageInfo: 'c'));
      await pumpEventQueue();

      expect(metadata.discarded, ['/stripped/a.jpg', '/stripped/b.jpg']);
    });

    test('설명만 고쳐 같은 사진으로 바꾸면 지우지 않는다', () async {
      final (vm, metadata) = await vmWith();
      addTearDown(vm.dispose);
      final path = await vm.prepareImage('/picker/a.jpg');
      vm.addItem(EditorItem(imagePath: path!, imageInfo: '전'));

      vm.replaceItem(0, EditorItem(imagePath: path, imageInfo: '후'));
      await pumpEventQueue();

      expect(metadata.discarded, isEmpty);
    });

    test('저장된 원본 사진은 목록에서 빼도 저장 전에는 지우지 않는다', () async {
      final repo = _FakeRepository();
      repo.worldCups[7] = WorldCupModel(
        7,
        '제목',
        '설명',
        DateTime(2026),
        '/saved/0.jpg',
        4,
      );
      repo.itemsById[7] = [
        for (var i = 0; i < 4; i++)
          WorldCupItemModel(i, '/saved/$i.jpg', '$i', 7),
      ];
      final (vm, metadata) = await vmWith(repository: repo, editWorldCupId: 7);
      await vm.load();

      vm.removeItemAt(0);
      vm.dispose();
      await pumpEventQueue();

      expect(
        metadata.discarded,
        isEmpty,
        reason: '저장된 월드컵의 사진은 저장소가 수정을 확정한 뒤에 지운다.',
      );
    });

    test('저장하지 않고 화면을 닫으면 만든 사본을 모두 지운다', () async {
      final (vm, metadata) = await vmWith();
      for (final name in ['a', 'b']) {
        final path = await vm.prepareImage('/picker/$name.jpg');
        vm.addItem(EditorItem(imagePath: path!, imageInfo: name));
      }

      vm.dispose();
      await pumpEventQueue();

      expect(
        metadata.discarded,
        unorderedEquals(['/stripped/a.jpg', '/stripped/b.jpg']),
      );
    });

    test('저장한 뒤에 화면을 닫으면 사본을 지우지 않는다', () async {
      final (vm, metadata) = await vmWith();
      for (final name in ['a', 'b', 'c', 'd']) {
        final path = await vm.prepareImage('/picker/$name.jpg');
        vm.addItem(EditorItem(imagePath: path!, imageInfo: name));
      }

      await vm.save(title: '제목', info: '설명');
      vm.dispose();
      await pumpEventQueue();

      expect(metadata.discarded, isEmpty);
    });

    test('처리 중에 화면이 닫히면 방금 만든 사본도 지운다', () async {
      final metadata = _FakeImageMetadata()..gate = Completer<void>();
      final vm = WorldCupEditorViewModel(
        _FakeRepository(),
        imageMetadata: metadata,
      );

      final pending = vm.prepareImage('/picker/a.jpg');
      vm.dispose();
      metadata.gate!.complete();
      await pending;
      await pumpEventQueue();

      expect(metadata.discarded, ['/stripped/a.jpg']);
    });
  });
}

class _FakeImageMetadata implements ImageMetadataPort {
  final bool fail;
  final Set<String> failing;
  final requested = <String>[];
  final discarded = <String>[];
  Completer<void>? gate;

  _FakeImageMetadata({this.fail = false, this.failing = const {}});

  @override
  Future<String> stripMetadata(String sourcePath) async {
    requested.add(sourcePath);
    await gate?.future;
    if (fail || failing.contains(sourcePath)) {
      throw StateError('decode failed');
    }
    return '/stripped/${sourcePath.split('/').last}';
  }

  @override
  Future<void> discard(String path) async {
    discarded.add(path);
  }
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
  Completer<void>? _gate;
  bool _gateArmed = false;

  /// 다음 findById 호출을 [releaseBlocked]가 불릴 때까지 붙잡아 둔다.
  void blockNextRead() {
    _gate = Completer<void>();
    _gateArmed = true;
  }

  void releaseBlocked() {
    final gate = _gate;
    if (gate != null && !gate.isCompleted) gate.complete();
  }

  @override
  Future<WorldCupModel?> findById(int idx) async {
    findCalls++;
    if (_gateArmed) {
      _gateArmed = false;
      await _gate!.future;
    }
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
  Future<int> count({
    String searchQuery = '',
    List<int> matchingIds = const [],
  }) => throw UnimplementedError();

  @override
  Future<int> indexOf(int idx) => throw UnimplementedError();

  @override
  Future<List<WorldCupModel>> page({
    required int limit,
    required int offset,
    String searchQuery = '',
    List<int> matchingIds = const [],
  }) => throw UnimplementedError();

  @override
  Future<void> delete(int idx) => throw UnimplementedError();
}
