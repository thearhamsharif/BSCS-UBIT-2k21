-- File: query.sql
-- DB name: pos_dds
CREATE DATABASE pos_dds;
\c pos_dds;

-- ========================
-- 0. Extensions
-- ========================
CREATE EXTENSION IF NOT EXISTS dblink; -- for cross-db queries
CREATE EXTENSION IF NOT EXISTS pgcrypto; -- for gen_random_uuid()

-- ========================
-- 1. Schemas
-- ========================
CREATE SCHEMA IF NOT EXISTS central;
CREATE SCHEMA IF NOT EXISTS karachi;
CREATE SCHEMA IF NOT EXISTS lahore;

-- ========================
-- 2. CENTRAL TABLES (master)
-- ========================
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

-------------------------------------
DROP SCHEMA IF EXISTS public CASCADE;
-- ========================
-- End of script
-- ========================