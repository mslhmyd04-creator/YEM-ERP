CREATE TABLE expense_categories (
  id TEXT PRIMARY KEY,
  company_id TEXT NOT NULL REFERENCES companies(id) ON DELETE RESTRICT,
  code TEXT NOT NULL,
  name TEXT NOT NULL CHECK(length(trim(name))>0),
  account_id TEXT NOT NULL,
  currency_code TEXT NOT NULL DEFAULT 'YER' CHECK(currency_code='YER'),
  UNIQUE(company_id,code), UNIQUE(id,company_id),
  FOREIGN KEY(account_id,company_id,currency_code) REFERENCES accounts(id,company_id,currency_code) ON DELETE RESTRICT
);
CREATE TABLE custodies (
  id TEXT PRIMARY KEY,
  company_id TEXT NOT NULL,
  branch_id TEXT NOT NULL,
  document_number TEXT NOT NULL,
  employee_id TEXT NOT NULL,
  account_id TEXT NOT NULL UNIQUE,
  issued_minor INTEGER NOT NULL CHECK(typeof(issued_minor)='integer' AND issued_minor BETWEEN 1 AND 9000000000000000),
  document_date TEXT NOT NULL,
  description TEXT NOT NULL,
  currency_code TEXT NOT NULL DEFAULT 'YER' CHECK(currency_code='YER'),
  journal_entry_id TEXT NOT NULL UNIQUE,
  created_by TEXT NOT NULL,
  UNIQUE(id,company_id), UNIQUE(company_id,document_number),
  FOREIGN KEY(branch_id,company_id) REFERENCES branches(id,company_id) ON DELETE RESTRICT,
  FOREIGN KEY(employee_id,company_id) REFERENCES users(id,company_id) ON DELETE RESTRICT,
  FOREIGN KEY(created_by,company_id) REFERENCES users(id,company_id) ON DELETE RESTRICT,
  FOREIGN KEY(account_id,company_id,currency_code) REFERENCES accounts(id,company_id,currency_code) ON DELETE RESTRICT,
  FOREIGN KEY(journal_entry_id,company_id,currency_code) REFERENCES journal_entries(id,company_id,currency_code) ON DELETE RESTRICT
);
CREATE TABLE expenses (
  id TEXT PRIMARY KEY,
  company_id TEXT NOT NULL,
  branch_id TEXT NOT NULL,
  document_number TEXT NOT NULL,
  category_id TEXT NOT NULL,
  amount_minor INTEGER NOT NULL CHECK(typeof(amount_minor)='integer' AND amount_minor BETWEEN 1 AND 9000000000000000),
  document_date TEXT NOT NULL,
  description TEXT NOT NULL,
  currency_code TEXT NOT NULL DEFAULT 'YER' CHECK(currency_code='YER'),
  cash_account_id TEXT,
  custody_id TEXT,
  journal_entry_id TEXT NOT NULL UNIQUE,
  created_by TEXT NOT NULL,
  CHECK((cash_account_id IS NOT NULL AND custody_id IS NULL) OR (cash_account_id IS NULL AND custody_id IS NOT NULL)),
  UNIQUE(id,company_id), UNIQUE(company_id,document_number),
  FOREIGN KEY(branch_id,company_id) REFERENCES branches(id,company_id) ON DELETE RESTRICT,
  FOREIGN KEY(category_id,company_id) REFERENCES expense_categories(id,company_id) ON DELETE RESTRICT,
  FOREIGN KEY(cash_account_id,company_id,currency_code) REFERENCES accounts(id,company_id,currency_code) ON DELETE RESTRICT,
  FOREIGN KEY(custody_id,company_id) REFERENCES custodies(id,company_id) ON DELETE RESTRICT,
  FOREIGN KEY(journal_entry_id,company_id,currency_code) REFERENCES journal_entries(id,company_id,currency_code) ON DELETE RESTRICT,
  FOREIGN KEY(created_by,company_id) REFERENCES users(id,company_id) ON DELETE RESTRICT
);
CREATE TABLE custody_ledger (
  id TEXT PRIMARY KEY,
  company_id TEXT NOT NULL,
  custody_id TEXT NOT NULL,
  journal_entry_id TEXT NOT NULL UNIQUE,
  movement_type TEXT NOT NULL CHECK(movement_type IN ('issue','expense')),
  amount_minor INTEGER NOT NULL CHECK(typeof(amount_minor)='integer' AND amount_minor BETWEEN 1 AND 9000000000000000),
  balance_before_minor INTEGER NOT NULL CHECK(typeof(balance_before_minor)='integer' AND balance_before_minor BETWEEN 0 AND 9000000000000000),
  balance_after_minor INTEGER NOT NULL CHECK(typeof(balance_after_minor)='integer' AND balance_after_minor BETWEEN 0 AND 9000000000000000),
  currency_code TEXT NOT NULL DEFAULT 'YER' CHECK(currency_code='YER'),
  CHECK((movement_type='issue' AND balance_after_minor=balance_before_minor+amount_minor) OR (movement_type='expense' AND balance_after_minor=balance_before_minor-amount_minor)),
  FOREIGN KEY(custody_id,company_id) REFERENCES custodies(id,company_id) ON DELETE RESTRICT,
  FOREIGN KEY(journal_entry_id,company_id,currency_code) REFERENCES journal_entries(id,company_id,currency_code) ON DELETE RESTRICT
);
CREATE TRIGGER expense_category_account BEFORE INSERT ON expense_categories
BEGIN SELECT CASE WHEN NOT EXISTS(SELECT 1 FROM accounts WHERE id=NEW.account_id AND company_id=NEW.company_id AND kind='expense') THEN RAISE(ABORT,'Expense category requires an expense account') END; END;
CREATE TRIGGER custody_matches_journal BEFORE INSERT ON custodies
BEGIN
  SELECT CASE WHEN NOT EXISTS(SELECT 1 FROM journal_entries e WHERE e.id=NEW.journal_entry_id AND e.company_id=NEW.company_id AND e.posted=1 AND e.reference_type='custodyIssue' AND e.reference_id=NEW.id AND e.branch_id=NEW.branch_id AND e.document_date=NEW.document_date
    AND EXISTS(SELECT 1 FROM accounts WHERE id=NEW.account_id AND company_id=NEW.company_id AND kind='custody')
    AND (SELECT sum(debit_minor) FROM journal_entry_lines WHERE entry_id=e.id)=NEW.issued_minor
    AND (SELECT sum(debit_minor) FROM journal_entry_lines WHERE entry_id=e.id AND account_id=NEW.account_id)=NEW.issued_minor)
    THEN RAISE(ABORT,'Custody does not match posted journal') END;
