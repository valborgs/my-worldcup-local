/// 월드컵에 속한 항목(이미지) 하나.
class WorldCupItemModel {
  /// 식별자.
  final int idx;

  /// 이미지 경로. 샘플은 에셋 경로, 사용자 항목은 파일 경로다.
  /// 어느 쪽인지는 [worldCupIdx]의 부호로 판단한다.
  final String imagePath;

  /// 항목 설명(이름).
  final String imageInfo;

  /// 소속 월드컵 id.
  final int worldCupIdx;

  const WorldCupItemModel(
    this.idx,
    this.imagePath,
    this.imageInfo,
    this.worldCupIdx,
  );

  /// 샘플 월드컵의 항목인지 여부. 참이면 [imagePath]는 에셋 경로다.
  bool get isSample => worldCupIdx < 0;

  WorldCupItemModel copyWith({
    int? idx,
    String? imagePath,
    String? imageInfo,
    int? worldCupIdx,
  }) {
    return WorldCupItemModel(
      idx ?? this.idx,
      imagePath ?? this.imagePath,
      imageInfo ?? this.imageInfo,
      worldCupIdx ?? this.worldCupIdx,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is WorldCupItemModel &&
      other.idx == idx &&
      other.imagePath == imagePath &&
      other.imageInfo == imageInfo &&
      other.worldCupIdx == worldCupIdx;

  @override
  int get hashCode => Object.hash(idx, imagePath, imageInfo, worldCupIdx);

  @override
  String toString() => 'WorldCupItemModel($idx, $imageInfo)';
}
