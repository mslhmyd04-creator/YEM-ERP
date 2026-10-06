import frappe
from yem_erp_core import __version__
from yem_erp_core.identity import ENTITY_TYPES, canonical_uuid, mapping_key
from yem_erp_core.security import require_company


@frappe.whitelist(methods=["GET"])
def capabilities(company):
    require_company(company)
    return {"api_version": 1, "app_version": __version__, "company": company,
            "entity_types": list(ENTITY_TYPES), "sync_ready": False}


@frappe.whitelist(methods=["POST"])
def bind_entity(company, entity_type, local_uuid, target_name):
    require_company(company, manage=True)
    try:
        local_uuid = canonical_uuid(local_uuid)
        key = mapping_key(company, entity_type, local_uuid)
    except (ValueError, TypeError, AttributeError):
        frappe.throw("Invalid entity identity")
    target = frappe.get_doc(ENTITY_TYPES[entity_type], target_name)
    target.check_permission("read")
    if target.meta.has_field("company") and target.company != company:
        frappe.throw("Target belongs to another company", frappe.PermissionError)
    existing = frappe.db.get_value("YEM Entity Mapping", key,
                                  ["target_name", "local_uuid"], as_dict=True)
    if existing:
        if existing.target_name != target_name:
            frappe.throw("UUID is already bound to a different target")
        return {"mapping_id": key, "local_uuid": existing.local_uuid,
                "target_name": existing.target_name}
    # Unique primary and reverse keys arbitrate concurrent requests. No commit:
    # Frappe's successful POST transaction owns the mapping and its audit record.
    frappe.get_doc({"doctype": "YEM Entity Mapping", "company": company,
                   "entity_type": entity_type, "local_uuid": local_uuid,
                   "target_doctype": ENTITY_TYPES[entity_type],
                   "target_name": target_name}).insert()
    return {"mapping_id": key, "local_uuid": local_uuid, "target_name": target_name}


@frappe.whitelist(methods=["GET"])
def resolve_entity(company, entity_type, local_uuid):
    require_company(company)
    try:
        key = mapping_key(company, entity_type, canonical_uuid(local_uuid))
    except (ValueError, TypeError, AttributeError):
        frappe.throw("Invalid entity identity")
    row = frappe.get_doc("YEM Entity Mapping", key)
    target = frappe.get_doc(row.target_doctype, row.target_name)
    target.check_permission("read")
    if target.meta.has_field("company") and target.company != company:
        frappe.throw("Target company changed", frappe.PermissionError)
    return {"mapping_id": row.name, "local_uuid": row.local_uuid,
            "target_name": row.target_name}
