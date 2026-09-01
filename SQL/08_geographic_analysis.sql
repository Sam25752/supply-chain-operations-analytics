USE SupplyChainAnalytics;
GO

/* ============================================================
   07_GEOGRAPHIC_ANALYSIS.SQL
   Supply Chain & Delivery Operations Intelligence

   Objective:
   Identify geographic patterns in:
   1. Order volume
   2. Delivery performance
   3. Delay rates
   4. Freight cost
   5. Customer experience
   6. Seller/customer geography
   ============================================================ */


/*========================================================================================
ANALYSIS SUMMARY

| Analysis                   | Grain        | Business question                         |
| -------------------------- | ------------ | ----------------------------------------- |
| State volume               | State        | Where are most orders?                    |
| State delivery performance | State        | Where are delays concentrated?            |
| Delay variance             | State        | How severe are delays?                    |
| Freight                    | State        | Where is logistics expensive?             |
| Reviews                    | State        | Where is CX poor?                         |
| City performance           | City + State | Which cities are problematic?             |
| ZIP performance            | ZIP prefix   | Can we identify granular hotspots?        |
| Customer → Seller          | State pair   | Are cross-region flows riskier?           |
| Risk geography             | State        | Where should intervention be prioritized? |
============================================================================================*/

/* ============================================================
   1. STATE-LEVEL ORDER VOLUME
   Grain: customer_state
   ============================================================ */

SELECT
    c.customer_state,
    COUNT(DISTINCT o.order_id) AS order_count,
    COUNT(DISTINCT c.customer_unique_id) AS unique_customers
FROM dbo.raw_orders o
JOIN dbo.raw_customers c
    ON o.customer_id = c.customer_id
GROUP BY
    c.customer_state
ORDER BY
    order_count DESC;


/* ============================================================
   2. STATE-LEVEL DELIVERY PERFORMANCE
   Grain: customer_state
   ============================================================ */

SELECT
    c.customer_state,

    COUNT(DISTINCT o.order_id) AS total_orders,

    SUM(
        CASE
            WHEN o.order_delivered_customer_date IS NOT NULL
             AND o.order_delivered_customer_date
                 <= o.order_estimated_delivery_date
            THEN 1
            ELSE 0
        END
    ) AS on_time_orders,

    SUM(
        CASE
            WHEN o.order_delivered_customer_date IS NOT NULL
             AND o.order_delivered_customer_date
                 > o.order_estimated_delivery_date
            THEN 1
            ELSE 0
        END
    ) AS late_orders,

    SUM(
        CASE
            WHEN o.order_delivered_customer_date IS NULL
            THEN 1
            ELSE 0
        END
    ) AS not_delivered_orders,

    CAST(
        100.0 *
        SUM(
            CASE
                WHEN o.order_delivered_customer_date IS NOT NULL
                 AND o.order_delivered_customer_date
                     > o.order_estimated_delivery_date
                THEN 1
                ELSE 0
            END
        )
        /
        NULLIF(
            SUM(
                CASE
                    WHEN o.order_delivered_customer_date IS NOT NULL
                    THEN 1
                    ELSE 0
                END
            ),
            0
        )
        AS DECIMAL(10,2)
    ) AS late_delivery_rate

FROM dbo.raw_orders o
JOIN dbo.raw_customers c
    ON o.customer_id = c.customer_id

GROUP BY
    c.customer_state

ORDER BY
    late_delivery_rate DESC;


/* ============================================================
   3. STATE-LEVEL AVERAGE DELIVERY DELAY
   Only delivered orders
   Grain: customer_state
   ============================================================ */

SELECT
    c.customer_state,

    COUNT(DISTINCT o.order_id) AS delivered_orders,

    CAST(
        AVG(
            DATEDIFF(
                DAY,
                o.order_estimated_delivery_date,
                o.order_delivered_customer_date
            ) * 1.0
        )
        AS DECIMAL(10,2)
    ) AS avg_delivery_variance_days,

    MAX(
        DATEDIFF(
            DAY,
            o.order_estimated_delivery_date,
            o.order_delivered_customer_date
        )
    ) AS max_delay_days

