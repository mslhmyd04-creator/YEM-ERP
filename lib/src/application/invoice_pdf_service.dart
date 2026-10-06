import 'dart:typed_data';
import '../domain/sales_invoice.dart';
import '../infrastructure/invoice_pdf_renderer.dart';
import 'local_auth_service.dart';
import 'sales_service.dart';

class InvoicePdfService {
  InvoicePdfService(this.auth,this.sales,{Future<Uint8List> Function(SalesInvoice)? render}):_render=render??InvoicePdfRenderer().render;
  final LocalAuthService auth;
  final SalesService sales;
  final Future<Uint8List> Function(SalesInvoice) _render;
  Future<Uint8List> generate(String id) async {
    final session=auth.requirePermission('sales.view');
    final invoice=sales.invoice(id);
    final bytes=await _render(invoice);
    final current=auth.requirePermission('sales.view');
    if(!identical(session,current)){throw const AccessDenied('تغيرت الجلسة. أعد فتح الفاتورة.');}
    return bytes;
  }
}
