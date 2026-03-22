WITH date_validation as (
SELECT
order_id AS date_check
FROM dbo.dim_orders
WHERE(
    order_delivered_carrier_date > order_delivered_customer_date
    OR order_approved_at > order_delivered_customer_date
    OR order_approved_at > order_delivered_carrier_date
    OR order_purchase_timestamp > order_approved_at
    OR order_purchase_timestamp > order_delivered_carrier_date
    OR order_purchase_timestamp > order_delivered_customer_date
    OR order_approved_at IS NULL
    OR order_delivered_carrier_date IS NULL
    OR order_delivered_customer_date IS NULL
)
AND order_status = 'delivered')

SELECT
AVG(approving_time) AS avg_approving_time,
AVG(time_until_carrier) AS avg_fulfillment_time,
AVG(delivering_time) AS avg_delivering_time,
CONCAT(ROUND(COUNT(CASE WHEN delivery_performance IN ('Faster', 'On-time') THEN 1 END) * 100 / COUNT(*), 2),'%') AS on_time_rate 
FROM(
SELECT
   order_id,
   order_status,
   DATEDIFF(DAY, order_purchase_timestamp, order_approved_at) AS approving_time,
   DATEDIFF(DAY, order_approved_at, order_delivered_carrier_date) AS time_until_carrier,
   DATEDIFF(DAY, order_delivered_carrier_date, order_delivered_customer_date) AS delivering_time,
   CASE WHEN order_delivered_customer_date < order_estimated_delivery_date THEN 'Faster'
        WHEN order_delivered_customer_date = order_estimated_delivery_date THEN 'On-time'
        ELSE 'Slower'
   END delivery_performance
FROM dbo.dim_orders
WHERE order_status = 'delivered' and order_id NOT IN (SELECT date_check from date_validation )
)t