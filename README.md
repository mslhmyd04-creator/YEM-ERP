# YEM ERP

Phase 0 foundation for the Arabic Android/Windows client. The complete specifications are in `docs/`. This is an initial source tree, not an ERP release.

## Local setup

Install a compatible Flutter SDK with Android and Windows desktop tooling. From this directory run:

```bash
flutter create --platforms=android,windows --project-name yem_erp .
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
```

Review the generated Android manifest before distributing any strict offline build. The offline variant and encrypted persistent database have **not** been implemented. Do not store business data in this foundation build. Windows builds require Flutter's Windows toolchain on Windows.

## Migration SQL check

`python3 -m unittest discover -s tools -p 'check_*.py' -v` runs migration 001 in a fresh in-memory SQLite database and checks tenant isolation and constraints. It does not run a Flutter build or certify encrypted storage.
