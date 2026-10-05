import 'package:sqlite3/sqlite3.dart';

import '../domain/product.dart';
import '../domain/identifiers.dart';

/// Local catalog persistence. Stock quantities belong to the stock ledger.
/// Application services will enforce permissions before calling this adapter.
class ProductRepository {
  ProductRepository(this._db);

  final Database _db;

  Product create({
    required String companyId,
    required String unitId,
    required String name,
    required String sku,
    String? categoryId,
  }) {
    final id = newUuid();
    final product = Product(
      id: id,
      companyId: companyId,
      unitId: unitId,
      name: name.trim(),
      sku: sku.trim(),
      isActive: true,
      categoryId: categoryId,
    );
    final now = DateTime.now().toUtc().toIso8601String();
    _db.execute(
      'INSERT INTO products(id, company_id, unit_id, name, sku, category_id, created_at, updated_at) '
      'VALUES(?,?,?,?,?,?,?,?)',
      [product.id, product.companyId, product.unitId, product.name, product.sku, product.categoryId, now, now],
    );
    return product;
  }

  List<Product> listForCompany(String companyId, {bool includeArchived = false}) {
    if (companyId.trim().isEmpty) throw ArgumentError.value(companyId, 'companyId');
    final rows = _db.select(
      'SELECT id, company_id, unit_id, name, sku, is_active, category_id FROM products '
      'WHERE company_id = ? ${includeArchived ? '' : 'AND is_active = 1'} ORDER BY name, id',
      [companyId],
    );
    return rows.map(_fromRow).toList(growable: false);
  }

  /// Returns false if the product does not belong to this company.
  bool archive({required String companyId, required String id}) {
    if (companyId.trim().isEmpty || id.trim().isEmpty) throw ArgumentError('Identity is required.');
    _db.execute(
      'UPDATE products SET is_active = 0, updated_at = ? WHERE id = ? AND company_id = ? AND is_active = 1',
      [DateTime.now().toUtc().toIso8601String(), id, companyId],
    );
    return _db.select('SELECT changes() AS count').single['count'] == 1;
  }

  static Product _fromRow(Row row) => Product(
        id: row['id'] as String,
        companyId: row['company_id'] as String,
        unitId: row['unit_id'] as String,
        name: row['name'] as String,
        sku: row['sku'] as String,
        isActive: row['is_active'] == 1,
        categoryId: row['category_id'] as String?,
      );

}
