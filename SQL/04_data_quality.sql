/*
=========================================
DATA QUALITY CONCLUSION
=========================================

1. Duplicate primary-key checks:
   - Orders: No duplicates
   - Customers: No duplicates
   - Sellers: No duplicates
   - Products: No duplicates
   - Order-item combinations: No duplicates
   - Payment sequential records: No duplicates

2. Review grain:
   Review data is at review_id + order_id level.
   Multiple review records can exist for an order.
   Reviews must therefore be aggregated before joining
   to the order-level analytical table.

3. Missing values:
   - Order timestamps contain legitimate NULLs for
     non-delivered/cancelled orders.
   - Product category contains NULL values.
   - Some product physical attributes contain NULLs.

4. Referential integrity:
   Major order, customer, product, seller and payment
   relationships were validated.

5. Timestamp anomalies:
   Some operational timestamps violate expected chronology.
   These records will not be modified in the raw layer.
   Appropriate exclusions/flags will be applied in analytical
   calculations.

6. Source ingestion:
   CSV quote handling caused an initial order_id formatting
   issue during ingestion. The orders table was reloaded
   using CSV-aware parsing and validated afterward.

Raw tables will remain unchanged.
Cleaning and business-rule handling will occur in the
analytical layer.
*/


--checking duplicate order_id in raw_orders table
select order_id
from dbo.raw_orders
group by order_id
having count(*)>1


--checking duplicate customer_id in raw_customers table

select customer_id
from dbo.raw_customers
group by customer_id
having count(*)>1


-- 3. Duplicate seller IDs

SELECT
    seller_id,
    COUNT(*) AS occurrence_count
FROM dbo.raw_sellers
GROUP BY seller_id
HAVING COUNT(*) > 1;

-- 4. Duplicate product IDs

SELECT
    product_id,
    COUNT(*) AS occurrence_count
FROM dbo.raw_products
GROUP BY product_id
HAVING COUNT(*) > 1;


-- 5. Duplicate order-item combinations

SELECT
    order_id,
    order_item_id,
    COUNT(*) AS occurrence_count
FROM dbo.raw_order_items
GROUP BY
    order_id,
    order_item_id
HAVING COUNT(*) > 1;


-- 6. Duplicate payment records

SELECT
    order_id,
    payment_sequential,
    COUNT(*) AS occurrence_count
FROM dbo.raw_order_payments
GROUP BY
    order_id,
    payment_sequential
HAVING COUNT(*) > 1;


-- 7. Duplicate review IDs

SELECT
    review_id,
    COUNT(*) AS occurrence_count
FROM dbo.raw_order_reviews
GROUP BY review_id
HAVING COUNT(*) > 1;

SELECT
    review_id,
    COUNT(*) AS review_count,
    COUNT(DISTINCT order_id) AS order_count
FROM dbo.raw_order_reviews
GROUP BY review_id
HAVING COUNT(*) > 1
ORDER BY review_count DESC;


-- 8. Duplicate category translations

SELECT
    product_category_name,
    COUNT(*) AS occurrence_count
FROM dbo.raw_category_translation
GROUP BY product_category_name
HAVING COUNT(*) > 1;



--==========================================
--CHECKING FOR NULLS
--==========================================

-- checking in raw_orders table
SELECT
    COUNT(*) AS total_orders,  --99441

    SUM(CASE WHEN order_id IS NULL THEN 1 ELSE 0 END) AS missing_order_id,    --NO NULLS

    SUM(CASE WHEN customer_id IS NULL THEN 1 ELSE 0 END) AS missing_customer_id,  --NO NULLS

    SUM(CASE WHEN order_status IS NULL THEN 1 ELSE 0 END) AS missing_order_status,   --NO NULLS

    SUM(CASE WHEN order_purchase_timestamp IS NULL THEN 1 ELSE 0 END) AS missing_purchase_timestamp,   ---NO NULLS

    SUM(CASE WHEN order_approved_at IS NULL THEN 1 ELSE 0 END) AS missing_approval_timestamp,  --160 NULLS

    SUM(CASE WHEN order_delivered_carrier_date IS NULL THEN 1 ELSE 0 END) AS missing_carrier_date,  --1783 NULLS

    SUM(CASE WHEN order_delivered_customer_date IS NULL THEN 1 ELSE 0 END) AS missing_delivery_date,  --2985 NULLS

    SUM(CASE WHEN order_estimated_delivery_date IS NULL THEN 1 ELSE 0 END) AS missing_estimated_delivery_date  --NO NULLS

