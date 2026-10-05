import 'package:sqlite3/sqlite3.dart';
import '../domain/journal.dart';

class JournalRepository {
  JournalRepository(this.db);
  final Database db;
  List<LedgerAccount> accounts(String company) => db.select('SELECT id,code,name,kind FROM accounts WHERE company_id=? ORDER BY code', [company])
    .map((r) => LedgerAccount(r['id'] as String, r['code'] as String, r['name'] as String, AccountKind.values.byName(r['kind'] as String))).toList();
  bool ownsBranch(String company, String branch) => db.select('SELECT 1 FROM branches WHERE id=? AND company_id=?', [branch,company]).isNotEmpty;
  bool ownsAccount(String company, String id) => db.select("SELECT 1 FROM accounts WHERE id=? AND company_id=? AND currency_code='YER'", [id,company]).isNotEmpty;
  String currency(String company) => db.select('SELECT currency_code FROM companies WHERE id=?', [company]).single['currency_code'] as String;
  void addAccount(String company, String id, String code, String name, AccountKind kind) => db.execute(
    "INSERT INTO accounts(id,company_id,code,name,kind,currency_code) VALUES(?,?,?,?,?,'YER')", [id,company,code,name,kind.name]);
  Row? existing(String company, FinancialReference type, String reference) {
    final rows = db.select('SELECT id,canonical_request,posted FROM journal_entries WHERE company_id=? AND reference_type=? AND reference_id=?', [company,type.name,reference]);
    return rows.isEmpty ? null : rows.single;
  }
  String nextNumber(String company, {String kind = 'journal', String prefix = 'JE'}) {
    db.execute("INSERT OR IGNORE INTO document_sequences(company_id,kind,next_value) VALUES(?,?,1)", [company,kind]);
    final next = db.select("SELECT next_value FROM document_sequences WHERE company_id=? AND kind=?", [company,kind]).single['next_value'] as int;
    db.execute("UPDATE document_sequences SET next_value=next_value+1 WHERE company_id=? AND kind=?", [company,kind]);
    return '$prefix-${next.toString().padLeft(8,'0')}';
  }
  void insert(String company, String user, String id, String number, PostingRequest request, String canonical, List<JournalLine> lines) {
    db.execute("INSERT INTO journal_entries(id,company_id,branch_id,document_number,reference_type,reference_id,document_date,description,currency_code,canonical_request,created_by,created_at) VALUES(?,?,?,?,?,?,?,?,'YER',?,?,?)",
      [id,company,request.branchId,number,request.reference.name,request.referenceId,request.date,request.description.trim(),canonical,user,DateTime.now().toUtc().toIso8601String()]);
    for (var i=0; i<lines.length; i++) {
      final line = lines[i];
      db.execute("INSERT INTO journal_entry_lines(entry_id,line_number,company_id,currency_code,account_id,debit_minor,credit_minor) VALUES(?,?,?,'YER',?,?,?)",
        [id,i,company,line.accountId,line.debit.minor,line.credit.minor]);
    }
    db.execute('UPDATE journal_entries SET posted=1 WHERE id=? AND company_id=?', [id,company]);
  }
  List<JournalRecord> entries(String company) => db.select('SELECT id,document_number,reference_id,document_date,description FROM journal_entries WHERE company_id=? AND posted=1 ORDER BY created_at,id', [company])
    .map((r) => JournalRecord(r['id'] as String,r['document_number'] as String,r['reference_id'] as String,r['document_date'] as String,r['description'] as String)).toList();
  BigInt balance(String company, String account) {
    var value = BigInt.zero;
    for (final row in db.select('SELECT l.debit_minor,l.credit_minor FROM journal_entry_lines l JOIN journal_entries e ON e.id=l.entry_id AND e.company_id=l.company_id WHERE l.company_id=? AND l.account_id=? AND e.posted=1', [company,account])) {
      value += BigInt.from(row['debit_minor'] as int) - BigInt.from(row['credit_minor'] as int);
    }
    return value;
  }
}
