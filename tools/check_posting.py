"""Exercise the financial migration's SQL guards without a Flutter SDK."""
import sqlite3
import unittest
from pathlib import Path


class PostingMigrationTest(unittest.TestCase):
    def setUp(self):
        self.db = sqlite3.connect(':memory:')
        self.db.execute('PRAGMA foreign_keys=ON')
        root = Path(__file__).resolve().parents[1] / 'lib/src/data/migrations'
        for path in sorted(root.glob('*.sql')):
            self.db.executescript(path.read_text())
        for company in ('a', 'b'):
            self.db.execute("INSERT INTO companies(id,name,created_at) VALUES(?,?, 'date')", (company, company))
            self.db.execute("INSERT INTO branches(id,company_id,name,created_at) VALUES(?,?, 'Main','date')", ('branch-' + company, company))
            self.db.execute("INSERT INTO users(id,company_id,branch_id,username,password_hash,created_at) VALUES(?,?,?,'admin','hash','date')", ('user-' + company, company, 'branch-' + company))
        for account, company in (('cash', 'a'), ('equity', 'a'), ('foreign', 'b')):
            self.db.execute("INSERT INTO accounts(id,company_id,code,name,kind,currency_code) VALUES(?,?,?,?,'cash','YER')", (account, company, account, account))
        self.db.execute("INSERT INTO journal_entries(id,company_id,branch_id,document_number,reference_type,reference_id,document_date,description,currency_code,canonical_request,created_by,created_at) VALUES('j','a','branch-a','JE-1','openingBalance','ref','2026-10-05','Opening','YER','[]','user-a','date')")

    def tearDown(self):
        self.db.close()

    def line(self, number, account, debit, credit):
        self.db.execute("INSERT INTO journal_entry_lines(entry_id,line_number,company_id,currency_code,account_id,debit_minor,credit_minor) VALUES('j',?,'a','YER',?,?,?)", (number, account, debit, credit))

    def test_finalization_rejects_imbalance_and_cross_tenant(self):
        self.line(0, 'cash', 100, 0)
        with self.assertRaises(sqlite3.IntegrityError):
            self.db.execute("UPDATE journal_entries SET posted=1 WHERE id='j'")
        with self.assertRaises(sqlite3.IntegrityError):
            self.line(1, 'foreign', 0, 100)
        self.line(1, 'equity', 0, 99)
        with self.assertRaises(sqlite3.IntegrityError):
            self.db.execute("UPDATE journal_entries SET posted=1 WHERE id='j'")
        self.db.execute("DELETE FROM journal_entry_lines WHERE line_number=1")
        self.line(1, 'equity', 0, 100)
        self.db.execute("UPDATE journal_entries SET posted=1 WHERE id='j'")
        self.assertEqual(self.db.execute('PRAGMA foreign_key_check').fetchall(), [])

    def test_posted_records_cannot_be_changed_or_deleted(self):
        self.line(0, 'cash', 100, 0)
        self.line(1, 'equity', 0, 100)
        self.db.execute("UPDATE journal_entries SET posted=1 WHERE id='j'")
        for sql in ("UPDATE journal_entries SET posted=0", "DELETE FROM journal_entries", "UPDATE journal_entry_lines SET debit_minor=101", "DELETE FROM journal_entry_lines", "INSERT INTO journal_entry_lines VALUES('j',2,'a','YER','cash',1,0)"):
            with self.assertRaises(sqlite3.IntegrityError):
                self.db.execute(sql)
        with self.assertRaises(sqlite3.IntegrityError):
            self.db.execute("INSERT INTO journal_entries SELECT 'other',company_id,branch_id,'JE-2',reference_type,'other',document_date,description,currency_code,canonical_request,posted,created_by,created_at FROM journal_entries")

    def test_exact_amount_constraints_and_total_range(self):
        for debit, credit in ((-1, 0), (1.5, 0), (0, 0), (1, 1), (9000000000000001, 0)):
            with self.assertRaises(sqlite3.IntegrityError):
                self.line(0, 'cash', debit, credit)
        for i, (debit, credit) in enumerate(((9000000000000000, 0), (9000000000000000, 0), (0, 9000000000000000), (0, 9000000000000000))):
            self.line(i, 'cash' if debit else 'equity', debit, credit)
        with self.assertRaises(sqlite3.IntegrityError):
            self.db.execute("UPDATE journal_entries SET posted=1 WHERE id='j'")


if __name__ == '__main__':
    unittest.main()
