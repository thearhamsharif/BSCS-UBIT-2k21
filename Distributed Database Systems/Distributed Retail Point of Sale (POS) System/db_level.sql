-- ==========================
-- 1. CENTRAL DATABASE
-- ==========================
CREATE DATABASE pos_central;
\c pos_central;

CREATE EXTENSION IF NOT EXISTS dblink;
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- --------------------------
-- Security / Roles
-- --------------------------
-- Full admin
CREATE ROLE central_admin LOGIN PASSWORD 'admin123';
GRANT ALL PRIVILEGES ON DATABASE pos_central TO central_admin;

-- Restricted dblink user
CREATE ROLE dblink_user LOGIN PASSWORD 'dblink123';
GRANT CONNECT ON DATABASE pos_central TO dblink_user;

-- Allow schema/table access for dblink_user
GRANT USAGE ON SCHEMA public TO dblink_user;
GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA public TO dblink_user;

-- --------------------------
-- Tables
-- --------------------------

-- Cities
CREATE TABLE Cities (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) UNIQUE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- Categories
CREATE TABLE Categories (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) UNIQUE NOT NULL,
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- Products
CREATE TABLE Products (
    id SERIAL PRIMARY KEY,
    sku VARCHAR(100) UNIQUE NOT NULL,
    name VARCHAR(150) NOT NULL,
    category_id INT NOT NULL REFERENCES Categories(id),
    price NUMERIC(12,2) NOT NULL CHECK(price >= 0),
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- Stores
CREATE TABLE Stores (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    code VARCHAR(50) UNIQUE NOT NULL,
    city_id INT NOT NULL REFERENCES Cities(id),
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- Customers
CREATE TABLE Customers (
    id SERIAL PRIMARY KEY,
    name VARCHAR(150) NOT NULL,
    phone VARCHAR(20),
    email VARCHAR(150),
    city_id INT NOT NULL REFERENCES Cities(id),
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- Order Mapping
CREATE TABLE Order_Mapping (
    id SERIAL PRIMARY KEY,
    global_order_id UUID UNIQUE DEFAULT gen_random_uuid(),
    store_id INT NOT NULL REFERENCES Stores(id),
    store_order_id INT NOT NULL,
    customer_id INT,
    order_time TIMESTAMPTZ DEFAULT now()
);

-- Replication Logging
CREATE TABLE IF NOT EXISTS Replication_Log (
    id SERIAL PRIMARY KEY,
    table_name VARCHAR(50),
    record_id INT,
    target_db VARCHAR(50),
    status VARCHAR(20),
    message TEXT,
    log_time TIMESTAMPTZ DEFAULT now()
);

-- ==========================
-- 2. STORE DATABASES
-- ==========================
CREATE DATABASE karachi_db;
CREATE DATABASE lahore_db;

-- --------------------------
-- Tables for store DBs (same for both)
-- --------------------------
\c karachi_db

CREATE TABLE Customers (
    id SERIAL PRIMARY KEY,
    name VARCHAR(150) NOT NULL,
    phone VARCHAR(20),
    email VARCHAR(150),
    city_id INT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE Stores (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    code VARCHAR(50) UNIQUE NOT NULL,
    city_id INT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE Orders (
    id SERIAL PRIMARY KEY,
    global_order_id UUID NOT NULL,
    store_id INT NOT NULL,
    customer_id INT NOT NULL,
    order_date TIMESTAMPTZ DEFAULT now(),
    total_amount NUMERIC(12,2) NOT NULL,
    status VARCHAR(50) DEFAULT 'Pending'
);

CREATE TABLE Order_Items (
    id SERIAL PRIMARY KEY,
    order_id INT NOT NULL REFERENCES Orders(id),
    product_id INT NOT NULL,
    quantity INT NOT NULL CHECK(quantity > 0),
    price NUMERIC(12,2) NOT NULL
);

CREATE TABLE Payments (
    id SERIAL PRIMARY KEY,
    global_order_id UUID NOT NULL,
    amount NUMERIC(12,2) NOT NULL,
    method VARCHAR(50) CHECK(method IN ('Cash','Card','Online')),
    status VARCHAR(50) DEFAULT 'Paid'
);

CREATE TABLE Inventory (
    id SERIAL PRIMARY KEY,
    product_id INT NOT NULL,
    store_id INT NOT NULL,
    quantity INT NOT NULL DEFAULT 0,
    purchase_price NUMERIC(12,2),
    updated_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(product_id, store_id)
);

\c lahore_db

CREATE TABLE Customers (
    id SERIAL PRIMARY KEY,
    name VARCHAR(150) NOT NULL,
    phone VARCHAR(20),
    email VARCHAR(150),
    city_id INT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE Stores (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    code VARCHAR(50) UNIQUE NOT NULL,
    city_id INT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE Orders (
    id SERIAL PRIMARY KEY,
    global_order_id UUID NOT NULL,
    store_id INT NOT NULL,
    customer_id INT NOT NULL,
    order_date TIMESTAMPTZ DEFAULT now(),
    total_amount NUMERIC(12,2) NOT NULL,
    status VARCHAR(50) DEFAULT 'Pending'
);

CREATE TABLE Order_Items (
    id SERIAL PRIMARY KEY,
    order_id INT NOT NULL REFERENCES Orders(id),
    product_id INT NOT NULL,
    quantity INT NOT NULL CHECK(quantity > 0),
    price NUMERIC(12,2) NOT NULL
);

CREATE TABLE Payments (
    id SERIAL PRIMARY KEY,
    global_order_id UUID NOT NULL,
    amount NUMERIC(12,2) NOT NULL,
    method VARCHAR(50) CHECK(method IN ('Cash','Card','Online')),
    status VARCHAR(50) DEFAULT 'Paid'
);

CREATE TABLE Inventory (
    id SERIAL PRIMARY KEY,
    product_id INT NOT NULL,
    store_id INT NOT NULL,
    quantity INT NOT NULL DEFAULT 0,
    purchase_price NUMERIC(12,2),
    updated_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(product_id, store_id)
);

-- ==========================
-- 3. REPLICATION TRIGGERS with Logging
-- ==========================
\c pos_central

-- Customers replication
CREATE OR REPLACE FUNCTION replicate_customers() RETURNS TRIGGER AS $$
DECLARE 
    db_name TEXT;
BEGIN
    IF NEW.city_id = (SELECT id FROM Cities WHERE name='Karachi') THEN
        db_name := 'karachi_db';
    ELSE
        db_name := 'lahore_db';
    END IF;

    BEGIN
        PERFORM dblink_exec(
            'dbname='||db_name||' user=dblink_user password=dblink123',
            'INSERT INTO Customers (id,name,phone,email,city_id,created_at,updated_at) VALUES ('||
            NEW.id||','''||NEW.name||''','''||COALESCE(NEW.phone,'')||''','''||COALESCE(NEW.email,'')||''','||
            NEW.city_id||','''||NEW.created_at||''','''||NEW.updated_at||''')'
        );
        INSERT INTO Replication_Log(table_name, record_id, target_db, status, message)
        VALUES ('Customers', NEW.id, db_name, 'Success', 'Replicated successfully');
    EXCEPTION WHEN OTHERS THEN
        INSERT INTO Replication_Log(table_name, record_id, target_db, status, message)
        VALUES ('Customers', NEW.id, db_name, 'Failed', SQLERRM);
    END;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_customers
AFTER INSERT OR UPDATE ON Customers
FOR EACH ROW EXECUTE FUNCTION replicate_customers();

-- Stores replication (similar)
CREATE OR REPLACE FUNCTION replicate_stores() RETURNS TRIGGER AS $$
DECLARE 
    db_name TEXT;
BEGIN
    IF NEW.city_id = (SELECT id FROM Cities WHERE name='Karachi') THEN
        db_name := 'karachi_db';
    ELSE
        db_name := 'lahore_db';
    END IF;

    BEGIN
        PERFORM dblink_exec(
            'dbname='||db_name||' user=dblink_user password=dblink123',
            'INSERT INTO Stores (id,name,code,city_id,created_at,updated_at) VALUES ('||
            NEW.id||','''||NEW.name||''','''||NEW.code||''','||NEW.city_id||','''||NEW.created_at||''','''||NEW.updated_at||''')'
        );
        INSERT INTO Replication_Log(table_name, record_id, target_db, status, message)
        VALUES ('Stores', NEW.id, db_name, 'Success', 'Replicated successfully');
    EXCEPTION WHEN OTHERS THEN
        INSERT INTO Replication_Log(table_name, record_id, target_db, status, message)
        VALUES ('Stores', NEW.id, db_name, 'Failed', SQLERRM);
    END;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_stores
AFTER INSERT OR UPDATE ON Stores
FOR EACH ROW EXECUTE FUNCTION replicate_stores();

-- ==========================
-- 4. Process Order Procedure with Concurrency Control
-- ==========================
CREATE OR REPLACE FUNCTION ProcessOrder(
    p_store_id INT,
    p_customer_id INT,
    p_items JSONB,
    p_payment_method VARCHAR,
    p_created_by INT
) RETURNS UUID AS $$
DECLARE
    v_global_order_id UUID := gen_random_uuid();
    v_total_amount NUMERIC := 0;
    v_item JSONB;
    v_order_id INT;
BEGIN
    -- Total calculation
    FOR v_item IN SELECT * FROM jsonb_array_elements(p_items)
    LOOP
        v_total_amount := v_total_amount + (v_item->>'quantity')::NUMERIC * (v_item->>'price')::NUMERIC;
    END LOOP;

    -- Insert Order Mapping
    INSERT INTO Order_Mapping(store_id, store_order_id, customer_id, global_order_id, order_time)
    VALUES (
        p_store_id,
        (SELECT COALESCE(MAX(store_order_id),0)+1 FROM Order_Mapping WHERE store_id=p_store_id),
        p_customer_id,
        v_global_order_id,
        now()
    );

    -- Insert Orders
    INSERT INTO Orders(global_order_id, store_id, customer_id, total_amount, status, order_date)
    VALUES (v_global_order_id, p_store_id, p_customer_id, v_total_amount, 'Pending', now());

    SELECT id INTO v_order_id FROM Orders WHERE global_order_id=v_global_order_id;

    -- Order Items + Inventory update with locks
    FOR v_item IN SELECT * FROM jsonb_array_elements(p_items)
    LOOP
        PERFORM * FROM Inventory
        WHERE product_id = (v_item->>'product_id')::INT AND store_id = p_store_id
        FOR UPDATE;

        INSERT INTO Order_Items(order_id, product_id, quantity, price)
        VALUES (v_order_id, (v_item->>'product_id')::INT, (v_item->>'quantity')::INT, (v_item->>'price')::NUMERIC);

        UPDATE Inventory
        SET quantity = quantity - (v_item->>'quantity')::INT,
            updated_at = now()
        WHERE product_id = (v_item->>'product_id')::INT AND store_id = p_store_id;
    END LOOP;

    -- Payment
    INSERT INTO Payments(global_order_id, amount, method, status)
    VALUES (v_global_order_id, v_total_amount, p_payment_method, 'Paid');

    RETURN v_global_order_id;
END;
$$ LANGUAGE plpgsql;

-- ==========================
-- 5. Distributed Query (Sales total)
-- ==========================
WITH karachi_sales AS (
    SELECT SUM(quantity*price) AS total
    FROM dblink('dbname=karachi_db user=dblink_user password=dblink123',
                'SELECT quantity, price FROM Order_Items') AS t(quantity INT, price NUMERIC)
),
lahore_sales AS (
    SELECT SUM(quantity*price) AS total
    FROM dblink('dbname=lahore_db user=dblink_user password=dblink123',
                'SELECT quantity, price FROM Order_Items') AS t(quantity INT, price NUMERIC)
)
SELECT COALESCE(k.total,0)+COALESCE(l.total,0) AS total_sales
FROM karachi_sales k, lahore_sales l;

-- ==========================
-- 6. Backup / Recovery Examples
-- ==========================
-- Backup central DB
-- \! pg_dump -U central_admin -F c -b -v -f '/path/to/backup/pos_central.backup' pos_central

-- Restore central DB
-- \! pg_restore -U central_admin -d pos_central -v '/path/to/backup/pos_central.backup'

-- Backup store DBs
-- \! pg_dump -U central_admin -F c -b -v -f '/path/to/backup/karachi_db.backup' karachi_db
-- \! pg_dump -U central_admin -F c -b -v -f '/path/to/backup/lahore_db.backup' lahore_db

-- Restore store DBs
-- \! pg_restore -U central_admin -d karachi_db -v '/path/to/backup/karachi_db.backup'
-- \! pg_restore -U central_admin -d lahore_db -v '/path/to/backup/lahore_db.backup'

-- ==========================
-- 7. Results / Testing placeholders
-- ==========================
-- SELECT * FROM Customers;
-- SELECT * FROM Stores;
-- SELECT * FROM Order_Mapping;
-- SELECT * FROM Replication_Log;
-- Use EXPLAIN ANALYZE on distributed query for optimization screenshots
-- EX: EXPLAIN ANALYZE
-- WITH karachi_sales AS (...)
-- SELECT COALESCE(k.total,0)+COALESCE(l.total,0) AS total_sales
-- FROM karachi_sales k, lahore_sales l;