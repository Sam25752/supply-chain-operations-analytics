/* ============================================================
   09_ROOT_CAUSE_ANALYSIS.SQL

   Objective:
   Identify operational drivers of delivery delays.

   Main dimensions:
   1. Processing time
   2. Shipping time
   3. Seller performance
   4. Freight cost
   5. Order value
   6. Product characteristics
   7. Geography
   8. Customer experience
   ============================================================ */


/* ============================================================
   1. PROCESSING TIME VS DELIVERY DELAY

   Processing Time:
   Purchase -> Carrier Handover
   ============================================================ */

SELECT
    CASE
        WHEN DATEDIFF(
            HOUR,
            order_purchase_timestamp,
            order_delivered_carrier_date
        ) < 24
            THEN '< 1 day'

        WHEN DATEDIFF(
            HOUR,
            order_purchase_timestamp,
            order_delivered_carrier_date
        ) < 72
            THEN '1-3 days'

        WHEN DATEDIFF(
            HOUR,
            order_purchase_timestamp,
            order_delivered_carrier_date
        ) < 168
            THEN '3-7 days'

        ELSE '7+ days'
    END AS processing_time_bucket,

    COUNT(*) AS delivered_orders,

    SUM(
        CASE
            WHEN order_delivered_customer_date
                 > order_estimated_delivery_date
            THEN 1 ELSE 0
        END
    ) AS late_orders,

    CAST(
        100.0 *
        SUM(
            CASE
                WHEN order_delivered_customer_date
                     > order_estimated_delivery_date
                THEN 1 ELSE 0
            END
        )
        /
        NULLIF(COUNT(*),0)
        AS DECIMAL(10,2)
    ) AS late_delivery_rate

FROM dbo.raw_orders

WHERE
    order_delivered_carrier_date IS NOT NULL
    AND order_delivered_customer_date IS NOT NULL

GROUP BY
    CASE
        WHEN DATEDIFF(
            HOUR,
            order_purchase_timestamp,
            order_delivered_carrier_date
        ) < 24
            THEN '< 1 day'

        WHEN DATEDIFF(
            HOUR,
            order_purchase_timestamp,
            order_delivered_carrier_date
        ) < 72
            THEN '1-3 days'

        WHEN DATEDIFF(
            HOUR,
            order_purchase_timestamp,
            order_delivered_carrier_date
        ) < 168
            THEN '3-7 days'

        ELSE '7+ days'
    END

ORDER BY
    late_delivery_rate DESC;


/* ============================================================
   2. SHIPPING TIME VS DELIVERY DELAY

   Shipping Time:
   Carrier Handover -> Customer Delivery
   ============================================================ */

SELECT
    CASE
        WHEN DATEDIFF(
            HOUR,
            order_delivered_carrier_date,
            order_delivered_customer_date
        ) < 48
            THEN '< 2 days'

        WHEN DATEDIFF(
            HOUR,
            order_delivered_carrier_date,
            order_delivered_customer_date
        ) < 96
            THEN '2-4 days'

        WHEN DATEDIFF(
            HOUR,
            order_delivered_carrier_date,
            order_delivered_customer_date
        ) < 168
            THEN '4-7 days'

        ELSE '7+ days'
    END AS shipping_time_bucket,

    COUNT(*) AS delivered_orders,

    SUM(
        CASE
            WHEN order_delivered_customer_date
                 > order_estimated_delivery_date
            THEN 1 ELSE 0
        END
    ) AS late_orders,

    CAST(
        100.0 *
        SUM(
            CASE
                WHEN order_delivered_customer_date
                     > order_estimated_delivery_date
                THEN 1 ELSE 0
            END
        )
        /
        NULLIF(COUNT(*),0)
        AS DECIMAL(10,2)
    ) AS late_delivery_rate

FROM dbo.raw_orders

WHERE
    order_delivered_carrier_date IS NOT NULL
    AND order_delivered_customer_date IS NOT NULL

