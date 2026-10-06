ALTER TABLE users ADD COLUMN auth_revision INTEGER NOT NULL DEFAULT 0 CHECK(auth_revision >= 0);
INSERT OR IGNORE INTO permissions(code,description) VALUES('administration.manage','إدارة المستخدمين والأدوار');
INSERT OR IGNORE INTO role_permissions(role_id,permission_code)
SELECT DISTINCT r.id,'administration.manage' FROM roles r
JOIN user_roles ur ON ur.role_id=r.id AND ur.company_id=r.company_id
JOIN audit_logs a ON a.user_id=ur.user_id AND a.company_id=r.company_id
WHERE r.name='مدير' AND a.action='company.bootstrap';
INSERT INTO schema_migrations(version,applied_at) VALUES(5,strftime('%Y-%m-%dT%H:%M:%fZ','now'));
