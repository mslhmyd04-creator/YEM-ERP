# Tasks

## Phase 0

- [x] Preserve supplied specifications and initialize versioned source tree.
- [x] Establish Flutter source layout and Arabic RTL app entry point.
- [x] Generate Android/Windows platform runners using Flutter SDK and retain source files.
- [x] Run `flutter analyze`, `flutter test`, and debug Android scaffold build in GitHub Actions.
- [ ] Verify SQLCipher binding, secure key storage and encrypted migration integration in CI and on devices (implementation added).
- [x] Draft migration 001 for tenant, roles, catalog, and counterparties; validate SQLite constraints in memory.
- [x] Add GitHub checks for migration, Flutter analysis, unit tests and debug Android build.
- [ ] Verify migration 001 under encrypted Flutter storage, upgrades and rollback on devices (first-open integration added).
- [ ] Add local authentication, company, branch, users, roles, permissions.
- [ ] Add products, categories, units, customers, suppliers, warehouses.
- [ ] Add expenses, basic custody, sales invoice, and PDF printing.
- [ ] Pass phase 0 build, unit, and migration gates.

Phases 1–9 remain blocked until phase 0 passes its gate.

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
