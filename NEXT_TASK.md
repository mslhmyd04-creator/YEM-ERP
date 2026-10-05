# Resume here

- CURRENT PHASE: 0 — incomplete
- WHAT WAS COMPLETED: encrypted local setup/auth, product/master/branch forms, user/role administration, exact-money and central balanced immutable journal posting; basic cash funding, custody issue and cash/custody expenses with Arabic forms. Migration 006 grants financial permissions without depending on an editable manager role name.
- WHAT IS WORKING: run 37345926353 / code 3876735f8b47e6c9f20d931b639416a59cd441cd passed analysis, 53 Flutter tests on Ubuntu/Windows, 15 SQL checks, both debug builds and artifact uploads. Schema version 7. Android artifact 11359489873; Windows artifact 11359929981.
- WHAT IS NOT WORKING: basic sales invoice/PDF pending; physical-device acceptance NOT VERIFIED. Posting currently supports YER with two-decimal precision only.
- EXACT ERROR IF ANY: permission migration and schema constraint-order issues resolved; native and SQL checks pass. Local Flutter/Dart unavailable.
- FILES MODIFIED: domain money/journal, journal repository, PostingEngine, migration 006, permission configuration and eight Flutter posting tests plus three Python SQL guard tests.
- NEXT TASK: basic sales invoice and PDF. Stocked goods need an initial stock ledger/opening balance and exact sale-cost posting: reject negative stock, derive quantities/values from immutable movements, validate the stock snapshot under the posting lock, and commit invoice/GL/stock/audit together. Add explicit stock/non-stock product flag (existing products remain stocked), inventory/COGS account classification without rebuilding referenced account IDs, and tests. Whole-unit quantities and YER precision are Phase 0 limits; advanced inventory remains Phase 5.
- NEXT COMMAND: python -m unittest discover -s tools -p 'check_*.py' -v; run analysis/tests and Android/Windows builds in GitHub Actions after implementation.
- EXPECTED RESULT: atomic business/ledger rollback, exact balances, authorization/tenant references, duplicate conflict/retry and UI tests pass with both builds.
- DO NOT REDO: verified scaffold, encryption/auth, master data, administration or posting foundation. Keep immediate posting/no-tax-separation/no-approval/transfer/settlement limits explicit. Stay in Phase 0; Phases 1–9 and signed releases/device acceptance remain pending.
