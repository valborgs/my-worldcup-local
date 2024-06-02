class WorldCupItemModel{
  // idx
  int idx;
  // 타이틀
  String imagePath;
  // 설명
  String imageInfo;
  // 월드컵 idx
  int worldCupIdx;

  // 생성자
  WorldCupItemModel(
      this.idx,
      this.imagePath,
      this.imageInfo,
      this.worldCupIdx,
      );

  // dao 사용을 위해 model에서 Map으로 변환
  Map<String, dynamic> toMap(){
    return Map.of({
      "idx": idx,
      "imagePath": imagePath,
      "imageInfo": imageInfo,
      "worldCupIdx": worldCupIdx,
    });
  }

  // 새로운 인스턴스를 생성하지 않는 생성자를 구현할 때 factory 키워드를 사용
  factory WorldCupItemModel.fromDB(Map<String, dynamic> data){
    return WorldCupItemModel(
      data['idx'],
      data['imagePath'],
      data['imageInfo'],
      data['worldCupIdx'],
    );
  }
}