import 'dart:developer';
import 'dart:io';

import 'package:dotted_border/dotted_border.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worldcup_domain/worldcup_domain.dart';

import '../state/worldcup_editor_view_model.dart';
import '../widgets/worldcup_add_picture_dialog.dart';

class AddWorldCupScreen extends ConsumerStatefulWidget {
  /// 수정할 월드컵의 id. `null`이면 새로 만드는 화면이다.
  ///
  /// 라우트 인자가 엔티티가 아니라 id이므로 여기서 직접 조회한다.
  final int? editWorldCupId;

  const AddWorldCupScreen({super.key, this.editWorldCupId});

  @override
  ConsumerState<AddWorldCupScreen> createState() => _AddWorldCupScreenState();
}

class _AddWorldCupScreenState extends ConsumerState<AddWorldCupScreen> {
  /// 항목 목록과 저장 규칙. 화면은 입력 위젯만 들고 있는다.
  late final WorldCupEditorViewModel _vm = WorldCupEditorViewModel(
    ref.read(worldCupRepositoryProvider),
    editWorldCupId: widget.editWorldCupId,
  );

  late TextEditingController _titleController;
  late TextEditingController _infoController;
  late GlobalKey<FormState> _formKey;
  late FocusNode _titleFocusNode;
  late FocusNode _infoFocusNode;

  bool get isEditMode => widget.editWorldCupId != null;

  // ViewModel 항목을 기존 이름으로 읽는 통로. build()가 그대로 쓰인다.
  List<String> get _imagePathList => [
    for (final item in _vm.items) item.imagePath,
  ];
  List<String> get _imageInfoList => [
    for (final item in _vm.items) item.imageInfo,
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _infoController = TextEditingController();
    _formKey = GlobalKey<FormState>();
    _titleFocusNode = FocusNode();
    _infoFocusNode = FocusNode();

    _vm.addListener(_onViewModelChanged);
    if (isEditMode) {
      _initializeEditMode();
    }
  }

