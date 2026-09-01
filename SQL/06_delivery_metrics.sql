
/* ============================================================
   05_DELIVERY_METRICS.SQL

   PURPOSE:
   Create delivery and fulfillment performance metrics.

   GRAIN:
   1 row = 1 order

   SOURCE:
   dbo.order_level_metrics

   KEY BUSINESS QUESTIONS:
   1. How long does fulfillment take?
   2. Where is time being spent?
   3. Which orders are late?
   4. How many days late are they?
   5. How severe are delivery delays?
   ============================================================ */


-- ============================================================
-- 1. DROP TABLE IF IT ALREADY EXISTS
-- ============================================================

IF OBJECT_ID('dbo.delivery_metrics', 'U') IS NOT NULL
    DROP TABLE dbo.delivery_metrics;
GO


-- ============================================================
-- 2. CREATE DELIVERY METRICS TABLE
-- ============================================================

SELECT

    -- ========================================================
    -- ORDER IDENTIFICATION
    -- ========================================================

    order_id,

    customer_id,

    customer_unique_id,

    order_status,


    -- ========================================================
    -- CUSTOMER INFORMATION
    -- ========================================================

    customer_city,

    customer_state,

    customer_zip_code_prefix,


    -- ========================================================
    -- ORDER VALUE
    -- ========================================================

    order_item_count,

    product_count,

    seller_count,

    order_item_value,

    freight_value,

    total_order_value,

    total_payment_value,


    -- ========================================================
    -- ORIGINAL ORDER TIMESTAMPS
    -- ========================================================

    order_purchase_timestamp,

    order_approved_at,

    order_delivered_carrier_date,

    order_delivered_customer_date,

    order_estimated_delivery_date,


    -- ========================================================
    -- 1. APPROVAL TIME
    --
    -- Purchase → Approval
    -- ========================================================

    CASE
        WHEN order_purchase_timestamp IS NOT NULL
         AND order_approved_at IS NOT NULL
        THEN
            DATEDIFF(
                MINUTE,
                order_purchase_timestamp,
                order_approved_at
            ) / 60.0
    END AS approval_time_hours,


    -- ========================================================
    -- 2. PROCESSING / HANDLING TIME
    --
    -- Approval → Carrier Handoff
    -- ========================================================

    CASE
        WHEN order_approved_at IS NOT NULL
        AND order_delivered_carrier_date IS NOT NULL
        AND order_delivered_carrier_date >= order_approved_at
        THEN
            DATEDIFF(
                MINUTE,
                order_approved_at,
                order_delivered_carrier_date
            ) / 60.0
    END AS processing_time_hours,


    -- ========================================================
    -- 3. SHIPPING / TRANSIT TIME
    --
    -- Carrier Handoff → Customer Delivery
    -- ========================================================

    CASE
        WHEN order_delivered_carrier_date IS NOT NULL
        AND order_delivered_customer_date IS NOT NULL
        AND order_delivered_customer_date >= order_delivered_carrier_date
        THEN
            DATEDIFF(
                MINUTE,
                order_delivered_carrier_date,
                order_delivered_customer_date
            ) / 1440.0
    END AS shipping_time_days,


    -- ========================================================
    -- 4. TOTAL FULFILLMENT TIME
    --
    -- Purchase → Customer Delivery
    -- ========================================================

    CASE
        WHEN order_purchase_timestamp IS NOT NULL
         AND order_delivered_customer_date IS NOT NULL
        THEN
            DATEDIFF(
                MINUTE,
                order_purchase_timestamp,
                order_delivered_customer_date
            ) / 24.0 / 60.0
    END AS total_fulfillment_time_days,


    -- ========================================================
    -- 5. EXPECTED FULFILLMENT TIME
    --
    -- Purchase → Estimated Delivery
    -- ========================================================

    CASE
        WHEN order_purchase_timestamp IS NOT NULL
         AND order_estimated_delivery_date IS NOT NULL
        THEN
            DATEDIFF(
                MINUTE,
                order_purchase_timestamp,
                order_estimated_delivery_date
            ) / 24.0 / 60.0
    END AS expected_fulfillment_time_days,


    -- ========================================================
    -- 6. DELIVERY DELAY
    --
    -- Actual Delivery - Estimated Delivery
    --
    -- Positive = Late
    -- Zero/Negative = On time / Early
    -- NULL = Not delivered
    -- ========================================================

    CASE
        WHEN order_delivered_customer_date IS NOT NULL
         AND order_estimated_delivery_date IS NOT NULL
        THEN
            DATEDIFF(
                MINUTE,
                order_estimated_delivery_date,
                order_delivered_customer_date
            ) / 24.0 / 60.0
    END AS delivery_delay_days,


    -- ========================================================
    -- 7. LATE DELIVERY FLAG
    --
    -- 1 = Delivered late
    -- 0 = Delivered on time / early
    -- NULL = Not delivered
    -- ========================================================

    CASE
        WHEN order_status = 'delivered'
         AND order_delivered_customer_date IS NOT NULL
         AND order_estimated_delivery_date IS NOT NULL
         AND order_delivered_customer_date
                > order_estimated_delivery_date
        THEN 1

        WHEN order_status = 'delivered'
         AND order_delivered_customer_date IS NOT NULL
         AND order_estimated_delivery_date IS NOT NULL
        THEN 0

        ELSE NULL
    END AS late_delivery_flag,


    -- ========================================================
    -- 8. DELIVERY PERFORMANCE CATEGORY
    -- ========================================================

    CASE

        WHEN order_status = 'delivered'
         AND order_delivered_customer_date IS NOT NULL
         AND order_estimated_delivery_date IS NOT NULL
         AND order_delivered_customer_date
                < order_estimated_delivery_date
        THEN 'Early'

        WHEN order_status = 'delivered'
         AND order_delivered_customer_date IS NOT NULL
         AND order_estimated_delivery_date IS NOT NULL
         AND order_delivered_customer_date
                <= order_estimated_delivery_date
        THEN 'On Time'

        WHEN order_status = 'delivered'
         AND order_delivered_customer_date IS NOT NULL
         AND order_estimated_delivery_date IS NOT NULL
         AND order_delivered_customer_date
                > order_estimated_delivery_date
        THEN 'Late'

        ELSE 'Not Delivered'

    END AS delivery_performance_category,


    -- ========================================================
    -- 9. DELAY SEVERITY
    --
    -- Helps distinguish small delays from severe failures.
    -- ========================================================

    CASE

        WHEN order_status <> 'delivered'
          OR order_delivered_customer_date IS NULL
        THEN 'Not Delivered'

        WHEN order_delivered_customer_date
                <= order_estimated_delivery_date
        THEN 'No Delay'

        WHEN DATEDIFF(
                DAY,
                order_estimated_delivery_date,
                order_delivered_customer_date
             ) <= 2
        THEN 'Minor Delay'

        WHEN DATEDIFF(
                DAY,
                order_estimated_delivery_date,
                order_delivered_customer_date
             ) <= 7
        THEN 'Moderate Delay'

        ELSE 'Severe Delay'

    END AS delay_severity,


    -- ========================================================
    -- 10. DELIVERY MONTH
    --
    -- Useful for trend analysis later.
    -- ========================================================

    YEAR(order_purchase_timestamp) AS purchase_year,

    MONTH(order_purchase_timestamp) AS purchase_month,


    -- ========================================================
    -- 11. DELIVERY WEEKDAY
    -- ========================================================

    DATENAME(
        WEEKDAY,
        order_purchase_timestamp
    ) AS purchase_weekday


