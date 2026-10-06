class FinancialChoice {
  const FinancialChoice(this.id, this.name);
  final String id;
  final String name;
}
class ExpenseCategory {
  const ExpenseCategory(this.id, this.name, this.accountId);
  final String id;
  final String name;
  final String accountId;
}
class CustodyRecord {
  const CustodyRecord(this.id, this.number, this.employeeId, this.accountId, this.description, this.issuedMinor);
  final String id, number, employeeId, accountId, description;
  final int issuedMinor;
}
class ExpenseRecord {
  const ExpenseRecord(this.id, this.number, this.description, this.amountMinor, this.custodyId);
  final String id, number, description;
  final int amountMinor;
  final String? custodyId;
}
enum FinanceForm { expense, custody, opening }
