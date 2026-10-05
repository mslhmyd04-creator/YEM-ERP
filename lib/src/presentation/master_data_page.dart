import 'package:flutter/material.dart';

import '../application/app_services.dart';
import '../application/local_auth_service.dart';
import '../domain/master_record.dart';

class MasterDataPage extends StatefulWidget {
  const MasterDataPage({super.key, required this.services});
  final AppServices services;
  @override
  State<MasterDataPage> createState() => _MasterDataPageState();
}

class _MasterDataPageState extends State<MasterDataPage> {
  MasterKind kind = MasterKind.customer;
  String? editId;
  String? branchId;
  String? message;
  final name = TextEditingController();
  final phone = TextEditingController();

  @override
  void dispose() { name.dispose(); phone.dispose(); super.dispose(); }

  void reset() { editId = null; branchId = null; name.clear(); phone.clear(); }

  void save(String? selectedBranch) {
    try {
      widget.services.masterData.save(kind, id: editId, name: name.text,
        phone: phone.text, branchId: selectedBranch);
      setState(() { reset(); message = 'تم حفظ السجل.'; });
    } on AccessDenied catch (error) {
      setState(() => message = error.message);
    } catch (_) {
      setState(() => message = 'تعذر الحفظ. تحقق من البيانات وعدم تكرار الاسم في القوائم.');
    }
  }

  Widget content() {
    try {
      final records = widget.services.masterData.list(kind);
      final branches = kind == MasterKind.warehouse ? widget.services.masterData.branches() : <MasterRecord>[];
      final selectedBranch = branchId ?? (branches.isEmpty ? null : branches.first.id);
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        TextField(controller: name, decoration: const InputDecoration(labelText: 'الاسم', border: OutlineInputBorder())),
        const SizedBox(height: 12),
        if (kind.hasPhone) ...[
          TextField(controller: phone, keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'الهاتف (اختياري)', border: OutlineInputBorder())),
          const SizedBox(height: 12),
        ],
        if (kind == MasterKind.warehouse) ...[
          DropdownButtonFormField<String>(key: ValueKey('branch-$kind-$editId-$selectedBranch'), initialValue: selectedBranch,
            decoration: const InputDecoration(labelText: 'فرع المخزن'),
            items: branches.map((item) => DropdownMenuItem(value: item.id, child: Text(item.name))).toList(),
            onChanged: (value) => setState(() => branchId = value)),
          const SizedBox(height: 12),
        ],
        FilledButton(onPressed: () => save(selectedBranch), child: Text(editId == null ? 'إضافة سجل' : 'حفظ التعديل')),
        if (editId != null) TextButton(onPressed: () => setState(reset), child: const Text('إلغاء التعديل')),
        const SizedBox(height: 20),
        if (records.isEmpty) const Text('لا توجد سجلات.'),
        for (final record in records) Card(child: ListTile(title: Text(record.name),
          subtitle: record.phone == null || record.phone!.isEmpty ? null : Text(record.phone!),
          trailing: IconButton(tooltip: 'تعديل السجل', icon: const Icon(Icons.edit_outlined), onPressed: () => setState(() {
            editId = record.id; name.text = record.name; phone.text = record.phone ?? ''; branchId = record.branchId; message = null;
          })))),
      ]);
    } on AccessDenied catch (error) {
      // A revoked/expired session blocks reads as well as writes.
      return Text(error.message);
    }
  }

  @override
  Widget build(BuildContext context) => Directionality(textDirection: TextDirection.rtl,
    child: Scaffold(appBar: AppBar(title: const Text('البيانات الأساسية')),
      body: Align(alignment: Alignment.topCenter, child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 720),
        child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (message != null) ...[Text(message!, key: const Key('master-status')), const SizedBox(height: 12)],
        DropdownButtonFormField<MasterKind>(initialValue: kind,
          decoration: const InputDecoration(labelText: 'نوع البيانات'),
          items: MasterKind.values.map((item) => DropdownMenuItem(value: item, child: Text(item.label))).toList(),
          onChanged: (value) { if (value != null) { setState(() { kind = value; reset(); message = null; }); } }),
        const SizedBox(height: 16),
          content(),
        ])))),
    ),
  );
}
