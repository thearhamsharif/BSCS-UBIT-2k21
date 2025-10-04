-- File: query.sql
-- DB name: pos_dds
CREATE DATABASE pos_dds;
\c pos_dds;

-- ================================================
-- 0. Extensions
-- ================================================
CREATE EXTENSION IF NOT EXISTS dblink; -- for cross-db queries
CREATE EXTENSION IF NOT EXISTS pgcrypto; -- for gen_random_uuid()
CREATE EXTENSION IF NOT EXISTS pg_stat_statements; -- for query performance monitoring and statistics

-- ================================================
-- 1. Schemas
-- ================================================
CREATE SCHEMA IF NOT EXISTS central;
CREATE SCHEMA IF NOT EXISTS karachi;
CREATE SCHEMA IF NOT EXISTS lahore;

-- ================================================
-- 2. CENTRAL TABLES (master)
-- ================================================
SET search_path = central;

-- Cities
CREATE TABLE IF NOT EXISTS central.Cities (
  id SERIAL PRIMARY KEY,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  created_by INT,
  updated_by INT,
  name VARCHAR(100) UNIQUE NOT NULL
);

-- Stores
CREATE TABLE IF NOT EXISTS central.Stores (
  id SERIAL PRIMARY KEY,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  created_by INT,
  updated_by INT,
  city_id INT NOT NULL REFERENCES central.Cities(id),
  name VARCHAR(100) NOT NULL,
  code VARCHAR(50) UNIQUE NOT NULL
);

-- Categories
CREATE TABLE IF NOT EXISTS central.Categories (
  id SERIAL PRIMARY KEY,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  created_by INT,
  updated_by INT,
  name VARCHAR(100) UNIQUE NOT NULL,
  description TEXT
);

-- Roles
CREATE TABLE IF NOT EXISTS central.Roles (
  id SERIAL PRIMARY KEY,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  created_by INT,
  updated_by INT,
  role_name VARCHAR(50) UNIQUE NOT NULL,
  description TEXT
);

