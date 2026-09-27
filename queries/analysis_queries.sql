-- =====================================================================
-- Retail Sales Data Analysis — Analytical Queries
-- Dialect: SQLite (also runs on PostgreSQL/MySQL with minor date tweaks)
-- Author: Hassan Khan
-- Note: "Returned" orders are excluded from revenue analysis.
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. Headline KPIs: revenue, profit, margin, orders, AOV
-- ---------------------------------------------------------------------
SELECT
    ROUND(SUM(oi.sales), 2)                                   AS total_revenue,
    ROUND(SUM(oi.profit), 2)                                  AS total_profit,
    ROUND(SUM(oi.profit) * 100.0 / SUM(oi.sales), 1)         AS profit_margin_pct,
    COUNT(DISTINCT o.order_id)                                AS total_orders,
    ROUND(SUM(oi.sales) / COUNT(DISTINCT o.order_id), 2)     AS avg_order_value
FROM order_items oi
JOIN orders o ON o.order_id = oi.order_id
WHERE o.order_status <> 'Returned';

-- ---------------------------------------------------------------------
-- 2. Monthly revenue trend
-- ---------------------------------------------------------------------
SELECT
    strftime('%Y-%m', o.order_date)  AS year_month,
    ROUND(SUM(oi.sales), 2)          AS revenue,
    ROUND(SUM(oi.profit), 2)         AS profit
FROM order_items oi
JOIN orders o ON o.order_id = oi.order_id
WHERE o.order_status <> 'Returned'
GROUP BY year_month
ORDER BY year_month;

-- ---------------------------------------------------------------------
-- 3. Revenue by category and sub-category
-- ---------------------------------------------------------------------
SELECT
    p.category,
    p.subcategory,
    ROUND(SUM(oi.sales), 2)   AS revenue,
    ROUND(SUM(oi.profit), 2)  AS profit
FROM order_items oi
JOIN orders   o ON o.order_id  = oi.order_id
JOIN products p ON p.product_id = oi.product_id
WHERE o.order_status <> 'Returned'
GROUP BY p.category, p.subcategory
ORDER BY revenue DESC;

-- ---------------------------------------------------------------------
-- 4. Revenue by region (customer geography)
-- ---------------------------------------------------------------------
SELECT
    c.region,
    ROUND(SUM(oi.sales), 2)              AS revenue,
    COUNT(DISTINCT o.order_id)           AS orders
FROM order_items oi
JOIN orders    o ON o.order_id    = oi.order_id
JOIN customers c ON c.customer_id = o.customer_id
WHERE o.order_status <> 'Returned'
GROUP BY c.region
ORDER BY revenue DESC;

-- ---------------------------------------------------------------------
-- 5. Top 10 products by revenue
-- ---------------------------------------------------------------------
SELECT
    p.product_name,
    p.category,
    ROUND(SUM(oi.sales), 2)   AS revenue,
    SUM(oi.quantity)          AS units_sold
FROM order_items oi
JOIN orders   o ON o.order_id  = oi.order_id
JOIN products p ON p.product_id = oi.product_id
WHERE o.order_status <> 'Returned'
GROUP BY p.product_name, p.category
ORDER BY revenue DESC
LIMIT 10;

-- ---------------------------------------------------------------------
-- 6. Top 10 customers by revenue
-- ---------------------------------------------------------------------
SELECT
    c.customer_name,
    c.segment,
    c.region,
    ROUND(SUM(oi.sales), 2)      AS revenue,
    COUNT(DISTINCT o.order_id)   AS orders
FROM order_items oi
JOIN orders    o ON o.order_id    = oi.order_id
JOIN customers c ON c.customer_id = o.customer_id
WHERE o.order_status <> 'Returned'
GROUP BY c.customer_name, c.segment, c.region
ORDER BY revenue DESC
LIMIT 10;

-- ---------------------------------------------------------------------
-- 7. Order status breakdown & return rate
-- ---------------------------------------------------------------------
SELECT
    order_status,
    COUNT(*)                                                        AS orders,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM orders), 1)      AS pct_of_orders
