import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:kakao_flutter_sdk_share/kakao_flutter_sdk_share.dart';
import 'package:my_worldcup_local/screens/main_worldcup_screen.dart';

Future<void> main() async {
  // .env 폴더에서 api 키값 사용하기 위해 초기화
  await dotenv.load(fileName: ".env");

  // 웹 환경에서 카카오 로그인을 정상적으로 완료하려면 runApp() 호출 전 아래 메서드 호출 필요
  WidgetsFlutterBinding.ensureInitialized();
  // runApp() 호출 전 Flutter SDK 초기화
  KakaoSdk.init(
    nativeAppKey: dotenv.env['kakao_nativeAppKey'],
    javaScriptAppKey: dotenv.env['kakao_javaScriptAppKey'],
  );

  runApp(const MyWorldCup());
}

class MyWorldCup extends StatelessWidget {
  const MyWorldCup({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "내가 만든 월드컵",
      themeMode: ThemeMode.light,
      theme: ThemeData(
        colorScheme:ColorScheme.fromSeed(seedColor: Colors.deepPurpleAccent),
        useMaterial3: true,
      ),
      home: const MainWorldCupScreen()
    );
  }
}