-- Users
CREATE TABLE IF NOT EXISTS central.Users (
  id SERIAL PRIMARY KEY,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
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
CREATE TABLE IF NOT EXISTS central.Products (
  id SERIAL PRIMARY KEY,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  created_by INT,
  updated_by INT,
  sku VARCHAR(100) UNIQUE NOT NULL,
  name VARCHAR(150) NOT NULL,
  category_id INT REFERENCES central.Categories(id),
  price NUMERIC(12,2) NOT NULL CHECK (price >= 0)
);

-- Suppliers
CREATE TABLE IF NOT EXISTS central.Suppliers (
  id SERIAL PRIMARY KEY,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  created_by INT,
  updated_by INT,
  name VARCHAR(150) NOT NULL,
  contact_info TEXT
);

-- Inventory
CREATE TABLE IF NOT EXISTS central.Inventory (
  id SERIAL PRIMARY KEY,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  created_by INT,
  updated_by INT,
  product_id INT NOT NULL REFERENCES central.Products(id),
  store_id INT NOT NULL REFERENCES central.Stores(id),
  quantity INT NOT NULL DEFAULT 0 CHECK (quantity >= 0),
  purchase_price NUMERIC(12,2),
  UNIQUE(product_id, store_id)
);

-- Customers
CREATE TABLE IF NOT EXISTS central.Customers (
  id SERIAL PRIMARY KEY,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  created_by INT,
  updated_by INT,
  city_id INT NOT NULL REFERENCES central.Cities(id),
  name VARCHAR(150) NOT NULL,
  phone VARCHAR(20),
  email VARCHAR(150)
);

-- Order_Mapping
CREATE TABLE IF NOT EXISTS central.Order_Mapping (
  id SERIAL PRIMARY KEY,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  created_by INT,
  updated_by INT,
  global_order_id UUID UNIQUE DEFAULT gen_random_uuid(),
  store_id INT NOT NULL REFERENCES central.Stores(id),
  store_order_id INT NOT NULL,
  customer_id INT REFERENCES central.Customers(id),
  order_time TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Orders
CREATE TABLE IF NOT EXISTS central.Orders (
  id SERIAL PRIMARY KEY,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  created_by INT,
  updated_by INT,
  global_order_id UUID NOT NULL REFERENCES central.Order_Mapping(global_order_id),
  store_id INT NOT NULL REFERENCES central.Stores(id),
  customer_id INT REFERENCES central.Customers(id),
  order_date TIMESTAMP WITH TIME ZONE DEFAULT now(),
  total_amount NUMERIC(12,2) NOT NULL,
  status VARCHAR(50) DEFAULT 'Pending',
  tracking_code VARCHAR(50) UNIQUE DEFAULT (
    'TRK-' || to_char(now(), 'YYYYMMDD') || '-' ||
    substr(md5(gen_random_uuid()::text), 1, 6)
  )
);

-- Order Items
CREATE TABLE IF NOT EXISTS central.Order_Items (
  id SERIAL PRIMARY KEY,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  created_by INT,
  updated_by INT,
  order_id INT NOT NULL REFERENCES central.Orders(id),
  product_id INT NOT NULL REFERENCES central.Products(id),
  quantity INT NOT NULL CHECK (quantity > 0),
  price NUMERIC(12,2) NOT NULL
);

-- Payments
CREATE TABLE IF NOT EXISTS central.Payments (
  id SERIAL PRIMARY KEY,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  created_by INT,
  updated_by INT,
  global_order_id UUID NOT NULL REFERENCES central.Order_Mapping(global_order_id),
  amount NUMERIC(12,2) NOT NULL,
  method VARCHAR(50) CHECK (method IN ('Cash','Card','Online')),
  status VARCHAR(50) DEFAULT 'Paid'
);

-- Audit_Logs
CREATE TABLE IF NOT EXISTS central.Audit_Logs (
  id SERIAL PRIMARY KEY,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  created_by INT,
  table_name TEXT NOT NULL,
  action TEXT NOT NULL,
  payload JSONB
);  

-- ================================================
-- 3. NODES TABLES (karachi and lahore)
-- ================================================
-- Karachi Customers
CREATE TABLE karachi.Customers AS
SELECT * FROM central.Customers
WHERE city_id = (SELECT id FROM central.Cities WHERE name='Karachi');

-- Lahore Customers
CREATE TABLE lahore.Customers AS
SELECT * FROM central.Customers
WHERE city_id = (SELECT id FROM central.Cities WHERE name='Lahore');

-- Karachi Orders
CREATE TABLE karachi.Orders AS
SELECT * FROM central.Orders o
JOIN central.Stores s ON o.store_id = s.id
WHERE s.city_id = (SELECT id FROM central.Cities WHERE name='Karachi');

-- Lahore Orders
CREATE TABLE lahore.Orders AS
SELECT * FROM central.Orders o
JOIN central.Stores s ON o.store_id = s.id
WHERE s.city_id = (SELECT id FROM central.Cities WHERE name='Lahore');

-- Karachi Order_Items
CREATE TABLE karachi.Order_Items AS
SELECT oi.*
FROM central.Order_Items oi
JOIN central.Orders o ON oi.order_id = o.id
JOIN central.Stores s ON o.store_id = s.id
WHERE s.city_id = (SELECT id FROM central.Cities WHERE name='Karachi');

-- Lahore Order_Items
CREATE TABLE lahore.Order_Items AS
SELECT oi.*
FROM central.Order_Items oi
JOIN central.Orders o ON oi.order_id = o.id
JOIN central.Stores s ON o.store_id = s.id
WHERE s.city_id = (SELECT id FROM central.Cities WHERE name='Lahore');

-- Karachi Payments
CREATE TABLE karachi.Payments AS
SELECT p.*
FROM central.Payments p
JOIN central.Order_Mapping om ON p.global_order_id = om.global_order_id
JOIN central.Stores s ON om.store_id = s.id
WHERE s.city_id = (SELECT id FROM central.Cities WHERE name='Karachi');

-- Lahore Payments
CREATE TABLE lahore.Payments AS
SELECT p.*
FROM central.Payments p
JOIN central.Order_Mapping om ON p.global_order_id = om.global_order_id
JOIN central.Stores s ON om.store_id = s.id
WHERE s.city_id = (SELECT id FROM central.Cities WHERE name='Lahore');

-- Karachi Inventory
CREATE TABLE karachi.Inventory AS
SELECT i.*
FROM central.Inventory i
JOIN central.Stores s ON i.store_id = s.id
WHERE s.city_id = (SELECT id FROM central.Cities WHERE name='Karachi');

-- Lahore Inventory
CREATE TABLE lahore.Inventory AS
SELECT i.*
FROM central.Inventory i
JOIN central.Stores s ON i.store_id = s.id
WHERE s.city_id = (SELECT id FROM central.Cities WHERE name='Lahore');

-- ================================================
-- 4. Replication Triggers
-- ================================================
-- Karachi Store
CREATE OR REPLACE FUNCTION replicate_store_karachi()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.city_id = (SELECT id FROM central.Cities WHERE name='Karachi') THEN
    INSERT INTO karachi.Stores VALUES (NEW.*)
    ON CONFLICT (id) DO UPDATE
    SET name = EXCLUDED.name,
        code = EXCLUDED.code,
        updated_at = EXCLUDED.updated_at;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_store_insert_karachi
AFTER INSERT OR UPDATE ON central.Stores
FOR EACH ROW EXECUTE FUNCTION replicate_store_karachi();

-- Lahore Store
CREATE OR REPLACE FUNCTION replicate_store_lahore()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.city_id = (SELECT id FROM central.Cities WHERE name='Lahore') THEN
    INSERT INTO lahore.Stores VALUES (NEW.*)
    ON CONFLICT (id) DO UPDATE
    SET name = EXCLUDED.name,
        code = EXCLUDED.code,
        updated_at = EXCLUDED.updated_at;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_store_insert_lahore
AFTER INSERT OR UPDATE ON central.Stores
FOR EACH ROW EXECUTE FUNCTION replicate_store_lahore();

-- Karachi Products
CREATE OR REPLACE FUNCTION replicate_product_karachi()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO karachi.Products VALUES (NEW.*)
  ON CONFLICT (id) DO UPDATE
    SET name = EXCLUDED.name,
        price = EXCLUDED.price,
        category_id = EXCLUDED.category_id,
        updated_at = EXCLUDED.updated_at;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_product_insert_karachi
AFTER INSERT OR UPDATE ON central.Products
FOR EACH ROW EXECUTE FUNCTION replicate_product_karachi();

-- Lahore Products
CREATE OR REPLACE FUNCTION replicate_product_lahore()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO lahore.Products VALUES (NEW.*)
  ON CONFLICT (id) DO UPDATE
    SET name = EXCLUDED.name,
        price = EXCLUDED.price,
        category_id = EXCLUDED.category_id,
        updated_at = EXCLUDED.updated_at;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_product_insert_lahore
AFTER INSERT OR UPDATE ON central.Products
FOR EACH ROW EXECUTE FUNCTION replicate_product_lahore();

-- Karachi Categories
CREATE OR REPLACE FUNCTION replicate_category_karachi()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO karachi.Categories VALUES (NEW.*)
  ON CONFLICT (id) DO UPDATE
    SET name = EXCLUDED.name,
        description = EXCLUDED.description,
        updated_at = EXCLUDED.updated_at;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_category_insert_karachi
AFTER INSERT OR UPDATE ON central.Categories
FOR EACH ROW EXECUTE FUNCTION replicate_category_karachi();

-- Lahore Categories
CREATE OR REPLACE FUNCTION replicate_category_lahore()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO lahore.Categories VALUES (NEW.*)
  ON CONFLICT (id) DO UPDATE
    SET name = EXCLUDED.name,
        description = EXCLUDED.description,
        updated_at = EXCLUDED.updated_at;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_category_insert_lahore
AFTER INSERT OR UPDATE ON central.Categories
FOR EACH ROW EXECUTE FUNCTION replicate_category_lahore();

-- Karachi Roles
CREATE OR REPLACE FUNCTION replicate_role_karachi()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO karachi.Roles VALUES (NEW.*)
  ON CONFLICT (id) DO UPDATE
    SET role_name = EXCLUDED.role_name,
        description = EXCLUDED.description,
        updated_at = EXCLUDED.updated_at;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_role_insert_karachi
AFTER INSERT OR UPDATE ON central.Roles
FOR EACH ROW EXECUTE FUNCTION replicate_role_karachi();

-- Lahore Roles
CREATE OR REPLACE FUNCTION replicate_role_lahore()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO lahore.Roles VALUES (NEW.*)
  ON CONFLICT (id) DO UPDATE
    SET role_name = EXCLUDED.role_name,
        description = EXCLUDED.description,
        updated_at = EXCLUDED.updated_at;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_role_insert_lahore
AFTER INSERT OR UPDATE ON central.Roles
FOR EACH ROW EXECUTE FUNCTION replicate_role_lahore();

-- Karachi Suppliers
CREATE OR REPLACE FUNCTION replicate_supplier_karachi()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO karachi.Suppliers VALUES (NEW.*)
  ON CONFLICT (id) DO UPDATE
    SET name = EXCLUDED.name,
        contact_info = EXCLUDED.contact_info,
        updated_at = EXCLUDED.updated_at;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_supplier_insert_karachi
AFTER INSERT OR UPDATE ON central.Suppliers
FOR EACH ROW EXECUTE FUNCTION replicate_supplier_karachi();

-- Lahore Suppliers
CREATE OR REPLACE FUNCTION replicate_supplier_lahore()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO lahore.Suppliers VALUES (NEW.*)
  ON CONFLICT (id) DO UPDATE
    SET name = EXCLUDED.name,
        contact_info = EXCLUDED.contact_info,
        updated_at = EXCLUDED.updated_at;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_supplier_insert_lahore
AFTER INSERT OR UPDATE ON central.Suppliers
FOR EACH ROW EXECUTE FUNCTION replicate_supplier_lahore();

-- ================================================
-- 5. Distributed Queries & Transactions
-- ================================================
-- 1. Local Queries (city-specific)

-- Get all orders in Karachi:
SELECT o.id, o.order_date, o.total_amount, c.name AS customer_name
FROM karachi.Orders o
JOIN karachi.Customers c ON o.customer_id = c.id;

-- Get inventory for Lahore store:
SELECT i.product_id, p.name AS product_name, i.quantity
FROM lahore.Inventory i
JOIN central.Products p ON i.product_id = p.id
WHERE i.store_id = 1; -- specific store

-- 2. Global Queries (combine all cities)

-- All orders across Karachi and Lahore:
SELECT * FROM karachi.Orders
UNION ALL
SELECT * FROM lahore.Orders;

-- Total sales per product across all cities:
SELECT oi.product_id, p.name, SUM(oi.quantity) AS total_qty, SUM(oi.price * oi.quantity) AS total_sales
FROM (
    SELECT * FROM karachi.Order_Items
    UNION ALL
    SELECT * FROM lahore.Order_Items
) oi
JOIN central.Products p ON oi.product_id = p.id
GROUP BY oi.product_id, p.name;

-- 3. Distributed Transactions Example

-- Scenario: Place an order in Karachi → update Orders, Order_Items, Payments, Inventory atomically
BEGIN;

-- Insert order
INSERT INTO karachi.Orders (global_order_id, store_id, customer_id, total_amount)
VALUES (gen_random_uuid(), 1, 101, 1200)
RETURNING id INTO order_id;

-- Insert order items
INSERT INTO karachi.Order_Items (order_id, product_id, quantity, price)
VALUES (order_id, 201, 2, 600);

-- Insert payment
INSERT INTO karachi.Payments (global_order_id, amount, method, status)
VALUES ((SELECT global_order_id FROM karachi.Orders WHERE id = order_id), 1200, 'Card', 'Paid');

-- Update inventory
UPDATE karachi.Inventory
SET quantity = quantity - 2
WHERE store_id = 1 AND product_id = 201;

COMMIT;

-- 4. Cross-City / Global Transaction Example

-- Scenario: Generate consolidated report → combine data from all cities

SELECT product_id, p.name, SUM(quantity) AS total_qty, SUM(price*quantity) AS total_sales
FROM (
    SELECT * FROM karachi.Order_Items
    UNION ALL
    SELECT * FROM lahore.Order_Items
) oi
JOIN central.Products p ON oi.product_id = p.id
GROUP BY product_id, p.name
ORDER BY total_sales DESC;

-- ================================================
-- 6. Backup, Recovery & Security
-- ================================================
-- 1. Backup

-- a) City-specific backup
-- Karachi schema
pg_dump -n karachi pos_dds > karachi_backup.sql

-- Lahore schema
pg_dump -n lahore pos_dds > lahore_backup.sql

-- b) Central schema backup
pg_dump -n central pos_dds > central_backup.sql

