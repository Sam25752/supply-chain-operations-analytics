



/* ============================================================
   04_ORDER_METRICS.SQL

   PURPOSE:
   Create the core analytical dataset at ORDER level.

   GRAIN:
   1 row = 1 order

   SOURCE TABLES:
   raw_orders
   raw_customers
   raw_order_items
   raw_order_payments
   raw_order_reviews

   IMPORTANT:
   Many-side tables are aggregated BEFORE joining.
   ============================================================ */

--check everything before creating the final table
--order item aggregation
    WITH order_item_agg AS
    (
        SELECT
            order_id,
            COUNT(*) AS order_item_count,
            COUNT(DISTINCT product_id) AS product_count,
            COUNT(DISTINCT seller_id) AS seller_count,
            SUM(price) AS order_item_value,
            SUM(freight_value) AS freight_value
        FROM dbo.raw_order_items
        GROUP BY order_id
    ),

    --payment aggregation
    payment_agg AS
    (
        SELECT
            order_id,
            COUNT(*) AS payment_record_count,
            COUNT(DISTINCT payment_type) AS payment_type_count,
            SUM(payment_value) AS total_payment_value,
            MAX(payment_installments) AS max_payment_installments
        FROM dbo.raw_order_payments
        GROUP BY order_id
    ),

    --review aggregation
    review_agg AS
    (
        SELECT
            order_id,
            COUNT(*) AS review_record_count,
            COUNT(DISTINCT review_id) AS distinct_review_count,
            AVG(CAST(review_score AS DECIMAL(10,2))) AS avg_review_score,
            MIN(review_score) AS min_review_score,
            MAX(review_score) AS max_review_score
        FROM dbo.raw_order_reviews
        GROUP BY order_id
    )

    SELECT TOP 20
        o.order_id,
        o.customer_id,
        o.order_status,

        o.order_purchase_timestamp,
        o.order_approved_at,
        o.order_delivered_carrier_date,
        o.order_delivered_customer_date,
        o.order_estimated_delivery_date,

        oi.order_item_count,
        oi.product_count,
        oi.seller_count,
        oi.order_item_value,
        oi.freight_value,

        p.payment_record_count,
        p.payment_type_count,
        p.total_payment_value,
        p.max_payment_installments,

        r.review_record_count,
        r.distinct_review_count,
        r.avg_review_score,
        r.min_review_score,
        r.max_review_score

    FROM dbo.raw_orders o

    LEFT JOIN order_item_agg oi
        ON o.order_id = oi.order_id

    LEFT JOIN payment_agg p
        ON o.order_id = p.order_id

    LEFT JOIN review_agg r
        ON o.order_id = r.order_id

    ORDER BY o.order_purchase_timestamp;



-- ============================================================
-- 1. DROP TABLE IF IT ALREADY EXISTS
-- ============================================================

IF OBJECT_ID('dbo.order_level_metrics', 'U') IS NOT NULL
    DROP TABLE dbo.order_level_metrics;
GO


-- ============================================================
-- 2. CREATE ORDER-LEVEL ANALYTICAL TABLE
-- ============================================================

WITH

/* ------------------------------------------------------------
   ORDER ITEMS
   Grain after aggregation: 1 row per order
   ------------------------------------------------------------ */

item_metrics AS
(
    SELECT
        order_id,

        COUNT(*) AS order_item_count,

        COUNT(DISTINCT product_id) AS product_count,

        COUNT(DISTINCT seller_id) AS seller_count,

        SUM(price) AS order_item_value,

        SUM(freight_value) AS freight_value

    FROM dbo.raw_order_items

    GROUP BY order_id
),


/* ------------------------------------------------------------
   PAYMENTS
   Grain after aggregation: 1 row per order
   ------------------------------------------------------------ */

payment_metrics AS
(
    SELECT
        order_id,

        COUNT(*) AS payment_record_count,

        COUNT(DISTINCT payment_type) AS payment_type_count,

        SUM(payment_value) AS total_payment_value,

        MAX(payment_installments) AS max_payment_installments

    FROM dbo.raw_order_payments

    GROUP BY order_id
),


/* ------------------------------------------------------------
   REVIEWS
   Grain after aggregation: 1 row per order
   ------------------------------------------------------------ */

review_metrics AS
(
    SELECT
        order_id,

        COUNT(*) AS review_record_count,

        COUNT(DISTINCT review_id) AS distinct_review_count,

        AVG(CAST(review_score AS DECIMAL(10,2))) AS avg_review_score,

        MIN(review_score) AS min_review_score,

        MAX(review_score) AS max_review_score

    FROM dbo.raw_order_reviews

    GROUP BY order_id
)


/* ------------------------------------------------------------
   FINAL ORDER-LEVEL DATASET
   Grain: 1 row = 1 order
   ------------------------------------------------------------ */

SELECT

    -- ========================================================
    -- ORDER IDENTIFICATION
    -- ========================================================

    o.order_id,

    o.customer_id,

    o.order_status,


    -- ========================================================
    -- ORDER TIMELINE
    -- ========================================================

    o.order_purchase_timestamp,

    o.order_approved_at,

    o.order_delivered_carrier_date,

    o.order_delivered_customer_date,

    o.order_estimated_delivery_date,


    -- ========================================================
    -- CUSTOMER ATTRIBUTES
    -- ========================================================

    c.customer_unique_id,

    c.customer_city,

    c.customer_state,

    c.customer_zip_code_prefix,


    -- ========================================================
    -- ORDER ITEM METRICS
    -- ========================================================

    im.order_item_count,

    im.product_count,

    im.seller_count,

    im.order_item_value,

    im.freight_value,


    -- ========================================================
    -- TOTAL ORDER VALUE
    -- ========================================================

    ISNULL(im.order_item_value, 0)
        + ISNULL(im.freight_value, 0)
        AS total_order_value,


    -- ========================================================
    -- PAYMENT METRICS
    -- ========================================================

    pm.payment_record_count,

    pm.payment_type_count,

    pm.total_payment_value,

    pm.max_payment_installments,


    -- ========================================================
    -- REVIEW METRICS
    -- ========================================================

    rm.review_record_count,

    rm.distinct_review_count,

    rm.avg_review_score,

    rm.min_review_score,

    rm.max_review_score


INTO dbo.order_level_metrics

FROM dbo.raw_orders o

LEFT JOIN dbo.raw_customers c
    ON o.customer_id = c.customer_id

LEFT JOIN item_metrics im
    ON o.order_id = im.order_id

LEFT JOIN payment_metrics pm
    ON o.order_id = pm.order_id

LEFT JOIN review_metrics rm
    ON o.order_id = rm.order_id;

GO


-- ============================================================
-- 3. BASIC VALIDATION
-- ============================================================

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT order_id) AS distinct_orders
FROM dbo.order_level_metrics;


-- ============================================================
-- 4. CHECK FOR DUPLICATE ORDER GRAIN
-- ============================================================

SELECT
    order_id,
    COUNT(*) AS row_count
FROM dbo.order_level_metrics
GROUP BY order_id
HAVING COUNT(*) > 1;


-- ============================================================
-- 5. CHECK CUSTOMER MATCHING
-- ============================================================

SELECT
    COUNT(*) AS total_orders,

    COUNT(customer_unique_id) AS matched_customers,

    COUNT(*) - COUNT(customer_unique_id)
        AS unmatched_customers

FROM dbo.order_level_metrics;


-- ============================================================
-- 6. PREVIEW
-- ============================================================

SELECT TOP 20 *
FROM dbo.order_level_metrics
ORDER BY order_purchase_timestamp;
GO





