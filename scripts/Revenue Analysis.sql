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
    order_year AS year,
    order_month AS month,
    ROUND(SUM(total_payment), 2) AS total_sales_monthly
FROM(
    SELECT
        o.order_id,
        YEAR(o.order_purchase_timestamp) AS order_year,
        MONTH(o.order_purchase_timestamp) AS order_month,
        p.total_payment
    FROM dbo.dim_orders o
    LEFT JOIN (select
		           order_id,
		           ROUND(SUM(payment_value), 2) AS total_payment
		       from dbo.fact_order_payments
	           GROUP BY order_id) p
    ON o.order_id = p.order_id
    WHERE order_status = 'delivered' and o.order_id NOT IN (SELECT date_check from date_validation ) AND total_payment IS NOT NULL)t
GROUP BY order_year, order_month
ORDER BY order_year, order_month