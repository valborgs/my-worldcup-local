import 'dart:async';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:worldcup_domain/worldcup_domain.dart';

/// 편집 중인 항목 하나. 아직 저장 전이라 id가 없다.
@immutable
class EditorItem {
  /// 이미지 파일 경로.
  final String imagePath;

  /// 항목 설명(이름).
  final String imageInfo;

  const EditorItem({required this.imagePath, required this.imageInfo});

  @override
  bool operator ==(Object other) =>
      other is EditorItem &&
      other.imagePath == imagePath &&
      other.imageInfo == imageInfo;

  @override
  int get hashCode => Object.hash(imagePath, imageInfo);
}

/// 월드컵 생성 / 수정 화면의 상태.
///
/// 항목 목록과 저장 규칙을 위젯에서 걷어낸다. 예전에는 경로 목록과 설명
/// 목록이 별개의 List로 화면 State에 있어서, 두 목록의 길이가 어긋나도
/// 아무도 막지 못했다. 여기서는 한 쌍으로만 다룬다.
///
/// 텍스트 입력(제목 / 설명)은 TextEditingController가 위젯에 있으므로
/// 저장할 때 인자로 받는다.
class WorldCupEditorViewModel extends ChangeNotifier {
  /// 게임을 만들 수 있는 최소 항목 수. 4강이 가장 작은 대진이다.
  static const int minimumItemCount = 4;

  final WorldCupRepository _repository;

  /// 새로 고른 사진의 위치 정보 등 메타데이터를 지운다.
  final ImageMetadataPort _imageMetadata;

  /// 수정할 월드컵 id. `null`이면 새로 만드는 중이다.
  final int? editWorldCupId;

