SELECT * FROM orders LIMIT 10;

SELECT order_status, COUNT(*) AS num_orders
FROM orders
GROUP BY order_status
ORDER BY num_orders DESC;

SELECT * FROM order_items LIMIT 10;

SELECT DATE_TRUNC('month', order_purchase_timestamp) AS order_month, COUNT(*) AS num_orders 
FROM orders
WHERE order_status = 'delivered' 
AND order_purchase_timestamp >= '2017-01-01' 
AND order_purchase_timestamp <  '2018-09-01' 
GROUP BY order_month
ORDER BY order_month;

WITH monthly AS (
    SELECT DATE_TRUNC('month', o.order_purchase_timestamp) AS order_month,
           COUNT(DISTINCT o.order_id) AS num_orders,
           SUM(oi.price)              AS revenue
    FROM orders AS o
    JOIN order_items AS oi
      ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
      AND o.order_purchase_timestamp >= '2017-01-01'
      AND o.order_purchase_timestamp <  '2018-09-01'
    GROUP BY order_month
)
SELECT order_month,
       num_orders,
       revenue,
       LAG(revenue) OVER (ORDER BY order_month) AS prev_month_revenue,
       ROUND(
           (revenue - LAG(revenue) OVER (ORDER BY order_month))
           / LAG(revenue) OVER (ORDER BY order_month) * 100
       , 1) AS revenue_growth_pct
FROM monthly
ORDER BY order_month;