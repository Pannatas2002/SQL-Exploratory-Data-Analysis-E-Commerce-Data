--- ROW 99441 rows 
SELECT
order_id,
customer_id,
order_status,
order_purchase_timestamp,
order_approved_at,
order_delivered_carrier_date,
order_delivered_customer_date,
order_estimated_delivery_date
FROM dbo.dim_orders;

---Check Duplicate (No Duplicates)
SELECT
COUNT(*) - COUNT(DISTINCT order_id) AS duplicate_check
FROM dbo.dim_orders;

---Check Null where order_status is Delivered
SELECT
COUNT(*) AS total_delivered,
COUNT(*) - COUNT(order_approved_at) AS null_approve,
COUNT(*) - COUNT(order_delivered_carrier_date) AS null_carrier,
COUNT(*) - COUNT(order_delivered_customer_date) AS null_customer
FROM dbo.dim_orders
WHERE order_status = 'delivered';

---Check order Status
SELECT
order_status,
Count(order_status) as amount
FROM dbo.dim_orders
GROUP by order_status;

---Check Date Validation
SELECT
*
FROM dbo.dim_orders
WHERE(
    order_delivered_carrier_date > order_delivered_customer_date
    OR order_approved_at > order_delivered_customer_date
    OR order_approved_at > order_delivered_carrier_date
    OR order_purchase_timestamp > order_approved_at
    OR order_purchase_timestamp > order_delivered_carrier_date
    OR order_purchase_timestamp > order_delivered_customer_date
)
AND order_status = 'delivered'

---Total amount by order_id
select
order_id,
ROUND(SUM(payment_value), 2) AS total_payment
from dbo.fact_order_payments
GROUP BY order_id