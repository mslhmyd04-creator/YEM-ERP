# Tasks

## Phase 0

- [x] Preserve supplied specifications and initialize versioned source tree.
- [x] Establish Flutter source layout and Arabic RTL app entry point.
- [x] Generate Android/Windows platform runners using Flutter SDK and retain source files.
- [x] Run `flutter analyze`, `flutter test`, and debug Android scaffold build in GitHub Actions.
- [x] Verify SQLCipher binding, secure key storage and first-open migration in CI.
- [ ] Verify encrypted database/key behavior on Android and Windows devices.
- [x] Draft migration 001 for tenant, roles, catalog, and counterparties; validate SQLite constraints in memory.
- [x] Add GitHub checks for migration, Flutter analysis, unit tests and debug Android build.
- [ ] Verify migration upgrades and rollback on devices (first-open integration passed CI).
- [x] Add first-company/branch/admin setup, local authentication, stored role permissions and permission checks.
- [x] Test local lockout, session expiry, revoked permissions and audited product rollback in CI.
- [x] Add user/role/branch administration UI; security and widget tests pass in run 37340719874.
- [x] Add authorized Arabic setup/login/product UI and widget workflow tests.
- [x] Verify company-scoped product repository create/list/archive tests in CI.
- [x] Verify Windows SQLCipher tests and debug build in GitHub CI (36465256956).
- [x] Add categories, units, customers, suppliers, warehouses and authorized UI workflows (run 37333836540).
- [x] Verify branch create/edit, migration 004 and preserved user/warehouse references (37335012029).
- [x] Add exact-money, balanced/immutable posting foundation with retry/conflict and SQL guards (37342842602).
- [x] Add basic cash opening, custody issue and cash/custody expense forms; atomic document/journal/ledger tests and builds pass (37345926353).
- [x] Add basic stock-backed sales invoice and Arabic PDF printing (37352094707).
- [x] Pass Phase 0 software gates: analysis, 68 Flutter tests per runner, 17 SQL checks and both debug builds (37352094707).

Phase 0 software gate PASS. Phase 1 target intake is blocked on the server/site and execution route; Phases 2–9 remain pending.

## Later phase gates

- Phase 1: Frappe/ERPNext deployment, custom `yem_erp_core`, API mapping, integration checks.
- Phase 2: outbox/inbox, idempotency, checkpoint, conflict queue, interrupted sync tests.
- Phase 3: custody ledger, approvals, transfers, settlements, balances and receipt tests.
- Phase 4: balanced posting engine, GL integration, fiscal periods and accounting tests.
- Phase 5: stock ledger, serial/batch, valuation, transfers, count and inventory tests.
- Phase 6: consented exchange notifications, parsing, deduplication, matching and reconciliation.
- Phase 7: Flutter Windows workflows, reporting, printing and desktop build checks.
- Phase 8: encryption, device activation, backup/restore, audit and security checks.
- Phase 9: signed releases, migration/integration/regression checks and deployment packages.

- [x] Verify basic immutable stock opening and atomic cash/credit/service sales invoices (37349903517).
- [x] Verify bundled Arabic PDF rendering, pagination and native print builds (37352094707); user-device printing NOT VERIFIED.

## Phase 1 current increment
- [x] Implement disposable CI target, custom Frappe app and mapping/security contract.
- [x] Run four pure identity tests locally.
- [ ] Verify ERPNext/app installation, migration and database integration tests in CI.
- [ ] Verify authenticated HTTP boundary/concurrent retry behavior and complete Phase 1 contract.
- [ ] Identify and verify persistent deployment target before production release.
