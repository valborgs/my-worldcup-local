import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:worldcup_core/worldcup_core.dart';

import '../database/app_database.dart';
import 'seed_ids.dart';

/// Android의 `Context.getNoBackupFilesDir()`. 다른 플랫폼에서는 null.
///
/// path_provider가 이 경로를 내주지 않아 문서 디렉터리(`<data>/app_flutter`)의
/// 형제인 `<data>/no_backup`으로 직접 구한다. 자동 백업과 기기 간 이전
/// 어느 쪽에도 실리지 않는다고 플랫폼이 보장하는 유일한 영구 경로다.
Future<Directory?> androidNoBackupDirectory() async {
  if (!Platform.isAndroid) return null;
  final documents = await getApplicationDocumentsDirectory();
  return Directory(p.join(documents.parent.path, 'no_backup'));
}

/// 샘플 월드컵을 앱 시작 시마다 최신 상태로 동기화한다.
///
/// 삭제 기록이 없는 샘플(idx < 0)만 다시 넣는다. 샘플 이미지 에셋이 교체되거나
/// 이름이 바뀌어도 로컬 DB에 남아있던 예전 경로를 참조하지 않게 하기 위해서다.
/// 사용자가 만든 월드컵(idx > 0)은 건드리지 않는다.
///
/// 시드 내용은 코드가 아니라 JSON에서 읽는다. 어느 에셋에서 읽을지는 앱이
/// [manifestLoader]로 정해주므로, 이 패키지는 앱의 에셋 경로를 알지 못한다.
class SampleWorldCupSeeder {
  static const String _installMarkerName = 'sample_seed_installed';

  final AppDatabase _database;
  final Future<String> Function() _manifestLoader;
  final Future<Directory?> Function() _noBackupDirectoryProvider;
  final AppLogger _logger;

  /// [database]는 시드를 쓸 연결, [manifestLoader]는 시드 JSON을 읽어오는
  /// 함수다. 후자를 주입받기 때문에 이 패키지는 앱의 에셋 경로를 모른다.
  /// [noBackupDirectoryProvider]는 테스트에서 임시 경로를 끼우기 위한 훅이다.
  const SampleWorldCupSeeder({
    required this._database,
    required this._manifestLoader,
    Future<Directory?> Function()? noBackupDirectoryProvider,
    this._logger = const DeveloperLogger('sample_worldcup_seeder'),
  }) : _noBackupDirectoryProvider =
           noBackupDirectoryProvider ?? androidNoBackupDirectory;

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

    final newInstallMarker = await _missingInstallMarker();

    try {
      final db = await _database.database;
      await db.transaction((txn) async {
        if (newInstallMarker != null) {
          await txn.delete(AppDatabase.deletedSampleTable);
        }
        final deletedRows = await txn.query(AppDatabase.deletedSampleTable);
        final deletedIds = deletedRows.map((row) => row['idx'] as int).toSet();
        // 예전에 저장됐던 샘플 데이터를 모두 지운다.
        await txn.delete(
          AppDatabase.worldCupItemTable,
          where: 'worldCupIdx < 0',
        );
        await txn.delete(AppDatabase.worldCupTable, where: 'idx < 0');

        for (final sample in samples) {
          if (deletedIds.contains(sample.idx)) continue;
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

    // 삭제 기록을 비운 트랜잭션이 커밋된 뒤에 남긴다. 먼저 남기면 동기화가
    // 실패했을 때 복원된 삭제 기록이 그대로 굳는다.
    if (newInstallMarker != null) {
      try {
        await newInstallMarker.create(recursive: true);
      } on FileSystemException catch (error, stackTrace) {
        _logger.error(
          '설치 표식을 남기지 못했습니다. 다음 실행에서 샘플이 다시 복원됩니다.',
          error: error,
          stackTrace: stackTrace,
        );
      }
    }
  }

  /// 이번 설치에서 아직 남기지 않은 설치 표식. 이미 있거나 알 수 없으면 null.
  ///
  /// Android 자동 백업은 재설치 때 DB를 통째로 복원하므로 샘플 삭제 기록도
  /// 따라온다. 삭제한 샘플은 재실행에서는 지워진 채여야 하지만 재설치에서는
  /// 돌아와야 하는데, DB만 봐서는 둘을 구분할 수 없다. 그래서 백업에 실리지
  /// 않는 곳에 표식을 두고, 표식이 없으면 새 설치로 보고 삭제 기록을 비운다.
  ///
  /// 표식을 확인할 수 없을 때는 비우지 않는다. 지운 샘플이 실행할 때마다
  /// 되살아나는 것보다 재설치 뒤에 안 돌아오는 쪽이 덜 나쁘다.
  Future<File?> _missingInstallMarker() async {
    try {
      final directory = await _noBackupDirectoryProvider();
      if (directory == null) return null;
      final marker = File(p.join(directory.path, _installMarkerName));
      return await marker.exists() ? null : marker;
    } catch (error, stackTrace) {
      _logger.error('설치 표식을 확인하지 못했습니다.', error: error, stackTrace: stackTrace);
      return null;
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
    if (isDebugWorldCupId(idx)) {
      throw FormatException('디버그 전용 idx는 샘플에 사용할 수 없습니다: $idx');
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
