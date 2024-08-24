import 'dart:io';

import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:my_worldcup_local/widgets/outlined_icon_button.dart';

class WorldCupAddPictureDialog extends StatefulWidget {
  const WorldCupAddPictureDialog({super.key});

  @override
  State<WorldCupAddPictureDialog> createState() => _WorldCupAddPictureDialogState();
}

class _WorldCupAddPictureDialogState extends State<WorldCupAddPictureDialog> {

  late TextEditingController _imageInfoController;
  late FocusNode _imageInfoFocusNode;
  late GlobalKey<FormState> _formKey;
  String _preImagePath = "";
  bool isPictureEmpty = false;


  @override
  void initState() {
    super.initState();
    _imageInfoController = TextEditingController();
    _imageInfoFocusNode = FocusNode();
    _formKey = GlobalKey<FormState>();
  }

  @override
  void dispose() {
    super.dispose();
    _imageInfoController.dispose();
    _imageInfoFocusNode.dispose();
    _preImagePath = "";
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(

      scrollable: true,
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          children: [
            const Text(
              "사진 추가",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              semanticsLabel: "사진 추가",
            ),
            const Padding(
                padding: EdgeInsetsDirectional.only(bottom: 10)),
            Row(
              children: [
                // 사진 찍기
                Expanded(
                  child: Semantics(
                    label: "Take a photo",
                    child: InkWell(
                      onTap: () => getCameraImage(),
                      child: Column(
                        children: [
                          DottedBorder(
                            color: Colors.black,
                            strokeWidth: 1,
                            child: Container(
                              width: double.maxFinite,
                              height: 48,
                              decoration: const BoxDecoration(
                                  color: Colors.grey),
                              child: const Icon(Icons.camera_alt, semanticLabel: "카메라"),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // 앨범에서 가져오기
                Expanded(
                  child: Semantics(
                    label: "Get a picture from album",
                    child: InkWell(
                      onTap: () => getAlbumImage(),
                      child: Column(
                        children: [
                          DottedBorder(
                            color: Colors.black,
                            strokeWidth: 1,
                            child: Container(
                              width: double.maxFinite,
                              height: 48,
                              decoration: const BoxDecoration(
                                  color: Colors.grey),
                              child: const Icon(Icons.photo_album, semanticLabel: "앨범"),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const Padding(padding: EdgeInsetsDirectional.only(bottom: 10)),
            SizedBox(
              width: 150,
              height: _preImagePath != ""
                  ? 200 : 0,
              child: _preImagePath != ""
                  ? Image.file(File(_preImagePath))
                  : Image.asset("assets/images/free_character.png"),
            ),
            isPictureEmpty
                ? const Text("사진을 추가해주세요", style: const TextStyle(color: Colors.red),)
                : const Padding(padding: EdgeInsetsDirectional.only(bottom: 1)),
            const Padding(padding: EdgeInsetsDirectional.only(bottom: 10)),
            // 사진 설명 입력
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _imageInfoController,
                    validator: (value) => checkImageInfo(),
                    focusNode: _imageInfoFocusNode,
                    decoration: const InputDecoration(
                      labelText: '사진 설명',
                      hintStyle: TextStyle(
                        color: Colors.black38,
                        fontSize: 12,
                      ),
                    ),
                    maxLength: 20,
                  ),
                ],
              ),
            ),
            const Padding(padding: EdgeInsetsDirectional.only(bottom: 10)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconOutlinedButton("취소", Icons.cancel_outlined, Colors.red, onPressed: () => Navigator.pop(context),),
                IconOutlinedButton("추가", Icons.check, Colors.deepPurple, onPressed: addPicture,),
              ],
            )
          ],
        ),
      ),
    );
  }

  Future<void> getAlbumImage() async{
    FocusManager.instance.primaryFocus?.unfocus();
    final ImagePicker picker = ImagePicker();
    XFile? file = await picker.pickImage(source: ImageSource.gallery);
    if(file != null){
      setState(() {
        _preImagePath = file.path;
      });
    }
  }

  Future<void> getCameraImage() async{
    FocusManager.instance.primaryFocus?.unfocus();
    final ImagePicker picker = ImagePicker();
    XFile? file = await picker.pickImage(source: ImageSource.camera);
    if(file != null){
      setState(() {
        _preImagePath = file.path;
      });
    }
  }

  void addPicture() {
    setState(() {
      isPictureEmpty = false;
    });
    // 키보드 내리기
    FocusManager.instance.primaryFocus?.unfocus();
    if(_preImagePath.isEmpty){
      setState(() {
        isPictureEmpty = true;
      });
      return;
    }
    if(!_formKey.currentState!.validate()) return;
    Navigator.pop(context, [_preImagePath, _imageInfoController.text]);
  }

  // 유효성 검사
  String? checkImageInfo() {
    if(_imageInfoController.text.isEmpty){
      return '사진 설명을 입력해주세요.';
    }
    return null;
  }

  void resetAddPicture(){
    setState(() {
      _preImagePath = "";
      _imageInfoController.clear();
      _imageInfoFocusNode.unfocus();
    });
  }

}
