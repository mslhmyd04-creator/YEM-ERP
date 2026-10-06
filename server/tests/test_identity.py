import sys
import unittest
from pathlib import Path
from uuid import uuid4
sys.path.insert(0, str(Path(__file__).parents[1] / 'yem_erp_core'))
from yem_erp_core.identity import canonical_uuid, mapping_key


class IdentityTests(unittest.TestCase):
    def test_uuid_normalization(self):
        value = str(uuid4())
        self.assertEqual(canonical_uuid(value.upper()), value)

    def test_invalid_identities(self):
        for value in ('', 'SI-0001', '00000000-0000-0000-0000-000000000000', None):
            with self.subTest(value=value), self.assertRaises(ValueError):
                canonical_uuid(value)

    def test_scope_and_delimiters(self):
        uid = str(uuid4())
        self.assertNotEqual(mapping_key('A', 'item', uid), mapping_key('B', 'item', uid))
        self.assertNotEqual(mapping_key('A', 'item', uid), mapping_key('A', 'customer', uid))
        self.assertNotEqual(mapping_key('A|item', 'item', 'B'), mapping_key('A', 'item', 'item|B'))

    def test_unknown_kind(self):
        with self.assertRaises(ValueError):
            mapping_key('A', 'User', 'admin')
