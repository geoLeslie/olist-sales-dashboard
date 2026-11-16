-- Monthly revenue, order count and growth vs last month
-- Delivered orders only, Jan 2017 to Aug 2018

WITH monthly AS (
    SELECT CAST(DATE_TRUNC('month', o.order_purchase_timestamp) AS DATE) AS order_month,
           COUNT(DISTINCT o.order_id) AS num_orders,  -- distinct because the join repeats orders
           SUM(oi.price) AS revenue
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
