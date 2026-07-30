import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:kakao_flutter_sdk_share/kakao_flutter_sdk_share.dart';
import 'package:my_worldcup_local/screens/help_screen.dart';
import 'package:my_worldcup_local/screens/main_worldcup_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dto/worldcup_dao.dart';

// 이 너비(dp) 이상을 '대화면'(폴더블 내부화면, 태블릿 등)으로 간주하여 회전을 허용한다.
const double _kLargeScreenWidth = 600.0;

Future<void> main() async {
  // runApp() 호출 전 Flutter SDK 초기화를 위해 바인딩을 가장 먼저 준비한다.
  WidgetsFlutterBinding.ensureInitialized();

  // .env 폴더에서 api 키값 사용하기 위해 초기화
  await dotenv.load(fileName: ".env");

  KakaoSdk.init(
    nativeAppKey: dotenv.env['kakao_nativeAppKey'],
    javaScriptAppKey: dotenv.env['kakao_javaScriptAppKey'],
  );

  // 구글 애드몹
  MobileAds.instance.initialize();

  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool? isAlreadyShownHelp = prefs.getBool("isAlreadyShownHelp");

  if(isAlreadyShownHelp==null){
    // 앱을 처음 실행할 때에만 샘플 월드컵 데이터를 추가한다.
    var dao = WorldCupDao();
    dao.addSampleWorldCup();
  }

  runApp(MyWorldCup(isAlreadyShownHelp));
}

class MyWorldCup extends StatefulWidget {
  bool? isAlreadyShownHelp;
  MyWorldCup(this.isAlreadyShownHelp, {super.key});

  @override
  State<MyWorldCup> createState() => _MyWorldCupState();
}

class _MyWorldCupState extends State<MyWorldCup> {
  // 직전에 적용한 대화면 여부. 값이 바뀔 때만 플랫폼 채널을 호출한다.
  bool? _isLargeScreen;

  // 화면 크기에 따라 회전 허용 정책을 적용한다.
  // 대화면(폴더블 내부화면, 태블릿 등)에서는 모든 방향을 허용하고,
  // 그 외 일반 폰에서는 기존처럼 세로 모드로 고정한다.
  void _applyOrientationPolicy(BuildContext context) {
    final isLargeScreen = MediaQuery.sizeOf(context).shortestSide >= _kLargeScreenWidth;
    if (isLargeScreen == _isLargeScreen) return;
    _isLargeScreen = isLargeScreen;

    if (isLargeScreen) {
      SystemChrome.setPreferredOrientations([]);
    } else {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    }
  }

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
      builder: (context, child) {
        _applyOrientationPolicy(context);
        return child!;
      },
      home: (widget.isAlreadyShownHelp == true)
          ? const MainWorldCupScreen()
          : Semantics(
            label: "도움말, 소개 화면",
            child: HelpScreen(true)
          )
    );
  }
}
