import 'package:flutter/material.dart';
import 'package:worldcup_nearby_transfer/worldcup_nearby_transfer.dart';
import 'package:worldcup_domain/worldcup_domain.dart';

import '../services/nearby_worldcup_transfer_controller.dart';
import '../services/worldcup_package_service.dart';

class NearbyWorldCupSendScreen extends StatefulWidget {
  final WorldCupModel worldCup;
  final NearbyTransferGateway? gateway;
  final WorldCupPackageGateway? packageGateway;
  final NearbyWorldCupTransferController? controller;

  const NearbyWorldCupSendScreen({
    required this.worldCup,
    this.gateway,
    this.packageGateway,
    this.controller,
    super.key,
  });

  @override
  State<NearbyWorldCupSendScreen> createState() =>
      _NearbyWorldCupSendScreenState();
}

class _NearbyWorldCupSendScreenState extends State<NearbyWorldCupSendScreen>
    with WidgetsBindingObserver {
  late final NearbyWorldCupTransferController _controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = widget.controller ??
        NearbyWorldCupTransferController.sender(
          gateway: widget.gateway ?? MethodChannelNearbyTransferGateway(),
          packageGateway: widget.packageGateway ?? WorldCupPackageService(),
          worldCup: widget.worldCup,
        );
    _controller.addListener(_onChanged);
    _controller.start();
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
    return _NearbyTransferScaffold(
      title: '주변 기기로 보내기',
      controller: _controller,
      introduction: '받는 기기에서 먼저 ‘월드컵 받기’를 열어주세요.',
    );
  }
}

class NearbyWorldCupReceiveScreen extends StatefulWidget {
  final NearbyTransferGateway? gateway;
  final WorldCupPackageGateway? packageGateway;
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
  State<NearbyWorldCupReceiveScreen> createState() =>
      _NearbyWorldCupReceiveScreenState();
}

class _NearbyWorldCupReceiveScreenState
    extends State<NearbyWorldCupReceiveScreen> with WidgetsBindingObserver {
  late final NearbyWorldCupTransferController _controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = widget.controller ??
        NearbyWorldCupTransferController.receiver(
          gateway: widget.gateway ?? MethodChannelNearbyTransferGateway(),
          packageGateway: widget.packageGateway ?? WorldCupPackageService(),
          onImported: widget.onImported,
        );
    _controller.addListener(_onChanged);
    _controller.start();
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
    return _NearbyTransferScaffold(
      title: '월드컵 받기',
      controller: _controller,
      introduction: '이 기기의 이름: ${_controller.displayName}\n\n'
          'Bluetooth와 Wi-Fi를 켜주세요. 같은 Wi-Fi 공유기나 인터넷 연결은 필요하지 않습니다.',
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
                onPressed: controller.busy &&
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
    final showProgress = controller.phase == NearbyTransferPhase.transferring ||
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
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      letterSpacing: 4,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '코드가 다르면 연결하지 마세요.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton(
                  onPressed:
                      controller.busy ? null : controller.rejectConnection,
                  child: const Text('거절'),
                ),
                FilledButton(
                  onPressed:
                      controller.busy ? null : controller.acceptConnection,
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
