-- One row per delivered order, used as the main data source for the dashboard
-- (KPI cards, date filter, trend and state charts)

WITH order_revenue AS (
    SELECT order_id, SUM(price) AS revenue, COUNT(*) AS num_items
    FROM order_items
    GROUP BY order_id
),
review_per_order AS (
    SELECT order_id, AVG(review_score) AS review_score
    FROM order_reviews
    GROUP BY order_id
)
SELECT o.order_id,
       CAST(o.order_purchase_timestamp AS DATE) AS purchase_date,
       c.customer_state,
       r.revenue,
       r.num_items,
       rv.review_score,
       DATE_DIFF('day',
                 CAST(o.order_purchase_timestamp AS DATE),
                 CAST(o.order_delivered_customer_date AS DATE)) AS delivery_days,
       CASE WHEN CAST(o.order_delivered_customer_date AS DATE)
               > CAST(o.order_estimated_delivery_date AS DATE)
            THEN 1 ELSE 0 END AS is_late
FROM orders AS o
JOIN customers AS c
  ON o.customer_id = c.customer_id
JOIN order_revenue AS r
  ON o.order_id = r.order_id
LEFT JOIN review_per_order AS rv
  ON o.order_id = rv.order_id
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
  AND o.order_purchase_timestamp >= '2017-01-01'
  AND o.order_purchase_timestamp <  '2018-09-01'
ORDER BY purchase_date;
