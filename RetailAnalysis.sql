-- ============================================================
-- RetailAnalysis.sql
-- Sales Uplift: Strategy Insights from Multi-Region Retail Data
-- ============================================================

-- ----------------------------------------------------------------
-- SETUP: Create and populate the table (SQLite / MySQL compatible)
-- ----------------------------------------------------------------
CREATE TABLE IF NOT EXISTS retail_transactions (
    TransactionID   INTEGER PRIMARY KEY,
    Date            TEXT,
    ProductName     TEXT,
    Category        TEXT,
    Region          TEXT,
    SalesChannel    TEXT,
    Quantity        INTEGER,
    UnitPrice       REAL,
    TotalAmount     REAL,
    PaymentMode     TEXT,
    CustomerID      TEXT
);

-- (Import CSV via your RDBMS tool, e.g., .import in SQLite or LOAD DATA in MySQL)

-- ================================================================
-- QUERY 1: Total sales amount per region for the last quarter (Q2)
-- ================================================================
SELECT
    Region,
    SUM(TotalAmount)                        AS Total_Sales,
    COUNT(TransactionID)                    AS Num_Transactions,
    ROUND(AVG(TotalAmount), 2)              AS Avg_Order_Value
FROM retail_transactions
WHERE Date >= '2024-04-01'
  AND Date <= '2024-06-30'
GROUP BY Region
ORDER BY Total_Sales DESC;

-- ================================================================
-- QUERY 2: Top 5 best-selling products by revenue
-- ================================================================
SELECT
    ProductName,
    Category,
    SUM(TotalAmount)    AS Total_Revenue,
    SUM(Quantity)       AS Units_Sold,
    COUNT(*)            AS Num_Transactions
FROM retail_transactions
GROUP BY ProductName, Category
ORDER BY Total_Revenue DESC
LIMIT 5;

-- ================================================================
-- QUERY 3: Monthly sales trend across all regions
-- ================================================================
SELECT
    STRFTIME('%Y-%m', Date)     AS Month,       -- SQLite syntax
    -- DATE_FORMAT(Date,'%Y-%m') AS Month,       -- MySQL syntax
    Region,
    SUM(TotalAmount)            AS Monthly_Sales,
    COUNT(TransactionID)        AS Transactions
FROM retail_transactions
GROUP BY Month, Region
ORDER BY Month, Region;

-- ================================================================
-- QUERY 4: Region-wise contribution to total sales (%)
-- ================================================================
SELECT
    Region,
    SUM(TotalAmount)                                        AS Region_Sales,
    ROUND(
        SUM(TotalAmount) * 100.0 /
        (SELECT SUM(TotalAmount) FROM retail_transactions),
    2)                                                      AS Pct_Contribution
FROM retail_transactions
GROUP BY Region
ORDER BY Region_Sales DESC;

-- ================================================================
-- QUERY 5: Online vs Offline sales comparison across all months
-- ================================================================
SELECT
    STRFTIME('%Y-%m', Date)     AS Month,
    SalesChannel,
    SUM(TotalAmount)            AS Channel_Sales,
    COUNT(TransactionID)        AS Transactions,
    ROUND(AVG(TotalAmount), 2)  AS Avg_Order_Value
FROM retail_transactions
GROUP BY Month, SalesChannel
ORDER BY Month, SalesChannel;

-- ================================================================
-- QUERY 6: Sales trend by Category (rising / falling)
-- ================================================================
SELECT
    Category,
    STRFTIME('%Y-%m', Date)     AS Month,
    SUM(TotalAmount)            AS Category_Monthly_Sales,
    SUM(Quantity)               AS Units_Sold
FROM retail_transactions
GROUP BY Category, Month
ORDER BY Category, Month;

-- Summary view: first-month vs last-month to identify direction
SELECT
    Category,
    MIN_Month_Sales,
    MAX_Month_Sales,
    CASE
        WHEN MAX_Month_Sales > MIN_Month_Sales THEN 'Rising'
        WHEN MAX_Month_Sales < MIN_Month_Sales THEN 'Falling'
        ELSE 'Stable'
    END AS Trend
FROM (
    SELECT
        Category,
        FIRST_VALUE(SUM(TotalAmount)) OVER (
            PARTITION BY Category ORDER BY STRFTIME('%Y-%m', Date)
            ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
        ) AS MIN_Month_Sales,
        LAST_VALUE(SUM(TotalAmount)) OVER (
            PARTITION BY Category ORDER BY STRFTIME('%Y-%m', Date)
            ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
        ) AS MAX_Month_Sales
    FROM retail_transactions
    GROUP BY Category, STRFTIME('%Y-%m', Date)
) sub
GROUP BY Category;

-- Simpler alternative for MySQL/SQLite:
SELECT
    Category,
    SUM(CASE WHEN STRFTIME('%Y-%m', Date) = '2024-01' THEN TotalAmount ELSE 0 END) AS Jan_Sales,
    SUM(CASE WHEN STRFTIME('%Y-%m', Date) = '2024-02' THEN TotalAmount ELSE 0 END) AS Feb_Sales,
    SUM(CASE WHEN STRFTIME('%Y-%m', Date) = '2024-03' THEN TotalAmount ELSE 0 END) AS Mar_Sales,
    SUM(CASE WHEN STRFTIME('%Y-%m', Date) = '2024-04' THEN TotalAmount ELSE 0 END) AS Apr_Sales,
    SUM(CASE WHEN STRFTIME('%Y-%m', Date) = '2024-05' THEN TotalAmount ELSE 0 END) AS May_Sales,
    SUM(CASE WHEN STRFTIME('%Y-%m', Date) = '2024-06' THEN TotalAmount ELSE 0 END) AS Jun_Sales
FROM retail_transactions
GROUP BY Category
ORDER BY Category;

-- ================================================================
-- QUERY 7: Customers who purchased more than 10 times
-- ================================================================
SELECT
    CustomerID,
    COUNT(TransactionID)        AS Purchase_Count,
    SUM(TotalAmount)            AS Total_Spent,
    ROUND(AVG(TotalAmount), 2)  AS Avg_Order_Value,
    MIN(Date)                   AS First_Purchase,
    MAX(Date)                   AS Last_Purchase
FROM retail_transactions
GROUP BY CustomerID
HAVING COUNT(TransactionID) > 10
ORDER BY Purchase_Count DESC;

-- ================================================================
-- BONUS: KPI Summary (for Dashboard cards)
-- ================================================================
SELECT
    SUM(TotalAmount)                        AS Total_Sales,
    COUNT(TransactionID)                    AS Total_Transactions,
    COUNT(DISTINCT CustomerID)              AS Unique_Customers,
    ROUND(AVG(TotalAmount), 2)              AS Avg_Order_Value,
    SUM(Quantity)                           AS Total_Units_Sold
FROM retail_transactions;

