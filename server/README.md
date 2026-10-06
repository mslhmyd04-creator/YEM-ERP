# Phase 1 isolated integration environment

This is an ephemeral test server, not a production deployment. It uses the
official `frappe/erpnext:v16.50.0` image with MariaDB 11.8 and Redis 6.2. This
version is selected only for our new CI site; no compatibility with an existing
user site is assumed. Upstream reference: https://github.com/frappe/frappe_docker/blob/main/pwd.yml

The GitHub workflow creates random credentials, builds the custom app image,
installs ERPNext and `yem_erp_core`, migrates, and runs real database tests.
No external port is published. Cleanup removes this job's disposable containers
and volumes. Do not point the scripts at a real business database.

API methods live at `/api/method/yem_erp_core.api.<method>`:

| Method | HTTP | Contract |
| --- | --- | --- |
| capabilities | GET | Authenticated company capability handshake; sync_ready=false |
| bind_entity | POST | System Manager, explicit company grant, UUID/ERP document binding |
| resolve_entity | GET | Company grant and current target read permission |

Administrator is the bootstrap exception to explicit Company User Permission.
All other accounts need an explicit Company grant. Customer, Supplier and Item
are shared ERPNext masters: bindings namespace them by company but do not make
those ERPNext records private. Target read permission remains mandatory.

Mapping creation and its Comment audit event share Frappe's POST transaction.
Sequential retries return the same mapping; changed bindings fail. Database
uniqueness rejects racing duplicates; clients must retry after a conflict.
Bindings cannot be reassigned or deleted through this API. Accounting documents
are not created or posted by these endpoints.

Pending Phase 1 work: authenticated HTTP integration tests, concurrent retry
tests, document posting/mapping policy and an approved persistent deployment
target. Phase 2 sync must wait for the complete Phase 1 gate.