GROUP BY
    CASE
        WHEN DATEDIFF(
            HOUR,
            order_delivered_carrier_date,
            order_delivered_customer_date
        ) < 48
            THEN '< 2 days'

        WHEN DATEDIFF(
            HOUR,
            order_delivered_carrier_date,
            order_delivered_customer_date
        ) < 96
            THEN '2-4 days'

        WHEN DATEDIFF(
            HOUR,
            order_delivered_carrier_date,
            order_delivered_customer_date
        ) < 168
            THEN '4-7 days'

        ELSE '7+ days'
    END

ORDER BY
    late_delivery_rate DESC;


/* ============================================================
   3. SELLER DELAY CONTRIBUTION

   Identify sellers with:
   - meaningful order volume
   - high late rate
   ============================================================ */

SELECT
    oi.seller_id,

    COUNT(DISTINCT o.order_id) AS delivered_orders,

    SUM(
        CASE
            WHEN o.order_delivered_customer_date
                 > o.order_estimated_delivery_date
            THEN 1 ELSE 0
        END
    ) AS late_orders,

    CAST(
        100.0 *
        SUM(
            CASE
                WHEN o.order_delivered_customer_date
                     > o.order_estimated_delivery_date
                THEN 1 ELSE 0
            END
        )
        /
        NULLIF(COUNT(DISTINCT o.order_id),0)
        AS DECIMAL(10,2)
    ) AS late_delivery_rate,

    CAST(
        AVG(oi.freight_value)
        AS DECIMAL(10,2)
    ) AS avg_freight_value

FROM dbo.raw_order_items oi

JOIN dbo.raw_orders o
    ON oi.order_id = o.order_id

WHERE
    o.order_delivered_customer_date IS NOT NULL

GROUP BY
    oi.seller_id

HAVING
    COUNT(DISTINCT o.order_id) >= 50

ORDER BY
    late_delivery_rate DESC;


/* ============================================================
   4. FREIGHT COST VS DELAY

   ============================================================ */

SELECT
    CASE
        WHEN oi.freight_value < 10
            THEN '< ₹10 equivalent'
        WHEN oi.freight_value < 25
            THEN '10-25'
        WHEN oi.freight_value < 50
            THEN '25-50'
        ELSE '50+'
    END AS freight_bucket,

    COUNT(DISTINCT o.order_id) AS order_count,

    CAST(
        AVG(oi.freight_value)
        AS DECIMAL(10,2)
    ) AS avg_freight,

    SUM(
        CASE
            WHEN o.order_delivered_customer_date
                 > o.order_estimated_delivery_date
            THEN 1 ELSE 0
        END
    ) AS late_orders,

    CAST(
        100.0 *
        SUM(
            CASE
                WHEN o.order_delivered_customer_date
                     > o.order_estimated_delivery_date
                THEN 1 ELSE 0
            END
        )
        /
        NULLIF(COUNT(DISTINCT o.order_id),0)
        AS DECIMAL(10,2)
    ) AS late_delivery_rate

FROM dbo.raw_order_items oi

JOIN dbo.raw_orders o
    ON oi.order_id = o.order_id

WHERE
    o.order_delivered_customer_date IS NOT NULL

GROUP BY
    CASE
        WHEN oi.freight_value < 10
            THEN '< ₹10 equivalent'
        WHEN oi.freight_value < 25
            THEN '10-25'
        WHEN oi.freight_value < 50
            THEN '25-50'
        ELSE '50+'
    END

ORDER BY
    late_delivery_rate DESC;


/* ============================================================
   5. ORDER VALUE VS DELIVERY DELAY
   ============================================================ */

