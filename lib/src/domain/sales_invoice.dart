import 'money.dart';

class SaleProduct {
  const SaleProduct(this.id,this.name,this.sku,this.unitName,this.isStockItem,this.isActive);
  final String id,name,sku,unitName;
  final bool isStockItem,isActive;
}
class SaleWarehouse {
  const SaleWarehouse(this.id,this.name,this.branchId);
  final String id,name,branchId;
}
class StockBalance {
  const StockBalance(this.quantity,this.value);
  final BigInt quantity,value;
}
class InvoiceLineDraft {
  const InvoiceLineDraft({required this.productId,required this.quantity,required this.unitPrice,this.warehouseId});
  final String productId;
  final int quantity;
  final Money unitPrice;
  final String? warehouseId;
}
class InvoiceItem {
  const InvoiceItem({required this.productId,required this.name,required this.sku,required this.unitName,required this.quantity,required this.unitPriceMinor,required this.totalMinor,required this.costMinor,required this.isStockItem,this.warehouseId});
  final String productId,name,sku,unitName;
  final int quantity,unitPriceMinor,totalMinor,costMinor;
  final bool isStockItem;
  final String? warehouseId;
}
class SalesInvoice {
  SalesInvoice({required this.id,required this.number,required this.date,required this.companyName,required this.branchName,required this.customerName,required this.description,required this.totalMinor,required this.isCash,required List<InvoiceItem> items}):items=List.unmodifiable(items);
  final String id,number,date,companyName,branchName,customerName,description;
  final int totalMinor;
  final bool isCash;
  final List<InvoiceItem> items;
}
enum SalesForm { invoice, stockOpening }
