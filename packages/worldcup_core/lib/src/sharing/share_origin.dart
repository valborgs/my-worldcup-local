/// 공유 시트를 띄울 화면상 위치 (iPad의 팝오버 앵커).
///
/// Flutter의 `Rect`를 도메인 / 데이터 포트 시그니처에 노출하지 않기 위한
/// 순수 값 타입이다. Flutter 타입으로의 변환은 UI와 어댑터 경계에서만 한다.
class ShareOrigin {
  final double left;
  final double top;
  final double width;
  final double height;

  const ShareOrigin({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });

  @override
  bool operator ==(Object other) =>
      other is ShareOrigin &&
      other.left == left &&
      other.top == top &&
      other.width == width &&
      other.height == height;

  @override
  int get hashCode => Object.hash(left, top, width, height);

  @override
  String toString() => 'ShareOrigin($left, $top, $width, $height)';
}
