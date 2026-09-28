import 'package:flutter_test/flutter_test.dart';
import 'package:yem_erp/src/domain/product.dart';

void main() {
  test('product keeps separate immutable identity and SKU', () {
    final product = Product(id: 'uuid-1', name: 'كاميرا', sku: 'CAM-001');
    expect(product.id, 'uuid-1');
    expect(product.sku, 'CAM-001');
  });

  test('product rejects empty identity or label', () {
    expect(() => Product(id: ' ', name: 'كاميرا', sku: 'CAM-001'), throwsArgumentError);
    expect(() => Product(id: 'uuid-1', name: '', sku: 'CAM-001'), throwsArgumentError);
    expect(() => Product(id: 'uuid-1', name: 'كاميرا', sku: ''), throwsArgumentError);
  });
}
