import 'package:sqlite3/sqlite3.dart';

import '../data/product_repository.dart';
import '../infrastructure/argon2_password_hasher.dart';
import '../infrastructure/local_database.dart';
import 'local_auth_service.dart';
import 'product_service.dart';

class NamedRecord {
  const NamedRecord(this.id, this.name);
  final String id;
  final String name;
}

class AppServices {
  AppServices(this.auth, {void Function()? close}) : _close = close {
    products = ProductService(auth, ProductRepository(auth.db));
  }
  final LocalAuthService auth;
  late final ProductService products;
  final void Function()? _close;

  static Future<AppServices> open() async {
    final local = await EncryptedLocalDatabase.openApp();
    return AppServices(LocalAuthService(local.connection, Argon2PasswordHasher()), close: local.close);
  }

  List<NamedRecord> get companies => _names(auth.db.select('SELECT id,name FROM companies ORDER BY name'));
  List<NamedRecord> get units {
    final session = auth.requirePermission('products.view');
    return _names(auth.db.select('SELECT id,name FROM units WHERE company_id=? ORDER BY name', [session.companyId]));
  }
  static List<NamedRecord> _names(ResultSet rows) => rows.map((row) => NamedRecord(row['id'] as String, row['name'] as String)).toList();
  void close() => _close?.call();
}