-- 2. Recovery

-- a) Restore city schema
psql pos_dds < karachi_backup.sql
psql pos_dds < lahore_backup.sql

-- b) Restore central schema
psql pos_dds < central_backup.sql

-- c) Restore full database
psql pos_dds < full_pos_backup.sql

-- 3. Security: Roles & Permissions

-- Create roles per city
-- Karachi users
CREATE ROLE karachi_user LOGIN PASSWORD 'pass123';
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA karachi TO karachi_user;

-- Lahore users
CREATE ROLE lahore_user LOGIN PASSWORD 'pass123';
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA lahore TO lahore_user;

-- Central read-only for cities
CREATE ROLE central_readonly LOGIN PASSWORD 'pass123';
GRANT SELECT ON ALL TABLES IN SCHEMA central TO central_readonly;

-- ================================================
-- 6. Performance Evaluation & Optimization
-- ================================================
-- 1. Indexes

-- Central

-- Cities
CREATE INDEX IF NOT EXISTS idx_cities_name ON central.Cities(name);

-- Stores
CREATE INDEX IF NOT EXISTS idx_stores_city_id ON central.Stores(city_id);
CREATE INDEX IF NOT EXISTS idx_stores_code ON central.Stores(code);

-- Categories
CREATE INDEX IF NOT EXISTS idx_categories_name ON central.Categories(name);

