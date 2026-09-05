import 'dart:developer';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:kakao_flutter_sdk_share/kakao_flutter_sdk_share.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:worldcup_domain/worldcup_domain.dart';
import 'package:worldcup_ui_kit/worldcup_ui_kit.dart';

import 'app_router.dart';
import 'di/providers.dart';
import 'firebase_options.dart';
import 'screens/help_screen.dart';
import 'screens/main_worldcup_screen.dart';

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

  // 위젯 트리 밖에서도 같은 의존성을 쓰기 위해 컨테이너를 직접 만든다.
  // 이 컨테이너를 그대로 UncontrolledProviderScope에 넘기므로, 부팅 중에
  // 연 DB 연결을 앱이 그대로 물려받는다.
  final container = ProviderContainer(overrides: portOverrides);

  var enableBottomSheetSelectionPagerTransition =
      FeatureFlags.bottomSheetSelectionPagerTransitionDefault;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    enableBottomSheetSelectionPagerTransition = await container
        .read(featureFlagProvider)
        .getBool(
          FeatureFlags.bottomSheetSelectionPagerTransition,
          defaultValue: FeatureFlags.bottomSheetSelectionPagerTransitionDefault,
        );
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
  //
  // 실패해도 앱은 계속 띄운다. 샘플이 없을 뿐 사용자가 만든 월드컵은
  // 멀쩡하기 때문이다. 예전에는 시드가 코드에 박혀 있어 실패할 수 없었지만,
  // 지금은 에셋을 읽으므로 실패 가능성이 생겼다.
  try {
    await container.read(sampleWorldCupSeederProvider).sync();
  } catch (error, stackTrace) {
    log(
      '샘플 월드컵 동기화에 실패해 샘플 없이 계속 실행합니다.',
      error: error,
      stackTrace: stackTrace,
      name: 'main_sample_seed',
    );
  }

  // 개발 중 페이징 확인용 데이터. 제거 시 이 호출과 provider만 삭제하면 된다.
  if (kDebugMode) await container.read(testWorldCupSeederProvider).seed();

  // 첫 화면 진입 시 빈 목록이 잠깐 보였다가 바뀌는 깜빡임을 없애기 위해 미리 불러온다.
  List<WorldCupModel> initialWorldCupList = await container
      .read(worldCupRepositoryProvider)
      .page(limit: 10, offset: 0);

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: MyWorldCup(
        isAlreadyShownHelp,
        initialWorldCupList,
        enableBottomSheetSelectionPagerTransition:
            enableBottomSheetSelectionPagerTransition,
      ),
    ),
  );
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
    final isLargeScreen =
        MediaQuery.sizeOf(context).shortestSide >= _kLargeScreenWidth;
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
    final router = AppRouter(
      enableBottomSheetSelectionPagerTransition:
          widget.enableBottomSheetSelectionPagerTransition,
    );

    return MaterialApp(
      title: "내가 만든 월드컵",
      themeMode: ThemeMode.light,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      builder: (context, child) {
        _applyOrientationPolicy(context);
        return child!;
      },
      onGenerateRoute: router.onGenerateRoute,
      // 첫 화면만 여기서 만든다. 목록 화면은 미리 불러온 목록을 받아
      // 첫 프레임의 깜빡임을 없애기 때문에 라우터를 거치지 않는다.
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
              ),
            ),
    );
  }
}
