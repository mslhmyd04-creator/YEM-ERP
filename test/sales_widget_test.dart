import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:yem_erp/src/application/app_services.dart';
import 'package:yem_erp/src/application/local_auth_service.dart';
import 'package:yem_erp/src/data/local_migrations.dart';
import 'package:yem_erp/src/domain/sales_invoice.dart';
import 'package:yem_erp/src/presentation/sales_page.dart';
import 'administration_widget_test.dart' show tapVisible,field,settle;
import 'local_auth_test.dart' show TestHasher;

void main(){
  TestWidgetsFlutterBinding.ensureInitialized();late Database db;late AppServices app;late String product,warehouse;
  setUp(()async{
    db=sqlite3.openInMemory();db.execute('PRAGMA foreign_keys=ON');await LocalMigrations.apply(db);app=AppServices(LocalAuthService(db,TestHasher()));
    await app.auth.bootstrap(companyName:'مؤسسة',branchName:'الرئيسي',username:'admin',password:'LongPassword123!');final company=app.companies.single.id;await app.auth.login(companyId:company,username:'admin',password:'LongPassword123!');
    final branch=app.administration.branches().single.id;
    product=app.products.create(unitId:app.units.single.id,name:'سلعة',sku:'A').id;warehouse='warehouse';
    db.execute('INSERT INTO warehouses(id,company_id,branch_id,name) VALUES(?,?,?,?)',[warehouse,company,branch,'المخزن']);db.execute("INSERT INTO customers(id,company_id,name,created_at) VALUES('customer',?,'عميل','date')",[company]);
  });
  tearDown(()=>db.close());
  testWidgets('Arabic stock opening and cash invoice forms change real ledgers',(tester)async{
    await tester.pumpWidget(MaterialApp(home:SalesPage(services:app)));await settle(tester);
    await tapVisible(tester,find.widgetWithText(OutlinedButton,'إعداد حسابات المبيعات'));
    Future<void> mode(String label)async{await tapVisible(tester,find.byType(DropdownButtonFormField<SalesForm>));await tester.tap(find.text(label).last);await settle(tester);}
    await mode('رصيد مخزني افتتاحي');await field(tester,'الكمية (وحدات كاملة)','10');await field(tester,'تكلفة الوحدة (YER)','5');await field(tester,'الوصف','Opening');await tapVisible(tester,find.widgetWithText(FilledButton,'حفظ وترحيل'));
    expect(app.inventory.balance(product,warehouse).quantity,BigInt.from(10));
    await mode('فاتورة بيع');await field(tester,'الكمية (وحدات كاملة)','3');await field(tester,'سعر الوحدة (YER)','8');await field(tester,'الوصف','Sale');await tapVisible(tester,find.widgetWithText(OutlinedButton,'إضافة بند'));await tapVisible(tester,find.widgetWithText(FilledButton,'حفظ وترحيل'));
    expect(find.text('تم الحفظ.'),findsOneWidget);expect(app.sales.invoices().single.totalMinor,2400);expect(app.sales.invoices().single.items.single.costMinor,1500);expect(app.inventory.balance(product,warehouse).quantity,BigInt.from(7));expect(app.posting.balance(app.sales.cashAccounts().single.id),BigInt.from(2400));
    await tester.pumpWidget(const SizedBox());
  });
}
