import 'package:sqflite/sqflite.dart';

import '../db_helper.dart';
import '../models/task.dart';

class TaskRepository {
  Future<Database> get _db => DbHelper.instance.database;

  /// Soonest deadline first - that is the order a manager cares about.
  Future<List<Task>> getAll() async {
    final Database db = await _db;
    final List<Map<String, Object?>> rows =
        await db.query('tasks', orderBy: 'dueDate ASC');
    return rows.map(Task.fromMap).toList();
  }

  Future<Task?> findById(String id) async {
    final Database db = await _db;
    final List<Map<String, Object?>> rows = await db.query(
      'tasks',
      where: 'id = ?',
      whereArgs: <Object?>[id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Task.fromMap(rows.first);
  }

  Future<List<Task>> findByAssignee(String memberId) async {
    final Database db = await _db;
    final List<Map<String, Object?>> rows = await db.query(
      'tasks',
      where: 'assigneeId = ?',
      whereArgs: <Object?>[memberId],
      orderBy: 'dueDate ASC',
    );
    return rows.map(Task.fromMap).toList();
  }

  Future<void> upsert(Task task) async {
    final Database db = await _db;
    await db.insert(
      'tasks',
      task.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> delete(String id) async {
    final Database db = await _db;
    await db.delete('tasks', where: 'id = ?', whereArgs: <Object?>[id]);
  }

  /// Used by Insights: how many tasks sit in each status, counted in SQL.
  Future<int> countAll() async {
    final Database db = await _db;
    final List<Map<String, Object?>> rows =
        await db.rawQuery('SELECT COUNT(*) AS c FROM tasks');
    return (rows.first['c'] as int?) ?? 0;
  }
}
