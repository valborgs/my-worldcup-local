import 'package:worldcup_ui_kit/worldcup_ui_kit.dart';
import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:worldcup_core/worldcup_core.dart';

class HelpScreen extends StatefulWidget {
  final bool isFirstShow;
  final bool enableBottomSheetSelectionPagerTransition;

  const HelpScreen(
    this.isFirstShow, {
    required this.enableBottomSheetSelectionPagerTransition,
    super.key,
  });

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  List<PageViewModel> _pages(BuildContext context) => [
    PageViewModel(
      title: AppLocalizations.of(context).appTitle,
      body: AppLocalizations.of(context).onboardingWelcome,
      image: Image.asset("assets/icon/logo.png", width: 200, height: 200),
    ),
    PageViewModel(
      title: AppLocalizations.of(context).onboardingCreateOneTitle,
      body: AppLocalizations.of(context).onboardingCreateOneBody,
      image: Image.asset("assets/images/help1.png", width: 300, height: 300),
    ),
    PageViewModel(
      title: AppLocalizations.of(context).onboardingCreateTwoTitle,
      body: AppLocalizations.of(context).onboardingCreateTwoBody,
      image: Image.asset("assets/images/help2.png", width: 300, height: 300),
    ),
    PageViewModel(
      title: AppLocalizations.of(context).onboardingPlayTitle,
      body: AppLocalizations.of(context).onboardingPlayBody,
      image: Image.asset("assets/images/help3.png", width: 300, height: 300),
    ),
    PageViewModel(
      title: AppLocalizations.of(context).onboardingWinnerTitle,
      body: AppLocalizations.of(context).onboardingWinnerBody,
      image: Image.asset("assets/images/help4.png", width: 300, height: 300),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.only(top: 80),
        child: Semantics(
          label: AppLocalizations.of(context).onboardingSemantics,
          child: IntroductionScreen(
            pages: _pages(context),
            showNextButton: true,
            next: Text(
              AppLocalizations.of(context).commonNext,
              semanticsLabel: AppLocalizations.of(context).commonNext,
            ),
            showSkipButton: true,
            skip: Text(
              AppLocalizations.of(context).onboardingSkip,
              semanticsLabel: AppLocalizations.of(context).onboardingSkip,
            ),
            done: Text(
              AppLocalizations.of(context).onboardingStart,
              semanticsLabel: AppLocalizations.of(context).onboardingStart,
            ),
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

  Future<void> finishScreen() async {
    if (widget.isFirstShow) {
      // SharedPreferences에 첫 Help화면 여부를 true로 변경
      // 이후에는 앱을 다시 켜도 Help화면이 안나온다.
      SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setBool("isAlreadyShownHelp", true);

      if (!mounted) return;

      Navigator.of(context).pushReplacementNamed(AppRoutes.list);
    } else {
      Navigator.of(context).pop();
    }
  }
}
