import 'dart:developer';
import 'dart:io';
import 'dart:math' hide log;

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:my_worldcup_local/screens/play_worldcup_screen.dart';

import '../ad/ad_helper.dart';
import '../api/imgbb_upload.dart';
import '../api/kakaotalk_feed.dart';
import '../models/worldcup_item_model.dart';
import '../models/worldcup_model.dart';
import '../tools/asset_to_file.dart';
import '../tools/make_binary_file.dart';

class ResultWorldCupScreen extends StatefulWidget {
  final WorldCupModel worldCupModel;
  final WorldCupItemModel winnerModel;
  final int round;
  const ResultWorldCupScreen(this.worldCupModel, this.winnerModel, this.round,
      {super.key});

  @override
  State<ResultWorldCupScreen> createState() => _ResultWorldCupScreen();
}

class _ResultWorldCupScreen extends State<ResultWorldCupScreen> {
  late ConfettiController _confettiController;
  InterstitialAd? _interstitialAd;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 5));
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
      adUnitId: AdHelper.interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
        },
        onAdFailedToLoad: (LoadAdError error) {
          log('InterstitialAd failed to load',
              error: error, name: 'result_worldcup_screen');
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
          log('Failed to show interstitial ad',
              error: error, name: 'result_worldcup_screen');
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
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) =>
            PlayWorldCupScreen(widget.worldCupModel, widget.round),
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
          title: Text(
            "${widget.worldCupModel.title} 우승자",
            semanticsLabel: "월드컵 우승자 화면",
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
                    child: const Row(
                      children: [
                        Text(
                          "축하합니다!",
                          style: TextStyle(
                            fontSize: 22,
                          ),
                          semanticsLabel: "축하 문구",
                        ),
                        Icon(Icons.auto_awesome,
                            color: Colors.yellow, semanticLabel: "축하")
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
                              cacheWidth: (150 *
                                      MediaQuery.of(context).devicePixelRatio)
                                  .round(),
                            ).image,
                    ),
                  ),
                  Text(
                    widget.winnerModel.imageInfo,
                    style: const TextStyle(
                      fontSize: 18,
                    ),
                    semanticsLabel: "우승자 이름",
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
                                        Radius.circular(5.0))))),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.replay,
                              color: Colors.white,
                              semanticLabel: "다시하기",
                            ),
                            Padding(padding: EdgeInsets.only(right: 10)),
                            Text(
                              '다시 하기',
                              style: TextStyle(
                                color: Colors.white,
                              ),
                              semanticsLabel: "다시 하기 버튼",
                            )
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
                          )),
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
    if (isLoading) return;
    setState(() => isLoading = true);

    try {
      final title = widget.worldCupModel.title;
      final image = widget.winnerModel.worldCupIdx > 0
          ? File(widget.winnerModel.imagePath)
          : await getImageFileFromAssets(widget.winnerModel.imagePath);
      final binaryFile = base64Encode1(image);
      final imgUrl = await uploadImage(binaryFile) ?? "";
      if (imgUrl.isEmpty) {
        throw StateError('ImgBB did not return an image URL.');
      }

      final description =
          '${widget.worldCupModel.title} 우승자 : ${widget.winnerModel.imageInfo}';
      final playstoreUrl = dotenv.env['playstore_url'] ?? "";
      final myTemplate =
          await makeFeedTemplate(title, description, imgUrl, playstoreUrl);
      final didOpenShare = await sendFeed(myTemplate);
      if (!didOpenShare) {
        throw StateError('Kakao share UI could not be opened.');
      }
    } catch (error) {
      log('Failed to share result',
          error: error, name: 'result_worldcup_screen');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('공유할 수 없습니다. 잠시 후 다시 시도해주세요.')),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }
}
