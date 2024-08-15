import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'main_worldcup_screen.dart';

class HelpScreen extends StatefulWidget {
  bool isFirstShow;
  HelpScreen(this.isFirstShow, {super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {

  var pageViewModel = [
    PageViewModel(
      title: "내가 만든 월드컵",
      body: "앱을 실행해주셔서 감사합니다!",
      image: Image.asset("assets/icon/logo.png",width: 200, height: 200,),
    ),
    PageViewModel(
      title: "월드컵 만들기 1",
      body: "상단의 추가 버튼을 눌러 \n월드컵을 만들어보세요",
      image: Image.asset("assets/images/help1.png",width: 300, height: 300,),
    ),
    PageViewModel(
      title: "월드컵 만들기 2",
      body: "내가 직접 찍은 사진을 골라 \n리스트에 추가해보세요",
      image: Image.asset("assets/images/help2.png",width: 300, height: 300,),
    ),
    PageViewModel(
      title: "월드컵 게임 진행",
      body: "2개의 사진 중 마음에 든 사진을 선택해보세요",
      image: Image.asset("assets/images/help3.png",width: 300, height: 300,),
    ),
    PageViewModel(
      title: "월드컵 게임 우승자",
      body: "월드컵 우승자를 가려봅시다!",
      image: Image.asset("assets/images/help4.png",width: 300, height: 300,),
    ),
  ];

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.only(top: 80),
        child: Semantics(
          label: "도움말, 소개 화면",
          child: IntroductionScreen(
            pages: pageViewModel,
            showNextButton: true,
            next: const Text("다음", semanticsLabel: "다음",),
            showSkipButton: true,
            skip: const Text("스킵하기", semanticsLabel: "스킵하기",),
            done: const Text("시작하기", semanticsLabel: "시작하기",),
            onDone: () {
              finishScreen();
            },
            onSkip: () {
              finishScreen();
            },
          ),
        ),
      ),
    );
  }

  Future<void> finishScreen() async{
    if(widget.isFirstShow){
      // SharedPreferences에 첫 Help화면 여부를 true로 변경
      // 이후에는 앱을 다시 켜도 Help화면이 안나온다.
      SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setBool("isAlreadyShownHelp", true);

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const MainWorldCupScreen(),
        ),
      );
    }else{
      Navigator.of(context).pop();
    }
  }

}
