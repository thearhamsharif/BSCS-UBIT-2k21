-- ==================================================
-- DATABASE: pos_dds (Distributed Retail POS)
-- ==================================================

-- Create database
CREATE DATABASE pos_dds;
\c pos_dds;

-- ==================================================
-- 0. Extensions
-- ==================================================
CREATE EXTENSION IF NOT EXISTS dblink;
CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;

-- ==================================================
-- 1. Schemas
-- ==================================================
CREATE SCHEMA IF NOT EXISTS central;
CREATE SCHEMA IF NOT EXISTS karachi;
CREATE SCHEMA IF NOT EXISTS lahore;

-- ==================================================
-- 2. CENTRAL TABLES
-- ==================================================
SET search_path = central;

-- Cities
CREATE TABLE IF NOT EXISTS Cities (
  id SERIAL PRIMARY KEY,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  created_by INT,
  updated_by INT,
  name VARCHAR(100) UNIQUE NOT NULL
);

-- Stores
CREATE TABLE IF NOT EXISTS Stores (
  id SERIAL PRIMARY KEY,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  created_by INT,
  updated_by INT,
  city_id INT NOT NULL REFERENCES central.Cities(id),
  name VARCHAR(100) NOT NULL,
  code VARCHAR(50) UNIQUE NOT NULL
);

-- Categories
CREATE TABLE IF NOT EXISTS Categories (
  id SERIAL PRIMARY KEY,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  created_by INT,
  updated_by INT,
  name VARCHAR(100) UNIQUE NOT NULL,
  description TEXT
);

-- Roles
CREATE TABLE IF NOT EXISTS Roles (
  id SERIAL PRIMARY KEY,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  created_by INT,
  updated_by INT,
  role_name VARCHAR(50) UNIQUE NOT NULL,
  description TEXT
);

-- Users
CREATE TABLE IF NOT EXISTS Users (
  id SERIAL PRIMARY KEY,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  created_by INT,
  updated_by INT,
  username VARCHAR(150) UNIQUE NOT NULL,
  email VARCHAR(150) UNIQUE NOT NULL,
  password_hash TEXT NOT NULL,
  full_name VARCHAR(100),
  role_id INT REFERENCES central.Roles(id),
  store_id INT REFERENCES central.Stores(id)
);

-- Products
CREATE TABLE IF NOT EXISTS Products (
  id SERIAL PRIMARY KEY,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  created_by INT,
  updated_by INT,
  sku VARCHAR(100) UNIQUE NOT NULL,
  name VARCHAR(150) NOT NULL,
  category_id INT REFERENCES central.Categories(id),
  price NUMERIC(12,2) NOT NULL CHECK (price >= 0)
);

-- Suppliers
CREATE TABLE IF NOT EXISTS Suppliers (
  id SERIAL PRIMARY KEY,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  created_by INT,
  updated_by INT,
  name VARCHAR(150) NOT NULL,
  contact_info TEXT
);

-- Inventory
CREATE TABLE IF NOT EXISTS Inventory (
  id SERIAL PRIMARY KEY,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  created_by INT,
  updated_by INT,
  product_id INT NOT NULL REFERENCES central.Products(id),
  store_id INT NOT NULL REFERENCES central.Stores(id),
  quantity INT NOT NULL DEFAULT 0 CHECK (quantity >= 0),
  purchase_price NUMERIC(12,2),
  UNIQUE(product_id, store_id)
);

-- Customers
CREATE TABLE IF NOT EXISTS Customers (
  id SERIAL PRIMARY KEY,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  created_by INT,
  updated_by INT,
  city_id INT NOT NULL REFERENCES central.Cities(id),
  name VARCHAR(150) NOT NULL,
  phone VARCHAR(20),
  email VARCHAR(150)
);

-- Order_Mapping
CREATE TABLE IF NOT EXISTS Order_Mapping (
  id SERIAL PRIMARY KEY,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  created_by INT,
  updated_by INT,
  global_order_id UUID UNIQUE DEFAULT gen_random_uuid(),
  store_id INT NOT NULL REFERENCES central.Stores(id),
  store_order_id INT NOT NULL,
  customer_id INT REFERENCES central.Customers(id),
  order_time TIMESTAMPTZ DEFAULT now()
);

-- Orders
CREATE TABLE IF NOT EXISTS Orders (
  id SERIAL PRIMARY KEY,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  created_by INT,
  updated_by INT,
  global_order_id UUID NOT NULL REFERENCES central.Order_Mapping(global_order_id),
  store_id INT NOT NULL REFERENCES central.Stores(id),
  customer_id INT REFERENCES central.Customers(id),
  order_date TIMESTAMPTZ DEFAULT now(),
  total_amount NUMERIC(12,2) NOT NULL,
  status VARCHAR(50) DEFAULT 'Pending',
  tracking_code VARCHAR(50) UNIQUE DEFAULT ('TRK-' || to_char(now(), 'YYYYMMDD') || '-' || substr(md5(gen_random_uuid()::text),1,6))
);

