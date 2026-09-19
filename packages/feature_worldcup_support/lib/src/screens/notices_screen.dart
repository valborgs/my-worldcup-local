import 'package:worldcup_ui_kit/worldcup_ui_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worldcup_domain/worldcup_domain.dart';

import '../state/support_view_models.dart';

class NoticesScreen extends ConsumerStatefulWidget {
  const NoticesScreen({super.key});
  @override
  ConsumerState<NoticesScreen> createState() => _NoticesScreenState();
}

class _NoticesScreenState extends ConsumerState<NoticesScreen> {
  late final NoticesViewModel _vm;
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _vm = NoticesViewModel(ref.read(supportProvider));
    _vm.load(1);
  }

  @override
  void dispose() {
    _vm.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load(int page) async {
    await _vm.load(page);
    if (!mounted) return;
    if (_vm.error == null && _scroll.hasClients) _scroll.jumpTo(0);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(AppLocalizations.of(context).noticesTitle)),
    body: SafeArea(
      child: ListenableBuilder(
        listenable: _vm,
        builder: (context, _) {
          return RefreshIndicator(
            onRefresh: () => _load(1),
            child: ListView(
              controller: _scroll,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                if (_vm.loading) const LinearProgressIndicator(),
                if (_vm.error != null) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      AppLocalizations.of(context)
                          .message(_vm.error!.userMessage),
                      semanticsLabel: AppLocalizations.of(context)
                          .supportErrorSemantics(
                            AppLocalizations.of(context)
                                .message(_vm.error!.userMessage),
                          ),
                    ),
                  ),
                  if (_vm.error!.retryAfterSeconds != null)
                    Text(
                      AppLocalizations.of(context)
                          .supportRetryAfter(_vm.error!.retryAfterSeconds!),
                    ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: _vm.loading
                          ? null
                          : () => _load(_vm.requestedPage),
                      icon: const Icon(Icons.refresh),
                      label: Text(AppLocalizations.of(context).commonRetry),
                    ),
                  ),
                ],
                if (_vm.loaded && _vm.notices.isEmpty && !_vm.loading)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 80),
                    child: Center(
                      child: Text(AppLocalizations.of(context).noticesEmpty),
                    ),
                  ),
                for (final notice in _vm.notices)
                  Card(
                    child: ExpansionTile(
                      key: ValueKey('${_vm.page}-${notice.id}'),
                      title: Text(notice.title),
                      subtitle: Text(_date(notice.publishedAt)),
                      expandedCrossAxisAlignment: CrossAxisAlignment.start,
                      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: SelectableText(notice.content),
                        ),
                        if (notice.imageUrl != null) ...[
                          const SizedBox(height: 16),
                          Image.network(
                            notice.imageUrl!,
                            fit: BoxFit.contain,
                            semanticLabel: AppLocalizations.of(context)
                                .noticesImageSemantics,
                            loadingBuilder: (context, child, progress) =>
                                progress == null
                                ? child
                                : const Padding(
                                    padding: EdgeInsets.all(20),
                                    child: Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  ),
                            errorBuilder: (context, error, stack) => Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(
                                AppLocalizations.of(context).noticesImageFailed,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                if (_vm.loaded)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: _vm.loading || _vm.page == 1
                              ? null
                              : () => _load(_vm.page - 1),
                          child: Text(
                            AppLocalizations.of(context).commonPrevious,
                          ),
                        ),
                        Text(
                          AppLocalizations.of(context).noticesPage(_vm.page),
                        ),
                        TextButton(
                          onPressed: _vm.loading || !_vm.hasNext
                              ? null
                              : () => _load(_vm.page + 1),
                          child: Text(AppLocalizations.of(context).commonNext),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    ),
  );

  String _date(DateTime value) =>
      AppLocalizations.of(context).noticesDate(value.toLocal());
}
