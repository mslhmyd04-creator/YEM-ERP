import 'dart:convert';
import '../data/sales_repository.dart';
import '../domain/financial_document.dart';
import '../domain/journal.dart';
import '../domain/money.dart';
import '../domain/sales_invoice.dart';
import 'financial_service.dart';
import 'inventory_engine.dart';
import 'local_auth_service.dart';
import 'posting_engine.dart';

class SalesService {
  SalesService(this.auth,this.posting,this.finance,this.inventory,this.repository);
  final LocalAuthService auth;
  final PostingEngine posting;
  final FinancialService finance;
  final InventoryEngine inventory;
  final SalesRepository repository;
  String get _company=>auth.requirePermission('sales.view').companyId;
  List<SaleProduct> products()=>repository.products(_company).where((p)=>p.isActive).toList();
  List<SaleWarehouse> warehouses()=>repository.warehouses(_company);
  List<FinancialChoice> customers()=>repository.customers(_company);
  List<FinancialChoice> branches()=>repository.branches(_company);
  List<LedgerAccount> cashAccounts()=>posting.repository.accounts(_company).where((a)=>a.kind==AccountKind.cash).toList();
  List<SalesInvoice> invoices()=>repository.invoices(_company);
  SalesInvoice invoice(String id){final value=repository.invoice(_company,id);if(value==null){throw const AccessDenied('الفاتورة غير متاحة لهذه المؤسسة.');}return value;}
  void configureDefaults(){
    final session=auth.requirePermission('administration.manage');finance.configureDefaults();
    for(final item in [(code:'phase0.receivable',name:'العملاء',kind:AccountKind.receivable),(code:'phase0.sales',name:'إيرادات المبيعات',kind:AccountKind.sales),(code:'phase0.inventory',name:'المخزون',kind:AccountKind.inventory),(code:'phase0.cogs',name:'تكلفة المبيعات',kind:AccountKind.costOfSales)]){
      final existing=posting.repository.accounts(session.companyId).where((a)=>a.code==item.code).toList();
      if(existing.isEmpty){posting.createAccount(code:item.code,name:item.name,kind:item.kind);}else if(existing.single.kind!=item.kind){throw const AccessDenied('نوع الحساب الافتراضي غير صحيح.');}
    }
  }
  String _account(String company,String code,AccountKind kind){
    final rows=posting.repository.accounts(company).where((a)=>a.code==code && a.kind==kind).toList();
    if(rows.isEmpty){throw const AccessDenied('هيئ حسابات المبيعات أولًا.');}return rows.single.id;
  }
  String opening({required String id,required String branch,required String product,required String warehouse,required int units,required Money unitCost,required String date,required String description}){
    final company=auth.requirePermission('administration.manage').companyId;
    return inventory.opening(id:id,branch:branch,product:product,warehouse:warehouse,units:units,unitCost:unitCost,inventory:_account(company,'phase0.inventory',AccountKind.inventory),equity:_account(company,'phase0.equity',AccountKind.equity),date:date,description:description);
  }
  String create({required String id,required String branch,required String customer,required bool isCash,required String date,required String description,required List<InvoiceLineDraft> lines,String? cash}) {
    final session=auth.requirePermission('sales.create');
    if(lines.isEmpty || lines.length>50 || (isCash && cash==null) || (!isCash && cash!=null)){throw const AccessDenied('تحقق من بنود الفاتورة وطريقة الدفع.');}
    final company=session.companyId;
    final debit=isCash?cash!:_account(company,'phase0.receivable',AccountKind.receivable);
    final revenue=_account(company,'phase0.sales',AccountKind.sales),stock=_account(company,'phase0.inventory',AccountKind.inventory),cogs=_account(company,'phase0.cogs',AccountKind.costOfSales);
    final existing=repository.invoice(company,id);
    final sorted=List<InvoiceLineDraft>.of(lines)..sort((a,b){final c=a.productId.compareTo(b.productId);return c==0?(a.warehouseId??'').compareTo(b.warehouseId??''):c;});
    final keys=<String>{},items=<InvoiceItem>[],snapshots=<String,StockBalance>{};
    var total=BigInt.zero,cost=BigInt.zero;
    for(final line in sorted){
      InventoryEngine.quantity(line.quantity);
      final key='${line.productId}/${line.warehouseId??''}';
      if(line.unitPrice.minor==0 || !keys.add(key)){throw const AccessDenied('السعر موجب ولا يسمح بتكرار الصنف في المخزن نفسه.');}
      final matches=repository.products(company).where((p)=>p.id==line.productId).toList();
      if(matches.isEmpty){throw const AccessDenied('الصنف غير متاح لهذه المؤسسة.');}
      final product=matches.single;
      if(product.isStockItem==(line.warehouseId==null)){throw const AccessDenied('اختر مخزنًا للصنف المخزني فقط.');}
      var lineCost=0;
      if(product.isStockItem){
        final oldItems=existing?.items.where((i)=>i.productId==line.productId && i.warehouseId==line.warehouseId).toList();
        if(oldItems!=null && oldItems.isNotEmpty){lineCost=oldItems.single.costMinor;}else{
          final before=repository.balance(company,line.productId,line.warehouseId!);snapshots[key]=before;
          lineCost=inventory.cost(before,line.quantity);
        }
      }
      final lineTotal=InventoryEngine.bounded(BigInt.from(line.quantity)*BigInt.from(line.unitPrice.minor));
      total+=BigInt.from(lineTotal);cost+=BigInt.from(lineCost);
      items.add(InvoiceItem(productId:product.id,name:product.name,sku:product.sku,unitName:product.unitName,quantity:line.quantity,unitPriceMinor:line.unitPrice.minor,totalMinor:lineTotal,costMinor:lineCost,isStockItem:product.isStockItem,warehouseId:line.warehouseId));
    }
    final amount=Money(InventoryEngine.bounded(total)),costAmount=Money(InventoryEngine.bounded(cost));
    final journal=[JournalLine(accountId:debit,debit:amount,credit:Money(0)),JournalLine(accountId:revenue,debit:Money(0),credit:amount),if(costAmount.minor>0)...[JournalLine(accountId:cogs,debit:costAmount,credit:Money(0)),JournalLine(accountId:stock,debit:Money(0),credit:costAmount)]];
    posting.post(PostingRequest(reference:FinancialReference.salesInvoice,referenceId:id,branchId:branch,date:date,description:description,lines:journal),
      businessPayload:jsonEncode([customer,isCash,cash,sorted.map((l)=>[l.productId,l.warehouseId,l.quantity,l.unitPrice.minor]).toList()]),prepare:(){
        auth.requirePermission('sales.create');
        if(!repository.customers(company).any((c)=>c.id==customer) || !posting.repository.accounts(company).any((a)=>a.id==debit && a.kind==(isCash?AccountKind.cash:AccountKind.receivable))){throw const AccessDenied('العميل أو حساب الدفع غير متاح.');}
        for(final item in items){
          if(!repository.products(company).any((p)=>p.id==item.productId && p.isActive)){throw const AccessDenied('الصنف مؤرشف.');}
          if(item.isStockItem){inventory.recheck(company,item.productId,item.warehouseId!,branch,snapshots['${item.productId}/${item.warehouseId}']!);}
        }
      },persist:(entry){
        final number=posting.repository.nextNumber(company,kind:'salesInvoice',prefix:'SI');
        final value=SalesInvoice(id:id,number:number,date:date,companyName:auth.db.select('SELECT name FROM companies WHERE id=?',[company]).single['name'] as String,branchName:repository.branches(company).singleWhere((b)=>b.id==branch).name,customerName:repository.customers(company).singleWhere((c)=>c.id==customer).name,description:description.trim(),totalMinor:amount.minor,isCash:isCash,items:items);
        repository.insert(invoice:value,company:company,branch:branch,customer:customer,debit:debit,sales:revenue,inventory:stock,cogs:cogs,entry:entry,user:session.userId);
        for(final item in items.where((i)=>i.isStockItem)){
          inventory.record(company:company,user:session.userId,branch:branch,product:item.productId,warehouse:item.warehouseId!,type:'sale',reference:id,number:number,date:date,description:description.trim(),entry:entry,units:-item.quantity,value:-item.costMinor,before:snapshots['${item.productId}/${item.warehouseId}']!,invoice:id);
        }
        repository.complete(company,id);
        auth.audit(companyId:company,userId:session.userId,action:'sales.post',entity:'sales_invoices',recordId:id);
      });
    return id;
  }
}
