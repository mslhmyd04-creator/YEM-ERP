# Changelog

## 0.0.1 — 2026-09-28

- Started phase 0 Flutter source layout and Arabic RTL app shell.
- Preserved the master plan and execution instructions.
- Added product identity validation tests; execution awaits Flutter SDK.
- Added migration 001 for tenant, access-control, product, party and warehouse tables; four transient SQLite constraint tests pass.
- Added GitHub Actions checks for migration, Flutter analysis, unit tests and Android debug build; CI results pending.
- Replaced the generated sample widget test with an Arabic RTL app-shell test after the first CI analysis failure.
- Confirmed migration, Flutter analysis/tests and Android debug scaffold build in GitHub Actions run 36461872576.
- Retained generated Android/Windows platform source and added SQLCipher local database opening, protected keys, migration and encrypted-file tests (CI verification pending).
- Verified SQLCipher tests, Flutter analysis and Android debug build in GitHub Actions run 36464020834; added company-scoped product repository and tests (verification pending).
- Verified product repository tests and Android debug build in run 36464645152; added a Windows CI job (verification pending).

- 2026-09-30: Added migration 002 and local authentication/RBAC with password hashing, lockout, expiring sessions and atomic product audit; verification pending.

- 2026-09-30: Connect startup to encrypted storage; add Arabic setup/login/product UI and an end-to-end widget workflow.

- CI now retains Android APK and complete Windows debug output for device testing; documentation-only changes skip builds.

- Verified 2026-09-30: run 36752011534 passed 9 SQL checks, static analysis, 18 Flutter tests on both runners, Android/Windows builds and debug artifact uploads. Device verification remains pending.

- 2026-10-05: Add master-data services/repository and Arabic create/edit forms; optional product category binding; migration 003 and upgrade/permission/tenant/audit/UI tests. Verification PENDING CI.

- 2026-10-05: Verified master data in run 37333836540. Add branch create/edit with stable references, migration 004 and system dark theme; CI pending.

- Add regression test that branch renaming preserves existing user and warehouse references.

- 2026-10-05: Final branch/master increment verified in run 37335012029: 10 SQL checks, analysis, 25 Flutter tests on Ubuntu/Windows, both builds and debug package uploads PASS. Physical-device acceptance still NOT VERIFIED.
