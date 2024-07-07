// 최대 라운드 수에서 최소 4강까지 만들어주는 함수
List<int> makeRoundList(int maxRound){
  List<int> tempList = [];
  var round = 4;
  while(true){
    if(maxRound ~/ 4 == 0) {
      break; // 4강까지 만들어줌
    }else {
      tempList.add(round);
      maxRound = maxRound~/2;
      round*=2;
    }
  }
  return tempList;
}

// 전체 항목 개수에서 최대 라운드를 구해주는 함수
int makeMaxRound(int maxRound){
  if(maxRound ~/ 4 == 0) return 0; // 4강까지 만들어줌
  return maxRound ~/ 4 * 4;
}