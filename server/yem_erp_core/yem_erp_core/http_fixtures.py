"""Temporary credentials stay inside the disposable integration container."""
import json
import os
import secrets
import frappe
from yem_erp_core.api import bind_entity


def setup():
    if frappe.local.site != "yem-ci.localhost":
        raise RuntimeError("Disposable site required")
    frappe.set_user("Administrator")
    api_key, api_secret = secrets.token_hex(16), secrets.token_hex(24)
    user = frappe.get_doc({"doctype": "User", "email": "ci-http@example.invalid",
                           "first_name": "HTTP", "send_welcome_email": 0,
                           "api_key": api_key, "api_secret": api_secret,
                           "roles": [{"role": "System Manager"}, {"role": "Stock User"}]}).insert()
    frappe.get_doc({"doctype": "User Permission", "user": user.name,
                    "allow": "Company", "for_value": "YEM CI A",
                    "apply_to_all_doctypes": 1}).insert()
    bind_entity('YEM CI B', 'item', '6d5d6651-b0db-43a9-bdb6-6da68ca719d0', 'YEM-CI-SERVICE')
    frappe.db.commit()
    fd = os.open('/tmp/yem-ci-http.json', os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
    with os.fdopen(fd, 'w') as handle:
        json.dump({"token": f"token {api_key}:{api_secret}"}, handle)
    return "HTTP fixtures ready"
