// #19 회귀 테스트.
//
// 항목 설명은 20자로 제한하는 것이 기획 의도였지만, 여러 장 업로드 경로에는
// 그 제한이 빠져 있었다. 그 시절에 만들어진 월드컵에는 20자를 넘는 설명이
// 이미 저장되어 있는데, 게임 화면이 maxLines: 2 + ellipsis로 그리면서
// 그런 항목의 설명이 잘려 보였다.
//
// 이제는 넘칠 때 글자 크기를 줄여서라도 설명 전체를 보여준다. 짧은 설명은
// 선호 크기를 그대로 써야 하므로 겉모습이 달라지지 않는다.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worldcup_domain/worldcup_domain.dart';

import 'package:feature_worldcup_play/src/widgets/game_item.dart';
import 'package:feature_worldcup_play/src/widgets/item_description_text.dart';

void main() {
  // 게임 화면이 실제로 쓰는 값에 맞춘 상자. 세로 폰(가로 411dp) 기준으로
  // 항목 하나의 높이가 약 380dp일 때 설명이 쓸 수 있는 크기다.
  const preferredFontSize = 24.0;
  const minFontSize = 12.0;
  const maxWidth = 411.0 - 24;
  const maxHeight = 380.0 * 0.4;
  const style = TextStyle(
    fontSize: preferredFontSize,
    fontWeight: FontWeight.bold,
  );

  DescriptionTextFit fitFor(
    String text, {
    double width = maxWidth,
    double height = maxHeight,
  }) {
    return resolveDescriptionTextFit(
      text: text,
      style: style,
      maxWidth: width,
      maxHeight: height,
      minFontSize: minFontSize,
      textScaler: TextScaler.noScaling,
      textDirection: TextDirection.ltr,
    );
  }

  double laidOutHeight(String text, DescriptionTextFit fit, {double? width}) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: style.copyWith(fontSize: fit.fontSize),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
      textScaler: TextScaler.noScaling,
      maxLines: fit.maxLines,
    )..layout(maxWidth: width ?? maxWidth);
    final height = painter.height;
    painter.dispose();
    return height;
  }

  setUpAll(TestWidgetsFlutterBinding.ensureInitialized);

  test('20자 이하 설명은 선호 글자 크기를 그대로 쓰고 줄 수를 제한하지 않는다', () {
    const short = '아이유';
    const twenty = '가나다라마바사아자차카타파하가나다라마바'; // 정확히 20자

    expect(twenty.length, 20);

    for (final text in [short, twenty]) {
      final fit = fitFor(text);
      expect(fit.fontSize, preferredFontSize, reason: text);
      expect(fit.maxLines, isNull, reason: text);
    }
  });

  test('20자를 크게 넘는 설명도 줄임표 없이 전부 표시한다', () {
    // 제한이 없던 시절에 저장된 40자짜리 설명.
    const long =
        '가나다라마바사아자차카타파하가나다라마바'
        '사아자차카타파하가나다라마바사아자차카타';
    expect(long.length, 40);

    final fit = fitFor(long);

    // 줄 수 제한이 없다 = 잘리는 글자가 없다.
    expect(fit.maxLines, isNull);
    // 상자를 넘지 않는다.
    expect(laidOutHeight(long, fit), lessThanOrEqualTo(maxHeight));
    expect(fit.fontSize, lessThanOrEqualTo(preferredFontSize));
    expect(fit.fontSize, greaterThanOrEqualTo(minFontSize));
  });

  test('상자가 좁으면 최소 글자 크기까지 줄인다', () {
    const long =
        '가나다라마바사아자차카타파하가나다라마바'
        '사아자차카타파하가나다라마바사아자차카타';

    // 두세 줄밖에 못 담는 낮은 상자.
    final fit = fitFor(long, height: 60);

    expect(fit.fontSize, lessThan(preferredFontSize));
    expect(fit.fontSize, greaterThanOrEqualTo(minFontSize));
  });

  test('최소 글자 크기로도 못 담는 설명은 오버플로 대신 들어가는 줄 수만 보여준다', () {
    final absurd = '가나다라마바사아자차카타파하' * 40; // 560자

    final fit = fitFor(absurd, height: 60);

    expect(fit.fontSize, minFontSize);
    expect(fit.maxLines, isNotNull);
    expect(fit.maxLines, greaterThanOrEqualTo(1));
    expect(laidOutHeight(absurd, fit), lessThanOrEqualTo(60));
  });

  testWidgets('게임 화면의 긴 설명이 잘리지 않고 전부 렌더된다', (WidgetTester tester) async {
    const long =
        '가나다라마바사아자차카타파하가나다라마바'
        '사아자차카타파하가나다라마바사아자차카타';
    const item = WorldCupItemModel(1, 'assets/sample/female/chu.jpg', long, -1);

    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                GameItem(
                  item,
                  position: SelectedItemPosition.top,
                  axis: Axis.vertical,
                  matchId: 0,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // 설명 문자열 전체가 하나의 Text로 그려진다.
    final text = tester.widget<Text>(find.text(long));
    expect(text.maxLines, isNull);
    expect(text.overflow, TextOverflow.clip);
    expect(tester.takeException(), isNull);
  });
}
