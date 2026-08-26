import 'dart:developer';
import 'dart:io';

import 'package:dotted_border/dotted_border.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:my_worldcup_local/models/worldcup_item_model.dart';
import 'package:my_worldcup_local/models/worldcup_model.dart';

import '../dto/worldcup_dao.dart';
import '../widgets/worldcup_add_picutre_dialog.dart';

class AddWorldCupScreen extends StatefulWidget {
  final WorldCupModel? editModel;
  const AddWorldCupScreen({super.key, this.editModel});

  @override
  State<AddWorldCupScreen> createState() => _AddWorldCupScreenState();
}

class _AddWorldCupScreenState extends State<AddWorldCupScreen> {

  late TextEditingController _titleController;
  late TextEditingController _infoController;
  late GlobalKey<FormState> _formKey;
  late FocusNode _titleFocusNode;
  late FocusNode _infoFocusNode;
  late List<String> _imagePathList;
  late List<String> _imageInfoList;
  bool get isEditMode => widget.editModel != null;


  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _infoController = TextEditingController();
    _formKey = GlobalKey<FormState>();
    _titleFocusNode = FocusNode();
    _infoFocusNode = FocusNode();
    _imagePathList = [];
    _imageInfoList = [];
    
    if (isEditMode) {
      _initializeEditMode();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _infoController.dispose();
    _titleFocusNode.dispose();
    _infoFocusNode.dispose();
    _imagePathList = [];
    _imageInfoList = [];
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text(isEditMode ? "월드컵 수정" : "월드컵 등록", semanticsLabel: isEditMode ? "월드컵 수정 화면" : "월드컵 등록 화면",),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Semantics(
              button: true,
              label: "Confirm Button",
              child: IconButton(
                onPressed: () async {
                  final success = isEditMode ? await updateWorldCup() : await addWorldCup();
                  if (success) {
                    if (!context.mounted) return;
                    Navigator.of(context).pop();
                  }
                } ,
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
              style: (_imagePathList.isNotEmpty && _imagePathList.length>3)
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
                              Text(
                                "이미지 선택",
                                style: TextStyle(fontSize: 14),
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
                              Text(
                                "여러개 선택",
                                style: TextStyle(fontSize: 14),
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
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                ),

                child: GridView.builder(
                  itemCount: _imageInfoList.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemBuilder: (context, index) => makeListItem(context, index, _imagePathList[index], _imageInfoList[index]),
                )
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 유효성 검사
  String? checkTitle() {
    if(_titleController.text.isEmpty){
      _titleFocusNode.requestFocus();
      return '제목을 입력해주세요.';
    }
    return null;
  }

  String? checkInfo() {
    if(_infoController.text.isEmpty){
      if(_titleController.text.isNotEmpty){
        _infoFocusNode.requestFocus();
      }
      return '설명을 입력해주세요.';
    }
    return null;
  }

  Widget makeListItem(BuildContext context, int index, String src, String info){
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
                    style: const TextStyle(
                      overflow: TextOverflow.ellipsis,
                    ),
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
                        cacheWidth: (100 * MediaQuery.of(context).devicePixelRatio).round(),
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

  void deleteDialog(int index){
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
                // 해당 아이템을 리스트에서 삭제
                setState(() {
                  _imagePathList.removeAt(index);
                  _imageInfoList.removeAt(index);
                });
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

  // 월드컵 등록
  Future<bool> addWorldCup() async {
    // 키보드 내리기
    FocusManager.instance.primaryFocus?.unfocus();
    // 제목, 설명 입력 체크
    if(!_formKey.currentState!.validate()) return false;

    // 등록된 항목이 없을 경우 체크
    if(_imagePathList.isEmpty || _imagePathList.length<4){
      return false;
    }

    // Dao 객체
    var dao = WorldCupDao();
    // 월드컵 객체 생성
    var model = WorldCupModel(
        0,
        _titleController.text,
        _infoController.text,
        DateTime.now(),
        _imagePathList.first,
        _imagePathList.length
    );

    // 등록
    try{
      final items = List.generate(
        _imagePathList.length,
        (index) => WorldCupItemModel(0, _imagePathList[index], _imageInfoList[index], 0),
      );
      await dao.addWorldCupWithItems(model, items);
      return true;
    }catch(e){
      log('DB Error', error: e, name: 'add_worldcup_screen');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("데이터를 저장할 수 없습니다. 잠시후에 다시 시도해주세요.")),
        );
      }
      return false;
    }
  }

  TextStyle isPictureListEmpty(){
    return const TextStyle(
      color: Colors.red,
      fontWeight: FontWeight.bold,
    );
  }

  TextStyle isPictureListNotEmpty(){
    return const TextStyle(
      color: Colors.black,
      fontWeight: FontWeight.normal,
    );
  }

  void _initializeEditMode() async {
    if (widget.editModel != null) {
      _titleController.text = widget.editModel!.title;
      _infoController.text = widget.editModel!.info;
      
      WorldCupDao dao = WorldCupDao();
      List<WorldCupItemModel> items = await dao.getWorldCupItemList(widget.editModel!.idx);
      if (!mounted) return;
      setState(() {
        _imagePathList = items.map((item) => item.imagePath).toList();
        _imageInfoList = items.map((item) => item.imageInfo).toList();
      });
    }
  }

  Future<bool> updateWorldCup() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if(!_formKey.currentState!.validate()) return false;

    if(_imagePathList.isEmpty || _imagePathList.length<4){
      return false;
    }

    var dao = WorldCupDao();
    var model = WorldCupModel(
        widget.editModel!.idx,
        _titleController.text,
        _infoController.text,
        widget.editModel!.date,
        _imagePathList.first,
        _imagePathList.length
    );

    try{
      final items = List.generate(
        _imagePathList.length,
        (index) => WorldCupItemModel(
          0,
          _imagePathList[index],
          _imageInfoList[index],
          widget.editModel!.idx,
        ),
      );
      await dao.updateWorldCupWithItems(model, items);
      return true;
    }catch(e){
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
        }
    );

    if (!mounted) return;
    if(result != null && result.isNotEmpty){
      setState(() {
        _imagePathList.add(result[0]);
        _imageInfoList.add(result[1]);
      });
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
            existingImagePath: _imagePathList[index]
          );
        }
    );

    if (!mounted) return;
    if(result != null && result.isNotEmpty){
      setState(() {
        _imagePathList[index] = result[0];
        _imageInfoList[index] = result[1];
      });
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
                      cacheHeight: (200 * MediaQuery.of(context).devicePixelRatio).round(),
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
                        Navigator.of(context).pop(value.isNotEmpty ? value : '설명 없음');
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
                      Navigator.of(context).pop(controller.text.isNotEmpty ? controller.text : '설명 없음');
                    },
                    child: const Text('확인'),
                  ),
                ],
              );
            },
          );

          if (!mounted) return;
          if (description != null) {
            setState(() {
              _imagePathList.add(file.path!);
              _imageInfoList.add(description);
            });
          }
        }
      }
    }
  }
}



