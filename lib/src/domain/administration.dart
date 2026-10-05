import 'master_record.dart';

class PermissionOption {
  const PermissionOption(this.code, this.label);
  final String code;
  final String label;
  static List<PermissionOption> get all => [
    const PermissionOption('administration.manage', 'إدارة المستخدمين والأدوار'),
    const PermissionOption('products.view', 'عرض الأصناف'),
    const PermissionOption('products.create', 'إضافة الأصناف'),
    const PermissionOption('products.archive', 'أرشفة الأصناف'),
    for (final kind in MasterKind.values) ...[
      PermissionOption('${kind.table}.view', 'عرض ${kind.label}'),
      PermissionOption('${kind.table}.create', 'إضافة ${kind.label}'),
      PermissionOption('${kind.table}.update', 'تعديل ${kind.label}'),
    ],
  ];
}

class RoleRecord {
  RoleRecord(this.id, this.name, Set<String> permissions) : permissions = Set.unmodifiable(permissions);
  final String id;
  final String name;
  final Set<String> permissions;
}

class UserRecord {
  UserRecord(this.id, this.username, this.branchId, this.isActive, Set<String> roleIds) : roleIds = Set.unmodifiable(roleIds);
  final String id;
  final String username;
  final String branchId;
  final bool isActive;
  final Set<String> roleIds;
}
