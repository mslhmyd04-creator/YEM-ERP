/// A product identity is separate from its displayed SKU and stock quantity.
/// Stock balances will be calculated from the stock ledger in a later task.
class Product {
  Product({
    required this.id,
    required this.companyId,
    required this.unitId,
    required this.name,
    required this.sku,
    required this.isActive,
    this.categoryId,
    this.isStockItem = true,
  }) {
    if ([id, companyId, unitId, name, sku].any((value) => value.trim().isEmpty)) {
      throw ArgumentError('Product identity, company, unit, name and SKU are required.');
    }
  }

  final String id;
  final String companyId;
  final String unitId;
  final String name;
  final String sku;
  final bool isActive;
  final bool isStockItem;
  final String? categoryId;
}
