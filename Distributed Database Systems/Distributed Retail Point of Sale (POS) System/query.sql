-- ==================================================
-- DATABASE: pos_dds (Distributed Retail POS)
-- ==================================================

-- Create database
CREATE DATABASE pos_dds;
\c pos_dds;

-- ==================================================
-- 0. Extensions
-- ==================================================
CREATE EXTENSION IF NOT EXISTS dblink; -- for connection
CREATE EXTENSION IF NOT EXISTS pgcrypto; -- for unique_id or security
CREATE EXTENSION IF NOT EXISTS pg_stat_statements; -- for monitoring

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
CREATE TABLE karachi.Customers AS SELECT * FROM central.Customers WHERE city_id=(SELECT id FROM central.Cities WHERE name='Karachi');
CREATE TABLE lahore.Customers AS SELECT * FROM central.Customers WHERE city_id=(SELECT id FROM central.Cities WHERE name='Lahore');

CREATE TABLE karachi.Orders AS SELECT o.* FROM central.Orders o JOIN central.Stores s ON o.store_id=s.id WHERE s.city_id=(SELECT id FROM central.Cities WHERE name='Karachi');
CREATE TABLE lahore.Orders AS SELECT o.* FROM central.Orders o JOIN central.Stores s ON o.store_id=s.id WHERE s.city_id=(SELECT id FROM central.Cities WHERE name='Lahore');

CREATE TABLE karachi.Order_Items AS SELECT oi.* FROM central.Order_Items oi JOIN central.Orders o ON oi.order_id=o.id JOIN central.Stores s ON o.store_id=s.id WHERE s.city_id=(SELECT id FROM central.Cities WHERE name='Karachi');
CREATE TABLE lahore.Order_Items AS SELECT oi.* FROM central.Order_Items oi JOIN central.Orders o ON oi.order_id=o.id JOIN central.Stores s ON o.store_id=s.id WHERE s.city_id=(SELECT id FROM central.Cities WHERE name='Lahore');

CREATE TABLE karachi.Payments AS SELECT p.* FROM central.Payments p JOIN central.Order_Mapping om ON p.global_order_id=om.global_order_id JOIN central.Stores s ON om.store_id=s.id WHERE s.city_id=(SELECT id FROM central.Cities WHERE name='Karachi');
CREATE TABLE lahore.Payments AS SELECT p.* FROM central.Payments p JOIN central.Order_Mapping om ON p.global_order_id=om.global_order_id JOIN central.Stores s ON om.store_id=s.id WHERE s.city_id=(SELECT id FROM central.Cities WHERE name='Lahore');

CREATE TABLE karachi.Inventory AS SELECT i.* FROM central.Inventory i JOIN central.Stores s ON i.store_id=s.id WHERE s.city_id=(SELECT id FROM central.Cities WHERE name='Karachi');
CREATE TABLE lahore.Inventory AS SELECT i.* FROM central.Inventory i JOIN central.Stores s ON i.store_id=s.id WHERE s.city_id=(SELECT id FROM central.Cities WHERE name='Lahore');

-- ==================================================
-- 4. FULL REPLICATION TRIGGERS (ALL TABLES)
-- ==================================================
-- Template for triggers: Stores, Products, Categories, Roles, Suppliers, Orders, Order_Items, Payments, Inventory
-- Triggers for central.Stores
CREATE OR REPLACE FUNCTION replicate_store(city TEXT) RETURNS TRIGGER AS $$
BEGIN
  IF NEW.city_id=(SELECT id FROM central.Cities WHERE name=city) THEN
    IF city='Karachi' THEN
      INSERT INTO karachi.Stores VALUES (NEW.*)
      ON CONFLICT (id) DO UPDATE SET name=EXCLUDED.name, code=EXCLUDED.code, updated_at=EXCLUDED.updated_at;
    ELSE
      INSERT INTO lahore.Stores VALUES (NEW.*)
      ON CONFLICT (id) DO UPDATE SET name=EXCLUDED.name, code=EXCLUDED.code, updated_at=EXCLUDED.updated_at;
    END IF;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_store_insert AFTER INSERT OR UPDATE ON central.Stores
FOR EACH ROW EXECUTE FUNCTION replicate_store(NEW.city_id);

