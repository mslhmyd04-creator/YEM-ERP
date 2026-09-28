# YEM ERP

Phase 0 foundation for the Arabic Android/Windows client. The complete specifications are in `docs/`. This is an initial source tree, not an ERP release.

## Local setup

Install a compatible Flutter SDK with Android and Windows desktop tooling. Platform runner files are included. From this directory run:

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
```

Review the merged Android manifest before distributing any strict offline build. The offline variant and production data workflows have **not** been implemented. Do not store business data in this foundation build. Windows builds require Flutter's Windows toolchain on Windows.

The SQLCipher-backed local database is isolated in `lib/src/infrastructure/local_database.dart`. Its key is generated per installation and stored through platform secure storage. The integration tests require the SQLCipher native build and will fail rather than fall back to plaintext SQLite. The app shell does not open this database until the first business workflow is implemented.

## Migration SQL check

`python3 -m unittest discover -s tools -p 'check_*.py' -v` runs migration 001 in a fresh in-memory SQLite database and checks tenant isolation and constraints. It does not run a Flutter build or certify encrypted storage.
