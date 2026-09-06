import 'package:flutter/material.dart';

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
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Semantics(
        button: true,
        enabled: !isBusy,
        label: '월드컵 추가 메뉴',
        child: IconButton(
          tooltip: '월드컵 추가 메뉴',
          onPressed: isBusy ? null : () => _showActionSheet(context),
          icon: isBusy
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.add, semanticLabel: '월드컵 추가 메뉴', size: 32),
        ),
      ),
    );
  }

  Future<void> _showActionSheet(BuildContext context) async {
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
                  '월드컵 추가 방법 선택',
                  style: Theme.of(sheetContext).textTheme.titleLarge,
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.add_photo_alternate_outlined),
                title: const Text('새 월드컵 만들기'),
                subtitle: const Text('사진을 골라 나만의 월드컵 만들기'),
                onTap: () => Navigator.pop(sheetContext, WorldCupAction.create),
              ),
              ListTile(
                leading: const Icon(Icons.devices_other),
                title: const Text('주변 기기에서 받기'),
                subtitle: const Text('인터넷 없이 Nearby Connections로 직접 받기'),
                onTap: () =>
                    Navigator.pop(sheetContext, WorldCupAction.receiveNearby),
              ),
              ListTile(
                leading: const Icon(Icons.file_download_outlined),
                title: const Text('파일에서 가져오기'),
                subtitle: const Text('.myworldcup 파일을 직접 선택하여 가져오기'),
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
