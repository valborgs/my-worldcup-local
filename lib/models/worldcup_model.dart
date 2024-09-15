class WorldCupModel{
  // idx
  int idx;
  // 타이틀
  String title;
  // 설명
  String info;
  // 등록일
  DateTime date;
  // 대표이미지
  String titleImageSrc;
  // 최대 라운드
  int maxRound;

  // 생성자
  WorldCupModel(
      this.idx,
      this.title,
      this.info,
      this.date,
      this.titleImageSrc,
      this.maxRound,
      );

  // dao 사용을 위해 model에서 Map으로 변환
  Map<String, dynamic> toMap(){
    return Map.of({
      if(idx<0) "idx": idx,
      "title": title,
      "info": info,
      "date": date.millisecondsSinceEpoch, //millisecondsSinceEpoch는 현재시간을 ms로 변환하여 int값으로 반환해줌
      "titleImageSrc": titleImageSrc,
      "maxRound": maxRound,
    });
  }

  // 새로운 인스턴스를 생성하지 않는 생성자를 구현할 때 factory 키워드를 사용
  factory WorldCupModel.fromDB(Map<String, dynamic> data){
    return WorldCupModel(
        data['idx'],
        data['title'],
        data['info'],
        DateTime.fromMicrosecondsSinceEpoch(data['date'] as int),
        data['titleImageSrc'],
        data['maxRound'],
    );
  }
}