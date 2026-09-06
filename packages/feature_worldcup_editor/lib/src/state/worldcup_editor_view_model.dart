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

  /// 수정할 월드컵 id. `null`이면 새로 만드는 중이다.
  final int? editWorldCupId;

  WorldCupEditorViewModel(this._repository, {this.editWorldCupId});

  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
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

  List<EditorItem> get items => List.unmodifiable(_items);

  bool get isEditMode => editWorldCupId != null;

  /// 수정 모드에서 원본을 불러오는 중인지.
  bool get isLoading => _isLoading;

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

  void addItem(EditorItem item) {
    _items = [..._items, item];
    _notify();
  }

  void replaceItem(int index, EditorItem item) {
    if (index < 0 || index >= _items.length) return;
    final next = [..._items];
    next[index] = item;
    _items = next;
    _notify();
  }

  void removeItemAt(int index) {
    if (index < 0 || index >= _items.length) return;
    final next = [..._items]..removeAt(index);
    _items = next;
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
    return _repository.add(model, _toItemModels(0));
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
    return true;
  }

  List<WorldCupItemModel> _toItemModels(int worldCupIdx) => [
    for (final item in _items)
      WorldCupItemModel(0, item.imagePath, item.imageInfo, worldCupIdx),
  ];
}