END;
CREATE TRIGGER expense_matches_journal BEFORE INSERT ON expenses
BEGIN
  SELECT CASE WHEN NOT EXISTS(SELECT 1 FROM journal_entries e WHERE e.id=NEW.journal_entry_id AND e.company_id=NEW.company_id AND e.posted=1 AND e.reference_type='expense' AND e.reference_id=NEW.id AND e.branch_id=NEW.branch_id AND e.document_date=NEW.document_date
    AND (SELECT sum(debit_minor) FROM journal_entry_lines WHERE entry_id=e.id)=NEW.amount_minor
    AND (SELECT sum(debit_minor) FROM journal_entry_lines WHERE entry_id=e.id AND account_id=(SELECT account_id FROM expense_categories WHERE id=NEW.category_id AND company_id=NEW.company_id))=NEW.amount_minor
    AND (SELECT sum(credit_minor) FROM journal_entry_lines WHERE entry_id=e.id AND account_id=coalesce(NEW.cash_account_id,(SELECT account_id FROM custodies WHERE id=NEW.custody_id AND company_id=NEW.company_id)))=NEW.amount_minor)
    THEN RAISE(ABORT,'Expense does not match posted journal') END;
END;
CREATE TRIGGER custody_movement_matches BEFORE INSERT ON custody_ledger
BEGIN
  SELECT CASE WHEN NEW.balance_before_minor<>(SELECT coalesce(sum(CASE WHEN movement_type='issue' THEN amount_minor ELSE -amount_minor END),0) FROM custody_ledger WHERE custody_id=NEW.custody_id AND company_id=NEW.company_id)
    OR (NEW.movement_type='issue' AND NOT EXISTS(SELECT 1 FROM custodies WHERE id=NEW.custody_id AND company_id=NEW.company_id AND journal_entry_id=NEW.journal_entry_id AND issued_minor=NEW.amount_minor))
    OR (NEW.movement_type='expense' AND NOT EXISTS(SELECT 1 FROM expenses WHERE custody_id=NEW.custody_id AND company_id=NEW.company_id AND journal_entry_id=NEW.journal_entry_id AND amount_minor=NEW.amount_minor))
    THEN RAISE(ABORT,'Custody movement does not match document or balance') END;
END;
CREATE TRIGGER expenses_immutable_update BEFORE UPDATE ON expenses BEGIN SELECT RAISE(ABORT,'Posted expense is immutable'); END;
CREATE TRIGGER expenses_immutable_delete BEFORE DELETE ON expenses BEGIN SELECT RAISE(ABORT,'Posted expense is immutable'); END;
CREATE TRIGGER custodies_immutable_update BEFORE UPDATE ON custodies BEGIN SELECT RAISE(ABORT,'Posted custody is immutable'); END;
CREATE TRIGGER custodies_immutable_delete BEFORE DELETE ON custodies BEGIN SELECT RAISE(ABORT,'Posted custody is immutable'); END;
CREATE TRIGGER custody_ledger_immutable_update BEFORE UPDATE ON custody_ledger BEGIN SELECT RAISE(ABORT,'Custody ledger is immutable'); END;
CREATE TRIGGER custody_ledger_immutable_delete BEFORE DELETE ON custody_ledger BEGIN SELECT RAISE(ABORT,'Custody ledger is immutable'); END;
INSERT INTO schema_migrations(version,applied_at) VALUES(7,strftime('%Y-%m-%dT%H:%M:%fZ','now'));