-- Order_Items
CREATE TABLE IF NOT EXISTS Order_Items (
  id SERIAL PRIMARY KEY,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  created_by INT,
  updated_by INT,
  order_id INT NOT NULL REFERENCES central.Orders(id),
  product_id INT NOT NULL REFERENCES central.Products(id),
  quantity INT NOT NULL CHECK (quantity > 0),
  price NUMERIC(12,2) NOT NULL
);

-- Payments
CREATE TABLE IF NOT EXISTS Payments (
  id SERIAL PRIMARY KEY,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  created_by INT,
  updated_by INT,
  global_order_id UUID NOT NULL REFERENCES central.Order_Mapping(global_order_id),
  amount NUMERIC(12,2) NOT NULL,
  method VARCHAR(50) CHECK (method IN ('Cash','Card','Online')),
  status VARCHAR(50) DEFAULT 'Paid'
);

-- Audit_Logs
CREATE TABLE IF NOT EXISTS Audit_Logs (
  id SERIAL PRIMARY KEY,
  created_at TIMESTAMPTZ DEFAULT now(),
  created_by INT,
  table_name TEXT NOT NULL,
  action TEXT NOT NULL,
  payload JSONB
);

-- ==================================================
-- 3. NODES TABLES (Karachi & Lahore)
-- ==================================================
-- Customers
CREATE TABLE karachi.Customers AS SELECT * FROM central.Customers WHERE city_id=(SELECT id FROM central.Cities WHERE name='Karachi');
CREATE TABLE lahore.Customers AS SELECT * FROM central.Customers WHERE city_id=(SELECT id FROM central.Cities WHERE name='Lahore');

-- Orders
CREATE TABLE karachi.Orders AS
SELECT o.* FROM central.Orders o JOIN central.Stores s ON o.store_id=s.id WHERE s.city_id=(SELECT id FROM central.Cities WHERE name='Karachi');
CREATE TABLE lahore.Orders AS
SELECT o.* FROM central.Orders o JOIN central.Stores s ON o.store_id=s.id WHERE s.city_id=(SELECT id FROM central.Cities WHERE name='Lahore');

-- Order_Items
CREATE TABLE karachi.Order_Items AS
SELECT oi.* FROM central.Order_Items oi JOIN central.Orders o ON oi.order_id=o.id JOIN central.Stores s ON o.store_id=s.id WHERE s.city_id=(SELECT id FROM central.Cities WHERE name='Karachi');
CREATE TABLE lahore.Order_Items AS
SELECT oi.* FROM central.Order_Items oi JOIN central.Orders o ON oi.order_id=o.id JOIN central.Stores s ON o.store_id=s.id WHERE s.city_id=(SELECT id FROM central.Cities WHERE name='Lahore');

-- Payments
CREATE TABLE karachi.Payments AS
SELECT p.* FROM central.Payments p JOIN central.Order_Mapping om ON p.global_order_id=om.global_order_id JOIN central.Stores s ON om.store_id=s.id WHERE s.city_id=(SELECT id FROM central.Cities WHERE name='Karachi');
CREATE TABLE lahore.Payments AS
SELECT p.* FROM central.Payments p JOIN central.Order_Mapping om ON p.global_order_id=om.global_order_id JOIN central.Stores s ON om.store_id=s.id WHERE s.city_id=(SELECT id FROM central.Cities WHERE name='Lahore');

-- Inventory
CREATE TABLE karachi.Inventory AS SELECT i.* FROM central.Inventory i JOIN central.Stores s ON i.store_id=s.id WHERE s.city_id=(SELECT id FROM central.Cities WHERE name='Karachi');
CREATE TABLE lahore.Inventory AS SELECT i.* FROM central.Inventory i JOIN central.Stores s ON i.store_id=s.id WHERE s.city_id=(SELECT id FROM central.Cities WHERE name='Lahore');

-- ==================================================
-- 4. FULL REPLICATION TRIGGERS (Karachi & Lahore)
-- ==================================================
-- Example: replicate Stores for Karachi
CREATE OR REPLACE FUNCTION replicate_store_karachi()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.city_id = (SELECT id FROM central.Cities WHERE name='Karachi') THEN
    INSERT INTO karachi.Stores VALUES (NEW.*)
    ON CONFLICT (id) DO UPDATE SET name=EXCLUDED.name, code=EXCLUDED.code, updated_at=EXCLUDED.updated_at;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_store_insert_karachi
