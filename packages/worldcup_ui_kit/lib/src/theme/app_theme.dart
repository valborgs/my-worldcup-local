import 'package:flutter/material.dart';

/// 앱 전역 테마.
///
/// 색과 타이포그래피를 한곳에 모아, 화면이 여러 feature 패키지로 나뉘어도
/// 같은 모습을 유지하게 한다.
abstract final class AppTheme {
  /// 브랜드 시드 색상.
  static const Color seedColor = Colors.deepPurpleAccent;

  static ThemeData light() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: seedColor),
      useMaterial3: true,
    );
  }
}
