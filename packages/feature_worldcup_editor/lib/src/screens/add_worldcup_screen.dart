import 'package:worldcup_ui_kit/worldcup_ui_kit.dart';

import 'dart:developer';
import 'dart:io';

import 'package:dotted_border/dotted_border.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worldcup_domain/worldcup_domain.dart';

import '../state/worldcup_editor_view_model.dart';
import '../widgets/worldcup_add_picture_dialog.dart';
import '../widgets/worldcup_image_description_dialog.dart';

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
    imageMetadata: ref.read(imageMetadataProvider),
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
            isEditMode
                ? AppLocalizations.of(context).editorEditTitle
                : AppLocalizations.of(context).editorCreateTitle,
            semanticsLabel: isEditMode
                ? AppLocalizations.of(context).editorEditSemantics
                : AppLocalizations.of(context).editorCreateSemantics,
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Semantics(
                button: true,
                label: AppLocalizations.of(context).editorConfirmSemantics,
                child: IconButton(
                  onPressed: () async {
                    // 사진을 처리하는 동안에는 항목 목록이 아직 확정되지 않았다.
                    if (_vm.isProcessingImage) return;
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
                  icon: Icon(
                    Icons.check_rounded,
                    semanticLabel: AppLocalizations.of(context).commonConfirm,
                    size: 32,
                  ),
                ),
              ),
            ),
          ],
        ),
        body: Stack(
          children: [
            _buildBody(context),
            if (_vm.isProcessingImage)
              Positioned.fill(
                child: ColoredBox(
                  color: Colors.black26,
                  child: Center(child: _buildImageProcessingIndicator(context)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// 한 장이면 스피너, 여러 장이면 몇 장째인지 보이는 진행률 바.
  Widget _buildImageProcessingIndicator(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final total = _vm.processingImageTotal;
    if (total <= 1) {
      return CircularProgressIndicator(
        semanticsLabel: l10n.editorImageProcessing,
      );
    }
    final done = _vm.processedImageCount;
    final label = l10n.editorImageProcessingProgress(done, total);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 40),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: done / total,
              semanticsLabel: l10n.editorImageProcessing,
              semanticsValue: label,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return Padding(
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
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context).editorTitleLabel,
                    hintText: AppLocalizations.of(context).editorTitleHint,
                    hintStyle: const TextStyle(
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
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context).commonDescription,
                    hintText: AppLocalizations.of(context)
                        .editorDescriptionHint,
                    hintStyle: const TextStyle(
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
            AppLocalizations.of(context).editorItemCount(_imagePathList.length),
            style: (_imagePathList.isNotEmpty && _imagePathList.length > 3)
                ? isPictureListNotEmpty()
                : isPictureListEmpty(),
          ),
          const Padding(padding: EdgeInsetsDirectional.only(bottom: 10)),
          Row(
            children: [
              Expanded(
                child: Semantics(
                  label: AppLocalizations.of(context)
                      .editorSingleButtonSemantics,
                  child: InkWell(
                    onTap: () => showAddPictureDialog(context),
                    child: DottedBorder(
                      child: SizedBox(
                        height: 48,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add,
                              semanticLabel: AppLocalizations.of(context)
                                  .editorSingleImage,
                              size: 20,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              AppLocalizations.of(context).editorPickImage,
                              style: const TextStyle(fontSize: 14),
                            ),
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
                  label: AppLocalizations.of(context)
                      .editorMultipleButtonSemantics,
                  child: InkWell(
                    onTap: () => showMultipleImagePicker(context),
                    child: DottedBorder(
                      child: SizedBox(
                        height: 48,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add,
                              semanticLabel: AppLocalizations.of(context)
                                  .editorMultipleImages,
                              size: 20,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              AppLocalizations.of(context).editorPickMultiple,
                              style: const TextStyle(fontSize: 14),
                            ),
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
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
    );
  }

  // 유효성 검사
  String? checkTitle() {
    if (_titleController.text.isEmpty) {
      _titleFocusNode.requestFocus();
      return AppLocalizations.of(context).editorTitleRequired;
    }
    return null;
  }

  String? checkInfo() {
    if (_infoController.text.isEmpty) {
      if (_titleController.text.isNotEmpty) {
        _infoFocusNode.requestFocus();
      }
      return AppLocalizations.of(context).editorDescriptionRequired;
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
                icon: Icon(
                  Icons.highlight_remove_rounded,
                  color: Colors.red,
                  semanticLabel: AppLocalizations.of(context).commonDelete,
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
          title: Text(AppLocalizations.of(context).commonDelete),
          content: Text(
            AppLocalizations.of(context).editorDeleteImageConfirmation,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // 해당 아이템을 리스트에서 삭제. ViewModel이 알림을 보내
                // 화면이 다시 그려지므로 setState는 필요 없다.
                _vm.removeItemAt(index);
              },
              child: Text(AppLocalizations.of(context).commonYes),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(AppLocalizations.of(context).commonNo),
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
          title: Text(
            isEditMode
                ? AppLocalizations.of(context).editorCancelEditTitle
                : AppLocalizations.of(context).editorCancelCreateTitle,
          ),
          content: Text(
            isEditMode
                ? AppLocalizations.of(context).editorCancelEditBody
                : AppLocalizations.of(context).editorCancelCreateBody,
          ),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
                textStyle: Theme.of(dialogContext).textTheme.labelLarge,
              ),
              child: Text(AppLocalizations.of(context).commonNo),
              onPressed: () => Navigator.pop(dialogContext),
            ),
            TextButton(
              style: TextButton.styleFrom(
                textStyle: Theme.of(dialogContext).textTheme.labelLarge,
              ),
              child: Text(AppLocalizations.of(context).commonYes),
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
          SnackBar(
            content: Text(AppLocalizations.of(context).editorSaveFailed),
          ),
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
          SnackBar(
            content: Text(AppLocalizations.of(context).editorStillLoading),
          ),
        );
      }
      return updated;
    } catch (e) {
      log('DB Error', error: e, name: 'add_worldcup_screen');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).editorUpdateFailed),
          ),
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
      final path = await _prepareImage(result[0]);
      if (path == null) return;
      _vm.addItem(EditorItem(imagePath: path, imageInfo: result[1]));
    }
  }

  /// 새로 고른 사진의 메타데이터를 지운 사본 경로. 실패하면 알리고 null.
  Future<String?> _prepareImage(String sourcePath) async {
    final path = await _vm.prepareImage(sourcePath);
    if (path == null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).editorImageProcessFailed),
        ),
      );
    }
    return path;
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
      // 설명만 고쳤으면 이미 저장된 사진을 다시 처리하지 않는다.
      final path = result[0] == _imagePathList[index]
          ? result[0]
          : await _prepareImage(result[0]);
      if (path == null || !mounted) return;
      _vm.replaceItem(index, EditorItem(imagePath: path, imageInfo: result[1]));
    }
  }

  Future<void> showMultipleImagePicker(BuildContext context) async {
    FocusManager.instance.primaryFocus?.unfocus();

    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
    );

    if (result != null && result.files.isNotEmpty) {
      final pickedPaths = [
        for (final PlatformFile file in result.files)
          if (file.path != null) file.path!,
      ];
      // 설명을 묻기 전에 모두 처리해 둔다. 기다림이 한 번으로 모이고,
      // 그동안 진행률 바로 몇 장째인지 보여 준다.
      final preparedPaths = await _vm.prepareImages(pickedPaths);
      if (!context.mounted) return;
      final failedCount = preparedPaths.where((path) => path == null).length;
      if (failedCount > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)
                  .editorImagesProcessFailed(failedCount),
            ),
          ),
        );
      }

      for (final String? path in preparedPaths) {
        if (!context.mounted) return;
        if (path == null) continue;

        // 설명 입력 규칙(20자 제한, 빈 값 금지)은 다이얼로그가 들고 있다.
        // 컨트롤러도 다이얼로그가 소유하므로 여기서 해제하지 않는다.
        final String? description = await showDialog<String>(
          context: context,
          builder: (context) => WorldCupImageDescriptionDialog(imagePath: path),
        );

        if (!mounted) return;
        if (description != null) {
          _vm.addItem(EditorItem(imagePath: path, imageInfo: description));
        }
      }
    }
  }
}