WITH order_value AS
(
    SELECT
        o.order_id,

        SUM(oi.price + oi.freight_value) AS total_order_value,

        o.order_delivered_customer_date,
        o.order_estimated_delivery_date

    FROM dbo.raw_orders o

    JOIN dbo.raw_order_items oi
        ON o.order_id = oi.order_id

    WHERE
        o.order_delivered_customer_date IS NOT NULL

    GROUP BY
        o.order_id,
        o.order_delivered_customer_date,
        o.order_estimated_delivery_date
)

SELECT
    CASE
        WHEN total_order_value < 50
            THEN '< 50'
        WHEN total_order_value < 100
            THEN '50-100'
        WHEN total_order_value < 250
            THEN '100-250'
        WHEN total_order_value < 500
            THEN '250-500'
        ELSE '500+'
    END AS order_value_bucket,

    COUNT(*) AS order_count,

    SUM(
        CASE
            WHEN order_delivered_customer_date
                 > order_estimated_delivery_date
            THEN 1 ELSE 0
        END
    ) AS late_orders,

    CAST(
        100.0 *
        SUM(
            CASE
                WHEN order_delivered_customer_date
                     > order_estimated_delivery_date
                THEN 1 ELSE 0
            END
        )
        / NULLIF(COUNT(*),0)
        AS DECIMAL(10,2)
    ) AS late_delivery_rate

FROM order_value

GROUP BY
    CASE
        WHEN total_order_value < 50
            THEN '< 50'
        WHEN total_order_value < 100
            THEN '50-100'
        WHEN total_order_value < 250
            THEN '100-250'
        WHEN total_order_value < 500
            THEN '250-500'
        ELSE '500+'
    END

ORDER BY
    late_delivery_rate DESC;


/* ============================================================
   6. NUMBER OF ITEMS VS DELIVERY DELAY
   ============================================================ */

WITH order_items_count AS
(
    SELECT
        o.order_id,

        COUNT(oi.order_item_id) AS item_count,

        o.order_delivered_customer_date,
        o.order_estimated_delivery_date

    FROM dbo.raw_orders o

    JOIN dbo.raw_order_items oi
        ON o.order_id = oi.order_id

    WHERE
        o.order_delivered_customer_date IS NOT NULL

    GROUP BY
        o.order_id,
        o.order_delivered_customer_date,
        o.order_estimated_delivery_date
)

SELECT
    CASE
        WHEN item_count = 1
            THEN '1 item'
        WHEN item_count = 2
            THEN '2 items'
        WHEN item_count <= 5
            THEN '3-5 items'
        ELSE '6+ items'
    END AS item_count_bucket,

    COUNT(*) AS order_count,

    SUM(
        CASE
            WHEN order_delivered_customer_date
                 > order_estimated_delivery_date
            THEN 1 ELSE 0
        END
    ) AS late_orders,

    CAST(
        100.0 *
        SUM(
            CASE
                WHEN order_delivered_customer_date
                     > order_estimated_delivery_date
                THEN 1 ELSE 0
            END
        )
        / NULLIF(COUNT(*),0)
        AS DECIMAL(10,2)
    ) AS late_delivery_rate

FROM order_items_count

GROUP BY
    CASE
        WHEN item_count = 1
            THEN '1 item'
        WHEN item_count = 2
            THEN '2 items'
        WHEN item_count <= 5
            THEN '3-5 items'
        ELSE '6+ items'
    END

ORDER BY
    late_delivery_rate DESC;


/* ============================================================
   7. PRODUCT CATEGORY VS DELIVERY DELAY
   ============================================================ */

SELECT
    COALESCE(
        p.product_category_name,
        'Unknown'
    ) AS product_category,

    COUNT(DISTINCT o.order_id) AS order_count,

    SUM(
        CASE
            WHEN o.order_delivered_customer_date
                 > o.order_estimated_delivery_date
            THEN 1 ELSE 0
        END
    ) AS late_orders,

    CAST(
        100.0 *
        SUM(
            CASE
                WHEN o.order_delivered_customer_date
                     > o.order_estimated_delivery_date
                THEN 1 ELSE 0
            END
        )
        /
        NULLIF(COUNT(DISTINCT o.order_id),0)
        AS DECIMAL(10,2)
    ) AS late_delivery_rate

