/*==============================================================
  07_SELLER_PERFORMANCE.SQL

  Purpose:
  Analyze seller-level delivery performance, order volume,
  revenue, freight cost, delays and customer experience.

  Grain:
  Seller-level analytical metrics

  Important:
  Order-level delivery metrics are calculated at
  Seller + Order grain first to avoid double counting.
==============================================================*/



/*==============================================================
  Business questions
| Analysis              | Business question                   |
| --------------------- | ----------------------------------- |
| Seller volume         | Who handles the most orders?        |
| Seller revenue        | Who generates the most GMV?         |
| Freight               | Who has high shipping costs?        |
| Fulfillment           | Who takes longer to deliver?        |
| Late delivery         | Who causes SLA failures?            |
| Review score          | Which sellers create poor CX?       |
| Seller ranking        | Who are the best/worst performers?  |
| Seller classification | Which sellers require intervention? |
=================================================================*/




/*==============================================================
  1. SELLER + ORDER LEVEL BASE
==============================================================*/

WITH seller_order_base AS
(
    SELECT
        oi.seller_id,
        oi.order_id,

        o.order_status,
        o.order_purchase_timestamp,
        o.order_delivered_carrier_date,
        o.order_delivered_customer_date,
        o.order_estimated_delivery_date,

        DATEDIFF(
            MINUTE,
            o.order_purchase_timestamp,
            o.order_delivered_customer_date
        ) / 1440.0 AS fulfillment_days,

        DATEDIFF(
            MINUTE,
            o.order_estimated_delivery_date,
            o.order_delivered_customer_date
        ) / 1440.0 AS delay_days,

        CASE
            WHEN o.order_delivered_customer_date IS NULL
                THEN 1
            WHEN o.order_delivered_customer_date
                 > o.order_estimated_delivery_date
                THEN 1
            ELSE 0
        END AS is_late,

        SUM(oi.price) AS item_value,
        SUM(oi.freight_value) AS freight_value,
        COUNT(*) AS item_count

    FROM dbo.raw_order_items oi

    INNER JOIN dbo.raw_orders o
        ON oi.order_id = o.order_id

    GROUP BY
        oi.seller_id,
        oi.order_id,
        o.order_status,
        o.order_purchase_timestamp,
        o.order_delivered_carrier_date,
        o.order_delivered_customer_date,
        o.order_estimated_delivery_date
)


/*==============================================================
  2. SELLER PERFORMANCE SUMMARY
==============================================================*/

SELECT
    seller_id,

    COUNT(*) AS total_orders,

    SUM(item_count) AS total_items,

    ROUND(SUM(item_value), 2) AS total_item_value,

    ROUND(SUM(freight_value), 2) AS total_freight_value,

    ROUND(
        SUM(item_value + freight_value),
        2
    ) AS total_order_value,

    ROUND(
        AVG(item_value),
        2
    ) AS avg_order_value,

    ROUND(
        AVG(freight_value),
        2
    ) AS avg_freight_value,

    SUM(
        CASE
            WHEN order_status = 'delivered'
            THEN 1
            ELSE 0
        END
    ) AS delivered_orders,

    SUM(is_late) AS late_orders,

    SUM(
        CASE
            WHEN order_status <> 'delivered'
            THEN 1
            ELSE 0
        END
    ) AS not_delivered_orders,

    ROUND(
        100.0 *
        SUM(
            CASE
                WHEN order_status = 'delivered'
                 AND is_late = 1
                THEN 1
                ELSE 0
            END
        )
        /
        NULLIF(
            SUM(
                CASE
                    WHEN order_status = 'delivered'
                    THEN 1
                    ELSE 0
                END
            ),
            0
        ),
        2
    ) AS late_delivery_rate,

    ROUND(
        AVG(
            CASE
                WHEN order_status = 'delivered'
                THEN fulfillment_days
            END
        ),
        2
    ) AS avg_fulfillment_days,

    ROUND(
        AVG(
            CASE
                WHEN order_status = 'delivered'
                 AND is_late = 1
                THEN delay_days
            END
        ),
        2
    ) AS avg_late_delay_days

FROM seller_order_base

GROUP BY
    seller_id

ORDER BY
    late_delivery_rate DESC;




/*==============================================================
  -- sellers contributing the most business.
==============================================================*/


WITH seller_metrics AS
(
    SELECT
        oi.seller_id,

        COUNT(DISTINCT oi.order_id) AS total_orders,

        SUM(oi.price) AS total_item_value,

        SUM(oi.freight_value) AS total_freight_value

    FROM dbo.raw_order_items oi

    GROUP BY
        oi.seller_id
)

SELECT
    seller_id,

    total_orders,

    ROUND(total_item_value, 2) AS total_item_value,

    ROUND(total_freight_value, 2) AS total_freight_value,

    RANK() OVER (
        ORDER BY total_orders DESC
    ) AS order_volume_rank,

    RANK() OVER (
        ORDER BY total_item_value DESC
    ) AS revenue_rank

FROM seller_metrics

ORDER BY
    order_volume_rank;




/*==============================================================
    Worst sellers by late delivery rate
==============================================================*/

