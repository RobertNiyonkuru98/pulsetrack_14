import 'package:sqflite/sqflite.dart';

import '../db_helper.dart';
import '../models/activity.dart';

class ActivityRepository {
  Future<Database> get _db => DbHelper.instance.database;

  /// Newest first.
  Future<List<Activity>> getAll({int limit = 100}) async {
    final Database db = await _db;
    final List<Map<String, Object?>> rows = await db.query(
      'activity',
      orderBy: 'at DESC',
      limit: limit,
    );
    return rows.map(Activity.fromMap).toList();
  }

  Future<void> add(Activity activity) async {
    final Database db = await _db;
    await db.insert('activity', activity.toMap());
  }
}
