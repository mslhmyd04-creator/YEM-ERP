"""Run only in the disposable site via bench execute; never on a user's site."""
import unittest
from uuid import uuid4
import frappe
from yem_erp_core.api import bind_entity, resolve_entity, capabilities


class InstalledAppTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        frappe.set_user("Administrator")
        cls.companies = []
        for label in ('A', 'B'):
            company = frappe.get_doc({
                "doctype": "Company", "company_name": "YEM CI " + label,
                "abbr": "YCI" + label, "default_currency": "YER",
                "country": "Yemen", "chart_of_accounts": "Standard",
            }).insert()
            cls.companies.append(company.name)
        cls.item = frappe.get_doc({"doctype": "Item", "item_code": "YEM-CI-SERVICE",
                                   "item_name": "CI service", "item_group": "Services",
                                   "stock_uom": "Nos", "is_stock_item": 0}).insert().name
        cls.other_item = frappe.get_doc({"doctype": "Item", "item_code": "YEM-CI-OTHER",
                                         "item_name": "Other", "item_group": "Services",
                                         "stock_uom": "Nos", "is_stock_item": 0}).insert().name
        frappe.db.commit()

    def setUp(self):
        frappe.set_user("Administrator")
        frappe.db.savepoint("test_case")
        self.uid = str(uuid4())

    def tearDown(self):
        frappe.set_user("Administrator")
        frappe.db.rollback(save_point="test_case")

    def test_installed_schema_and_capabilities(self):
        self.assertIn("yem_erp_core", frappe.get_installed_apps())
        result = capabilities(self.companies[0])
        self.assertFalse(result['sync_ready'])
        self.assertEqual(result['api_version'], 1)

    def test_guest_denied(self):
        frappe.set_user("Guest")
        with self.assertRaises(frappe.PermissionError):
            capabilities(self.companies[0])

    def test_repeat_resolve_and_audit(self):
        args = (self.companies[0], "item", self.uid, self.item)
        first = bind_entity(*args)
        self.assertEqual(first, bind_entity(*args))
        self.assertEqual(first, resolve_entity(*args[:3]))
        self.assertEqual(frappe.db.count("YEM Entity Mapping"), 1)
        self.assertEqual(frappe.db.count("Comment", {
            "reference_doctype": "YEM Entity Mapping", "reference_name": first['mapping_id']
        }), 1)

    def test_changed_request_rejected(self):
        bind_entity(self.companies[0], "item", self.uid, self.item)
        with self.assertRaises(frappe.ValidationError):
            bind_entity(self.companies[0], "item", self.uid, self.other_item)

    def test_company_namespaces(self):
        first = bind_entity(self.companies[0], "item", self.uid, self.item)
        second = bind_entity(self.companies[1], "item", self.uid, self.item)
        self.assertNotEqual(first['mapping_id'], second['mapping_id'])

    def test_cross_company_account_rejected(self):
        account = frappe.db.get_value("Account", {"company": self.companies[1]}, "name")
        self.assertIsNotNone(account)
        with self.assertRaises(frappe.PermissionError):
            bind_entity(self.companies[0], "account", self.uid, account)
        self.assertEqual(frappe.db.count("YEM Entity Mapping"), 0)

    def test_immutable_and_reverse_unique(self):
        first = bind_entity(self.companies[0], "item", self.uid, self.item)
        doc = frappe.get_doc("YEM Entity Mapping", first['mapping_id'])
        with self.assertRaises((frappe.PermissionError, frappe.ValidationError)):
            doc.save()
        with self.assertRaises((frappe.PermissionError, frappe.ValidationError)):
            frappe.delete_doc("YEM Entity Mapping", doc.name)
        with self.assertRaises((frappe.UniqueValidationError, frappe.DuplicateEntryError)):
            bind_entity(self.companies[0], "item", str(uuid4()), self.item)

    def test_transaction_rollback_removes_mapping_and_audit(self):
        frappe.db.savepoint("binding")
        result = bind_entity(self.companies[0], "item", self.uid, self.item)
        frappe.db.rollback(save_point="binding")
        self.assertFalse(frappe.db.exists("YEM Entity Mapping", result['mapping_id']))
        self.assertFalse(frappe.db.exists("Comment", {
            "reference_doctype": "YEM Entity Mapping", "reference_name": result['mapping_id']
        }))

    def test_manager_requires_explicit_company_grant(self):
        user = frappe.get_doc({"doctype": "User", "email": "ci-manager@example.invalid",
                               "first_name": "CI", "send_welcome_email": 0,
                               "roles": [{"role": "System Manager"}]}).insert()
        frappe.set_user(user.name)
        with self.assertRaises(frappe.PermissionError):
            capabilities(self.companies[0])
        frappe.set_user("Administrator")
        frappe.get_doc({"doctype": "User Permission", "user": user.name,
                        "allow": "Company", "for_value": self.companies[0],
                        "apply_to_all_doctypes": 1}).insert()
        frappe.set_user(user.name)
        self.assertEqual(capabilities(self.companies[0])['company'], self.companies[0])
        with self.assertRaises(frappe.PermissionError):
            capabilities(self.companies[1])


def run():
    if frappe.local.site != "yem-ci.localhost":
        raise RuntimeError("Integration fixtures require the disposable yem-ci.localhost site")
    result = unittest.TextTestRunner(verbosity=2).run(
        unittest.defaultTestLoader.loadTestsFromTestCase(InstalledAppTests))
    if not result.wasSuccessful():
        raise RuntimeError("YEM ERP installed integration tests failed")
    return {"tests": result.testsRun, "result": "PASS"}
