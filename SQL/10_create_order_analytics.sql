/* ============================================================
   10_CREATE_ORDER_ANALYTICS.SQL
   Grain: 1 row = 1 order
   Purpose: Central analytical dataset for downstream analysis
   ============================================================ */

IF OBJECT_ID('dbo.order_analytics', 'V') IS NOT NULL
    DROP VIEW dbo.order_analytics;
GO


CREATE VIEW dbo.order_analytics
AS

WITH

/* ============================================================
   1. ORDER ITEMS AGGREGATION
   ============================================================ */

item_metrics AS
(
    SELECT
        order_id,

        COUNT(*) AS order_item_count,

        COUNT(DISTINCT product_id) AS product_count,

        COUNT(DISTINCT seller_id) AS seller_count,

        SUM(price) AS order_item_value,

        SUM(freight_value) AS freight_value,

        SUM(price + freight_value) AS total_order_value

    FROM dbo.raw_order_items

    GROUP BY order_id
),


/* ============================================================
   2. PAYMENT AGGREGATION
   ============================================================ */

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


/* ============================================================
   3. REVIEW AGGREGATION
   ============================================================ */

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


/* ============================================================
   4. FINAL ORDER-LEVEL DATASET
   ============================================================ */

SELECT

    /* ---------------------------
       ORDER IDENTIFICATION
       --------------------------- */

    o.order_id,

    o.customer_id,

    c.customer_unique_id,

    o.order_status,


    /* ---------------------------
       CUSTOMER INFORMATION
       --------------------------- */

    c.customer_city,

    c.customer_state,

    c.customer_zip_code_prefix,


    /* ---------------------------
       ORDER TIMESTAMPS
       --------------------------- */

    o.order_purchase_timestamp,

    o.order_approved_at,

    o.order_delivered_carrier_date,

    o.order_delivered_customer_date,

    o.order_estimated_delivery_date,


    /* ---------------------------
       ORDER ECONOMICS
       --------------------------- */

    im.order_item_count,

    im.product_count,

    im.seller_count,

    im.order_item_value,

    im.freight_value,

    im.total_order_value,


    /* ---------------------------
       PAYMENT
       --------------------------- */

    pm.payment_record_count,

    pm.payment_type_count,

    pm.total_payment_value,

    pm.max_payment_installments,


    /* ---------------------------
       REVIEWS
       --------------------------- */

    rm.review_record_count,

    rm.distinct_review_count,

    rm.avg_review_score,

    rm.min_review_score,

    rm.max_review_score,


    /* ========================================================
       DELIVERY / FULFILLMENT METRICS
       ======================================================== */


    /* Processing:
       Purchase → Approval
    */

    CASE
        WHEN o.order_approved_at IS NOT NULL
        THEN DATEDIFF(
                MINUTE,
                o.order_purchase_timestamp,
                o.order_approved_at
             ) / 1440.0
    END AS processing_days,


    /* Shipping:
       Approval → Carrier
    */

    CASE
        WHEN o.order_approved_at IS NOT NULL
         AND o.order_delivered_carrier_date IS NOT NULL
        THEN DATEDIFF(
                MINUTE,
                o.order_approved_at,
                o.order_delivered_carrier_date
             ) / 1440.0
    END AS shipping_days,


    /* Fulfillment:
       Purchase → Customer
    */

    CASE
        WHEN o.order_delivered_customer_date IS NOT NULL
        THEN DATEDIFF(
                MINUTE,
                o.order_purchase_timestamp,
                o.order_delivered_customer_date
             ) / 1440.0
    END AS fulfillment_days,


    /* Expected delivery duration:
       Purchase → Estimated Delivery
    */

    CASE
        WHEN o.order_estimated_delivery_date IS NOT NULL
        THEN DATEDIFF(
                MINUTE,
                o.order_purchase_timestamp,
                o.order_estimated_delivery_date
             ) / 1440.0
    END AS expected_delivery_days,


    /* Actual delay:
       Delivered → Estimated Delivery

       Positive = late
       Negative = early
    */

    CASE
        WHEN o.order_delivered_customer_date IS NOT NULL
        THEN DATEDIFF(
                MINUTE,
                o.order_estimated_delivery_date,
                o.order_delivered_customer_date
             ) / 1440.0
    END AS delay_days,


    /* ========================================================
       DELIVERY STATUS FLAGS
       ======================================================== */


    CASE
        WHEN o.order_delivered_customer_date IS NOT NULL
        THEN 1
        ELSE 0
    END AS is_delivered,


    CASE
        WHEN o.order_delivered_customer_date IS NOT NULL
         AND o.order_delivered_customer_date
             > o.order_estimated_delivery_date
        THEN 1
        ELSE 0
    END AS is_late,


    CASE
        WHEN o.order_delivered_customer_date IS NULL
        THEN 1
        ELSE 0
    END AS is_not_delivered,


    /* ========================================================
       DELIVERY PERFORMANCE CATEGORY
       ======================================================== */

    CASE

        WHEN o.order_delivered_customer_date IS NULL
            THEN 'Not Delivered'

        WHEN o.order_delivered_customer_date
             > o.order_estimated_delivery_date
            THEN 'Late'

        ELSE 'Early'

    END AS delivery_performance_category,


    /* ========================================================
       DELAY SEVERITY
       ======================================================== */

    CASE

        WHEN o.order_delivered_customer_date IS NULL
            THEN 'Not Delivered'

        WHEN DATEDIFF(
                MINUTE,
                o.order_estimated_delivery_date,
                o.order_delivered_customer_date
             ) / 1440.0 <= 0
            THEN 'No Delay'

        WHEN DATEDIFF(
                MINUTE,
                o.order_estimated_delivery_date,
                o.order_delivered_customer_date
             ) / 1440.0 <= 3
            THEN 'Minor Delay'

        WHEN DATEDIFF(
                MINUTE,
                o.order_estimated_delivery_date,
                o.order_delivered_customer_date
             ) / 1440.0 <= 7
            THEN 'Moderate Delay'

        ELSE 'Severe Delay'

    END AS delay_severity,


    /* ========================================================
       ORDER COMPLEXITY FLAGS
       ======================================================== */

    CASE
        WHEN im.order_item_count > 1
        THEN 1
        ELSE 0
    END AS has_multiple_items,


    CASE
        WHEN im.seller_count > 1
        THEN 1
        ELSE 0
    END AS has_multiple_sellers,


    /* ========================================================
       ORDER VALUE BUCKET
       ======================================================== */

    CASE

        WHEN im.total_order_value IS NULL
            THEN 'Unknown'

        WHEN im.total_order_value < 100
            THEN 'Low Value'

        WHEN im.total_order_value < 500
            THEN 'Medium Value'

        WHEN im.total_order_value < 1000
            THEN 'High Value'

        ELSE 'Very High Value'

    END AS order_value_bucket


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




