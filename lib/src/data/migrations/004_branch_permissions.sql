INSERT OR IGNORE INTO permissions(code,description) VALUES
('branches.view','عرض الفروع'),('branches.create','إنشاء الفروع'),('branches.update','تعديل الفروع');
INSERT OR IGNORE INTO role_permissions(role_id,permission_code)
SELECT DISTINCT r.id,p.code FROM roles r
JOIN user_roles ur ON ur.role_id=r.id AND ur.company_id=r.company_id
JOIN audit_logs a ON a.user_id=ur.user_id AND a.company_id=r.company_id
CROSS JOIN permissions p
WHERE r.name='مدير' AND a.action='company.bootstrap'
AND p.code IN ('branches.view','branches.create','branches.update');
INSERT INTO schema_migrations(version,applied_at) VALUES(4,strftime('%Y-%m-%dT%H:%M:%fZ','now'));