FROM dbo.raw_order_items oi

JOIN dbo.raw_orders o
    ON oi.order_id = o.order_id

LEFT JOIN dbo.raw_products p
    ON oi.product_id = p.product_id

WHERE
    o.order_delivered_customer_date IS NOT NULL

GROUP BY
    COALESCE(
        p.product_category_name,
        'Unknown'
    )

HAVING
    COUNT(DISTINCT o.order_id) >= 50

ORDER BY
    late_delivery_rate DESC;


/* ============================================================
   8. DELIVERY DELAY VS CUSTOMER REVIEW SCORE

   This is critical for establishing business impact.
   ============================================================ */

SELECT
    CASE
        WHEN o.order_delivered_customer_date IS NULL
            THEN 'Not Delivered'

        WHEN o.order_delivered_customer_date
             <= o.order_estimated_delivery_date
            THEN 'On Time'

        ELSE 'Late'
    END AS delivery_status,

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
                THEN 1 ELSE 0
            END
        )
        / NULLIF(COUNT(*),0)
        AS DECIMAL(10,2)
    ) AS negative_review_rate

FROM dbo.raw_orders o

JOIN dbo.raw_order_reviews r
    ON o.order_id = r.order_id

GROUP BY
    CASE
        WHEN o.order_delivered_customer_date IS NULL
            THEN 'Not Delivered'

        WHEN o.order_delivered_customer_date
             <= o.order_estimated_delivery_date
            THEN 'On Time'

        ELSE 'Late'
    END

ORDER BY
    avg_review_score ASC;


/* ============================================================
   9. ROOT-CAUSE SUMMARY BY ORDER

   Creates a compact analytical view for later Python/ML work.

   IMPORTANT:
   This is a SELECT for validation first.
   We will create a permanent analytical table later.
   ============================================================ */

SELECT TOP 100

    o.order_id,

    o.customer_id,

    o.order_status,

    DATEDIFF(
        HOUR,
        o.order_purchase_timestamp,
        o.order_approved_at
    ) / 24.0 AS approval_days,

    DATEDIFF(
        HOUR,
        o.order_purchase_timestamp,
        o.order_delivered_carrier_date
    ) / 24.0 AS processing_days,

    DATEDIFF(
        HOUR,
        o.order_delivered_carrier_date,
        o.order_delivered_customer_date
    ) / 24.0 AS shipping_days,

    DATEDIFF(
        HOUR,
        o.order_purchase_timestamp,
        o.order_delivered_customer_date
    ) / 24.0 AS fulfillment_days,

    DATEDIFF(
        HOUR,
        o.order_estimated_delivery_date,
        o.order_delivered_customer_date
    ) / 24.0 AS delivery_delay_days,

    CASE
        WHEN o.order_delivered_customer_date IS NULL
            THEN 1
        WHEN o.order_delivered_customer_date
             > o.order_estimated_delivery_date
            THEN 1
        ELSE 0
    END AS late_delivery_flag,

    c.customer_state,

    SUM(oi.price) AS item_value,

    SUM(oi.freight_value) AS freight_value,

    COUNT(oi.order_item_id) AS item_count

FROM dbo.raw_orders o

LEFT JOIN dbo.raw_customers c
    ON o.customer_id = c.customer_id

LEFT JOIN dbo.raw_order_items oi
    ON o.order_id = oi.order_id

GROUP BY
    o.order_id,
    o.customer_id,
    o.order_status,
    o.order_purchase_timestamp,
    o.order_approved_at,
    o.order_delivered_carrier_date,
    o.order_delivered_customer_date,
    o.order_estimated_delivery_date,
    c.customer_state

ORDER BY
    delivery_delay_days DESC;