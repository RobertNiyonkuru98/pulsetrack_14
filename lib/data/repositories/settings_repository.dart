import 'package:sqflite/sqflite.dart';

import '../db_helper.dart';
import '../models/sla_settings.dart';

/// The SLA rules are stored in the database, not hard-coded, so the user can
/// change them at runtime and the change survives a restart.
class SettingsRepository {
  Future<Database> get _db => DbHelper.instance.database;

  Future<SlaSettings> load() async {
    final Database db = await _db;
    final List<Map<String, Object?>> rows =
        await db.query('sla_settings', limit: 1);
    if (rows.isEmpty) return const SlaSettings();
    return SlaSettings.fromMap(rows.first);
  }

  Future<void> save(SlaSettings settings) async {
    final Database db = await _db;
    await db.insert(
      'sla_settings',
      settings.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
