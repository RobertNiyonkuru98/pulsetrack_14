import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'seed_data.dart';

/// The single door to local storage.
///
/// We chose sqflite (SQLite) rather than SharedPreferences because our data is
/// relational: members own many tasks, and the Insights screen aggregates with
/// GROUP BY. SharedPreferences is a key-value store, so we would have to load
/// and re-sort whole JSON lists on every screen.
class DbHelper {
  DbHelper._();

  static final DbHelper instance = DbHelper._();

  static const String dbName = 'pulsetrack.db';
  static const int dbVersion = 1;

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    final String path = join(await getDatabasesPath(), dbName);
    _database = await openDatabase(
      path,
      version: dbVersion,
      onCreate: _onCreate,
    );
    return _database!;
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute(
      'CREATE TABLE members ('
      'id TEXT PRIMARY KEY, '
      'name TEXT NOT NULL, '
      'role TEXT NOT NULL, '
      'email TEXT)',
    );

    await db.execute(
      'CREATE TABLE tasks ('
      'id TEXT PRIMARY KEY, '
      'title TEXT NOT NULL, '
      'description TEXT, '
      'project TEXT, '
      'assigneeId TEXT, '
      'createdAt INTEGER NOT NULL, '
      'dueDate INTEGER NOT NULL, '
      'priority TEXT NOT NULL, '
      'status TEXT NOT NULL, '
      'progress INTEGER NOT NULL DEFAULT 0)',
    );

    await db.execute(
      'CREATE TABLE activity ('
      'id TEXT PRIMARY KEY, '
      'memberId TEXT, '
      'message TEXT NOT NULL, '
      'at INTEGER NOT NULL, '
      'type TEXT NOT NULL)',
    );

    await db.execute(
      'CREATE TABLE sla_settings ('
      'id INTEGER PRIMARY KEY, '
      'criticalThreshold REAL NOT NULL, '
      'highThreshold REAL NOT NULL, '
      'mediumThreshold REAL NOT NULL, '
      'lowThreshold REAL NOT NULL, '
      'flagBlockedAsAtRisk INTEGER NOT NULL, '
      'warnUnder24h INTEGER NOT NULL)',
    );

    await SeedData.insertInto(db);
  }

  /// Only used by the "Reset demo data" button in Profile.
  Future<void> resetToSeed() async {
    final Database db = await database;
    await db.delete('tasks');
    await db.delete('activity');
    await SeedData.insertInto(db);
  }
}
