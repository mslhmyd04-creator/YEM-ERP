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
