import 'package:sqlite3/sqlite3.dart';

import '../domain/administration.dart';
import '../domain/master_record.dart';

class AdministrationRepository {
  AdministrationRepository(this.db);
  final Database db;

  List<RoleRecord> roles(String company) => db.select('SELECT id,name FROM roles WHERE company_id=? ORDER BY name,id', [company])
    .map((row) => RoleRecord(row['id'] as String, row['name'] as String,
      db.select('SELECT permission_code FROM role_permissions WHERE role_id=?', [row['id']])
        .map((permission) => permission['permission_code'] as String).toSet())).toList();

  List<UserRecord> users(String company) => db.select('SELECT id,username,branch_id,is_active FROM users WHERE company_id=? ORDER BY username,id', [company])
    .map((row) => UserRecord(row['id'] as String, row['username'] as String, row['branch_id'] as String, row['is_active'] == 1,
      db.select('SELECT role_id FROM user_roles WHERE user_id=? AND company_id=?', [row['id'], company])
        .map((role) => role['role_id'] as String).toSet())).toList();

  List<MasterRecord> branches(String company) => db.select('SELECT id,name FROM branches WHERE company_id=? ORDER BY name,id', [company])
    .map((row) => MasterRecord(id: row['id'] as String, name: row['name'] as String)).toList();

  bool owns(String table, String id, String company) {
    if (!['users', 'roles', 'branches'].contains(table)) { throw ArgumentError('Unsupported table.'); }
    return db.select('SELECT 1 FROM $table WHERE id=? AND company_id=?', [id, company]).isNotEmpty;
  }

  void saveRole(String company, String id, String name, Set<String> permissions, {required bool create}) {
    if (create) { db.execute('INSERT INTO roles(id,company_id,name) VALUES(?,?,?)', [id, company, name]); }
    else { db.execute('UPDATE roles SET name=? WHERE id=? AND company_id=?', [name, id, company]); }
    db.execute('DELETE FROM role_permissions WHERE role_id=?', [id]);
    for (final code in permissions) { db.execute('INSERT INTO role_permissions(role_id,permission_code) VALUES(?,?)', [id, code]); }
  }

  void saveUser(String company, String id, String username, String branch, Set<String> roles,
    bool active, String? hash, {required bool create}) {
    if (create) {
      db.execute('INSERT INTO users(id,company_id,branch_id,username,password_hash,is_active,created_at) VALUES(?,?,?,?,?,?,?)',
        [id, company, branch, username, hash, active ? 1 : 0, DateTime.now().toUtc().toIso8601String()]);
    } else {
      db.execute('UPDATE users SET username=?,branch_id=?,is_active=?,auth_revision=auth_revision+1 WHERE id=? AND company_id=?',
        [username, branch, active ? 1 : 0, id, company]);
      if (hash != null) {
        db.execute('UPDATE users SET password_hash=?,failed_login_count=0,locked_until_ms=0 WHERE id=? AND company_id=?', [hash, id, company]);
      }
      db.execute('DELETE FROM user_roles WHERE user_id=? AND company_id=?', [id, company]);
    }
    for (final role in roles) { db.execute('INSERT INTO user_roles(user_id,role_id,company_id) VALUES(?,?,?)', [id, role, company]); }
  }

  bool hasActiveAdministrator(String company) => db.select(
    "SELECT 1 FROM users u JOIN user_roles ur ON ur.user_id=u.id AND ur.company_id=u.company_id "
    "JOIN roles r ON r.id=ur.role_id AND r.company_id=ur.company_id "
    "JOIN role_permissions rp ON rp.role_id=r.id WHERE u.company_id=? AND u.is_active=1 "
    "AND rp.permission_code='administration.manage' LIMIT 1", [company]).isNotEmpty;
}
