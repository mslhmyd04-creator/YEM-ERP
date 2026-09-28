# Engineering decisions

- ADR-001 (2026-09-28): Flutter targets Android and Windows; Arabic is the default interface direction.
- ADR-002 (2026-09-28): ERPNext/Frappe is the planned server. Custom behavior belongs in `yem_erp_core`, not ERPNext core.
- ADR-003 (2026-09-28): Offline strict storage requires SQLCipher or equivalent audited encryption with keys in platform secure storage. No plaintext SQLite fallback for financial data.
- ADR-004 (2026-09-28): The current scaffold displays no data-entry controls until persistent encrypted storage and migrations are verified.
- ADR-005 (2026-09-28): Migration SQL is tested using only an ephemeral in-memory SQLite database. It must run against encrypted production storage after the Flutter database binding and secure key storage are chosen. `sqflite_sqlcipher` is Android/iOS focused, so it is not assumed to solve the Windows target.
- ADR-006 (2026-09-28): Use the `sqlite3` 3.x SQLCipher build hook on Android/Windows and `flutter_secure_storage` for the per-install raw 256-bit database key. Reject missing cipher, missing keys for existing files and wrong keys. This integration remains unverified until CI/device tests pass. References: https://pub.dev/documentation/sqlite3/latest/topics/hook-topic.html and https://www.zetetic.net/sqlcipher/sqlcipher-api/.
