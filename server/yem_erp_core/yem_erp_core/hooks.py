app_name = "yem_erp_core"
app_title = "YEM ERP Core"
app_publisher = "YEM ERP"
app_description = "Company-scoped integration API"
app_email = "development@example.invalid"
app_license = "MIT"
required_apps = ["erpnext"]
permission_query_conditions = {
    "YEM Entity Mapping": "yem_erp_core.security.mapping_query_conditions"
}
has_permission = {
    "YEM Entity Mapping": "yem_erp_core.security.mapping_has_permission"
}
doc_events = {"*": {"before_rename": "yem_erp_core.security.protect_bound_identity"}}
