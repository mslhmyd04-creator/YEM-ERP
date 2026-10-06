import 'dart:convert';
import '../data/financial_repository.dart';
import '../domain/financial_document.dart';
import '../domain/identifiers.dart';
import '../domain/journal.dart';
import '../domain/money.dart';
import 'local_auth_service.dart';
import 'posting_engine.dart';

class FinancialService {
  FinancialService(this.auth,this.posting,this.repository);
  final LocalAuthService auth;
  final PostingEngine posting;
  final FinancialRepository repository;
  String get _company => auth.requirePermission('finance.view').companyId;
  List<FinancialChoice> branches() => repository.branches(_company);
  List<FinancialChoice> employees() => repository.employees(_company);
  List<ExpenseCategory> categories() => repository.categories(_company);
  List<CustodyRecord> custodies() => repository.custodies(_company);
  List<ExpenseRecord> expenses() => repository.expenses(_company);
  List<LedgerAccount> cashAccounts() => posting.accounts().where((a)=>a.kind==AccountKind.cash).toList();
  List<LedgerAccount> equityAccounts() => posting.accounts().where((a)=>a.kind==AccountKind.equity).toList();
  BigInt custodyBalance(String id) {
    final record=_custody(_company,id);
    if(record==null){throw const AccessDenied('العهدة غير متاحة لهذه المؤسسة.');}
    return posting.balance(record.accountId);
  }
  CustodyRecord? _custody(String company,String id) {
    final rows=repository.custodies(company).where((r)=>r.id==id).toList();
    return rows.isEmpty?null:rows.single;
  }
  static const categoryLabels = <String,String>{'fuel':'وقود','transport':'نقل','maintenance':'صيانة','communications':'اتصالات','internet':'إنترنت','rent':'إيجار','electricity':'كهرباء','water':'ماء','hospitality':'ضيافة','office':'مشتريات مكتبية','travel':'سفر','salaries':'رواتب','marketing':'تسويق','other':'أخرى'};
  void configureDefaults() {
    final session=auth.requirePermission('administration.manage');
    String account(String code,String name,AccountKind kind) {
      final matches=posting.repository.accounts(session.companyId).where((a)=>a.code==code).toList();
      if(matches.isNotEmpty){
        if(matches.single.kind!=kind){throw const AccessDenied('نوع الحساب الافتراضي غير صحيح.');}
        return matches.single.id;
      }
      return posting.createAccount(code: code,name: name,kind: kind);
    }
    // Each account is independently audited; interrupted configuration resumes by code.
    account('phase0.cash','الصندوق الرئيسي',AccountKind.cash);
    account('phase0.equity','رصيد افتتاحي',AccountKind.equity);
    final expense=account('phase0.expense','المصروفات العامة',AccountKind.expense);
    auth.db.execute('BEGIN IMMEDIATE');
    try {
      auth.requirePermission('administration.manage');
      for(final item in categoryLabels.entries){
        if(!repository.hasCategory(session.companyId,item.key)){
          final id=newUuid(); repository.addCategory(session.companyId,id,item.key,item.value,expense);
          auth.audit(companyId: session.companyId,userId: session.userId,action: 'expense_categories.create',entity: 'expense_categories',recordId: id);
        }
      }
      auth.db.execute('COMMIT');
    } catch(_){auth.db.execute('ROLLBACK');rethrow;}
  }
  void _kind(String company,String id,AccountKind kind) {
    if(!posting.repository.accounts(company).any((a)=>a.id==id && a.kind==kind)){throw const AccessDenied('حساب الدفع غير متاح أو نوعه غير صحيح.');}
  }
  void _available(String company,String account,Money amount) {
    if(posting.repository.balance(company,account)<BigInt.from(amount.minor)){throw const AccessDenied('الرصيد المتاح لا يكفي لهذه العملية.');}
  }
  List<JournalLine> _lines(String debit,String credit,Money amount) => [JournalLine(accountId: debit,debit: amount,credit: Money(0)),JournalLine(accountId: credit,debit: Money(0),credit: amount)];
  String opening({required String id,required String branch,required String cash,required String equity,required Money amount,required String date,required String description}) {
    final session=auth.requirePermission('administration.manage');
    return posting.post(PostingRequest(reference: FinancialReference.openingBalance,referenceId: id,branchId: branch,date: date,description: description,lines: _lines(cash,equity,amount)),prepare: (){
      _kind(session.companyId,cash,AccountKind.cash);_kind(session.companyId,equity,AccountKind.equity);
    });
  }
  String issue({required String id,required String branch,required String cash,required String employee,required Money amount,required String date,required String description}) {
    final session=auth.requirePermission('finance.post');
    final existing=_custody(session.companyId,id);
    final account=existing?.accountId??newUuid();
    posting.post(PostingRequest(reference: FinancialReference.custodyIssue,referenceId: id,branchId: branch,date: date,description: description,lines: _lines(account,cash,amount)),
      businessPayload: jsonEncode([employee,cash]),prepare: (){
        _kind(session.companyId,cash,AccountKind.cash);_available(session.companyId,cash,amount);
        if(!repository.employees(session.companyId).any((u)=>u.id==employee)){throw const AccessDenied('الموظف غير متاح لهذه المؤسسة.');}
        posting.repository.addAccount(session.companyId,account,'custody-$id','عهدة $id',AccountKind.custody);
        auth.audit(companyId: session.companyId,userId: session.userId,action: 'accounts.create',entity: 'accounts',recordId: account);
      },persist: (entry){
        repository.addCustody(id: id,company: session.companyId,branch: branch,number: posting.repository.nextNumber(session.companyId,kind: 'custody',prefix: 'CU'),employee: employee,account: account,amount: amount.minor,date: date,description: description.trim(),entry: entry,user: session.userId);
        repository.movement(newUuid(),session.companyId,id,entry,'issue',amount.minor,0,amount.minor);
        auth.audit(companyId: session.companyId,userId: session.userId,action: 'custody.issue',entity: 'custodies',recordId: id);
      });
    return id;
  }
  String expense({required String id,required String branch,required String category,required Money amount,required String date,required String description,String? cash,String? custody}) {
    final session=auth.requirePermission('finance.post');
    if((cash==null)==(custody==null)){throw const AccessDenied('اختر صندوقًا أو عهدة واحدة للدفع.');}
    final choices=repository.categories(session.companyId).where((c)=>c.id==category).toList();
    if(choices.isEmpty){throw const AccessDenied('فئة المصروف غير متاحة لهذه المؤسسة.');}
    final holding=custody==null?null:_custody(session.companyId,custody);
    if(custody!=null && holding==null){throw const AccessDenied('العهدة غير متاحة لهذه المؤسسة.');}
    final source=cash??holding!.accountId;
    var before=0;
    posting.post(PostingRequest(reference: FinancialReference.expense,referenceId: id,branchId: branch,date: date,description: description,lines: _lines(choices.single.accountId,source,amount)),
      businessPayload: jsonEncode([category,cash,custody]),prepare: (){
        if(cash!=null){_kind(session.companyId,cash,AccountKind.cash);}
        _available(session.companyId,source,amount);
        if(custody!=null){before=posting.repository.balance(session.companyId,source).toInt();}
      },persist: (entry){
        repository.addExpense(id: id,company: session.companyId,branch: branch,number: posting.repository.nextNumber(session.companyId,kind: 'expense',prefix: 'EX'),category: category,amount: amount.minor,date: date,description: description.trim(),cash: cash,custody: custody,entry: entry,user: session.userId);
        if(custody!=null){repository.movement(newUuid(),session.companyId,custody,entry,'expense',amount.minor,before,before-amount.minor);}
        auth.audit(companyId: session.companyId,userId: session.userId,action: 'expenses.post',entity: 'expenses',recordId: id);
      });
    return id;
  }
}
