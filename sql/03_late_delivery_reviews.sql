-- Do late deliveries get worse reviews?
-- Late = delivered on a later day than the estimated date

WITH review_per_order AS (
    -- some orders have more than one review, so take the average
    SELECT order_id, AVG(review_score) AS review_score
    FROM order_reviews
    GROUP BY order_id
),
delivered AS (
    SELECT o.order_id,
           DATE_DIFF('day',
                     CAST(o.order_estimated_delivery_date AS DATE),
                     CAST(o.order_delivered_customer_date AS DATE)) AS days_late,
           r.review_score
    FROM orders AS o
    LEFT JOIN review_per_order AS r
      ON o.order_id = r.order_id
    WHERE o.order_status = 'delivered'
      AND o.order_delivered_customer_date IS NOT NULL
      AND o.order_purchase_timestamp >= '2017-01-01'
      AND o.order_purchase_timestamp <  '2018-09-01'
)
SELECT CASE
           WHEN days_late <= 0 THEN '1. On time'
           WHEN days_late <= 3 THEN '2. 1-3 days late'
           WHEN days_late <= 7 THEN '3. 4-7 days late'
           ELSE '4. 8+ days late'
       END AS delivery_group,
       COUNT(*) AS num_orders,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS pct_of_orders,
       ROUND(AVG(review_score), 2) AS avg_review_score
FROM delivered
GROUP BY delivery_group
ORDER BY delivery_group;
