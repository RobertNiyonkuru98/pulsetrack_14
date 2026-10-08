import 'package:sqflite/sqflite.dart';

import '../db_helper.dart';
import '../models/member.dart';

class MemberRepository {
  Future<Database> get _db => DbHelper.instance.database;

  Future<List<Member>> getAll() async {
    final Database db = await _db;
    final List<Map<String, Object?>> rows =
        await db.query('members', orderBy: 'name ASC');
    return rows.map(Member.fromMap).toList();
  }

  Future<Member?> findById(String id) async {
    final Database db = await _db;
    final List<Map<String, Object?>> rows = await db.query(
      'members',
      where: 'id = ?',
      whereArgs: <Object?>[id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Member.fromMap(rows.first);
  }

  Future<void> upsert(Member member) async {
    final Database db = await _db;
    await db.insert(
      'members',
      member.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> delete(String id) async {
    final Database db = await _db;
    await db.delete('members', where: 'id = ?', whereArgs: <Object?>[id]);
  }
}
