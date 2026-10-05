# Resume here

- CURRENT PHASE: 0 — incomplete
- WHAT WAS COMPLETED: branches, categories, units, customers, suppliers and warehouses have audited create/edit/list services and connected Arabic forms; products select categories/units. Schema version 4, existing IDs preserved, granular master permissions.
- WHAT IS WORKING: master data PASS in run 37333836540 (24 Flutter tests on both runners, 10 SQL checks, analysis and both debug builds). Final branch increment PASS in run 37335012029: analysis, 25 Flutter tests on Ubuntu/Windows, 10 SQL checks, Android/Windows builds and debug package uploads. Tested code SHA 84d3089a445f4a43b9d7c621a6c11bb9d7de7593.
- WHAT IS NOT WORKING: user/role administration UI and remaining financial/PDF workflows not implemented; device acceptance NOT VERIFIED.
- EXACT ERROR IF ANY: none in current analysis/tests. Local Flutter/Dart unavailable.
- FILES MODIFIED: see GitHub commits 0a434758d7370e145767f06c3ca39dc3e67f2f79, 82579cca04c341a1c625e18ab95afc720134f195, 84d3089a445f4a43b9d7c621a6c11bb9d7de7593.
- NEXT TASK: implement company-scoped user/role administration with tests. Prevent disabling/removing the last active administrator and invalidate prior sessions after password reset. Continue expenses/basic custody/invoice/PDF after administration passes.
- NEXT COMMAND: flutter pub get && flutter analyze && flutter test && flutter build apk --debug. On Windows also flutter build windows --debug.
- EXPECTED RESULT: user/role administration must pass tenant, last-administrator, credential/session and UI tests plus both native builds. Preserve the verified baseline.
- DO NOT REDO: scaffold, encryption/auth and completed master-data flows. Do not advance Phase 1 before Phase 0 passes build/unit/migration gates. Never claim all ERP phases or device validation complete.

- Current checkpoint: inspect administration CI, resolve any errors before continuing financial Phase 0 workflows. Prior master/branch increment remains verified.
