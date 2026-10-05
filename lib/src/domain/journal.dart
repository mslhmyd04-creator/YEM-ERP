import 'money.dart';

enum AccountKind { cash, custody, expense, sales, receivable, equity }
enum FinancialReference { openingBalance, custodyIssue, expense, salesInvoice }

class LedgerAccount {
  const LedgerAccount(this.id, this.code, this.name, this.kind);
  final String id;
  final String code;
  final String name;
  final AccountKind kind;
}
class JournalLine {
  JournalLine({required this.accountId, required this.debit, required this.credit});
  final String accountId;
  final Money debit;
  final Money credit;
}
class PostingRequest {
  PostingRequest({required this.reference, required this.referenceId, required this.branchId,
    required this.date, required this.description, required List<JournalLine> lines}) : lines = List.unmodifiable(lines);
  final FinancialReference reference;
  final String referenceId;
  final String branchId;
  final String date; // ISO date without a timezone.
  final String description;
  final List<JournalLine> lines;
}
class JournalRecord {
  const JournalRecord(this.id, this.number, this.referenceId, this.date, this.description);
  final String id;
  final String number;
  final String referenceId;
  final String date;
  final String description;
}
