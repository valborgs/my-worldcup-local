import 'dart:math';

import 'package:flutter/material.dart';
import 'package:my_worldcup_local/screens/result_worldcup_screen.dart';
import 'package:my_worldcup_local/widgets/item_bottom.dart';
import 'package:my_worldcup_local/widgets/item_top.dart';
import 'package:provider/provider.dart';

import '../models/worldcup_item_model.dart';
import '../provider/worldcup_select_provider.dart';

class WorldCupGame extends StatefulWidget {
  String? title;
  List<WorldCupItemModel> itemList;
  int selectedRound;
  WorldCupGame(this.title, this.itemList, this.selectedRound, {super.key});

  @override
  State<WorldCupGame> createState() => _WorldCupGameState();
}

class _WorldCupGameState extends State<WorldCupGame> {

  // 진행 용어는 '강' 과 '라운드'로 구분한다.
  // '강' : 128강, 64강, 32강 등 모든 대결 항목이 한 번씩 게임을 진행하는 큰 횟수
  // '라운드' : '강' 안에서 항목끼리 대결할때 진행되는 횟수

  // 현재 진행중인 '강'의 항목이 담긴 리스트
  List<WorldCupItemModel> nowList = [];

  // 이긴 항목은 nextList에 추가되고 다음 '강'이 시작될 때 사용되며 초기화된다.
  List<WorldCupItemModel> nextList = [];
  // '라운드'를 담을 변수
  int round = -1;
  // 현재 '강'의 최대 라운드 수를 담을 변수
  int maxRound = -1;

  // 위에 있는 선택 항목
  late WorldCupItemModel topItem;
  // 아래에 있는 선택 항목
  late WorldCupItemModel bottomItem;

  // 게임 시작 시 초기 셋팅
  @override
  void initState() {
    super.initState();
    nowList = widget.itemList;
    // 항목은 랜덤으로 섞은 후
    nowList.shuffle(Random());
    // 선택한 라운드만큼 리스트를 수정하기
    List<WorldCupItemModel> tempList = [];
    for(int i=0; i<widget.selectedRound; i++){
      tempList.add(nowList[i]);
    }
    nowList.clear();
    nowList.addAll(tempList);

    // 1라운드 부터 시작
    round = 1;
    // 최대 라운드
    maxRound = nowList.length ~/ 2;
    // nowList에서 2개 항목을 꺼내 위아래 화면에 배치한다.
    setGame();

    // Provider
    final selectProvider = Provider.of<WorldCupSelectProvider>(context, listen: false);
    // 항목이 선택될때마다 nextList에 해당 항목을 추가
    selectProvider.addListener((){
      nextList.add(selectProvider.selectedModel);
      showNext();
    });
  }

  // 매 라운드가 시작할 때마다 nowList에서 항목 2개를 각각 topItem, bottomItem에 넣는다.
  void setGame(){
    topItem = nowList.removeLast();
    bottomItem = nowList.removeLast();
  }

  // 항목을 선택하면 호출하는 메서드
  Future<void> showNext() async {
    // 항목 선택하고 3초후에 다음으로 진행
    return Future.delayed(const Duration(seconds: 3), () {
      // 결승전이었을 경우
      if(maxRound==1){
        // 게임이 끝나면 결과 화면으로 이동
        Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const ResultWorldCupScreen(),
            ),
        );
      }else{
        // 결승전이 아닌 경우
        setState(() {
          if(nowList.isEmpty){
            // 라운드가 끝나면 다음 라운드를 위해 초기화
            round = 1;
            nowList.addAll(nextList);
            nowList.shuffle(Random());
            nextList.clear();
            maxRound = nowList.length ~/ 2;
          }else{
            // 라운드가 아직 안 끝난 경우
            round ++;
          }
          setGame();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black,
      child: Stack(
        children: [
          Column(
            children: [
              ItemTop(topItem),
              ItemBottom(bottomItem),
            ],
          ),
          Text(
              (maxRound==1) ? "결승" : "$round / $maxRound",
              style: const TextStyle(
                  fontSize: 24,
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  backgroundColor: Colors.grey
              )
          ),
        ],
      ),
    );
  }
}

enum SelectedItemPosition{
  top,
  bottom,
  none,
}