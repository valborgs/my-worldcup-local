import 'dart:developer';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:kakao_flutter_sdk_share/kakao_flutter_sdk_share.dart';
import 'package:my_worldcup_local/screens/help_screen.dart';
import 'package:my_worldcup_local/screens/main_worldcup_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dto/worldcup_dao.dart';
import 'dev/test_worldcup_seeder.dart';
import 'firebase_options.dart';
import 'models/worldcup_model.dart';

// 이 너비(dp) 이상을 '대화면'(폴더블 내부화면, 태블릿 등)으로 간주하여 회전을 허용한다.
const double _kLargeScreenWidth = 600.0;

const String _bottomSheetSelectionPagerTransitionKey =
    'enableBottomSheetSelectionPagerTransition';
const bool _bottomSheetSelectionPagerTransitionDefault = true;

Future<void> main() async {
  // runApp() 호출 전 Flutter SDK 초기화를 위해 바인딩을 가장 먼저 준비한다.
  WidgetsFlutterBinding.ensureInitialized();

  // .env 폴더에서 api 키값 사용하기 위해 초기화
  await dotenv.load(fileName: ".env");

  KakaoSdk.init(
    nativeAppKey: dotenv.env['kakao_nativeAppKey'],
    javaScriptAppKey: dotenv.env['kakao_javaScriptAppKey'],
  );

  var enableBottomSheetSelectionPagerTransition =
      _bottomSheetSelectionPagerTransitionDefault;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    enableBottomSheetSelectionPagerTransition =
        await _loadBottomSheetSelectionPagerTransitionFlag();
  } catch (error, stackTrace) {
    log(
      'Firebase 초기화에 실패해 앱 기본값으로 계속 실행합니다.',
      error: error,
      stackTrace: stackTrace,
      name: 'main_firebase',
    );
  }

  // 구글 애드몹
  await MobileAds.instance.initialize();

  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool? isAlreadyShownHelp = prefs.getBool("isAlreadyShownHelp");

  // 앱을 시작할 때마다 샘플 월드컵 데이터를 최신 상태로 동기화한다.
  // (샘플 이미지 에셋이 교체되어도 로컬 db가 예전 경로를 들고 있지 않도록 함)
  var dao = WorldCupDao();
  await dao.syncSampleWorldCup();

  // 개발 중 페이징 확인용 데이터. 제거 시 이 호출과 import만 삭제하면 된다.
  if (kDebugMode) await TestWorldCupSeeder.seed();

  // 첫 화면 진입 시 빈 목록이 잠깐 보였다가 바뀌는 깜빡임을 없애기 위해 미리 불러온다.
  List<WorldCupModel> initialWorldCupList = await dao.getWorldCupPage(
    limit: 10,
    offset: 0,
  );

  runApp(
    MyWorldCup(
      isAlreadyShownHelp,
      initialWorldCupList,
      enableBottomSheetSelectionPagerTransition:
          enableBottomSheetSelectionPagerTransition,
    ),
  );
}

Future<bool> _loadBottomSheetSelectionPagerTransitionFlag() async {
  try {
    final remoteConfig = FirebaseRemoteConfig.instance;
    await remoteConfig.setDefaults(const {
      _bottomSheetSelectionPagerTransitionKey:
          _bottomSheetSelectionPagerTransitionDefault,
    });

    try {
      await remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          minimumFetchInterval: kDebugMode
              ? const Duration(minutes: 5)
              : const Duration(hours: 12),
        ),
      );
      await remoteConfig.fetchAndActivate();
    } catch (error, stackTrace) {
      log(
        'Remote Config를 가져오지 못해 캐시 또는 기본값을 사용합니다.',
        error: error,
        stackTrace: stackTrace,
        name: 'main_remote_config',
      );
    }

    return remoteConfig.getBool(_bottomSheetSelectionPagerTransitionKey);
  } catch (error, stackTrace) {
    log(
      'Remote Config 초기화에 실패해 앱 기본값을 사용합니다.',
      error: error,
      stackTrace: stackTrace,
      name: 'main_remote_config',
    );
    return _bottomSheetSelectionPagerTransitionDefault;
  }
}

class MyWorldCup extends StatefulWidget {
  final bool? isAlreadyShownHelp;
  final List<WorldCupModel> initialWorldCupList;
  final bool enableBottomSheetSelectionPagerTransition;

  const MyWorldCup(
    this.isAlreadyShownHelp,
    this.initialWorldCupList, {
    required this.enableBottomSheetSelectionPagerTransition,
    super.key,
  });

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
          ? MainWorldCupScreen(
              initialWorldCupList: widget.initialWorldCupList,
              enableBottomSheetSelectionPagerTransition:
                  widget.enableBottomSheetSelectionPagerTransition,
            )
          : Semantics(
            label: "도움말, 소개 화면",
            child: HelpScreen(
              true,
              enableBottomSheetSelectionPagerTransition:
                  widget.enableBottomSheetSelectionPagerTransition,
            )
          )
    );
  }
}
