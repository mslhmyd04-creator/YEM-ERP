enum MasterKind {
  branch('branches', 'الفروع'),
  category('product_categories', 'الفئات'),
  unit('units', 'الوحدات'),
  customer('customers', 'العملاء'),
  supplier('suppliers', 'الموردون'),
  warehouse('warehouses', 'المخازن');

  const MasterKind(this.table, this.label);
  final String table;
  final String label;
  bool get hasTimestamp => hasPhone || this == branch;
  bool get hasPhone => this == customer || this == supplier;
}

class MasterRecord {
  const MasterRecord({required this.id, required this.name, this.phone, this.branchId});
  final String id;
  final String name;
  final String? phone;
  final String? branchId;
}