WITH seller_order_metrics AS
(
    SELECT
        oi.seller_id,
        oi.order_id,

        o.order_status,

        CASE
            WHEN o.order_status = 'delivered'
             AND o.order_delivered_customer_date
                 > o.order_estimated_delivery_date
            THEN 1
            ELSE 0
        END AS is_late

    FROM dbo.raw_order_items oi

    INNER JOIN dbo.raw_orders o
        ON oi.order_id = o.order_id

    GROUP BY
        oi.seller_id,
        oi.order_id,
        o.order_status,
        o.order_delivered_customer_date,
        o.order_estimated_delivery_date
)

SELECT
    seller_id,

    COUNT(*) AS total_orders,

    SUM(
        CASE
            WHEN order_status = 'delivered'
            THEN 1
            ELSE 0
        END
    ) AS delivered_orders,

    SUM(is_late) AS late_orders,

    ROUND(
        100.0 * SUM(is_late)
        /
        NULLIF(
            SUM(
                CASE
                    WHEN order_status = 'delivered'
                    THEN 1
                    ELSE 0
                END
            ),
            0
        ),
        2
    ) AS late_delivery_rate

FROM seller_order_metrics

GROUP BY
    seller_id

HAVING
    SUM(
        CASE
            WHEN order_status = 'delivered'
            THEN 1
            ELSE 0
        END
    ) >= 20

ORDER BY
    late_delivery_rate DESC;




/*==============================================================
    sellers with unusually high freight costs.
==============================================================*/

SELECT
    oi.seller_id,

    COUNT(DISTINCT oi.order_id) AS total_orders,

    ROUND(SUM(oi.price), 2) AS item_value,

    ROUND(SUM(oi.freight_value), 2) AS freight_value,

    ROUND(
        100.0 * SUM(oi.freight_value)
        /
        NULLIF(SUM(oi.price), 0),
        2
    ) AS freight_to_item_value_pct,

    ROUND(
        AVG(oi.freight_value),
        2
    ) AS avg_freight_per_item

FROM dbo.raw_order_items oi

GROUP BY
    oi.seller_id

HAVING
    COUNT(DISTINCT oi.order_id) >= 20

ORDER BY
    freight_to_item_value_pct DESC;




/*==============================================================
    Seller + customer experience
==============================================================*/

WITH seller_order_reviews AS
(
    SELECT
        oi.seller_id,
        oi.order_id,

        AVG(CAST(r.review_score AS DECIMAL(10,2)))
            AS order_review_score

    FROM dbo.raw_order_items oi

    INNER JOIN dbo.raw_order_reviews r
        ON oi.order_id = r.order_id

    GROUP BY
        oi.seller_id,
        oi.order_id
)

SELECT
    seller_id,

    COUNT(*) AS reviewed_orders,

    ROUND(
        AVG(order_review_score),
        2
    ) AS avg_review_score,

    SUM(
        CASE
            WHEN order_review_score <= 2
            THEN 1
            ELSE 0
        END
    ) AS poor_review_orders,

    ROUND(
        100.0 *
        SUM(
            CASE
                WHEN order_review_score <= 2
                THEN 1
                ELSE 0
            END
        )
        /
        COUNT(*),
        2
    ) AS poor_review_rate

FROM seller_order_reviews

GROUP BY
    seller_id

HAVING
    COUNT(*) >= 20

ORDER BY
    poor_review_rate DESC;



/*==============================================================
    Seller performance classification
==============================================================*/

WITH seller_order_metrics AS
(
    SELECT
        oi.seller_id,
        oi.order_id,

        o.order_status,

        CASE
            WHEN o.order_status = 'delivered'
             AND o.order_delivered_customer_date
                 > o.order_estimated_delivery_date
            THEN 1
            ELSE 0
        END AS is_late

    FROM dbo.raw_order_items oi

    INNER JOIN dbo.raw_orders o
        ON oi.order_id = o.order_id

    GROUP BY
        oi.seller_id,
        oi.order_id,
        o.order_status,
        o.order_delivered_customer_date,
        o.order_estimated_delivery_date
),

seller_summary AS
(
    SELECT
        seller_id,

        COUNT(*) AS total_orders,

        SUM(
            CASE
                WHEN order_status = 'delivered'
                THEN 1
                ELSE 0
            END
        ) AS delivered_orders,

        SUM(is_late) AS late_orders

    FROM seller_order_metrics

    GROUP BY
        seller_id
)

SELECT
    seller_id,

    total_orders,

    delivered_orders,

    late_orders,

    ROUND(
        100.0 * late_orders
        /
        NULLIF(delivered_orders, 0),
        2
    ) AS late_delivery_rate,

    CASE

        WHEN delivered_orders < 20
            THEN 'Low Volume'

        WHEN
            100.0 * late_orders
            / NULLIF(delivered_orders, 0) <= 5
            THEN 'High Performer'

        WHEN
            100.0 * late_orders
            / NULLIF(delivered_orders, 0) <= 10
            THEN 'Average Performer'

        ELSE 'At Risk'

    END AS seller_performance_category

FROM seller_summary

ORDER BY
    late_delivery_rate DESC;