-- Users
CREATE INDEX IF NOT EXISTS idx_users_role_id ON central.Users(role_id);
CREATE INDEX IF NOT EXISTS idx_users_store_id ON central.Users(store_id);

-- Products
CREATE INDEX IF NOT EXISTS idx_products_category_id ON central.Products(category_id);
CREATE INDEX IF NOT EXISTS idx_products_sku ON central.Products(sku);

-- Inventory
CREATE INDEX IF NOT EXISTS idx_inventory_product_store ON central.Inventory(product_id, store_id);

-- Customers
CREATE INDEX IF NOT EXISTS idx_customers_city_id ON central.Customers(city_id);
CREATE INDEX IF NOT EXISTS idx_customers_phone ON central.Customers(phone);

-- Order_Mapping
CREATE UNIQUE INDEX IF NOT EXISTS idx_order_mapping_store_order ON central.Order_Mapping(store_id, store_order_id);

-- Orders
CREATE INDEX IF NOT EXISTS idx_orders_store_id ON central.Orders(store_id);
CREATE INDEX IF NOT EXISTS idx_orders_customer_id ON central.Orders(customer_id);
CREATE INDEX IF NOT EXISTS idx_orders_global_order_id ON central.Orders(global_order_id);
CREATE UNIQUE INDEX IF NOT EXISTS idx_orders_tracking_code ON central.Orders(tracking_code);

