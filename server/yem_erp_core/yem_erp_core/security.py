import frappe


def require_company(company, *, manage=False):
    if frappe.session.user == "Guest":
        frappe.throw("Authentication required", frappe.PermissionError)
    if manage and "System Manager" not in frappe.get_roles():
        frappe.throw("System Manager required", frappe.PermissionError)
    document = frappe.get_doc("Company", company)
    document.check_permission("read")
    # Explicit grants are mandatory for API tenants, even where ERPNext permits
    # all companies when User Permission has no entries.
    if frappe.session.user != "Administrator" and not frappe.db.exists(
        "User Permission", {"user": frappe.session.user,
                            "allow": "Company", "for_value": company}
    ):
        frappe.throw("Company access not granted", frappe.PermissionError)
    return document
