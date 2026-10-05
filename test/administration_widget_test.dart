import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:yem_erp/src/application/app_services.dart';
import 'package:yem_erp/src/application/local_auth_service.dart';
import 'package:yem_erp/src/data/local_migrations.dart';
import 'package:yem_erp/src/presentation/administration_page.dart';
import 'package:yem_erp/src/presentation/app.dart';

import 'local_auth_test.dart' show TestHasher;

void main() {
  testWidgets('create role/user through UI and login without product permission', (tester) async {
    final db = sqlite3.openInMemory(); addTearDown(db.close);
    db.execute('PRAGMA foreign_keys=ON'); await LocalMigrations.apply(db);
    final app = AppServices(LocalAuthService(db, TestHasher()));
    await app.auth.bootstrap(companyName: 'A', branchName: 'Main', username: 'admin', password: 'LongPassword123!');
    await app.auth.login(companyId: app.companies.single.id, username: 'admin', password: 'LongPassword123!');
    await tester.pumpWidget(MaterialApp(home: AdministrationPage(services: app))); await tester.pumpAndSettle(const Duration(milliseconds: 100), EnginePhase.sendSemanticsUpdate, const Duration(seconds: 5));
    Future<void> mode(String label) async {
      final selector = find.byType(DropdownButtonFormField<bool>);
      await tester.ensureVisible(selector); await tester.pumpAndSettle(const Duration(milliseconds: 100), EnginePhase.sendSemanticsUpdate, const Duration(seconds: 5)); await tester.tap(selector); await tester.pumpAndSettle(const Duration(milliseconds: 100), EnginePhase.sendSemanticsUpdate, const Duration(seconds: 5));
      await tester.tap(find.text(label).last); await tester.pumpAndSettle(const Duration(milliseconds: 100), EnginePhase.sendSemanticsUpdate, const Duration(seconds: 5));
    }
    Future<void> field(String label, String value) async {
      final target = find.widgetWithText(TextField, label); await tester.ensureVisible(target); await tester.pumpAndSettle(const Duration(milliseconds: 100), EnginePhase.sendSemanticsUpdate, const Duration(seconds: 5)); await tester.enterText(target, value);
    }
    Future<void> button(String label) async {
      final target = find.widgetWithText(FilledButton, label); await tester.ensureVisible(target); await tester.pumpAndSettle(const Duration(milliseconds: 100), EnginePhase.sendSemanticsUpdate, const Duration(seconds: 5)); await tester.tap(target); await tester.pumpAndSettle(const Duration(milliseconds: 100), EnginePhase.sendSemanticsUpdate, const Duration(seconds: 5));
    }
    await mode('الأدوار'); await field('اسم الدور', 'القارئ');
    final permission = find.widgetWithText(CheckboxListTile, 'عرض العملاء');
    await tester.ensureVisible(permission); await tester.pumpAndSettle(const Duration(milliseconds: 100), EnginePhase.sendSemanticsUpdate, const Duration(seconds: 5)); await tester.tap(permission); await tester.pumpAndSettle(const Duration(milliseconds: 100), EnginePhase.sendSemanticsUpdate, const Duration(seconds: 5)); await button('إضافة');
    expect(app.administration.roles().any((r) => r.name == 'القارئ'), isTrue);
    await mode('المستخدمون'); await field('اسم المستخدم', 'reader');
    await field('كلمة المرور الجديدة', 'LongPassword123!'); await field('تأكيد كلمة المرور', 'LongPassword123!');
    final role = find.widgetWithText(CheckboxListTile, 'القارئ'); await tester.ensureVisible(role); await tester.pumpAndSettle(const Duration(milliseconds: 100), EnginePhase.sendSemanticsUpdate, const Duration(seconds: 5)); await tester.tap(role); await tester.pumpAndSettle(const Duration(milliseconds: 100), EnginePhase.sendSemanticsUpdate, const Duration(seconds: 5));
    await button('إضافة'); expect(app.administration.users().any((u) => u.username == 'reader'), isTrue);
    app.auth.logout();
    await tester.pumpWidget(YemErpApp(initialize: () async => app)); await tester.pumpAndSettle(const Duration(milliseconds: 100), EnginePhase.sendSemanticsUpdate, const Duration(seconds: 5));
    await field('اسم المستخدم', 'reader'); await field('كلمة المرور', 'LongPassword123!'); await button('دخول');
    expect(find.text('المستخدمون والأدوار'), findsNothing);
    final data = find.widgetWithText(OutlinedButton, 'البيانات الأساسية');
    await tester.ensureVisible(data); await tester.pumpAndSettle(const Duration(milliseconds: 100), EnginePhase.sendSemanticsUpdate, const Duration(seconds: 5)); await tester.tap(data); await tester.pumpAndSettle(const Duration(milliseconds: 100), EnginePhase.sendSemanticsUpdate, const Duration(seconds: 5));
    expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'إضافة سجل')).onPressed, isNull);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('disabling the last manager displays denial and retains account', (tester) async {
    final db = sqlite3.openInMemory(); addTearDown(db.close);
    db.execute('PRAGMA foreign_keys=ON'); await LocalMigrations.apply(db);
    final app = AppServices(LocalAuthService(db, TestHasher()));
    await app.auth.bootstrap(companyName: 'A', branchName: 'Main', username: 'admin', password: 'LongPassword123!');
    await app.auth.login(companyId: app.companies.single.id, username: 'admin', password: 'LongPassword123!');
    await tester.pumpWidget(MaterialApp(home: AdministrationPage(services: app))); await tester.pumpAndSettle(const Duration(milliseconds: 100), EnginePhase.sendSemanticsUpdate, const Duration(seconds: 5));
    debugPrint('ADMIN TEST: initial form ready');
    final edit = find.byTooltip('تعديل المستخدم'); await tester.ensureVisible(edit); await tester.pumpAndSettle(const Duration(milliseconds: 100), EnginePhase.sendSemanticsUpdate, const Duration(seconds: 5)); await tester.tap(edit); await tester.pumpAndSettle(const Duration(milliseconds: 100), EnginePhase.sendSemanticsUpdate, const Duration(seconds: 5));
    debugPrint('ADMIN TEST: edit form ready');
    final active = find.widgetWithText(CheckboxListTile, 'الحساب نشط'); await tester.ensureVisible(active); await tester.pumpAndSettle(const Duration(milliseconds: 100), EnginePhase.sendSemanticsUpdate, const Duration(seconds: 5)); await tester.tap(active); await tester.pumpAndSettle(const Duration(milliseconds: 100), EnginePhase.sendSemanticsUpdate, const Duration(seconds: 5));
    debugPrint('ADMIN TEST: active flag changed');
    final save = find.widgetWithText(FilledButton, 'حفظ التعديل'); await tester.ensureVisible(save); await tester.pumpAndSettle(const Duration(milliseconds: 100), EnginePhase.sendSemanticsUpdate, const Duration(seconds: 5)); await tester.tap(save); await tester.pumpAndSettle(const Duration(milliseconds: 100), EnginePhase.sendSemanticsUpdate, const Duration(seconds: 5));
    debugPrint('ADMIN TEST: save returned');
    expect(find.text('يجب الاحتفاظ بمدير نشط واحد على الأقل.'), findsOneWidget);
    expect(app.administration.users().single.isActive, isTrue);
    await tester.pumpWidget(const SizedBox());
  });
}
