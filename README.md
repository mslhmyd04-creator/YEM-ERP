# YEM ERP

Arabic Android/Windows local ERP prototype. Specifications: [master plan](docs/YEM_ERP_Master_Plan_2026.md). Phase 0 software gate PASS; server, sync and production phases remain pending.

The local app includes SQLCipher encryption, Argon2id login/lockout, company-scoped permissions, audited master data and protected user/role administration, exact balanced immutable journals, cash/custody expenses, whole-unit stock opening, cash/credit/service sales and bundled-font Arabic invoice PDF. Invoice/GL/stock/numbering/audit commit or roll back together.

## Build and checks

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
python3 -m unittest discover -s tools -p 'check_*.py' -v
```

On Windows with the Flutter desktop toolchain also run `flutter build windows --debug`. Missing/wrong SQLCipher credentials fail closed. Python SQL checks do not certify encrypted native storage.

## Verified development packages

[Run 37352094707](https://github.com/mslhmyd04-creator/YEM-ERP/actions/runs/37352094707), code `5d8c545edab01de34072550d0eee1e1ec630f90e`: analysis, 68 Flutter tests on each runner, 17 SQL checks, both builds and uploads PASS. See [gate](docs/PHASE0_GATE.md).

- [Android debug](https://github.com/mslhmyd04-creator/YEM-ERP/actions/runs/37352094707/artifacts/11362299404)
- [Windows debug bundle](https://github.com/mslhmyd04-creator/YEM-ERP/actions/runs/37352094707/artifacts/11363252267)
- [Synthetic Arabic PDF fixture](https://github.com/mslhmyd04-creator/YEM-ERP/actions/runs/37352094707/artifacts/11362513485)

Artifacts expire October 19, 2026. Follow [device acceptance](docs/PHASE0_DEVICE_TESTS.md) with isolated test data. User-device installation, native credential storage and physical printing remain NOT VERIFIED.

Current limits: YER/two decimals, whole quantities, positive opening cost, immediate posting and no tax separation. Full approvals/settlement, serial/batch/returns, synchronization, backups, signed releases and separate strict offline/LAN/online variants remain pending. This development package is not a production or certified strict-offline release. See [financial scope](docs/PHASE0_FINANCIAL_SCOPE.md), [sales scope](docs/PHASE0_SALES_SCOPE.md) and [PDF QA](docs/PHASE0_PDF_QA.md).

Phase 1 requires an identified ERPNext/Frappe target and authorized execution route: [required inputs](docs/PHASE1_REQUIRED_INPUTS.md).
