# Project state

- Project Version: 0.0.1 development prototype
- Current Phase: 1 — mapping/API foundation verified; complete business integration and persistent deployment pending
- Current Task: complete the Phase 1 business-document API contract before synchronization
- Phase 0: local encrypted auth/RBAC/master data, balanced posting, basic expenses/custody, stock-backed sales and Arabic PDF remain verified.
- Client Validation: run 37538221425; analysis, 68 Flutter tests per Ubuntu/Windows runner, 17 SQL checks, Android/Windows debug builds and uploads PASS. No client feature change in this server increment.
- Server Code: e841190241c2cfcc939551a575dee9a58b3b3e99; run 37538670785 PASS.
- Server Validation: official ERPNext v16.50.0 with MariaDB 11.8/Redis 6.2; app installation/migration PASS; 4 pure identity + 11 installed database + 5 actual HTTP tests PASS.
- Implemented Server: yem_erp_core; nine supported mapping types; immutable scoped UUID bindings; explicit Company grants; target read permissions; native REST query/doc permission hooks; transactional Comment audit; duplicate/conflict controls; bound item/company rename protection.
- Server Scope: binding EXISTING documents, not creating/posting financial or stock documents. capabilities.sync_ready=false. Full Phase 1 NOT complete.
- Database Migration Status: local schema 8 verified; installed server mapping DocType migration verified in disposable CI. Physical-device migration NOT VERIFIED.
- Artifacts: Android 11448270020; Windows 11447321856; run 37538221425; expires 2026-10-20.
- Known Errors: Transit fixture setup and insufficient Item permission in test user resolved. Latest native and server checks PASS. Local Docker/Flutter unavailable; corresponding checks run in GitHub Actions.
- Persistent Target: not supplied; CI site is disposable, unpublished and removed after testing. No claim of production hosting.
- Pending Tasks: Phase 1 business-document APIs/integration and persistent deployment; Phases 2–9; user-device acceptance/release signing.
- Next Task: see NEXT_TASK.md and docs/PHASE1_GATE.md. Do not redo verified mapping foundations or call current debug APK/Windows builds final.
- Device Status: installation, secure credential backend, restart/upgrade and physical printing NOT VERIFIED.
