import 'dart:convert';
import '../data/journal_repository.dart';
import '../domain/identifiers.dart';
import '../domain/journal.dart';
import '../domain/money.dart';
import 'local_auth_service.dart';

/// Central Phase 0 ledger boundary. Business workflows will compose here.
class PostingEngine {
  PostingEngine(this.auth, this.repository);
  final LocalAuthService auth;
  final JournalRepository repository;
  List<LedgerAccount> accounts() => repository.accounts(auth.requirePermission('finance.view').companyId);
  List<JournalRecord> entries() => repository.entries(auth.requirePermission('finance.view').companyId);
  BigInt balance(String account) {
    final company = auth.requirePermission('finance.view').companyId;
    if (!repository.ownsAccount(company,account)) { throw const AccessDenied('الحساب غير متاح لهذه المؤسسة.'); }
    return repository.balance(company,account);
  }
  String createAccount({required String code, required String name, required AccountKind kind}) {
    final session = auth.requirePermission('administration.manage');
    final clean = code.trim(), label = name.trim();
    if (clean.isEmpty || clean.length>50 || label.isEmpty || label.length>100 || repository.currency(session.companyId)!='YER') {
      throw const AccessDenied('تحقق من الحساب. المرحلة 0 تدعم عملة المؤسسة YER فقط.');
    }
    final id = newUuid();
    return _transaction(() {
      auth.requirePermission('administration.manage');
      repository.addAccount(session.companyId,id,clean,label,kind);
      auth.audit(companyId: session.companyId,userId: session.userId,action: 'accounts.create',entity: 'accounts',recordId: id);
      return id;
    });
  }
  String post(PostingRequest request, {String? businessPayload, void Function()? prepare, void Function(String entryId)? persist}) {
    final session = auth.requirePermission('finance.post');
    final lines = _validate(request);
    final canonical = jsonEncode([request.reference.name,request.referenceId,request.branchId,request.date,request.description.trim(),
      lines.map((l)=>[l.accountId,l.debit.minor,l.credit.minor]).toList(), if (businessPayload != null) businessPayload]);
    return _transaction(() {
      auth.requirePermission('finance.post');
      if (repository.currency(session.companyId)!='YER' || !repository.ownsBranch(session.companyId,request.branchId)) {
        throw const AccessDenied('الفرع أو الحساب أو العملة غير متاحة لهذه المؤسسة.');
      }
      final prior = repository.existing(session.companyId,request.reference,request.referenceId);
      if (prior != null) {
        if (prior['posted']!=1 || prior['canonical_request']!=canonical) { throw const AccessDenied('يتعارض الطلب مع قيد سابق. لا يمكن تغيير مستند مرحّل.'); }
        return prior['id'] as String;
      }
      prepare?.call(); // Synchronous business validation/preparation under the same lock.
      if (!lines.every((l)=>repository.ownsAccount(session.companyId,l.accountId))) { throw const AccessDenied('الحساب غير متاح لهذه المؤسسة.'); }
      final id = newUuid();
      repository.insert(session.companyId,session.userId,id,repository.nextNumber(session.companyId),request,canonical,lines);
      persist?.call(id); // A failure rolls back business document, journal and sequence.
      auth.audit(companyId: session.companyId,userId: session.userId,action: 'journal.post',entity: 'journal_entries',recordId: id);
      return id;
    });
  }
  List<JournalLine> _validate(PostingRequest request) {
    final parsed = DateTime.tryParse(request.date);
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(request.date) || parsed == null || parsed.toIso8601String().substring(0,10)!=request.date ||
      !RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$').hasMatch(request.referenceId) ||
      request.description.trim().isEmpty || request.description.length>500 || request.lines.length<2 || request.lines.length>100) {
      throw const AccessDenied('تحقق من تاريخ ووصف وهوية المستند وبنود القيد.');
    }
    var debit = BigInt.zero, credit = BigInt.zero;
    for (final line in request.lines) {
      if (line.accountId.isEmpty || !((line.debit.minor>0 && line.credit.minor==0) || (line.credit.minor>0 && line.debit.minor==0))) {
        throw const AccessDenied('كل بند يحتوي مبلغًا مدينًا أو دائنًا موجبًا فقط.');
      }
      debit += BigInt.from(line.debit.minor); credit += BigInt.from(line.credit.minor);
    }
    if (debit != credit || debit>BigInt.from(Money.maximumMinor)) { throw const AccessDenied('القيد غير متوازن أو يتجاوز الحد المسموح.'); }
    final sorted = List<JournalLine>.of(request.lines);
    sorted.sort((a,b) { var c=a.accountId.compareTo(b.accountId); if(c==0){c=a.debit.minor.compareTo(b.debit.minor);} if(c==0){c=a.credit.minor.compareTo(b.credit.minor);} return c; });
    return sorted;
  }
  T _transaction<T>(T Function() action) {
    auth.db.execute('BEGIN IMMEDIATE');
    try { final result=action(); auth.db.execute('COMMIT'); return result; }
    catch (_) { auth.db.execute('ROLLBACK'); rethrow; }
  }
}
