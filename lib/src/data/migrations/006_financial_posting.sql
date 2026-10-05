-- Phase 0: single-company currency YER, two-decimal exact minor units.
CREATE TABLE accounts (
  id TEXT PRIMARY KEY CHECK(length(id)>0),
  company_id TEXT NOT NULL REFERENCES companies(id) ON DELETE RESTRICT,
  code TEXT NOT NULL CHECK(length(trim(code))>0),
  name TEXT NOT NULL CHECK(length(trim(name))>0),
  kind TEXT NOT NULL CHECK(kind IN ('cash','custody','expense','sales','receivable','equity')),
  currency_code TEXT NOT NULL CHECK(currency_code='YER'),
  UNIQUE(company_id,code), UNIQUE(id,company_id,currency_code)
);
CREATE TABLE document_sequences (
  company_id TEXT NOT NULL REFERENCES companies(id) ON DELETE RESTRICT,
  kind TEXT NOT NULL,
  next_value INTEGER NOT NULL CHECK(typeof(next_value)='integer' AND next_value BETWEEN 1 AND 9000000000000000),
  PRIMARY KEY(company_id,kind)
);
CREATE TABLE journal_entries (
  id TEXT PRIMARY KEY CHECK(length(id)>0),
  company_id TEXT NOT NULL REFERENCES companies(id) ON DELETE RESTRICT,
  branch_id TEXT NOT NULL,
  document_number TEXT NOT NULL CHECK(length(document_number)>0),
  reference_type TEXT NOT NULL CHECK(reference_type IN ('openingBalance','custodyIssue','expense','salesInvoice')),
  reference_id TEXT NOT NULL CHECK(length(reference_id)>0),
  document_date TEXT NOT NULL,
  description TEXT NOT NULL,
  currency_code TEXT NOT NULL CHECK(currency_code='YER'),
  canonical_request TEXT NOT NULL,
  posted INTEGER NOT NULL DEFAULT 0 CHECK(posted IN (0,1)),
  created_by TEXT NOT NULL,
  created_at TEXT NOT NULL,
  UNIQUE(company_id,document_number), UNIQUE(company_id,reference_type,reference_id),
  UNIQUE(id,company_id,currency_code),
  FOREIGN KEY(branch_id,company_id) REFERENCES branches(id,company_id) ON DELETE RESTRICT,
  FOREIGN KEY(created_by,company_id) REFERENCES users(id,company_id) ON DELETE RESTRICT
);
CREATE TABLE journal_entry_lines (
  entry_id TEXT NOT NULL,
  line_number INTEGER NOT NULL CHECK(line_number BETWEEN 0 AND 99),
  company_id TEXT NOT NULL,
  currency_code TEXT NOT NULL,
  account_id TEXT NOT NULL,
  debit_minor INTEGER NOT NULL CHECK(typeof(debit_minor)='integer' AND debit_minor BETWEEN 0 AND 9000000000000000),
  credit_minor INTEGER NOT NULL CHECK(typeof(credit_minor)='integer' AND credit_minor BETWEEN 0 AND 9000000000000000),
  CHECK((debit_minor>0 AND credit_minor=0) OR (credit_minor>0 AND debit_minor=0)),
  PRIMARY KEY(entry_id,line_number),
  FOREIGN KEY(entry_id,company_id,currency_code) REFERENCES journal_entries(id,company_id,currency_code) ON DELETE RESTRICT,
  FOREIGN KEY(account_id,company_id,currency_code) REFERENCES accounts(id,company_id,currency_code) ON DELETE RESTRICT
);
CREATE INDEX journal_lines_account ON journal_entry_lines(company_id,account_id);
CREATE TRIGGER journal_insert_draft BEFORE INSERT ON journal_entries WHEN NEW.posted<>0
BEGIN SELECT RAISE(ABORT,'Post only through finalization'); END;
CREATE TRIGGER journal_post_balanced BEFORE UPDATE OF posted ON journal_entries WHEN OLD.posted=0 AND NEW.posted=1
BEGIN
  SELECT CASE WHEN (SELECT count(*) FROM journal_entry_lines WHERE entry_id=OLD.id)<2
    OR (SELECT coalesce(sum(debit_minor),0) FROM journal_entry_lines WHERE entry_id=OLD.id)=0
    OR (SELECT sum(debit_minor) FROM journal_entry_lines WHERE entry_id=OLD.id)<> (SELECT sum(credit_minor) FROM journal_entry_lines WHERE entry_id=OLD.id)
    OR (SELECT sum(debit_minor) FROM journal_entry_lines WHERE entry_id=OLD.id)>9000000000000000
    THEN RAISE(ABORT,'Unbalanced or unsupported posting') END;
END;
CREATE TRIGGER journal_immutable_update BEFORE UPDATE ON journal_entries WHEN OLD.posted=1
BEGIN SELECT RAISE(ABORT,'Posted entry is immutable'); END;
CREATE TRIGGER journal_immutable_delete BEFORE DELETE ON journal_entries WHEN OLD.posted=1
BEGIN SELECT RAISE(ABORT,'Posted entry is immutable'); END;
CREATE TRIGGER journal_lines_insert BEFORE INSERT ON journal_entry_lines WHEN (SELECT posted FROM journal_entries WHERE id=NEW.entry_id)=1
BEGIN SELECT RAISE(ABORT,'Posted lines are immutable'); END;
CREATE TRIGGER journal_lines_update BEFORE UPDATE ON journal_entry_lines
BEGIN SELECT RAISE(ABORT,'Journal lines are immutable'); END;
CREATE TRIGGER journal_lines_delete BEFORE DELETE ON journal_entry_lines WHEN (SELECT posted FROM journal_entries WHERE id=OLD.entry_id)=1
BEGIN SELECT RAISE(ABORT,'Posted lines are immutable'); END;
INSERT OR IGNORE INTO permissions(code,description) VALUES('finance.view','عرض السجل المالي'),('finance.post','ترحيل العمليات المالية');
-- Original bootstrap manager may have been renamed. Do not grant reader roles.
INSERT OR IGNORE INTO role_permissions(role_id,permission_code)
SELECT DISTINCT ur.role_id,p.code FROM user_roles ur
JOIN audit_logs a ON a.user_id=ur.user_id AND a.company_id=ur.company_id AND a.action='company.bootstrap'
JOIN role_permissions rp ON rp.role_id=ur.role_id AND rp.permission_code='administration.manage'
JOIN permissions p ON p.code IN ('finance.view','finance.post');
INSERT INTO schema_migrations(version,applied_at) VALUES(6,strftime('%Y-%m-%dT%H:%M:%fZ','now'));
