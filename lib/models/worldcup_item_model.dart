class WorldCupItemModel{
  // idx
  int idx;
  // 타이틀
  String itemImageSrc;
  // 설명
  String itemInfo;
  // 월드컵 idx
  int worldCupIdx;

  // 생성자
  WorldCupItemModel(
      this.idx,
      this.itemImageSrc,
      this.itemInfo,
      this.worldCupIdx,
      );

  // dao 사용을 위해 model에서 Map으로 변환
  Map<String, dynamic> toMap(){
    return Map.of({
      "idx": idx,
      "itemImageSrc": itemImageSrc,
      "itemInfo": itemInfo,
      "worldCupIdx": worldCupIdx,
    });
  }

  // 새로운 인스턴스를 생성하지 않는 생성자를 구현할 때 factory 키워드를 사용
  factory WorldCupItemModel.fromDB(Map<String, dynamic> data){
    return WorldCupItemModel(
      data['idx'],
      data['itemImageSrc'],
      data['itemInfo'],
      data['worldCupIdx'],
    );
  }
}