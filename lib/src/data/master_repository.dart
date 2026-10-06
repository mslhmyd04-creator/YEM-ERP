import 'package:sqlite3/sqlite3.dart';

import '../domain/identifiers.dart';
import '../domain/master_record.dart';

class MasterRepository {
  MasterRepository(this.db);
  final Database db;

  // Table and column names come only from this enum, never from user input.
  List<MasterRecord> list(MasterKind kind, String companyId) => db.select(
    'SELECT id,name,${kind.hasPhone ? 'phone' : 'NULL AS phone'},'
    '${kind == MasterKind.warehouse ? 'branch_id' : 'NULL AS branch_id'} '
    'FROM ${kind.table} WHERE company_id=? ORDER BY name,id', [companyId],
  ).map((row) => MasterRecord(id: row['id'] as String, name: row['name'] as String,
    phone: row['phone'] as String?, branchId: row['branch_id'] as String?)).toList();

  MasterRecord create(MasterKind kind, String companyId, {required String name, String? phone, String? branchId}) {
    final id = newUuid();
    final columns = ['id', 'company_id', 'name'];
    final values = <Object?>[id, companyId, name];
    if (kind.hasPhone) { columns.add('phone'); values.add(phone); }
    if (kind == MasterKind.warehouse) { columns.add('branch_id'); values.add(branchId); }
    if (kind.hasTimestamp) { columns.add('created_at'); values.add(DateTime.now().toUtc().toIso8601String()); }
    db.execute('INSERT INTO ${kind.table}(${columns.join(',')}) VALUES(${List.filled(columns.length, '?').join(',')})', values);
    return MasterRecord(id: id, name: name, phone: phone, branchId: branchId);
  }

  bool update(MasterKind kind, String companyId, String id, {required String name, String? phone, String? branchId}) {
    final fields = ['name=?'];
    final values = <Object?>[name];
    if (kind.hasPhone) { fields.add('phone=?'); values.add(phone); }
    if (kind == MasterKind.warehouse) { fields.add('branch_id=?'); values.add(branchId); }
    values.addAll([id, companyId]);
    db.execute('UPDATE ${kind.table} SET ${fields.join(',')} WHERE id=? AND company_id=?', values);
    return db.select('SELECT changes() AS n').single['n'] == 1;
  }
}
