# Resume here

- CURRENT PHASE: 1; mapping increment PASS, complete phase still pending.
- VERIFIED SERVER: e841190241c2cfcc939551a575dee9a58b3b3e99, run 37538670785: ERPNext/app install+migrate and 20 tests PASS (4 pure, 11 database, 5 HTTP).
- VERIFIED CLIENT: 37538221425: 68 Flutter tests per runner, 17 SQL checks, analysis, Android/Windows debug builds PASS. Artifacts 11448270020 / 11447321856 expire October 20.
- COMPLETED: isolated Docker CI plus yem_erp_core bindings, authorization, native REST tenant rules, audit, retry/conflict/rollback and identity rename guards.
- EXACT RESOLVED ERRORS: install ERPNext setup fixtures before companies (Transit type); grant HTTP fixture Stock User for Item reads without bypassing permissions; follow Frappe v16 permission veto contract.
- FILES: server/, .github/workflows/phase1.yml; Phase 0 workflow avoids duplicate same-repo PR builds.
- NEXT CODE TASK: define and implement the Phase 1 business-document API contract using ERPNext validation/posting. Existing mapping API only binds existing records; it does not transfer/create documents. Explicitly test company/account/warehouse references, permissions, idempotency and atomic document/mapping/audit rollback. Then close the complete Phase 1 integration gate before Phase 2.
- NEXT COMMAND: inspect current branch/server tests, run python -m unittest discover -s server/tests -v; use the Phase 1 push workflow for actual ERPNext checks. Read docs/PHASE1_GATE.md.
- DEPLOYMENT INPUT: persistent host/OS/execution route and LAN/online endpoint still required for a deployed service. Do not wait for those to improve isolated testable code; do not claim CI is hosting.
- DO NOT REDO: verified client Phase 0 or server identity foundation. No force-push, no merging draft while later gates are incomplete.
- DEVICE/RELEASE: physical devices, native credential runtime, printing, strict offline/LAN/online variants and production signing remain unverified/incomplete.
