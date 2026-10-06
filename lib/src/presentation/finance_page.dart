import 'package:flutter/material.dart';
import '../application/app_services.dart';
import '../application/local_auth_service.dart';
import '../domain/financial_document.dart';
import '../domain/identifiers.dart';
import '../domain/money.dart';

class FinancePage extends StatefulWidget {
  const FinancePage({super.key,required this.services});
  final AppServices services;
  @override
  State<FinancePage> createState()=>_FinancePageState();
}
class _FinancePageState extends State<FinancePage> {
  FinanceForm form=FinanceForm.expense;
  bool fromCustody=false;
  String id=newUuid();
  String? branch,cash,equity,employee,category,custody,message;
  final amount=TextEditingController();
  final date=TextEditingController(text: DateTime.now().toIso8601String().substring(0,10));
  final description=TextEditingController();
  @override
  void dispose(){amount.dispose();date.dispose();description.dispose();super.dispose();}
  void perform(void Function() action,{bool reset=false}) {
    try {
      action();
      setState((){message='تم الحفظ.';if(reset){amount.clear();description.clear();id=newUuid();}});
    } on AccessDenied catch(error){setState(()=>message=error.message);}
    on FormatException {setState(()=>message='أدخل مبلغًا صحيحًا بمنزلتين عشريتين كحد أقصى.');}
    catch(_){setState(()=>message='تعذر الحفظ. تحقق من البيانات وأعد المحاولة.');}
  }
  String? chosen(String? value,List<FinancialChoice> options) => options.any((r)=>r.id==value)?value:(options.isEmpty?null:options.first.id);
  Widget select(String label,String? value,List<FinancialChoice> options,void Function(String?) change,{bool enabled=true}) => Padding(
    padding: const EdgeInsets.only(bottom:12),child: DropdownButtonFormField<String>(key: ValueKey('$label-$value'),initialValue: value,
      decoration: InputDecoration(labelText: label),items: options.map((r)=>DropdownMenuItem(value:r.id,child:Text(r.name))).toList(),onChanged:enabled?(v)=>setState(()=>change(v)):null));
  Widget field(TextEditingController controller,String label,bool enabled) => Padding(padding:const EdgeInsets.only(bottom:12),child:TextField(controller:controller,enabled:enabled,decoration:InputDecoration(labelText:label,border:const OutlineInputBorder())));
  String label(FinanceForm value) => switch(value){FinanceForm.expense=>'مصروف',FinanceForm.custody=>'عهدة جديدة',FinanceForm.opening=>'رصيد افتتاحي للصندوق'};
  Widget content() {
    final app=widget.services;
    try {
      final branches=app.finance.branches(),employees=app.finance.employees();
      final cashAccounts=app.finance.cashAccounts(),equityAccounts=app.finance.equityAccounts();
      final categories=app.finance.categories(),custodies=app.finance.custodies(),expenses=app.finance.expenses();
      final b=chosen(branch,branches),c=chosen(cash,cashAccounts.map((r)=>FinancialChoice(r.id,r.name)).toList());
      final e=chosen(equity,equityAccounts.map((r)=>FinancialChoice(r.id,r.name)).toList());
      final u=chosen(employee,employees),cat=chosen(category,categories.map((r)=>FinancialChoice(r.id,r.name)).toList());
      final hold=chosen(custody,custodies.map((r)=>FinancialChoice(r.id,'${r.number}: ${r.description}')).toList());
      final manager=app.auth.hasPermission('administration.manage'),canPost=app.auth.hasPermission('finance.post');
      return Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
        if(cashAccounts.isEmpty || categories.isEmpty || equityAccounts.isEmpty) ...[
          const Text('يلزم إعداد الصندوق وحسابات المصروفات قبل التسجيل.'),
          if(manager) FilledButton(onPressed:()=>perform(app.finance.configureDefaults),child:const Text('إعداد الحسابات والفئات')),
        ],
        DropdownButtonFormField<FinanceForm>(initialValue:form,decoration:const InputDecoration(labelText:'العملية'),
          items:FinanceForm.values.map((f)=>DropdownMenuItem(value:f,enabled:f!=FinanceForm.opening || manager,child:Text(label(f)))).toList(),
          onChanged:(v)=>setState((){form=v??FinanceForm.expense;message=null;id=newUuid();amount.clear();description.clear();})),
        const SizedBox(height:12),
        select('الفرع',b,branches,(v)=>branch=v,enabled:canPost),
        field(date,'التاريخ (YYYY-MM-DD)',canPost),field(amount,'المبلغ (YER)',canPost),field(description,'الوصف',canPost),
        if(form==FinanceForm.custody)select('صاحب العهدة',u,employees,(v)=>employee=v,enabled:canPost),
        if(form==FinanceForm.expense)...[
          select('فئة المصروف',cat,categories.map((r)=>FinancialChoice(r.id,r.name)).toList(),(v)=>category=v,enabled:canPost),
          DropdownButtonFormField<bool>(initialValue:fromCustody,decoration:const InputDecoration(labelText:'مصدر الدفع'),items:const[DropdownMenuItem(value:false,child:Text('الصندوق')),DropdownMenuItem(value:true,child:Text('العهدة'))],onChanged:canPost?(v)=>setState(()=>fromCustody=v??false):null),
          const SizedBox(height:12),
          const Text('تفصيل ضريبة المصروف غير متاح حاليًا.'),
        ],
        if(form!=FinanceForm.expense || !fromCustody)select('الصندوق',c,cashAccounts.map((r)=>FinancialChoice(r.id,r.name)).toList(),(v)=>cash=v,enabled:canPost)
        else select('العهدة',hold,custodies.map((r)=>FinancialChoice(r.id,'${r.number}: ${r.description}')).toList(),(v)=>custody=v,enabled:canPost),
        if(form==FinanceForm.opening)select('مقابل الرصيد الافتتاحي',e,equityAccounts.map((r)=>FinancialChoice(r.id,r.name)).toList(),(v)=>equity=v,enabled:canPost),
        FilledButton(onPressed:!canPost || (form==FinanceForm.opening && !manager)?null:()=>perform((){
          if(b==null){throw const AccessDenied('اختر الفرع.');}
          final value=Money.parse(amount.text);
          if(form==FinanceForm.opening){
            if(c==null || e==null){throw const AccessDenied('اختر الحسابات.');}
            app.finance.opening(id:id,branch:b,cash:c,equity:e,amount:value,date:date.text.trim(),description:description.text);
          }else if(form==FinanceForm.custody){
            if(c==null || u==null){throw const AccessDenied('اختر الصندوق وصاحب العهدة.');}
            app.finance.issue(id:id,branch:b,cash:c,employee:u,amount:value,date:date.text.trim(),description:description.text);
          }else{
            if(cat==null || (fromCustody?hold==null:c==null)){throw const AccessDenied('اختر الفئة ومصدر الدفع.');}
            app.finance.expense(id:id,branch:b,category:cat,amount:value,date:date.text.trim(),description:description.text,cash:fromCustody?null:c,custody:fromCustody?hold:null);
          }
        },reset:true),child:const Text('حفظ وترحيل')),
        const SizedBox(height:24),
        Text('أرصدة الصناديق',style:Theme.of(context).textTheme.titleMedium),
        for(final item in cashAccounts)Text('${item.name}: ${formatLedgerBalance(app.posting.balance(item.id))} YER'),
        const SizedBox(height:16),Text('العهد',style:Theme.of(context).textTheme.titleMedium),
        for(final item in custodies)Card(child:ListTile(title:Text('${item.number}: ${item.description}'),subtitle:Text('المستلم ${Money(item.issuedMinor)} — المتبقي ${formatLedgerBalance(app.finance.custodyBalance(item.id))} YER'))),
        const SizedBox(height:16),Text('المصروفات',style:Theme.of(context).textTheme.titleMedium),
        for(final item in expenses)Card(child:ListTile(title:Text('${item.number}: ${item.description}'),subtitle:Text('${Money(item.amountMinor)} YER'))),
      ]);
    } on AccessDenied catch(error){return Text(error.message);}
  }
  @override
  Widget build(BuildContext context)=>Directionality(textDirection:TextDirection.rtl,child:Scaffold(appBar:AppBar(title:const Text('المصروفات والعهد')),
    body:Align(alignment:Alignment.topCenter,child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:720),child:SingleChildScrollView(padding:const EdgeInsets.all(24),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
      if(message!=null)...[Text(message!,key:const Key('finance-status')),const SizedBox(height:12)],content(),
    ]))))));
}
