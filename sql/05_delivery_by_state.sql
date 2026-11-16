-- Average delivery time and % late deliveries by customer state

WITH deliveries AS (
    SELECT c.customer_state,
           DATE_DIFF('day',
                     CAST(o.order_purchase_timestamp AS DATE),
                     CAST(o.order_delivered_customer_date AS DATE)) AS delivery_days,
           CASE WHEN CAST(o.order_delivered_customer_date AS DATE)
                   > CAST(o.order_estimated_delivery_date AS DATE)
                THEN 1 ELSE 0 END AS is_late
    FROM orders AS o
    JOIN customers AS c
      ON o.customer_id = c.customer_id
    WHERE o.order_status = 'delivered'
      AND o.order_delivered_customer_date IS NOT NULL
      AND o.order_purchase_timestamp >= '2017-01-01'
      AND o.order_purchase_timestamp <  '2018-09-01'
)
SELECT customer_state,
       COUNT(*) AS num_orders,
       ROUND(AVG(delivery_days), 1) AS avg_delivery_days,
       ROUND(100.0 * AVG(is_late), 1) AS pct_late,
       RANK() OVER (ORDER BY AVG(delivery_days) DESC) AS slowest_rank
FROM deliveries
GROUP BY customer_state
ORDER BY slowest_rank;
