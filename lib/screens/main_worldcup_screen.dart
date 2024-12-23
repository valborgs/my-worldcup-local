import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:my_worldcup_local/screens/help_screen.dart';

import '../ad/ad_helper.dart';
import '../widgets/worldcup_list.dart';
import 'add_worldcup_screen.dart';

class MainWorldCupScreen extends StatefulWidget {
  const MainWorldCupScreen({super.key});

  @override
  State<MainWorldCupScreen> createState() => _MainWorldCupScreenState();
}

class _MainWorldCupScreenState extends State<MainWorldCupScreen> {

  late String admobBannerId;
  BannerAd? _bannerAd;

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
      onPopInvoked: (didPop) {
        _showBackDialog();
      },
      child: Scaffold(
          appBar: AppBar(
            leading: Semantics(
              label: "도움말 버튼",
              button: true,
              enabled: true,
              child: IconButton(
                tooltip: "도움말",
                onPressed: (){
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => HelpScreen(false),
                      fullscreenDialog: true,
                    ),
                  );
                },
                icon: const Icon(
                  Icons.help_outline,
                  semanticLabel: "도움말",
                  size: 24,
                ),
              ),
            ),
            title: const Text("내가 만든 월드컵", semanticsLabel: "내가 만든 월드컵 화면",),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Semantics(
                  button: true,
                  enabled: true,
                  label: "Add WorldCup Button",
                  child: IconButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const AddWorldCupScreen(),
                          fullscreenDialog: true,
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.add,
                      semanticLabel: "추가",
                      size: 32,
                    ),
                  ),
                ),
              ),
            ],
          ),
          body: Container(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
            child: Column(
              children: [
                // 애드몹 배너
                if(_bannerAd != null)
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
                const WorldCupList(),
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
          content: const Text(
            '내가 만든 월드컵을 종료하시겠습니까?',
          ),
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

  void setAdmob() async {
    // admob 셋팅
    BannerAd(
      adUnitId: AdHelper.bannerAdUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(onAdLoaded: (ad){
        setState(() {
          // 광고가 로드되면 아래의 코드를 실행한다.
          _bannerAd = ad as BannerAd;
        });
      }, onAdFailedToLoad: (ad, error){
        // 광고 로드가 실패하면 아래의 코드를 실행한다.
        print(error.message);
        ad.dispose();
      }),
    ).load();
  }
}