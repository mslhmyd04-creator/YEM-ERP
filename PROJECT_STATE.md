# Project state

- Project Version: 0.0.1 development prototype
- Current Phase: 0 — incomplete
- Current Task: User/role administration, then remaining financial Phase 0 workflows
- Completed Tasks: encrypted Android/Windows storage; migrations 001–004; local setup/login/RBAC; audited product create/archive; categories/units/customers/suppliers/warehouses create/edit; branch create/edit; product category selection; Arabic RTL and system light/dark themes.
- Pending Tasks: user/role administration; expenses, basic custody, basic invoice and PDF; physical-device acceptance; Phase 0 gate. Phases 1–9 remain pending.
- Current Branch: feat/phase-0-foundation
- Last Commit: see git log and GitHub PR #1 (connector/local commit IDs differ)
- Build Status: Android/Windows builds and debug artifact uploads PASS in run 37335012029; tested code commit 84d3089a445f4a43b9d7c621a6c11bb9d7de7593.
- Test Status: 10 SQL checks PASS locally/CI; analysis PASS; 25 Flutter tests PASS on Ubuntu and Windows in run 37335012029.
- Database Migration Status: schema version 4; encryption/reopening, upgrade/history validation, rollback and original-manager permission migration tested in CI. Physical-device migration NOT VERIFIED.
- Known Errors: none in current analysis/tests. Local Flutter/Dart unavailable; native builds run in GitHub Actions.
- Important Decisions: DECISIONS.md. SQL identifiers are enum-whitelisted; tenant values parameterized; edits preserve referenced IDs; each master type has separate permissions and atomic audit.
- Files Modified: see commits for master data, branch management and reference tests.
- Next Task: implement user/role administration with company boundaries, last-administrator protection and password-change session invalidation before financial Phase 0 workflows.
- Exact Next Command: flutter pub get && flutter analyze && flutter test && flutter build apk --debug. On Windows also flutter build windows --debug.
- Device Status: secure credential backend, installation and actual layout checks NOT VERIFIED; follow docs/PHASE0_DEVICE_TESTS.md.
