import 'dart:convert';
import '../data/sales_repository.dart';
import '../domain/journal.dart';
import '../domain/money.dart';
import '../domain/sales_invoice.dart';
import 'local_auth_service.dart';
import 'posting_engine.dart';

/// Stock changes are composed into the PostingEngine transaction, never UI writes.
class InventoryEngine {
  InventoryEngine(this.auth,this.posting,this.repository);
  final LocalAuthService auth;
  final PostingEngine posting;
  final SalesRepository repository;
  static int bounded(BigInt value) {
    if(value< BigInt.zero || value>BigInt.from(Money.maximumMinor)){throw const AccessDenied('القيمة تتجاوز الحد المسموح.');}
    return value.toInt();
  }
  static void quantity(int value) {if(value<1 || value>1000000000){throw const AccessDenied('الكمية عدد صحيح موجب حتى مليار وحدة.');}}
  StockBalance balance(String product,String warehouse) {
    final company=auth.requirePermission('sales.view').companyId;
    validate(company,product,warehouse,null,active:false);
    return repository.balance(company,product,warehouse);
  }
  void validate(String company,String product,String warehouse,String? branch,{bool active=true}) {
    if(!repository.products(company).any((p)=>p.id==product && p.isStockItem && (!active || p.isActive)) || !repository.warehouses(company).any((w)=>w.id==warehouse && (branch==null || w.branchId==branch))){throw const AccessDenied('الصنف المخزني أو المخزن غير متاح لهذا الفرع.');}
  }
  int cost(StockBalance before,int units) {
    quantity(units);final count=BigInt.from(units);
    if(before.quantity<count){throw const AccessDenied('المخزون المتاح لا يكفي.');}
    return bounded(count==before.quantity?before.value:(before.value*count+before.quantity~/BigInt.two)~/before.quantity);
  }
  void recheck(String company,String product,String warehouse,String branch,StockBalance before) {
    validate(company,product,warehouse,branch);
    final current=repository.balance(company,product,warehouse);
    if(current.quantity!=before.quantity || current.value!=before.value){throw const AccessDenied('تغير المخزون. أعد المحاولة لحساب التكلفة الحالية.');}
  }
  void record({required String company,required String user,required String branch,required String product,required String warehouse,required String type,required String reference,required String number,required String date,required String description,required String entry,required int units,required int value,required StockBalance before,String? invoice}) {
    repository.movement(company:company,user:user,branch:branch,product:product,warehouse:warehouse,type:type,reference:reference,number:number,date:date,description:description,entry:entry,quantity:units,value:value,before:before,invoice:invoice);
  }
  String opening({required String id,required String branch,required String product,required String warehouse,required int units,required Money unitCost,required String inventory,required String equity,required String date,required String description}) {
    final session=auth.requirePermission('administration.manage');quantity(units);
    if(unitCost.minor==0){throw const AccessDenied('تكلفة الوحدة يجب أن تكون موجبة.');}
    final value=Money(bounded(BigInt.from(units)*BigInt.from(unitCost.minor)));
    final before=repository.balance(session.companyId,product,warehouse);
    posting.post(PostingRequest(reference:FinancialReference.openingBalance,referenceId:id,branchId:branch,date:date,description:description,lines:[JournalLine(accountId:inventory,debit:value,credit:Money(0)),JournalLine(accountId:equity,debit:Money(0),credit:value)]),
      businessPayload:jsonEncode(['stock',product,warehouse,units,unitCost.minor]),prepare:(){
        auth.requirePermission('administration.manage');recheck(session.companyId,product,warehouse,branch,before);
        final accounts=posting.repository.accounts(session.companyId);
        if(!accounts.any((a)=>a.id==inventory && a.kind==AccountKind.inventory) || !accounts.any((a)=>a.id==equity && a.kind==AccountKind.equity)){throw const AccessDenied('تحقق من حساب المخزون والرصيد الافتتاحي.');}
        if(before.quantity+BigInt.from(units)>BigInt.from(1000000000)){throw const AccessDenied('رصيد الكمية يتجاوز الحد المسموح.');}
        bounded(before.value+BigInt.from(value.minor));
      },persist:(entry){
        record(company:session.companyId,user:session.userId,branch:branch,product:product,warehouse:warehouse,type:'opening',reference:id,number:posting.repository.nextNumber(session.companyId,kind:'stockOpening',prefix:'ST'),date:date,description:description.trim(),entry:entry,units:units,value:value.minor,before:before);
        auth.audit(companyId:session.companyId,userId:session.userId,action:'stock.opening',entity:'stock_ledger',recordId:id);
      });
    return id;
  }
}
