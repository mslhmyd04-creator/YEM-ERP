#!/usr/bin/env bash
set -euo pipefail
ls -1 apps > sites/apps.txt
bench set-config -g db_host db
bench set-config -gp db_port 3306
bench set-config -g redis_cache redis://redis:6379/0
bench set-config -g redis_queue redis://redis:6379/1
bench set-config -g redis_socketio redis://redis:6379/2
bench new-site yem-ci.localhost --mariadb-user-host-login-scope='%' \
  --db-root-username root --db-root-password "$YEM_CI_DB_PASSWORD" \
  --admin-password "$YEM_CI_ADMIN_PASSWORD" --install-app erpnext
bench --site yem-ci.localhost install-app yem_erp_core
bench --site yem-ci.localhost migrate
bench --site yem-ci.localhost list-apps
bench --site yem-ci.localhost execute yem_erp_core.integration_tests.run
bench --site yem-ci.localhost execute yem_erp_core.http_fixtures.setup
env/bin/gunicorn --chdir sites --bind 127.0.0.1:8000 --workers 2 --threads 2 \
  frappe.app:application > /tmp/yem-http-server.log 2>&1 &
http_pid=$!
trap 'kill "$http_pid" 2>/dev/null || true; rm -f /tmp/yem-ci-http.json' EXIT
env/bin/python -m yem_erp_core.http_tests