-- Replication triggers for Products
CREATE OR REPLACE FUNCTION replicate_product() RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO karachi.Products VALUES (NEW.*)
  ON CONFLICT (id) DO UPDATE SET name=EXCLUDED.name, price=EXCLUDED.price, category_id=EXCLUDED.category_id, updated_at=EXCLUDED.updated_at;
  
  INSERT INTO lahore.Products VALUES (NEW.*)
  ON CONFLICT (id) DO UPDATE SET name=EXCLUDED.name, price=EXCLUDED.price, category_id=EXCLUDED.category_id, updated_at=EXCLUDED.updated_at;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_product_insert AFTER INSERT OR UPDATE ON central.Products
FOR EACH ROW EXECUTE FUNCTION replicate_product();

-- Replication triggers for Categories
CREATE OR REPLACE FUNCTION replicate_category() RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO karachi.Categories VALUES (NEW.*)
  ON CONFLICT (id) DO UPDATE SET name=EXCLUDED.name, description=EXCLUDED.description, updated_at=EXCLUDED.updated_at;
  
  INSERT INTO lahore.Categories VALUES (NEW.*)
  ON CONFLICT (id) DO UPDATE SET name=EXCLUDED.name, description=EXCLUDED.description, updated_at=EXCLUDED.updated_at;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_category_insert AFTER INSERT OR UPDATE ON central.Categories
FOR EACH ROW EXECUTE FUNCTION replicate_category();

-- Replication triggers for Roles
CREATE OR REPLACE FUNCTION replicate_role() RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO karachi.Roles VALUES (NEW.*)
  ON CONFLICT (id) DO UPDATE SET role_name=EXCLUDED.role_name, description=EXCLUDED.description, updated_at=EXCLUDED.updated_at;

  INSERT INTO lahore.Roles VALUES (NEW.*)
  ON CONFLICT (id) DO UPDATE SET role_name=EXCLUDED.role_name, description=EXCLUDED.description, updated_at=EXCLUDED.updated_at;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_role_insert AFTER INSERT OR UPDATE ON central.Roles
FOR EACH ROW EXECUTE FUNCTION replicate_role();

-- Replication triggers for Suppliers
CREATE OR REPLACE FUNCTION replicate_supplier() RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO karachi.Suppliers VALUES (NEW.*)
  ON CONFLICT (id) DO UPDATE SET name=EXCLUDED.name, contact_info=EXCLUDED.contact_info, updated_at=EXCLUDED.updated_at;

  INSERT INTO lahore.Suppliers VALUES (NEW.*)
  ON CONFLICT (id) DO UPDATE SET name=EXCLUDED.name, contact_info=EXCLUDED.contact_info, updated_at=EXCLUDED.updated_at;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_supplier_insert AFTER INSERT OR UPDATE ON central.Suppliers
FOR EACH ROW EXECUTE FUNCTION replicate_supplier();

-- Replication triggers for Orders
CREATE OR REPLACE FUNCTION replicate_orders() RETURNS TRIGGER AS $$
BEGIN
  IF (SELECT city_id FROM central.Stores WHERE id=NEW.store_id)=(SELECT id FROM central.Cities WHERE name='Karachi') THEN
    INSERT INTO karachi.Orders VALUES (NEW.*)
    ON CONFLICT (id) DO UPDATE SET updated_at=EXCLUDED.updated_at, total_amount=EXCLUDED.total_amount;
  ELSE
    INSERT INTO lahore.Orders VALUES (NEW.*)
    ON CONFLICT (id) DO UPDATE SET updated_at=EXCLUDED.updated_at, total_amount=EXCLUDED.total_amount;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_orders_insert AFTER INSERT OR UPDATE ON central.Orders
FOR EACH ROW EXECUTE FUNCTION replicate_orders();

-- Replication triggers for Order_Items
CREATE OR REPLACE FUNCTION replicate_order_items() RETURNS TRIGGER AS $$
BEGIN
  IF (SELECT city_id FROM central.Stores WHERE id=(SELECT store_id FROM central.Orders WHERE id=NEW.order_id))=(SELECT id FROM central.Cities WHERE name='Karachi') THEN
    INSERT INTO karachi.Order_Items VALUES (NEW.*)
    ON CONFLICT (id) DO UPDATE SET quantity=EXCLUDED.quantity, price=EXCLUDED.price, updated_at=EXCLUDED.updated_at;
  ELSE
    INSERT INTO lahore.Order_Items VALUES (NEW.*)
    ON CONFLICT (id) DO UPDATE SET quantity=EXCLUDED.quantity, price=EXCLUDED.price, updated_at=EXCLUDED.updated_at;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_order_items_insert AFTER INSERT OR UPDATE ON central.Order_Items
