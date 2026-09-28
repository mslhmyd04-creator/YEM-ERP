import 'dart:io';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

/// Kept out of the database file and source code. On Android this delegates to
/// platform key storage; the Windows implementation uses its platform backend.
abstract interface class DatabaseKeyStore {
  Future<String?> read();
  Future<void> write(String hexKey);
}

class PlatformDatabaseKeyStore implements DatabaseKeyStore {
  PlatformDatabaseKeyStore(this.storage);

  final FlutterSecureStorage storage;
  static const keyName = 'yem_erp_database_key_v1';

  @override
  Future<String?> read() => storage.read(key: keyName);

  @override
  Future<void> write(String hexKey) => storage.write(key: keyName, value: hexKey);
}

class EncryptedLocalDatabase {
  EncryptedLocalDatabase._(this.connection);

  final Database connection;

  static Future<EncryptedLocalDatabase> openApp() async {
    final directory = await getApplicationSupportDirectory();
    final path = '${directory.path}${Platform.pathSeparator}yem_erp.db';
    return open(
      path: path,
      keyStore: PlatformDatabaseKeyStore(const FlutterSecureStorage()),
    );
  }

  /// Fails closed: an existing file without its key is never silently reset.
  static Future<EncryptedLocalDatabase> open({
    required String path,
    required DatabaseKeyStore keyStore,
  }) async {
    final file = File(path);
    final existed = await file.exists();
    var hexKey = await keyStore.read();
    if (existed && hexKey == null) {
      throw StateError('Existing encrypted database has no stored key.');
    }
    if (hexKey == null) {
      final random = Random.secure();
      final bytes = List<int>.generate(32, (_) => random.nextInt(256));
      hexKey = bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
      await keyStore.write(hexKey);
    }
    if (!RegExp(r'^[0-9a-fA-F]{64}$').hasMatch(hexKey)) {
      throw StateError('Database key has invalid format.');
    }

    final db = sqlite3.open(path);
    try {
      final cipher = db.select('PRAGMA cipher_version');
      if (cipher.isEmpty || cipher.first.values.first.toString().isEmpty) {
        throw StateError('SQLCipher is unavailable; refusing unencrypted storage.');
      }
      db.execute('PRAGMA key = "x\'$hexKey\'"');
      db.select('SELECT count(*) FROM sqlite_master'); // Validate the key now.
      db.execute('PRAGMA foreign_keys = ON');
      if (db.select('PRAGMA foreign_keys').first.values.first != 1) {
        throw StateError('Foreign key enforcement is unavailable.');
      }
      await _migrate(db);
      return EncryptedLocalDatabase._(db);
    } catch (_) {
      db.close();
      rethrow;
    }
  }

  static Future<void> _migrate(Database db) async {
    final version = db.select('PRAGMA user_version').first.values.first as int;
    if (version == 1) {
      final applied = db.select('SELECT version FROM schema_migrations');
      if (applied.length != 1 || applied.first['version'] != 1) {
        throw StateError('Database migration history mismatch.');
      }
      return;
    }
    if (version != 0) {
      throw StateError('Unsupported database schema version: $version');
    }
    // Never apply the initial migration over a partially initialized database.
    if (db.select("SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'").isNotEmpty) {
      throw StateError('Unversioned database contains tables.');
    }
    final sql = await rootBundle.loadString('lib/src/data/migrations/001_core.sql');
    db.execute('BEGIN IMMEDIATE');
    try {
      db.execute(sql);
      db.execute('PRAGMA user_version = 1');
      db.execute('COMMIT');
    } catch (_) {
      db.execute('ROLLBACK');
      rethrow;
    }
  }

  void close() => connection.close();
}