FROM dbo.raw_orders;



--checking in raw_customers table  (NO NULLS)
SELECT
    COUNT(*) AS total_customers,

    SUM(CASE WHEN customer_id IS NULL THEN 1 ELSE 0 END) AS missing_customer_id,

    SUM(CASE WHEN customer_unique_id IS NULL THEN 1 ELSE 0 END) AS missing_customer_unique_id,

    SUM(CASE WHEN customer_zip_code_prefix IS NULL THEN 1 ELSE 0 END) AS missing_zip,

    SUM(CASE WHEN customer_city IS NULL THEN 1 ELSE 0 END) AS missing_city,

    SUM(CASE WHEN customer_state IS NULL THEN 1 ELSE 0 END) AS missing_state

FROM dbo.raw_customers;


--CHECKING FOR SELLERS TABLE (NO NULLS)
SELECT
    COUNT(*) AS total_sellers,

    SUM(CASE WHEN seller_id IS NULL THEN 1 ELSE 0 END) AS missing_seller_id,

    SUM(CASE WHEN seller_zip_code_prefix IS NULL THEN 1 ELSE 0 END) AS missing_zip,

    SUM(CASE WHEN seller_city IS NULL THEN 1 ELSE 0 END) AS missing_city,

    SUM(CASE WHEN seller_state IS NULL THEN 1 ELSE 0 END) AS missing_state

FROM dbo.raw_sellers;


--CHECKING FOR PRODUCTS TABLE
SELECT
    COUNT(*) AS total_products,

    SUM(CASE WHEN product_id IS NULL THEN 1 ELSE 0 END) AS missing_product_id,

    SUM(CASE WHEN product_category_name IS NULL THEN 1 ELSE 0 END) AS missing_category, --610 NULLS

    SUM(CASE WHEN product_name_lenght IS NULL THEN 1 ELSE 0 END) AS missing_name_length,  --610 NULLS

    SUM(CASE WHEN product_description_lenght IS NULL THEN 1 ELSE 0 END) AS missing_description_length,  --610 NULLS

    SUM(CASE WHEN product_photos_qty IS NULL THEN 1 ELSE 0 END) AS missing_photo_count,  --610 NULLS

    SUM(CASE WHEN product_weight_g IS NULL THEN 1 ELSE 0 END) AS missing_weight,  --2 NULLS

    SUM(CASE WHEN product_length_cm IS NULL THEN 1 ELSE 0 END) AS missing_length,  --2 NULLS

    SUM(CASE WHEN product_height_cm IS NULL THEN 1 ELSE 0 END) AS missing_height,   --2 NULLS

    SUM(CASE WHEN product_width_cm IS NULL THEN 1 ELSE 0 END) AS missing_width  --2 NULLS

FROM dbo.raw_products;


--CHECKING order_items table (NO NULLS)
SELECT
    COUNT(*) AS total_order_items,

    SUM(CASE WHEN order_id IS NULL THEN 1 ELSE 0 END) AS missing_order_id,

    SUM(CASE WHEN product_id IS NULL THEN 1 ELSE 0 END) AS missing_product_id,

    SUM(CASE WHEN seller_id IS NULL THEN 1 ELSE 0 END) AS missing_seller_id,

    SUM(CASE WHEN price IS NULL THEN 1 ELSE 0 END) AS missing_price,

    SUM(CASE WHEN freight_value IS NULL THEN 1 ELSE 0 END) AS missing_freight

FROM dbo.raw_order_items;


--CHECKING ORDER_PAYMENTS TABLE (NO NULLS)
SELECT
    COUNT(*) AS total_payments,

    SUM(CASE WHEN order_id IS NULL THEN 1 ELSE 0 END) AS missing_order_id,

    SUM(CASE WHEN payment_type IS NULL THEN 1 ELSE 0 END) AS missing_payment_type,

    SUM(CASE WHEN payment_installments IS NULL THEN 1 ELSE 0 END) AS missing_installments,

    SUM(CASE WHEN payment_value IS NULL THEN 1 ELSE 0 END) AS missing_payment_value

FROM dbo.raw_order_payments;


