import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:yem_erp/src/application/app_services.dart';
import 'package:yem_erp/src/application/local_auth_service.dart';
import 'package:yem_erp/src/data/local_migrations.dart';
import 'package:yem_erp/src/domain/identifiers.dart';
import 'package:yem_erp/src/domain/journal.dart';
import 'package:yem_erp/src/domain/money.dart';
import 'local_auth_test.dart' show TestHasher;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('money parses exact decimal and Arabic input and rejects precision/range loss', () {
    expect(Money.parse('٠٫١٠').minor + Money.parse('0.20').minor, 30);
    expect(Money.parse('12.3').toString(), '12.30');
    expect(Money.parse('90000000000000').minor, Money.maximumMinor);
    for (final value in ['-1','1.234','1e3','NaN','1,000','90000000000000.01','']) {
      expect(() => Money.parse(value), throwsFormatException);
    }
    expect(() => Money(-1), throwsArgumentError);
  });
  group('posting boundary', () {
    late Database db; late AppServices app; late String company, branch, cash, equity;
    const password = 'LongPassword123!';
    setUp(() async {
      db=sqlite3.openInMemory(); db.execute('PRAGMA foreign_keys=ON'); await LocalMigrations.apply(db);
      app=AppServices(LocalAuthService(db,TestHasher()));
      await app.auth.bootstrap(companyName: 'A',branchName: 'Main',username: 'admin',password: password);
      company=app.companies.single.id;
      await app.auth.login(companyId: company,username: 'admin',password: password);
      branch=app.administration.branches().single.id;
      cash=app.posting.createAccount(code: 'cash',name: 'Cash',kind: AccountKind.cash);
      equity=app.posting.createAccount(code: 'equity',name: 'Opening equity',kind: AccountKind.equity);
    });
    tearDown(() => db.close());
    PostingRequest request({String? ref, String? branchId, String? debitAccount, int amount=10000, int? credit, String date='2026-10-05'}) => PostingRequest(
      reference: FinancialReference.openingBalance,referenceId: ref??newUuid(),branchId: branchId??branch,date: date,description: 'Opening balance',
      lines: [JournalLine(accountId: debitAccount??cash,debit: Money(amount),credit: Money(0)),JournalLine(accountId: equity,debit: Money(0),credit: Money(credit??amount))]);
    test('posts exact balanced entry; retry with reordered lines does not duplicate', () {
      final r=request(); final id=app.posting.post(r);
      final reversed=PostingRequest(reference: r.reference,referenceId: r.referenceId,branchId: r.branchId,date: r.date,description: r.description,lines: r.lines.reversed.toList());
      expect(app.posting.post(reversed),id);
      expect(app.posting.entries(),hasLength(1)); expect(app.posting.entries().single.number,'JE-00000001');
      expect(app.posting.balance(cash),BigInt.from(10000)); expect(app.posting.balance(equity),BigInt.from(-10000));
      expect(db.select("SELECT 1 FROM audit_logs WHERE action='journal.post'"),hasLength(1));
      expect(() => app.posting.post(request(ref: r.referenceId,amount: 20000)),throwsA(isA<AccessDenied>()));
      app.posting.post(request(amount: 30)); expect(app.posting.entries().map((e)=>e.number),contains('JE-00000002'));
    });
    test('rejects imbalance, zero, invalid dates and total overflow before writes', () {
      for(final r in [request(credit: 99),request(amount: 0),request(date: '2026-02-31')]) {
        expect(()=>app.posting.post(r),throwsA(isA<AccessDenied>()));
      }
      final r=request(amount: Money.maximumMinor);
      expect(()=>app.posting.post(PostingRequest(reference: r.reference,referenceId: r.referenceId,branchId: branch,date: r.date,description: r.description,lines: [...r.lines,...r.lines])),throwsA(isA<AccessDenied>()));
      expect(app.posting.entries(),isEmpty); expect(db.select('SELECT 1 FROM document_sequences'),isEmpty);
    });
    test('rejects foreign branch/account and unsupported company currency', () {
      db.execute("INSERT INTO companies(id,name,created_at) VALUES('b','B','date')");
      db.execute("INSERT INTO branches(id,company_id,name,created_at) VALUES('bb','b','B','date')");
      db.execute("INSERT INTO accounts(id,company_id,code,name,kind,currency_code) VALUES('bc','b','cash','Private','cash','YER')");
      expect(()=>app.posting.post(request(branchId: 'bb')),throwsA(isA<AccessDenied>()));
      expect(()=>app.posting.post(request(debitAccount: 'bc')),throwsA(isA<AccessDenied>()));
      expect(()=>app.posting.balance('bc'),throwsA(isA<AccessDenied>()));
      expect(app.posting.accounts().map((a)=>a.id),isNot(contains('bc')));
      db.execute("UPDATE companies SET currency_code='USD' WHERE id=?",[company]);
      expect(()=>app.posting.post(request()),throwsA(isA<AccessDenied>()));
      expect(app.posting.entries(),isEmpty);
    });
    test('view-only role cannot post or configure accounts', () async {
      final role=app.administration.saveRole(name: 'Finance reader',permissions: {'finance.view'});
      await app.administration.saveUser(username: 'reader',branchId: branch,roleIds: {role},active: true,password: password);
      app.auth.logout(); await app.auth.login(companyId: company,username: 'reader',password: password);
      expect(app.posting.accounts(),hasLength(2)); expect(app.posting.entries(),isEmpty);
      expect(()=>app.posting.post(request()),throwsA(isA<AccessDenied>()));
      expect(()=>app.posting.createAccount(code: 'x',name: 'X',kind: AccountKind.cash),throwsA(isA<AccessDenied>()));
    });
    test('audit failure rolls back header, lines and document sequence', () {
      db.execute("CREATE TRIGGER fail_post_audit BEFORE INSERT ON audit_logs WHEN NEW.action='journal.post' BEGIN SELECT RAISE(ABORT,'audit failed'); END");
      final r=request(); expect(()=>app.posting.post(r),throwsA(isA<SqliteException>()));
      expect(db.select('SELECT 1 FROM journal_entries'),isEmpty); expect(db.select('SELECT 1 FROM journal_entry_lines'),isEmpty);
      expect(db.select('SELECT 1 FROM document_sequences'),isEmpty);
      db.execute('DROP TRIGGER fail_post_audit'); app.posting.post(r);
      expect(app.posting.entries().single.number,'JE-00000001');
    });
    test('posted headers and lines are immutable at database boundary', () {
      final id=app.posting.post(request());
      for(final sql in ["UPDATE journal_entries SET description='Changed' WHERE id='$id'", "DELETE FROM journal_entries WHERE id='$id'",
        "UPDATE journal_entry_lines SET debit_minor=9 WHERE entry_id='$id'", "DELETE FROM journal_entry_lines WHERE entry_id='$id'",
        "INSERT INTO journal_entry_lines(entry_id,line_number,company_id,currency_code,account_id,debit_minor,credit_minor) VALUES('$id',2,'$company','YER','$cash',1,0)"]) {
        expect(()=>db.execute(sql),throwsA(isA<SqliteException>()));
      }
      expect(app.posting.balance(cash),BigInt.from(10000));
      expect(db.select('PRAGMA foreign_key_check'),isEmpty);
    });
    test('migration upgrades renamed bootstrap manager without promoting reader', () async {
      final old=sqlite3.openInMemory();
      try {
        old.execute('PRAGMA foreign_keys=ON');
        for(final asset in LocalMigrations.assets.take(5)){old.execute(await rootBundle.loadString(asset));}
        old.execute('PRAGMA user_version=5');
        final auth=LocalAuthService(old,TestHasher()); await auth.bootstrap(companyName: 'Legacy',branchName: 'Main',username: 'admin',password: password);
        final user=old.select('SELECT id,company_id FROM users').single;
        old.execute("DELETE FROM role_permissions WHERE permission_code LIKE 'finance.%'");
        old.execute("DELETE FROM permissions WHERE code LIKE 'finance.%'");
        old.execute("UPDATE roles SET name='Renamed manager'");
        old.execute("INSERT INTO roles(id,company_id,name) VALUES('reader',?,'Reader')",[user['company_id']]);
        old.execute("INSERT INTO user_roles(user_id,role_id,company_id) VALUES(?,'reader',?)",[user['id'],user['company_id']]);
        await LocalMigrations.apply(old); await LocalMigrations.apply(old);
        expect(old.select("SELECT 1 FROM role_permissions WHERE permission_code LIKE 'finance.%'"),hasLength(2));
        expect(old.select("SELECT 1 FROM role_permissions WHERE role_id='reader'"),isEmpty);
        expect(old.select('PRAGMA user_version').single.values.first,6);
        expect(old.select('SELECT password_hash FROM users').single['password_hash'],'test:$password');
      } finally {old.close();}
    });
  });
}
