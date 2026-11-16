-- Top 10 product categories by revenue (English names)

WITH category_revenue AS (
    SELECT COALESCE(t.product_category_name_english, p.product_category_name, 'unknown') AS category,
           SUM(oi.price) AS revenue,
           COUNT(*) AS items_sold
    FROM order_items AS oi
    JOIN orders AS o
      ON oi.order_id = o.order_id
    JOIN products AS p
      ON oi.product_id = p.product_id
    LEFT JOIN category_translation AS t  -- a few categories have no translation
      ON p.product_category_name = t.product_category_name
    WHERE o.order_status = 'delivered'
      AND o.order_purchase_timestamp >= '2017-01-01'
      AND o.order_purchase_timestamp <  '2018-09-01'
    GROUP BY category
),
ranked AS (
    SELECT category,
           revenue,
           items_sold,
           RANK() OVER (ORDER BY revenue DESC) AS revenue_rank,
           ROUND(100.0 * revenue / SUM(revenue) OVER (), 2) AS pct_of_total_revenue
    FROM category_revenue
)
SELECT revenue_rank, category, revenue, items_sold, pct_of_total_revenue
FROM ranked
WHERE revenue_rank <= 10
ORDER BY revenue_rank;