--CHECKING REVIEWS TABLE (NO NULLS) 
SELECT
    COUNT(*) AS total_reviews,

    SUM(CASE WHEN review_id IS NULL THEN 1 ELSE 0 END) AS missing_review_id,

    SUM(CASE WHEN order_id IS NULL THEN 1 ELSE 0 END) AS missing_order_id,

    SUM(CASE WHEN review_score IS NULL THEN 1 ELSE 0 END) AS missing_review_score,

    SUM(CASE WHEN review_creation_date IS NULL THEN 1 ELSE 0 END) AS missing_creation_date,

    SUM(CASE WHEN review_answer_timestamp IS NULL THEN 1 ELSE 0 END) AS missing_answer_timestamp

FROM dbo.raw_order_reviews;



--CHECKING GEOLOCATION TABLE (NO NULLS)
SELECT
    COUNT(*) AS total_rows,

    SUM(CASE WHEN geolocation_zip_code_prefix IS NULL THEN 1 ELSE 0 END) AS missing_zip,

    SUM(CASE WHEN geolocation_lat IS NULL THEN 1 ELSE 0 END) AS missing_latitude,

    SUM(CASE WHEN geolocation_lng IS NULL THEN 1 ELSE 0 END) AS missing_longitude,

    SUM(CASE WHEN geolocation_city IS NULL THEN 1 ELSE 0 END) AS missing_city,

    SUM(CASE WHEN geolocation_state IS NULL THEN 1 ELSE 0 END) AS missing_state

FROM dbo.raw_geolocation;



-- are the nulls genuine or a data quality issue?
SELECT
    order_status,
    COUNT(*) AS order_count
FROM dbo.raw_orders
WHERE order_delivered_customer_date IS NULL
GROUP BY order_status
ORDER BY order_count DESC;


SELECT
    order_id,
    order_status,
    order_purchase_timestamp,
    order_approved_at,
    order_delivered_carrier_date,
    order_delivered_customer_date,
    order_estimated_delivery_date
FROM dbo.raw_orders
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NULL;


--is product category null for these products
SELECT
    product_category_name,
    COUNT(*) AS product_count
FROM dbo.raw_products
WHERE product_category_name IS NULL
GROUP BY product_category_name;


--are the products actually being ordered?
SELECT
    COUNT(DISTINCT p.product_id) AS products_missing_category,
    COUNT(DISTINCT oi.product_id) AS missing_category_products_with_orders,
    COUNT(oi.order_id) AS order_item_rows
FROM dbo.raw_products p
LEFT JOIN dbo.raw_order_items oi
    ON p.product_id = oi.product_id
WHERE p.product_category_name IS NULL;


--===================================
--Foreign-key / orphan validation
--===================================


--orders->customers (clean)
SELECT
    COUNT(*) AS orphan_orders
FROM dbo.raw_orders o
LEFT JOIN dbo.raw_customers c
    ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

--order_items->orders (clean)
SELECT
    COUNT(*) AS orphan_order_items
FROM dbo.raw_order_items oi
LEFT JOIN dbo.raw_orders o
    ON oi.order_id = o.order_id
WHERE o.order_id IS NULL;


--order_items->products (clean)
SELECT
    COUNT(*) AS orphan_order_items
FROM dbo.raw_order_items oi
LEFT JOIN dbo.raw_products p
    ON oi.product_id = p.product_id
WHERE p.product_id IS NULL;


--order_items->sellers (clean)
SELECT
    COUNT(*) AS orphan_order_items
FROM dbo.raw_order_items oi
LEFT JOIN dbo.raw_sellers s
    ON oi.seller_id = s.seller_id
WHERE s.seller_id IS NULL;


--payments->orders (clean)
SELECT
    COUNT(*) AS orphan_payments
FROM dbo.raw_order_payments op
LEFT JOIN dbo.raw_orders o
    ON op.order_id = o.order_id
WHERE o.order_id IS NULL;


--reviews->orders (clean)
SELECT
    COUNT(*) AS orphan_reviews
FROM dbo.raw_order_reviews r
LEFT JOIN dbo.raw_orders o
    ON r.order_id = o.order_id
WHERE o.order_id IS NULL;


--===================================
-- Category translation relationship
--===================================

--how many ctaegories doesnt have transalation
SELECT
    COUNT(DISTINCT p.product_category_name) AS product_categories,
    COUNT(DISTINCT ct.product_category_name) AS translated_categories
FROM dbo.raw_products p
LEFT JOIN dbo.raw_category_translation ct
    ON p.product_category_name = ct.product_category_name
WHERE p.product_category_name IS NOT NULL;

