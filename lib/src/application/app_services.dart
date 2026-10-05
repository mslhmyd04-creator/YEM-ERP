import 'package:sqlite3/sqlite3.dart';

import '../data/product_repository.dart';
import '../data/master_repository.dart';
import 'master_data_service.dart';
import 'administration_service.dart';
import 'posting_engine.dart';
import 'financial_service.dart';
import 'inventory_engine.dart';
import 'sales_service.dart';
import '../data/sales_repository.dart';
import '../data/financial_repository.dart';
import '../data/journal_repository.dart';
import '../data/administration_repository.dart';
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
    masterData = MasterDataService(auth, MasterRepository(auth.db));
    administration = AdministrationService(auth, AdministrationRepository(auth.db));
    posting = PostingEngine(auth, JournalRepository(auth.db));
    finance = FinancialService(auth, posting, FinancialRepository(auth.db));
    final salesRepository=SalesRepository(auth.db);
    inventory=InventoryEngine(auth,posting,salesRepository);
    sales=SalesService(auth,posting,finance,inventory,salesRepository);
  }
  final LocalAuthService auth;
  late final ProductService products;
  late final MasterDataService masterData;
  late final AdministrationService administration;
  late final PostingEngine posting;
  late final FinancialService finance;
  late final InventoryEngine inventory;
  late final SalesService sales;
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
  List<NamedRecord> get categories {
    final session = auth.requirePermission('products.view');
    return _names(auth.db.select('SELECT id,name FROM product_categories WHERE company_id=? ORDER BY name', [session.companyId]));
  }
  static List<NamedRecord> _names(ResultSet rows) => rows.map((row) => NamedRecord(row['id'] as String, row['name'] as String)).toList();
  void close() => _close?.call();
}
