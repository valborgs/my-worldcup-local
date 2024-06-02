import 'package:flutter/material.dart';
import 'package:my_worldcup_local/models/worldcup_model.dart';

import '../dto/worldcup_dao.dart';

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

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _infoController = TextEditingController();
    _formKey = GlobalKey<FormState>();
    _titleFocusNode = FocusNode();
    _infoFocusNode = FocusNode();
  }

  @override
  void dispose() {
    super.dispose();
    _titleController.dispose();
    _infoController.dispose();
    _titleFocusNode.dispose();
    _infoFocusNode.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text("월드컵 등록"),
        actions: [
          IconButton(
            onPressed: () => addWorldCup(),
            icon: const Icon(Icons.check_rounded),
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

  // 월드컵 등록
  Future<void> addWorldCup() async {
    // 키보드 내리기
    FocusManager.instance.primaryFocus?.unfocus();
    // 제목, 설명 입력 체크
    if(!_formKey.currentState!.validate()) return;

    // Dao 객체
    var dao = WorldCupDao();
    // 월드컵 객체 생성
    var model = WorldCupModel(
        0,
        _titleController.text,
        _infoController.text,
        DateTime.now(),
        "",
        4
    );

    // 등록
    try{
      dao.addWorldCup(model);
      Navigator.pop(context);
    }catch(e){
      print("DB Error : $e");
      const SnackBar(content: Text("데이터를 저장할 수 없습니다. 잠시후에 다시 시도해주세요."));
    }
  }
}
