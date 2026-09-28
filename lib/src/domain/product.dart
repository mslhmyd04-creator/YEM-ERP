/// A product identity is separate from its displayed SKU and stock quantity.
/// Stock balances will be calculated from the stock ledger in a later task.
class Product {
  Product({required this.id, required this.name, required this.sku}) {
    if (id.trim().isEmpty || name.trim().isEmpty || sku.trim().isEmpty) {
      throw ArgumentError('Product id, name and SKU are required.');
    }
  }

  final String id;
  final String name;
  final String sku;
}
