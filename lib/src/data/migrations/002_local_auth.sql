ALTER TABLE users ADD COLUMN failed_login_count INTEGER NOT NULL DEFAULT 0 CHECK (failed_login_count >= 0);
ALTER TABLE users ADD COLUMN locked_until_ms INTEGER NOT NULL DEFAULT 0 CHECK (locked_until_ms >= 0);

CREATE TABLE audit_logs (
  id TEXT PRIMARY KEY CHECK(length(id) > 0),
  company_id TEXT NOT NULL REFERENCES companies(id) ON DELETE RESTRICT,
  user_id TEXT,
  action TEXT NOT NULL CHECK(length(action) > 0),
  entity_type TEXT NOT NULL,
  entity_id TEXT,
  created_at TEXT NOT NULL,
  FOREIGN KEY(user_id, company_id) REFERENCES users(id, company_id) ON DELETE RESTRICT
);
CREATE INDEX audit_logs_company_time ON audit_logs(company_id, created_at);
INSERT INTO schema_migrations(version, applied_at)
VALUES(2, strftime('%Y-%m-%dT%H:%M:%fZ', 'now'));
