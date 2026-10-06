import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:yem_erp/src/application/app_services.dart';
import 'package:yem_erp/src/application/local_auth_service.dart';
import 'package:yem_erp/src/data/local_migrations.dart';
import 'package:yem_erp/src/domain/financial_document.dart';
import 'package:yem_erp/src/presentation/finance_page.dart';
import 'administration_widget_test.dart' show tapVisible,field,settle;
import 'local_auth_test.dart' show TestHasher;

void main(){
  TestWidgetsFlutterBinding.ensureInitialized();late Database db;late AppServices app;
  setUp(()async{
    db=sqlite3.openInMemory();db.execute('PRAGMA foreign_keys=ON');await LocalMigrations.apply(db);app=AppServices(LocalAuthService(db,TestHasher()));
    await app.auth.bootstrap(companyName:'A',branchName:'Main',username:'admin',password:'LongPassword123!');await app.auth.login(companyId:app.companies.single.id,username:'admin',password:'LongPassword123!');
  });
  tearDown(()=>db.close());
  testWidgets('Arabic forms fund cash issue custody and record custody expense',(tester)async{
    await tester.pumpWidget(MaterialApp(home:FinancePage(services:app)));await settle(tester);
    await tapVisible(tester,find.widgetWithText(FilledButton,'إعداد الحسابات والفئات'));
    Future<void> mode(String label)async{
      await tapVisible(tester,find.byType(DropdownButtonFormField<FinanceForm>));await tester.tap(find.text(label).last);await settle(tester);
    }
    Future<void> save(String value,String description)async{
      await field(tester,'المبلغ (YER)',value);await field(tester,'الوصف',description);await tapVisible(tester,find.widgetWithText(FilledButton,'حفظ وترحيل'));
      expect(find.text('تم الحفظ.'),findsOneWidget);
    }
    await mode('رصيد افتتاحي للصندوق');await save('1000','Capital');
    await mode('عهدة جديدة');await save('300','Daily custody');expect(app.finance.custodies(),hasLength(1));
    await mode('مصروف');await tapVisible(tester,find.byType(DropdownButtonFormField<bool>));await tester.tap(find.text('العهدة').last);await settle(tester);
    await save('50','Fuel');expect(app.finance.expenses(),hasLength(1));
    expect(app.finance.custodyBalance(app.finance.custodies().single.id),BigInt.from(25000));expect(app.posting.balance(app.finance.cashAccounts().single.id),BigInt.from(70000));
    expect(find.textContaining('المتبقي 250.00'),findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
