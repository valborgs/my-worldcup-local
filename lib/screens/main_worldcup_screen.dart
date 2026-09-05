import 'dart:developer';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:worldcup_nearby_transfer/worldcup_nearby_transfer.dart';
import 'package:worldcup_domain/worldcup_domain.dart';

import '../widgets/worldcup_list.dart';

import 'package:worldcup_core/worldcup_core.dart';
import 'package:worldcup_ui_kit/worldcup_ui_kit.dart';


class MainWorldCupScreen extends ConsumerStatefulWidget {
  final List<WorldCupModel>? initialWorldCupList;
  final bool enableBottomSheetSelectionPagerTransition;
  final NearbyTransferGateway Function()? nearbyGatewayFactory;
  final WorldCupPackagePort? packageGateway;

  const MainWorldCupScreen({
    this.initialWorldCupList,
    required this.enableBottomSheetSelectionPagerTransition,
    this.nearbyGatewayFactory,
    this.packageGateway,
    super.key,
  });

  @override
  ConsumerState<MainWorldCupScreen> createState() => _MainWorldCupScreenState();
}

class _MainWorldCupScreenState extends ConsumerState<MainWorldCupScreen> {
  late String admobBannerId;
  BannerAd? _bannerAd;
  final _worldCupListKey = GlobalKey<WorldCupListState>();
  bool _isImporting = false;

  @override
  void initState() {
    super.initState();
    // admob 셋팅
    setAdmob();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_worldCupListKey.currentState?.handleBack() == true) return;
        _showBackDialog();
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          leading: Semantics(
            label: "도움말 버튼",
            button: true,
            enabled: true,
            child: IconButton(
              tooltip: "도움말",
              onPressed: () {
                Navigator.of(context).pushNamed<void>(AppRoutes.help);
              },
              icon: const Icon(
                Icons.help_outline,
                semanticLabel: "도움말",
                size: 24,
              ),
            ),
          ),
          title: const Text("내가 만든 월드컵", semanticsLabel: "내가 만든 월드컵 화면"),
          actions: [
            WorldCupActionMenuButton(
              isBusy: _isImporting,
              onCreate: _addWorldCup,
              onReceiveNearby: _receiveWorldCup,
              onImportFile: _importWorldCup,
            ),
          ],
        ),
        body: Container(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
          child: Column(
            children: [
              // 애드몹 배너
              if (_bannerAd != null)
                Semantics(
                  button: true,
                  enabled: true,
                  label: "Banner Ad",
                  child: SizedBox(
                    width: _bannerAd?.size.width.toDouble(),
                    height: _bannerAd?.size.height.toDouble(),
                    child: AdWidget(ad: _bannerAd!),
                  ),
                ),
              // 월드컵 리스트
              WorldCupList(
                key: _worldCupListKey,
                initialWorldCupList: widget.initialWorldCupList,
                enableBottomSheetSelectionPagerTransition:
                    widget.enableBottomSheetSelectionPagerTransition,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBackDialog() {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('앱 종료'),
          content: const Text('내가 만든 월드컵을 종료하시겠습니까?'),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
                textStyle: Theme.of(context).textTheme.labelLarge,
              ),
              child: const Text('아니오'),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            TextButton(
              style: TextButton.styleFrom(
                textStyle: Theme.of(context).textTheme.labelLarge,
              ),
              child: const Text('네'),
              onPressed: () {
                SystemNavigator.pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _addWorldCup() async {
    final addedWorldCupIdx = await Navigator.of(context)
        .pushNamed<int>(AppRoutes.editor, arguments: const EditorArgs());
    if (!mounted || addedWorldCupIdx == null) return;
    await _worldCupListKey.currentState?.refreshAndScrollTo(addedWorldCupIdx);
  }

  Future<void> _importWorldCup() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const [WorldCupPackageFormat.fileExtension],
      allowMultiple: false,
    );
    if (!mounted || result == null || result.files.isEmpty) return;

    final packagePath = result.files.single.path;
    if (packagePath == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('선택한 파일을 읽을 수 없습니다.')));
      return;
    }

    setState(() => _isImporting = true);
    try {
      final WorldCupPackagePort packagePort =
          widget.packageGateway ?? ref.read(worldCupPackageProvider);
      final imported = await packagePort.importPackage(packagePath);
      if (!mounted) return;
      await _worldCupListKey.currentState?.refreshAndScrollTo(imported.idx);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"${imported.title}" 월드컵을 가져왔습니다.')),
      );
    } catch (error, stackTrace) {
      log(
        'Failed to import world cup package',
        error: error,
        stackTrace: stackTrace,
        name: 'main_worldcup_screen',
      );
      if (!mounted) return;
      final message = error is Failure
          ? error.message
          : '월드컵을 가져올 수 없습니다. 잠시 후 다시 시도해주세요.';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  Future<void> _receiveWorldCup() async {
    final imported = await Navigator.of(context)
        .pushNamed<ImportedWorldCup>(AppRoutes.nearbyReceive);
    if (!mounted || imported == null) return;
    await _worldCupListKey.currentState?.refreshAndScrollTo(imported.idx);
  }

  void setAdmob() async {
    // admob 셋팅
    BannerAd(
      adUnitId: ref.read(adUnitProvider).bannerAdUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          setState(() {
            // 광고가 로드되면 아래의 코드를 실행한다.
            _bannerAd = ad as BannerAd;
          });
        },
        onAdFailedToLoad: (ad, error) {
          // 광고 로드가 실패하면 아래의 코드를 실행한다.
          log(error.message, name: 'main_worldcup_screen');
          ad.dispose();
        },
      ),
    ).load();
  }
}
