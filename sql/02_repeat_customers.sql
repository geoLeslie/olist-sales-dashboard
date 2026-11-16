-- How many customers order more than once?
-- Uses customer_unique_id because customer_id is new for every order

WITH orders_per_customer AS (
    SELECT c.customer_unique_id,
           COUNT(DISTINCT o.order_id) AS num_orders
    FROM orders AS o
    JOIN customers AS c
      ON o.customer_id = c.customer_id
    WHERE o.order_status = 'delivered'
      AND o.order_purchase_timestamp >= '2017-01-01'
      AND o.order_purchase_timestamp <  '2018-09-01'
    GROUP BY c.customer_unique_id
)
SELECT CASE WHEN num_orders = 1 THEN 'One-time' ELSE 'Repeat' END AS customer_type,
       COUNT(*) AS num_customers,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS pct_of_customers  -- share of all customers
FROM orders_per_customer
GROUP BY customer_type
ORDER BY num_customers DESC;
