import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: const Text("내가 만든 월드컵"),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const AddWorldCupScreen(),
                  fullscreenDialog: true,
                ),
              );
            },
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: Container(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
        child: Column(
          children: [
            // 애드몹 배너
            if(_bannerAd != null)
              SizedBox(
                width: _bannerAd?.size.width.toDouble(),
                height: _bannerAd?.size.height.toDouble(),
                child: AdWidget(ad: _bannerAd!),
              ),
            // 월드컵 리스트
            const WorldCupList(),
          ],
        ),
      ),
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