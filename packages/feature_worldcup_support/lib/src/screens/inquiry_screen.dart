import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worldcup_domain/worldcup_domain.dart';

import '../state/support_view_models.dart';

class InquiryScreen extends ConsumerStatefulWidget {
  const InquiryScreen({super.key});
  @override
  ConsumerState<InquiryScreen> createState() => _InquiryScreenState();
}

class _InquiryScreenState extends ConsumerState<InquiryScreen> {
  late final InquiryViewModel _vm;
  final _email = TextEditingController();
  final _content = TextEditingController();
  final _form = GlobalKey<FormState>();
  bool _picking = false;
  bool _leaving = false;
  bool _confirmingLeave = false;
  bool _confirmingResend = false;

  @override
  void initState() {
    super.initState();
    _vm = InquiryViewModel(
      ref.read(supportProvider),
      ref.read(inquiryImageUploadProvider),
    );
  }

  @override
  void dispose() {
    _vm.dispose();
    _email.dispose();
    _content.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    if (_picking || _vm.busy) return;
    setState(() => _picking = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['png', 'jpg', 'jpeg', 'webp'],
        withData: false,
        withReadStream: true,
        allowMultiple: false,
      );
      if (!mounted) return;
      if (result == null) return;
      final file = result.files.single;
      if (file.size > InquiryViewModel.maxImageBytes) {
        throw const SupportFailure('image_size', '10MB 이하의 이미지를 선택해 주세요.');
      }
      final stream = file.readStream;
      if (stream == null) {
        _vm.selectionFailed();
      } else {
        final bytes = await InquiryViewModel.readScreenshot(stream);
        if (!mounted) return;
        // Reject renamed/non-image files before uploading them.
        final codec = await ui.instantiateImageCodec(
          bytes,
          targetWidth: 1,
          targetHeight: 1,
        );
        try {
          final frame = await codec.getNextFrame();
          frame.image.dispose();
        } finally {
          codec.dispose();
        }
        if (!mounted) return;
        _vm.setScreenshot(bytes, file.name);
      }
    } on SupportFailure catch (failure) {
      if (mounted) _vm.attachmentFailed(failure);
    } catch (_) {
      if (mounted) _vm.selectionFailed();
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<void> _submit() async {
    if (_vm.busy ||
        _picking ||
        _confirmingResend ||
        !_form.currentState!.validate()) {
      return;
    }
    var confirmed = false;
    if (_vm.deliveryUncertain) {
      _confirmingResend = true;
      confirmed =
          await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('문의를 다시 전송할까요?'),
              content: const Text(
                '이전 문의가 이미 접수되었을 수 있습니다. 다시 전송하면 같은 문의가 중복 접수될 수 있습니다.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('취소'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('다시 전송'),
                ),
              ],
            ),
          ) ??
          false;
      _confirmingResend = false;
      if (!mounted || !confirmed) return;
    }
    FocusScope.of(context).unfocus();
    await _vm.submit(
      content: _content.text,
      email: _email.text,
      confirmResend: confirmed,
    );
    if (!mounted) return;
    if (_vm.receipt != null) {
      _email.clear();
      _content.clear();
    }
  }

  Future<void> _leave() async {
    if (_vm.busy || _picking || _confirmingLeave) return;
    if (_vm.receipt == null &&
        (_email.text.isNotEmpty ||
            _content.text.isNotEmpty ||
            _vm.screenshot != null)) {
      _confirmingLeave = true;
      final discard =
          await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('작성을 그만둘까요?'),
              content: const Text('작성 중인 문의는 저장되지 않습니다.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('계속 작성'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('나가기'),
                ),
              ],
            ),
          ) ??
          false;
      _confirmingLeave = false;
      if (!mounted || !discard) return;
    }
    setState(() => _leaving = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _vm,
    builder: (context, _) {
      final blocked = _vm.busy || _picking;
      final receipt = _vm.receipt;
      return PopScope(
        canPop: _leaving,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) _leave();
        },
        child: Scaffold(
          appBar: AppBar(
            title: const Text('문의함'),
            leading: BackButton(onPressed: blocked ? null : _leave),
          ),
          body: SafeArea(
            child: receipt != null
                ? Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            size: 64,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '문의가 접수되었습니다.',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text('접수 번호: ${receipt.id}'),
                          const SizedBox(height: 24),
                          FilledButton(
                            onPressed: _leave,
                            child: const Text('확인'),
                          ),
                        ],
                      ),
                    ),
                  )
                : Form(
                    key: _form,
                    child: ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        Text(
                          '의견을 들려주세요',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        const Text('불편한 점이나 제안하고 싶은 내용을 남겨 주세요.'),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _email,
                          enabled: !blocked,
                          keyboardType: TextInputType.emailAddress,
                          autocorrect: false,
                          maxLength: 254,
                          validator: (value) =>
                              InquiryViewModel.validateEmail(value ?? ''),
                          decoration: const InputDecoration(
                            labelText: '이메일 (선택)',
                            helperText: '답변받을 이메일을 남겨 주세요.',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _content,
                          enabled: !blocked,
                          keyboardType: TextInputType.multiline,
                          minLines: 7,
                          maxLines: 14,
                          maxLength: 5000,
                          validator: (value) =>
                              InquiryViewModel.validateContent(value ?? ''),
                          decoration: const InputDecoration(
                            labelText: '문의 내용',
                            alignLabelWithHint: true,
                            hintText: '문제가 발생한 상황을 자세히 알려 주세요.',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: OutlinedButton.icon(
                            onPressed: blocked ? null : _pick,
                            icon: const Icon(
                              Icons.add_photo_alternate_outlined,
                            ),
                            label: Text(
                              _picking
                                  ? '이미지 선택 중…'
                                  : _vm.screenshot == null
                                  ? '스크린샷 첨부 (선택)'
                                  : '스크린샷 변경',
                            ),
                          ),
                        ),
                        const Text('PNG, JPG, WEBP · 최대 10MB · 1장'),
                        if (_vm.screenshot != null) ...[
                          const SizedBox(height: 12),
                          Image.memory(
                            _vm.screenshot!,
                            height: 180,
                            fit: BoxFit.contain,
                            semanticLabel: '선택한 스크린샷',
                            errorBuilder: (context, error, stack) =>
                                const Text('이미지를 표시할 수 없습니다. 다른 파일을 선택해 주세요.'),
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _vm.screenshotName ?? '스크린샷',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              IconButton(
                                tooltip: '첨부 제거',
                                onPressed: blocked
                                    ? null
                                    : () => _vm.setScreenshot(null, null),
                                icon: const Icon(Icons.close),
                              ),
                            ],
                          ),
                          const Text(
                            '첨부 이미지는 외부 이미지 호스팅에 업로드되며 3일 후 만료됩니다. 개인정보가 보이지 않도록 확인해 주세요.',
                          ),
                        ],
                        if (_vm.error != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Semantics(
                              liveRegion: true,
                              child: Text(
                                [
                                  _vm.error!.message,
                                  for (final messages
                                      in _vm.error!.fields.values)
                                    ...messages,
                                  if (_vm.error!.retryAfterSeconds != null)
                                    '${_vm.error!.retryAfterSeconds}초 후 다시 시도해 주세요.',
                                  if (_vm.deliveryUncertain)
                                    '이미 접수되었을 수 있습니다. 재전송 시 중복 접수에 유의해 주세요.',
                                ].join('\n'),
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(height: 24),
                        if (_vm.busy) ...[
                          const LinearProgressIndicator(),
                          const SizedBox(height: 12),
                        ],
                        FilledButton(
                          onPressed: blocked ? null : _submit,
                          child: Text(
                            _vm.uploading
                                ? '스크린샷 업로드 중…'
                                : _vm.busy
                                ? '문의 접수 중…'
                                : '문의 등록',
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
          ),
        ),
      );
    },
  );
}
