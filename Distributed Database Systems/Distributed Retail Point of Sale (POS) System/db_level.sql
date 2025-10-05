-- ==================================================
-- 1. CENTRAL DATABASE
-- ==================================================
CREATE DATABASE pos_central;
\c pos_central;

-- Extensions
CREATE EXTENSION IF NOT EXISTS dblink;
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ------------------
-- Cities
-- ------------------
CREATE TABLE Cities (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) UNIQUE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- ------------------
-- Categories
-- ------------------
CREATE TABLE Categories (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) UNIQUE NOT NULL,
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- ------------------
-- Products
-- ------------------
CREATE TABLE Products (
    id SERIAL PRIMARY KEY,
    sku VARCHAR(100) UNIQUE NOT NULL,
    name VARCHAR(150) NOT NULL,
    category_id INT NOT NULL REFERENCES Categories(id),
    price NUMERIC(12,2) NOT NULL CHECK(price >= 0),
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- ------------------
-- Stores
-- ------------------
CREATE TABLE Stores (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    code VARCHAR(50) UNIQUE NOT NULL,
    city_id INT NOT NULL REFERENCES Cities(id),
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- ------------------
-- Order Mapping
-- ------------------
CREATE TABLE Order_Mapping (
    id SERIAL PRIMARY KEY,
    global_order_id UUID UNIQUE DEFAULT gen_random_uuid(),
    store_id INT NOT NULL REFERENCES Stores(id),
    store_order_id INT NOT NULL,
    customer_id INT,
    order_time TIMESTAMPTZ DEFAULT now()
);

-- ==================================================
-- 2. STORE DATABASES
-- ==================================================
CREATE DATABASE karachi_db;
CREATE DATABASE lahore_db;

-- ------------------
-- Karachi DB
-- ------------------
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
    UNIQUE(product_id, store_id)
);

-- ------------------
-- Lahore DB (same as Karachi)
-- ------------------
\c lahore_db

-- ==================================================
-- 3. REPLICATION TRIGGERS (central -> stores)
-- ==================================================
\c pos_central

-- ------------------
-- Customers
-- ------------------
CREATE OR REPLACE FUNCTION replicate_customers_db() RETURNS TRIGGER AS $$
DECLARE
    db_name TEXT;
BEGIN
    IF NEW.city_id = (SELECT id FROM Cities WHERE name='Karachi') THEN
        db_name := 'karachi_db';
    ELSE
        db_name := 'lahore_db';
    END IF;

    PERFORM dblink_exec(
        'dbname='||db_name||' user=root password=root',
        'INSERT INTO Customers (id,name,phone,email,city_id,created_at,updated_at) VALUES ('||
        NEW.id||','''||NEW.name||''','''||COALESCE(NEW.phone,'')||''','''||COALESCE(NEW.email,'')||''','||
        NEW.city_id||','''||NEW.created_at||''','''||NEW.updated_at||''')'
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_customers_db
AFTER INSERT OR UPDATE ON Customers
FOR EACH ROW EXECUTE FUNCTION replicate_customers_db();

-- ------------------
-- Stores
-- ------------------
CREATE OR REPLACE FUNCTION replicate_stores_db() RETURNS TRIGGER AS $$
DECLARE db_name TEXT;
BEGIN
    IF NEW.city_id = (SELECT id FROM Cities WHERE name='Karachi') THEN
        db_name := 'karachi_db';
    ELSE
        db_name := 'lahore_db';
    END IF;

    PERFORM dblink_exec(
        'dbname='||db_name||' user=root password=root',
        'INSERT INTO Stores (id,name,code,city_id,created_at,updated_at) VALUES ('||
        NEW.id||','''||NEW.name||''','''||NEW.code||''','||NEW.city_id||','''||NEW.created_at||''','''||NEW.updated_at||''')'
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_stores_db
AFTER INSERT OR UPDATE ON Stores
FOR EACH ROW EXECUTE FUNCTION replicate_stores_db();

-- ------------------
-- Orders
-- ------------------
CREATE OR REPLACE FUNCTION replicate_orders_db() RETURNS TRIGGER AS $$
DECLARE db_name TEXT;
BEGIN
    SELECT CASE c.name WHEN 'Karachi' THEN 'karachi_db' ELSE 'lahore_db' END INTO db_name
    FROM Stores s JOIN Cities c ON s.city_id=c.id WHERE s.id=NEW.store_id;

    PERFORM dblink_exec(
        'dbname='||db_name||' user=root password=root',
        'INSERT INTO Orders (id,global_order_id,store_id,customer_id,order_date,total_amount,status) VALUES ('||
        NEW.id||','''||NEW.global_order_id||''','||NEW.store_id||','||NEW.customer_id||','''||
        NEW.order_date||''','||NEW.total_amount||','''||NEW.status||''')'
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_orders_db
AFTER INSERT OR UPDATE ON Orders
FOR EACH ROW EXECUTE FUNCTION replicate_orders_db();

-- ------------------
-- Order_Items
-- ------------------
CREATE OR REPLACE FUNCTION replicate_order_items_db() RETURNS TRIGGER AS $$
DECLARE db_name TEXT;
BEGIN
    SELECT CASE c.name WHEN 'Karachi' THEN 'karachi_db' ELSE 'lahore_db' END INTO db_name
    FROM Orders o JOIN Stores s ON o.store_id=s.id JOIN Cities c ON s.city_id=c.id WHERE o.id=NEW.order_id;

    PERFORM dblink_exec(
        'dbname='||db_name||' user=root password=root',
        'INSERT INTO Order_Items (id,order_id,product_id,quantity,price) VALUES ('||
        NEW.id||','||NEW.order_id||','||NEW.product_id||','||NEW.quantity||','||NEW.price||')'
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_order_items_db
AFTER INSERT OR UPDATE ON Order_Items
FOR EACH ROW EXECUTE FUNCTION replicate_order_items_db();

-- ------------------
-- Payments
-- ------------------
CREATE OR REPLACE FUNCTION replicate_payments_db() RETURNS TRIGGER AS $$
DECLARE db_name TEXT;
BEGIN
    SELECT CASE c.name WHEN 'Karachi' THEN 'karachi_db' ELSE 'lahore_db' END INTO db_name
    FROM Order_Mapping om JOIN Stores s ON om.store_id=s.id JOIN Cities c ON s.city_id=c.id
    WHERE om.global_order_id=NEW.global_order_id;

    PERFORM dblink_exec(
        'dbname='||db_name||' user=root password=root',
        'INSERT INTO Payments (id,global_order_id,amount,method,status) VALUES ('||
        NEW.id||','''||NEW.global_order_id||''','||NEW.amount||','''||NEW.method||''','''||NEW.status||''')'
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_payments_db
AFTER INSERT OR UPDATE ON Payments
FOR EACH ROW EXECUTE FUNCTION replicate_payments_db();

-- ------------------
-- Inventory
-- ------------------
CREATE OR REPLACE FUNCTION replicate_inventory_db() RETURNS TRIGGER AS $$
DECLARE db_name TEXT;
BEGIN
    SELECT CASE c.name WHEN 'Karachi' THEN 'karachi_db' ELSE 'lahore_db' END INTO db_name
    FROM Stores s JOIN Cities c ON s.city_id=c.id WHERE s.id=NEW.store_id;

    PERFORM dblink_exec(
        'dbname='||db_name||' user=root password=root',
        'INSERT INTO Inventory (id,product_id,store_id,quantity,purchase_price) VALUES ('||
        NEW.id||','||NEW.product_id||','||NEW.store_id||','||NEW.quantity||','||COALESCE(NEW.purchase_price,0)||')'
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_inventory_db
AFTER INSERT OR UPDATE ON Inventory
FOR EACH ROW EXECUTE FUNCTION replicate_inventory_db();

-- ==================================================
-- 4. SAMPLE DISTRIBUTED QUERY
-- ==================================================
WITH karachi_sales AS (
    SELECT SUM(quantity*price) AS total
    FROM dblink('dbname=karachi_db user=root password=root',
                'SELECT quantity, price FROM Order_Items') AS t(quantity INT, price NUMERIC)
),
lahore_sales AS (
    SELECT SUM(quantity*price) AS total
    FROM dblink('dbname=lahore_db user=root password=root',
                'SELECT quantity, price FROM Order_Items') AS t(quantity INT, price NUMERIC)
)
SELECT COALESCE(k.total,0)+COALESCE(l.total,0) AS total_sales
FROM karachi_sales k, lahore_sales l;

\c pos_central

CREATE OR REPLACE FUNCTION ProcessOrder(
    p_store_id INT,
    p_customer_id INT,
    p_items JSONB,       -- [{"product_id":1,"quantity":2,"price":100}, ...]
    p_payment_method VARCHAR,
    p_created_by INT
) RETURNS UUID AS $$
DECLARE
    v_global_order_id UUID := gen_random_uuid();
    v_total_amount NUMERIC := 0;
    v_item JSONB;
    v_order_id INT;
BEGIN
    -- Calculate total
    FOR v_item IN SELECT * FROM jsonb_array_elements(p_items)
    LOOP
        v_total_amount := v_total_amount + (v_item->>'quantity')::NUMERIC * (v_item->>'price')::NUMERIC;
    END LOOP;

    -- Insert into Order_Mapping
    INSERT INTO Order_Mapping(store_id, store_order_id, customer_id, global_order_id, created_by, updated_by)
    VALUES (
        p_store_id,
        (SELECT COALESCE(MAX(store_order_id),0)+1 FROM Order_Mapping WHERE store_id=p_store_id),
        p_customer_id,
        v_global_order_id,
        p_created_by,
        p_created_by
    );

    -- Insert into Orders
    INSERT INTO Orders(global_order_id, store_id, customer_id, total_amount, status, created_at, updated_at)
    VALUES (v_global_order_id, p_store_id, p_customer_id, v_total_amount, 'Pending', now(), now());

    -- Get inserted order_id
    SELECT id INTO v_order_id FROM Orders WHERE global_order_id=v_global_order_id;

    -- Insert into Order_Items & update Inventory
    FOR v_item IN SELECT * FROM jsonb_array_elements(p_items)
    LOOP
        INSERT INTO Order_Items(order_id, product_id, quantity, price)
        VALUES (
            v_order_id,
            (v_item->>'product_id')::INT,
            (v_item->>'quantity')::INT,
            (v_item->>'price')::NUMERIC
        );

        -- Deduct inventory
        UPDATE Inventory
        SET quantity = quantity - (v_item->>'quantity')::INT,
            updated_at = now()
        WHERE product_id = (v_item->>'product_id')::INT AND store_id = p_store_id;
    END LOOP;

    -- Insert into Payments
    INSERT INTO Payments(global_order_id, amount, method, status)
    VALUES (v_global_order_id, v_total_amount, p_payment_method, 'Paid');

    RETURN v_global_order_id;
END;
$$ LANGUAGE plpgsql;

-- =========================
-- Test the procedure
-- =========================
SELECT ProcessOrder(
    1,  -- store_id
    10, -- customer_id
    '[{"product_id":1,"quantity":2,"price":100},{"product_id":2,"quantity":1,"price":200}]'::jsonb,
    'Card',
    1   -- created_by
);