  WorldCupEditorViewModel(
    this._repository, {
    required this._imageMetadata,
    this.editWorldCupId,
  });

  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    // 저장하지 않고 나가면 이번에 만든 사본은 어디에도 쓰이지 않는다.
    for (final path in _preparedPaths) {
      _discard(path);
    }
    _preparedPaths.clear();
    super.dispose();
  }

  /// 이미 dispose 됐으면 알리지 않는다.
  ///
  /// 수정 화면에 들어가자마자 뒤로가기를 누르면 원본을 불러오는 도중에
  /// ViewModel이 dispose된다. 응답이 돌아와 그대로 알리면 ChangeNotifier가
  /// "used after being disposed"로 던진다.
  void _notify() {
    if (_disposed) return;
    notifyListeners();
  }

  List<EditorItem> _items = [];

  /// 수정 모드에서 불러온 원본. 제목 / 설명 / 등록일을 유지하는 데 쓴다.
  WorldCupModel? _original;

  bool _isLoading = false;

  bool _isProcessingImage = false;

  /// 이 화면에서 새로 만들었고 아직 저장되지 않은 사본들.
  ///
  /// 저장된 월드컵의 사진은 여기 없다. 그런 사진은 저장소가 수정을
  /// 확정한 뒤에 지운다. 여기서 먼저 지우면 수정을 취소했을 때 원본이
  /// 사진을 잃는다.
  final Set<String> _preparedPaths = {};
  int _processedImageCount = 0;
  int _processingImageTotal = 0;

  List<EditorItem> get items => List.unmodifiable(_items);

  bool get isEditMode => editWorldCupId != null;

  /// 수정 모드에서 원본을 불러오는 중인지.
  bool get isLoading => _isLoading;

  /// 새로 고른 사진의 메타데이터를 지우는 중인지.
  bool get isProcessingImage => _isProcessingImage;

  /// [prepareImages]가 처리를 마친 사진 수. 여러 장을 처리할 때만 센다.
  int get processedImageCount => _processedImageCount;

  /// [prepareImages]가 처리할 전체 사진 수. 처리 중이 아니면 0.
  int get processingImageTotal => _processingImageTotal;

  /// 수정 모드에서 원본을 불러왔는지. 새로 만드는 중이면 항상 참이다.
  bool get isReady => !isEditMode || _original != null;

  /// 수정 모드에서 화면에 채워 넣을 원본 제목.
  String get originalTitle => _original?.title ?? '';

  /// 수정 모드에서 화면에 채워 넣을 원본 설명.
  String get originalInfo => _original?.info ?? '';

  /// 저장할 수 있는 상태인지. 제목 / 설명 유효성은 폼이 따로 검사한다.
  bool get hasEnoughItems => _items.length >= minimumItemCount;

  /// 수정 모드에서 원본과 항목을 불러온다.
  Future<void> load() async {
    final id = editWorldCupId;
    if (id == null) return;

    _isLoading = true;
    _notify();
    try {
      final model = await _repository.findById(id);
      if (_disposed || model == null) return;
      final items = await _repository.items(id);
      if (_disposed) return;
      _original = model;
      _items = [
        for (final item in items)
          EditorItem(imagePath: item.imagePath, imageInfo: item.imageInfo),
      ];
    } finally {
      _isLoading = false;
      _notify();
    }
  }

  /// 새로 고른 사진 [sourcePath]에서 메타데이터를 지운 사본의 경로.
  ///
  /// 월드컵 사진은 공유 파일에 담겨 다른 사람에게 가므로, 항목에는 이
  /// 경로를 넣어야 한다. 지우지 못했거나 그 사이 화면이 닫혔으면 `null`.
  /// 이때 원본을 대신 쓰지 않는다.
  Future<String?> prepareImage(String sourcePath) async {
    _isProcessingImage = true;
    _notify();
    try {
      return await _strip(sourcePath);
    } finally {
      _isProcessingImage = false;
      _notify();
    }
  }

  /// 여러 장을 [prepareImage]처럼 처리한다. 결과는 입력과 같은 순서이며,
  /// 처리하지 못한 사진 자리는 `null`이다.
  ///
  /// 한 장 끝날 때마다 알리므로 화면은 [processedImageCount] /
  /// [processingImageTotal]로 진행률을 보여 줄 수 있다. 원본 사진은 한 장에
  /// 수 초씩 걸릴 수 있어, 진행이 보이지 않으면 앱이 멈춘 것처럼 보인다.
  /// 도중에 화면이 닫히면 남은 사진은 처리하지 않는다.
  Future<List<String?>> prepareImages(List<String> sourcePaths) async {
    final results = <String?>[];
    _isProcessingImage = true;
    _processedImageCount = 0;
    _processingImageTotal = sourcePaths.length;
    _notify();
    try {
      for (final sourcePath in sourcePaths) {
        results.add(_disposed ? null : await _strip(sourcePath));
        _processedImageCount++;
        _notify();
      }
      return results;
    } finally {
      _isProcessingImage = false;
      _processedImageCount = 0;
      _processingImageTotal = 0;
      _notify();
    }
  }

  Future<String?> _strip(String sourcePath) async {
    try {
      final path = await _imageMetadata.stripMetadata(sourcePath);
      if (_disposed) {
        // 처리하는 사이 화면이 닫혔다. 방금 만든 사본은 쓰일 곳이 없다.
        if (path != sourcePath) _discard(path);
        return null;
      }
      if (path != sourcePath) _preparedPaths.add(path);
      return path;
    } catch (error, stackTrace) {
      log(
        '사진 메타데이터 제거 실패',
        error: error,
        stackTrace: stackTrace,
        name: 'worldcup_editor_view_model',
      );
      return null;
    }
  }

  void addItem(EditorItem item) {
    _items = [..._items, item];
    _notify();
  }

  /// [prepareImage]로 만들었지만 항목에 넣지 않기로 한 사본을 지운다.
  Future<void> discardPreparedImage(String path) async {
    if (!_preparedPaths.remove(path)) return;
    await _discardNow(path);
  }

  /// 목록에서 빠진 경로가 이번에 만든 사본이면 지운다.
  void _discardIfUnused(String path) {
    if (_items.any((item) => item.imagePath == path)) return;
    if (_preparedPaths.remove(path)) _discard(path);
  }

  void _discard(String path) => unawaited(_discardNow(path));

  Future<void> _discardNow(String path) async {
    try {
      await _imageMetadata.discard(path);
    } catch (error, stackTrace) {
      log(
        '사진 사본 정리 실패',
        error: error,
        stackTrace: stackTrace,
        name: 'worldcup_editor_view_model',
      );
    }
  }

  void replaceItem(int index, EditorItem item) {
    if (index < 0 || index >= _items.length) return;
    final previous = _items[index].imagePath;
    final next = [..._items];
    next[index] = item;
    _items = next;
    _discardIfUnused(previous);
    _notify();
  }

  void removeItemAt(int index) {
    if (index < 0 || index >= _items.length) return;
    final removed = _items[index].imagePath;
    final next = [..._items]..removeAt(index);
    _items = next;
    _discardIfUnused(removed);
    _notify();
  }

  /// 새 월드컵을 저장하고 만들어진 id를 돌려준다.
  ///
  /// 항목이 모자라면 `null`을 돌려준다. 저장에 실패하면 예외가 그대로
  /// 올라온다(저장소가 `StorageFailure`로 감싼다).
  Future<int?> save({required String title, required String info}) async {
    if (!hasEnoughItems) return null;

    // 첫 항목의 이미지를 대표 이미지로 쓴다.
    final model = WorldCupModel(
      0,
      title,
      info,
      DateTime.now(),
      _items.first.imagePath,
      _items.length,
    );
    final idx = await _repository.add(model, _toItemModels(0));
    // 이제 저장된 월드컵의 사진이다. 화면을 닫아도 지우면 안 된다.
    _preparedPaths.clear();
    return idx;
  }

  /// 수정 내용을 저장한다. 저장했으면 참을 돌려준다.
  ///
  /// 항목이 모자라거나 원본을 아직 못 불러왔으면 거짓을 돌려준다.
  Future<bool> update({required String title, required String info}) async {
    final original = _original;
    if (original == null || !hasEnoughItems) return false;

    // 등록일은 원본 것을 유지한다.
    final model = WorldCupModel(
      original.idx,
      title,
      info,
      original.date,
      _items.first.imagePath,
      _items.length,
    );
    await _repository.update(model, _toItemModels(original.idx));
    _preparedPaths.clear();
    return true;
  }

  List<WorldCupItemModel> _toItemModels(int worldCupIdx) => [
    for (final item in _items)
      WorldCupItemModel(0, item.imagePath, item.imageInfo, worldCupIdx),
  ];
}
