import '../data/administration_repository.dart';
import '../domain/administration.dart';
import '../domain/identifiers.dart';
import '../domain/master_record.dart';
import 'local_auth_service.dart';

class AdministrationService {
  AdministrationService(this.auth, this.repository);
  final LocalAuthService auth;
  final AdministrationRepository repository;
  bool _busy = false;
  static const permission = 'administration.manage';

  List<RoleRecord> roles() => repository.roles(auth.requirePermission(permission).companyId);
  List<UserRecord> users() => repository.users(auth.requirePermission(permission).companyId);
  List<MasterRecord> branches() => repository.branches(auth.requirePermission(permission).companyId);

  String saveRole({String? id, required String name, required Set<String> permissions}) {
    final session = auth.requirePermission(permission);
    final label = name.trim();
    if (label.isEmpty || label.length > 100 || !permissions.every(PermissionOption.all.map((p) => p.code).toSet().contains)) {
      throw const AccessDenied('تحقق من اسم الدور والصلاحيات.');
    }
    final create = id == null;
    final recordId = id ?? newUuid();
    return _transaction<String>(session, () {
      if (!create && !repository.owns('roles', recordId, session.companyId)) { throw const AccessDenied('الدور غير متاح لهذه المؤسسة.'); }
      repository.saveRole(session.companyId, recordId, label, permissions, create: create);
      _protectAdministrator(session.companyId);
      auth.audit(companyId: session.companyId, userId: session.userId, action: create ? 'roles.create' : 'roles.update', entity: 'roles', recordId: recordId);
      return recordId;
    });
  }

  Future<String> saveUser({String? id, required String username, required String branchId,
    required Set<String> roleIds, required bool active, String? password}) async {
    if (_busy) { throw const AccessDenied('انتظر اكتمال العملية الحالية.'); }
    _busy = true;
    try {
      final original = auth.requirePermission(permission);
      final clean = username.trim().toLowerCase();
      final create = id == null;
      final assignedRoles = Set<String>.of(roleIds);
      final secret = password ?? '';
      if (clean.isEmpty || clean.length > 100 || assignedRoles.isEmpty) { throw const AccessDenied('أدخل اسم المستخدم واختر دورًا واحدًا على الأقل.'); }
      final changePassword = secret.isNotEmpty;
      if ((create && !changePassword) || (changePassword && (secret.runes.length < 12 || secret.length > 1024))) {
        throw const AccessDenied('كلمة المرور يجب أن تتكون من 12 حرفًا على الأقل.');
      }
      final hash = changePassword ? await auth.hasher.hash(secret) : null;
      final session = auth.requirePermission(permission); // Revalidate after asynchronous hashing.
      if (!identical(session, original)) { throw const AccessDenied('تغيرت جلسة الدخول. أعد المحاولة.'); }
      final recordId = id ?? newUuid();
      return _transaction<String>(session, () {
        if ((!create && !repository.owns('users', recordId, session.companyId)) ||
            !repository.owns('branches', branchId, session.companyId) ||
            !assignedRoles.every((role) => repository.owns('roles', role, session.companyId))) {
          throw const AccessDenied('المستخدم أو الفرع أو الدور غير متاح لهذه المؤسسة.');
        }
        repository.saveUser(session.companyId, recordId, clean, branchId, assignedRoles, active, hash, create: create);
        _protectAdministrator(session.companyId);
        auth.audit(companyId: session.companyId, userId: session.userId, action: create ? 'users.create' : 'users.update', entity: 'users', recordId: recordId);
        if (!create && changePassword) {
          auth.audit(companyId: session.companyId, userId: session.userId, action: 'users.password_reset', entity: 'users', recordId: recordId);
        }
        return recordId;
      });
    } finally { _busy = false; }
  }

  void _protectAdministrator(String company) {
    if (!repository.hasActiveAdministrator(company)) { throw const AccessDenied('يجب الاحتفاظ بمدير نشط واحد على الأقل.'); }
  }

  T _transaction<T>(LocalSession session, T Function() action) {
    auth.db.execute('BEGIN IMMEDIATE');
    try {
      final current = auth.requirePermission(permission);
      if (!identical(current, session)) {
        throw const AccessDenied('تغيرت جلسة الدخول. أعد المحاولة.');
      }
      // Callers validate access before modifying membership/credentials.
      final result = action();
      auth.db.execute('COMMIT');
      return result;
    } catch (_) { auth.db.execute('ROLLBACK'); rethrow; }
  }
}