FROM dbo.raw_orders o
JOIN dbo.raw_customers c
    ON o.customer_id = c.customer_id

WHERE
    o.order_delivered_customer_date IS NOT NULL

GROUP BY
    c.customer_state

ORDER BY
    avg_delivery_variance_days DESC;


/* ============================================================
   4. STATE-LEVEL FREIGHT COST
   Grain: customer_state
   ============================================================ */

SELECT
    c.customer_state,

    COUNT(DISTINCT o.order_id) AS order_count,

    CAST(
        SUM(oi.freight_value)
        AS DECIMAL(15,2)
    ) AS total_freight_value,

    CAST(
        AVG(oi.freight_value)
        AS DECIMAL(10,2)
    ) AS avg_freight_per_item,

    CAST(
        SUM(oi.freight_value)
        /
        NULLIF(COUNT(DISTINCT o.order_id), 0)
        AS DECIMAL(10,2)
    ) AS avg_freight_per_order

FROM dbo.raw_orders o
JOIN dbo.raw_customers c
    ON o.customer_id = c.customer_id
JOIN dbo.raw_order_items oi
    ON o.order_id = oi.order_id

GROUP BY
    c.customer_state

ORDER BY
    avg_freight_per_order DESC;


/* ============================================================
   5. STATE-LEVEL CUSTOMER EXPERIENCE
   Grain: customer_state
   ============================================================ */

SELECT
    c.customer_state,

    COUNT(DISTINCT r.order_id) AS reviewed_orders,

    CAST(
        AVG(r.review_score * 1.0)
        AS DECIMAL(10,2)
    ) AS avg_review_score,

    CAST(
        100.0 *
        SUM(
            CASE
                WHEN r.review_score <= 2
                THEN 1
                ELSE 0
            END
        )
        /
        NULLIF(COUNT(*), 0)
        AS DECIMAL(10,2)
    ) AS negative_review_rate

FROM dbo.raw_orders o
JOIN dbo.raw_customers c
    ON o.customer_id = c.customer_id
JOIN dbo.raw_order_reviews r
    ON o.order_id = r.order_id

GROUP BY
    c.customer_state

ORDER BY
    avg_review_score ASC;


/* ============================================================
   6. CITY-LEVEL DELIVERY PERFORMANCE
   Grain: customer_city + customer_state
   ============================================================ */

SELECT
    c.customer_state,
    c.customer_city,

    COUNT(DISTINCT o.order_id) AS total_orders,

    SUM(
        CASE
            WHEN o.order_delivered_customer_date IS NOT NULL
             AND o.order_delivered_customer_date
                 > o.order_estimated_delivery_date
            THEN 1
            ELSE 0
        END
    ) AS late_orders,

    CAST(
        100.0 *
        SUM(
            CASE
                WHEN o.order_delivered_customer_date IS NOT NULL
                 AND o.order_delivered_customer_date
                     > o.order_estimated_delivery_date
                THEN 1
                ELSE 0
            END
        )
        /
        NULLIF(
            SUM(
                CASE
                    WHEN o.order_delivered_customer_date IS NOT NULL
                    THEN 1
                    ELSE 0
                END
            ),
            0
        )
        AS DECIMAL(10,2)
    ) AS late_delivery_rate

FROM dbo.raw_orders o
JOIN dbo.raw_customers c
    ON o.customer_id = c.customer_id

GROUP BY
    c.customer_state,
    c.customer_city

HAVING
    COUNT(DISTINCT o.order_id) >= 50

ORDER BY
    late_delivery_rate DESC;


/* ============================================================
   7. ZIP PREFIX-LEVEL DELIVERY PERFORMANCE
   Grain: customer_zip_code_prefix
   ============================================================ */

SELECT
    c.customer_zip_code_prefix,

    COUNT(DISTINCT o.order_id) AS total_orders,

    SUM(
        CASE
            WHEN o.order_delivered_customer_date IS NOT NULL
             AND o.order_delivered_customer_date
                 > o.order_estimated_delivery_date
            THEN 1
            ELSE 0
        END
    ) AS late_orders,

    CAST(
        100.0 *
        SUM(
            CASE
                WHEN o.order_delivered_customer_date IS NOT NULL
                 AND o.order_delivered_customer_date
                     > o.order_estimated_delivery_date
                THEN 1
                ELSE 0
            END
        )
        /
        NULLIF(
            SUM(
                CASE
                    WHEN o.order_delivered_customer_date IS NOT NULL
                    THEN 1
                    ELSE 0
                END
            ),
            0
        )
        AS DECIMAL(10,2)
    ) AS late_delivery_rate