-- Order Items
CREATE INDEX IF NOT EXISTS idx_order_items_order_id ON central.Order_Items(order_id);
CREATE INDEX IF NOT EXISTS idx_order_items_product_id ON central.Order_Items(product_id);

-- Payments
CREATE INDEX IF NOT EXISTS idx_payments_global_order_id ON central.Payments(global_order_id);

-- Audit_Logs
CREATE INDEX IF NOT EXISTS idx_audit_logs_table_action ON central.Audit_Logs(table_name, action);
--------------------------------------------------------------------------
-- Karachi
CREATE INDEX idx_karachi_orders_store_id ON karachi.Orders(store_id);
CREATE INDEX idx_karachi_order_items_order_id ON karachi.Order_Items(order_id);
CREATE INDEX idx_karachi_inventory_product_store ON karachi.Inventory(product_id, store_id);

-- Lahore
CREATE INDEX idx_lahore_orders_store_id ON lahore.Orders(store_id);
CREATE INDEX idx_lahore_order_items_order_id ON lahore.Order_Items(order_id);
CREATE INDEX idx_lahore_inventory_product_store ON lahore.Inventory(product_id, store_id);

-- 2. Explain Query Plans

EXPLAIN ANALYZE
SELECT o.id, c.name
FROM karachi.Orders o
JOIN karachi.Customers c ON o.customer_id = c.id
WHERE o.store_id = 1;

-- 3. Distributed Query Optimization

-- Better approach for total sales per product
WITH karachi_sales AS (
  SELECT product_id, SUM(quantity*price) AS total_sales
  FROM karachi.Order_Items
  GROUP BY product_id
),
lahore_sales AS (
  SELECT product_id, SUM(quantity*price) AS total_sales
  FROM lahore.Order_Items
  GROUP BY product_id
)
SELECT p.id, p.name, COALESCE(k.total_sales,0) + COALESCE(l.total_sales,0) AS total_sales
FROM central.Products p
LEFT JOIN karachi_sales k ON p.id = k.product_id
LEFT JOIN lahore_sales l ON p.id = l.product_id;

-- 4. Monitoring / Performance Evaluation
SELECT * FROM pg_stat_statements ORDER BY total_exec_time DESC LIMIT 10;

--------------------------------------------------------------------------
DROP SCHEMA IF EXISTS public CASCADE;
-- ================================================
-- End of script
-- ================================================