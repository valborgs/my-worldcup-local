import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AdHelper {

  static String get bannerAdUnitId {
    if (Platform.isAndroid) {
      // aos 일 때
      if(kReleaseMode){
        // 디버그 모드가 아닌 앱 출시할 때의 빌드 모드일 때
        return dotenv.env['admob_aos_releaseUnitId'] ?? "ca-app-pub-3940256099942544/9214589741";
      }else{
        // 디버그 모드일 때
        return dotenv.env['admob_aos_debugUnitId'] ?? "ca-app-pub-3940256099942544/9214589741";
      }
    } else if (Platform.isIOS) {
      // ios 일 때
      if(kReleaseMode){
        // 디버그 모드가 아닌 앱 출시할 때의 빌드 모드일 때
        return dotenv.env['admob_ios_releaseUnitId'] ?? "ca-app-pub-3940256099942544/2435281174";
      }else{
        // 디버그 모드일 때
        return dotenv.env['admob_ios_debugUnitId'] ?? "ca-app-pub-3940256099942544/2435281174";
      }
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }

  static String get interstitialAdUnitId {
    if (Platform.isAndroid) {
      // aos 일 때
      if(kReleaseMode){
        // 디버그 모드가 아닌 앱 출시할 때의 빌드 모드일 때
        return dotenv.env['admob_interstitial_aos_releaseUnitId'] ?? "ca-app-pub-3940256099942544/1033173712";
      }else{
        // 디버그 모드일 때
        return dotenv.env['admob_interstitial_aos_debugUnitId'] ?? "ca-app-pub-3940256099942544/1033173712";
      }
    } else if (Platform.isIOS) {
      // ios 일 때
      if(kReleaseMode){
        // 디버그 모드가 아닌 앱 출시할 때의 빌드 모드일 때
        return dotenv.env['admob_interstitial_ios_releaseUnitId'] ?? "ca-app-pub-3940256099942544/4411468910";
      }else{
        // 디버그 모드일 때
        return dotenv.env['admob_interstitial_ios_debugUnitId'] ?? "ca-app-pub-3940256099942544/4411468910";
      }
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }

}