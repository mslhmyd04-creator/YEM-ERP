import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:yem_erp/src/application/app_services.dart';
import 'package:yem_erp/src/application/local_auth_service.dart';
import 'package:yem_erp/src/data/local_migrations.dart';
import 'package:yem_erp/src/domain/identifiers.dart';
import 'package:yem_erp/src/domain/journal.dart';
import 'package:yem_erp/src/domain/money.dart';
import 'package:yem_erp/src/domain/sales_invoice.dart';
import 'local_auth_test.dart' show TestHasher;

void main(){
  TestWidgetsFlutterBinding.ensureInitialized();
  late Database db;late AppServices app;late String company,branch,product,service,warehouse,customer,cash;
  const password='LongPassword123!';
  setUp(()async{
    db=sqlite3.openInMemory();db.execute('PRAGMA foreign_keys=ON');await LocalMigrations.apply(db);
    app=AppServices(LocalAuthService(db,TestHasher()));await app.auth.bootstrap(companyName:'مؤسسة يمن',branchName:'الرئيسي',username:'admin',password:password);
    company=app.companies.single.id;await app.auth.login(companyId:company,username:'admin',password:password);
    app.sales.configureDefaults();branch=app.sales.branches().single.id;cash=app.sales.cashAccounts().single.id;
    product=newUuid();service=newUuid();warehouse=newUuid();customer=newUuid();
    final unit=app.units.single.id;
    for(final pair in [(product,1),(service,0)]){db.execute('INSERT INTO products(id,company_id,sku,name,unit_id,is_stock_item,created_at,updated_at) VALUES(?,?,?,?,?,?,?,?)',[pair.$1,company,pair.$1,pair.$2==1?'سلعة':'خدمة',unit,pair.$2,'date','date']);}
    db.execute('INSERT INTO warehouses(id,company_id,branch_id,name) VALUES(?,?,?,?)',[warehouse,company,branch,'المخزن']);
    db.execute('INSERT INTO customers(id,company_id,name,created_at) VALUES(?,?,?,?)',[customer,company,'عميل','date']);
  });
  tearDown(()=>db.close());
  String opening({String? id,int quantity=10,int cost=101})=>app.sales.opening(id:id??newUuid(),branch:branch,product:product,warehouse:warehouse,units:quantity,unitCost:Money(cost),date:'2026-10-05',description:'Stock capital');
  String sale({String? id,int quantity=3,int price=200,bool credit=false,String? selectedProduct,String? selectedWarehouse,String? selectedCustomer})=>app.sales.create(id:id??newUuid(),branch:branch,customer:selectedCustomer??customer,isCash:!credit,cash:credit?null:cash,date:'2026-10-05',description:'Sale',lines:[InvoiceLineDraft(productId:selectedProduct??product,warehouseId:selectedProduct==service?null:selectedWarehouse??warehouse,quantity:quantity,unitPrice:Money(price))]);
  int count(String table)=>db.select('SELECT count(*) AS n FROM $table').single['n'] as int;
  test('weighted average and full depletion preserve exact ledger values',(){
    opening(quantity:3,cost:101);opening(quantity:2,cost:102);
    final first=sale(quantity:2);expect(app.sales.invoice(first).items.single.costMinor,203);
    final balance=app.inventory.balance(product,warehouse);expect(balance.quantity,BigInt.from(3));expect(balance.value,BigInt.from(304));
    final last=sale(quantity:3,credit:true);expect(app.sales.invoice(last).items.single.costMinor,304);
    expect(app.inventory.balance(product,warehouse).quantity,BigInt.zero);expect(app.inventory.balance(product,warehouse).value,BigInt.zero);
    final accounts=app.posting.accounts();
    expect(app.posting.balance(accounts.singleWhere((a)=>a.kind==AccountKind.inventory).id),BigInt.zero);
    expect(app.posting.balance(accounts.singleWhere((a)=>a.kind==AccountKind.costOfSales).id),BigInt.from(507));
    expect(app.posting.balance(cash),BigInt.from(400));expect(app.posting.balance(accounts.singleWhere((a)=>a.kind==AccountKind.receivable).id),BigInt.from(600));
    expect(db.select('PRAGMA foreign_key_check'),isEmpty);
  });
  test('retries after later movements and renames keep original invoice snapshots',(){
    final start=newUuid();opening(id:start);opening(id:start);final id=newUuid();sale(id:id);opening(quantity:5,cost:500);
    db.execute("UPDATE products SET name='Renamed' WHERE id=?",[product]);db.execute("UPDATE customers SET name='Renamed customer' WHERE id=?",[customer]);
    sale(id:id);expect(app.sales.invoice(id).items.single.name,'سلعة');expect(app.sales.invoice(id).customerName,'عميل');
    expect(app.sales.invoices(),hasLength(1));expect(count('stock_ledger'),3);expect(app.posting.entries(),hasLength(3));
    expect(()=>sale(id:id,quantity:2,price:300),throwsA(isA<AccessDenied>()));
    expect(app.inventory.balance(product,warehouse).quantity,BigInt.from(12));
  });
  test('insufficient stock and invalid quantities create no partial journals',(){
    expect(()=>sale(),throwsA(isA<AccessDenied>()));opening(quantity:2);
    for(final qty in [0,3,1000000001]){expect(()=>sale(quantity:qty),throwsA(isA<AccessDenied>()));}
    expect(()=>sale(price:0),throwsA(isA<AccessDenied>()));expect(()=>opening(cost:0),throwsA(isA<AccessDenied>()));
    expect(app.sales.invoices(),isEmpty);expect(app.posting.entries(),hasLength(1));expect(count('stock_ledger'),1);
  });
  test('audit failure rolls back invoice stock journal and numbering',(){
    opening();final id=newUuid();
    db.execute("CREATE TRIGGER fail_sales BEFORE INSERT ON audit_logs WHEN NEW.action='sales.post' BEGIN SELECT RAISE(ABORT,'audit failure'); END");
    expect(()=>sale(id:id),throwsA(isA<SqliteException>()));expect(app.sales.invoices(),isEmpty);expect(app.posting.entries(),hasLength(1));expect(count('stock_ledger'),1);expect(count('sales_invoice_items'),0);
    expect(db.select("SELECT 1 FROM document_sequences WHERE kind='salesInvoice'"),isEmpty);
    db.execute('DROP TRIGGER fail_sales');sale(id:id);expect(app.sales.invoice(id).number,'SI-00000001');expect(app.posting.entries().map((e)=>e.number),contains('JE-00000002'));
  });
  test('stock persistence failure rolls back draft invoice and posted GL',(){
    opening();db.execute("CREATE TRIGGER fail_stock BEFORE INSERT ON stock_ledger WHEN NEW.movement_type='sale' BEGIN SELECT RAISE(ABORT,'stock failure'); END");
    expect(()=>sale(),throwsA(isA<SqliteException>()));expect(count('sales_invoices'),0);expect(count('sales_invoice_items'),0);expect(app.posting.entries(),hasLength(1));expect(app.inventory.balance(product,warehouse).quantity,BigInt.from(10));
  });
  test('services post revenue without stock or cost ledger',(){
    final id=sale(selectedProduct:service,quantity:2,price:1000);final record=app.sales.invoice(id);
    expect(record.totalMinor,2000);expect(record.items.single.costMinor,0);expect(count('stock_ledger'),0);
    expect(count('journal_entry_lines'),2);expect(app.posting.balance(cash),BigInt.from(2000));
    expect(()=>app.sales.create(id:newUuid(),branch:branch,customer:customer,isCash:true,cash:cash,date:'2026-10-05',description:'Bad service',lines:[InvoiceLineDraft(productId:service,warehouseId:warehouse,quantity:1,unitPrice:Money(100))]),throwsA(isA<AccessDenied>()));
  });
  test('branch tenant and archive checks reject inaccessible references',(){
    opening();final otherBranch=newUuid(),otherWarehouse=newUuid();
    db.execute("INSERT INTO branches(id,company_id,name,created_at) VALUES(?,?,?,'date')",[otherBranch,company,'Other']);
    db.execute('INSERT INTO warehouses(id,company_id,branch_id,name) VALUES(?,?,?,?)',[otherWarehouse,company,otherBranch,'Other']);
    expect(()=>sale(selectedWarehouse:otherWarehouse),throwsA(isA<AccessDenied>()));expect(()=>sale(selectedCustomer:'foreign'),throwsA(isA<AccessDenied>()));
    db.execute('UPDATE products SET is_active=0 WHERE id=?',[product]);expect(()=>sale(),throwsA(isA<AccessDenied>()));expect(app.sales.invoices(),isEmpty);
    expect(()=>app.sales.invoice('foreign'),throwsA(isA<AccessDenied>()));
  });
  test('sales clerk works without broad catalog finance or master read permissions',()async{
    opening();final role=app.administration.saveRole(name:'Clerk',permissions:{'sales.view','sales.create','finance.post'});
    await app.administration.saveUser(username:'clerk',branchId:branch,roleIds:{role},active:true,password:password);
    app.auth.logout();await app.auth.login(companyId:company,username:'clerk',password:password);
    sale();expect(app.sales.invoices(),hasLength(1));expect(app.sales.products(),hasLength(2));
    expect(()=>opening(),throwsA(isA<AccessDenied>()));expect(()=>app.sales.configureDefaults(),throwsA(isA<AccessDenied>()));
    db.execute("DELETE FROM role_permissions WHERE role_id=? AND permission_code='sales.create'",[role]);
    expect(()=>sale(),throwsA(isA<AccessDenied>()));expect(app.sales.invoices(),hasLength(1));
  });
  test('stock quote rechecks quantity and value under posting lock',(){
    opening();final before=app.inventory.balance(product,warehouse);opening(quantity:1,cost:200);
    expect(()=>app.inventory.recheck(company,product,warehouse,branch,before),throwsA(isA<AccessDenied>()));
    expect(app.inventory.cost(app.inventory.balance(product,warehouse),11),1210);
  });
  test('version 7 upgrade preserves account UUIDs balances and stocked product default',()async{
    final old=sqlite3.openInMemory();try{
      old.execute('PRAGMA foreign_keys=ON');for(final asset in LocalMigrations.assets.take(7)){old.execute(await rootBundle.loadString(asset));}old.execute('PRAGMA user_version=7');
      final legacy=AppServices(LocalAuthService(old,TestHasher()));await legacy.auth.bootstrap(companyName:'Legacy',branchName:'Main',username:'admin',password:password);await legacy.auth.login(companyId:legacy.companies.single.id,username:'admin',password:password);legacy.finance.configureDefaults();
      final account=legacy.finance.cashAccounts().single.id;final equity=legacy.finance.equityAccounts().single.id;final b=legacy.finance.branches().single.id;final cid=legacy.companies.single.id;
      legacy.finance.opening(id:newUuid(),branch:b,cash:account,equity:equity,amount:Money(10000),date:'2026-10-05',description:'Capital');
      old.execute("INSERT INTO products(id,company_id,sku,name,unit_id,created_at,updated_at) VALUES('old',?,'old','Old',?,'date','date')",[cid,legacy.units.single.id]);
      await LocalMigrations.apply(old);legacy.sales.configureDefaults();
      expect(legacy.posting.balance(account),BigInt.from(10000));expect(legacy.sales.products().single.isStockItem,isTrue);expect(old.select('PRAGMA foreign_key_check'),isEmpty);expect(legacy.posting.accounts().where((a)=>a.kind==AccountKind.inventory),hasLength(1));
      expect(legacy.auth.hasPermission('sales.create'),isTrue);
    }finally{old.close();}
  });
}
