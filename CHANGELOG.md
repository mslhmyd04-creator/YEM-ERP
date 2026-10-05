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

- 2026-10-05: Add audited user/role administration, limited-user dashboard navigation, session revision invalidation and migration 005; administration/security/UI tests added; CI pending.

- Bind pending administrative changes to the original session object; logout/re-login during hashing cancels the request, even for the same user. Regression test added.

- 2026-10-05: Administration verified in 37340719874: analysis, 36 Flutter tests on each runner, 10 SQL checks, Android/Windows builds and package uploads PASS. Widget fixtures run outside FakeAsync and unfocus before scrolling/tapping.

- 2026-10-05: Add migration 006, exact money parsing, account/journal repository and central posting engine with company boundaries, balanced finalization, immutable posted records and conflict-aware retries. Verification PENDING CI.

- 2026-10-05: Financial foundation verified in run 37342842602: analysis, 44 Flutter tests on each runner, 13 SQL checks, Android/Windows builds and debug artifact uploads PASS. Expense/custody/invoice/PDF business workflows remain pending.

- 2026-10-05: Add basic cash funding, custody issue, cash/custody expenses and Arabic forms. Migration 007 verifies document/journal links and immutable custody movements; business writes share the posting transaction, retries compare full category/owner/source payload and insufficient funds are rejected. Native verification PENDING CI.

- 2026-10-05: Basic expense/custody increment verified in 37345926353: analysis, 53 Flutter tests per runner, 15 SQL checks, both builds and debug uploads PASS. Basic invoice/PDF and physical-device acceptance remain pending.

- 2026-10-05: Basic stock opening/cash and credit sales verified in 37349903517 (code f4e86a454b6f3e93ba00be0f02e57768bc89c371): analysis, both Flutter test suites, 17 SQL checks and Android/Windows debug builds PASS. Add offline Arabic invoice PDF and session-aware native print boundary; PDF/native verification pending.
