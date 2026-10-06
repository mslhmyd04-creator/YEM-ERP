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


def mapping_has_permission(doc, user=None, permission_type=None):
    user = user or frappe.session.user
    if user == "Administrator":
        return None
    if user == "Guest" or not frappe.db.exists(
        "User Permission", {"user": user, "allow": "Company", "for_value": doc.company}
    ):
        return False
    # None preserves Frappe's ordinary role/document permission checks.
    return None


def mapping_query_conditions(user=None):
    user = user or frappe.session.user
    if user == "Administrator":
        return ""
    companies = frappe.get_all("User Permission", filters={"user": user, "allow": "Company"},
                               pluck="for_value")
    if user == "Guest" or not companies:
        return "1=0"
    names = ",".join(frappe.db.escape(company) for company in companies)
    return f"`tabYEM Entity Mapping`.`company` IN ({names})"
