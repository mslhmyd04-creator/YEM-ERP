# Project state

- Project Version: 0.0.1 development prototype
- Current Phase: 0 — incomplete
- Current Task: Basic stock-backed sales invoice and PDF
- Completed Tasks: encrypted Android/Windows storage; migrations 001–007; local setup/login/RBAC; audited product create/archive; categories/units/customers/suppliers/warehouses create/edit; branch create/edit; product category selection; Arabic RTL and system light/dark themes; user/role administration, last-active-administrator protection and stale-session invalidation; exact-money central posting, immutable journals and conflict-aware retries; basic cash opening/custody issue/cash and custody expenses with Arabic forms and atomic business/ledger saves.
- Pending Tasks: basic stock-backed invoice and PDF; physical-device acceptance; Phase 0 gate. Phases 1–9 remain pending.
- Current Branch: feat/phase-0-foundation
- Last Commit: see git log and GitHub PR #1 (connector/local commit IDs differ)
- Build Status: Android/Windows builds and debug artifact uploads PASS in run 37345926353; tested code commit 3876735f8b47e6c9f20d931b639416a59cd441cd.
- Test Status: 15 SQL checks PASS locally/CI; analysis PASS; 53 Flutter tests PASS on Ubuntu and Windows in run 37345926353.
- Database Migration Status: schema version 7; encryption/reopening, upgrade/history validation, rollback and original-manager permission migration tested in CI. Physical-device migration NOT VERIFIED.
- Known Errors: none in current analysis/tests. Local Flutter/Dart unavailable; native builds run in GitHub Actions.
- Important Decisions: DECISIONS.md. SQL identifiers are enum-whitelisted; tenant values parameterized; edits preserve referenced IDs; each master type has separate permissions and atomic audit.
- Files Modified: see commits for master data, branch management and reference tests.
- Next Task: implement basic sales invoices and PDF. For stocked goods, add basic stock opening/ledger and sale-cost posting before invoices; preserve exact values, negative-stock rejection and atomic document/GL/stock commits.
- Exact Next Command: flutter pub get && flutter analyze && flutter test && flutter build apk --debug. On Windows also flutter build windows --debug.
- Device Status: secure credential backend, installation and actual layout checks NOT VERIFIED; follow docs/PHASE0_DEVICE_TESTS.md.

- Stock/sales checkpoint: migration 008, immutable stock opening/sale movements, exact weighted-average cost and cash/credit/service invoices verified in 37349903517 / f4e86a454b6f3e93ba00be0f02e57768bc89c371. 17 SQL checks and all native jobs PASS. Offline Arabic PDF implementation currently under verification.
