import frappe
from frappe.model.document import Document
from yem_erp_core.identity import ENTITY_TYPES, canonical_uuid, mapping_key
from yem_erp_core.security import require_company


class YEMEntityMapping(Document):
    def autoname(self):
        self.local_uuid = canonical_uuid(self.local_uuid)
        self.name = mapping_key(self.company, self.entity_type, self.local_uuid)

    def validate(self):
        require_company(self.company, manage=True)
        if not self.is_new():
            frappe.throw("Mappings are immutable")
        self.local_uuid = canonical_uuid(self.local_uuid)
        if ENTITY_TYPES.get(self.entity_type) != self.target_doctype:
            frappe.throw("Invalid target type")
        target = frappe.get_doc(self.target_doctype, self.target_name)
        target.check_permission("read")
        if target.meta.has_field("company") and target.company != self.company:
            frappe.throw("Cross-company target", frappe.PermissionError)
        self.reverse_key = mapping_key(self.company, self.entity_type, self.target_name)

    def after_insert(self):
        # Comment is an audit event in the same database transaction.
        self.add_comment("Info", "YEM entity binding created")

    def on_trash(self):
        frappe.throw("Mappings cannot be deleted")