FROM orders
GROUP BY order_status
ORDER BY orders DESC;

-- ---------------------------------------------------------------------
-- 8. Running (cumulative) monthly revenue — WINDOW FUNCTION
-- ---------------------------------------------------------------------
WITH monthly AS (
    SELECT strftime('%Y-%m', o.order_date) AS year_month,
           SUM(oi.sales)                    AS revenue
    FROM order_items oi
    JOIN orders o ON o.order_id = oi.order_id
    WHERE o.order_status <> 'Returned'
    GROUP BY year_month
)
SELECT
    year_month,
    ROUND(revenue, 2)                                                  AS revenue,
    ROUND(SUM(revenue) OVER (ORDER BY year_month), 2)                  AS cumulative_revenue
FROM monthly
ORDER BY year_month;

-- ---------------------------------------------------------------------
-- 9. Rank products within their category — WINDOW FUNCTION
-- ---------------------------------------------------------------------
WITH product_rev AS (
    SELECT p.category, p.product_name, SUM(oi.sales) AS revenue
    FROM order_items oi
    JOIN orders   o ON o.order_id  = oi.order_id
    JOIN products p ON p.product_id = oi.product_id
    WHERE o.order_status <> 'Returned'
    GROUP BY p.category, p.product_name
)
SELECT
    category,
    product_name,
    ROUND(revenue, 2) AS revenue,
    RANK() OVER (PARTITION BY category ORDER BY revenue DESC) AS rank_in_category
FROM product_rev
ORDER BY category, rank_in_category;

-- ---------------------------------------------------------------------
-- 10. Month-over-month revenue growth — LAG WINDOW FUNCTION
-- ---------------------------------------------------------------------
WITH monthly AS (
    SELECT strftime('%Y-%m', o.order_date) AS year_month,
           SUM(oi.sales)                    AS revenue
    FROM order_items oi
    JOIN orders o ON o.order_id = oi.order_id
    WHERE o.order_status <> 'Returned'
    GROUP BY year_month
)
SELECT
    year_month,
    ROUND(revenue, 2) AS revenue,
    ROUND(revenue - LAG(revenue) OVER (ORDER BY year_month), 2)                       AS mom_change,
    ROUND((revenue - LAG(revenue) OVER (ORDER BY year_month))
          * 100.0 / LAG(revenue) OVER (ORDER BY year_month), 1)                       AS mom_growth_pct
FROM monthly
ORDER BY year_month;

-- ---------------------------------------------------------------------
-- 11. Customer value tiers — CTE + CASE segmentation
-- ---------------------------------------------------------------------
WITH cust_rev AS (
    SELECT c.customer_id, c.customer_name,
           SUM(oi.sales)              AS revenue,
           COUNT(DISTINCT o.order_id) AS orders
    FROM order_items oi
    JOIN orders    o ON o.order_id    = oi.order_id
    JOIN customers c ON c.customer_id = o.customer_id
    WHERE o.order_status <> 'Returned'
    GROUP BY c.customer_id, c.customer_name
)
SELECT
    CASE
        WHEN revenue >= 40000 THEN 'A - High value'
        WHEN revenue >= 20000 THEN 'B - Mid value'
        ELSE 'C - Low value'
    END                        AS value_tier,
    COUNT(*)                   AS customers,
    ROUND(SUM(revenue), 2)     AS revenue,
    ROUND(AVG(orders), 1)      AS avg_orders
FROM cust_rev
GROUP BY value_tier
ORDER BY value_tier;

-- ---------------------------------------------------------------------
-- 12. Average discount vs. profit by category (does discounting pay off?)
-- ---------------------------------------------------------------------
SELECT
    p.category,
    ROUND(AVG(oi.discount) * 100, 1)                       AS avg_discount_pct,
    ROUND(SUM(oi.profit) * 100.0 / SUM(oi.sales), 1)      AS profit_margin_pct
FROM order_items oi
JOIN orders   o ON o.order_id  = oi.order_id
JOIN products p ON p.product_id = oi.product_id
WHERE o.order_status <> 'Returned'
GROUP BY p.category
ORDER BY avg_discount_pct DESC;
