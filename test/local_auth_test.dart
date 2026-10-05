import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:yem_erp/src/application/local_auth_service.dart';
import 'package:yem_erp/src/application/product_service.dart';
import 'package:yem_erp/src/data/local_migrations.dart';
import 'package:yem_erp/src/data/product_repository.dart';
import 'package:yem_erp/src/domain/password_hasher.dart';

// Deterministic test double only. Production uses Argon2PasswordHasher.
class TestHasher implements PasswordHasher {
  @override
  Future<String> hash(String password) async => 'test:$password';
  @override
  Future<bool> verify(String password, String encoded) async => encoded == 'test:$password';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Database db;
  late LocalAuthService auth;
  late DateTime now;
  late String company;
  const password = 'LongPassword123!';
  setUp(() async {
    db = sqlite3.openInMemory();
    db.execute('PRAGMA foreign_keys=ON');
    await LocalMigrations.apply(db);
    now = DateTime.utc(2026, 9, 30);
    auth = LocalAuthService(db, TestHasher(), clock: () => now);
    await auth.bootstrap(companyName: 'شركة', branchName: 'الرئيسي', username: 'Admin', password: password);
    company = db.select('SELECT id FROM companies').single['id'] as String;
  });
  tearDown(() => db.close());
  Future<void> login() => auth.login(companyId: company, username: 'ADMIN', password: password);

  test('bootstrap is atomic and cannot replace the first administrator', () async {
    expect(auth.needsSetup, isFalse);
    expect(db.select('SELECT password_hash FROM users').single['password_hash'], isNot(password));
    await expectLater(auth.bootstrap(companyName: 'other', branchName: 'b', username: 'x', password: password), throwsA(isA<AccessDenied>()));
    expect(db.select('SELECT count(*) AS n FROM companies').single['n'], 1);
    expect(db.select('SELECT count(*) AS n FROM role_permissions').single['n'], 24);
  });
  test('lockout persists across service instances and expires', () async {
    for (var i = 0; i < 5; i++) {
      await expectLater(auth.login(companyId: company, username: 'admin', password: 'wrong'), throwsA(isA<AccessDenied>()));
    }
    auth = LocalAuthService(db, TestHasher(), clock: () => now);
    await expectLater(login(), throwsA(isA<AccessDenied>()));
    now = now.add(const Duration(minutes: 15));
    await login();
    expect(auth.requirePermission('products.view').companyId, company);
    expect(db.select('SELECT failed_login_count FROM users').single['failed_login_count'], 0);
  });
  test('expiry, logout, disabled account and permission revocation block access', () async {
    await login();
    db.execute("DELETE FROM role_permissions WHERE permission_code='products.create'");
    expect(() => auth.requirePermission('products.create'), throwsA(isA<AccessDenied>()));
    now = now.add(const Duration(minutes: 30));
    expect(() => auth.requirePermission('products.view'), throwsA(isA<AccessDenied>()));
    await login();
    auth.logout();
    expect(() => auth.requirePermission('products.view'), throwsA(isA<AccessDenied>()));
    await login();
    db.execute('UPDATE users SET is_active=0');
    expect(() => auth.requirePermission('products.view'), throwsA(isA<AccessDenied>()));
  });
  test('product operations require permission and roll back when audit fails', () async {
    final products = ProductService(auth, ProductRepository(db));
    final unit = db.select('SELECT id FROM units').single['id'] as String;
    expect(() => products.create(unitId: unit, name: 'Camera', sku: 'C1'), throwsA(isA<AccessDenied>()));
    await login();
    final item = products.create(unitId: unit, name: 'Camera', sku: 'C1');
    expect(products.list().single.id, item.id);
    expect(products.archive(item.id), isTrue);
    expect(products.list(), isEmpty);
    db.execute("CREATE TRIGGER fail_audit BEFORE INSERT ON audit_logs BEGIN SELECT RAISE(ABORT,'audit unavailable'); END");
    expect(() => products.create(unitId: unit, name: 'Other', sku: 'C2'), throwsA(isA<SqliteException>()));
    expect(db.select("SELECT id FROM products WHERE sku='C2'"), isEmpty);
  });
}
