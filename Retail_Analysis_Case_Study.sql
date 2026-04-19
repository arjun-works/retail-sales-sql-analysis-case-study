ALTER TABLE product_inventory 
RENAME COLUMN `ï»¿ProductID` TO ProductID;
ALTER TABLE customer_profiles 
RENAME COLUMN `ï»¿CustomerID` TO CustomerID;
ALTER TABLE sales_transaction 
RENAME COLUMN `ï»¿TransactionID` TO TransactionID;

/*
Write a query to identify the number of duplicates in "sales_transaction" table. Also, create a separate table containing the unique values and remove the the original table from the databases and replace the name of the new table with the original name.
*/
SELECT TransactionID, COUNT(*)
FROM Sales_transaction
GROUP BY TransactionID
HAVING COUNT(*) > 1;

CREATE TABLE unique_sales AS
SELECT DISTINCT * FROM Sales_transaction;
DROP TABLE Sales_transaction;
ALTER TABLE unique_sales RENAME TO Sales_transaction;

SELECT * FROM Sales_transaction;

/*
Write a query to identify the discrepancies in the price of the same product in "sales_transaction" and "product_inventory" tables. Also, update those discrepancies to match the price in both the tables.
*/

SELECT 
    s.TransactionID, 
    s.Price AS TransactionPrice, 
    p.Price AS InventoryPrice
FROM sales_transaction s
JOIN product_inventory p ON s.ProductID = p.ProductID
WHERE s.Price <> p.Price;

UPDATE sales_transaction
SET Price = (
    SELECT Price 
    FROM product_inventory 
    WHERE product_inventory.ProductID = sales_transaction.ProductID
)
WHERE ProductID IN (
    SELECT ProductID 
    FROM product_inventory
);

SELECT * FROM sales_transaction;

/*
Write a SQL query to identify the null values in the dataset and replace those by “Unknown”.
*/

SELECT COUNT(*) 
FROM customer_profiles 
WHERE Location IS NULL;

UPDATE customer_profiles
SET Location = 'Unknown'
WHERE Location IS NULL;

SELECT * FROM customer_profiles;

/*
Write a SQL query to clean the DATE column in the dataset.
*/
CREATE TABLE Sales_transaction_temp AS
SELECT *, 
       CAST(TransactionDate AS DATE) AS TransactionDate_updated
FROM Sales_transaction;

DROP TABLE Sales_transaction;
ALTER TABLE Sales_transaction_temp RENAME TO Sales_transaction;
SELECT * FROM Sales_transaction;

/*
Write a SQL query to summarize the total sales and quantities sold per product by the company.
*/
SELECT 
    ProductID, 
    SUM(QuantityPurchased) AS TotalUnitsSold, 
    SUM(Price * QuantityPurchased) AS TotalSales
FROM Sales_transaction
GROUP BY ProductID
ORDER BY TotalSales DESC;

/*
Write a SQL query to count the number of transactions per customer to understand purchase frequency.
*/

SELECT 
    CustomerID, 
    COUNT(*) AS NumberOfTransactions
FROM Sales_transaction
GROUP BY CustomerID
ORDER BY NumberOfTransactions DESC;

/*
Write a SQL query to evaluate the performance of the product categories based on the total sales which help us understand the product categories which needs to be promoted in the marketing campaigns */
SELECT 
    p.Category, 
    SUM(s.QuantityPurchased) AS TotalUnitsSold, 
    SUM(s.Price * s.QuantityPurchased) AS TotalSales
FROM Sales_transaction s
JOIN product_inventory p ON s.ProductID = p.ProductID
GROUP BY p.Category
ORDER BY TotalSales DESC;

/*
Write a SQL query to find the top 10 products with the highest total sales revenue from the sales transactions. This will help the company to identify the High sales products which needs to be focused to increase the revenue of the company. */

SELECT 
    ProductID, 
    SUM(Price * QuantityPurchased) AS TotalRevenue
FROM Sales_transaction
GROUP BY ProductID
ORDER BY TotalRevenue DESC
LIMIT 10;

/*
Write a SQL query to find the ten products with the least amount of units sold from the sales transactions, provided that at least one unit was sold for those products.
*/

SELECT 
    ProductID, 
    SUM(QuantityPurchased) AS TotalUnitsSold
