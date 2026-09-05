import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';

/// 샘플 월드컵 시드가 코드에서 JSON 에셋으로 옮겨왔다.
/// 이 에셋이 깨지면 앱 첫 실행 시 샘플 월드컵이 사라지므로,
/// 형식과 참조 이미지의 존재를 여기서 지킨다.
void main() {
  const assetPath = 'assets/sample/sample_worldcups.json';

  late List<dynamic> worldCups;

  setUpAll(() async {
    // 앱과 똑같이 에셋 번들에서 읽는다.
    // 디스크에서 File로 읽으면 pubspec에 에셋을 등록하지 않아도 통과해버려,
    // 앱이 시작조차 못 하는 상황을 놓친다(실제로 그렇게 놓쳤다).
    TestWidgetsFlutterBinding.ensureInitialized();
    final raw = await rootBundle.loadString(assetPath);
    worldCups = (jsonDecode(raw) as Map<String, dynamic>)['worldCups'] as List;
  });

  test('시드 에셋이 pubspec에 등록되어 번들에서 읽힌다', () async {
    // 이 호출이 던지면 pubspec의 flutter/assets 목록을 확인할 것.
    // 디렉터리 항목은 재귀적이지 않아 하위 폴더만 적으면 최상위 파일이 빠진다.
    await expectLater(rootBundle.loadString(assetPath), completes);
  });

  test('시드 에셋이 파싱된다', () {
    expect(worldCups, hasLength(2));
  });

  test('샘플 월드컵의 idx는 음수다', () {
    // 시더가 idx < 0 조건으로 샘플만 지우고 다시 넣는다.
    // 양수면 사용자가 만든 월드컵을 지울 위험이 있다.
    for (final raw in worldCups) {
      expect(raw['idx'] as int, lessThan(0), reason: '${raw['title']}');
    }
  });

  test('항목 개수가 maxRound와 일치한다', () {
    for (final raw in worldCups) {
      final items = raw['items'] as List;
      expect(items, hasLength(raw['maxRound'] as int),
          reason: '${raw['title']}');
    }
  });

  test('참조하는 이미지 파일이 모두 존재한다', () {
    final missing = <String>[];
    for (final raw in worldCups) {
      final paths = <String>[
        raw['titleImage'] as String,
        for (final item in raw['items'] as List) item['image'] as String,
      ];
      for (final path in paths) {
        if (!File(path).existsSync()) missing.add(path);
      }
    }
    expect(missing, isEmpty);
  });

  test('대표 이미지가 항목 목록에 포함된다', () {
    for (final raw in worldCups) {
      final images = [
        for (final item in raw['items'] as List) item['image'] as String,
      ];
      expect(images, contains(raw['titleImage'] as String),
          reason: '${raw['title']}');
    }
  });

  test('항목 설명이 비어있지 않다', () {
    for (final raw in worldCups) {
      for (final item in raw['items'] as List) {
        expect((item['info'] as String).trim(), isNotEmpty);
      }
    }
  });
}
