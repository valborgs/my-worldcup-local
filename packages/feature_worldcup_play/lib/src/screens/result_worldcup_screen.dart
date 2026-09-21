import 'dart:developer';
import 'dart:io';
import 'dart:math' hide log;

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:worldcup_domain/worldcup_domain.dart';
import 'package:worldcup_ui_kit/worldcup_ui_kit.dart';
import 'package:worldcup_core/worldcup_core.dart';

class ResultWorldCupScreen extends ConsumerStatefulWidget {
  final WorldCupModel worldCupModel;
  final WorldCupItemModel winnerModel;
  final int round;
  const ResultWorldCupScreen(
    this.worldCupModel,
    this.winnerModel,
    this.round, {
    super.key,
  });

  @override
  ConsumerState<ResultWorldCupScreen> createState() => _ResultWorldCupScreen();
}

class _ResultWorldCupScreen extends ConsumerState<ResultWorldCupScreen> {
  late ConfettiController _confettiController;
  InterstitialAd? _interstitialAd;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 5),
    );
    _confettiController.play();
    _loadInterstitialAd();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _interstitialAd?.dispose();
    super.dispose();
  }

  void _loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: ref.read(adUnitProvider).interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
        },
        onAdFailedToLoad: (LoadAdError error) {
          log(
            'InterstitialAd failed to load',
            error: error,
            name: 'result_worldcup_screen',
          );
        },
      ),
    );
  }

  void _showInterstitialAdAndNavigate(VoidCallback onAdClosed) {
    if (_interstitialAd != null) {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _interstitialAd = null;
          _loadInterstitialAd(); // 다음 사용을 위해 새 광고 로드
          onAdClosed();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          log(
            'Failed to show interstitial ad',
            error: error,
            name: 'result_worldcup_screen',
          );
          ad.dispose();
          _interstitialAd = null;
          _loadInterstitialAd(); // 다음 사용을 위해 새 광고 로드
          onAdClosed(); // 광고 실패 시에도 원래 동작 수행
        },
      );
      _interstitialAd!.show();
    } else {
      // 광고가 로드되지 않은 경우 바로 원래 동작 수행
      onAdClosed();
    }
  }

  void _replayGame() {
    Navigator.of(context).pushReplacementNamed(
      AppRoutes.play,
      arguments: PlayArgs(
        worldCupId: widget.worldCupModel.idx,
        round: widget.round,
      ),
    );
  }

  void _goBack() {
    Navigator.of(context).pop();
  }

  // 로딩 이미지
  final spinkit = const SpinKitPulsingGrid(
    color: Colors.deepPurple,
    size: 100.0,
  );

  var isLoading = false;
  // 공유 확인 창이 떠 있는 동안 버튼을 다시 눌러 창이 겹치지 않게 한다.
  var _confirmingShare = false;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _showInterstitialAdAndNavigate(_goBack);
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          title: AutoScrollingText(
            AppLocalizations.of(context).resultTitle(
              AppLocalizations.of(context).worldCupTitle(
                widget.worldCupModel.idx,
                widget.worldCupModel.title,
              ),
            ),
            semanticsLabel: AppLocalizations.of(context).resultScreenSemantics,
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              _showInterstitialAdAndNavigate(_goBack);
            },
          ),
        ),
        // 화면
        body: Stack(
          alignment: AlignmentDirectional.center,
          children: [
            Container(
              height: double.maxFinite,
              color: Colors.grey.withValues(alpha: 0.1),
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
              alignment: Alignment.center,
              child: Column(
                children: [
                  Container(
                    alignment: Alignment.center,
                    child: Row(
                      children: [
                        Text(
                          AppLocalizations.of(context).resultCongratulations,
                          style: const TextStyle(fontSize: 22),
                          semanticsLabel: AppLocalizations.of(context)
                              .resultCongratulationsSemantics,
                        ),
                        Icon(
                          Icons.auto_awesome,
                          color: Colors.yellow,
                          semanticLabel: AppLocalizations.of(context)
                              .resultCelebrationSemantics,
                        ),
                      ],
                    ),
                  ),
                  const Padding(padding: EdgeInsets.only(top: 20)),
                  SizedBox(
                    width: 150,
                    height: 150,
                    child: CircleAvatar(
                      backgroundImage: widget.winnerModel.worldCupIdx < 0
                          ? Image.asset(widget.winnerModel.imagePath).image
                          // 아바타 크기(150dp) 이상으로 디코딩할 필요가 없다.
                          : Image.file(
                              File(widget.winnerModel.imagePath),
                              cacheWidth:
                                  (150 *
                                          MediaQuery.of(context)
                                              .devicePixelRatio)
                                      .round(),
                            ).image,
                    ),
                  ),
                  Text(
                    AppLocalizations.of(context).worldCupItemInfo(
                      widget.winnerModel.worldCupIdx,
                      widget.winnerModel.imagePath,
                      widget.winnerModel.imageInfo,
                    ),
                    style: const TextStyle(fontSize: 18),
                    semanticsLabel: AppLocalizations.of(context)
                        .resultWinnerName,
                  ),
                  const Padding(padding: EdgeInsets.only(top: 30)),
                  // 버튼 묶음
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 다시하기 버튼
                      ElevatedButton(
                        onPressed: () {
                          _showInterstitialAdAndNavigate(_replayGame);
                        },
                        style: const ButtonStyle(
                          backgroundColor: WidgetStatePropertyAll(Colors.red),
                          shape: WidgetStatePropertyAll(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(5.0),
                              ),
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.replay,
                              color: Colors.white,
                              semanticLabel: AppLocalizations.of(context)
                                  .resultReplayIcon,
                            ),
                            const Padding(padding: EdgeInsets.only(right: 10)),
                            Text(
                              AppLocalizations.of(context).resultReplay,
                              style: const TextStyle(color: Colors.white),
                              semanticsLabel: AppLocalizations.of(context)
                                  .resultReplaySemantics,
                            ),
                          ],
                        ),
                      ),
                      const Padding(padding: EdgeInsets.only(top: 10)),
                      // 정식 출시 전까지는 가렸다가 출시 후에 공유 버튼 살리기
                      // 공유 버튼
                      IconButton(
                        onPressed: () => shareGameWithKakao(),
                        icon: Image.network(
                          'https://developers.kakao.com/assets/img/about/logos/kakaotalksharing/kakaotalk_sharing_btn_medium.png',
                          width: 40,
                        ),
                      ),
                    ],
                  ),
                  // 팡파레 효과
                  Container(
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ConfettiWidget(
                          confettiController: _confettiController,
                          blastDirection: -pi / 2 - 0.15,
                          emissionFrequency: 0,
                          numberOfParticles: 20,
                          maxBlastForce: 120,
                          minBlastForce: 60,
                        ),
                        ConfettiWidget(
                          confettiController: _confettiController,
                          blastDirection: -pi / 2,
                          emissionFrequency: 0,
                          numberOfParticles: 20,
                          maxBlastForce: 120,
                          minBlastForce: 60,
                        ),
                        ConfettiWidget(
                          confettiController: _confettiController,
                          blastDirection: -pi / 2 + 0.15,
                          emissionFrequency: 0,
                          numberOfParticles: 20,
                          maxBlastForce: 120,
                          minBlastForce: 60,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (isLoading) spinkit,
          ],
        ),
      ),
    );
  }

  // 카카오톡 공유하기 기능
  Future<void> shareGameWithKakao() async {
    if (isLoading || _confirmingShare) return;
    // 공유하려면 사진을 외부 이미지 호스팅에 올려야 한다. 링크를 받은
    // 사람은 누구나 볼 수 있으므로 업로드 전에 사용자에게 먼저 묻는다.
    _confirmingShare = true;
    final bool confirmed;
    try {
      confirmed = await _confirmPhotoShare();
    } finally {
      _confirmingShare = false;
    }
    if (!confirmed || !mounted) return;
    setState(() => isLoading = true);

    try {
      final imgUrl =
          await ref
              .read(imageUploadProvider)
              .uploadItemImage(widget.winnerModel) ??
          "";
      if (imgUrl.isEmpty) {
        throw StateError('ImgBB did not return an image URL.');
      }

      if (!mounted) return;
      final title = AppLocalizations.of(context)
          .worldCupTitle(widget.worldCupModel.idx, widget.worldCupModel.title);
      final description = AppLocalizations.of(context).resultShareDescription(
        AppLocalizations.of(
          context,
        ).worldCupTitle(widget.worldCupModel.idx, widget.worldCupModel.title),
        AppLocalizations.of(context).worldCupItemInfo(
          widget.winnerModel.worldCupIdx,
          widget.winnerModel.imagePath,
          widget.winnerModel.imageInfo,
        ),
      );
      final didOpenShare = await ref
          .read(socialShareProvider)
          .shareFeed(
            title: title,
            description: description,
            imageUrl: imgUrl,
            buttonTitle: AppLocalizations.of(context).resultShareButton,
          );
      if (!didOpenShare) {
        throw StateError('Kakao share UI could not be opened.');
      }
    } catch (error) {
      log(
        'Failed to share result',
        error: error,
        name: 'result_worldcup_screen',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).resultShareFailed)),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  /// 사진 공유 전 확인. 사용자가 확인을 눌렀을 때만 true.
  Future<bool> _confirmPhotoShare() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        final l10n = AppLocalizations.of(dialogContext);
        return AlertDialog(
          content: Text(l10n.resultShareConfirmBody),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(l10n.commonCancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(l10n.commonConfirm),
            ),
          ],
        );
      },
    );
    return confirmed ?? false;
  }
}
