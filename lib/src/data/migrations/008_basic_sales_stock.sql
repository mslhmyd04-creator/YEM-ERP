-- Extend account classification without rebuilding UUIDs referenced by journals.
ALTER TABLE accounts ADD COLUMN account_type TEXT CHECK(account_type IS NULL OR
  (account_type='inventory' AND kind='receivable') OR (account_type='costOfSales' AND kind='expense') OR account_type=kind);
ALTER TABLE products ADD COLUMN is_stock_item INTEGER NOT NULL DEFAULT 1 CHECK(is_stock_item IN (0,1));
CREATE UNIQUE INDEX products_id_company ON products(id,company_id);
CREATE UNIQUE INDEX warehouses_id_company ON warehouses(id,company_id);
DROP TRIGGER expense_category_account;
CREATE TRIGGER expense_category_account BEFORE INSERT ON expense_categories
BEGIN SELECT CASE WHEN NOT EXISTS(SELECT 1 FROM accounts WHERE id=NEW.account_id AND company_id=NEW.company_id AND coalesce(account_type,kind)='expense') THEN RAISE(ABORT,'Expense category requires an expense account') END; END;
CREATE TABLE sales_invoices (
  id TEXT PRIMARY KEY,
  company_id TEXT NOT NULL,
  branch_id TEXT NOT NULL,
  customer_id TEXT NOT NULL,
  document_number TEXT NOT NULL,
  document_date TEXT NOT NULL,
  description TEXT NOT NULL,
  company_name TEXT NOT NULL,
  branch_name TEXT NOT NULL,
  customer_name TEXT NOT NULL,
  total_minor INTEGER NOT NULL CHECK(typeof(total_minor)='integer' AND total_minor BETWEEN 1 AND 9000000000000000),
  is_cash INTEGER NOT NULL CHECK(is_cash IN (0,1)),
  debit_account_id TEXT NOT NULL,
  sales_account_id TEXT NOT NULL,
  inventory_account_id TEXT NOT NULL,
  cogs_account_id TEXT NOT NULL,
  currency_code TEXT NOT NULL DEFAULT 'YER' CHECK(currency_code='YER'),
  journal_entry_id TEXT NOT NULL UNIQUE,
  is_complete INTEGER NOT NULL DEFAULT 0 CHECK(is_complete IN (0,1)),
  created_by TEXT NOT NULL,
  UNIQUE(id,company_id), UNIQUE(company_id,document_number),
  FOREIGN KEY(branch_id,company_id) REFERENCES branches(id,company_id) ON DELETE RESTRICT,
  FOREIGN KEY(customer_id,company_id) REFERENCES customers(id,company_id) ON DELETE RESTRICT,
  FOREIGN KEY(created_by,company_id) REFERENCES users(id,company_id) ON DELETE RESTRICT,
  FOREIGN KEY(journal_entry_id,company_id,currency_code) REFERENCES journal_entries(id,company_id,currency_code) ON DELETE RESTRICT,
  FOREIGN KEY(debit_account_id,company_id,currency_code) REFERENCES accounts(id,company_id,currency_code) ON DELETE RESTRICT,
  FOREIGN KEY(sales_account_id,company_id,currency_code) REFERENCES accounts(id,company_id,currency_code) ON DELETE RESTRICT,
  FOREIGN KEY(inventory_account_id,company_id,currency_code) REFERENCES accounts(id,company_id,currency_code) ON DELETE RESTRICT,
  FOREIGN KEY(cogs_account_id,company_id,currency_code) REFERENCES accounts(id,company_id,currency_code) ON DELETE RESTRICT
);
CREATE TABLE sales_invoice_items (
  id TEXT PRIMARY KEY,
  company_id TEXT NOT NULL,
  invoice_id TEXT NOT NULL,
  line_number INTEGER NOT NULL CHECK(line_number BETWEEN 0 AND 49),
  product_id TEXT NOT NULL,
  product_name TEXT NOT NULL,
  sku TEXT NOT NULL,
  unit_name TEXT NOT NULL,
  quantity INTEGER NOT NULL CHECK(typeof(quantity)='integer' AND quantity BETWEEN 1 AND 1000000000),
  unit_price_minor INTEGER NOT NULL CHECK(typeof(unit_price_minor)='integer' AND unit_price_minor BETWEEN 1 AND 9000000000000000),
  total_minor INTEGER NOT NULL CHECK(typeof(total_minor)='integer' AND total_minor BETWEEN 1 AND 9000000000000000 AND total_minor=quantity*unit_price_minor),
  cost_minor INTEGER NOT NULL CHECK(typeof(cost_minor)='integer' AND cost_minor BETWEEN 0 AND 9000000000000000),
  is_stock_item INTEGER NOT NULL CHECK(is_stock_item IN (0,1)),
  warehouse_id TEXT,
  CHECK((is_stock_item=1 AND warehouse_id IS NOT NULL AND cost_minor>0) OR (is_stock_item=0 AND warehouse_id IS NULL AND cost_minor=0)),
  UNIQUE(invoice_id,line_number), UNIQUE(invoice_id,product_id,warehouse_id),
  FOREIGN KEY(invoice_id,company_id) REFERENCES sales_invoices(id,company_id) ON DELETE RESTRICT,
  FOREIGN KEY(product_id,company_id) REFERENCES products(id,company_id) ON DELETE RESTRICT,
  FOREIGN KEY(warehouse_id,company_id) REFERENCES warehouses(id,company_id) ON DELETE RESTRICT
);
CREATE TABLE stock_ledger (
  id TEXT PRIMARY KEY,
  company_id TEXT NOT NULL,
  branch_id TEXT NOT NULL,
  warehouse_id TEXT NOT NULL,
  product_id TEXT NOT NULL,
  ledger_order INTEGER NOT NULL CHECK(ledger_order>0),
  movement_type TEXT NOT NULL CHECK(movement_type IN ('opening','sale')),
  reference_id TEXT NOT NULL,
  document_number TEXT NOT NULL,
  document_date TEXT NOT NULL,
  description TEXT NOT NULL,
  invoice_id TEXT,
  quantity_delta INTEGER NOT NULL CHECK(typeof(quantity_delta)='integer' AND quantity_delta<>0 AND quantity_delta BETWEEN -1000000000 AND 1000000000),
  quantity_in INTEGER GENERATED ALWAYS AS (max(quantity_delta,0)) VIRTUAL,
  quantity_out INTEGER GENERATED ALWAYS AS (max(-quantity_delta,0)) VIRTUAL,
  value_delta_minor INTEGER NOT NULL CHECK(typeof(value_delta_minor)='integer' AND value_delta_minor<>0 AND value_delta_minor BETWEEN -9000000000000000 AND 9000000000000000),
  quantity_before INTEGER NOT NULL CHECK(quantity_before BETWEEN 0 AND 1000000000),
  quantity_after INTEGER NOT NULL CHECK(quantity_after BETWEEN 0 AND 1000000000),
  value_before_minor INTEGER NOT NULL CHECK(value_before_minor BETWEEN 0 AND 9000000000000000),
  value_after_minor INTEGER NOT NULL CHECK(value_after_minor BETWEEN 0 AND 9000000000000000),
  currency_code TEXT NOT NULL DEFAULT 'YER' CHECK(currency_code='YER'),
  journal_entry_id TEXT NOT NULL,
  created_by TEXT NOT NULL,
  created_at TEXT NOT NULL,
  CHECK(quantity_after=quantity_before+quantity_delta AND value_after_minor=value_before_minor+value_delta_minor),
  CHECK((quantity_after=0 AND value_after_minor=0) OR (quantity_after>0 AND value_after_minor>=quantity_after)),
  CHECK((movement_type='opening' AND invoice_id IS NULL AND quantity_delta>0 AND value_delta_minor>0) OR (movement_type='sale' AND invoice_id=reference_id AND quantity_delta<0 AND value_delta_minor<0)),
  UNIQUE(company_id,ledger_order), UNIQUE(company_id,movement_type,reference_id,product_id,warehouse_id),
  FOREIGN KEY(branch_id,company_id) REFERENCES branches(id,company_id) ON DELETE RESTRICT,
  FOREIGN KEY(warehouse_id,company_id) REFERENCES warehouses(id,company_id) ON DELETE RESTRICT,
  FOREIGN KEY(product_id,company_id) REFERENCES products(id,company_id) ON DELETE RESTRICT,
  FOREIGN KEY(invoice_id,company_id) REFERENCES sales_invoices(id,company_id) ON DELETE RESTRICT,
  FOREIGN KEY(journal_entry_id,company_id,currency_code) REFERENCES journal_entries(id,company_id,currency_code) ON DELETE RESTRICT,
  FOREIGN KEY(created_by,company_id) REFERENCES users(id,company_id) ON DELETE RESTRICT
);
CREATE INDEX stock_balance_index ON stock_ledger(company_id,product_id,warehouse_id,ledger_order);
CREATE TRIGGER stock_insert_valid BEFORE INSERT ON stock_ledger
BEGIN
  SELECT CASE WHEN NOT EXISTS(SELECT 1 FROM products p JOIN warehouses w ON w.company_id=p.company_id WHERE p.id=NEW.product_id AND p.company_id=NEW.company_id AND p.is_stock_item=1 AND w.id=NEW.warehouse_id AND w.branch_id=NEW.branch_id)
    OR NEW.quantity_before<>coalesce((SELECT quantity_after FROM stock_ledger WHERE company_id=NEW.company_id AND product_id=NEW.product_id AND warehouse_id=NEW.warehouse_id ORDER BY ledger_order DESC LIMIT 1),0)
    OR NEW.value_before_minor<>coalesce((SELECT value_after_minor FROM stock_ledger WHERE company_id=NEW.company_id AND product_id=NEW.product_id AND warehouse_id=NEW.warehouse_id ORDER BY ledger_order DESC LIMIT 1),0)
    OR NOT EXISTS(SELECT 1 FROM journal_entries WHERE id=NEW.journal_entry_id AND company_id=NEW.company_id AND posted=1 AND reference_id=NEW.reference_id AND branch_id=NEW.branch_id AND document_date=NEW.document_date AND reference_type=CASE WHEN NEW.movement_type='opening' THEN 'openingBalance' ELSE 'salesInvoice' END)
    OR (NEW.movement_type='opening' AND (EXISTS(SELECT 1 FROM stock_ledger WHERE company_id=NEW.company_id AND movement_type='opening' AND reference_id=NEW.reference_id) OR NEW.value_delta_minor<>(SELECT coalesce(sum(l.debit_minor),0) FROM journal_entry_lines l JOIN accounts a ON a.id=l.account_id AND a.company_id=l.company_id WHERE l.entry_id=NEW.journal_entry_id AND coalesce(a.account_type,a.kind)='inventory')))
    OR (NEW.movement_type='sale' AND NOT EXISTS(SELECT 1 FROM sales_invoice_items i JOIN sales_invoices s ON s.id=i.invoice_id AND s.company_id=i.company_id WHERE i.invoice_id=NEW.invoice_id AND i.company_id=NEW.company_id AND i.product_id=NEW.product_id AND i.warehouse_id=NEW.warehouse_id AND i.quantity=-NEW.quantity_delta AND i.cost_minor=-NEW.value_delta_minor AND s.is_complete=0))
    THEN RAISE(ABORT,'Stock movement/reference/snapshot mismatch') END;
