select * from my_data;

---- Objective #14 Identify the top 5 most valuable customers using a composite score that combines three key metrics: (SQL)

with My_View as
(select
	CustomerID,
    round((sum(Sale_Price)* 0.5) + (count(OrderID)* 0.3) + (avg(sale_price)* 0.2),0) as "Composite_Score"
from my_data
group by CustomerID
order by 2 desc),

Second_View as
(select
	*,
    dense_rank() over(order by Composite_Score desc) as "Ranking"
from My_View)

select
	distinct CustomerID,
    Composite_Score
from Second_View
where Ranking = 1;

--- Objective 15) Calculate the month-over-month growth rate in total revenue across the entire dataset. (SQL)

WITH MonthlyRevenue AS (
    SELECT
        DATE_FORMAT(OrderDate, '%m') AS month,
        SUM(Sale_Price) AS total_revenue
    FROM
        my_data
    GROUP BY
        DATE_FORMAT(OrderDate, '%m')
),
RevenueWithLag AS (
    SELECT
        month,
        total_revenue,
        LAG(total_revenue) OVER (ORDER BY month) AS previous_revenue
    FROM
        MonthlyRevenue
)
SELECT
    month,
    total_revenue,
    previous_revenue,
    CASE 
        WHEN previous_revenue IS NOT NULL THEN 
            concat(round(((total_revenue - previous_revenue) / previous_revenue * 100),2),"%")
        ELSE 
            NULL
    END AS month_over_month_growth_rate
FROM
    RevenueWithLag;


--- Objective 17) Update the orders table to apply a 15% discount on the `Sale Price` for orders placed by customers who have made at least 10 orders. (SQL)

UPDATE my_data
SET Sale_Price = Sale_Price * 0.85
WHERE CustomerID IN (
    SELECT CustomerID
    FROM my_data
    GROUP BY CustomerID
    HAVING COUNT(*) >= 10
);

--- Objective 18) Calculate the average number of days between consecutive orders for customers who have placed at least five orders. (SQL)

WITH RankedOrders AS (
    SELECT
        CustomerID,
        OrderDate,
        ROW_NUMBER() OVER (PARTITION BY CustomerID ORDER BY OrderDate) AS OrderRank
    FROM my_data
),
OrderDifferences AS (
    SELECT
        ro1.CustomerID,
        DATEDIFF(ro2.OrderDate, ro1.OrderDate) AS DaysBetween
    FROM RankedOrders ro1
    JOIN RankedOrders ro2
        ON ro1.CustomerID = ro2.CustomerID
        AND ro1.OrderRank = ro2.OrderRank - 1
),
EligibleCustomers AS (
    SELECT
        CustomerID
    FROM my_data
    GROUP BY CustomerID
    HAVING COUNT(OrderID) >= 5
)
SELECT 
    od.CustomerID,
    AVG(od.DaysBetween) AS AvgDaysBetween
FROM OrderDifferences od
JOIN EligibleCustomers ec
    ON od.CustomerID = ec.CustomerID
GROUP BY od.CustomerID;

--- Objective 19) Identify customers who have generated revenue that is more than 30% higher than the average revenue per customer. (SQL)

select distinct CustomerID from my_data 
group by CustomerID
having sum(Sale_Price) > 
(0.3 * (select avg(Sale_Price) from my_data));

--- Objective 20) Determine the top 3 product categories that have shown the highest increase in sales over the past year compared to the previous year. (SQL)
with 2019_Revenue as
(Select
	Product_Category,
    sum(Sale_Price) as Revenue_2019
from my_data
where year(OrderDate) = 2019
group by 1),

2020_Revenue as
(Select
	Product_Category,
    sum(Sale_Price) as Revenue_2020
from my_data
where year(OrderDate) = 2020
group by 1)

select
	a.Product_Category,
    a.Revenue_2019,
    b.Revenue_2020,
    (b.Revenue_2020 - a.Revenue_2019) as "Increase_in_Sales"
from 2019_Revenue as a
join 2020_Revenue as b
on a.Product_Category = b.Product_Category
order by Increase_in_Sales desc
limit 3