INTO dbo.delivery_metrics

FROM dbo.order_level_metrics;

GO


-- ============================================================
-- 3. BASIC GRAIN VALIDATION
-- ============================================================

SELECT
    COUNT(*) AS total_rows,

    COUNT(DISTINCT order_id) AS distinct_orders

FROM dbo.delivery_metrics;
GO


-- ============================================================
-- 4. DUPLICATE ORDER CHECK
-- ============================================================

SELECT
    order_id,
    COUNT(*) AS row_count

FROM dbo.delivery_metrics

GROUP BY order_id

HAVING COUNT(*) > 1;
GO


-- ============================================================
-- 5. DELIVERY PERFORMANCE DISTRIBUTION
-- ============================================================

SELECT
    delivery_performance_category,
    COUNT(*) AS order_count

FROM dbo.delivery_metrics

GROUP BY delivery_performance_category

ORDER BY order_count DESC;
GO


-- ============================================================
-- 6. LATE DELIVERY SUMMARY
-- ============================================================

SELECT

    COUNT(
        CASE
            WHEN order_status = 'delivered'
            THEN 1
        END
    ) AS delivered_orders,

    SUM(
        CASE
            WHEN late_delivery_flag = 1
            THEN 1
            ELSE 0
        END
    ) AS late_orders,

    SUM(
        CASE
            WHEN late_delivery_flag = 0
            THEN 1
            ELSE 0
        END
    ) AS on_time_orders,

    CAST(
        100.0 *
        SUM(
            CASE
                WHEN late_delivery_flag = 1
                THEN 1
                ELSE 0
            END
        )
        /
        NULLIF(COUNT(late_delivery_flag), 0)
        AS DECIMAL(10,2)
    ) AS late_delivery_rate

FROM dbo.delivery_metrics;


-- ============================================================
-- 7. DELAY SEVERITY DISTRIBUTION
-- ============================================================

SELECT

    delay_severity,

    COUNT(*) AS order_count

FROM dbo.delivery_metrics

GROUP BY delay_severity

ORDER BY order_count DESC;
GO


-- ============================================================
-- 8. DELIVERY TIME SUMMARY
-- ============================================================

SELECT

    MIN(total_fulfillment_time_days)
        AS min_fulfillment_days,

    MAX(total_fulfillment_time_days)
        AS max_fulfillment_days,

    AVG(total_fulfillment_time_days)
        AS avg_fulfillment_days,

    MIN(delivery_delay_days)
        AS min_delay_days,

    MAX(delivery_delay_days)
        AS max_delay_days,

    AVG(
        CASE
            WHEN late_delivery_flag = 1
            THEN delivery_delay_days
        END
    ) AS avg_late_delay_days

FROM dbo.delivery_metrics;
GO


-- ============================================================
-- 9. CHECK FOR NEGATIVE OPERATIONAL TIMES
-- ============================================================

SELECT

    COUNT(*) AS invalid_processing_times

FROM dbo.delivery_metrics

WHERE processing_time_hours < 0;


SELECT

    COUNT(*) AS invalid_shipping_times

FROM dbo.delivery_metrics

WHERE shipping_time_days < 0;


SELECT

    COUNT(*) AS invalid_fulfillment_times

FROM dbo.delivery_metrics

WHERE total_fulfillment_time_days < 0;
GO


-- ============================================================
-- 10. TOP SEVERE DELAYS
-- ============================================================

SELECT TOP 20

    order_id,

    customer_state,

    order_status,

    total_order_value,

    total_fulfillment_time_days,

    delivery_delay_days,

    delivery_performance_category,

    delay_severity

FROM dbo.delivery_metrics

WHERE late_delivery_flag = 1

ORDER BY delivery_delay_days DESC;
GO