import 'dart:io';

import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:worldcup_ui_kit/worldcup_ui_kit.dart';

class WorldCupAddPictureDialog extends StatefulWidget {
  final bool isEditMode;
  final String? existingImageInfo;
  final String? existingImagePath;
  const WorldCupAddPictureDialog({
    super.key,
    this.isEditMode = false,
    this.existingImageInfo,
    this.existingImagePath,
  });

  @override
  State<WorldCupAddPictureDialog> createState() =>
      _WorldCupAddPictureDialogState();
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

    if (widget.isEditMode) {
      if (widget.existingImageInfo != null) {
        _imageInfoController.text = widget.existingImageInfo!;
      }
      if (widget.existingImagePath != null) {
        _preImagePath = widget.existingImagePath!;
      }
    }
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
            Text(
              widget.isEditMode
                  ? AppLocalizations.of(context).editorEditPhoto
                  : AppLocalizations.of(context).editorAddPhoto,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              semanticsLabel: widget.isEditMode
                  ? AppLocalizations.of(context).editorEditPhoto
                  : AppLocalizations.of(context).editorAddPhoto,
            ),
            const Padding(padding: EdgeInsetsDirectional.only(bottom: 10)),
            Row(
              children: [
                // 사진 찍기
                Expanded(
                  child: Semantics(
                    label: AppLocalizations.of(context).editorTakePhoto,
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
                                color: Colors.grey,
                              ),
                              child: Icon(
                                Icons.camera_alt,
                                semanticLabel: AppLocalizations.of(context)
                                    .editorCamera,
                              ),
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
                    label: AppLocalizations.of(context).editorFromAlbum,
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
                                color: Colors.grey,
                              ),
                              child: Icon(
                                Icons.photo_album,
                                semanticLabel: AppLocalizations.of(context)
                                    .editorAlbum,
                              ),
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
              height: _preImagePath != "" ? 200 : 0,
              child: _preImagePath != ""
                  ? InkWell(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) {
                            return Dialog(
                              child: InteractiveViewer(
                                child: Image.file(File(_preImagePath)),
                              ),
                            );
                          },
                        );
                      },
                      child: Image.file(
                        File(_preImagePath),
                        // 미리보기 박스(150x200dp) 이상으로 디코딩할 필요가 없다.
                        cacheWidth:
                            (150 * MediaQuery.of(context).devicePixelRatio)
                                .round(),
                      ),
                    )
                  : Image.asset("assets/images/free_character.png"),
            ),
            isPictureEmpty
                ? Text(
                    AppLocalizations.of(context).editorPhotoRequired,
                    style: const TextStyle(color: Colors.red),
                  )
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
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)
                          .editorPhotoDescription,
                      hintStyle: const TextStyle(
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
                IconOutlinedButton(
                  AppLocalizations.of(context).commonCancel,
                  Icons.cancel_outlined,
                  Colors.red,
                  onPressed: () => Navigator.pop(context),
                ),
                IconOutlinedButton(
                  widget.isEditMode
                      ? AppLocalizations.of(context).commonEdit
                      : AppLocalizations.of(context).commonAdd,
                  Icons.check,
                  Colors.deepPurple,
                  onPressed: addPicture,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> getAlbumImage() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final ImagePicker picker = ImagePicker();
    XFile? file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1280,
      maxHeight: 1280,
      imageQuality: 85,
    );
    if (file != null) {
      setState(() {
        _preImagePath = file.path;
      });
    }
  }

  Future<void> getCameraImage() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final ImagePicker picker = ImagePicker();
    XFile? file = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1280,
      maxHeight: 1280,
      imageQuality: 85,
    );
    if (file != null) {
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
    if (_preImagePath.isEmpty) {
      setState(() {
        isPictureEmpty = true;
      });
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, [_preImagePath, _imageInfoController.text]);
  }

  // 유효성 검사
  String? checkImageInfo() {
    if (_imageInfoController.text.isEmpty) {
      return AppLocalizations.of(context).editorPhotoDescriptionRequired;
    }
    return null;
  }

  void resetAddPicture() {
    setState(() {
      _preImagePath = "";
      _imageInfoController.clear();
      _imageInfoFocusNode.unfocus();
    });
  }
}
