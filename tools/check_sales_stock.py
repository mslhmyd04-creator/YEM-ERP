"""Direct SQL stock/invoice guards, independent of the service's validation."""
import sqlite3
import unittest
import check_posting

class SalesStockMigrationTest(unittest.TestCase):
    setUp = check_posting.PostingMigrationTest.setUp
    tearDown = check_posting.PostingMigrationTest.tearDown

    def fixtures(self):
        d = self.db
        d.execute("INSERT INTO accounts(id,company_id,code,name,kind,currency_code,account_type) VALUES('inv','a','inv','Inventory','receivable','YER','inventory')")
        d.execute("INSERT INTO accounts(id,company_id,code,name,kind,currency_code,account_type) VALUES('cogs','a','cogs','Cost','expense','YER','costOfSales')")
        d.execute("INSERT INTO accounts(id,company_id,code,name,kind,currency_code) VALUES('sales','a','sales','Sales','sales','YER')")
        d.execute("INSERT INTO units VALUES('u','a','Unit')")
        d.execute("INSERT INTO products(id,company_id,sku,name,unit_id,created_at,updated_at) VALUES('p','a','p','Product','u','date','date')")
        d.execute("INSERT INTO warehouses VALUES('w','a','branch-a','Warehouse')")
        d.execute("INSERT INTO customers(id,company_id,name,created_at) VALUES('customer','a','Customer','date')")
        check_posting.PostingMigrationTest.line(self,0,'inv',1000,0)
        check_posting.PostingMigrationTest.line(self,1,'equity',0,1000)
        d.execute("UPDATE journal_entries SET posted=1 WHERE id='j'")

    def movement(self, quantity=10, value=1000, before=0, after=10):
        self.db.execute("INSERT INTO stock_ledger(id,company_id,branch_id,warehouse_id,product_id,ledger_order,movement_type,reference_id,document_number,document_date,description,quantity_delta,value_delta_minor,quantity_before,quantity_after,value_before_minor,value_after_minor,journal_entry_id,created_by,created_at) VALUES('stock','a','branch-a','w','p',1,'opening','ref','ST-1','2026-10-05','Opening',?,?,?, ?,0,?,'j','user-a','date')",(quantity,value,before,after,value))

    def test_stock_value_snapshot_and_immutability(self):
        self.fixtures()
        for args in ((10,999,0,10),(10,1000,1,11),(0,1000,0,0)):
            with self.assertRaises(sqlite3.IntegrityError):
                self.movement(*args)
        self.movement()
        for sql in ("DELETE FROM stock_ledger", "UPDATE stock_ledger SET quantity_after=0", "UPDATE stock_ledger SET value_delta_minor=999"):
            with self.assertRaises(sqlite3.IntegrityError):
                self.db.execute(sql)
        self.assertEqual(self.db.execute('PRAGMA foreign_key_check').fetchall(),[])

    def test_invoice_requires_matching_sales_journal_and_items(self):
        self.fixtures()
        self.db.execute("INSERT INTO sales_invoices(id,company_id,branch_id,customer_id,document_number,document_date,description,company_name,branch_name,customer_name,total_minor,is_cash,debit_account_id,sales_account_id,inventory_account_id,cogs_account_id,journal_entry_id,created_by) VALUES('invoice','a','branch-a','customer','SI-1','2026-10-05','Sale','A','Main','Customer',1000,1,'cash','sales','inv','cogs','j','user-a')")
        with self.assertRaises(sqlite3.IntegrityError):
            self.db.execute("UPDATE sales_invoices SET is_complete=1")
        self.db.execute("INSERT INTO sales_invoice_items(id,company_id,invoice_id,line_number,product_id,product_name,sku,unit_name,quantity,unit_price_minor,total_minor,cost_minor,is_stock_item,warehouse_id) VALUES('item','a','invoice',0,'p','Product','p','Unit',10,100,1000,1000,1,'w')")
        with self.assertRaises(sqlite3.IntegrityError):
            self.db.execute("UPDATE sales_invoices SET is_complete=1")
        with self.assertRaises(sqlite3.IntegrityError):
            self.db.execute("UPDATE sales_invoice_items SET quantity=1")
        with self.assertRaises(sqlite3.IntegrityError):
            self.db.execute("INSERT INTO expense_categories(id,company_id,code,name,account_id) VALUES('bad','a','bad','Bad','cogs')")

if __name__ == '__main__':
    unittest.main()