FROM dbo.raw_orders o
JOIN dbo.raw_customers c
    ON o.customer_id = c.customer_id

GROUP BY
    c.customer_zip_code_prefix

HAVING
    COUNT(DISTINCT o.order_id) >= 20

ORDER BY
    late_delivery_rate DESC;


/* ============================================================
   8. CUSTOMER VS SELLER GEOGRAPHIC DISTANCE PROXY
   We do NOT calculate physical distance here yet.
   We first identify customer-state / seller-state combinations.

   Grain: customer_state + seller_state
   ============================================================ */

SELECT
    c.customer_state,
    s.seller_state,

    COUNT(DISTINCT o.order_id) AS order_count,

    CAST(
        AVG(oi.freight_value)
        AS DECIMAL(10,2)
    ) AS avg_freight_value,

    SUM(
        CASE
            WHEN o.order_delivered_customer_date IS NOT NULL
             AND o.order_delivered_customer_date
                 > o.order_estimated_delivery_date
            THEN 1
            ELSE 0
        END
    ) AS late_orders,

    CAST(
        100.0 *
        SUM(
            CASE
                WHEN o.order_delivered_customer_date IS NOT NULL
                 AND o.order_delivered_customer_date
                     > o.order_estimated_delivery_date
                THEN 1
                ELSE 0
            END
        )
        /
        NULLIF(
            SUM(
                CASE
                    WHEN o.order_delivered_customer_date IS NOT NULL
                    THEN 1
                    ELSE 0
                END
            ),
            0
        )
        AS DECIMAL(10,2)
    ) AS late_delivery_rate

FROM dbo.raw_orders o

JOIN dbo.raw_customers c
    ON o.customer_id = c.customer_id

JOIN dbo.raw_order_items oi
    ON o.order_id = oi.order_id

JOIN dbo.raw_sellers s
    ON oi.seller_id = s.seller_id

GROUP BY
    c.customer_state,
    s.seller_state

HAVING
    COUNT(DISTINCT o.order_id) >= 50

ORDER BY
    late_delivery_rate DESC;


/* ============================================================
   9. TOP HIGH-RISK GEOGRAPHIC AREAS
   High volume + high delay rate

   Grain: customer_state
   ============================================================ */

WITH state_metrics AS
(
    SELECT
        c.customer_state,

        COUNT(DISTINCT o.order_id) AS order_count,

        SUM(
            CASE
                WHEN o.order_delivered_customer_date IS NOT NULL
                 AND o.order_delivered_customer_date
                     > o.order_estimated_delivery_date
                THEN 1
                ELSE 0
            END
        ) AS late_orders,

        CAST(
            100.0 *
            SUM(
                CASE
                    WHEN o.order_delivered_customer_date IS NOT NULL
                     AND o.order_delivered_customer_date
                         > o.order_estimated_delivery_date
                    THEN 1
                    ELSE 0
                END
            )
            /
            NULLIF(
                SUM(
                    CASE
                        WHEN o.order_delivered_customer_date IS NOT NULL
                        THEN 1
                        ELSE 0
                    END
                ),
                0
            )
            AS DECIMAL(10,2)
        ) AS late_delivery_rate

    FROM dbo.raw_orders o

    JOIN dbo.raw_customers c
        ON o.customer_id = c.customer_id

    GROUP BY
        c.customer_state
)

SELECT
    customer_state,
    order_count,
    late_orders,
    late_delivery_rate,

    RANK() OVER (
        ORDER BY late_delivery_rate DESC
    ) AS delay_rate_rank,

    RANK() OVER (
        ORDER BY order_count DESC
    ) AS volume_rank

FROM state_metrics

ORDER BY
    late_delivery_rate DESC;