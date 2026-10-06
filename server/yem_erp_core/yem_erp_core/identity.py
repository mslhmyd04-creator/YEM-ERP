"""Pure identity contract; UUIDs are never ERPNext display numbers."""
import hashlib
import json
from uuid import UUID

ENTITY_TYPES = {
    "account": "Account", "customer": "Customer", "supplier": "Supplier",
    "item": "Item", "warehouse": "Warehouse", "sale": "Sales Invoice",
    "purchase": "Purchase Invoice", "payment": "Payment Entry",
    "stock": "Stock Entry",
}


def canonical_uuid(value):
    if not isinstance(value, str):
        raise ValueError("UUID must be text")
    parsed = UUID(value)
    if parsed.int == 0:
        raise ValueError("Nil UUID is not an entity identity")
    return str(parsed)


def mapping_key(company, entity_type, identity):
    if entity_type not in ENTITY_TYPES:
        raise ValueError("Unsupported entity type")
    if not isinstance(company, str) or not company.strip():
        raise ValueError("Company is required")
    payload = json.dumps([company, entity_type, identity], ensure_ascii=False,
                         separators=(",", ":"))
    return hashlib.sha256(payload.encode()).hexdigest()
