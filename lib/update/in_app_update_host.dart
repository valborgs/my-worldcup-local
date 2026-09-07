import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../di/providers.dart';
import 'in_app_update_controller.dart';

/// 앱 전체를 감싸고 유연한 업데이트를 이끄는 위젯.
///
/// [MaterialApp.builder] 안에 두므로 화면을 바꿔도 살아 있고,
/// 루트 [ScaffoldMessenger]를 통해 어느 화면에서든 안내를 띄울 수 있다.
class InAppUpdateHost extends ConsumerStatefulWidget {
  final Widget child;

  const InAppUpdateHost({required this.child, super.key});

  @override
  ConsumerState<InAppUpdateHost> createState() => _InAppUpdateHostState();
}

class _InAppUpdateHostState extends ConsumerState<InAppUpdateHost>
    with WidgetsBindingObserver {
  late final InAppUpdateController _controller;

  ScaffoldFeatureController<SnackBar, SnackBarClosedReason>? _promptBar;
  bool _syncScheduled = false;

  @override
  void initState() {
    super.initState();
    _controller = InAppUpdateController(
      gateway: ref.read(inAppUpdateGatewayProvider),
    );
    _controller.addListener(_onControllerChanged);
    WidgetsBinding.instance.addObserver(this);
    // 첫 프레임 전에는 ScaffoldMessenger가 없고, 조회가 시작을 늦출 이유도 없다.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _controller.start();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    // 지난 실행에서 받아 두고 설치하지 않은 업데이트를 여기서 찾는다.
    _controller.resume();
  }

  void _onControllerChanged() {
    // 상태 변화는 프레임 도중에도 올 수 있다. 스낵바는 빌드 중에 띄울 수 없으므로
    // 프레임이 끝난 뒤로 미룬다.
    if (_syncScheduled) return;
    _syncScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncScheduled = false;
      if (!mounted) return;
      _syncSnackBars();
    });
    // addPostFrameCallback은 프레임을 예약하지 않는다. 직접 깨워 준다.
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  void _syncSnackBars() {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    if (_controller.hasUnseenInstallFailure) {
      _controller.acknowledgeInstallFailure();
      messenger.showSnackBar(
        const SnackBar(content: Text('업데이트 설치를 시작하지 못했습니다. 잠시 후 다시 시도해 주세요.')),
      );
      return;
    }

    if (_controller.shouldPromptInstall) {
      _showInstallPrompt(messenger);
    } else {
      _promptBar?.close();
      _promptBar = null;
    }
  }

  void _showInstallPrompt(ScaffoldMessengerState messenger) {
    if (_promptBar != null) return;
    final bar = messenger.showSnackBar(
      SnackBar(
        // 사용자가 직접 닫거나 재시작을 고를 때까지 남겨 둔다.
        // (안드로이드 가이드의 Snackbar.LENGTH_INDEFINITE에 해당한다)
        duration: const Duration(days: 365),
        showCloseIcon: true,
        content: const Text('새 버전을 모두 받았습니다. 재시작하면 적용됩니다.'),
        action: SnackBarAction(label: '재시작', onPressed: _controller.installNow),
      ),
    );
    _promptBar = bar;
    bar.closed.then((reason) {
      if (!mounted || !identical(_promptBar, bar)) return;
      _promptBar = null;
      // 재시작을 누른 경우는 컨트롤러가 이미 설치 단계로 넘어갔다.
      if (reason == SnackBarClosedReason.action) return;
      _controller.dismissInstallPrompt();
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
