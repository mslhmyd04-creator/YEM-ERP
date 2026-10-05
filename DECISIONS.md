# Engineering decisions

- ADR-001 (2026-09-28): Flutter targets Android and Windows; Arabic is the default interface direction.
- ADR-002 (2026-09-28): ERPNext/Frappe is the planned server. Custom behavior belongs in `yem_erp_core`, not ERPNext core.
- ADR-003 (2026-09-28): Offline strict storage requires SQLCipher or equivalent audited encryption with keys in platform secure storage. No plaintext SQLite fallback for financial data.
- ADR-004 (2026-09-28): The current scaffold displays no data-entry controls until persistent encrypted storage and migrations are verified.
- ADR-005 (2026-09-28): Migration SQL is tested using only an ephemeral in-memory SQLite database. It must run against encrypted production storage after the Flutter database binding and secure key storage are chosen. `sqflite_sqlcipher` is Android/iOS focused, so it is not assumed to solve the Windows target.
- ADR-006 (2026-09-28): Use the `sqlite3` 3.x SQLCipher build hook on Android/Windows and `flutter_secure_storage` for the per-install raw 256-bit database key. Reject missing cipher, missing keys for existing files and wrong keys. This integration remains unverified until CI/device tests pass. References: https://pub.dev/documentation/sqlite3/latest/topics/hook-topic.html and https://www.zetetic.net/sqlcipher/sqlcipher-api/.

- 2026-09-30: Local passwords use Argon2id (19 MiB, two iterations, one lane), random salt; hashing runs outside UI isolate. Session expires after 30 minutes; five failed logins lock account for 15 minutes. Migration batches are atomic and verify history before opening.

- 2026-10-05: Master data uses an enum whitelist for SQL identifiers and parameterized values. Each type has separate view/create/update permissions. Migration 003 grants them only to the original bootstrap manager identified by setup audit, not every existing role. Existing IDs and tenant references remain stable during edits; deletion is not exposed.

- 2026-10-05: Branch editing reuses the authorized master-data flow and preserves IDs referenced by users/warehouses. Branch create/update permissions are separate; migration 004 upgrades only the bootstrap manager.

- 2026-10-05: User edits increment auth_revision; sessions validate it on each operation and login rechecks it after hashing. Transactions prevent removal of the last active user holding administration.manage. Password reset hashes off the UI isolate, revalidates actor permission, invalidates old sessions and audits without storing secret values.

- 2026-10-05: Phase 0 financial foundation supports YER at two-decimal fixed precision and rejects unsupported currencies. Amounts and balanced totals are exact integers with explicit limits; balances accumulate as BigInt. Posted journals/lines are immutable, retries use company/business-reference UUID and canonical payload; audit/sequence/posting commit together. Migration permission upgrade uses bootstrap audit and current management permission so role renaming does not break it. Full multi-currency/fiscal/stock/reversal workflows remain later work.

- 2026-10-05: Phase 0 basic custody/expense workflows post immediately without tax separation or approval/transfer/settlement. Default expense categories share one general expense account. Opening balances/configuration require administration.manage; financial operations use finance.post. Synchronous prepare/persist callbacks compose business writes with posting/audit/sequence in one transaction; null business payload keeps prior version-6 canonical retry format compatible.

- Basic Phase 0 inventory uses whole units, positive opening cost and exact moving weighted-average cost rounded half-up in minor units; full depletion consumes the complete residual value. Negative stock is denied. Quantity and value derive from immutable stock movements. Inventory and COGS classification uses an additive account_type column to preserve existing account UUIDs and journal references.
- Invoice/customer/item names are frozen at posting, while retry identity compares source IDs, quantities, prices and payment choices. Posted invoice/GL/stock/audit save in one transaction. The cost snapshot is rechecked under the posting lock; a retry after later stock changes uses the stored cost.
- Arabic invoice PDF embeds unmodified licensed Amiri locally and requires sales.view before and after asynchronous rendering, with the same session identity. No runtime font download. Phase 0 invoice has no tax separation, returns or fractional quantities.
