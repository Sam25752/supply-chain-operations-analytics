-- create database SupplyChainAnalytics;
-- GO
-- USE SupplyChainAnalytics;
-- GO
SELECT DB_NAME() AS CurrentDatabase;

create table dbo.raw_orders
(
    order_id NVARCHAR(50) not NULL,
    customer_id NVARCHAR(50) NOT NULL,
    Order_status NVARCHAR(50) NOT NULL,
    order_purchase_timestamp DATETIME2 NULL,
    order_approved_at DATETIME2 NULL,
    order_delivered_carrier_date DATETIME2 NULL,
    order_delivered_customer_date DATETIME2 NULL,
    order_estimated_delivery_date DATETIME2 NULL
)

--create customers table

CREATE TABLE dbo.raw_customers
(
    customer_id NVARCHAR(50) NOT NULL,
    customer_unique_id NVARCHAR(50) NOT NULL,
    customer_zip_code_prefix INT NULL,
    customer_city NVARCHAR(100) NULL,
    customer_state NVARCHAR(10) NULL
);
GO

ALTER TABLE dbo.raw_customers
ALTER COLUMN customer_zip_code_prefix NVARCHAR(10) NULL;
GO

--create sellers table

CREATE TABLE dbo.raw_sellers
(
    seller_id NVARCHAR(50) NOT NULL,
    seller_zip_code_prefix INT NULL,
    seller_city NVARCHAR(100) NULL,
    seller_state NVARCHAR(10) NULL
);
GO

ALTER TABLE dbo.raw_sellers
ALTER COLUMN seller_zip_code_prefix NVARCHAR(20) NULL;
GO

ALTER TABLE dbo.raw_sellers
ALTER COLUMN seller_state NVARCHAR(100) NULL;
GO

--create products table

CREATE TABLE dbo.raw_products
(
    product_id NVARCHAR(50) NOT NULL,
    product_category_name NVARCHAR(100) NULL,
    product_name_lenght INT NULL,
    product_description_lenght INT NULL,
    product_photos_qty INT NULL,
    product_weight_g INT NULL,
    product_length_cm INT NULL,
    product_height_cm INT NULL,
    product_width_cm INT NULL
);
GO

--create order_items table

CREATE TABLE dbo.raw_order_items
(
    order_id NVARCHAR(50) NOT NULL,
    order_item_id INT NOT NULL,
    product_id NVARCHAR(50) NOT NULL,
    seller_id NVARCHAR(50) NOT NULL,
    shipping_limit_date DATETIME2 NULL,
    price DECIMAL(12,2) NULL,
    freight_value DECIMAL(12,2) NULL
);
GO

--create payments table

CREATE TABLE dbo.raw_order_payments
(
    order_id NVARCHAR(50) NOT NULL,
    payment_sequential INT NOT NULL,
    payment_type NVARCHAR(30) NULL,
    payment_installments INT NULL,
    payment_value DECIMAL(12,2) NULL
);
GO

--create reviews table

CREATE TABLE dbo.raw_order_reviews
(
    review_id NVARCHAR(MAX) NULL,
    order_id NVARCHAR(MAX) NULL,
    review_score NVARCHAR(MAX) NULL,
    review_comment_title NVARCHAR(MAX) NULL,
    review_comment_message NVARCHAR(MAX) NULL,
    review_creation_date NVARCHAR(MAX) NULL,
    review_answer_timestamp NVARCHAR(MAX) NULL
);
GO

--create geolocation table

CREATE TABLE dbo.raw_geolocation
(
    geolocation_zip_code_prefix INT NULL,
    geolocation_lat DECIMAL(10,7) NULL,
    geolocation_lng DECIMAL(10,7) NULL,
    geolocation_city NVARCHAR(100) NULL,
    geolocation_state NVARCHAR(10) NULL
);
GO
ALTER TABLE dbo.raw_geolocation
ALTER COLUMN geolocation_state NVARCHAR(100) NULL;
GO

ALTER TABLE dbo.raw_geolocation
ALTER COLUMN geolocation_zip_code_prefix NVARCHAR(10) NULL;
GO

--create category_translation table

CREATE TABLE dbo.raw_category_translation
(
    product_category_name NVARCHAR(100) NOT NULL,
    product_category_name_english NVARCHAR(100) NULL
);
GO

--checking the tables created in the database
SELECT
    TABLE_NAME
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'dbo'
ORDER BY TABLE_NAME;
