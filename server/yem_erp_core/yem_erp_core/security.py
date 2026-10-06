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


def mapping_has_permission(doc, user=None, ptype=None, debug=False):
    user = user or frappe.session.user
    if user == "Administrator":
        return True
    if user == "Guest" or not frappe.db.exists(
        "User Permission", {"user": user, "allow": "Company", "for_value": doc.company}
    ):
        return False
    # Frappe v16 combines this veto with ordinary role/document permissions.
    return True


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


def protect_bound_identity(doc, method=None, old=None, new=None, merge=False):
    from yem_erp_core.identity import ENTITY_TYPES
    if doc.doctype == "YEM Entity Mapping":
        frappe.throw("Mapping identity cannot be renamed")
    if doc.doctype == "Company" and frappe.db.table_exists("YEM Entity Mapping"):
        if frappe.db.exists("YEM Entity Mapping", {"company": doc.name}):
            frappe.throw("Mapped company identity cannot be renamed or merged")
    if doc.doctype not in ENTITY_TYPES.values():
        return
    if frappe.db.table_exists("YEM Entity Mapping") and frappe.db.exists(
        "YEM Entity Mapping", {"target_doctype": doc.doctype, "target_name": doc.name}
    ):
        frappe.throw("Mapped document identity cannot be renamed or merged")
