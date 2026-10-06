# Resume here

- CURRENT PHASE: 1 isolated server CI; Phase 0 software gate PASS.
- VERIFIED CLIENT: 37352094707; 68 Flutter tests per runner, 17 SQL checks, Android/Windows debug builds. No client code changed in this increment.
- NEW: server/yem_erp_core with company-scoped immutable UUID bindings for nine ERP document types, explicit Company User Permission, target read permission, transactional Comment audit and duplicate constraints.
- TEST TARGET: ephemeral GitHub Actions Docker site yem-ci.localhost; official ERPNext v16.50.0, MariaDB 11.8, Redis 6.2. No external ports, production data or permanent server assumed.
- LOCAL: four pure identity tests, Python compilation and shell syntax PASS. Native installed tests PENDING in Phase 1 workflow.
- NEXT: inspect workflow for the latest branch commit, fix failures, verify installed tests. Then implement HTTP auth/concurrent duplicate checks and remaining Phase 1 integration contract. Phase 2 remains gated.
- PRODUCTION: persistent host/LAN/online endpoint still unspecified; no deployed production server or signed final client releases. Physical-device tests NOT VERIFIED.