  void _onViewModelChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _titleController.dispose();
    _infoController.dispose();
    _titleFocusNode.dispose();
    _infoFocusNode.dispose();
    _vm.removeListener(_onViewModelChanged);
    _vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _showCancelDialog();
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          title: Text(
            isEditMode ? "월드컵 수정" : "월드컵 등록",
            semanticsLabel: isEditMode ? "월드컵 수정 화면" : "월드컵 등록 화면",
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Semantics(
                button: true,
                label: "Confirm Button",
                child: IconButton(
                  onPressed: () async {
                    if (isEditMode) {
                      final success = await updateWorldCup();
                      if (!success || !context.mounted) return;
                      Navigator.of(context).pop();
                      return;
                    }

                    final addedWorldCupIdx = await addWorldCup();
                    if (addedWorldCupIdx == null || !context.mounted) return;
                    Navigator.of(context).pop(addedWorldCupIdx);
                  },
                  icon: const Icon(
                    Icons.check_rounded,
                    semanticLabel: "확인",
                    size: 32,
                  ),
                ),
              ),
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _titleController,
                      validator: (value) => checkTitle(),
                      focusNode: _titleFocusNode,
                      decoration: const InputDecoration(
                        labelText: '제목',
                        hintText: '만드실 월드컵의 제목을 입력해주세요.',
                        hintStyle: TextStyle(
                          color: Colors.black38,
                          fontSize: 12,
                        ),
                      ),
                      maxLength: 100,
                    ),
                    TextFormField(
                      controller: _infoController,
                      validator: (value) => checkInfo(),
                      focusNode: _infoFocusNode,
                      decoration: const InputDecoration(
                        labelText: '설명',
                        hintText: '만드실 월드컵의 설명을 간단히 입력해주세요.',
                        hintStyle: TextStyle(
                          color: Colors.black38,
                          fontSize: 12,
                        ),
                      ),
                      maxLength: 150,
                    ),
                  ],
                ),
              ),
              const Padding(padding: EdgeInsetsDirectional.only(bottom: 10)),
              Text(
                "등록된 항목 개수 : ${_imagePathList.length}개",
                style: (_imagePathList.isNotEmpty && _imagePathList.length > 3)
                    ? isPictureListNotEmpty()
                    : isPictureListEmpty(),
              ),
              const Padding(padding: EdgeInsetsDirectional.only(bottom: 10)),
              Row(
                children: [
                  Expanded(
                    child: Semantics(
                      label: "Add Single Item Button",
                      child: InkWell(
                        onTap: () => showAddPictureDialog(context),
                        child: DottedBorder(
                          child: const SizedBox(
                            height: 48,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add,
                                  semanticLabel: "단일 추가",
                                  size: 20,
                                ),
                                SizedBox(width: 6),
                                Text("이미지 선택", style: TextStyle(fontSize: 14)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Semantics(
                      label: "Add Multiple Items Button",
                      child: InkWell(
                        onTap: () => showMultipleImagePicker(context),
                        child: DottedBorder(
                          child: const SizedBox(
                            height: 48,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add,
                                  semanticLabel: "복수 추가",
                                  size: 20,
                                ),
                                SizedBox(width: 6),
                                Text("여러개 선택", style: TextStyle(fontSize: 14)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const Padding(padding: EdgeInsetsDirectional.only(bottom: 10)),
              Expanded(
                child: Container(
                  padding: const EdgeInsetsDirectional.fromSTEB(20, 5, 20, 0),
                  decoration: BoxDecoration(
                    color: Colors.grey.withAlpha(50),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(30),
                    ),
                  ),
                  child: GridView.builder(
                    itemCount: _imageInfoList.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                    itemBuilder: (context, index) => makeListItem(
                      context,
                      index,
                      _imagePathList[index],
                      _imageInfoList[index],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 유효성 검사
  String? checkTitle() {
    if (_titleController.text.isEmpty) {
      _titleFocusNode.requestFocus();
      return '제목을 입력해주세요.';
    }
    return null;
  }

  String? checkInfo() {
    if (_infoController.text.isEmpty) {
      if (_titleController.text.isNotEmpty) {
        _infoFocusNode.requestFocus();
      }
      return '설명을 입력해주세요.';
    }
    return null;
  }

  Widget makeListItem(
    BuildContext context,
    int index,
    String src,
    String info,
  ) {
    return SizedBox(
      width: 100,
      height: 80,
      child: Stack(
        children: [
          Card(
            child: SingleChildScrollView(
              padding: const EdgeInsetsDirectional.fromSTEB(5, 25, 5, 20),
              child: Column(
                children: [
                  Text(
                    info,
                    style: const TextStyle(overflow: TextOverflow.ellipsis),
                  ),
                  InkWell(
                    onTap: () {
                      showEditPictureDialog(context, index);
                    },
                    child: AspectRatio(
                      aspectRatio: 2,
                      child: Image.file(
                        File(src),
                        fit: BoxFit.scaleDown,
                        // 카드 너비(100dp) 이상으로 디코딩할 필요가 없다.
                        cacheWidth:
                            (100 * MediaQuery.of(context).devicePixelRatio)
                                .round(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                visualDensity: VisualDensity.compact,
                icon: const Icon(
                  Icons.highlight_remove_rounded,
                  color: Colors.red,
                  semanticLabel: "삭제",
                ),
                onPressed: () => deleteDialog(index),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void deleteDialog(int index) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('삭제'),
          content: const Text('해당 이미지를 삭제하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // 해당 아이템을 리스트에서 삭제. ViewModel이 알림을 보내
                // 화면이 다시 그려지므로 setState는 필요 없다.
                _vm.removeItemAt(index);
              },
              child: const Text('네'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('아니오'),
            ),
          ],
        );
      },
    );
  }

  // 뒤로가기 시 등록/수정 취소 확인
  void _showCancelDialog() {
    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(isEditMode ? '수정 취소' : '등록 취소'),
          content: Text(isEditMode ? '수정을 취소하시겠습니까?' : '등록을 취소하시겠습니까?'),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
                textStyle: Theme.of(dialogContext).textTheme.labelLarge,
              ),
              child: const Text('아니오'),
              onPressed: () => Navigator.pop(dialogContext),
            ),
            TextButton(
              style: TextButton.styleFrom(
                textStyle: Theme.of(dialogContext).textTheme.labelLarge,
              ),
              child: const Text('네'),
              onPressed: () {
                Navigator.pop(dialogContext); // 다이얼로그 닫기
                Navigator.of(context).pop(); // 등록 화면 닫기
              },
            ),
          ],
        );
      },
    );
  }

  // 월드컵 등록
  Future<int?> addWorldCup() async {
    // 키보드 내리기
    FocusManager.instance.primaryFocus?.unfocus();
    // 제목, 설명 입력 체크
    if (!_formKey.currentState!.validate()) return null;

    try {
      return await _vm.save(
        title: _titleController.text,
        info: _infoController.text,
      );
    } catch (e) {
      log('DB Error', error: e, name: 'add_worldcup_screen');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("데이터를 저장할 수 없습니다. 잠시후에 다시 시도해주세요.")),
        );
      }
      return null;
    }
  }

  TextStyle isPictureListEmpty() {
    return const TextStyle(color: Colors.red, fontWeight: FontWeight.bold);
  }

  TextStyle isPictureListNotEmpty() {
    return const TextStyle(color: Colors.black, fontWeight: FontWeight.normal);
  }

  Future<void> _initializeEditMode() async {
    await _vm.load();
    if (!mounted) return;
    // 텍스트 컨트롤러는 화면이 들고 있으므로 여기서 채운다.
    _titleController.text = _vm.originalTitle;
    _infoController.text = _vm.originalInfo;
  }

  Future<bool> updateWorldCup() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!_formKey.currentState!.validate()) return false;

    try {
      final updated = await _vm.update(
        title: _titleController.text,
        info: _infoController.text,
      );
      // 원본을 아직 못 불러왔으면 덮어쓸 수 없다. 보통 화면 진입 직후
      // 한순간뿐이지만, 아무 반응 없이 끝나면 안 되므로 알린다.
      if (!updated && !_vm.isReady && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("월드컵 정보를 아직 불러오는 중입니다. 잠시 후 다시 시도해주세요."),
          ),
        );
      }
      return updated;
    } catch (e) {
      log('DB Error', error: e, name: 'add_worldcup_screen');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("데이터를 업데이트할 수 없습니다. 잠시후에 다시 시도해주세요.")),
        );
      }
      return false;
    }
  }

  Future<void> showAddPictureDialog(BuildContext context) async {
    FocusManager.instance.primaryFocus?.unfocus();

    final result = await showDialog<List<String>>(
      context: context,
      builder: (context) {
        return const WorldCupAddPictureDialog();
      },
    );

    if (!mounted) return;
    if (result != null && result.isNotEmpty) {
      _vm.addItem(EditorItem(imagePath: result[0], imageInfo: result[1]));
    }
  }

  Future<void> showEditPictureDialog(BuildContext context, int index) async {
    FocusManager.instance.primaryFocus?.unfocus();

    final result = await showDialog<List<String>>(
      context: context,
      builder: (context) {
        return WorldCupAddPictureDialog(
          isEditMode: true,
          existingImageInfo: _imageInfoList[index],
          existingImagePath: _imagePathList[index],
        );
      },
    );

    if (!mounted) return;
    if (result != null && result.isNotEmpty) {
      _vm.replaceItem(
        index,
        EditorItem(imagePath: result[0], imageInfo: result[1]),
      );
    }
  }

  Future<void> showMultipleImagePicker(BuildContext context) async {
    FocusManager.instance.primaryFocus?.unfocus();

    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
    );

    if (result != null && result.files.isNotEmpty) {
      for (PlatformFile file in result.files) {
        if (!context.mounted) return;
        if (file.path != null) {
          TextEditingController controller = TextEditingController();
          String? description = await showDialog<String>(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: const Text('이미지 설명'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.file(
                      File(file.path!),
                      height: 200,
                      fit: BoxFit.contain,
                      // 미리보기 높이(200dp) 이상으로 디코딩할 필요가 없다.
                      cacheHeight:
                          (200 * MediaQuery.of(context).devicePixelRatio)
                              .round(),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: controller,
                      autofocus: true,
                      decoration: const InputDecoration(
                        labelText: '설명',
                        hintText: '이미지에 대한 설명을 입력하세요',
                      ),
                      onSubmitted: (value) {
                        Navigator.of(context)
                            .pop(value.isNotEmpty ? value : '설명 없음');
                      },
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('취소'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(
                        controller.text.isNotEmpty ? controller.text : '설명 없음',
                      );
                    },
                    child: const Text('확인'),
                  ),
                ],
              );
            },
          );

          if (!mounted) return;
          if (description != null) {
            _vm.addItem(
              EditorItem(imagePath: file.path!, imageInfo: description),
            );
          }
        }
      }
    }
  }
}
