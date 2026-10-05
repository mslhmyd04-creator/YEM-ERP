import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:yem_erp/src/application/app_services.dart';
import 'package:yem_erp/src/application/local_auth_service.dart';
import 'package:yem_erp/src/data/local_migrations.dart';
import 'package:yem_erp/src/domain/master_record.dart';

import 'local_auth_test.dart' show TestHasher;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Database db;
  late AppServices app;
  late String company;
  const password = 'LongPassword123!';
  setUp(() async {
    db = sqlite3.openInMemory();
    db.execute('PRAGMA foreign_keys=ON');
    await LocalMigrations.apply(db);
    app = AppServices(LocalAuthService(db, TestHasher()));
    await app.auth.bootstrap(companyName: 'A', branchName: 'Main', username: 'admin', password: password);
    company = app.companies.single.id;
    await app.auth.login(companyId: company, username: 'admin', password: password);
    db.execute("INSERT INTO companies(id,name,created_at) VALUES('b','B','date')");
    db.execute("INSERT INTO branches(id,company_id,name,created_at) VALUES('bb','b','Branch B','date')");
  });
  tearDown(() => db.close());

  test('all master data is created and edited with stable identity and audit', () {
    for (final kind in MasterKind.values) {
      final record = app.masterData.save(kind, name: ' Initial ', phone: kind.hasPhone ? '123' : null,
        branchId: kind == MasterKind.warehouse ? app.masterData.branches().last.id : null);
      final edited = app.masterData.save(kind, id: record.id, name: 'Updated', phone: kind.hasPhone ? '456' : null,
        branchId: record.branchId);
      expect(edited.id, record.id);
      expect(app.masterData.list(kind).where((row) => row.id == record.id).single.name, 'Updated');
      if (kind.hasPhone) { expect(app.masterData.list(kind).single.phone, '456'); }
      expect(db.select('SELECT action FROM audit_logs WHERE entity_id=?', [record.id]).map((row) => row['action']),
        ['${kind.table}.create', '${kind.table}.update']);
    }
  });
  test('renaming a branch preserves existing user and warehouse references', () {
    final branch = app.masterData.branches().single;
    final warehouse = app.masterData.save(MasterKind.warehouse, name: 'Existing warehouse', branchId: branch.id);
    app.masterData.save(MasterKind.branch, id: branch.id, name: 'Renamed branch');
    expect(db.select('SELECT branch_id FROM users WHERE company_id=?', [company]).single['branch_id'], branch.id);
    expect(app.masterData.list(MasterKind.warehouse).single.branchId, branch.id);
    expect(app.masterData.list(MasterKind.warehouse).single.id, warehouse.id);
    expect(app.masterData.branches().single.name, 'Renamed branch');
  });
  test('foreign company branches, records and categories are rejected', () {
    expect(() => app.masterData.save(MasterKind.warehouse, name: 'Cross', branchId: 'bb'), throwsA(isA<SqliteException>()));
    db.execute("INSERT INTO customers(id,company_id,name,created_at) VALUES('foreign','b','Private','date')");
    expect(app.masterData.list(MasterKind.customer), isEmpty);
    expect(() => app.masterData.save(MasterKind.customer, id: 'foreign', name: 'Changed'), throwsA(isA<AccessDenied>()));
    expect(db.select("SELECT name FROM customers WHERE id='foreign'").single['name'], 'Private');
    db.execute("INSERT INTO product_categories(id,company_id,name) VALUES('cat-b','b','Other')");
    expect(() => app.products.create(unitId: app.units.single.id, name: 'Product', sku: 'C1', categoryId: 'cat-b'),
      throwsA(isA<SqliteException>()));
    final category = app.masterData.save(MasterKind.category, name: 'Camera');
    final product = app.products.create(unitId: app.units.single.id, name: 'Product', sku: 'C1', categoryId: category.id);
    expect(app.products.list().single.categoryId, category.id);
    expect(product.categoryId, category.id);
  });
  test('revoked permissions and failing audit leave data unchanged', () {
    final customer = app.masterData.save(MasterKind.customer, name: 'Existing');
    db.execute("DELETE FROM role_permissions WHERE permission_code='customers.update'");
    expect(() => app.masterData.save(MasterKind.customer, id: customer.id, name: 'Forbidden'), throwsA(isA<AccessDenied>()));
    expect(app.masterData.list(MasterKind.customer).single.name, 'Existing');
    db.execute("CREATE TRIGGER fail_master_audit BEFORE INSERT ON audit_logs BEGIN SELECT RAISE(ABORT,'audit failure'); END");
    expect(() => app.masterData.save(MasterKind.supplier, name: 'Supplier'), throwsA(isA<SqliteException>()));
    expect(app.masterData.list(MasterKind.supplier), isEmpty);
    db.execute("DELETE FROM role_permissions WHERE permission_code='customers.view'");
    expect(() => app.masterData.list(MasterKind.customer), throwsA(isA<AccessDenied>()));
  });
  test('validation rejects blank names and missing branches', () {
    expect(() => app.masterData.save(MasterKind.customer, name: '  '), throwsA(isA<AccessDenied>()));
    expect(() => app.masterData.save(MasterKind.warehouse, name: 'Warehouse'), throwsA(isA<AccessDenied>()));
  });
  test('version 2 upgrade restores only bootstrap manager capabilities', () async {
    final old = sqlite3.openInMemory();
    try {
      old.execute('PRAGMA foreign_keys=ON');
      for (final asset in LocalMigrations.assets.take(2)) { old.execute(await rootBundle.loadString(asset)); }
      old.execute('PRAGMA user_version=2');
      final auth = LocalAuthService(old, TestHasher());
      await auth.bootstrap(companyName: 'Legacy', branchName: 'Main', username: 'admin', password: password);
      old.execute("DELETE FROM role_permissions WHERE permission_code NOT LIKE 'products.%'");
      old.execute("DELETE FROM permissions WHERE code NOT LIKE 'products.%'");
      final user = old.select('SELECT id,company_id FROM users').single;
      old.execute("INSERT INTO roles(id,company_id,name) VALUES('reader',?,'reader')", [user['company_id']]);
      old.execute("INSERT INTO user_roles(user_id,role_id,company_id) VALUES(?,'reader',?)", [user['id'], user['company_id']]);
      await LocalMigrations.apply(old);
      await LocalMigrations.apply(old);
      expect(old.select("SELECT permission_code FROM role_permissions WHERE role_id='reader'"), isEmpty);
      expect(old.select('SELECT count(*) AS n FROM role_permissions').single['n'], 26);
      expect(old.select('SELECT password_hash FROM users').single['password_hash'], 'test:$password');
    } finally { old.close(); }
  });
}
