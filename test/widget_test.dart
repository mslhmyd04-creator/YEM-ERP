import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:yem_erp/src/application/app_services.dart';
import 'package:yem_erp/src/application/local_auth_service.dart';
import 'package:yem_erp/src/data/local_migrations.dart';
import 'package:yem_erp/src/presentation/app.dart';

import 'local_auth_test.dart' show TestHasher;

void main() {
  testWidgets('RTL setup, login, product creation and archive workflow', (tester) async {
    final db = sqlite3.openInMemory();
    db.execute('PRAGMA foreign_keys=ON');
    await LocalMigrations.apply(db);
    final app = AppServices(LocalAuthService(db, TestHasher()), close: db.close);
    await tester.pumpWidget(YemErpApp(initialize: () async => app));
    await tester.pumpAndSettle();
    expect(Directionality.of(tester.element(find.text('إعداد المؤسسة'))), TextDirection.rtl);
    Future<void> enter(String label, String value) async {
      final field = find.widgetWithText(TextField, label);
      await tester.ensureVisible(field);
      await tester.enterText(field, value);
    }
    Future<void> press(String label) async {
      final button = find.widgetWithText(FilledButton, label);
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();
    }
    await enter('اسم المؤسسة', 'شركة الاختبار');
    await enter('اسم الفرع', 'الرئيسي');
    await enter('اسم المستخدم', 'admin');
    await enter('كلمة المرور', 'LongPassword123!');
    await enter('تأكيد كلمة المرور', 'LongPassword123!');
    await press('إنشاء المؤسسة');
    expect(find.text('تسجيل الدخول'), findsOneWidget);
    await enter('كلمة المرور', 'LongPassword123!');
    await press('دخول');
    await enter('اسم الصنف', 'كاميرا');
    await enter('رمز الصنف', 'C1');
    await press('إضافة صنف');
    expect(find.text('كاميرا'), findsOneWidget);
    expect(app.products.list().single.sku, 'C1');
    final archive = find.byTooltip('أرشفة الصنف');
    await tester.ensureVisible(archive);
    await tester.tap(archive);
    await tester.pumpAndSettle();
    await press('أرشفة');
    expect(app.products.list(), isEmpty);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('failed secure opening provides retry without creating data', (tester) async {
    await tester.pumpWidget(YemErpApp(initialize: () async => throw StateError('missing key')));
    await tester.pumpAndSettle();
    expect(find.text('إعادة المحاولة'), findsOneWidget);
    expect(find.text('إنشاء المؤسسة'), findsNothing);
  });
}
