import 'dart:convert';

import 'package:sqflite/sqflite.dart';
import 'package:worldcup_core/worldcup_core.dart';

import '../database/app_database.dart';

/// 샘플 월드컵을 앱 시작 시마다 최신 상태로 동기화한다.
///
/// 기존 샘플(idx < 0)을 지우고 다시 넣는다. 샘플 이미지 에셋이 교체되거나
/// 이름이 바뀌어도 로컬 DB에 남아있던 예전 경로를 참조하지 않게 하기 위해서다.
/// 사용자가 만든 월드컵(idx > 0)은 건드리지 않는다.
///
/// 시드 내용은 코드가 아니라 JSON에서 읽는다. 어느 에셋에서 읽을지는 앱이
/// [manifestLoader]로 정해주므로, 이 패키지는 앱의 에셋 경로를 알지 못한다.
class SampleWorldCupSeeder {
  final AppDatabase _database;
  final Future<String> Function() _manifestLoader;

  /// [database]는 시드를 쓸 연결, [manifestLoader]는 시드 JSON을 읽어오는
  /// 함수다. 후자를 주입받기 때문에 이 패키지는 앱의 에셋 경로를 모른다.
  const SampleWorldCupSeeder({
    required this._database,
    required this._manifestLoader,
  });

  Future<void> sync() async {
    final List<_SampleWorldCup> samples;
    try {
      samples = _parse(await _manifestLoader());
    } catch (error, stackTrace) {
      throw StorageFailure(
        '샘플 월드컵 데이터를 읽지 못했습니다.',
        cause: error,
        stackTrace: stackTrace,
      );
    }

    try {
      final db = await _database.database;
      await db.transaction((txn) async {
        // 예전에 저장됐던 샘플 데이터를 모두 지운다.
        await txn.delete(
          AppDatabase.worldCupItemTable,
          where: 'worldCupIdx < 0',
        );
        await txn.delete(AppDatabase.worldCupTable, where: 'idx < 0');

        for (final sample in samples) {
          await txn.insert(AppDatabase.worldCupTable, <String, Object?>{
            'idx': sample.idx,
            'title': sample.title,
            'info': sample.info,
            // 샘플은 등록일이 의미가 없어 예전부터 DateTime(0)을 써왔다.
            'date': DateTime(0).millisecondsSinceEpoch,
            'titleImageSrc': sample.titleImage,
            'maxRound': sample.maxRound,
          });

          final batch = txn.batch();
          for (final item in sample.items) {
            batch.insert(AppDatabase.worldCupItemTable, <String, Object?>{
              'imagePath': item.image,
              'imageInfo': item.info,
              'worldCupIdx': sample.idx,
            });
          }
          await batch.commit(noResult: true);
        }
      });
    } on DatabaseException catch (error, stackTrace) {
      throw StorageFailure(
        '샘플 월드컵 데이터를 저장하지 못했습니다.',
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }

  static List<_SampleWorldCup> _parse(String source) {
    final decoded = jsonDecode(source) as Map<String, Object?>;
    final worldCups = decoded['worldCups'] as List<Object?>;
    return [
      for (final raw in worldCups)
        _SampleWorldCup.fromJson(raw as Map<String, Object?>),
    ];
  }
}

class _SampleWorldCup {
  final int idx;
  final String title;
  final String info;
  final String titleImage;
  final int maxRound;
  final List<_SampleItem> items;

  const _SampleWorldCup({
    required this.idx,
    required this.title,
    required this.info,
    required this.titleImage,
    required this.maxRound,
    required this.items,
  });

  factory _SampleWorldCup.fromJson(Map<String, Object?> json) {
    final items = [
      for (final raw in json['items'] as List<Object?>)
        _SampleItem.fromJson(raw as Map<String, Object?>),
    ];
    final idx = json['idx'] as int;
    if (idx >= 0) {
      throw FormatException('샘플 월드컵의 idx는 음수여야 합니다: $idx');
    }
    return _SampleWorldCup(
      idx: idx,
      title: json['title'] as String,
      info: json['info'] as String,
      titleImage: json['titleImage'] as String,
      maxRound: json['maxRound'] as int,
      items: items,
    );
  }
}

class _SampleItem {
  final String image;
  final String info;

  const _SampleItem({required this.image, required this.info});

  factory _SampleItem.fromJson(Map<String, Object?> json) {
    return _SampleItem(
      image: json['image'] as String,
      info: json['info'] as String,
    );
  }
}