AFTER INSERT OR UPDATE ON central.Stores
FOR EACH ROW EXECUTE FUNCTION replicate_store_karachi();

-- replicate Stores for Lahore
CREATE OR REPLACE FUNCTION replicate_store_lahore()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.city_id = (SELECT id FROM central.Cities WHERE name='Lahore') THEN
    INSERT INTO lahore.Stores VALUES (NEW.*)
    ON CONFLICT (id) DO UPDATE SET name=EXCLUDED.name, code=EXCLUDED.code, updated_at=EXCLUDED.updated_at;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_store_insert_lahore
AFTER INSERT OR UPDATE ON central.Stores
FOR EACH ROW EXECUTE FUNCTION replicate_store_lahore();

-- replicate Products for Karachi
CREATE OR REPLACE FUNCTION replicate_product_karachi()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO karachi.Products VALUES (NEW.*)
  ON CONFLICT (id) DO UPDATE SET name=EXCLUDED.name, price=EXCLUDED.price, category_id=EXCLUDED.category_id, updated_at=EXCLUDED.updated_at;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_product_insert_karachi
AFTER INSERT OR UPDATE ON central.Products
FOR EACH ROW EXECUTE FUNCTION replicate_product_karachi();

-- replicate Products for Lahore
CREATE OR REPLACE FUNCTION replicate_product_lahore()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO lahore.Products VALUES (NEW.*)
  ON CONFLICT (id) DO UPDATE SET name=EXCLUDED.name, price=EXCLUDED.price, category_id=EXCLUDED.category_id, updated_at=EXCLUDED.updated_at;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_product_insert_lahore
AFTER INSERT OR UPDATE ON central.Products
FOR EACH ROW EXECUTE FUNCTION replicate_product_lahore();

-- replicate Categories for Karachi
CREATE OR REPLACE FUNCTION replicate_category_karachi()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO karachi.Categories VALUES (NEW.*)
  ON CONFLICT (id) DO UPDATE SET name=EXCLUDED.name, description=EXCLUDED.description, updated_at=EXCLUDED.updated_at;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_category_insert_karachi
AFTER INSERT OR UPDATE ON central.Categories
FOR EACH ROW EXECUTE FUNCTION replicate_category_karachi();

-- replicate Categories for Lahore
CREATE OR REPLACE FUNCTION replicate_category_lahore()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO lahore.Categories VALUES (NEW.*)
  ON CONFLICT (id) DO UPDATE SET name=EXCLUDED.name, description=EXCLUDED.description, updated_at=EXCLUDED.updated_at;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_category_insert_lahore
AFTER INSERT OR UPDATE ON central.Categories
FOR EACH ROW EXECUTE FUNCTION replicate_category_lahore();

-- replicate Roles for Karachi
CREATE OR REPLACE FUNCTION replicate_role_karachi()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO karachi.Roles VALUES (NEW.*)
  ON CONFLICT (id) DO UPDATE SET role_name=EXCLUDED.role_name, description=EXCLUDED.description, updated_at=EXCLUDED.updated_at;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_role_insert_karachi
AFTER INSERT OR UPDATE ON central.Roles
FOR EACH ROW EXECUTE FUNCTION replicate_role_karachi();

-- replicate Roles for Lahore
CREATE OR REPLACE FUNCTION replicate_role_lahore()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO lahore.Roles VALUES (NEW.*)
  ON CONFLICT (id) DO UPDATE SET role_name=EXCLUDED.role_name, description=EXCLUDED.description, updated_at=EXCLUDED.updated_at;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_role_insert_lahore
AFTER INSERT OR UPDATE ON central.Roles
FOR EACH ROW EXECUTE FUNCTION replicate_role_lahore();

-- replicate Suppliers for Karachi
CREATE OR REPLACE FUNCTION replicate_supplier_karachi()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO karachi.Suppliers VALUES (NEW.*)
  ON CONFLICT (id) DO UPDATE SET name=EXCLUDED.name, contact_info=EXCLUDED.contact_info, updated_at=EXCLUDED.updated_at;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_supplier_insert_karachi
AFTER INSERT OR UPDATE ON central.Suppliers
FOR EACH ROW EXECUTE FUNCTION replicate_supplier_karachi();

-- replicate Suppliers for Lahore
CREATE OR REPLACE FUNCTION replicate_supplier_lahore()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO lahore.Suppliers VALUES (NEW.*)
  ON CONFLICT (id) DO UPDATE SET name=EXCLUDED.name, contact_info=EXCLUDED.contact_info, updated_at=EXCLUDED.updated_at;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_supplier_insert_lahore
AFTER INSERT OR UPDATE ON central.Suppliers
FOR EACH ROW EXECUTE FUNCTION replicate_supplier_lahore();

