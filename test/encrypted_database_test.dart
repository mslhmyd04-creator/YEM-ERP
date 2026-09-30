import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:yem_erp/src/infrastructure/local_database.dart';

class _MemoryKeyStore implements DatabaseKeyStore {
  String? value;

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String hexKey) async => value = hexKey;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory directory;
  late String path;
  late _MemoryKeyStore keys;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('yem_erp_cipher_test_');
    path = '${directory.path}${Platform.pathSeparator}store.db';
    keys = _MemoryKeyStore();
  });

  tearDown(() async => directory.delete(recursive: true));

  test('database is encrypted, migrates once and reopens', () async {
    final first = await EncryptedLocalDatabase.open(path: path, keyStore: keys);
    expect(first.connection.select('PRAGMA user_version').first.values.first, 2);
    first.connection.execute(
      'INSERT INTO companies(id,name,created_at) VALUES(?,?,?)',
      ['company-1', 'مؤسسة', '2026-09-28T00:00:00Z'],
    );
    first.close();

    final header = await File(path).openRead(0, 16).expand((bytes) => bytes).toList();
    expect(String.fromCharCodes(header), isNot('SQLite format 3\u0000'));

    final reopened = await EncryptedLocalDatabase.open(path: path, keyStore: keys);
    expect(reopened.connection.select('SELECT name FROM companies').single['name'], 'مؤسسة');
    expect(reopened.connection.select('SELECT count(*) AS n FROM schema_migrations').single['n'], 2);
    reopened.close();
  });

  test('existing database refuses missing or incorrect key', () async {
    final db = await EncryptedLocalDatabase.open(path: path, keyStore: keys);
    db.close();
    final lost = _MemoryKeyStore();
    await expectLater(
      EncryptedLocalDatabase.open(path: path, keyStore: lost),
      throwsStateError,
    );
    lost.value = 'a' * 64;
    await expectLater(
      EncryptedLocalDatabase.open(path: path, keyStore: lost),
      throwsA(isA<Exception>()),
    );
  });

  test('invalid stored key refuses to create database', () async {
    keys.value = 'unsafe-key';
    await expectLater(
      EncryptedLocalDatabase.open(path: path, keyStore: keys),
      throwsStateError,
    );
    expect(await File(path).exists(), isFalse);
  });
}
