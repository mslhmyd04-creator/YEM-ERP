import 'package:flutter/material.dart';

import '../application/app_services.dart';
import '../application/local_auth_service.dart';
import '../domain/administration.dart';

class AdministrationPage extends StatefulWidget {
  const AdministrationPage({super.key, required this.services});
  final AppServices services;
  @override
  State<AdministrationPage> createState() => _AdministrationPageState();
}

class _AdministrationPageState extends State<AdministrationPage> {
  bool roleMode = false;
  bool active = true;
  bool busy = false;
  String? id;
  String? branch;
  String? message;
  final label = TextEditingController();
  final password = TextEditingController();
  final confirmation = TextEditingController();
  final selections = <String>{};

  @override
  void dispose() { label.dispose(); password.dispose(); confirmation.dispose(); super.dispose(); }

  void reset() {
    id = null; branch = null; active = true; label.clear(); password.clear(); confirmation.clear(); selections.clear();
  }

  Future<void> save(String? selectedBranch) async {
    setState(() { busy = true; message = null; });
    try {
      if (roleMode) {
        widget.services.administration.saveRole(id: id, name: label.text, permissions: selections.toSet());
      } else {
        if (password.text != confirmation.text) { throw const AccessDenied('كلمتا المرور غير متطابقتين.'); }
        if (selectedBranch == null) { throw const AccessDenied('اختر الفرع.'); }
        await widget.services.administration.saveUser(id: id, username: label.text, branchId: selectedBranch,
          roleIds: selections.toSet(), active: active, password: password.text);
      }
      if (mounted) { setState(() { reset(); message = 'تم الحفظ. قد يلزم تسجيل الدخول مجددًا بعد تعديل الحساب.'; }); }
    } on AccessDenied catch (error) {
      if (mounted) { setState(() => message = error.message); }
    } catch (_) {
      if (mounted) { setState(() => message = 'تعذر الحفظ. تحقق من البيانات وعدم تكرار الاسم.'); }
    } finally {
      if (mounted) { password.clear(); confirmation.clear(); setState(() => busy = false); }
    }
  }

  Widget field(TextEditingController controller, String text, {bool secret = false}) => Padding(
    padding: const EdgeInsets.only(bottom: 12), child: TextField(controller: controller, enabled: !busy,
      obscureText: secret, autocorrect: !secret, enableSuggestions: !secret,
      decoration: InputDecoration(labelText: text, border: const OutlineInputBorder())));

  Widget content() {
    try {
      final roles = widget.services.administration.roles();
      final users = widget.services.administration.users();
      final branches = widget.services.administration.branches();
      final selectedBranch = branch ?? (branches.isEmpty ? null : branches.first.id);
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        field(label, roleMode ? 'اسم الدور' : 'اسم المستخدم'),
        if (!roleMode) ...[
          DropdownButtonFormField<String>(key: ValueKey('admin-branch-$id-$selectedBranch'), initialValue: selectedBranch,
            decoration: const InputDecoration(labelText: 'فرع المستخدم'),
            items: branches.map((item) => DropdownMenuItem(value: item.id, child: Text(item.name))).toList(),
            onChanged: busy ? null : (value) => setState(() => branch = value)),
          const SizedBox(height: 12),
          field(password, 'كلمة المرور الجديدة', secret: true), field(confirmation, 'تأكيد كلمة المرور', secret: true),
          Text(id == null ? 'كلمة المرور: 12 حرفًا على الأقل.' : 'اترك كلمة المرور فارغة للاحتفاظ بها.'),
          CheckboxListTile(title: const Text('الحساب نشط'), value: active, onChanged: busy ? null : (value) => setState(() => active = value ?? false)),
        ],
        Text(roleMode ? 'صلاحيات الدور' : 'أدوار المستخدم', style: Theme.of(context).textTheme.titleMedium),
        if (roleMode) for (final option in PermissionOption.all)
          CheckboxListTile(title: Text(option.label), value: selections.contains(option.code),
            onChanged: busy ? null : (checked) => setState(() { if (checked == true) { selections.add(option.code); } else { selections.remove(option.code); } })),
        if (!roleMode) for (final role in roles)
          CheckboxListTile(title: Text(role.name), value: selections.contains(role.id),
            onChanged: busy ? null : (checked) => setState(() { if (checked == true) { selections.add(role.id); } else { selections.remove(role.id); } })),
        FilledButton(onPressed: busy ? null : () => save(selectedBranch), child: Text(id == null ? 'إضافة' : 'حفظ التعديل')),
        if (id != null) TextButton(onPressed: busy ? null : () => setState(reset), child: const Text('إلغاء التعديل')),
        const SizedBox(height: 24),
        if (roleMode) for (final role in roles) Card(child: ListTile(title: Text(role.name),
          trailing: IconButton(tooltip: 'تعديل الدور', icon: const Icon(Icons.edit_outlined), onPressed: busy ? null : () => setState(() {
            reset(); id = role.id; label.text = role.name; selections.addAll(role.permissions); message = null;
          })))),
        if (!roleMode) for (final user in users) Card(child: ListTile(title: Text(user.username), subtitle: Text(user.isActive ? 'نشط' : 'موقوف'),
          trailing: IconButton(tooltip: 'تعديل المستخدم', icon: const Icon(Icons.edit_outlined), onPressed: busy ? null : () => setState(() {
            reset(); id = user.id; label.text = user.username; branch = user.branchId; active = user.isActive; selections.addAll(user.roleIds); message = null;
          })))),
      ]);
    } on AccessDenied catch (error) { return Text(error.message); }
  }

  @override
  Widget build(BuildContext context) => Directionality(textDirection: TextDirection.rtl, child: Scaffold(
    appBar: AppBar(title: const Text('المستخدمون والأدوار')),
    body: Align(alignment: Alignment.topCenter, child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 720),
      child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (busy) const LinearProgressIndicator(),
        if (message != null) ...[Text(message!, key: const Key('admin-status')), const SizedBox(height: 12)],
        DropdownButtonFormField<bool>(initialValue: roleMode, decoration: const InputDecoration(labelText: 'إدارة'),
          items: const [DropdownMenuItem(value: false, child: Text('المستخدمون')), DropdownMenuItem(value: true, child: Text('الأدوار'))],
          onChanged: busy ? null : (value) => setState(() { roleMode = value ?? false; reset(); message = null; })),
        const SizedBox(height: 16), content(),
      ])))),
  ));
}
