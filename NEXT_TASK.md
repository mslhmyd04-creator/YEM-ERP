# Resume here

- CURRENT PHASE: 0 — incomplete
- WHAT WAS COMPLETED: audited master data, branches, products, user/role administration; scoped Arabic forms, last-administrator protection, password/session revisions, cancellation of pending changes on logout/re-login.
- WHAT IS WORKING: run 37340719874 / code ecfb36c8e64941b74a36eb7b7dabdca9a44c757d passed analysis, 36 Flutter tests on Ubuntu/Windows, 10 SQL checks, both debug builds and artifact uploads. Schema version 5.
- WHAT IS NOT WORKING: financial workflows and PDF not implemented; device acceptance NOT VERIFIED.
- EXACT ERROR IF ANY: administration test scrolling/focus and cached-asset FakeAsync setup issues resolved. Local SDK unavailable; native checks run on GitHub.
- FILES MODIFIED: administration service/repository/domain/page, migration 005, auth session revision, permission-based dashboard, CI test diagnostics and administration unit/widget tests.
- NEXT TASK: implement exact integer monetary amounts and central balanced posting foundation for Phase 0 expenses/custody/invoice. Each posted entry is immutable; tenant/branch/account ownership enforced; retries must not duplicate or change postings. Do not expose a fake financial UI before services exist.
- NEXT COMMAND: python -m unittest discover -s tools -p 'check_*.py' -v; run flutter analyze/test and Android/Windows builds in GitHub Actions after changes.
- EXPECTED RESULT: money precision, imbalance, wrong-tenant references, rollback, duplicate retry/conflict and immutability tests pass before business workflows.
- DO NOT REDO: scaffold, SQLCipher/auth, verified master-data or administration. Keep all work in Phase 0. Phases 1–9 and release/device acceptance remain pending.
