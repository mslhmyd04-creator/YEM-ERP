# Project state

- Project Version: 0.0.1 source foundation
- Current Phase: 0 — foundation
- Current Task: Verify Windows encrypted-storage tests and debug build
- Completed Tasks: specifications, source layout, platform runners, migration 001, SQLCipher tests, product repository tests and Android debug build passed in run 36464645152
- Pending Tasks: Windows CI and device tests; Android device tests; authentication, other data modules, invoices, PDF
- Current Branch: feat/phase-0-foundation (GitHub proposal)
- Last Commit: see `git log -1 --oneline`
- Build Status: Android debug PASS in GitHub Actions run 36464645152; Windows debug PASS in run 36465256956
- Test Status: SQLite migration checks and Flutter encrypted/product tests PASS in run 36464645152
- Database Migration Status: Migration 001 PASS under SQLCipher in CI; device migration and rollback NOT VERIFIED
- Known Errors: Local Flutter/Dart executables absent; first GitHub analysis error resolved by project widget test
- Important Decisions: see DECISIONS.md
- Files Modified: see latest git commit
- Next Task: inspect Windows CI; fix failures before adding authentication and RBAC
- Exact Next Command: `flutter pub get && flutter analyze && flutter test && flutter build apk --debug`

## Authentication increment (2026-09-30)

- Windows SQLCipher tests and Android/Windows debug builds PASS in run 36465256956.
- Added migration 002, Argon2id hashing, local setup/login/lockout/session, permissions and atomic product audit.
- Added authentication, upgrade/rollback and password hashing tests; Flutter verification PENDING GitHub CI.
- Phase 0 remains in progress; authenticated UI and device checks remain required.