END;
CREATE TRIGGER stock_immutable_update BEFORE UPDATE ON stock_ledger BEGIN SELECT RAISE(ABORT,'Stock ledger is immutable'); END;
CREATE TRIGGER stock_immutable_delete BEFORE DELETE ON stock_ledger BEGIN SELECT RAISE(ABORT,'Stock ledger is immutable'); END;
CREATE TRIGGER invoice_insert_draft BEFORE INSERT ON sales_invoices WHEN NEW.is_complete<>0 BEGIN SELECT RAISE(ABORT,'Finalize invoice after items'); END;
CREATE TRIGGER invoice_finalize BEFORE UPDATE OF is_complete ON sales_invoices WHEN OLD.is_complete=0 AND NEW.is_complete=1
BEGIN
  SELECT CASE WHEN NOT EXISTS(SELECT 1 FROM accounts WHERE id=NEW.debit_account_id AND company_id=NEW.company_id AND coalesce(account_type,kind)=CASE WHEN NEW.is_cash=1 THEN 'cash' ELSE 'receivable' END)
    OR NOT EXISTS(SELECT 1 FROM accounts WHERE id=NEW.sales_account_id AND company_id=NEW.company_id AND coalesce(account_type,kind)='sales')
    OR NOT EXISTS(SELECT 1 FROM accounts WHERE id=NEW.inventory_account_id AND company_id=NEW.company_id AND coalesce(account_type,kind)='inventory')
    OR NOT EXISTS(SELECT 1 FROM accounts WHERE id=NEW.cogs_account_id AND company_id=NEW.company_id AND coalesce(account_type,kind)='costOfSales')
    OR (SELECT count(*) FROM sales_invoice_items WHERE invoice_id=OLD.id)<1
    OR (SELECT sum(total_minor) FROM sales_invoice_items WHERE invoice_id=OLD.id)<>NEW.total_minor
    OR NOT EXISTS(SELECT 1 FROM journal_entries e WHERE e.id=NEW.journal_entry_id AND e.company_id=NEW.company_id AND e.posted=1 AND e.reference_type='salesInvoice' AND e.reference_id=NEW.id AND e.branch_id=NEW.branch_id AND e.document_date=NEW.document_date)
    OR (SELECT coalesce(sum(credit_minor),0) FROM journal_entry_lines WHERE entry_id=NEW.journal_entry_id AND account_id=NEW.sales_account_id)<>NEW.total_minor
    OR (SELECT coalesce(sum(debit_minor),0) FROM journal_entry_lines WHERE entry_id=NEW.journal_entry_id AND account_id=NEW.debit_account_id)<>NEW.total_minor
    OR (SELECT coalesce(sum(cost_minor),0) FROM sales_invoice_items WHERE invoice_id=OLD.id)<>(SELECT coalesce(sum(credit_minor),0) FROM journal_entry_lines WHERE entry_id=NEW.journal_entry_id AND account_id=NEW.inventory_account_id)
    OR (SELECT coalesce(sum(cost_minor),0) FROM sales_invoice_items WHERE invoice_id=OLD.id)<>(SELECT coalesce(sum(debit_minor),0) FROM journal_entry_lines WHERE entry_id=NEW.journal_entry_id AND account_id=NEW.cogs_account_id)
    OR (SELECT count(*) FROM stock_ledger WHERE invoice_id=OLD.id)<>(SELECT count(*) FROM sales_invoice_items WHERE invoice_id=OLD.id AND is_stock_item=1)
    THEN RAISE(ABORT,'Invoice lines/stock/journal mismatch') END;
