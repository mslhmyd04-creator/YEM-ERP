import '../data/product_repository.dart';
import '../domain/product.dart';
import 'local_auth_service.dart';

class ProductService {
  ProductService(this.auth, this.repository);
  final LocalAuthService auth;
  final ProductRepository repository;

  List<Product> list() {
    final session = auth.requirePermission('products.view');
    return repository.listForCompany(session.companyId);
  }

  Product create({required String unitId, required String name, required String sku}) {
    final session = auth.requirePermission('products.create');
    auth.db.execute('BEGIN IMMEDIATE');
    try {
      final product = repository.create(companyId: session.companyId, unitId: unitId, name: name, sku: sku);
      auth.audit(companyId: session.companyId, userId: session.userId, action: 'products.create', entity: 'products', recordId: product.id);
      auth.db.execute('COMMIT');
      return product;
    } catch (_) {
      auth.db.execute('ROLLBACK');
      rethrow;
    }
  }

  bool archive(String id) {
    final session = auth.requirePermission('products.archive');
    auth.db.execute('BEGIN IMMEDIATE');
    try {
      final changed = repository.archive(companyId: session.companyId, id: id);
      if (changed) auth.audit(companyId: session.companyId, userId: session.userId,
        action: 'products.archive', entity: 'products', recordId: id);
      auth.db.execute('COMMIT');
      return changed;
    } catch (_) {
      auth.db.execute('ROLLBACK');
      rethrow;
    }
  }
}
