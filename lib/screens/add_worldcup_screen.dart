import 'dart:io';

import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:my_worldcup_local/models/worldcup_item_model.dart';
import 'package:my_worldcup_local/models/worldcup_model.dart';

import '../dto/worldcup_dao.dart';
import '../widgets/worldcup_add_picutre_dialog.dart';

class AddWorldCupScreen extends StatefulWidget {
  const AddWorldCupScreen({super.key});

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
  }

  @override
  void dispose() {
    super.dispose();
    _titleController.dispose();
    _infoController.dispose();
    _titleFocusNode.dispose();
    _infoFocusNode.dispose();
    _imagePathList = [];
    _imageInfoList = [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text("월드컵 등록", semanticsLabel: "월드컵 등록 화면",),
        actions: [
          Semantics(
            button: true,
            label: "Confirm Button",
            child: IconButton(
              onPressed: () {
                addWorldCup().then((value) {
                  if(value){
                    Navigator.of(context).pop();
                  }
                });
              } ,
              icon: const Icon(Icons.check_rounded),
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
            Semantics(
              label: "Add Item Button",
              child: InkWell(
                onTap: () => showAddPictureDialog(context),
                child: Column(
                  children: [
                    DottedBorder(
                      child: const SizedBox(
                        width: double.maxFinite,
                        height: 48,
                        child: Icon(Icons.add),
                      ),
                    ),
                  ],
                ),
              ),
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
                      FocusManager.instance.primaryFocus?.unfocus();
                      showDialog(
                        context: context,
                        builder: (context) {
                          Image image = Image.file(
                            File(src),
                          );
                          return Dialog(
                            child: SizedBox(
                              width: image.width,
                              height: image.height,
                              child: image,
                            ),
                          );
                        },
                      );
                    },
                    child: AspectRatio(
                      aspectRatio: 2,
                      child: Image.file(
                        File(src),
                        fit: BoxFit.scaleDown,
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
      // 월드컵 등록
      int worldCupIdx = await dao.addWorldCup(model);
      // 월드컵 항목 등록
      for(int i=0; i<_imagePathList.length; i++){
        WorldCupItemModel itemModel = WorldCupItemModel(0, _imagePathList[i], _imageInfoList[i], worldCupIdx);
        await dao.addWorldCupItem(itemModel);
      }
      return true;
    }catch(e){
      print("DB Error : $e");
      const SnackBar(content: Text("데이터를 저장할 수 없습니다. 잠시후에 다시 시도해주세요."));
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

  Future<void> showAddPictureDialog(BuildContext context) async {
    // 키보드 내리기
    FocusManager.instance.primaryFocus?.unfocus();

    List<String> result = await showDialog(
        context: context,
        builder: (context) {
          return const WorldCupAddPictureDialog();
        }
    );

    if(result.isNotEmpty){
      setState(() {
        _imagePathList.add(result[0]);
        _imageInfoList.add(result[1]);
      });
    }
  }
}



