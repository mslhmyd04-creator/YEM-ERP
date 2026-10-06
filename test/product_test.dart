import 'package:flutter_test/flutter_test.dart';
import 'package:yem_erp/src/domain/product.dart';

void main() {
  test('product keeps separate immutable identity and SKU', () {
    final product = Product(
      id: 'uuid-1', companyId: 'company-1', unitId: 'unit-1',
      name: 'كاميرا', sku: 'CAM-001', isActive: true,
    );
    expect(product.id, 'uuid-1');
    expect(product.sku, 'CAM-001');
  });

  test('product rejects empty identity or label', () {
    Product make({String id = 'uuid-1', String name = 'كاميرا', String sku = 'CAM-001'}) =>
        Product(id: id, companyId: 'company-1', unitId: 'unit-1',
          name: name, sku: sku, isActive: true);
    expect(() => make(id: ' '), throwsArgumentError);
    expect(() => make(name: ''), throwsArgumentError);
    expect(() => make(sku: ''), throwsArgumentError);
  });
}
