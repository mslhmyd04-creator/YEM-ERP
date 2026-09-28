# Project state

- Project Version: 0.0.1 source foundation
- Current Phase: 0 — foundation
- Current Task: Verify SQLCipher-backed local database and migration 001 in CI
- Completed Tasks: specifications copied; source layout, app entry, product domain validation, migration 001 and four in-memory SQLite constraint checks
- Pending Tasks: CI/device verification of encrypted storage; Windows build; authentication, data modules, invoices, PDF
- Current Branch: feat/phase-0-foundation (GitHub proposal)
- Last Commit: see `git log -1 --oneline`
- Build Status: Previous Android debug scaffold PASS in run 36461872576; new SQLCipher changes NOT VERIFIED; Windows NOT VERIFIED
- Test Status: Four transient SQLite checks PASS; new encrypted Flutter tests NOT VERIFIED
- Database Migration Status: SQL migration 001 validated in transient SQLite; encrypted first-open integration added, NOT VERIFIED
- Known Errors: Local Flutter/Dart executables absent; first GitHub analysis error resolved by project widget test
- Important Decisions: see DECISIONS.md
- Files Modified: see latest git commit
- Next Task: inspect GitHub CI, fix encrypted migration failures, then build a real catalog repository/service
- Exact Next Command: `flutter pub get && flutter analyze && flutter test && flutter build apk --debug`
