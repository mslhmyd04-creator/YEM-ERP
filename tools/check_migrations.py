"""Check migration invariants in transient SQLite memory (never a user database).

This validates SQL syntax and relational constraints; it does not certify
SQLCipher, application integration, or a Flutter build.
"""

from pathlib import Path
import sqlite3
import unittest


SQL = (Path(__file__).resolve().parents[1] / "lib/src/data/migrations/001_core.sql").read_text()
NOW = "2026-09-28T00:00:00Z"


class CoreMigrationTest(unittest.TestCase):
    def setUp(self):
        self.db = sqlite3.connect(":memory:")
        self.db.execute("PRAGMA foreign_keys = ON")
        self.db.executescript("BEGIN IMMEDIATE;\n" + SQL + "\nCOMMIT;")
        for company in ("a", "b"):
            self.db.execute(
                "INSERT INTO companies(id,name,created_at) VALUES(?,?,?)",
                (company, company, NOW),
            )
            self.db.execute(
                "INSERT INTO branches(id,company_id,name,created_at) VALUES(?,?,?,?)",
                ("branch-" + company, company, "main", NOW),
            )
            self.db.execute(
                "INSERT INTO units(id,company_id,name) VALUES(?,?,?)",
                ("unit-" + company, company, "piece"),
            )

    def tearDown(self):
        self.db.close()

    def test_migration_and_integrity(self):
        self.assertEqual(self.db.execute("SELECT version FROM schema_migrations").fetchone(), (1,))
        self.assertEqual(self.db.execute("PRAGMA integrity_check").fetchone(), ("ok",))
        self.assertEqual(self.db.execute("PRAGMA foreign_key_check").fetchall(), [])

    def test_product_sku_unique_within_company(self):
        self.db.execute(
            "INSERT INTO products(id,company_id,sku,name,unit_id,created_at,updated_at) "
            "VALUES(?,?,?,?,?,?,?)",
            ("p1", "a", "C-1", "Camera", "unit-a", NOW, NOW),
        )
        with self.assertRaises(sqlite3.IntegrityError):
            self.db.execute(
                "INSERT INTO products(id,company_id,sku,name,unit_id,created_at,updated_at) "
                "VALUES(?,?,?,?,?,?,?)",
                ("p2", "a", "C-1", "Other", "unit-a", NOW, NOW),
            )
        self.db.execute(
            "INSERT INTO products(id,company_id,sku,name,unit_id,created_at,updated_at) "
            "VALUES(?,?,?,?,?,?,?)",
            ("p3", "b", "C-1", "Camera", "unit-b", NOW, NOW),
        )

    def test_cross_company_references_rejected(self):
        with self.assertRaises(sqlite3.IntegrityError):
            self.db.execute(
                "INSERT INTO products(id,company_id,sku,name,unit_id,created_at,updated_at) "
                "VALUES(?,?,?,?,?,?,?)",
                ("p1", "a", "C-1", "Camera", "unit-b", NOW, NOW),
            )
        with self.assertRaises(sqlite3.IntegrityError):
            self.db.execute(
                "INSERT INTO warehouses(id,company_id,branch_id,name) VALUES(?,?,?,?)",
                ("w1", "a", "branch-b", "Warehouse"),
            )

    def test_password_hash_required_and_branch_company_scoped(self):
        with self.assertRaises(sqlite3.IntegrityError):
            self.db.execute(
                "INSERT INTO users(id,company_id,branch_id,username,password_hash,created_at) "
                "VALUES(?,?,?,?,?,?)",
                ("u1", "a", "branch-a", "admin", "", NOW),
            )
        with self.assertRaises(sqlite3.IntegrityError):
            self.db.execute(
                "INSERT INTO users(id,company_id,branch_id,username,password_hash,created_at) "
                "VALUES(?,?,?,?,?,?)",
                ("u2", "a", "branch-b", "admin", "hash-placeholder", NOW),
            )


class AuthMigrationTest(CoreMigrationTest):
    def setUp(self):
        super().setUp()
        self.db.execute(
            "INSERT INTO users(id,company_id,branch_id,username,password_hash,created_at) VALUES(?,?,?,?,?,?)",
            ("u1", "a", "branch-a", "admin", "existing-hash", NOW),
        )
        self.db.commit()
        sql = (Path(__file__).resolve().parents[1] / "lib/src/data/migrations/002_local_auth.sql").read_text()
        self.db.executescript("BEGIN IMMEDIATE;\n" + sql + "\nCOMMIT;")

    def test_migration_and_integrity(self):
        self.assertEqual(self.db.execute("SELECT version FROM schema_migrations ORDER BY version").fetchall(), [(1,), (2,)])
        self.assertEqual(self.db.execute("SELECT password_hash,failed_login_count,locked_until_ms FROM users WHERE id='u1'").fetchone(), ("existing-hash", 0, 0))
        self.assertEqual(self.db.execute("PRAGMA integrity_check").fetchone(), ("ok",))
        self.assertEqual(self.db.execute("PRAGMA foreign_key_check").fetchall(), [])

    def test_audit_and_lockout_constraints(self):
        with self.assertRaises(sqlite3.IntegrityError):
            self.db.execute("UPDATE users SET failed_login_count=-1 WHERE id='u1'")
        with self.assertRaises(sqlite3.IntegrityError):
            self.db.execute("INSERT INTO audit_logs(id,company_id,user_id,action,entity_type,created_at) VALUES('log','b','u1','login','users',?)", (NOW,))


if __name__ == "__main__":
    unittest.main()
