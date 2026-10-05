-- Grant new capabilities only to the original bootstrap administrator role.
INSERT OR IGNORE INTO permissions(code,description) VALUES
('product_categories.view','product_categories.view'),
('product_categories.create','product_categories.create'),
('product_categories.update','product_categories.update'),
('units.view','units.view'),
('units.create','units.create'),
('units.update','units.update'),
('customers.view','customers.view'),
('customers.create','customers.create'),
('customers.update','customers.update'),
('suppliers.view','suppliers.view'),
('suppliers.create','suppliers.create'),
('suppliers.update','suppliers.update'),
('warehouses.view','warehouses.view'),
('warehouses.create','warehouses.create'),
('warehouses.update','warehouses.update');
INSERT OR IGNORE INTO role_permissions(role_id,permission_code)
SELECT DISTINCT r.id,p.code FROM roles r
JOIN user_roles ur ON ur.role_id=r.id AND ur.company_id=r.company_id
JOIN audit_logs a ON a.user_id=ur.user_id AND a.company_id=r.company_id
CROSS JOIN permissions p
WHERE r.name='مدير' AND a.action='company.bootstrap'
AND p.code IN ('product_categories.view','product_categories.create','product_categories.update','units.view','units.create','units.update','customers.view','customers.create','customers.update','suppliers.view','suppliers.create','suppliers.update','warehouses.view','warehouses.create','warehouses.update' );
INSERT INTO schema_migrations(version,applied_at) VALUES(3,strftime('%Y-%m-%dT%H:%M:%fZ','now'));
