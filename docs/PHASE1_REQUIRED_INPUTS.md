# Phase 1 target intake

Phase 0 software gate PASS (PHASE0_GATE.md). Actual ERPNext/Frappe deployment and integration cannot be verified through repository access alone.

| Required input | Purpose |
| --- | --- |
| Existing ERPNext URL/version or a new empty test host | Choose compatible branches without altering an unknown site |
| Test hostname/IP and OS | Identify isolated deployment environment |
| Authorized execution route (SSH/deployment platform) | Install/run server and integration tests |
| Intended LAN-only or online endpoint | Configure endpoint and HTTPS where applicable |

Supply identifiers/access method and provision secrets through an approved execution environment, never source control. No server target or callable server execution environment is currently supplied.

Next workflow: inspect/isolate target; install/verify compatible Frappe and ERPNext; create yem_erp_core without core edits; explicit UUID mappings for accounts/counterparties/items/warehouses/documents; authenticated company-scoped/idempotent/audited APIs; integration/permission/duplicate/rollback tests. Pass Phase 1 gate before synchronization.

Physical Android/Windows installation, native credentials and print tests remain separate acceptance evidence. Do not mark deployment complete or skip later gates by assuming a server exists.
