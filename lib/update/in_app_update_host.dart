import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worldcup_domain/worldcup_domain.dart';
import 'package:worldcup_in_app_update/worldcup_in_app_update.dart';

import '../di/providers.dart';
import 'in_app_update_controller.dart';

/// 앱 전체를 감싸고 인앱 업데이트를 이끄는 위젯.
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
    _controller = _createController();
    _controller.addListener(_onControllerChanged);
    WidgetsBinding.instance.addObserver(this);
    // 첫 프레임 전에는 ScaffoldMessenger가 없고, 조회가 시작을 늦출 이유도 없다.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _controller.start();
    });
  }

  /// 의존성을 만들지 못해도 앱은 그대로 떠야 한다.
  ///
  /// 이 위젯은 라우터 위에 있어서, 여기서 예외가 나면 화면이 통째로 뜨지 않는다.
  /// 예컨대 `main()`이 Firebase 초기화 실패를 잡고 앱을 계속 띄운 경우,
  /// Remote Config 포트를 만드는 것만으로도 예외가 날 수 있다.
  /// 그런 상황에서는 아무것도 하지 않는 컨트롤러로 대신한다.
  InAppUpdateController _createController() {
    try {
      return InAppUpdateController(
        gateway: ref.read(inAppUpdateGatewayProvider),
        featureFlags: ref.read(featureFlagProvider),
      );
    } catch (error, stackTrace) {
      log(
        '인앱 업데이트를 준비하지 못해 업데이트 안내 없이 계속합니다.',
        error: error,
        stackTrace: stackTrace,
        name: 'in_app_update',
      );
      return InAppUpdateController(
        // 채널을 건드리지 않는 게이트웨이. 모든 조회가 "쓸 수 없음"으로 끝난다.
        gateway: MethodChannelInAppUpdateGateway(isSupportedPlatform: false),
        featureFlags: const _UnavailableFeatureFlags(),
      );
    }
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
    // 강제 업데이트가 필요한 상태라면 여기서 다시 요구한다.
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
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        // 막는 화면만 컨트롤러를 구독한다. child는 같은 위젯 인스턴스라
        // 여기서 다시 만들어도 아래 트리는 리빌드되지 않는다.
        ListenableBuilder(
          listenable: _controller,
          builder: (context, _) => _controller.isUpdateRequired
              ? RequiredUpdateOverlay(onUpdate: _controller.retryRequiredUpdate)
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

/// 반드시 올려야 하는 버전인데 사용자가 Play 화면을 닫았을 때 앱을 막는 화면.
///
/// Play의 즉시 업데이트 화면을 다시 띄우는 것 말고는 할 수 있는 일이 없다.
/// 뒤로 가기로 화면을 벗어나도 이 막이 계속 덮고 있으므로, 사용자가 할 수
/// 있는 선택은 업데이트하거나 앱을 닫는 것뿐이다.
@visibleForTesting
class RequiredUpdateOverlay extends StatelessWidget {
  final VoidCallback onUpdate;

  const RequiredUpdateOverlay({required this.onUpdate, super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      label: '업데이트 필요',
      child: Stack(
        children: [
          // 아래 화면으로 가는 터치를 모두 막는다.
          const ModalBarrier(dismissible: false, color: Colors.black54),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          '업데이트가 필요합니다',
                          style: theme.textTheme.titleLarge,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '이 버전에서는 앱을 계속 사용할 수 없습니다.\n'
                          '최신 버전으로 업데이트해 주세요.',
                          style: theme.textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        FilledButton(
                          onPressed: onUpdate,
                          child: const Text('업데이트'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 원격 설정을 쓸 수 없을 때 자리를 채우는 포트. 언제나 기본값을 돌려준다.
class _UnavailableFeatureFlags implements FeatureFlagPort {
  const _UnavailableFeatureFlags();

  @override
  Future<bool> getBool(String key, {required bool defaultValue}) async =>
      defaultValue;

  @override
  Future<int> getInt(String key, {required int defaultValue}) async =>
      defaultValue;
}