-- ==================================================
-- 5. INDEXES & PERFORMANCE
-- ==================================================
-- Central indexes
CREATE INDEX IF NOT EXISTS idx_cities_name ON central.Cities(name);
CREATE INDEX IF NOT EXISTS idx_stores_city_id ON central.Stores(city_id);
CREATE INDEX IF NOT EXISTS idx_stores_code ON central.Stores(code);
CREATE INDEX IF NOT EXISTS idx_categories_name ON central.Categories(name);
CREATE INDEX IF NOT EXISTS idx_users_role_id ON central.Users(role_id);
CREATE INDEX IF NOT EXISTS idx_users_store_id ON central.Users(store_id);
CREATE INDEX IF NOT EXISTS idx_products_category_id ON central.Products(category_id);
CREATE INDEX IF NOT EXISTS idx_products_sku ON central.Products(sku);
CREATE INDEX IF NOT EXISTS idx_inventory_product_store ON central.Inventory(product_id,store_id);
CREATE INDEX IF NOT EXISTS idx_customers_city_id ON central.Customers(city_id);
CREATE INDEX IF NOT EXISTS idx_customers_phone ON central.Customers(phone);
CREATE UNIQUE INDEX IF NOT EXISTS idx_order_mapping_store_order ON central.Order_Mapping(store_id,store_order_id);
CREATE INDEX IF NOT EXISTS idx_orders_store_id ON central.Orders(store_id);
CREATE INDEX IF NOT EXISTS idx_orders_customer_id ON central.Orders(customer_id);
CREATE INDEX IF NOT EXISTS idx_orders_global_order_id ON central.Orders(global_order_id);
CREATE UNIQUE INDEX IF NOT EXISTS idx_orders_tracking_code ON central.Orders(tracking_code);
CREATE INDEX IF NOT EXISTS idx_order_items_order_id ON central.Order_Items(order_id);
CREATE INDEX IF NOT EXISTS idx_order_items_product_id ON central.Order_Items(product_id);
CREATE INDEX IF NOT EXISTS idx_payments_global_order_id ON central.Payments(global_order_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_table_action ON central.Audit_Logs(table_name,action);

-- Karachi indexes
CREATE INDEX idx_karachi_orders_store_id ON karachi.Orders(store_id);
CREATE INDEX idx_karachi_order_items_order_id ON karachi.Order_Items(order_id);
CREATE INDEX idx_karachi_inventory_product_store ON karachi.Inventory(product_id,store_id);

-- Lahore indexes
CREATE INDEX idx_lahore_orders_store_id ON lahore.Orders(store_id);
CREATE INDEX idx_lahore_order_items_order_id ON lahore.Order_Items(order_id);
CREATE INDEX idx_lahore_inventory_product_store ON lahore.Inventory(product_id,store_id);

-- ==================================================
-- 6. BACKUP & RESTORE SNIPPETS
-- ==================================================
-- pg_dump -n central pos_dds > central_backup.sql
-- pg_dump -n karachi pos_dds > karachi_backup.sql
-- pg_dump -n lahore pos_dds > lahore_backup.sql
-- psql pos_dds < central_backup.sql
-- psql pos_dds < karachi_backup.sql
-- psql pos_dds < lahore_backup.sql

-- ==================================================
-- 7. SECURITY: Roles & Permissions
-- ==================================================
CREATE ROLE karachi_user LOGIN PASSWORD 'pass123';
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA karachi TO karachi_user;
CREATE ROLE lahore_user LOGIN PASSWORD 'pass123';
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA lahore TO lahore_user;
CREATE ROLE central_readonly LOGIN PASSWORD 'pass123';
GRANT SELECT ON ALL TABLES IN SCHEMA central TO central_readonly;

-- ==================================================
-- 8. SAMPLE DISTRIBUTED QUERIES
-- ==================================================
-- Local query (Karachi orders)
SELECT o.id, o.order_date, o.total_amount, c.name AS customer_name
FROM karachi.Orders o
JOIN karachi.Customers c ON o.customer_id=c.id;

-- Global query (total sales per product)
WITH karachi_sales AS (
  SELECT product_id, SUM(quantity*price) AS total_sales
  FROM karachi.Order_Items
  GROUP BY product_id
), lahore_sales AS (
  SELECT product_id, SUM(quantity*price) AS total_sales
  FROM lahore.Order_Items
  GROUP BY product_id
)
SELECT p.id, p.name, COALESCE(k.total_sales,0)+COALESCE(l.total_sales,0) AS total_sales
FROM central.Products p
LEFT JOIN karachi_sales k ON p.id=k.product_id
LEFT JOIN lahore_sales l ON p.id=l.product_id
ORDER BY total_sales DESC;

-- ==================================================
-- END OF FILE
-- ==================================================
