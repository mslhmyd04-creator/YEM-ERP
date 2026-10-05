import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../domain/money.dart';
import '../domain/sales_invoice.dart';

class InvoicePdfRenderer {
  Future<Uint8List> render(SalesInvoice invoice) async {
    final font=pw.Font.ttf(await rootBundle.load('assets/fonts/Amiri-Regular.ttf'));
    final doc=pw.Document(title:'${invoice.number} - YEM ERP',author:invoice.companyName);
    pw.Widget cell(String text,{bool numeric=false,bool heading=false})=>pw.Padding(padding:const pw.EdgeInsets.symmetric(horizontal:6,vertical:7),child:pw.Text(text,textDirection:numeric?pw.TextDirection.ltr:pw.TextDirection.rtl,textAlign:numeric?pw.TextAlign.center:pw.TextAlign.right,style:pw.TextStyle(fontSize:heading?11:(numeric && text.length>8?8:10),color:heading?PdfColors.white:PdfColors.blueGrey900)));
    doc.addPage(pw.MultiPage(pageFormat:PdfPageFormat.a4,margin:const pw.EdgeInsets.all(36),theme:pw.ThemeData.withFont(base:font,bold:font),textDirection:pw.TextDirection.rtl,
      header:(context)=>pw.Column(crossAxisAlignment:pw.CrossAxisAlignment.stretch,children:[
        pw.Row(mainAxisAlignment:pw.MainAxisAlignment.spaceBetween,children:[pw.Expanded(child:pw.Text(invoice.companyName,textAlign:pw.TextAlign.right,style:const pw.TextStyle(fontSize:20))),pw.SizedBox(width:12),pw.Text('YEM ERP',textDirection:pw.TextDirection.ltr,style:const pw.TextStyle(fontSize:15,color:PdfColors.blueGrey700))]),
        pw.SizedBox(height:5),pw.Divider(color:PdfColors.blueGrey200),pw.SizedBox(height:8),
      ]),
      footer:(context)=>pw.Column(children:[pw.Divider(color:PdfColors.blueGrey200),pw.Row(mainAxisAlignment:pw.MainAxisAlignment.center,children:[pw.Text('صفحة',style:const pw.TextStyle(fontSize:10)),pw.SizedBox(width:5),pw.Text('${context.pageNumber} / ${context.pagesCount}',textDirection:pw.TextDirection.ltr,style:const pw.TextStyle(fontSize:10))])]),
      build:(context)=>[
        pw.Text('فاتورة بيع',style:const pw.TextStyle(fontSize:22)),pw.SizedBox(height:10),
        pw.Row(mainAxisAlignment:pw.MainAxisAlignment.spaceBetween,children:[pw.Text('الرقم'),pw.Text(invoice.number,textDirection:pw.TextDirection.ltr)]),
        pw.Row(mainAxisAlignment:pw.MainAxisAlignment.spaceBetween,children:[pw.Text('التاريخ'),pw.Text(invoice.date,textDirection:pw.TextDirection.ltr)]),
        pw.Text('الفرع: ${invoice.branchName}'),pw.Text('العميل: ${invoice.customerName}'),pw.Text('طريقة الدفع: ${invoice.isCash?'نقدي':'آجل'}'),pw.SizedBox(height:16),
        pw.Table(border:pw.TableBorder.all(color:PdfColors.blueGrey200,width:0.5),columnWidths:const{0:pw.FlexColumnWidth(1.2),1:pw.FlexColumnWidth(1.1),2:pw.FlexColumnWidth(0.7),3:pw.FlexColumnWidth(0.8),4:pw.FlexColumnWidth(2.5)},children:[
          pw.TableRow(repeat:true,decoration:const pw.BoxDecoration(color:PdfColors.blueGrey800),children:[cell('الإجمالي',heading:true),cell('سعر الوحدة',heading:true),cell('الكمية',heading:true),cell('الوحدة',heading:true),cell('الصنف / الرمز',heading:true)]),
          for(final item in invoice.items)pw.TableRow(children:[cell(Money(item.totalMinor).toString(),numeric:true),cell(Money(item.unitPriceMinor).toString(),numeric:true),cell('${item.quantity}',numeric:true),cell(item.unitName),pw.Padding(padding:const pw.EdgeInsets.all(7),child:pw.Column(crossAxisAlignment:pw.CrossAxisAlignment.end,children:[pw.Text(item.name,textDirection:pw.TextDirection.rtl,style:const pw.TextStyle(fontSize:11)),pw.Text(item.sku,textDirection:pw.TextDirection.ltr,style:const pw.TextStyle(fontSize:9,color:PdfColors.blueGrey500))]))]),
        ]),
        pw.Container(child:pw.Column(crossAxisAlignment:pw.CrossAxisAlignment.stretch,children:[pw.SizedBox(height:16),pw.Container(padding:const pw.EdgeInsets.all(12),color:PdfColors.blueGrey50,child:pw.Row(mainAxisAlignment:pw.MainAxisAlignment.spaceBetween,children:[pw.Text('الإجمالي المستحق',style:const pw.TextStyle(fontSize:16)),pw.Text('${Money(invoice.totalMinor)} YER',textDirection:pw.TextDirection.ltr,style:const pw.TextStyle(fontSize:16))])),
        pw.SizedBox(height:14),pw.Text('الوصف: ${invoice.description}'),pw.SizedBox(height:12),pw.Text('المبالغ بالريال اليمني. هذه الفاتورة دون تفصيل ضريبي.',style:const pw.TextStyle(fontSize:10,color:PdfColors.blueGrey600)),
        ])),
      ]));
    return doc.save();
  }
}