END;
CREATE TRIGGER invoice_immutable_update BEFORE UPDATE ON sales_invoices WHEN OLD.is_complete=1 BEGIN SELECT RAISE(ABORT,'Posted invoice is immutable'); END;
CREATE TRIGGER invoice_immutable_delete BEFORE DELETE ON sales_invoices WHEN OLD.is_complete=1 BEGIN SELECT RAISE(ABORT,'Posted invoice is immutable'); END;
CREATE TRIGGER invoice_items_insert BEFORE INSERT ON sales_invoice_items
BEGIN SELECT CASE WHEN (SELECT is_complete FROM sales_invoices WHERE id=NEW.invoice_id)=1 OR NOT EXISTS(SELECT 1 FROM products WHERE id=NEW.product_id AND company_id=NEW.company_id AND is_stock_item=NEW.is_stock_item) THEN RAISE(ABORT,'Invoice item is immutable or mismatched') END; END;
CREATE TRIGGER invoice_items_update BEFORE UPDATE ON sales_invoice_items BEGIN SELECT RAISE(ABORT,'Invoice item is immutable'); END;
CREATE TRIGGER invoice_items_delete BEFORE DELETE ON sales_invoice_items WHEN (SELECT is_complete FROM sales_invoices WHERE id=OLD.invoice_id)=1 BEGIN SELECT RAISE(ABORT,'Invoice item is immutable'); END;
INSERT OR IGNORE INTO permissions(code,description) VALUES('sales.view','عرض فواتير البيع'),('sales.create','إنشاء فاتورة بيع');
INSERT OR IGNORE INTO role_permissions(role_id,permission_code)
SELECT DISTINCT ur.role_id,p.code FROM user_roles ur
JOIN audit_logs a ON a.user_id=ur.user_id AND a.company_id=ur.company_id AND a.action='company.bootstrap'
JOIN role_permissions rp ON rp.role_id=ur.role_id AND rp.permission_code='administration.manage'
JOIN permissions p ON p.code IN ('sales.view','sales.create');
INSERT INTO schema_migrations(version,applied_at) VALUES(8,strftime('%Y-%m-%dT%H:%M:%fZ','now'));
