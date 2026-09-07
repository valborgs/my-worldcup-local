import 'dart:io';

import 'package:flutter/material.dart';

/// 여러 장을 한 번에 고른 뒤 장당 한 번씩 열리는 설명 입력 다이얼로그.
///
/// 설명 규칙은 [WorldCupAddPictureDialog]와 같다 — 20자 제한, 빈 값 금지.
///
/// 컨트롤러를 이 위젯이 소유하는 것이 중요하다. 호출부가 `showDialog`를 await한
/// 뒤 곧바로 dispose하면 안 된다: pop된 라우트의 Future는 퇴장 애니메이션이
/// 끝나기 전에 완료되므로 그 시점의 `TextFormField`는 아직 마운트되어 있고,
/// "A TextEditingController was used after being disposed" 뒤에 트리 해제가
/// 중단되면서 `_dependents.isEmpty` 어설션으로 앱 전체가 에러 화면이 된다.
class WorldCupImageDescriptionDialog extends StatefulWidget {
  final String imagePath;

  const WorldCupImageDescriptionDialog({super.key, required this.imagePath});

  @override
  State<WorldCupImageDescriptionDialog> createState() =>
      _WorldCupImageDescriptionDialogState();
}

class _WorldCupImageDescriptionDialogState
    extends State<WorldCupImageDescriptionDialog> {
  late final TextEditingController _controller;
  late final GlobalKey<FormState> _formKey;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _formKey = GlobalKey<FormState>();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    // 키보드 내리기
    FocusManager.instance.primaryFocus?.unfocus();
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('이미지 설명'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.file(
            File(widget.imagePath),
            height: 200,
            fit: BoxFit.contain,
            // 미리보기 높이(200dp) 이상으로 디코딩할 필요가 없다.
            cacheHeight: (200 * MediaQuery.of(context).devicePixelRatio)
                .round(),
          ),
          const SizedBox(height: 10),
          Form(
            key: _formKey,
            child: TextFormField(
              controller: _controller,
              autofocus: true,
              maxLength: 20,
              validator: (value) =>
                  (value == null || value.isEmpty) ? '사진 설명을 입력해주세요.' : null,
              decoration: const InputDecoration(
                labelText: '설명',
                hintText: '이미지에 대한 설명을 입력하세요',
              ),
              onFieldSubmitted: (_) => _submit(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),
        TextButton(onPressed: _submit, child: const Text('확인')),
      ],
    );
  }
}
