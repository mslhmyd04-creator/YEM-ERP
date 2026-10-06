import 'package:sqlite3/sqlite3.dart';

import '../domain/identifiers.dart';
import '../domain/password_hasher.dart';
import 'master_data_service.dart';

class AccessDenied implements Exception {
  const AccessDenied(this.message);
  final String message;
  @override
  String toString() => message;
}

class LocalSession {
  const LocalSession({required this.userId, required this.companyId, required this.expiresAt, required this.authRevision});
  final String userId;
  final String companyId;
  final DateTime expiresAt;
  final int authRevision;
}

class LocalAuthService {
  LocalAuthService(this.db, this.hasher, {DateTime Function()? clock})
      : _clock = clock ?? (() => DateTime.now().toUtc());
  final Database db;
  final PasswordHasher hasher;
  final DateTime Function() _clock;
  LocalSession? _session;
  bool _busy = false;

  static List<String> get permissions => ['products.view', 'products.create', 'products.archive', 'administration.manage', 'finance.view', 'finance.post', 'sales.view', 'sales.create', ...MasterDataService.permissions];
  bool get needsSetup => db.select('SELECT count(*) AS n FROM companies').single['n'] == 0;

  Future<void> bootstrap({required String companyName, required String branchName,
    required String username, required String password}) => _exclusive(() async {
    if (!needsSetup) throw const AccessDenied('تم إعداد المؤسسة مسبقًا.');
    if ([companyName, branchName, username].any((value) => value.trim().isEmpty)) {
      throw const AccessDenied('أكمل بيانات المؤسسة والمستخدم.');
    }
    if (password.runes.length < 12 || password.length > 1024) {
      throw const AccessDenied('كلمة المرور يجب أن تتكون من 12 حرفًا على الأقل.');
    }
    final hash = await hasher.hash(password);
    final company = newUuid(), branch = newUuid(), user = newUuid(), role = newUuid();
    final timestamp = _clock().toIso8601String();
    db.execute('BEGIN IMMEDIATE');
    try {
      if (!needsSetup) throw const AccessDenied('تم إعداد المؤسسة مسبقًا.');
      db.execute('INSERT INTO companies(id,name,created_at) VALUES(?,?,?)', [company, companyName.trim(), timestamp]);
      db.execute('INSERT INTO branches(id,company_id,name,created_at) VALUES(?,?,?,?)', [branch, company, branchName.trim(), timestamp]);
      db.execute('INSERT INTO users(id,company_id,branch_id,username,password_hash,created_at) VALUES(?,?,?,?,?,?)',
        [user, company, branch, username.trim().toLowerCase(), hash, timestamp]);
      db.execute('INSERT INTO roles(id,company_id,name) VALUES(?,?,?)', [role, company, 'مدير']);
      for (final permission in permissions) {
        db.execute('INSERT OR IGNORE INTO permissions(code,description) VALUES(?,?)', [permission, permission]);
        db.execute('INSERT INTO role_permissions(role_id,permission_code) VALUES(?,?)', [role, permission]);
      }
      db.execute('INSERT INTO user_roles(user_id,role_id,company_id) VALUES(?,?,?)', [user, role, company]);
      db.execute('INSERT INTO units(id,company_id,name) VALUES(?,?,?)', [newUuid(), company, 'قطعة']);
      audit(companyId: company, userId: user, action: 'company.bootstrap', entity: 'companies', recordId: company);
      db.execute('COMMIT');
    } catch (_) {
      db.execute('ROLLBACK');
      rethrow;
    }
  });

