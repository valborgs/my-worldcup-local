import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worldcup_nearby_transfer/worldcup_nearby_transfer.dart';
import 'package:worldcup_domain/worldcup_domain.dart';
import 'package:worldcup_data/worldcup_data.dart';


class NearbyWorldCupSendScreen extends ConsumerStatefulWidget {
  /// 보낼 월드컵의 id.
  ///
  /// 라우트 인자가 엔티티가 아니라 id이므로 여기서 조회한 뒤 컨트롤러를 만든다.
  /// [controller]를 직접 주입하면 조회를 건너뛴다.
  final int worldCupId;
  final NearbyTransferGateway? gateway;
  final WorldCupPackagePort? packageGateway;
  final NearbyWorldCupTransferController? controller;

  const NearbyWorldCupSendScreen({
    required this.worldCupId,
    this.gateway,
    this.packageGateway,
    this.controller,
    super.key,
  });

  @override
  ConsumerState<NearbyWorldCupSendScreen> createState() =>
      _NearbyWorldCupSendScreenState();
}

class _NearbyWorldCupSendScreenState
    extends ConsumerState<NearbyWorldCupSendScreen>
    with WidgetsBindingObserver {
  // 월드컵을 불러온 뒤에야 컨트롤러를 만들 수 있어 nullable이다.
  NearbyWorldCupTransferController? _controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final injected = widget.controller;
    if (injected != null) {
      _attach(injected);
    } else {
      unawaited(_loadAndStart());
    }
  }

  Future<void> _loadAndStart() async {
    final model = await ref
        .read(worldCupRepositoryProvider)
        .findById(widget.worldCupId);
    if (!mounted || model == null) return;
    _attach(
      NearbyWorldCupTransferController.sender(
        gateway: widget.gateway ?? MethodChannelNearbyTransferGateway(),
        packageGateway:
            widget.packageGateway ?? ref.read(worldCupPackageProvider),
        worldCup: model,
      ),
    );
  }

  void _attach(NearbyWorldCupTransferController controller) {
    setState(() => _controller = controller);
    controller.addListener(_onChanged);
    controller.start();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden) {
      _controller?.cancel();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.removeListener(_onChanged);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const title = '주변 기기로 보내기';
    final controller = _controller;
    if (controller == null) {
      // 월드컵을 불러오는 동안. 보통 한 프레임 안에 끝난다.
      return Scaffold(
        appBar: AppBar(title: const Text(title)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    return _NearbyTransferScaffold(
      title: title,
      controller: controller,
      introduction: '받는 기기에서 먼저 ‘월드컵 받기’를 열어주세요.',
    );
  }
}

/// 주변 기기에서 월드컵을 받는 화면.
///
/// 가져오기에 성공하면 화면이 닫힐 때 [ImportedWorldCup]을 pop 결과로 돌려준다.
/// 예전에는 `onImported` 콜백으로 목록을 갱신했지만, 라우트 인자로는 클로저를
/// 넘길 수 없어 결과 반환 방식으로 바꿨다. 전체 화면 다이얼로그라 목록은
/// 어차피 닫힌 뒤에야 보인다.
class NearbyWorldCupReceiveScreen extends ConsumerStatefulWidget {
  final NearbyTransferGateway? gateway;
  final WorldCupPackagePort? packageGateway;
  final Future<void> Function(ImportedWorldCup imported)? onImported;
  final NearbyWorldCupTransferController? controller;

  const NearbyWorldCupReceiveScreen({
    this.gateway,
    this.packageGateway,
    this.onImported,
    this.controller,
    super.key,
  });

  @override
  ConsumerState<NearbyWorldCupReceiveScreen> createState() =>
      _NearbyWorldCupReceiveScreenState();
}

class _NearbyWorldCupReceiveScreenState
    extends ConsumerState<NearbyWorldCupReceiveScreen>
    with WidgetsBindingObserver {
  late final NearbyWorldCupTransferController _controller;

  /// 가져오기에 성공한 월드컵. 화면이 닫힐 때 pop 결과로 돌려준다.
  ImportedWorldCup? _imported;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller =
        widget.controller ??
        NearbyWorldCupTransferController.receiver(
          gateway: widget.gateway ?? MethodChannelNearbyTransferGateway(),
          packageGateway:
              widget.packageGateway ?? ref.read(worldCupPackageProvider),
          onImported: _handleImported,
        );
    _controller.addListener(_onChanged);
    _controller.start();
  }

  Future<void> _handleImported(ImportedWorldCup imported) async {
    _imported = imported;
    // 테스트나 호출부가 직접 콜백을 넘겼다면 그대로 이어준다.
    await widget.onImported?.call(imported);
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden) {
      _controller.cancel();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.removeListener(_onChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 기본 뒤로가기로 닫힐 때도 가져온 월드컵을 결과로 실어 보내야 해서
    // pop을 가로챈다.
    return PopScope<ImportedWorldCup?>(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.of(context).pop(_imported);
      },
      child: _NearbyTransferScaffold(
        title: '월드컵 받기',
        controller: _controller,
        introduction:
            '이 기기의 이름: ${_controller.displayName}\n\n'
            'Bluetooth와 Wi-Fi를 켜주세요. 같은 Wi-Fi 공유기나 인터넷 연결은 필요하지 않습니다.',
      ),
    );
  }
}

class _NearbyTransferScaffold extends StatelessWidget {
  final String title;
  final String introduction;
  final NearbyWorldCupTransferController controller;

  const _NearbyTransferScaffold({
    required this.title,
    required this.introduction,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final verificationCode = controller.verificationCode;
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          if (!controller.finished)
            Semantics(
              button: true,
              label: '주변 기기 전송 취소',
              child: IconButton(
                tooltip: '전송 취소',
                onPressed:
                    controller.busy &&
                        controller.phase == NearbyTransferPhase.importing
                    ? null
                    : controller.cancel,
                icon: const Icon(Icons.cancel_outlined),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _InformationCard(text: introduction),
            const SizedBox(height: 18),
            _StatusSection(controller: controller),
            if (controller.mode == NearbyTransferMode.send &&
                controller.phase == NearbyTransferPhase.discovering) ...[
              const SizedBox(height: 24),
              _EndpointList(controller: controller),
            ],
            if (controller.needsConnectionDecision &&
                verificationCode != null) ...[
              const SizedBox(height: 24),
              _ConnectionDecision(
                controller: controller,
                verificationCode: verificationCode,
              ),
            ],
            if (controller.canOpenSettings &&
                controller.phase == NearbyTransferPhase.error) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: controller.openSettings,
                icon: const Icon(Icons.settings_outlined),
                label: const Text('앱 설정 열기'),
              ),
            ],
            if (controller.finished ||
                controller.phase == NearbyTransferPhase.error) ...[
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => Navigator.of(context).maybePop(),
                child: const Text('닫기'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InformationCard extends StatelessWidget {
  final String text;

  const _InformationCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.info_outline, semanticLabel: '안내'),
            const SizedBox(width: 12),
            Expanded(child: Text(text)),
          ],
        ),
      ),
    );
  }
}

