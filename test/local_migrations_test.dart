import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:yem_erp/src/data/local_migrations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Database db;
  setUp(() => db = sqlite3.openInMemory());
  tearDown(() => db.close());
  Future<void> versionOne() async {
    db.execute(await rootBundle.loadString(LocalMigrations.assets.first));
    db.execute('PRAGMA user_version=1');
    db.execute("INSERT INTO companies(id,name,created_at) VALUES('old','Existing','date')");
  }
  test('upgrade preserves existing records and runs once', () async {
    await versionOne();
    await LocalMigrations.apply(db);
    await LocalMigrations.apply(db);
    expect(db.select('SELECT name FROM companies').single['name'], 'Existing');
    expect(db.select('PRAGMA user_version').single.values.first, 6);
    expect(db.select('SELECT version FROM schema_migrations').length, 6);
  });
  test('failed upgrade rolls back DDL and keeps the old version', () async {
    await versionOne();
    await expectLater(LocalMigrations.apply(db, load: (_) async => 'ALTER TABLE users ADD COLUMN broken TEXT; INVALID SQL;'), throwsA(isA<SqliteException>()));
    expect(db.select('PRAGMA user_version').single.values.first, 1);
    expect(db.select('PRAGMA table_info(users)').where((row) => row['name'] == 'broken'), isEmpty);
    await LocalMigrations.apply(db);
  });
  test('rejects future schema and inconsistent history without changing data', () async {
    await versionOne();
    db.execute('PRAGMA user_version=7');
    await expectLater(LocalMigrations.apply(db), throwsStateError);
    db.execute('PRAGMA user_version=1');
    db.execute('DELETE FROM schema_migrations');
    await expectLater(LocalMigrations.apply(db), throwsStateError);
    expect(db.select('SELECT name FROM companies').single['name'], 'Existing');
  });
}
