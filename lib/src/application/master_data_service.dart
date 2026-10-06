import '../data/master_repository.dart';
import '../domain/master_record.dart';
import 'local_auth_service.dart';

class MasterDataService {
  MasterDataService(this.auth, this.repository);
  final LocalAuthService auth;
  final MasterRepository repository;

  static List<String> get permissions => [
    for (final kind in MasterKind.values) ...['${kind.table}.view', '${kind.table}.create', '${kind.table}.update'],
  ];

  List<MasterRecord> list(MasterKind kind) {
    final session = auth.requirePermission('${kind.table}.view');
    return repository.list(kind, session.companyId);
  }

  List<MasterRecord> branches() {
    final session = auth.requirePermission('warehouses.view');
    return auth.db.select('SELECT id,name FROM branches WHERE company_id=? ORDER BY name', [session.companyId])
      .map((row) => MasterRecord(id: row['id'] as String, name: row['name'] as String)).toList();
  }

  MasterRecord save(MasterKind kind, {String? id, required String name, String? phone, String? branchId}) {
    final action = id == null ? 'create' : 'update';
    final session = auth.requirePermission('${kind.table}.$action');
    final cleanName = name.trim();
    if (cleanName.isEmpty || cleanName.length > 200) {
      throw const AccessDenied('أدخل اسمًا من 1 إلى 200 حرف.');
    }
    final cleanPhone = kind.hasPhone ? phone?.trim() : null;
    if ((cleanPhone?.length ?? 0) > 40) {
      throw const AccessDenied('رقم الهاتف طويل جدًا.');
    }
    if (kind == MasterKind.warehouse && (branchId == null || branchId.isEmpty)) {
      throw const AccessDenied('اختر فرع المخزن.');
    }
    auth.db.execute('BEGIN IMMEDIATE');
    try {
      if (id == null) {
        id = repository.create(kind, session.companyId, name: cleanName, phone: cleanPhone,
          branchId: kind == MasterKind.warehouse ? branchId : null).id;
      } else if (!repository.update(kind, session.companyId, id, name: cleanName, phone: cleanPhone,
          branchId: kind == MasterKind.warehouse ? branchId : null)) {
        throw const AccessDenied('السجل غير متاح لهذه المؤسسة.');
      }
      auth.audit(companyId: session.companyId, userId: session.userId, action: '${kind.table}.$action',
        entity: kind.table, recordId: id);
      auth.db.execute('COMMIT');
      return MasterRecord(id: id, name: cleanName, phone: cleanPhone, branchId: kind == MasterKind.warehouse ? branchId : null);
    } catch (_) {
      auth.db.execute('ROLLBACK');
      rethrow;
    }
  }
}
