import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';

enum WorldCupAction { create, receiveNearby, importFile }

class WorldCupActionMenuButton extends StatelessWidget {
  final bool isBusy;
  final Future<void> Function() onCreate;
  final Future<void> Function() onReceiveNearby;
  final Future<void> Function() onImportFile;

  const WorldCupActionMenuButton({
    required this.onCreate,
    required this.onReceiveNearby,
    required this.onImportFile,
    this.isBusy = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Semantics(
        button: true,
        enabled: !isBusy,
        label: l10n.worldCupAddMenu,
        child: IconButton(
          tooltip: l10n.worldCupAddMenu,
          onPressed: isBusy ? null : () => _showActionSheet(context),
          icon: isBusy
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(Icons.add, semanticLabel: l10n.worldCupAddMenu, size: 32),
        ),
      ),
    );
  }

  Future<void> _showActionSheet(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final action = await showModalBottomSheet<WorldCupAction>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.8,
          ),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            children: [
              Semantics(
                header: true,
                child: Text(
                  l10n.worldCupAddMethodTitle,
                  style: Theme.of(sheetContext).textTheme.titleLarge,
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.add_photo_alternate_outlined),
                title: Text(l10n.worldCupCreate),
                subtitle: Text(l10n.worldCupCreateDescription),
                onTap: () => Navigator.pop(sheetContext, WorldCupAction.create),
              ),
              ListTile(
                leading: const Icon(Icons.devices_other),
                title: Text(l10n.worldCupReceiveNearby),
                subtitle: Text(l10n.worldCupReceiveNearbyDescription),
                onTap: () =>
                    Navigator.pop(sheetContext, WorldCupAction.receiveNearby),
              ),
              ListTile(
                leading: const Icon(Icons.file_download_outlined),
                title: Text(l10n.worldCupImportFile),
                subtitle: Text(l10n.worldCupImportFileDescription),
                onTap: () =>
                    Navigator.pop(sheetContext, WorldCupAction.importFile),
              ),
            ],
          ),
        ),
      ),
    );
    if (!context.mounted || action == null) return;

    switch (action) {
      case WorldCupAction.create:
        await onCreate();
      case WorldCupAction.receiveNearby:
        await onReceiveNearby();
      case WorldCupAction.importFile:
        await onImportFile();
    }
  }
}
