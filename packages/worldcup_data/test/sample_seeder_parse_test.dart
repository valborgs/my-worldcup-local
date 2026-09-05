import 'dart:convert';
import 'dart:io' show FileSystemException;

import 'package:flutter_test/flutter_test.dart';
import 'package:worldcup_data/worldcup_data.dart';
import 'package:worldcup_core/worldcup_core.dart';

/// 시더는 DB 없이도 매니페스트 파싱 단계에서 실패를 걸러야 한다.
/// 잘못된 시드로 사용자 데이터를 건드리는 일을 막기 위해서다.
void main() {
  test('매니페스트를 읽지 못하면 StorageFailure로 감싼다', () async {
    final seeder = SampleWorldCupSeeder(
      database: AppDatabase(),
      manifestLoader: () async => throw const FileSystemException('없음'),
    );
    await expectLater(seeder.sync(), throwsA(isA<StorageFailure>()));
  });

  test('매니페스트가 깨져 있으면 StorageFailure로 감싼다', () async {
    final seeder = SampleWorldCupSeeder(
      database: AppDatabase(),
      manifestLoader: () async => '{ not json',
    );
    await expectLater(seeder.sync(), throwsA(isA<StorageFailure>()));
  });

  test('샘플 idx가 양수면 거부한다', () async {
    // 양수 idx를 허용하면 사용자가 만든 월드컵을 지울 수 있다.
    final seeder = SampleWorldCupSeeder(
      database: AppDatabase(),
      manifestLoader: () async => jsonEncode({
        'worldCups': [
          {
            'idx': 5,
            'title': 't',
            'info': 'i',
            'titleImage': 'a.jpg',
            'maxRound': 4,
            'items': [
              {'image': 'a.jpg', 'info': 'x'},
            ],
          },
        ],
      }),
    );
    await expectLater(seeder.sync(), throwsA(isA<StorageFailure>()));
  });
}
