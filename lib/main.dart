import 'package:flutter/material.dart';
import 'package:my_worldcup_local/screens/main_worldcup_screen.dart';

void main() {
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
