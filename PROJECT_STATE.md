# Project state

- Project Version: 0.0.1 development foundation
- Current Phase: 0 — prototype
- Current Task: Continue remaining Phase 0 data workflows after verified auth/catalog increment
- Current Branch: feat/phase-0-foundation
- GitHub Review: draft PR #1
- Last Commit: see git log and the PR head (local/connector commit IDs differ)
- Completed: Flutter Android/Windows runners, Arabic RTL source, SQLCipher installation key management, tenant-scoped core schema, migration 002, Argon2id local login, lockout/session/permissions, audited catalog setup/create/archive UI.
- Build Status: Android/Windows current debug builds and package uploads PASS in run 36752011534 (code commit 337817009d57dc2046a3c9746cd61dd8f0e5172f).
- Test Status: 9 Python SQL checks PASS. Flutter analysis PASS; 18 Flutter tests PASS on Ubuntu and Windows in run 36752011534.
- Migration Status: upgrade/history validation and transactional rollback tested in CI; physical-device upgrade NOT VERIFIED.
- Device Status: Android/Windows real credential-backend checks NOT VERIFIED; see docs/PHASE0_DEVICE_TESTS.md.
- Known Errors: earlier style/deprecation and UI parenthesis errors corrected; current analysis PASS. Local Flutter/Dart unavailable, so native verification runs in GitHub Actions.
- Pending Phase 0: master data including customers/warehouses, expenses/custody, invoice/PDF, device acceptance and phase gate.
- Pending Phases 1–9: ERPNext server, sync, ledgers, advanced inventory, exchange notifications, reporting, security/backup and signed releases. Do not advance before Phase 0 gate passes.
- Important Decisions: DECISIONS.md
- Files Modified: see latest commit
- Next Task: continue customers/warehouses and other master-data workflows.

## 2026-10-05 master data increment

- Implemented create/edit/list for categories, units, customers, suppliers and warehouses; Arabic connected forms; product category selection.
- Migration 003 adds granular permissions and upgrades only original bootstrap manager role.
- 10 Python SQL checks PASS locally. Flutter analysis/tests/builds PENDING CI.
- Current task: verify increment on Ubuntu/Windows, fix failures before additional features.

- Master data increment PASS: run 37333836540, code commit 0a434758d7370e145767f06c3ca39dc3e67f2f79, 10 SQL checks and 24 Flutter tests on Ubuntu/Windows, analysis, builds and uploads.
- Next increment: branches join the authorized master-data form; migration 004; restore system dark theme. Verification PENDING CI.
