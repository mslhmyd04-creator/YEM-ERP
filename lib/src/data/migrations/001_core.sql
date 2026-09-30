-- Phase 0, migration 001. Run in an explicit transaction with foreign keys ON.
-- UUIDs are generated in the application layer. No stock quantity cache is stored.
CREATE TABLE schema_migrations (
  version INTEGER PRIMARY KEY,
  applied_at TEXT NOT NULL
);

CREATE TABLE companies (
  id TEXT PRIMARY KEY CHECK (length(id) > 0),
  name TEXT NOT NULL CHECK (length(trim(name)) > 0),
  currency_code TEXT NOT NULL DEFAULT 'YER',
  created_at TEXT NOT NULL
);

CREATE TABLE branches (
  id TEXT PRIMARY KEY CHECK (length(id) > 0),
  company_id TEXT NOT NULL REFERENCES companies(id) ON DELETE RESTRICT,
  name TEXT NOT NULL CHECK (length(trim(name)) > 0),
  created_at TEXT NOT NULL,
  UNIQUE(company_id, name)
);

CREATE TABLE roles (
  id TEXT PRIMARY KEY CHECK (length(id) > 0),
  company_id TEXT NOT NULL REFERENCES companies(id) ON DELETE RESTRICT,
  name TEXT NOT NULL CHECK (length(trim(name)) > 0),
  UNIQUE(company_id, name),
  UNIQUE(id, company_id)
);

CREATE TABLE permissions (
  code TEXT PRIMARY KEY CHECK (length(trim(code)) > 0),
  description TEXT NOT NULL
);

CREATE TABLE role_permissions (
  role_id TEXT NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
  permission_code TEXT NOT NULL REFERENCES permissions(code) ON DELETE RESTRICT,
  PRIMARY KEY(role_id, permission_code)
);

CREATE TABLE users (
  id TEXT PRIMARY KEY CHECK (length(id) > 0),
  company_id TEXT NOT NULL REFERENCES companies(id) ON DELETE RESTRICT,
  branch_id TEXT NOT NULL REFERENCES branches(id) ON DELETE RESTRICT,
  username TEXT NOT NULL CHECK (length(trim(username)) > 0),
  password_hash TEXT NOT NULL CHECK (length(password_hash) > 0),
  is_active INTEGER NOT NULL DEFAULT 1 CHECK (is_active IN (0, 1)),
  created_at TEXT NOT NULL,
  UNIQUE(company_id, username),
  FOREIGN KEY(branch_id, company_id) REFERENCES branches(id, company_id)
);

CREATE UNIQUE INDEX branches_id_company ON branches(id, company_id);

CREATE TABLE user_roles (
  user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  role_id TEXT NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
  company_id TEXT NOT NULL REFERENCES companies(id) ON DELETE RESTRICT,
  PRIMARY KEY(user_id, role_id),
  FOREIGN KEY(user_id, company_id) REFERENCES users(id, company_id),
  FOREIGN KEY(role_id, company_id) REFERENCES roles(id, company_id)
);

CREATE UNIQUE INDEX users_id_company ON users(id, company_id);

CREATE TABLE product_categories (
  id TEXT PRIMARY KEY CHECK (length(id) > 0),
  company_id TEXT NOT NULL REFERENCES companies(id) ON DELETE RESTRICT,
  name TEXT NOT NULL CHECK (length(trim(name)) > 0),
  UNIQUE(company_id, name),
  UNIQUE(id, company_id)
);

CREATE TABLE units (
  id TEXT PRIMARY KEY CHECK (length(id) > 0),
  company_id TEXT NOT NULL REFERENCES companies(id) ON DELETE RESTRICT,
  name TEXT NOT NULL CHECK (length(trim(name)) > 0),
  UNIQUE(company_id, name),
  UNIQUE(id, company_id)
);

CREATE TABLE products (
  id TEXT PRIMARY KEY CHECK (length(id) > 0),
  company_id TEXT NOT NULL REFERENCES companies(id) ON DELETE RESTRICT,
  sku TEXT NOT NULL CHECK (length(trim(sku)) > 0),
  name TEXT NOT NULL CHECK (length(trim(name)) > 0),
  category_id TEXT REFERENCES product_categories(id) ON DELETE RESTRICT,
  unit_id TEXT NOT NULL REFERENCES units(id) ON DELETE RESTRICT,
  is_active INTEGER NOT NULL DEFAULT 1 CHECK (is_active IN (0, 1)),
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  UNIQUE(company_id, sku),
  FOREIGN KEY(category_id, company_id) REFERENCES product_categories(id, company_id),
  FOREIGN KEY(unit_id, company_id) REFERENCES units(id, company_id)
);

CREATE TABLE customers (
  id TEXT PRIMARY KEY CHECK (length(id) > 0),
  company_id TEXT NOT NULL REFERENCES companies(id) ON DELETE RESTRICT,
  name TEXT NOT NULL CHECK (length(trim(name)) > 0),
  phone TEXT,
  created_at TEXT NOT NULL,
  UNIQUE(id, company_id)
);

CREATE TABLE suppliers (
  id TEXT PRIMARY KEY CHECK (length(id) > 0),
  company_id TEXT NOT NULL REFERENCES companies(id) ON DELETE RESTRICT,
  name TEXT NOT NULL CHECK (length(trim(name)) > 0),
  phone TEXT,
  created_at TEXT NOT NULL
);

CREATE TABLE warehouses (
  id TEXT PRIMARY KEY CHECK (length(id) > 0),
  company_id TEXT NOT NULL REFERENCES companies(id) ON DELETE RESTRICT,
  branch_id TEXT NOT NULL REFERENCES branches(id) ON DELETE RESTRICT,
  name TEXT NOT NULL CHECK (length(trim(name)) > 0),
  UNIQUE(company_id, name),
  FOREIGN KEY(branch_id, company_id) REFERENCES branches(id, company_id)
);

INSERT INTO schema_migrations (version, applied_at)
VALUES (1, strftime('%Y-%m-%dT%H:%M:%fZ', 'now'));
