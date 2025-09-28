-- File: query.sql
-- DB name: pos_dds

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
  store_code VARCHAR(150) -- 'Karachi' or 'Lahore' or NULL (Main)
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
  category VARCHAR(100),
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
  store_code VARCHAR(150) NOT NULL, -- 'Karachi' or 'Lahore'
  quantity INT NOT NULL DEFAULT 0 CHECK (quantity >= 0),
  purchase_price NUMERIC(12,2),
  UNIQUE(product_id, store_code)
);

-- Customers
CREATE TABLE IF NOT EXISTS central.Customers (
  id SERIAL PRIMARY KEY,
  city VARCHAR(50) CHECK (city IN ('Karachi','Lahore')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  created_by INT,
  updated_by INT,
  name VARCHAR(150) NOT NULL,
  phone VARCHAR(20),
  email VARCHAR(150)
);

-- Payments
CREATE TABLE IF NOT EXISTS central.Payments (
  id SERIAL PRIMARY KEY,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  created_by INT,
  updated_by INT,
  global_order_id UUID,
  amount NUMERIC(12,2) NOT NULL,
  method VARCHAR(50) CHECK (method IN ('Cash','Card','Online')),
  status VARCHAR(50) DEFAULT 'Paid'
);

-- OrderMapping
CREATE TABLE IF NOT EXISTS central.OrderMapping (
  global_order_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  store_code TEXT NOT NULL,
  store_order_id INT NOT NULL,
  customer_id INT,
  order_time TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  created_by INT
);

-- AuditLogs
CREATE TABLE IF NOT EXISTS central.AuditLogs (
  id SERIAL PRIMARY KEY,
  created_by INT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  table_name TEXT NOT NULL,
  action TEXT NOT NULL,
  payload JSONB
);

-- ========================
-- End of script
-- ========================