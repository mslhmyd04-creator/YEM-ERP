import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:yem_erp/src/application/app_services.dart';
import 'package:yem_erp/src/application/local_auth_service.dart';
import 'package:yem_erp/src/data/local_migrations.dart';
import 'package:yem_erp/src/presentation/administration_page.dart';
import 'package:yem_erp/src/presentation/app.dart';

import 'local_auth_test.dart' show TestHasher;

Future<void> settle(WidgetTester tester) => tester.pumpAndSettle(
  const Duration(milliseconds: 100), EnginePhase.sendSemanticsUpdate, const Duration(seconds: 5));

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pump();
  await tester.ensureVisible(finder);
  await settle(tester);
  expect(finder.hitTestable(), findsOneWidget);
  await tester.tap(finder);
  await settle(tester);
}

Future<void> field(WidgetTester tester, String label, String value) async {
  final target = find.widgetWithText(TextField, label);
  await tester.ensureVisible(target);
  await settle(tester);
  await tester.enterText(target, value);
  FocusManager.instance.primaryFocus?.unfocus();
  await settle(tester);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Database db;
  late AppServices app;
  // Prepare cached asset futures outside the widget test's FakeAsync zone.
  setUp(() async {
    db = sqlite3.openInMemory();
    db.execute('PRAGMA foreign_keys=ON');
    await LocalMigrations.apply(db);
    app = AppServices(LocalAuthService(db, TestHasher()));
    await app.auth.bootstrap(companyName: 'A', branchName: 'Main', username: 'admin', password: 'LongPassword123!');
    await app.auth.login(companyId: app.companies.single.id, username: 'admin', password: 'LongPassword123!');
  });
  tearDown(() => db.close());

  testWidgets('create role/user through UI and login without product permission', (tester) async {
    await tester.pumpWidget(MaterialApp(home: AdministrationPage(services: app)));
    await settle(tester);
    Future<void> mode(String label) async {
      await tapVisible(tester, find.byType(DropdownButtonFormField<bool>));
      await tester.tap(find.text(label).last); await settle(tester);
    }
    Future<void> button(String label) => tapVisible(tester, find.widgetWithText(FilledButton, label));
    await mode('الأدوار'); await field(tester, 'اسم الدور', 'القارئ');
    await tapVisible(tester, find.widgetWithText(CheckboxListTile, 'عرض العملاء'));
    await button('إضافة');
    expect(app.administration.roles().firstWhere((r) => r.name == 'القارئ').permissions, {'customers.view'});
    await mode('المستخدمون'); await field(tester, 'اسم المستخدم', 'reader');
    await field(tester, 'كلمة المرور الجديدة', 'LongPassword123!');
    await field(tester, 'تأكيد كلمة المرور', 'LongPassword123!');
    await tapVisible(tester, find.widgetWithText(CheckboxListTile, 'القارئ'));
    await button('إضافة'); expect(app.administration.users().any((u) => u.username == 'reader'), isTrue);
    app.auth.logout();
    await tester.pumpWidget(YemErpApp(initialize: () async => app)); await settle(tester);
    await field(tester, 'اسم المستخدم', 'reader'); await field(tester, 'كلمة المرور', 'LongPassword123!'); await button('دخول');
    expect(find.text('المستخدمون والأدوار'), findsNothing);
    await tapVisible(tester, find.widgetWithText(OutlinedButton, 'البيانات الأساسية'));
    expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'إضافة سجل')).onPressed, isNull);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('disabling the last manager displays denial and retains account', (tester) async {
    await tester.pumpWidget(MaterialApp(home: AdministrationPage(services: app))); await settle(tester);
    await tapVisible(tester, find.byTooltip('تعديل المستخدم'));
    await tapVisible(tester, find.widgetWithText(CheckboxListTile, 'الحساب نشط'));
    await tapVisible(tester, find.widgetWithText(FilledButton, 'حفظ التعديل'));
    expect(find.text('يجب الاحتفاظ بمدير نشط واحد على الأقل.'), findsOneWidget);
    expect(app.administration.users().single.isActive, isTrue);
    await tester.pumpWidget(const SizedBox());
  });
}