class _StatusSection extends StatelessWidget {
  final NearbyWorldCupTransferController controller;

  const _StatusSection({required this.controller});

  @override
  Widget build(BuildContext context) {
    final showProgress =
        controller.phase == NearbyTransferPhase.transferring ||
        controller.phase == NearbyTransferPhase.importing;
    final percent = controller.progress == null
        ? null
        : '${(controller.progress! * 100).round()}%';
    return Semantics(
      liveRegion: true,
      label: '전송 상태 ${controller.message}${percent == null ? '' : ' $percent'}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(_statusIcon(controller.phase), semanticLabel: '전송 상태'),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  controller.message,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          if (showProgress) ...[
            const SizedBox(height: 16),
            LinearProgressIndicator(value: controller.progress),
            if (percent != null) ...[
              const SizedBox(height: 8),
              Text(percent, textAlign: TextAlign.end),
            ],
          ],
        ],
      ),
    );
  }

  IconData _statusIcon(NearbyTransferPhase phase) {
    switch (phase) {
      case NearbyTransferPhase.success:
        return Icons.check_circle_outline;
      case NearbyTransferPhase.error:
        return Icons.error_outline;
      case NearbyTransferPhase.canceled:
        return Icons.cancel_outlined;
      case NearbyTransferPhase.advertising:
      case NearbyTransferPhase.discovering:
        return Icons.radar;
      default:
        return Icons.devices_other;
    }
  }
}

class _EndpointList extends StatelessWidget {
  final NearbyWorldCupTransferController controller;

  const _EndpointList({required this.controller});

  @override
  Widget build(BuildContext context) {
    final endpoints = controller.endpoints;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('발견된 기기', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        if (endpoints.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Column(
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 12),
                Text('주변 기기를 검색하고 있습니다.'),
              ],
            ),
          )
        else
          for (final endpoint in endpoints)
            Card(
              child: ListTile(
                leading: const Icon(Icons.smartphone),
                title: Text(endpoint.name, maxLines: 2),
                subtitle: const Text('탭하여 연결'),
                trailing: const Icon(Icons.chevron_right),
                enabled: !controller.busy,
                onTap: () => controller.connect(endpoint),
              ),
            ),
      ],
    );
  }
}

class _ConnectionDecision extends StatelessWidget {
  final NearbyWorldCupTransferController controller;
  final String verificationCode;

  const _ConnectionDecision({
    required this.controller,
    required this.verificationCode,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              controller.peer?.name ?? '상대 기기',
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text('양쪽 기기에 아래 인증 코드가 동일하게 표시되는지 확인하세요.'),
            const SizedBox(height: 16),
            Semantics(
              label: '인증 코드 $verificationCode',
              readOnly: true,
              child: SelectableText(
                verificationCode,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium
                    ?.copyWith(letterSpacing: 4, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            const Text('코드가 다르면 연결하지 마세요.', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton(
                  onPressed: controller.busy
                      ? null
                      : controller.rejectConnection,
                  child: const Text('거절'),
                ),
                FilledButton(
                  onPressed: controller.busy
                      ? null
                      : controller.acceptConnection,
                  child: const Text('코드 일치 · 수락'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
