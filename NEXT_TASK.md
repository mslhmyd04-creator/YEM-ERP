# Resume here

- CURRENT PHASE: 0 — incomplete
- WHAT WAS COMPLETED: encrypted local setup/auth, product/master/branch forms, user/role administration, exact-money and central balanced immutable journal posting. Migration 006 grants financial permissions without depending on an editable manager role name.
- WHAT IS WORKING: run 37342842602 / code 4b69b55db84efc186b841fab052d1df291995f33 passed analysis, 44 Flutter tests on Ubuntu/Windows, 13 SQL checks, both debug builds and artifact uploads. Schema version 6. Android artifact 11358729252; Windows artifact 11358319731.
- WHAT IS NOT WORKING: expense/basic custody/invoice/PDF workflows and forms pending; physical-device acceptance NOT VERIFIED. Posting currently supports YER with two-decimal precision only.
- EXACT ERROR IF ANY: migration duplicate permission definition resolved with INSERT OR IGNORE; native and SQL checks pass. Local Flutter/Dart unavailable.
- FILES MODIFIED: domain money/journal, journal repository, PostingEngine, migration 006, permission configuration and eight Flutter posting tests plus three Python SQL guard tests.
- NEXT TASK: add expense and basic custody services/repositories/schema and Arabic forms. Refactor posting transaction composition so business documents, custody movements and journals commit together; canonical retries must include the complete business payload. Custody balances come from ledger; reject insufficient funds and foreign references. Then basic invoice and PDF.
- NEXT COMMAND: python -m unittest discover -s tools -p 'check_*.py' -v; run analysis/tests and Android/Windows builds in GitHub Actions after implementation.
- EXPECTED RESULT: atomic business/ledger rollback, exact balances, authorization/tenant references, duplicate conflict/retry and UI tests pass with both builds.
- DO NOT REDO: verified scaffold, encryption/auth, master data, administration or posting foundation. Stay in Phase 0; Phases 1–9 and signed releases/device acceptance remain pending.
