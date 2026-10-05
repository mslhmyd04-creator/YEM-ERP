import 'package:flutter/services.dart';
import 'package:sqlite3/sqlite3.dart';

class LocalMigrations {
  static const latestVersion = 6;
  static const assets = [
    'lib/src/data/migrations/001_core.sql',
    'lib/src/data/migrations/002_local_auth.sql',
    'lib/src/data/migrations/003_master_permissions.sql',
    'lib/src/data/migrations/004_branch_permissions.sql',
    'lib/src/data/migrations/005_administration.sql',
    'lib/src/data/migrations/006_financial_posting.sql',
  ];

  static Future<void> apply(Database db, {Future<String> Function(int)? load}) async {
    final version = db.select('PRAGMA user_version').single.values.first as int;
    if (version < 0 || version > latestVersion) {
      throw StateError('Unsupported database schema version: $version');
    }
    if (version == 0) {
      if (db.select("SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'").isNotEmpty) {
        throw StateError('Unversioned database contains tables.');
      }
    } else {
      _verifyHistory(db, version);
    }
    if (version == latestVersion) return;
    // Load first, then transact synchronously. No asynchronous work holds a SQL lock.
    final pending = <String>[];
    for (var target = version + 1; target <= latestVersion; target++) {
      pending.add(await (load?.call(target) ?? rootBundle.loadString(assets[target - 1])));
    }
    db.execute('BEGIN IMMEDIATE');
    try {
      for (final sql in pending) {
        db.execute(sql);
      }
      _verifyHistory(db, latestVersion);
      db.execute('PRAGMA user_version = $latestVersion');
      db.execute('COMMIT');
    } catch (_) {
      db.execute('ROLLBACK');
      rethrow;
    }
  }

  static void _verifyHistory(Database db, int version) {
    final rows = db.select('SELECT version FROM schema_migrations ORDER BY version');
    if (rows.length != version) throw StateError('Database migration history mismatch.');
    for (var i = 0; i < version; i++) {
      if (rows[i]['version'] != i + 1) throw StateError('Database migration history mismatch.');
    }
  }
}
