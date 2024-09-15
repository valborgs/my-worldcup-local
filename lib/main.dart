import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:kakao_flutter_sdk_share/kakao_flutter_sdk_share.dart';
import 'package:my_worldcup_local/screens/help_screen.dart';
import 'package:my_worldcup_local/screens/main_worldcup_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dto/worldcup_dao.dart';

Future<void> main() async {
  // .env 폴더에서 api 키값 사용하기 위해 초기화
  await dotenv.load(fileName: ".env");

  // 웹 환경에서 카카오 로그인을 정상적으로 완료하려면 runApp() 호출 전 아래 메서드 호출 필요
  // WidgetsFlutterBinding.ensureInitialized();
  // // runApp() 호출 전 Flutter SDK 초기화
  // KakaoSdk.init(
  //   nativeAppKey: dotenv.env['kakao_nativeAppKey'],
  //   javaScriptAppKey: dotenv.env['kakao_javaScriptAppKey'],
  // );

  // 구글 애드몹
  MobileAds.instance.initialize();

  // 세로 모드 고정
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool? isAlreadyShownHelp = prefs.getBool("isAlreadyShownHelp");

  if(isAlreadyShownHelp==null){
    // 앱을 처음 실행할 때에만 샘플 월드컵 데이터를 추가한다.
    var dao = WorldCupDao();
    dao.addSampleWorldCup();
  }

  runApp(MyWorldCup(isAlreadyShownHelp));
}

class MyWorldCup extends StatelessWidget {
  bool? isAlreadyShownHelp;
  MyWorldCup(this.isAlreadyShownHelp, {super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "내가 만든 월드컵",
      themeMode: ThemeMode.light,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme:ColorScheme.fromSeed(seedColor: Colors.deepPurpleAccent),
        useMaterial3: true,
      ),
      home: (isAlreadyShownHelp == true)
          ? const MainWorldCupScreen()
          : Semantics(
            label: "도움말, 소개 화면",
            child: HelpScreen(true)
          )
    );
  }
}