  Future<void> login({required String companyId, required String username, required String password}) => _exclusive(() async {
    _session = null;
    if (password.length > 1024) throw const AccessDenied('بيانات الدخول غير صحيحة.');
    final rows = db.select('SELECT * FROM users WHERE company_id=? AND username=?', [companyId, username.trim().toLowerCase()]);
    if (rows.isEmpty || rows.single['is_active'] != 1) {
      await hasher.hash(password); // Do not return instantly for unknown identities.
      throw const AccessDenied('بيانات الدخول غير صحيحة.');
    }
    final row = rows.single;
    final user = row['id'] as String;
    final now = _clock();
    final lockedUntil = row['locked_until_ms'] as int;
    if (lockedUntil > now.millisecondsSinceEpoch) {
      throw const AccessDenied('تم إيقاف الدخول مؤقتًا. حاول بعد 15 دقيقة.');
    }
    final accepted = await hasher.verify(password, row['password_hash'] as String);
    // Recheck after asynchronous hashing; disabled users cannot acquire a session.
    if (db.select('SELECT is_active FROM users WHERE id=?', [user]).single['is_active'] != 1) {
      throw const AccessDenied('بيانات الدخول غير صحيحة.');
    }
    db.execute('BEGIN IMMEDIATE');
    try {
      final current = db.select('SELECT * FROM users WHERE id=? AND company_id=?', [user, companyId]);
      if (current.isEmpty || current.single['is_active'] != 1 ||
          current.single['password_hash'] != row['password_hash'] ||
          current.single['auth_revision'] != row['auth_revision'] ||
          (current.single['locked_until_ms'] as int) > _clock().millisecondsSinceEpoch) {
        throw const AccessDenied('بيانات الدخول غير صحيحة.');
      }
      if (!accepted) {
        final failures = ((current.single['locked_until_ms'] as int) > 0
            ? 0 : current.single['failed_login_count'] as int) + 1;
        final lock = failures >= 5 ? now.add(const Duration(minutes: 15)).millisecondsSinceEpoch : 0;
        db.execute('UPDATE users SET failed_login_count=?,locked_until_ms=? WHERE id=?', [failures, lock, user]);
        audit(companyId: companyId, userId: user, action: 'auth.login_failed', entity: 'users', recordId: user);
      } else {
        db.execute('UPDATE users SET failed_login_count=0,locked_until_ms=0 WHERE id=?', [user]);
        audit(companyId: companyId, userId: user, action: 'auth.login', entity: 'users', recordId: user);
      }
      db.execute('COMMIT');
    } catch (_) {
      db.execute('ROLLBACK');
      rethrow;
    }
    if (!accepted) throw const AccessDenied('بيانات الدخول غير صحيحة.');
    _session = LocalSession(userId: user, companyId: companyId, expiresAt: _clock().add(const Duration(minutes: 30)), authRevision: row['auth_revision'] as int);
  });

  LocalSession requirePermission(String permission) {
    final session = _session;
    if (session == null || !session.expiresAt.isAfter(_clock())) {
      _session = null;
      throw const AccessDenied('سجّل الدخول أولًا.');
    }
    final active = db.select('SELECT is_active,auth_revision FROM users WHERE id=? AND company_id=?', [session.userId, session.companyId]);
    if (active.isEmpty || active.single['is_active'] != 1 || active.single['auth_revision'] != session.authRevision) {
      _session = null;
      throw const AccessDenied('الحساب غير نشط.');
    }
    final allowed = db.select('SELECT 1 FROM user_roles ur JOIN role_permissions rp ON rp.role_id=ur.role_id '
      'WHERE ur.user_id=? AND ur.company_id=? AND rp.permission_code=? LIMIT 1',
      [session.userId, session.companyId, permission]);
    if (allowed.isEmpty) throw const AccessDenied('لا تملك صلاحية هذه العملية.');
    return session;
  }

  bool hasPermission(String code) {
    try { requirePermission(code); return true; } on AccessDenied { return false; }
  }

  void logout() {
    final current = _session;
    _session = null;
    if (current != null) {
      audit(companyId: current.companyId, userId: current.userId,
        action: 'auth.logout', entity: 'users', recordId: current.userId);
    }
  }

  void audit({required String companyId, required String userId, required String action,
    required String entity, required String recordId}) {
    db.execute('INSERT INTO audit_logs(id,company_id,user_id,action,entity_type,entity_id,created_at) VALUES(?,?,?,?,?,?,?)',
      [newUuid(), companyId, userId, action, entity, recordId, _clock().toIso8601String()]);
  }

  Future<T> _exclusive<T>(Future<T> Function() action) async {
    if (_busy) throw const AccessDenied('انتظر اكتمال العملية الحالية.');
    _busy = true;
    try { return await action(); } finally { _busy = false; }
  }
}
