# Project state

- Project Version: 0.0.1 development prototype
- Current Phase: 1 — isolated CI server implementation; Phase 0 software gate PASS
- Current Task: Verify the disposable ERPNext v16.50.0 CI site and yem_erp_core mapping API
- Completed Tasks: encrypted Android/Windows storage; migrations 001–008; setup/login/RBAC; products/master/branch forms; protected user/role administration; exact balanced immutable posting; basic cash/custody expenses; stock opening and atomic cash/credit/service invoices; offline Arabic PDF and session-aware print boundary.
- Latest Verified Code: 5d8c545edab01de34072550d0eee1e1ec630f90e; run 37352094707. Connector/local commit IDs differ.
- Build Status: Android and Windows debug builds and uploads PASS.
- Test Status: analysis PASS; 68 Flutter tests PASS on each Ubuntu/Windows runner; 17 SQL checks PASS locally/CI.
- PDF Status: seven A4 pages, embedded Amiri/Unicode mapping, all 50 lines, maximum amount, long SKU, repeated headers and inseparable summary structurally/visually PASS. Details: docs/PHASE0_PDF_QA.md.
- Database Migration Status: schema 8; encryption/reopen, history/upgrade/rollback, tenant references and stable account UUIDs tested. Physical-device migration NOT VERIFIED.
- Known Errors: current native/SQL checks pass; earlier PDF import/const/assertion/page-break issues resolved. Local Flutter/Dart SDK unavailable. A late local shell became unresponsive; final documentation checkpoint is written directly to GitHub. Retrieve the latest branch documentation before resuming if the workspace copy differs.
- Artifacts: Android 11362299404; Windows 11363252267; PDF fixture 11362513485; expire 2026-10-19.
- Test target: disposable GitHub Actions Docker site, ERPNext v16.50.0. Production target still unspecified. Real server integration PENDING CI; four pure identity tests PASS locally.
- Pending Tasks: user-device acceptance; Phase 1 deployment/custom app/mapping/APIs/integration; Phases 2–9 pending.
- Next Task: inspect Phase 1 server integration workflow; fix installation/test failures before further features. Then HTTP auth/concurrent mapping tests and remaining Phase 1 API/target gate. Do not start Phase 2 yet.
- Device Status: installation, native secure credentials, restart/upgrade and physical print/save NOT VERIFIED. Follow docs/PHASE0_DEVICE_TESTS.md.
