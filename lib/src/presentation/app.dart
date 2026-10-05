import 'package:flutter/material.dart';

import '../application/app_services.dart';
import '../application/local_auth_service.dart';
import 'master_data_page.dart';
import 'administration_page.dart';
import 'finance_page.dart';
import 'sales_page.dart';
import '../domain/master_record.dart';

class YemErpApp extends StatelessWidget {
  const YemErpApp({super.key, this.initialize});
  final Future<AppServices> Function()? initialize;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'YEM ERP',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(colorSchemeSeed: const Color(0xFF174B74), useMaterial3: true),
    darkTheme: ThemeData(colorSchemeSeed: const Color(0xFF174B74), brightness: Brightness.dark, useMaterial3: true),
    home: Directionality(textDirection: TextDirection.rtl, child: _Workspace(initialize: initialize ?? AppServices.open)),
  );
}

class _Workspace extends StatefulWidget {
  const _Workspace({required this.initialize});
  final Future<AppServices> Function() initialize;
  @override
  State<_Workspace> createState() => _WorkspaceState();
}

class _WorkspaceState extends State<_Workspace> {
  AppServices? services;
  bool busy = true;
  bool signedIn = false;
  bool failedOpen = false;
  String? message;
  String? companyId;
  String? unitId;
  String? categoryId;
  bool isStockItem = true;
  final company = TextEditingController();
  final branch = TextEditingController();
  final username = TextEditingController();
  final password = TextEditingController();
  final confirmation = TextEditingController();
  final name = TextEditingController();
  final sku = TextEditingController();

  @override
  void initState() { super.initState(); _open(); }

  Future<void> _open() async {
    setState(() { busy = true; message = null; failedOpen = false; });
    try {
      final opened = await widget.initialize();
      if (!mounted) { opened.close(); return; }
      setState(() {
        services = opened;
        companyId = opened.companies.isEmpty ? null : opened.companies.first.id;
      });
    } catch (_) {
      if (mounted) { setState(() { failedOpen = true; message = 'تعذر فتح التخزين الآمن. تحقق من إعدادات الجهاز ثم أعد المحاولة.'; }); }
    } finally {
      if (mounted) { setState(() => busy = false); }
    }
  }

  Future<void> _perform(Future<void> Function() action) async {
    setState(() { busy = true; message = null; });
    try {
      await action();
    } on AccessDenied catch (error) {
      if (mounted) { setState(() => message = error.message); }
    } catch (_) {
      if (mounted) { setState(() => message = 'تعذر إتمام العملية. تحقق من البيانات وتأكد من عدم تكرار رمز الصنف.' ); }
    } finally {
      if (mounted) { password.clear(); confirmation.clear(); setState(() => busy = false); }
    }
  }

  @override
  void dispose() {
    for (final controller in [company, branch, username, password, confirmation, name, sku]) { controller.dispose(); }
    services?.close();
    super.dispose();
  }

