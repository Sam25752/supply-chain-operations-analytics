
--====================================================================
--retrieve the metadeta information of the raw tables in the database
--====================================================================
SELECT
    TABLE_NAME,
    COLUMN_NAME,
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH,
    IS_NULLABLE,
    ORDINAL_POSITION
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'dbo'
  AND TABLE_NAME LIKE 'raw_%'
ORDER BY
    TABLE_NAME,
    ORDINAL_POSITION;


--==========================================
--checking the number of rows in each table
--==========================================

SELECT 'raw_orders' AS table_name, COUNT(*) AS row_count
FROM dbo.raw_orders

UNION ALL

SELECT 'raw_customers', COUNT(*)
FROM dbo.raw_customers

UNION ALL

SELECT 'raw_sellers', COUNT(*)
FROM dbo.raw_sellers

UNION ALL

SELECT 'raw_products', COUNT(*)
FROM dbo.raw_products

UNION ALL

SELECT 'raw_order_items', COUNT(*)
FROM dbo.raw_order_items

UNION ALL

SELECT 'raw_order_payments', COUNT(*)
FROM dbo.raw_order_payments

UNION ALL

SELECT 'raw_order_reviews', COUNT(*)
FROM dbo.raw_order_reviews

UNION ALL

SELECT 'raw_geolocation', COUNT(*)
FROM dbo.raw_geolocation

UNION ALL

SELECT 'raw_category_translation', COUNT(*)
FROM dbo.raw_category_translation

ORDER BY table_name;


--get the table grain 

--if total rows = unique orders, then the table grain is at order level

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT order_id) AS unique_orders
FROM dbo.raw_orders;


--if total_rows = unique customers, then the table grain is at customer level

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT customer_id) AS unique_customers
FROM dbo.raw_customers;


--if total_rows = unique sellers, then the table grain is at seller level

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT seller_id) AS unique_sellers
FROM dbo.raw_sellers;



--if total_rows = unique products, then the table grain is at product level

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT product_id) AS unique_products
FROM dbo.raw_products;



--if total_rows>unique_orders then an order contains multiple order item (orderid+order_item_id)

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT order_id) AS unique_orders,
    COUNT(DISTINCT CONCAT(order_id, '-', order_item_id)) AS unique_order_items
FROM dbo.raw_order_items;


SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT order_id) AS unique_orders
FROM dbo.raw_order_payments;
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT review_id) AS unique_reviews,
    COUNT(DISTINCT order_id) AS unique_orders
FROM dbo.raw_order_reviews;
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT product_category_name) AS unique_portuguese_categories,
    COUNT(DISTINCT product_category_name_english) AS unique_english_categories
FROM dbo.raw_category_translation;