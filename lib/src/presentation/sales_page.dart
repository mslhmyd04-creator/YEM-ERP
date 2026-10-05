import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../application/app_services.dart';
import '../application/local_auth_service.dart';
import '../domain/financial_document.dart';
import '../domain/identifiers.dart';
import '../domain/money.dart';
import '../domain/sales_invoice.dart';

class SalesPage extends StatefulWidget {
  const SalesPage({super.key,required this.services});
  final AppServices services;
  @override
  State<SalesPage> createState()=>_SalesPageState();
}
class _SalesPageState extends State<SalesPage> {
  bool printing=false;
  SalesForm form=SalesForm.invoice;
  String id=newUuid();
  String? branch,customer,cash,product,warehouse,message;
  bool isCash=true;
  final lines=<InvoiceLineDraft>[];
  final units=TextEditingController(text:'1'),price=TextEditingController(),description=TextEditingController();
  final date=TextEditingController(text:DateTime.now().toIso8601String().substring(0,10));
  @override
  void dispose(){units.dispose();price.dispose();description.dispose();date.dispose();super.dispose();}
  void perform(void Function() action){
    try{action();setState(()=>message='تم الحفظ.');}
    on AccessDenied catch(e){setState(()=>message=e.message);}
    on FormatException{setState(()=>message='تحقق من الكمية الصحيحة والسعر بمنزلتين عشريتين كحد أقصى.');}
    catch(_){setState(()=>message='تعذر الحفظ. تحقق من البيانات وأعد المحاولة.');}
  }
  String? chosen(String? value,List<FinancialChoice> choices)=>choices.any((c)=>c.id==value)?value:(choices.isEmpty?null:choices.first.id);
  Widget select(String label,String? value,List<FinancialChoice> choices,void Function(String?) change,{bool enabled=true})=>Padding(padding:const EdgeInsets.only(bottom:12),child:DropdownButtonFormField<String>(key:ValueKey('$label-$value'),initialValue:value,isExpanded:true,decoration:InputDecoration(labelText:label),items:choices.map((c)=>DropdownMenuItem(value:c.id,child:Text(c.name,overflow:TextOverflow.ellipsis))).toList(),onChanged:enabled?(v)=>setState(()=>change(v)):null));
  Widget field(TextEditingController controller,String label,bool enabled)=>Padding(padding:const EdgeInsets.only(bottom:12),child:TextField(controller:controller,enabled:enabled,decoration:InputDecoration(labelText:label,border:const OutlineInputBorder())));
  InvoiceLineDraft draft(String? p,String? w,bool stock){
    if(p==null || (stock && w==null)){throw const AccessDenied('اختر الصنف والمخزن.');}
    var text=units.text.trim();const digits='٠١٢٣٤٥٦٧٨٩';for(var i=0;i<10;i++){text=text.replaceAll(digits[i],'$i');}
    if(!RegExp(r'^\d+$').hasMatch(text)){throw const FormatException('Whole units required.');}
    final count=int.tryParse(text);if(count==null || count<1 || count>1000000000){throw const FormatException('Quantity outside range.');}
    return InvoiceLineDraft(productId:p,warehouseId:stock?w:null,quantity:count,unitPrice:Money.parse(price.text));
  }
  Future<void> printInvoice(SalesInvoice invoice) async {
    final app=widget.services;
    setState(()=>printing=true);
    try{
      final session=app.auth.requirePermission('sales.view');
      await Printing.layoutPdf(name:'${invoice.number}.pdf',onLayout:(_) async {
        final current=app.auth.requirePermission('sales.view');
        if(!identical(session,current)){throw const AccessDenied('تغيرت الجلسة. أعد فتح الفاتورة.');}
        return app.invoicePdf.generate(invoice.id);
      });
    }on AccessDenied catch(e){if(mounted){setState(()=>message=e.message);}}
    catch(_){if(mounted){setState(()=>message='تعذر فتح الطباعة. أعد المحاولة.');}}
    finally{if(mounted){setState(()=>printing=false);}}
  }
  Widget content(){
    final app=widget.services;
    try{
      final branches=app.sales.branches(),customers=app.sales.customers();
      final products=app.sales.products().where((p)=>form==SalesForm.invoice || p.isStockItem).toList();
      final accounts=app.sales.cashAccounts();
      final b=chosen(branch,branches),c=chosen(customer,customers),a=chosen(cash,accounts.map((r)=>FinancialChoice(r.id,r.name)).toList());
      final p=chosen(product,products.map((r)=>FinancialChoice(r.id,'${r.name} (${r.sku})')).toList());
      final selected=p==null?null:products.singleWhere((r)=>r.id==p);
      final warehouses=app.sales.warehouses().where((w)=>w.branchId==b).toList();
      final w=chosen(warehouse,warehouses.map((r)=>FinancialChoice(r.id,r.name)).toList());
      final manager=app.auth.hasPermission('administration.manage'),canPost=app.auth.hasPermission('finance.post');
      final canSave=canPost && (form==SalesForm.stockOpening?manager:app.auth.hasPermission('sales.create'));
      return Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
        if(manager)OutlinedButton(onPressed:()=>perform(app.sales.configureDefaults),child:const Text('إعداد حسابات المبيعات')),
        DropdownButtonFormField<SalesForm>(initialValue:form,decoration:const InputDecoration(labelText:'العملية'),items:[const DropdownMenuItem(value:SalesForm.invoice,child:Text('فاتورة بيع')),DropdownMenuItem(value:SalesForm.stockOpening,enabled:manager,child:const Text('رصيد مخزني افتتاحي'))],onChanged:(v)=>setState((){form=v??SalesForm.invoice;lines.clear();id=newUuid();product=null;message=null;})),
        const SizedBox(height:12),select('الفرع',b,branches,(v){branch=v;warehouse=null;lines.clear();id=newUuid();},enabled:canSave),
        field(date,'التاريخ (YYYY-MM-DD)',canSave),field(description,'الوصف',canSave),
        if(form==SalesForm.invoice)...[
          select('العميل',c,customers,(v)=>customer=v,enabled:canSave),
          DropdownButtonFormField<bool>(initialValue:isCash,decoration:const InputDecoration(labelText:'طريقة الدفع'),items:const[DropdownMenuItem(value:true,child:Text('نقدي')),DropdownMenuItem(value:false,child:Text('آجل'))],onChanged:canSave?(v)=>setState(()=>isCash=v??true):null),
          const SizedBox(height:12),if(isCash)select('الصندوق',a,accounts.map((r)=>FinancialChoice(r.id,r.name)).toList(),(v)=>cash=v,enabled:canSave),
        ],
        select('الصنف',p,products.map((r)=>FinancialChoice(r.id,'${r.name} (${r.sku})')).toList(),(v)=>product=v,enabled:canSave),
        if(selected?.isStockItem==true)...[
          select('المخزن',w,warehouses.map((r)=>FinancialChoice(r.id,r.name)).toList(),(v)=>warehouse=v,enabled:canSave),
          if(w!=null)Text('الكمية المتاحة: ${app.inventory.balance(p!,w).quantity}'),
        ],
        field(units,'الكمية (وحدات كاملة)',canSave),field(price,form==SalesForm.stockOpening?'تكلفة الوحدة (YER)':'سعر الوحدة (YER)',canSave),
        if(form==SalesForm.invoice)...[
          OutlinedButton(onPressed:canSave?()=>perform((){lines.add(draft(p,w,selected?.isStockItem??false));}):null,child:const Text('إضافة بند')),
          for(var i=0;i<lines.length;i++)Card(child:ListTile(title:Text('${products.where((p)=>p.id==lines[i].productId).firstOrNull?.name??lines[i].productId}: ${lines[i].quantity} × ${lines[i].unitPrice}'),trailing:IconButton(tooltip:'حذف البند',onPressed:canSave?()=>setState(()=>lines.removeAt(i)):null,icon:const Icon(Icons.delete_outline)))),
          const Text('الفاتورة الحالية دون تفصيل ضريبي. الكميات وحدات كاملة.'),
        ],
        FilledButton(onPressed:canSave?()=>perform((){
          if(b==null){throw const AccessDenied('اختر الفرع.');}
          if(form==SalesForm.stockOpening){
            final item=draft(p,w,true);
            app.sales.opening(id:id,branch:b,product:item.productId,warehouse:item.warehouseId!,units:item.quantity,unitCost:item.unitPrice,date:date.text.trim(),description:description.text);
          }else{
            if(c==null){throw const AccessDenied('اختر العميل.');}
            app.sales.create(id:id,branch:b,customer:c,isCash:isCash,cash:isCash?a:null,date:date.text.trim(),description:description.text,lines:List.of(lines));
          }
          lines.clear();id=newUuid();price.clear();description.clear();
        }):null,child:const Text('حفظ وترحيل')),
        const SizedBox(height:24),Text('فواتير البيع',style:Theme.of(context).textTheme.titleMedium),
        for(final invoice in app.sales.invoices())Card(child:ListTile(title:Text('${invoice.number}: ${invoice.customerName}'),subtitle:Text('${Money(invoice.totalMinor)} YER — ${invoice.isCash?'نقدي':'آجل'}'),trailing:IconButton(tooltip:'طباعة PDF',onPressed:printing?null:()=>printInvoice(invoice),icon:const Icon(Icons.print_outlined)))),
      ]);
    }on AccessDenied catch(e){return Text(e.message);}
  }
  @override
  Widget build(BuildContext context)=>Directionality(textDirection:TextDirection.rtl,child:Scaffold(appBar:AppBar(title:const Text('فواتير البيع والمخزون')),body:Align(alignment:Alignment.topCenter,child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:720),child:SingleChildScrollView(padding:const EdgeInsets.all(24),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[if(message!=null)...[Text(message!,key:const Key('sales-status')),const SizedBox(height:12)],content()]))))));
}