FROM Sales_transaction
GROUP BY ProductID
HAVING TotalUnitsSold >= 1
ORDER BY TotalUnitsSold ASC
LIMIT 10;

/*
Write a SQL query to identify the sales trend to understand the revenue pattern of the company.
*/

SELECT 
    DATE(TransactionDate) AS DateofTrans, 
    COUNT(*) AS Transaction_count, 
    SUM(QuantityPurchased) AS TotalUnitsSold, 
    ROUND(SUM(Price * QuantityPurchased), 2) AS TotalSales
FROM Sales_transaction
GROUP BY DateofTrans
ORDER BY DateofTrans DESC;

/*
Write a SQL query to understand the month on month growth rate of sales of the company which will help understand the growth trend of the company.
*/

WITH MonthlySales AS (
    SELECT 
        MONTH(TransactionDate) AS month,
        ROUND(SUM(Price * QuantityPurchased), 2) AS total_sales
    FROM sales_transaction
    GROUP BY MONTH(TransactionDate)
),
GrowthCalc AS (
    SELECT 
        month,
        total_sales,
        LAG(total_sales) OVER (ORDER BY month) AS previous_month_sales
    FROM MonthlySales
)
SELECT 
    month,
    total_sales,
    previous_month_sales,
    ROUND(((total_sales - previous_month_sales) / previous_month_sales) * 100, 2) AS mom_growth_percentage
FROM GrowthCalc
ORDER BY month;

/*
Write a SQL query that describes the number of transaction along with the total amount spent by each customer which are on the higher side and will help us understand the customers who are the high frequency purchase customers in the company.
*/

SELECT 
    CustomerID, 
    COUNT(*) AS NumberOfTransactions, 
    SUM(Price * QuantityPurchased) AS TotalSpent
FROM sales_transaction
GROUP BY CustomerID
HAVING NumberOfTransactions > 10 AND TotalSpent > 1000
ORDER BY TotalSpent DESC;

/*
Write a SQL query that describes the number of transaction along with the total amount spent by each customer, which will help us understand the customers who are occasional customers or have low purchase frequency in the company. */

SELECT 
    CustomerID, 
    COUNT(*) AS NumberOfTransactions, 
    SUM(Price * QuantityPurchased) AS TotalSpent
FROM Sales_transaction
GROUP BY CustomerID
HAVING NumberOfTransactions <= 2
ORDER BY NumberOfTransactions ASC, TotalSpent DESC;

/*
Write a SQL query that describes the total number of purchases made by each customer against each productID to understand the repeat customers in the company. */

SELECT 
    CustomerID, 
    ProductID, 
    COUNT(*) AS TimesPurchased
FROM Sales_transaction
GROUP BY CustomerID, ProductID
HAVING TimesPurchased > 1
ORDER BY TimesPurchased DESC;

/*
Write a SQL query that describes the duration between the first and the last purchase of the customer in that particular company to understand the loyalty of the customer.
*/
SELECT 
    CustomerID, 
    MIN(DATE(TransactionDate)) AS FirstPurchase, 
    MAX(DATE(TransactionDate)) AS LastPurchase, 
    DATEDIFF(MAX(DATE(TransactionDate)), MIN(DATE(TransactionDate))) AS DaysBetweenPurchases
FROM Sales_transaction
GROUP BY CustomerID
HAVING DaysBetweenPurchases > 0
ORDER BY DaysBetweenPurchases DESC;

/*
Write an SQL query that segments customers based on the total quantity of products they have purchased. Also, count the number of customers in each segment which will help us target a particular segment for marketing.
*/
DROP TABLE customer_segment;
CREATE TABLE customer_segment AS 
with cust_base as (
SELECT c.CustomerID, 
	sum(s.QuantityPurchased) total_qty
From sales_transaction s
LEFT JOIN customer_profiles c 
	on s.CustomerID = c.CustomerID
      group by 1
      ) 
  
select 
	CustomerID, 
    CASE WHEN total_qty between 1 and 10 then 'Low' 
    WHEN total_qty between 11 and 30 then 'Med'
    WHEN total_qty > 30 then 'High' 
    else 'None' end as CustomerSegment 
from cust_base;
select CustomerSegment, count(*)
from customer_segment
group by 1;


