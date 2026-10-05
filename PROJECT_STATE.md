# Project state

- Project Version: 0.0.1 development prototype
- Current Phase: 0 — incomplete
- Current Task: Expenses and basic custody, then invoice/PDF
- Completed Tasks: encrypted Android/Windows storage; migrations 001–006; local setup/login/RBAC; audited product create/archive; categories/units/customers/suppliers/warehouses create/edit; branch create/edit; product category selection; Arabic RTL and system light/dark themes; user/role administration, last-active-administrator protection and stale-session invalidation; exact-money central posting, immutable journals and conflict-aware retries.
- Pending Tasks: expenses, basic custody, basic invoice and PDF; physical-device acceptance; Phase 0 gate. Phases 1–9 remain pending.
- Current Branch: feat/phase-0-foundation
- Last Commit: see git log and GitHub PR #1 (connector/local commit IDs differ)
- Build Status: Android/Windows builds and debug artifact uploads PASS in run 37342842602; tested code commit 4b69b55db84efc186b841fab052d1df291995f33.
- Test Status: 13 SQL checks PASS locally/CI; analysis PASS; 44 Flutter tests PASS on Ubuntu and Windows in run 37342842602.
- Database Migration Status: schema version 6; encryption/reopening, upgrade/history validation, rollback and original-manager permission migration tested in CI. Physical-device migration NOT VERIFIED.
- Known Errors: none in current analysis/tests. Local Flutter/Dart unavailable; native builds run in GitHub Actions.
- Important Decisions: DECISIONS.md. SQL identifiers are enum-whitelisted; tenant values parameterized; edits preserve referenced IDs; each master type has separate permissions and atomic audit.
- Files Modified: see commits for master data, branch management and reference tests.
- Next Task: compose expense/basic custody documents with the verified posting engine. Business documents, custody movements, audit and journal must commit together; retries must compare the complete business payload.
- Exact Next Command: flutter pub get && flutter analyze && flutter test && flutter build apk --debug. On Windows also flutter build windows --debug.
- Device Status: secure credential backend, installation and actual layout checks NOT VERIFIED; follow docs/PHASE0_DEVICE_TESTS.md.
