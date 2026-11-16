-- Payment method share and average installments
-- One order can have several payments (e.g. voucher + credit card)

SELECT p.payment_type,
       COUNT(DISTINCT p.order_id) AS num_orders,
       SUM(p.payment_value) AS total_paid,
       ROUND(100.0 * SUM(p.payment_value) / SUM(SUM(p.payment_value)) OVER (), 2) AS pct_of_total_paid,
       ROUND(AVG(p.payment_installments), 2) AS avg_installments
FROM order_payments AS p
JOIN orders AS o
  ON p.order_id = o.order_id
WHERE o.order_status = 'delivered'
  AND o.order_purchase_timestamp >= '2017-01-01'
  AND o.order_purchase_timestamp <  '2018-09-01'
GROUP BY p.payment_type
ORDER BY total_paid DESC;
