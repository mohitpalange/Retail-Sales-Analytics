/* ============================================================
   RETAIL SALES ANALYTICS PROJECT
   Tools: MySQL | Excel | Power Query | Power BI

   Reporting Period: April 2025 - August 2026

   Purpose:
   Analyze delivered-order sales performance, profitability
   and monthly sales trends.
   ============================================================ */


/* ============================================================
   1. REPORTING PERIOD & TOTAL ORDERS
   ============================================================ */

SELECT
    MIN(Order_Date) AS Start_Date,
    MAX(Order_Date) AS End_Date,
    COUNT(*) AS Total_Orders
FROM orders_clean;


/* ============================================================
   2. ORDER STATUS DISTRIBUTION
   ============================================================ */

SELECT
    Order_Status,
    COUNT(*) AS Order_Count
FROM orders_clean
GROUP BY Order_Status
ORDER BY Order_Count DESC;


/* ============================================================
   3. EXECUTIVE SALES KPIs
   Business Rule:
   Only Delivered orders are included in recognized sales.
   ============================================================ */

SELECT
    COUNT(DISTINCT o.Order_ID) AS Delivered_Orders,

    SUM(ol.Quantity) AS Units_Sold,

    ROUND(SUM(ol.Net_Sales), 2) AS Net_Sales,

    ROUND(SUM(ol.Gross_Margin), 2) AS Gross_Margin,

    ROUND(
        SUM(ol.Gross_Margin) /
        SUM(ol.Net_Sales) * 100,
        2
    ) AS Gross_Margin_Pct,

    ROUND(
        SUM(ol.Net_Sales) /
        COUNT(DISTINCT o.Order_ID),
        2
    ) AS Avg_Order_Value

FROM orders_clean o
JOIN order_lines_clean ol
    ON o.Order_ID = ol.Order_ID

WHERE o.Order_Status = 'Delivered';


/* ============================================================
   4. MONTHLY SALES PERFORMANCE
   ============================================================ */

SELECT
    YEAR(o.Order_Date) AS Sales_Year,
    MONTH(o.Order_Date) AS Sales_Month,

    COUNT(DISTINCT o.Order_ID) AS Total_Orders,

    SUM(ol.Quantity) AS Units_Sold,

    ROUND(SUM(ol.Net_Sales), 2) AS Net_Sales,

    ROUND(SUM(ol.Gross_Margin), 2) AS Gross_Margin

FROM orders_clean o
JOIN order_lines_clean ol
    ON o.Order_ID = ol.Order_ID

WHERE o.Order_Status = 'Delivered'

GROUP BY
    YEAR(o.Order_Date),
    MONTH(o.Order_Date)

ORDER BY
    Sales_Year,
    Sales_Month;


/* ============================================================
   5. MONTH-OVER-MONTH SALES GROWTH
   Concepts demonstrated:
   CTE + LAG Window Function
   ============================================================ */

WITH Monthly_Sales AS
(
    SELECT
        DATE_FORMAT(o.Order_Date, '%Y-%m') AS Sales_Month,
        SUM(ol.Net_Sales) AS Net_Sales

    FROM orders_clean o

    JOIN order_lines_clean ol
        ON o.Order_ID = ol.Order_ID

    WHERE o.Order_Status = 'Delivered'

    GROUP BY
        DATE_FORMAT(o.Order_Date, '%Y-%m')
),

Sales_With_Previous AS
(
    SELECT
        Sales_Month,
        Net_Sales,

        LAG(Net_Sales) OVER (
            ORDER BY Sales_Month
        ) AS Previous_Month_Sales

    FROM Monthly_Sales
)

SELECT
    Sales_Month,

    ROUND(Net_Sales, 2) AS Net_Sales,

    ROUND(
        Previous_Month_Sales,
        2
    ) AS Previous_Month_Sales,

    ROUND(
        (Net_Sales - Previous_Month_Sales)
        / Previous_Month_Sales * 100,
        2
    ) AS MoM_Growth_Pct

FROM Sales_With_Previous

ORDER BY Sales_Month;
