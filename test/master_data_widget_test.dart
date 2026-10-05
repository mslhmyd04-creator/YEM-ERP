import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:yem_erp/src/application/app_services.dart';
import 'package:yem_erp/src/application/local_auth_service.dart';
import 'package:yem_erp/src/data/local_migrations.dart';
import 'package:yem_erp/src/domain/master_record.dart';
import 'package:yem_erp/src/presentation/master_data_page.dart';

import 'local_auth_test.dart' show TestHasher;

void main() {
  testWidgets('master form creates every type and edits a customer', (tester) async {
    final db = sqlite3.openInMemory();
    addTearDown(db.close);
    db.execute('PRAGMA foreign_keys=ON');
    await LocalMigrations.apply(db);
    final app = AppServices(LocalAuthService(db, TestHasher()));
    await app.auth.bootstrap(companyName: 'A', branchName: 'Main', username: 'admin', password: 'LongPassword123!');
    await app.auth.login(companyId: app.companies.single.id, username: 'admin', password: 'LongPassword123!');
    await tester.pumpWidget(MaterialApp(home: MasterDataPage(services: app)));
    await tester.pumpAndSettle();
    for (final kind in MasterKind.values) {
      final selector = find.byType(DropdownButtonFormField<MasterKind>);
      await tester.ensureVisible(selector);
      await tester.tap(selector);
      await tester.pumpAndSettle();
      await tester.tap(find.text(kind.label).last);
      await tester.pumpAndSettle();
      final name = find.widgetWithText(TextField, 'الاسم');
      await tester.enterText(name, 'Test ${kind.name}');
      final add = find.widgetWithText(FilledButton, 'إضافة سجل');
      await tester.ensureVisible(add);
      await tester.tap(add);
      await tester.pumpAndSettle();
      expect(app.masterData.list(kind).any((record) => record.name == 'Test ${kind.name}'), isTrue);
    }
    final selector = find.byType(DropdownButtonFormField<MasterKind>);
    await tester.ensureVisible(selector);
    await tester.tap(selector); await tester.pumpAndSettle();
    await tester.tap(find.text('العملاء').last); await tester.pumpAndSettle();
    final edit = find.byTooltip('تعديل السجل');
    await tester.ensureVisible(edit); await tester.tap(edit); await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'الاسم'), 'Edited customer');
    final save = find.widgetWithText(FilledButton, 'حفظ التعديل');
    await tester.ensureVisible(save); await tester.tap(save); await tester.pumpAndSettle();
    expect(app.masterData.list(MasterKind.customer).single.name, 'Edited customer');
    await tester.pumpWidget(const SizedBox());
  });
}
