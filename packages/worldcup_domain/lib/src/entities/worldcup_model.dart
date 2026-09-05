/// 월드컵(토너먼트) 한 건.
///
/// 불변 엔티티다. 값을 바꿀 때는 [copyWith]로 새 인스턴스를 만든다.
/// DB row와의 변환은 데이터 레이어의 매퍼가 담당한다. 엔티티는 저장 방식을
/// 알지 못한다.
class WorldCupModel {
  /// 식별자. 샘플 월드컵은 음수(-1, -2), 사용자가 만든 월드컵은 양수다.
  final int idx;

  /// 제목.
  final String title;

  /// 설명.
  final String info;

  /// 등록일.
  final DateTime date;

  /// 대표 이미지 경로.
  final String titleImageSrc;

  /// 등록된 항목 개수. 선택 가능한 라운드를 여기서 계산한다.
  final int maxRound;

  const WorldCupModel(
    this.idx,
    this.title,
    this.info,
    this.date,
    this.titleImageSrc,
    this.maxRound,
  );

  /// 앱이 기본 제공하는 샘플 월드컵인지 여부.
  ///
  /// 샘플은 수정 / 삭제 / 공유 대상이 아니며, 이미지도 파일이 아니라
  /// 에셋에서 읽는다.
  bool get isSample => idx < 0;

  WorldCupModel copyWith({
    int? idx,
    String? title,
    String? info,
    DateTime? date,
    String? titleImageSrc,
    int? maxRound,
  }) {
    return WorldCupModel(
      idx ?? this.idx,
      title ?? this.title,
      info ?? this.info,
      date ?? this.date,
      titleImageSrc ?? this.titleImageSrc,
      maxRound ?? this.maxRound,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is WorldCupModel &&
      other.idx == idx &&
      other.title == title &&
      other.info == info &&
      other.date == date &&
      other.titleImageSrc == titleImageSrc &&
      other.maxRound == maxRound;

  @override
  int get hashCode =>
      Object.hash(idx, title, info, date, titleImageSrc, maxRound);

  @override
  String toString() => 'WorldCupModel($idx, $title)';
}
