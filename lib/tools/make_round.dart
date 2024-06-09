// 최대 라운드 수에서 최소 4강까지 만들어주는 함수
List<int> makeRoundList(int maxRound){
  List<int> tempList = [];
  while(true){
    if(maxRound ~/ 4 == 0) break; // 4강까지 만들어줌
    if(maxRound ~/ 4 == 1) {
      tempList.add(4);
    }else{
      tempList.add(maxRound ~/ 2);
    }
    maxRound = maxRound~/2;
  }
  return tempList.reversed.toList();
}

// 전체 항목 개수에서 최대 라운드를 구해주는 함수
int makeMaxRound(int maxRound){
  if(maxRound ~/ 4 == 0) return 0; // 4강까지 만들어줌
  return maxRound ~/ 4 * 4;
}