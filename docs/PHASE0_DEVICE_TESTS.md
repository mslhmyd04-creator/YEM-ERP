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
| Administration | Create a role with customers.view only; create a user assigned to that role; log in as that user | Master data is accessible; customer creation and administration are denied | NOT VERIFIED |
| Last administrator | Attempt to disable the sole administrator or remove administration.manage from the sole manager role | Operation denied; administrator remains active and can manage users | NOT VERIFIED |
| Password reset | Create a second administrator, reset a test user password, attempt old/new login | Old password rejected; new password accepted; old session invalidated | NOT VERIFIED |
| Financial setup | Open المصروفات والعهد; configure defaults and post cash opening 1000 YER | Cash ledger balance is 1000.00; configuration can be repeated without duplicates | NOT VERIFIED |
| Basic custody | Issue 300 YER to a test employee, spend 50 YER from that custody | Cash remains 700.00; custody remainder is 250.00; documents remain after restart | NOT VERIFIED |
| Insufficient funds | Attempt to spend more than remaining cash/custody | Denied with no extra document or ledger movement | NOT VERIFIED |
| Stock opening | Configure sales accounts and open 10 units at 5 YER | Quantity 10; stock value 50.00 YER | NOT VERIFIED |
| Goods invoice | Sell 3 units at 8 YER for cash | Invoice 24.00; cost 15.00; quantity 7; stock value 35.00; cash increases 24.00 | NOT VERIFIED |
| Insufficient stock | Try to sell 8 further units | Denied without extra invoice/journal/movement | NOT VERIFIED |
| Service/credit invoice | Sell a non-stock service on credit | Receivable/revenue increase; no stock or COGS movement | NOT VERIFIED |
| Arabic PDF | Print/save a posted invoice; repeat with long item/SKU and 50 lines | Joined Arabic, intact exact amounts, repeated headers, complete summary | NOT VERIFIED |
| Logout | Logout and attempt to use catalog | Login required | NOT VERIFIED |
| Session expiry | Remain logged in for 30 minutes, then perform an operation | Operation denied and login offered | NOT VERIFIED |
| Secure-storage failure | In an isolated test installation, remove stored database credential while retaining its encrypted file | Startup fails closed; retry offered; no replacement database or setup | NOT VERIFIED |
| Layout | Narrow Android portrait, keyboard open; resize Windows | Forms scroll and actions remain accessible | NOT VERIFIED |

Record OS version, device model, artifact commit, time, result and any error. Do not call a device verified until all applicable checks pass. Save failures in ERROR_LOG.md and resume from NEXT_TASK.md.

## Automated evidence and limits

Run 37352094707 verifies 68 Flutter tests and 17 SQL checks plus analysis and both builds. CI covers exact financial amounts, balanced/immutable posting, retry/conflicts and ledger rollback, alongside encryption/file reopening, missing/wrong keys, migration upgrade/rollback, tenant references, Argon2 verification, persistent account lockout, permissions/session expiration and a setup/login/create/archive widget workflow. Device credential storage, installation and native desktop runtime behavior still require the checks above.

Master-data and branch flows have automated coverage. User/role administration is verified by automated security/widget tests in run 37340719874. Basic cash/custody expenses and custody issue have automated coverage. Basic stock-backed invoices and Arabic PDF also pass automated/visual checks; physical-device acceptance remains pending. Offline/online variants, release identity/signing, backups and later ERPNext/integration phases are not complete.
