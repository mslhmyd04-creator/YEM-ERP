import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:yem_erp/src/application/app_services.dart';
import 'package:yem_erp/src/application/local_auth_service.dart';
import 'package:yem_erp/src/data/local_migrations.dart';
import 'package:yem_erp/src/domain/identifiers.dart';
import 'package:yem_erp/src/domain/money.dart';
import 'package:yem_erp/src/domain/journal.dart';
import 'local_auth_test.dart' show TestHasher;

void main(){
  TestWidgetsFlutterBinding.ensureInitialized();
  late Database db;late AppServices app;late String company,branch,cash,equity,employee,category;
  const password='LongPassword123!';
  setUp(()async{
    db=sqlite3.openInMemory();db.execute('PRAGMA foreign_keys=ON');await LocalMigrations.apply(db);
    app=AppServices(LocalAuthService(db,TestHasher()));
    await app.auth.bootstrap(companyName:'A',branchName:'Main',username:'admin',password:password);
    company=app.companies.single.id;await app.auth.login(companyId:company,username:'admin',password:password);
    app.finance.configureDefaults();branch=app.finance.branches().single.id;employee=app.finance.employees().single.id;
    cash=app.finance.cashAccounts().single.id;equity=app.finance.equityAccounts().single.id;category=app.finance.categories().first.id;
  });
  tearDown(()=>db.close());
  void fund()=>app.finance.opening(id:newUuid(),branch:branch,cash:cash,equity:equity,amount:Money(100000),date:'2026-10-05',description:'Capital');
  String issue({String? id,int amount=30000,String? user})=>app.finance.issue(id:id??newUuid(),branch:branch,cash:cash,employee:user??employee,amount:Money(amount),date:'2026-10-05',description:'Daily custody');
  String spend({String? id,String? custody,int amount=5000,String? selectedCategory})=>app.finance.expense(id:id??newUuid(),branch:branch,category:selectedCategory??category,cash:custody==null?cash:null,custody:custody,amount:Money(amount),date:'2026-10-05',description:'Fuel');
  test('configuration resumes without duplicates and balances derive from journals',(){
    final audits=db.select('SELECT count(*) AS n FROM audit_logs').single['n'];app.finance.configureDefaults();
    expect(app.posting.accounts(),hasLength(3));expect(app.finance.categories(),hasLength(14));
    expect(db.select('SELECT count(*) AS n FROM audit_logs').single['n'],audits);
    fund();final custody=issue();spend(custody:custody);spend(amount:10000);
    expect(app.posting.balance(cash),BigInt.from(60000));expect(app.finance.custodyBalance(custody),BigInt.from(25000));
    expect(app.finance.expenses(),hasLength(2));expect(app.finance.custodies(),hasLength(1));expect(app.posting.entries(),hasLength(4));
    final movement=db.select("SELECT balance_before_minor,balance_after_minor FROM custody_ledger WHERE movement_type='expense'").single;
    expect(movement['balance_before_minor'],30000);expect(movement['balance_after_minor'],25000);
    expect(db.select('PRAGMA foreign_key_check'),isEmpty);
  });
  test('insufficient funds never create documents accounts or ledger rows',(){
    expect(()=>issue(),throwsA(isA<AccessDenied>()));expect(app.posting.accounts(),hasLength(3));
    fund();final custody=issue();expect(()=>spend(custody:custody,amount:30001),throwsA(isA<AccessDenied>()));
    expect(()=>spend(amount:70001),throwsA(isA<AccessDenied>()));expect(()=>issue(amount:70001),throwsA(isA<AccessDenied>()));
    expect(app.finance.expenses(),isEmpty);expect(app.posting.entries(),hasLength(2));expect(app.posting.accounts(),hasLength(4));
    expect(app.finance.custodyBalance(custody),BigInt.from(30000));
  });
  test('business write failure rolls back posted journal and all numbering',(){
    fund();final custody=issue();
    db.execute("CREATE TRIGGER fail_expense BEFORE INSERT ON expenses BEGIN SELECT RAISE(ABORT,'document failure'); END");
    final id=newUuid();expect(()=>spend(id:id,custody:custody),throwsA(isA<SqliteException>()));
    expect(app.posting.entries(),hasLength(2));expect(app.finance.expenses(),isEmpty);expect(app.finance.custodyBalance(custody),BigInt.from(30000));
    expect(db.select("SELECT 1 FROM document_sequences WHERE kind='expense'"),isEmpty);expect(db.select('SELECT 1 FROM custody_ledger'),hasLength(1));
    db.execute('DROP TRIGGER fail_expense');spend(id:id,custody:custody);
    expect(app.finance.expenses().single.number,'EX-00000001');expect(app.posting.entries().map((r)=>r.number),contains('JE-00000003'));
  });
  test('custody audit failure rolls back new account document and movement',(){
    fund();db.execute("CREATE TRIGGER fail_custody_audit BEFORE INSERT ON audit_logs WHEN NEW.action='custody.issue' BEGIN SELECT RAISE(ABORT,'audit failure'); END");
    expect(()=>issue(),throwsA(isA<SqliteException>()));expect(app.finance.custodies(),isEmpty);expect(app.posting.accounts(),hasLength(3));
    expect(app.posting.entries(),hasLength(1));expect(app.posting.balance(cash),BigInt.from(100000));expect(db.select('SELECT 1 FROM custody_ledger'),isEmpty);
  });
  test('retries preserve records and compare complete category/source payload',(){
    fund();final custodyId=newUuid();issue(id:custodyId);issue(id:custodyId);
    final expenseId=newUuid();spend(id:expenseId,custody:custodyId);spend(id:expenseId,custody:custodyId);
    final other=app.finance.categories().firstWhere((c)=>c.id!=category).id;
    expect(()=>spend(id:expenseId,custody:custodyId,selectedCategory:other),throwsA(isA<AccessDenied>()));
    expect(()=>spend(id:expenseId),throwsA(isA<AccessDenied>()));
    expect(app.posting.entries(),hasLength(3));expect(app.finance.expenses(),hasLength(1));expect(app.finance.custodies(),hasLength(1));
    expect(db.select('SELECT 1 FROM custody_ledger'),hasLength(2));expect(app.finance.custodyBalance(custodyId),BigInt.from(25000));
  });
  test('financial operator cannot configure accounts or insert opening balance',()async{
    fund();final role=app.administration.saveRole(name:'Operator',permissions:{'finance.view','finance.post'});
    await app.administration.saveUser(username:'operator',branchId:branch,roleIds:{role},active:true,password:password);
    app.auth.logout();await app.auth.login(companyId:company,username:'operator',password:password);
    expect(()=>app.finance.configureDefaults(),throwsA(isA<AccessDenied>()));expect(()=>fund(),throwsA(isA<AccessDenied>()));
    spend();expect(app.finance.expenses(),hasLength(1));
  });
  test('foreign employee category and custody references are rejected',()async{
    fund();
    db.execute("INSERT INTO companies(id,name,created_at) VALUES('b','B','date')");db.execute("INSERT INTO branches(id,company_id,name,created_at) VALUES('bb','b','B','date')");
    db.execute("INSERT INTO users(id,company_id,branch_id,username,password_hash,created_at) VALUES('ub','b','bb','admin',?,'date')",['test:$password']);
    db.execute("INSERT INTO roles(id,company_id,name) VALUES('rb','b','Manager')");
    for(final permission in ['administration.manage','finance.view','finance.post']){db.execute("INSERT INTO role_permissions VALUES('rb',?)",[permission]);}
    db.execute("INSERT INTO user_roles VALUES('ub','rb','b')");
    final other=AppServices(LocalAuthService(db,TestHasher()));await other.auth.login(companyId:'b',username:'admin',password:password);other.finance.configureDefaults();
    final otherCash=other.finance.cashAccounts().single.id;other.finance.opening(id:newUuid(),branch:'bb',cash:otherCash,equity:other.finance.equityAccounts().single.id,amount:Money(10000),date:'2026-10-05',description:'Capital');
    final otherCustody=other.finance.issue(id:newUuid(),branch:'bb',cash:otherCash,employee:'ub',amount:Money(1000),date:'2026-10-05',description:'Private');
    expect(()=>issue(user:'ub'),throwsA(isA<AccessDenied>()));expect(()=>spend(selectedCategory:other.finance.categories().first.id),throwsA(isA<AccessDenied>()));
    expect(()=>spend(custody:otherCustody),throwsA(isA<AccessDenied>()));expect(()=>app.finance.custodyBalance(otherCustody),throwsA(isA<AccessDenied>()));
    expect(app.finance.custodies(),isEmpty);expect(app.finance.expenses(),isEmpty);expect(app.posting.entries(),hasLength(1));expect(app.finance.employees().map((u)=>u.id),isNot(contains('ub')));
  });
  test('version 6 upgrade preserves posted balances and retry identity',()async{
    final old=sqlite3.openInMemory();
    try{
      old.execute('PRAGMA foreign_keys=ON');
      for(final asset in LocalMigrations.assets.take(6)){old.execute(await rootBundle.loadString(asset));}
      old.execute('PRAGMA user_version=6');
      final legacy=AppServices(LocalAuthService(old,TestHasher()));
      await legacy.auth.bootstrap(companyName:'Legacy',branchName:'Main',username:'admin',password:password);
      await legacy.auth.login(companyId:legacy.companies.single.id,username:'admin',password:password);
      final c=legacy.posting.createAccount(code:'cash',name:'Cash',kind:AccountKind.cash);
      final e=legacy.posting.createAccount(code:'equity',name:'Equity',kind:AccountKind.equity);
      final r=PostingRequest(reference:FinancialReference.openingBalance,referenceId:newUuid(),branchId:legacy.administration.branches().single.id,date:'2026-10-05',description:'Opening',lines:[JournalLine(accountId:c,debit:Money(10000),credit:Money(0)),JournalLine(accountId:e,debit:Money(0),credit:Money(10000))]);
      final id=legacy.posting.post(r);await LocalMigrations.apply(old);await LocalMigrations.apply(old);
      expect(legacy.posting.post(r),id);expect(legacy.posting.entries(),hasLength(1));expect(legacy.posting.balance(c),BigInt.from(10000));
      expect(legacy.finance.custodies(),isEmpty);expect(old.select('PRAGMA user_version').single.values.first,8);expect(old.select('PRAGMA foreign_key_check'),isEmpty);
    }finally{old.close();}
  });

}
