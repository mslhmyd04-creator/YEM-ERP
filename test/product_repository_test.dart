import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:yem_erp/src/data/product_repository.dart';
import 'package:yem_erp/src/infrastructure/local_database.dart';

class _Keys implements DatabaseKeyStore {
  String? value;
  @override
  Future<String?> read() async => value;
  @override
  Future<void> write(String hexKey) async => value = hexKey;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory temp;
  late EncryptedLocalDatabase local;
  late ProductRepository products;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('yem_erp_products_');
    local = await EncryptedLocalDatabase.open(
      path: '${temp.path}${Platform.pathSeparator}catalog.db',
      keyStore: _Keys(),
    );
    products = ProductRepository(local.connection);
    for (final tenant in ['a', 'b']) {
      local.connection.execute(
        'INSERT INTO companies(id,name,created_at) VALUES(?,?,?)',
        [tenant, 'Company $tenant', '2026-09-28T00:00:00Z'],
      );
      local.connection.execute(
        'INSERT INTO units(id,company_id,name) VALUES(?,?,?)',
        ['unit-$tenant', tenant, 'Piece'],
      );
    }
  });

  tearDown(() async {
    local.close();
    await temp.delete(recursive: true);
  });

  test('creates UUID products and scopes catalog to the company', () {
    final a = products.create(companyId: 'a', unitId: 'unit-a', name: ' كاميرا ', sku: ' C1 ');
    products.create(companyId: 'b', unitId: 'unit-b', name: 'Camera B', sku: 'C1');
    expect(a.id, matches(RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$')));
    expect(products.listForCompany('a').single.name, 'كاميرا');
    expect(products.listForCompany('a').single.sku, 'C1');
    expect(products.listForCompany('b').single.name, 'Camera B');
  });

  test('rejects duplicate SKU and a unit from another company', () {
    products.create(companyId: 'a', unitId: 'unit-a', name: 'One', sku: 'C1');
    expect(
      () => products.create(companyId: 'a', unitId: 'unit-a', name: 'Two', sku: 'C1'),
      throwsA(isA<SqliteException>()),
    );
    expect(
      () => products.create(companyId: 'a', unitId: 'unit-b', name: 'Cross', sku: 'C2'),
      throwsA(isA<SqliteException>()),
    );
  });

  test('archive changes only a product owned by the company', () {
    final item = products.create(companyId: 'a', unitId: 'unit-a', name: 'Camera', sku: 'C1');
    expect(products.archive(companyId: 'b', id: item.id), isFalse);
    expect(products.archive(companyId: 'a', id: item.id), isTrue);
    expect(products.listForCompany('a'), isEmpty);
    expect(products.listForCompany('a', includeArchived: true).single.isActive, isFalse);
  });
}
