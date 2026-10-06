# Phase 1 deployment targets

## Development target selected

GitHub Actions runs a disposable Docker site `yem-ci.localhost` using the official
ERPNext v16.50.0 image, MariaDB 11.8 and Redis 6.2. This permits installation,
migration and real integration tests without requesting a permanent host first.
No public port or user data is used. The job generates random temporary secrets
and removes its own containers/volumes at completion. See server/README.md.

## Persistent deployment still needs inputs

- Existing ERPNext URL/version, or an empty host and OS.
- Authorized execution route and private secret provisioning.
- LAN or online endpoint; HTTPS is required for online deployment.

Do not assume the CI version can upgrade an existing site. No existing server is
modified. A successful disposable run does not prove permanent deployment,
Android/Windows runtime behavior, signing or physical printing.

Complete the Phase 1 APIs/integration gate before starting Phase 2. Final
production release still requires a persistent target and device acceptance.
