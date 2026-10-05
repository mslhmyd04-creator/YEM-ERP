# Project state

- Project Version: 0.0.1 development prototype
- Current Phase: 0 — incomplete
- Current Task: Financial posting foundation, then expenses/custody/invoice/PDF
- Completed Tasks: encrypted Android/Windows storage; migrations 001–005; local setup/login/RBAC; audited product create/archive; categories/units/customers/suppliers/warehouses create/edit; branch create/edit; product category selection; Arabic RTL and system light/dark themes; user/role administration, last-active-administrator protection and stale-session invalidation.
- Pending Tasks: expenses, basic custody, basic invoice and PDF; physical-device acceptance; Phase 0 gate. Phases 1–9 remain pending.
- Current Branch: feat/phase-0-foundation
- Last Commit: see git log and GitHub PR #1 (connector/local commit IDs differ)
- Build Status: Android/Windows builds and debug artifact uploads PASS in run 37340719874; tested code commit ecfb36c8e64941b74a36eb7b7dabdca9a44c757d.
- Test Status: 10 SQL checks PASS locally/CI; analysis PASS; 36 Flutter tests PASS on Ubuntu and Windows in run 37340719874.
- Database Migration Status: schema version 5; encryption/reopening, upgrade/history validation, rollback and original-manager permission migration tested in CI. Physical-device migration NOT VERIFIED.
- Known Errors: none in current analysis/tests. Local Flutter/Dart unavailable; native builds run in GitHub Actions.
- Important Decisions: DECISIONS.md. SQL identifiers are enum-whitelisted; tenant values parameterized; edits preserve referenced IDs; each master type has separate permissions and atomic audit.
- Files Modified: see commits for master data, branch management and reference tests.
- Next Task: implement exact-money and balanced atomic posting foundation before expense/custody/invoice workflows. Preserve immutable posted records and reject conflicting duplicate references.
- Exact Next Command: flutter pub get && flutter analyze && flutter test && flutter build apk --debug. On Windows also flutter build windows --debug.
- Device Status: secure credential backend, installation and actual layout checks NOT VERIFIED; follow docs/PHASE0_DEVICE_TESTS.md.

- Financial foundation implemented with migration 006 and exact posting/retry/immutability tests; native verification PENDING CI. Business financial forms remain pending.
