import 'dart:io';

import 'package:flutter/foundation.dart';

class AdHelper {

  static String get bannerAdUnitId {
    if (Platform.isAndroid) {
      // aos 일 때
      if(kReleaseMode){
        // 디버그 모드가 아닌 앱 출시할 때의 빌드 모드일 때
        return "ca-app-pub-9185731715755618/3592717227";// release unit-id
      }else{
        // 디버그 모드일 때
        return "ca-app-pub-3940256099942544/9214589741";// debug(test) unit-id
      }
    } else if (Platform.isIOS) {
      // ios 일 때
      if(kReleaseMode){
        // 디버그 모드가 아닌 앱 출시할 때의 빌드 모드일 때
        return "ca-app-pub-9185731715755618/3393745984";// release unit-id
      }else{
        // 디버그 모드일 때
        return "ca-app-pub-3940256099942544/2435281174";// debug(test) unit-id
      }
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }

}