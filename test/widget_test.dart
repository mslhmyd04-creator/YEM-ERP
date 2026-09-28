import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yem_erp/src/presentation/app.dart';

void main() {
  testWidgets('Arabic foundation screen is visible in RTL', (tester) async {
    await tester.pumpWidget(const YemErpApp());

    expect(find.text('YEM ERP'), findsOneWidget);
    expect(find.textContaining('المرحلة 0'), findsOneWidget);
    final context = tester.element(find.textContaining('المرحلة 0'));
    expect(Directionality.of(context), TextDirection.rtl);
  });
}
