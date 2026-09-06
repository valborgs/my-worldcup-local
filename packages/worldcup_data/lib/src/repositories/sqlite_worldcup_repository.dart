import 'package:worldcup_core/worldcup_core.dart';
import 'package:worldcup_domain/worldcup_domain.dart';

import '../database/app_database.dart';
import '../dto/worldcup_row.dart';

/// [WorldCupRepository]의 SQLite 구현.
///
/// sqflite 예외는 밖으로 흘려보내지 않고 [StorageFailure]로 감싼다.
class SqliteWorldCupRepository implements WorldCupRepository {
  final AppDatabase _db;

  const SqliteWorldCupRepository(this._db);

  @override
  Future<int> count({String searchQuery = ''}) {
    return _guard('월드컵 개수를 불러오지 못했습니다.', () async {
      final db = await _db.database;
      final query = searchQuery.trim();
      final where = query.isEmpty ? '' : ' WHERE title LIKE ? OR info LIKE ?';
      final args = query.isEmpty ? <Object?>[] : ['%$query%', '%$query%'];
      final result = await db.rawQuery(
        'SELECT COUNT(*) AS count FROM ${AppDatabase.worldCupTable}$where',
        args,
      );
      return (result.first['count'] as num?)?.toInt() ?? 0;
    });
  }

  @override
  Future<int> indexOf(int idx) {
    return _guard('월드컵 위치를 찾지 못했습니다.', () async {
      final db = await _db.database;
      final result = await db.rawQuery(
        'SELECT COUNT(*) AS itemIndex FROM ${AppDatabase.worldCupTable} '
        'WHERE idx < ?',
        [idx],
      );
      return (result.first['itemIndex'] as num?)?.toInt() ?? 0;
    });
  }

  @override
  Future<List<WorldCupModel>> page({
    required int limit,
    required int offset,
    String searchQuery = '',
  }) {
    return _guard('월드컵 목록을 불러오지 못했습니다.', () async {
      final db = await _db.database;
      final query = searchQuery.trim();
      final rows = await db.query(
        AppDatabase.worldCupTable,
        where: query.isEmpty ? null : 'title LIKE ? OR info LIKE ?',
        whereArgs: query.isEmpty ? null : ['%$query%', '%$query%'],
        orderBy: 'idx ASC',
        limit: limit,
        offset: offset,
      );
      return rows.map(worldCupFromRow).toList();
    });
  }

  @override
  Future<WorldCupModel?> findById(int idx) {
    return _guard('월드컵을 불러오지 못했습니다.', () async {
      final db = await _db.database;
      final rows = await db.query(
        AppDatabase.worldCupTable,
        where: 'idx = ?',
        whereArgs: [idx],
        limit: 1,
      );
      if (rows.isEmpty) return null;
      return worldCupFromRow(rows.first);
    });
  }

  @override
  Future<List<WorldCupItemModel>> items(int worldCupIdx) {
    return _guard('월드컵 항목을 불러오지 못했습니다.', () async {
      final db = await _db.database;
      final rows = await db.query(
        AppDatabase.worldCupItemTable,
        where: 'worldCupIdx = ?',
        whereArgs: [worldCupIdx],
      );
      return rows.map(worldCupItemFromRow).toList();
    });
  }

  @override
  Future<int> add(WorldCupModel model, List<WorldCupItemModel> items) {
    return _guard('월드컵을 저장하지 못했습니다.', () async {
      final db = await _db.database;
      return db.transaction((txn) async {
        final worldCupIdx = await txn.insert(
          AppDatabase.worldCupTable,
          model.toRow(),
        );
        final batch = txn.batch();
        for (final item in items) {
          // 새로 만들어진 월드컵 id로 소속을 덮어쓴다.
          batch.insert(
            AppDatabase.worldCupItemTable,
            item.copyWith(worldCupIdx: worldCupIdx).toRow(),
          );
        }
        await batch.commit(noResult: true);
        return worldCupIdx;
      });
    });
  }

  @override
  Future<void> update(WorldCupModel model, List<WorldCupItemModel> items) {
    return _guard('월드컵을 수정하지 못했습니다.', () async {
      final db = await _db.database;
      await db.transaction((txn) async {
        await txn.update(
          AppDatabase.worldCupTable,
          model.toRow(),
          where: 'idx = ?',
          whereArgs: [model.idx],
        );
        // 항목은 부분 갱신하지 않고 통째로 교체한다.
        await txn.delete(
          AppDatabase.worldCupItemTable,
          where: 'worldCupIdx = ?',
          whereArgs: [model.idx],
        );
        final batch = txn.batch();
        for (final item in items) {
          batch.insert(AppDatabase.worldCupItemTable, item.toRow());
        }
        await batch.commit(noResult: true);
      });
    });
  }

  @override
  Future<void> delete(int idx) {
    return _guard('월드컵을 삭제하지 못했습니다.', () async {
      final db = await _db.database;
      await db.transaction((txn) async {
        await txn.delete(
          AppDatabase.worldCupItemTable,
          where: 'worldCupIdx = ?',
          whereArgs: [idx],
        );
        await txn.delete(
          AppDatabase.worldCupTable,
          where: 'idx = ?',
          whereArgs: [idx],
        );
      });
    });
  }

  Future<T> _guard<T>(String message, Future<T> Function() body) async {
    try {
      return await body();
    } catch (error, stackTrace) {
      throw StorageFailure(message, cause: error, stackTrace: stackTrace);
    }
  }
}