  Widget field(TextEditingController controller, String label, {bool secret = false}) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextField(controller: controller, obscureText: secret, enabled: !busy,
      autocorrect: !secret, enableSuggestions: !secret,
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder())),
  );

  Widget _identity(AppServices app) {
    final setup = app.auth.needsSetup;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(setup ? 'إعداد المؤسسة' : 'تسجيل الدخول', style: Theme.of(context).textTheme.headlineSmall),
      const SizedBox(height: 16),
      if (setup) ...[field(company, 'اسم المؤسسة'), field(branch, 'اسم الفرع')]
      else DropdownButtonFormField<String>(initialValue: companyId,
        decoration: const InputDecoration(labelText: 'المؤسسة'),
        items: app.companies.map((item) => DropdownMenuItem(value: item.id, child: Text(item.name))).toList(),
        onChanged: busy ? null : (value) => setState(() => companyId = value)),
      const SizedBox(height: 12),
      field(username, 'اسم المستخدم'), field(password, 'كلمة المرور', secret: true),
      if (setup) ...[field(confirmation, 'تأكيد كلمة المرور', secret: true), const Text('اختر كلمة مرور من 12 حرفًا على الأقل.')],
      const SizedBox(height: 16),
      FilledButton(onPressed: busy ? null : () => _perform(() async {
        if (setup) {
          if (password.text != confirmation.text) throw const AccessDenied('كلمتا المرور غير متطابقتين.');
          await app.auth.bootstrap(companyName: company.text, branchName: branch.text, username: username.text, password: password.text);
          if (!mounted) return;
          setState(() { companyId = app.companies.first.id; message = 'تم إعداد المؤسسة. سجّل الدخول للمتابعة.'; });
        } else {
          if (companyId == null) throw const AccessDenied('اختر المؤسسة.');
          await app.auth.login(companyId: companyId!, username: username.text, password: password.text);
          if (!mounted) return;
          setState(() { signedIn = true; categoryId = null; unitId = app.auth.hasPermission('products.view') && app.units.isNotEmpty ? app.units.first.id : null; });
        }
      }), child: Text(setup ? 'إنشاء المؤسسة' : 'دخول')),
    ]);
  }

  Widget _catalog(AppServices app) {
    try {
      final items = app.products.list();
      final units = app.units;
      final categories = app.categories;
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('الأصناف', style: Theme.of(context).textTheme.headlineSmall),
        field(name, 'اسم الصنف'), field(sku, 'رمز الصنف'),
        DropdownButtonFormField<String>(initialValue: unitId, decoration: const InputDecoration(labelText: 'الوحدة'),
          items: units.map((item) => DropdownMenuItem(value: item.id, child: Text(item.name))).toList(),
          onChanged: busy ? null : (value) => setState(() => unitId = value)),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(initialValue: categoryId ?? '', decoration: const InputDecoration(labelText: 'الفئة'),
          items: [const DropdownMenuItem(value: '', child: Text('بدون فئة')),
            ...categories.map((item) => DropdownMenuItem(value: item.id, child: Text(item.name)))],
          onChanged: busy ? null : (value) => setState(() => categoryId = value == '' ? null : value)),
        CheckboxListTile(title: const Text('صنف مخزني'), value: isStockItem, onChanged: busy ? null : (v)=>setState(()=>isStockItem=v??true)),
        const SizedBox(height: 16),
        FilledButton(onPressed: busy || !app.auth.hasPermission('products.create') ? null : () => _perform(() async {
          if (unitId == null) throw const AccessDenied('اختر الوحدة.');
          app.products.create(unitId: unitId!, name: name.text, sku: sku.text, categoryId: categoryId, isStockItem: isStockItem);
          name.clear(); sku.clear();
        }), child: const Text('إضافة صنف')),
        const SizedBox(height: 24),
        if (items.isEmpty) const Text('لا توجد أصناف نشطة.'),
        for (final item in items) Card(child: ListTile(title: Text(item.name), subtitle: Text(item.sku),
          trailing: IconButton(tooltip: 'أرشفة الصنف', icon: const Icon(Icons.archive_outlined),
            onPressed: busy || !app.auth.hasPermission('products.archive') ? null : () async {
              final approved = await showDialog<bool>(context: context, builder: (context) => Directionality(
                textDirection: TextDirection.rtl, child: AlertDialog(title: const Text('أرشفة الصنف؟'),
                  content: Text(item.name), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
                    FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('أرشفة'))])));
              if (approved == true && mounted) { await _perform(() async { app.products.archive(item.id); }); }
            }))),
      ]);
    } on AccessDenied catch (error) {
      return Column(children: [Text(error.message), TextButton(onPressed: () => setState(() => signedIn = false), child: const Text('العودة لتسجيل الدخول'))]);
    }
  }

  Future<void> _navigate(Widget page) async {
    await Navigator.of(context).push<void>(MaterialPageRoute(builder: (_) => page));
    if (mounted) { setState(() {}); }
  }

  Widget _dashboard(AppServices app) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    if (MasterKind.values.any((kind) => app.auth.hasPermission('${kind.table}.view')))
      OutlinedButton(onPressed: busy ? null : () => _navigate(MasterDataPage(services: app)), child: const Text('البيانات الأساسية')),
    if (app.auth.hasPermission('administration.manage'))
      OutlinedButton(onPressed: busy ? null : () => _navigate(AdministrationPage(services: app)), child: const Text('المستخدمون والأدوار')),
    if (app.auth.hasPermission('sales.view'))
      OutlinedButton(onPressed: busy ? null : () => _navigate(SalesPage(services: app)), child: const Text('فواتير البيع والمخزون')),
    if (app.auth.hasPermission('finance.view'))
      OutlinedButton(onPressed: busy ? null : () => _navigate(FinancePage(services: app)), child: const Text('المصروفات والعهد')),
    TextButton(onPressed: busy ? null : () => _perform(() async {
      app.auth.logout();
      setState(() { signedIn = false; name.clear(); sku.clear(); });
    }), child: const Text('تسجيل الخروج')),
    _catalog(app),
  ]);

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('YEM ERP')),
    body: Align(alignment: Alignment.topCenter, child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 720),
      child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Text('المرحلة 0 — نسخة تطوير'), const SizedBox(height: 16),
        if (busy) const LinearProgressIndicator(),
        if (message != null) ...[Text(message!, key: const Key('status-message')), const SizedBox(height: 16)],
        if (services != null) signedIn ? _dashboard(services!) : _identity(services!),
        if (failedOpen) FilledButton(onPressed: busy ? null : _open, child: const Text('إعادة المحاولة')),
      ])))),
  );
}
