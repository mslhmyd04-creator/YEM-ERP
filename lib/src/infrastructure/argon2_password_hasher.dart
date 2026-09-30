import 'dart:convert';
import 'dart:isolate';
import 'dart:math';

import 'package:cryptography/cryptography.dart';

import '../domain/password_hasher.dart';

class Argon2PasswordHasher implements PasswordHasher {
  static const memory = 19456; // KiB, 19 MiB.
  static const iterations = 2;

  @override
  Future<String> hash(String password) => Isolate.run(() async {
        final random = Random.secure();
        final salt = List<int>.generate(16, (_) => random.nextInt(256));
        final derived = await _derive(password, salt);
        return jsonEncode({
          'version': 1,
          'algorithm': 'argon2id',
          'memory': memory,
          'iterations': iterations,
          'salt': base64Encode(salt),
          'hash': base64Encode(derived),
        });
      });

  @override
  Future<bool> verify(String password, String encoded) => Isolate.run(() async {
        try {
          final record = jsonDecode(encoded) as Map<String, dynamic>;
          if (record['version'] != 1 || record['algorithm'] != 'argon2id' ||
              record['memory'] != memory || record['iterations'] != iterations) {
            return false;
          }
          final salt = base64Decode(record['salt'] as String);
          final expected = base64Decode(record['hash'] as String);
          if (salt.length != 16 || expected.length != 32) return false;
          final actual = await _derive(password, salt);
          var difference = 0;
          for (var i = 0; i < expected.length; i++) {
            difference |= expected[i] ^ actual[i];
          }
          return difference == 0;
        } on FormatException {
          return false;
        } on TypeError {
          return false;
        }
      });

  static Future<List<int>> _derive(String password, List<int> salt) async {
    final algorithm = Argon2id(memory: memory, iterations: iterations, parallelism: 1, hashLength: 32);
    final key = await algorithm.deriveKeyFromPassword(password: password, nonce: salt);
    return key.extractBytes();
  }
}
