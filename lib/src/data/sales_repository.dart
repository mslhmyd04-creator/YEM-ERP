import 'package:sqlite3/sqlite3.dart';
import '../domain/financial_document.dart';
import '../domain/identifiers.dart';
import '../domain/sales_invoice.dart';

class SalesRepository {
  SalesRepository(this.db);
  final Database db;
  List<SaleProduct> products(String company) => db.select('SELECT p.id,p.name,p.sku,p.is_stock_item,p.is_active,u.name AS unit_name FROM products p JOIN units u ON u.id=p.unit_id AND u.company_id=p.company_id WHERE p.company_id=? ORDER BY p.name,p.id',[company]).map((r)=>SaleProduct(r['id'] as String,r['name'] as String,r['sku'] as String,r['unit_name'] as String,r['is_stock_item']==1,r['is_active']==1)).toList();
  List<SaleWarehouse> warehouses(String company) => db.select('SELECT id,name,branch_id FROM warehouses WHERE company_id=? ORDER BY name,id',[company]).map((r)=>SaleWarehouse(r['id'] as String,r['name'] as String,r['branch_id'] as String)).toList();
  List<FinancialChoice> customers(String company) => db.select('SELECT id,name FROM customers WHERE company_id=? ORDER BY name,id',[company]).map((r)=>FinancialChoice(r['id'] as String,r['name'] as String)).toList();
  List<FinancialChoice> branches(String company) => db.select('SELECT id,name FROM branches WHERE company_id=? ORDER BY name,id',[company]).map((r)=>FinancialChoice(r['id'] as String,r['name'] as String)).toList();
  StockBalance balance(String company,String product,String warehouse) {
    var quantity=BigInt.zero,value=BigInt.zero;
    for(final r in db.select('SELECT quantity_delta,value_delta_minor FROM stock_ledger WHERE company_id=? AND product_id=? AND warehouse_id=?',[company,product,warehouse])){quantity+=BigInt.from(r['quantity_delta'] as int);value+=BigInt.from(r['value_delta_minor'] as int);}
    return StockBalance(quantity,value);
  }
  void movement({required String company,required String user,required String branch,required String product,required String warehouse,required String type,required String reference,required String number,required String date,required String description,required String entry,required int quantity,required int value,required StockBalance before,String? invoice}) {
    final order=db.select('SELECT coalesce(max(ledger_order),0)+1 AS n FROM stock_ledger WHERE company_id=?',[company]).single['n'] as int;
    db.execute('INSERT INTO stock_ledger(id,company_id,branch_id,warehouse_id,product_id,ledger_order,movement_type,reference_id,document_number,document_date,description,invoice_id,quantity_delta,value_delta_minor,quantity_before,quantity_after,value_before_minor,value_after_minor,journal_entry_id,created_by,created_at) VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)',
      [newUuid(),company,branch,warehouse,product,order,type,reference,number,date,description,invoice,quantity,value,before.quantity.toInt(),(before.quantity+BigInt.from(quantity)).toInt(),before.value.toInt(),(before.value+BigInt.from(value)).toInt(),entry,user,DateTime.now().toUtc().toIso8601String()]);
  }
  void insert({required SalesInvoice invoice,required String company,required String branch,required String customer,required String debit,required String sales,required String inventory,required String cogs,required String entry,required String user}) {
    db.execute('INSERT INTO sales_invoices(id,company_id,branch_id,customer_id,document_number,document_date,description,company_name,branch_name,customer_name,total_minor,is_cash,debit_account_id,sales_account_id,inventory_account_id,cogs_account_id,journal_entry_id,created_by) VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)',
      [invoice.id,company,branch,customer,invoice.number,invoice.date,invoice.description,invoice.companyName,invoice.branchName,invoice.customerName,invoice.totalMinor,invoice.isCash?1:0,debit,sales,inventory,cogs,entry,user]);
    for(var i=0;i<invoice.items.length;i++){
      final item=invoice.items[i];
      db.execute('INSERT INTO sales_invoice_items(id,company_id,invoice_id,line_number,product_id,product_name,sku,unit_name,quantity,unit_price_minor,total_minor,cost_minor,is_stock_item,warehouse_id) VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?)',
        [newUuid(),company,invoice.id,i,item.productId,item.name,item.sku,item.unitName,item.quantity,item.unitPriceMinor,item.totalMinor,item.costMinor,item.isStockItem?1:0,item.warehouseId]);
    }
  }
  void complete(String company,String id)=>db.execute('UPDATE sales_invoices SET is_complete=1 WHERE id=? AND company_id=?',[id,company]);
  List<SalesInvoice> invoices(String company)=>db.select('SELECT id FROM sales_invoices WHERE company_id=? AND is_complete=1 ORDER BY document_number DESC',[company]).map((r)=>invoice(company,r['id'] as String)!).toList();
  SalesInvoice? invoice(String company,String id) {
    final rows=db.select('SELECT * FROM sales_invoices WHERE company_id=? AND id=? AND is_complete=1',[company,id]);if(rows.isEmpty){return null;}
    final r=rows.single;
    final items=db.select('SELECT * FROM sales_invoice_items WHERE company_id=? AND invoice_id=? ORDER BY line_number',[company,id]).map((i)=>InvoiceItem(productId:i['product_id'] as String,name:i['product_name'] as String,sku:i['sku'] as String,unitName:i['unit_name'] as String,quantity:i['quantity'] as int,unitPriceMinor:i['unit_price_minor'] as int,totalMinor:i['total_minor'] as int,costMinor:i['cost_minor'] as int,isStockItem:i['is_stock_item']==1,warehouseId:i['warehouse_id'] as String?)).toList();
    return SalesInvoice(id:id,number:r['document_number'] as String,date:r['document_date'] as String,companyName:r['company_name'] as String,branchName:r['branch_name'] as String,customerName:r['customer_name'] as String,description:r['description'] as String,totalMinor:r['total_minor'] as int,isCash:r['is_cash']==1,items:items);
  }
}
