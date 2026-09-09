import 'package:flutter/material.dart';

/// [resolveDescriptionTextFit]이 고른 글자 크기와 줄 수.
@immutable
class DescriptionTextFit {
  /// 상자 안에 텍스트 전체가 들어가는 글자 크기.
  final double fontSize;

  /// 최소 글자 크기로도 전부 담을 수 없는 극단적인 경우에만 채워진다.
  /// 평소에는 null이고, null이면 줄 수 제한 없이 전부 표시한다.
  final int? maxLines;

  const DescriptionTextFit({required this.fontSize, this.maxLines});

  @override
  bool operator ==(Object other) =>
      other is DescriptionTextFit &&
      other.fontSize == fontSize &&
      other.maxLines == maxLines;

  @override
  int get hashCode => Object.hash(fontSize, maxLines);

  @override
  String toString() =>
      'DescriptionTextFit(fontSize: $fontSize, maxLines: $maxLines)';
}

/// [text]가 `maxWidth` x `maxHeight` 상자 안에 전부 들어가는 글자 크기를 찾는다.
///
/// [style]의 `fontSize`가 선호 크기다. 그 크기로 이미 들어가면 그대로 쓰므로
/// 짧은 설명의 겉모습은 달라지지 않고, 넘칠 때만 [minFontSize]까지 줄인다.
/// 줄바꿈은 매번 `maxWidth` 전체에서 다시 하므로 가로 공간을 낭비하지 않는다
/// (FittedBox처럼 블록 전체를 비례 축소하면 좌우에 빈 공간이 생긴다).
DescriptionTextFit resolveDescriptionTextFit({
  required String text,
  required TextStyle style,
  required double maxWidth,
  required double maxHeight,
  required double minFontSize,
  required TextScaler textScaler,
  required TextDirection textDirection,
  TextAlign textAlign = TextAlign.center,
}) {
  final preferredFontSize = style.fontSize ?? minFontSize;
  // TextPainter.layout은 음수 폭을 받지 못한다. 상자가 패딩보다 좁을 때를 막는다.
  final layoutWidth = maxWidth < 0 ? 0.0 : maxWidth;

  double heightAt(double fontSize) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: style.copyWith(fontSize: fontSize),
      ),
      textAlign: textAlign,
      textDirection: textDirection,
      textScaler: textScaler,
    )..layout(maxWidth: layoutWidth);
    final height = painter.height;
    painter.dispose();
    return height;
  }

  if (preferredFontSize <= minFontSize ||
      heightAt(preferredFontSize) <= maxHeight) {
    return DescriptionTextFit(fontSize: preferredFontSize);
  }

  if (heightAt(minFontSize) > maxHeight) {
    // 최소 크기로도 다 담기지 않는 비정상적으로 긴 설명. 오버플로를 내는 대신
    // 들어가는 줄 수만큼만 보여준다.
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: style.copyWith(fontSize: minFontSize),
      ),
      textAlign: textAlign,
      textDirection: textDirection,
      textScaler: textScaler,
    )..layout(maxWidth: layoutWidth);
    final lineHeight = painter.preferredLineHeight;
    painter.dispose();

    final fittingLines = lineHeight > 0 ? (maxHeight / lineHeight).floor() : 1;
    return DescriptionTextFit(
      fontSize: minFontSize,
      maxLines: fittingLines < 1 ? 1 : fittingLines,
    );
  }

  // 텍스트 높이는 글자 크기에 대해 단조 증가하므로 이분 탐색으로 좁힌다.
  // 최소 크기는 위에서 들어가는 것을 확인했으므로 항상 답이 존재한다.
  var low = minFontSize;
  var high = preferredFontSize;
  var best = minFontSize;
  for (var i = 0; i < 8; i++) {
    final mid = (low + high) / 2;
    if (heightAt(mid) <= maxHeight) {
      best = mid;
      low = mid;
    } else {
      high = mid;
    }
  }
  return DescriptionTextFit(fontSize: best);
}

/// 게임 화면의 항목 설명. 주어진 상자를 넘치면 글자 크기를 줄여서라도
/// 설명 전체를 보여준다.
///
/// 설명은 20자로 제한되지만, 제한이 없던 시절에 여러 장 업로드로 만들어진
/// 월드컵에는 20자를 넘는 설명이 이미 저장되어 있다. 그런 항목이 줄임표로
/// 잘리지 않게 하는 것이 이 위젯의 존재 이유다.
class ItemDescriptionText extends StatelessWidget {
  final String text;

  /// 선호 글자 크기가 담긴 스타일.
  final TextStyle style;

  /// 텍스트가 쓸 수 있는 최대 가로 크기.
  final double maxWidth;

  /// 텍스트가 쓸 수 있는 최대 세로 크기.
  final double maxHeight;

  /// 여기까지만 줄인다.
  final double minFontSize;

  final String? semanticsLabel;

  const ItemDescriptionText(
    this.text, {
    required this.style,
    required this.maxWidth,
    required this.maxHeight,
    this.minFontSize = 12.0,
    this.semanticsLabel,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    // Text가 실제로 쓰는 스타일과 같은 것으로 재야 계산이 맞는다.
    final effectiveStyle = DefaultTextStyle.of(context).style.merge(style);

    final fit = resolveDescriptionTextFit(
      text: text,
      style: effectiveStyle,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      minFontSize: minFontSize,
      textScaler: MediaQuery.textScalerOf(context),
      textDirection: Directionality.of(context),
    );

    return Text(
      text,
      textAlign: TextAlign.center,
      maxLines: fit.maxLines,
      overflow: fit.maxLines == null
          ? TextOverflow.clip
          : TextOverflow.ellipsis,
      style: effectiveStyle.copyWith(fontSize: fit.fontSize),
      semanticsLabel: semanticsLabel,
    );
  }
}
