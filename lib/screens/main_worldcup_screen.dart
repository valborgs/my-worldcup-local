import 'package:flutter/material.dart';

import '../widgets/worldcup_list.dart';
import 'add_worldcup_screen.dart';

class MainWorldCupScreen extends StatelessWidget {
  const MainWorldCupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("내가 만든 월드컵"),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const AddWorldCupScreen(),
                  fullscreenDialog: true,
                ),
              );
            },
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: Container(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
        child: const Column(
          children: [
            WorldCupList(),
          ],
        ),
      ),
    );
  }
}
