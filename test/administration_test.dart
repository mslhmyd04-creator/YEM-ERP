import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:yem_erp/src/application/app_services.dart';
import 'package:yem_erp/src/application/local_auth_service.dart';
import 'package:yem_erp/src/data/local_migrations.dart';
import 'package:yem_erp/src/domain/password_hasher.dart';

import 'local_auth_test.dart' show TestHasher;

class PausedHasher extends TestHasher implements PasswordHasher {
  Completer<void>? pause;
  @override
  Future<String> hash(String password) async { if (pause != null) { await pause!.future; } return super.hash(password); }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Database db;
  late AppServices app;
  late PausedHasher hasher;
  late String company;
  late String branch;
  const password = 'LongPassword123!';
  setUp(() async {
    db = sqlite3.openInMemory(); db.execute('PRAGMA foreign_keys=ON'); await LocalMigrations.apply(db);
    hasher = PausedHasher(); app = AppServices(LocalAuthService(db, hasher));
    await app.auth.bootstrap(companyName: 'A', branchName: 'Main', username: 'admin', password: password);
    company = app.companies.single.id; branch = app.administration.repository.branches(company).single.id;
    await app.auth.login(companyId: company, username: 'admin', password: password);
  });
  tearDown(() => db.close());
  Future<String> createReader() async {
    final role = app.administration.saveRole(name: 'Reader', permissions: {'products.view'});
    return app.administration.saveUser(username: 'Reader', branchId: branch, roleIds: {role}, active: true, password: password);
  }
  test('creates limited user and enforces the assigned role', () async {
    await createReader();
    app.auth.logout(); await app.auth.login(companyId: company, username: 'reader', password: password);
    expect(app.auth.requirePermission('products.view').companyId, company);
    expect(() => app.administration.users(), throwsA(isA<AccessDenied>()));
    expect(() => app.auth.requirePermission('products.create'), throwsA(isA<AccessDenied>()));
  });
  test('last active administrator cannot be disabled or lose management permission', () async {
    final admin = app.administration.users().single;
    final role = app.administration.roles().single;
    await expectLater(app.administration.saveUser(id: admin.id, username: admin.username, branchId: branch,
      roleIds: admin.roleIds, active: false), throwsA(isA<AccessDenied>()));
    expect(app.administration.users().single.isActive, isTrue);
    expect(() => app.administration.saveRole(id: role.id, name: role.name, permissions: {'products.view'}), throwsA(isA<AccessDenied>()));
    expect(app.auth.hasPermission('administration.manage'), isTrue);
  });
  test('second administrator permits retirement of the first without reviving old session', () async {
    final original = app.administration.users().single;
    final managerRole = app.administration.roles().single.id;
    await app.administration.saveUser(username: 'second', branchId: branch, roleIds: {managerRole}, active: true, password: password);
    final oldSession = LocalAuthService(db, TestHasher());
    await oldSession.login(companyId: company, username: 'admin', password: password);
    await app.auth.login(companyId: company, username: 'second', password: password);
    await app.administration.saveUser(id: original.id, username: 'admin', branchId: branch, roleIds: original.roleIds, active: false);
    await app.administration.saveUser(id: original.id, username: 'admin', branchId: branch, roleIds: original.roleIds, active: true);
    expect(() => oldSession.requirePermission('products.view'), throwsA(isA<AccessDenied>()));
  });
  test('password reset invalidates prior sessions and rejects the old password', () async {
    final id = await createReader(); final reader = app.administration.users().firstWhere((u) => u.id == id);
    final old = LocalAuthService(db, TestHasher()); await old.login(companyId: company, username: 'reader', password: password);
    await app.administration.saveUser(id: id, username: 'reader', branchId: branch, roleIds: reader.roleIds, active: true, password: 'NewPassword123!');
    expect(() => old.requirePermission('products.view'), throwsA(isA<AccessDenied>()));
    await expectLater(old.login(companyId: company, username: 'reader', password: password), throwsA(isA<AccessDenied>()));
    await old.login(companyId: company, username: 'reader', password: 'NewPassword123!');
    expect(old.hasPermission('products.view'), isTrue);
    expect(db.select("SELECT action FROM audit_logs WHERE entity_id=? AND action='users.password_reset'", [id]), hasLength(1));
  });
  test('rejects foreign branches, roles and user IDs without leaking records', () async {
    db.execute("INSERT INTO companies(id,name,created_at) VALUES('b','B','date')");
    db.execute("INSERT INTO branches(id,company_id,name,created_at) VALUES('bb','b','Branch B','date')");
    db.execute("INSERT INTO roles(id,company_id,name) VALUES('rb','b','Private')");
    db.execute("INSERT INTO users(id,company_id,branch_id,username,password_hash,created_at) VALUES('ub','b','bb','private','hash','date')");
    final role = app.administration.roles().single.id;
    for (final input in [('bb', role, null), (branch, 'rb', null), (branch, role, 'ub')]) {
      await expectLater(app.administration.saveUser(id: input.$3, username: 'Cross', branchId: input.$1, roleIds: {input.$2}, active: true, password: password), throwsA(isA<AccessDenied>()));
    }
    expect(() => app.administration.saveRole(id: 'rb', name: 'Changed', permissions: {}), throwsA(isA<AccessDenied>()));
    expect(app.administration.users().map((u) => u.id), isNot(contains('ub')));
    expect(db.select("SELECT username FROM users WHERE id='ub'").single['username'], 'private');
  });
  test('failed audit rolls back role/user writes and permission changes', () async {
    final manager = app.administration.roles().single;
    db.execute("CREATE TRIGGER fail_admin_audit BEFORE INSERT ON audit_logs BEGIN SELECT RAISE(ABORT,'audit failure'); END");
    expect(() => app.administration.saveRole(id: manager.id, name: 'Changed', permissions: manager.permissions), throwsA(isA<SqliteException>()));
    await expectLater(app.administration.saveUser(username: 'New', branchId: branch, roleIds: {manager.id}, active: true, password: password), throwsA(isA<SqliteException>()));
    expect(app.administration.roles().single.name, manager.name); expect(app.administration.users(), hasLength(1));
  });
  test('permission revocation during hashing cancels the pending operation', () async {
    hasher.pause = Completer<void>();
    final role = app.administration.roles().single.id;
    final pending = app.administration.saveUser(username: 'Pending', branchId: branch, roleIds: {role}, active: true, password: password);
    final assertion = expectLater(pending, throwsA(isA<AccessDenied>()));
    db.execute("DELETE FROM role_permissions WHERE permission_code='administration.manage'");
    hasher.pause!.complete(); await assertion;
    expect(db.select("SELECT id FROM users WHERE username='pending'"), isEmpty);
  });
  test('version 4 migration preserves user data and upgrades only bootstrap manager', () async {
    final old = sqlite3.openInMemory();
    try {
      old.execute('PRAGMA foreign_keys=ON');
      for (final asset in LocalMigrations.assets.take(4)) { old.execute(await rootBundle.loadString(asset)); }
      old.execute('PRAGMA user_version=4');
      final auth = LocalAuthService(old, TestHasher());
      await auth.bootstrap(companyName: 'Legacy', branchName: 'Main', username: 'admin', password: password);
      old.execute("DELETE FROM role_permissions WHERE permission_code='administration.manage'");
      old.execute("DELETE FROM permissions WHERE code='administration.manage'");
      await LocalMigrations.apply(old); await LocalMigrations.apply(old);
      expect(old.select('SELECT auth_revision,password_hash FROM users').single['auth_revision'], 0);
      expect(old.select('SELECT password_hash FROM users').single['password_hash'], 'test:$password');
      expect(old.select("SELECT 1 FROM role_permissions WHERE permission_code='administration.manage'"), hasLength(1));
    } finally { old.close(); }
  });
}
