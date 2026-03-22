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
,rfm_table AS (
SELECT
c.customer_unique_id,
MIN(o.order_purchase_timestamp) AS first_order,
MAX(o.order_purchase_timestamp) AS last_order,
DATEDIFF(DAY, MAX(o.order_purchase_timestamp), (SELECT MAX(order_purchase_timestamp) FROM dbo.dim_orders)) AS recency,
COUNT(DISTINCT o.order_id) AS frequency,
SUM(ROUND(p.payment_value, 0)) AS monetary
FROM dbo.dim_customers c
LEFT JOIN dbo.dim_orders o
ON c.customer_id = o.customer_id
INNER JOIN dbo.fact_order_payments p
ON o.order_id = p.order_id
WHERE order_status = 'delivered' and o.order_id NOT IN (SELECT date_check from date_validation)
GROUP BY c.customer_unique_id
)

,rfm_score AS(
SELECT
NTILE(5) OVER (ORDER BY recency DESC) AS r_score,
NTILE(5) OVER (ORDER BY frequency) AS f_score,
NTILE(5) OVER (ORDER BY monetary) AS m_score
FROM rfm_table)
SELECT
    segment,
    COUNT(segment) AS total_customers,
    CAST(COUNT(segment) * 100.0 / SUM(COUNT(segment)) OVER() AS DECIMAL(5,2)) AS percentage
FROM(
    SELECT
        CASE 
        WHEN r_score = 5 AND f_score >= 4 THEN 'Champions'
        WHEN r_score >= 4 AND f_score >= 3 THEN 'Loyal'
        WHEN r_score >= 3 AND f_score <= 2 THEN 'Potential'
        WHEN r_score <= 2 AND f_score <= 2 THEN 'At Risk'
        ELSE 'Others'
    END AS segment
    FROM rfm_score)t
GROUP BY segment