/* ============================================================
   ORDER ANALYTICS VALIDATION
   ============================================================ */

-- 1. Grain
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT order_id) AS distinct_orders
FROM dbo.order_analytics;


-- 2. Delivery performance
SELECT
    delivery_performance_category,
    COUNT(*) AS order_count
FROM dbo.order_analytics
GROUP BY delivery_performance_category
ORDER BY order_count DESC;


-- 3. Late rate
SELECT
    COUNT(*) AS total_orders,

    SUM(is_delivered) AS delivered_orders,

    SUM(is_late) AS late_orders,

    SUM(is_not_delivered) AS not_delivered_orders,

    CAST(
        100.0 * SUM(is_late)
        / NULLIF(SUM(is_delivered), 0)
        AS DECIMAL(10,2)
    ) AS late_rate_among_delivered

FROM dbo.order_analytics;


-- 4. Delivery timing
SELECT
    MIN(processing_days) AS min_processing_days,
    MAX(processing_days) AS max_processing_days,
    AVG(processing_days) AS avg_processing_days,

    MIN(shipping_days) AS min_shipping_days,
    MAX(shipping_days) AS max_shipping_days,
    AVG(shipping_days) AS avg_shipping_days,

    MIN(fulfillment_days) AS min_fulfillment_days,
    MAX(fulfillment_days) AS max_fulfillment_days,
    AVG(fulfillment_days) AS avg_fulfillment_days

FROM dbo.order_analytics;


-- 5. Customer linkage
SELECT
    COUNT(*) AS total_orders,

    SUM(
        CASE
            WHEN customer_unique_id IS NULL
            THEN 1 ELSE 0
        END
    ) AS missing_customer_unique_id

FROM dbo.order_analytics;


-- 6. Economic metrics
SELECT
    MIN(total_order_value) AS min_order_value,
    MAX(total_order_value) AS max_order_value,
    AVG(total_order_value) AS avg_order_value,

    MIN(freight_value) AS min_freight,
    MAX(freight_value) AS max_freight,
    AVG(freight_value) AS avg_freight

FROM dbo.order_analytics;


-- 7. Complexity
SELECT
    has_multiple_sellers,
    COUNT(*) AS order_count,
    AVG(CAST(is_late AS DECIMAL(10,4))) * 100 AS late_rate
FROM dbo.order_analytics
WHERE is_delivered = 1
GROUP BY has_multiple_sellers;