import 'package:worldcup_core/worldcup_core.dart';
import 'package:worldcup_ui_kit/worldcup_ui_kit.dart';

import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show MaxLengthEnforcement;
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

  String? _validation(AppMessage? value) =>
      value == null ? null : AppLocalizations.of(context).message(value);

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
        throw const SupportFailure(
          'image_size',
          'Screenshot exceeds the upload size limit.',
          userMessage: AppMessage(AppMessageId.supportImageSize),
        );
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
              title: Text(AppLocalizations.of(context).inquiryResendTitle),
              content: Text(AppLocalizations.of(context).inquiryResendBody),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(AppLocalizations.of(context).commonCancel),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(AppLocalizations.of(context).inquiryResend),
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
    if (_vm.busy || _confirmingLeave || _leaving) return;
    if (_vm.receipt == null &&
        (_email.text.isNotEmpty ||
            _content.text.isNotEmpty ||
            _vm.screenshot != null)) {
      _confirmingLeave = true;
      final discard =
          await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(AppLocalizations.of(context).inquiryLeaveTitle),
              content: Text(AppLocalizations.of(context).inquiryLeaveBody),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(AppLocalizations.of(context).inquiryKeepWriting),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(AppLocalizations.of(context).inquiryLeave),
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
            title: Text(AppLocalizations.of(context).inquiryTitle),
            leading: BackButton(onPressed: _vm.busy ? null : _leave),
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
                            AppLocalizations.of(context).inquirySuccess,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            AppLocalizations.of(context)
                                .inquiryReceipt(receipt.id),
                          ),
                          const SizedBox(height: 24),
                          FilledButton(
                            onPressed: _leave,
                            child: Text(
                              AppLocalizations.of(context).commonConfirm,
                            ),
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
                          AppLocalizations.of(context).inquiryHeading,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(AppLocalizations.of(context).inquiryIntroduction),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _email,
                          enabled: !blocked,
                          keyboardType: TextInputType.emailAddress,
                          autocorrect: false,
                          maxLength: 254,
                          validator: (value) => _validation(
                            InquiryViewModel.validateEmail(value ?? ''),
                          ),
                          decoration: InputDecoration(
                            labelText: AppLocalizations.of(context)
                                .inquiryEmailLabel,
                            helperText: AppLocalizations.of(context)
                                .inquiryEmailHint,
                            border: const OutlineInputBorder(),
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
                          // Django validates Unicode code points, not grapheme clusters.
                          // Keep pasted text intact and show the server's actual count.
                          maxLengthEnforcement: MaxLengthEnforcement.none,
                          buildCounter:
                              (
                                context, {
                                required currentLength,
                                required isFocused,
                                required maxLength,
                              }) {
                                final length = _content.text
                                    .trim()
                                    .runes
                                    .length;
                                return Text(
                                  AppLocalizations.of(context)
                                      .inquiryContentCounter(length),
                                  style: TextStyle(
                                    color: length > 5000
                                        ? Theme.of(context).colorScheme.error
                                        : null,
                                  ),
                                );
                              },
                          validator: (value) => _validation(
                            InquiryViewModel.validateContent(value ?? ''),
                          ),
                          decoration: InputDecoration(
                            labelText: AppLocalizations.of(context)
                                .inquiryContentLabel,
                            alignLabelWithHint: true,
                            hintText: AppLocalizations.of(context)
                                .inquiryContentHint,
                            border: const OutlineInputBorder(),
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
                                  ? AppLocalizations.of(context)
                                        .inquiryPickingImage
                                  : _vm.screenshot == null
                                  ? AppLocalizations.of(context)
                                        .inquiryAttachScreenshot
                                  : AppLocalizations.of(context)
                                        .inquiryChangeScreenshot,
                            ),
                          ),
                        ),
                        Text(AppLocalizations.of(context).inquiryImageLimit),
                        if (_vm.screenshot != null) ...[
                          const SizedBox(height: 12),
                          Image.memory(
                            _vm.screenshot!,
                            height: 180,
                            cacheHeight: 360,
                            fit: BoxFit.contain,
                            semanticLabel: AppLocalizations.of(context)
                                .inquirySelectedScreenshot,
                            errorBuilder: (context, error, stack) => Text(
                              AppLocalizations.of(context)
                                  .inquiryImageDisplayFailed,
                            ),
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _vm.screenshotName ??
                                      AppLocalizations.of(context)
                                          .inquiryScreenshot,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              IconButton(
                                tooltip: AppLocalizations.of(context)
                                    .inquiryRemoveAttachment,
                                onPressed: blocked
                                    ? null
                                    : () => _vm.setScreenshot(null, null),
                                icon: const Icon(Icons.close),
                              ),
                            ],
                          ),
                          Text(AppLocalizations.of(context).inquiryImageNotice),
                        ],
                        if (_vm.error != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Semantics(
                              liveRegion: true,
                              child: Text(
                                [
                                  AppLocalizations.of(context)
                                      .message(_vm.error!.userMessage),
                                  for (final messages
                                      in _vm.error!.fields.values)
                                    ...messages.map(
                                      AppLocalizations.of(context).message,
                                    ),
                                  if (_vm.error!.retryAfterSeconds != null)
                                    AppLocalizations.of(context)
                                        .supportRetryAfter(
                                          _vm.error!.retryAfterSeconds!,
                                        ),
                                  if (_vm.deliveryUncertain)
                                    AppLocalizations.of(context)
                                        .inquiryDeliveryUncertain,
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
                                ? AppLocalizations.of(context).inquiryUploading
                                : _vm.busy
                                ? AppLocalizations.of(context).inquirySubmitting
                                : AppLocalizations.of(context).inquirySubmit,
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
