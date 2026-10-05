import sqlite3
import unittest
import check_posting


class FinancialDocumentMigrationTest(unittest.TestCase):
    setUp = check_posting.PostingMigrationTest.setUp
    tearDown = check_posting.PostingMigrationTest.tearDown

    def custody(self):
        self.db.execute("INSERT INTO accounts(id,company_id,code,name,kind,currency_code) VALUES('holding','a','holding','Holding','custody','YER')")
        self.db.execute("INSERT INTO accounts(id,company_id,code,name,kind,currency_code) VALUES('expense','a','expense','Expense','expense','YER')")
        self.db.execute("INSERT INTO expense_categories(id,company_id,code,name,account_id) VALUES('cat','a','other','Other','expense')")
        self.db.execute("UPDATE journal_entries SET reference_type='custodyIssue',reference_id='cu' WHERE id='j'")
        self.db.execute("INSERT INTO journal_entry_lines VALUES('j',0,'a','YER','holding',100,0)")
        self.db.execute("INSERT INTO journal_entry_lines VALUES('j',1,'a','YER','cash',0,100)")
        self.db.execute("UPDATE journal_entries SET posted=1 WHERE id='j'")
        self.db.execute("INSERT INTO custodies(id,company_id,branch_id,document_number,employee_id,account_id,issued_minor,document_date,description,journal_entry_id,created_by) VALUES('cu','a','branch-a','CU-1','user-a','holding',100,'2026-10-05','Holding','j','user-a')")
        self.db.execute("INSERT INTO custody_ledger VALUES('m1','a','cu','j','issue',100,0,100,'YER')")

    def expense(self):
        self.db.execute("INSERT INTO journal_entries(id,company_id,branch_id,document_number,reference_type,reference_id,document_date,description,currency_code,canonical_request,created_by,created_at) VALUES('j2','a','branch-a','JE-2','expense','ex','2026-10-05','Expense','YER','[]','user-a','date')")
        self.db.execute("INSERT INTO journal_entry_lines VALUES('j2',0,'a','YER','expense',50,0)")
        self.db.execute("INSERT INTO journal_entry_lines VALUES('j2',1,'a','YER','holding',0,50)")
        self.db.execute("UPDATE journal_entries SET posted=1 WHERE id='j2'")
        self.db.execute("INSERT INTO expenses(id,company_id,branch_id,document_number,category_id,amount_minor,document_date,description,custody_id,journal_entry_id,created_by) VALUES('ex','a','branch-a','EX-1','cat',50,'2026-10-05','Expense','cu','j2','user-a')")

    def test_document_rejects_wrong_journal_and_category_account(self):
        self.custody()
        with self.assertRaises(sqlite3.IntegrityError):
            self.db.execute("INSERT INTO expense_categories(id,company_id,code,name,account_id) VALUES('wrong','a','wrong','Wrong','cash')")
        with self.assertRaises(sqlite3.IntegrityError):
            self.db.execute("INSERT INTO expenses(id,company_id,branch_id,document_number,category_id,amount_minor,document_date,description,custody_id,journal_entry_id,created_by) VALUES('wrong','a','branch-a','EX-1','cat',100,'2026-10-05','Wrong','cu','j','user-a')")
        self.expense()
        self.assertEqual(self.db.execute('PRAGMA foreign_key_check').fetchall(), [])

    def test_ledger_snapshot_matches_document_and_records_are_immutable(self):
        self.custody()
        self.expense()
        with self.assertRaises(sqlite3.IntegrityError):
            self.db.execute("INSERT INTO custody_ledger VALUES('wrong','a','cu','j2','expense',50,999,949,'YER')")
        self.db.execute("INSERT INTO custody_ledger VALUES('m2','a','cu','j2','expense',50,100,50,'YER')")
        for table in ('custodies', 'expenses', 'custody_ledger'):
            for sql in (f'UPDATE {table} SET id=id', f'DELETE FROM {table}'):
                with self.assertRaises(sqlite3.IntegrityError):
                    self.db.execute(sql)
        self.assertEqual(self.db.execute("SELECT sum(CASE WHEN movement_type='issue' THEN amount_minor ELSE -amount_minor END) FROM custody_ledger").fetchone(), (50,))


if __name__ == '__main__':
    unittest.main()
