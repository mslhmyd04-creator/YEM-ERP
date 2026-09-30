import 'package:flutter_test/flutter_test.dart';
import 'package:yem_erp/src/infrastructure/argon2_password_hasher.dart';

void main() {
  test('Argon2 verifies correct password and rejects wrong or malformed hashes', () async {
    final hasher = Argon2PasswordHasher();
    const password = 'StrongPassword123!';
    final encoded = await hasher.hash(password);
    expect(encoded.contains(password), isFalse);
    expect(await hasher.verify(password, encoded), isTrue);
    expect(await hasher.verify('wrong', encoded), isFalse);
    expect(await hasher.verify(password, 'invalid'), isFalse);
    expect(await hasher.verify(password, '{}'), isFalse);
  }, timeout: const Timeout(Duration(minutes: 3)));
}