FOR EACH ROW EXECUTE FUNCTION replicate_order_items();

-- Replication triggers for Payments
CREATE OR REPLACE FUNCTION replicate_payments() RETURNS TRIGGER AS $$
BEGIN
  IF (SELECT city_id FROM central.Stores WHERE id=(SELECT store_id FROM central.Order_Mapping WHERE global_order_id=NEW.global_order_id))=(SELECT id FROM central.Cities WHERE name='Karachi') THEN
    INSERT INTO karachi.Payments VALUES (NEW.*)
    ON CONFLICT (id) DO UPDATE SET amount=EXCLUDED.amount, status=EXCLUDED.status, updated_at=EXCLUDED.updated_at;
  ELSE
    INSERT INTO lahore.Payments VALUES (NEW.*)
    ON CONFLICT (id) DO UPDATE SET amount=EXCLUDED.amount, status=EXCLUDED.status, updated_at=EXCLUDED.updated_at;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_payments_insert AFTER INSERT OR UPDATE ON central.Payments
FOR EACH ROW EXECUTE FUNCTION replicate_payments();

-- Replication triggers for Inventory
CREATE OR REPLACE FUNCTION replicate_inventory() RETURNS TRIGGER AS $$
BEGIN
  IF (SELECT city_id FROM central.Stores WHERE id=NEW.store_id)=(SELECT id FROM central.Cities WHERE name='Karachi') THEN
    INSERT INTO karachi.Inventory VALUES (NEW.*)
    ON CONFLICT (id) DO UPDATE SET quantity=EXCLUDED.quantity, purchase_price=EXCLUDED.purchase_price, updated_at=EXCLUDED.updated_at;
  ELSE
    INSERT INTO lahore.Inventory VALUES (NEW.*)
    ON CONFLICT (id) DO UPDATE SET quantity=EXCLUDED.quantity, purchase_price=EXCLUDED.purchase_price, updated_at=EXCLUDED.updated_at;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_inventory_insert AFTER INSERT OR UPDATE ON central.Inventory
FOR EACH ROW EXECUTE FUNCTION replicate_inventory();

-- ==================================================
-- 5. INDEXES (Central + Nodes)
-- ==================================================
-- Central Indexes
CREATE INDEX IF NOT EXISTS idx_cities_name ON central.Cities(name);
CREATE INDEX IF NOT EXISTS idx_stores_city_id ON central.Stores(city_id);
CREATE INDEX IF NOT EXISTS idx_products_sku ON central.Products(sku);
CREATE INDEX IF NOT EXISTS idx_inventory_product_store ON central.Inventory(product_id, store_id);
CREATE INDEX IF NOT EXISTS idx_orders_store_id ON central.Orders(store_id);
CREATE INDEX IF NOT EXISTS idx_order_items_order_id ON central.Order_Items(order_id);

-- Karachi Indexes
CREATE INDEX IF NOT EXISTS idx_karachi_orders_store_id ON karachi.Orders(store_id);
CREATE INDEX IF NOT EXISTS idx_karachi_order_items_order_id ON karachi.Order_Items(order_id);
CREATE INDEX IF NOT EXISTS idx_karachi_inventory_product_store ON karachi.Inventory(product_id, store_id);

-- Lahore Indexes
CREATE INDEX IF NOT EXISTS idx_lahore_orders_store_id ON lahore.Orders(store_id);
CREATE INDEX IF NOT EXISTS idx_lahore_order_items_order_id ON lahore.Order_Items(order_id);
CREATE INDEX IF NOT EXISTS idx_lahore_inventory_product_store ON lahore.Inventory(product_id, store_id);

-- ==================================================
-- 6. SECURITY: Roles & Permissions
-- ==================================================
CREATE ROLE karachi_user LOGIN PASSWORD 'pass123';
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA karachi TO karachi_user;

CREATE ROLE lahore_user LOGIN PASSWORD 'pass123';
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA lahore TO lahore_user;

CREATE ROLE central_readonly LOGIN PASSWORD 'pass123';
GRANT SELECT ON ALL TABLES IN SCHEMA central TO central_readonly;

-- ==================================================
-- 7. BACKUP / RESTORE
-- ==================================================
-- Backup city-specific
-- pg_dump -n karachi pos_dds > karachi_backup.sql
-- pg_dump -n lahore pos_dds > lahore_backup.sql
-- pg_dump -n central pos_dds > central_backup.sql
-- Restore
-- psql pos_dds < karachi_backup.sql

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
-- END OF SCRIPT
-- ==================================================
