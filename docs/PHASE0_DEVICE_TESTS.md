# Phase 0 device acceptance

This is a development increment, not a production ERP release. Run with disposable test data on an Android 8.0+ device and a Windows test machine. Automated runner tests use test key stores and do not certify the real device credential backend.

## Obtain the packages

Open the latest successful Phase 0 checks run in GitHub Actions. Download `yem-erp-android-debug` or `yem-erp-windows-debug` from Artifacts. Install the extracted APK on Android. For Windows, extract the complete artifact and run `yem_erp.exe` with its accompanying DLLs and data folder. Windows debug builds may require the matching debug runtime from the Windows development toolchain.

## Record results separately for each device

| Check | Steps | Expected result | Actual result |
|---|---|---|---|
| First launch | Launch without previous installation data | Institution setup appears with Arabic RTL layout | NOT VERIFIED |
| Validation | Empty fields, short password, mismatched confirmation | Setup rejected without partial institution data | NOT VERIFIED |
| Setup | Create test institution, branch, administrator; use password with 12+ characters | Login screen appears; setup cannot be repeated | NOT VERIFIED |
| Login | Try wrong password, then correct credentials | Generic denial, then catalog opens | NOT VERIFIED |
| Lockout | Five wrong attempts; try correct credentials before and after 15 minutes | Login blocked before expiry and allowed after expiry | NOT VERIFIED |
| Create | Add Camera / C1 / default unit | Item appears; blank fields and duplicate SKU are rejected | NOT VERIFIED |
| Restart | Fully close application; reopen and login | Requires login again; company and item remain | NOT VERIFIED |
| Archive | Cancel archive, then confirm it | Cancel preserves item; confirm removes it from active list | NOT VERIFIED |
| Master data | From catalog open البيانات الأساسية; create/edit a branch, customer, supplier, category, unit and warehouse | Records persist after restart; warehouse is tied to chosen institution branch | NOT VERIFIED |
| Branch references | Rename an existing branch referenced by a user and warehouse | References stay intact; warehouse branch selector displays the renamed branch | NOT VERIFIED |
| Product category | Add category and unit in master data, return to products and create an item with both | Item retains category/unit identities after renaming either record | NOT VERIFIED |
| Logout | Logout and attempt to use catalog | Login required | NOT VERIFIED |
| Session expiry | Remain logged in for 30 minutes, then perform an operation | Operation denied and login offered | NOT VERIFIED |
| Secure-storage failure | In an isolated test installation, remove stored database credential while retaining its encrypted file | Startup fails closed; retry offered; no replacement database or setup | NOT VERIFIED |
| Layout | Narrow Android portrait, keyboard open; resize Windows | Forms scroll and actions remain accessible | NOT VERIFIED |

Record OS version, device model, artifact commit, time, result and any error. Do not call a device verified until all applicable checks pass. Save failures in ERROR_LOG.md and resume from NEXT_TASK.md.

## Automated evidence and limits

CI covers encryption/file reopening, missing/wrong keys, migration upgrade/rollback, tenant references, Argon2 verification, persistent account lockout, permissions/session expiration and a setup/login/create/archive widget workflow. Device credential storage, installation and native desktop runtime behavior still require the checks above.

Remaining Phase 0 work includes customer/warehouse and other master data workflows, expense/custody, basic invoice and PDF. Offline/online variants, release identity/signing, backups and later ERPNext/integration phases are not complete.