--which categories have missing translation
SELECT DISTINCT
    p.product_category_name
FROM dbo.raw_products p
LEFT JOIN dbo.raw_category_translation ct
    ON p.product_category_name = ct.product_category_name
WHERE p.product_category_name IS NOT NULL
  AND ct.product_category_name IS NULL;



--=========================
--Timestamp validation
--=========================

SELECT
    SUM(
        CASE
            WHEN order_approved_at < order_purchase_timestamp
            THEN 1 ELSE 0
        END
    ) AS approval_before_purchase,  

    SUM(
        CASE
            WHEN order_delivered_carrier_date < order_purchase_timestamp
            THEN 1 ELSE 0
        END
    ) AS shipping_before_purchase,  --166

    SUM(
        CASE
            WHEN order_delivered_customer_date < order_purchase_timestamp
            THEN 1 ELSE 0
        END
    ) AS delivery_before_purchase,

    SUM(
        CASE
            WHEN order_delivered_customer_date < order_delivered_carrier_date
            THEN 1 ELSE 0
        END
    ) AS delivery_before_carrier,  --23

    SUM(
        CASE
            WHEN order_estimated_delivery_date < order_purchase_timestamp
            THEN 1 ELSE 0
        END
    ) AS estimate_before_purchase

FROM dbo.raw_orders;

--Check timestamp NULL logic by order status
SELECT
    order_status,

    COUNT(*) AS total_orders,

    SUM(
        CASE WHEN order_approved_at IS NULL
             THEN 1 ELSE 0 END
    ) AS missing_approval,

    SUM(
        CASE WHEN order_delivered_carrier_date IS NULL
             THEN 1 ELSE 0 END
    ) AS missing_carrier_date,

    SUM(
        CASE WHEN order_delivered_customer_date IS NULL
             THEN 1 ELSE 0 END
    ) AS missing_delivery

FROM dbo.raw_orders
GROUP BY order_status
ORDER BY total_orders DESC;


--=================================
--Numeric data validation
--=================================


--Order item economics
SELECT
    MIN(price) AS min_price,
    MAX(price) AS max_price,
    AVG(price) AS avg_price,

    MIN(freight_value) AS min_freight,
    MAX(freight_value) AS max_freight,
    AVG(freight_value) AS avg_freight
FROM dbo.raw_order_items;

SELECT
    COUNT(*) AS negative_price_rows
FROM dbo.raw_order_items
WHERE price < 0;

SELECT
    COUNT(*) AS negative_freight_rows
FROM dbo.raw_order_items
WHERE freight_value < 0;


--==============================
--Review score validation
--==============================
SELECT
    review_score,
    COUNT(*) AS review_count
FROM dbo.raw_order_reviews
GROUP BY review_score
ORDER BY review_score;


SELECT
    COUNT(*) AS invalid_review_scores
FROM dbo.raw_order_reviews
WHERE review_score NOT BETWEEN 1 AND 5;


--==============================
--Payment validation
--==============================

SELECT
    MIN(payment_installments) AS min_installments,
    MAX(payment_installments) AS max_installments
FROM dbo.raw_order_payments;

SELECT
    COUNT(*) AS invalid_installments
FROM dbo.raw_order_payments
WHERE payment_installments <= 0;

SELECT
    MIN(payment_value) AS min_payment,
    MAX(payment_value) AS max_payment,
    AVG(payment_value) AS avg_payment
FROM dbo.raw_order_payments;

SELECT
    COUNT(*) AS negative_payment_values
FROM dbo.raw_order_payments
WHERE payment_value < 0;


--==============================
--Product physical dimensions
--==============================

SELECT
    product_id,
    product_weight_g,
    product_length_cm,
    product_height_cm,
    product_width_cm
FROM dbo.raw_products
WHERE product_weight_g IS NULL
   OR product_length_cm IS NULL
   OR product_height_cm IS NULL
   OR product_width_cm IS NULL;


--=========================================
--Check product category NULLs properly
--=========================================


SELECT
    COUNT(DISTINCT p.product_id) AS missing_category_products,
    COUNT(DISTINCT oi.order_id) AS affected_orders,
    SUM(oi.price) AS affected_item_value,
    SUM(oi.freight_value) AS affected_freight
FROM dbo.raw_products p
LEFT JOIN dbo.raw_order_items oi
    ON p.product_id = oi.product_id
WHERE p.product_category_name IS NULL;








