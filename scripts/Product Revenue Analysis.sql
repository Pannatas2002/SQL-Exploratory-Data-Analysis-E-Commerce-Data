WITH date_validation AS (
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
        pt.product_category_name_english AS category,
        ROUND(SUM(p.payment_value), 0) AS total_payment
        FROM dbo.fact_products pro
        LEFT JOIN dbo.dim_product_translation pt
        ON pro.product_category_name = pt.product_category_name
        LEFT JOIN fact_order_items i
        ON i.product_id = pro.product_id
        LEFT JOIN fact_order_payments p
        ON i.order_id = p.order_id
        LEFT JOIN dbo.dim_orders o
        ON i.order_id = o.order_id
    WHERE o.order_status = 'delivered' and i.order_id NOT IN (SELECT date_check from date_validation ) 
          AND pt.product_category_name_english IS NOT NULL
    GROUP BY pt.product_category_name_english
    ORDER BY total_payment DESC