-- creating Database
DROP DATABASE IF EXISTS toys;
CREATE DATABASE toys;

use toys;

-- loading datasets
LOAD DATA LOCAL INFILE 'E:/arpit/study/excel/Maven Toys Data/date.csv'
INTO TABLE calendar
FIELDS TERMINATED BY ',' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(@col1)
SET date_value = STR_TO_DATE(@col1, '%d-%m-%Y');



-- Count Number Of Rows
SELECT 
    COUNT(*)
FROM toys.sales;



-- Clean Product_Price column
-- Remove '$' and convert to INT           
UPDATE toys.products 
SET 
    Product_Price = REPLACE(Product_Price, '$', '');

ALTER TABLE toys.products
MODIFY Product_Price INT;
            
            
            
-- Calculate total sales
SELECT 
    SUM(s.Units * p.Product_Price) AS sales
FROM toys.sales s
LEFT JOIN toys.products p 
	ON s.Product_ID = p.Product_ID;
            

            
-- Sales grouped by product category
-- Including percentage contribution and order count
SELECT 
	p.Product_Category,
    SUM(s.Units*p.Product_Price) as sales,
    CONCAT(ROUND(100*SUM(s.Units*p.Product_Price) / SUM(SUM(s.Units*p.Product_Price)) OVER(),2),'%')  as sale_per,
    COUNT(s.Sale_ID) as orders,
    CONCAT(ROUND(100*COUNT(s.Sale_ID) / SUM(COUNT(s.Sale_ID)) OVER(),2),'%')  as order_per
    
	FROM toys.sales s
    LEFT JOIN toys.products p
		ON s.Product_ID = p.Product_ID
	GROUP BY p.Product_Category 
    ORDER BY sales DESC;
    


-- Clean Product_Price column
-- Remove '$' and convert to INT
UPDATE toys.products 
SET 
    Product_Cost = REPLACE(Product_Cost, '$', '');

ALTER TABLE toys.products
MODIFY Product_Cost INT;



-- Calculate total profit
SELECT 
    SUM((s.Units * p.Product_Price) - (s.Units * p.Product_Cost)) AS profit
FROM
    toys.sales s
        LEFT JOIN
    toys.products p ON s.Product_ID = p.Product_ID;
    
    
    
-- Total profit by product category
SELECT
	p.Product_Category as category,
    SUM((s.Units*p.Product_Price) - (s.Units*p.Product_Cost)) as profit,
    CONCAT(ROUND(100*SUM((s.Units*p.Product_Price) - (s.Units*p.Product_Cost)) / SUM(SUM((s.Units*p.Product_Price) - (s.Units*p.Product_Cost)) ) OVER() ,2 ),'%') as per
FROM toys.sales s 
LEFT JOIN toys.products p
	ON s.Product_ID = p.Product_ID
GROUP BY category;



-- Monthly Revenue Trend (Total Sales Over Time)
-- Including Month-over-Month (MoM) growth

WITH a2 as (
	SELECT 
			MONTHNAME(s.Date) as month_name,
            MONTH(s.DATE) as month_num,
			SUM(s.Units*p.Product_Price) as sales
	FROM toys.sales s
	LEFT JOIN toys.products p
			ON s.Product_ID = p.Product_ID
	GROUP BY  month_name, month_num
	ORDER BY month_num
    )

SELECT 
	*,
    CONCAT(
			ROUND(
				(100*(sales - LAG(sales) OVER(ORDER BY month_num)))
                /LAG(sales) OVER(ORDER BY month_num),
                2
		),
		'%'
	) as mom
FROM a2;



-- Sales aggregated by month and year
SELECT 
	DATE_FORMAT(s.Date, '%M-%y') as mon_yr,
    MONTH(s.Date) as mon_num,
	SUM( s.Units * p.Product_Price ) as sales 
FROM toys.sales s 
LEFT JOIN toys.products p
	ON s.Product_ID = p.Product_ID
GROUP BY mon_yr, mon_num
ORDER BY mon_num;



-- Top 10 products by sales and Average Order Value (AOV)
SELECT
	p.Product_Name as Top_Selling_Product,
	SUM(s.Units * p.Product_Price ) as sales,
    ROUND(SUM(s.Units * p.Product_Price ) / COUNT(DISTINCT s.Sale_ID),2) as AOV
FROM toys.sales s
LEFT JOIN toys.products p
	ON s.Product_ID = p.Product_ID
GROUP BY Top_Selling_Product
ORDER BY sales ;


--  products by sales and orders
SELECT
	p.Product_Name as Top_Selling_Product,
	SUM(s.Units * p.Product_Price ) as sales,
    SUM(s.Units ) as units
FROM toys.sales s
LEFT JOIN toys.products p
	ON s.Product_ID = p.Product_ID
GROUP BY Top_Selling_Product
ORDER BY units DESC;



-- Total number of orders per month and year for each product category
SELECT 
	p.Product_Category as product_category,
	EXTRACT(MONTH FROM s.Date) as mon,
    EXTRACT(YEAR FROM s.Date) as yr,
    COUNT(s.Sale_ID) as orders
FROM toys.sales s
LEFT JOIN toys.products p 
	ON s.Product_ID = p.Product_ID
GROUP BY mon, yr, product_category
ORDER BY mon , product_category ,yr;



-- Sales and profit by product category
SELECT
	p.Product_Category as cat,
	SUM(s.Units * p.Product_Price) as sales,
    SUM((s.Units * p.Product_Price) - (s.Units * p.Product_Cost)) as profit
FROM toys.sales s
LEFT JOIN toys.products p 
	ON s.Product_ID = p.Product_ID
GROUP BY cat
ORDER BY sales;



-- Percentage of sales and profit by product category
WITH tab as 
	(
		SELECT
			p.Product_Category as product_category,
			SUM(s.Units * p.Product_Price) as sales,
			SUM((s.Units * p.Product_Price) - (s.Units * p.Product_Cost)) as profit
		FROM toys.sales s
		LEFT JOIN toys.products p 
			ON s.Product_ID = p.Product_ID
		GROUP BY product_category
		ORDER BY sales
	)

SELECT
	*,
    CONCAT(ROUND((100*sales) / SUM(sales) OVER(),2),'%') as sales_perc,
    CONCAT(ROUND((100*profit)/SUM(profit) OVER(),2),'%') as profit_perc
FROM tab
ORDER BY sales DESC;



-- Profiit Margin By Product Category
WITH pm as(
		SELECT
			p.Product_Category as cat,
			SUM(s.Units * p.Product_Price) as sales,
			SUM((s.Units * p.Product_Price) - (s.Units * p.Product_Cost)) as profit
		FROM toys.sales s
		LEFT JOIN toys.products p 
			ON s.Product_ID = p.Product_ID
		GROUP BY cat
		ORDER BY sales
        )
SELECT 
	*,
    ROUND((100*profit)/sales,2) as profit_margin
FROM pm
ORDER BY profit_margin DESC;



-- Store Location performance: Revenue, Profit, Orders, and AOV
SELECT
	store.Store_Location as Store_location,
    SUM(sales.Units * product.Product_Price) as sales,
    SUM((sales.Units * product.Product_Price) - (sales.Units*product.Product_Cost)) as profit,
    COUNT(DISTINCT sales.Sale_ID) as orders,
    ROUND((SUM(sales.Units * product.Product_Price) / COUNT(DISTINCT sales.Sale_ID)),2) as AOV
FROM toys.sales sales
LEFT JOIN toys.stores store
	ON sales.Store_ID = store.Store_ID
    LEFT JOIN toys.products product
		ON sales.Product_ID = product.Product_ID
GROUP BY Store_location
ORDER BY sales DESC;



-- Store Location trend per year
WITH loc_yr as (
	SELECT
		st.Store_Location,
		EXTRACT(YEAR FROM s.Date) as yr,
		SUM(s.Units * p.Product_Price) as sales
	FROM toys.sales s
	LEFT JOIN toys.products p
		ON s.Product_ID = p.Product_ID
		LEFT JOIN toys.stores st
			ON st.Store_ID = s.Store_ID
	GROUP BY st.Store_Location,yr
	ORDER BY  st.Store_Location ,yr
    )
    SELECT 
		*,
        CONCAT(
			ROUND(
			(100* (sales-LAG(sales) OVER(PARTITION BY Store_Location)) )/ (LAG(sales) OVER(PARTITION BY Store_Location)),
			2),
        '%') as diff
    FROM loc_yr;



-- Store Location Trend per month-year
SELECT
	st.Store_Location,
    EXTRACT(MONTH FROM s.Date) as mon,
    EXTRACT(YEAR FROM s.Date) as yr,
    SUM(s.Units * p.Product_Price) as sales
FROM toys.sales s
LEFT JOIN toys.products p
	ON s.Product_ID = p.Product_ID
	LEFT JOIN toys.stores st
		ON st.Store_ID = s.Store_ID
GROUP BY st.Store_Location,mon,yr
ORDER BY  mon,st.Store_Location ,yr;



-- Inventory status by product
SELECT
	product.Product_Name as products,
	SUM(inventory.Stock_On_Hand) as stock
FROM toys.products product
LEFT JOIN toys.inventory inventory
	ON product.Product_ID = inventory.Product_ID
GROUP BY products
ORDER BY stock;


-- Inventory turnover rate
-- (Optimized query to avoid server crash)

--  SELECT
-- 	product.Product_Name as products,
-- 	SUM(sale.Units) as unit_sold,
--     SUM(sale.Units)/ inventory.Stock_On_Hand as  turnover_rate
-- FROM toys.sales sale
-- LEFT JOIN toys.inventory inventory
-- 	ON sale.Product_ID = inventory.Product_ID
--     LEFT JOIN toys.products product
-- 		ON sale.Product_ID = product.Product_ID
-- GROUP BY products, inventory.Stock_On_Hand;  


-- SELECT 
--     p.Product_name,
--     s.total_units / i.Stock_On_Hand AS turnover_rate
-- FROM toys.products p
-- JOIN toys.inventory i ON p.Product_ID = i.Product_ID
-- JOIN (
--     SELECT Product_ID, SUM(Units) AS total_units
--     FROM toys.sales
--     GROUP BY Product_ID
-- ) s ON p.Product_ID = s.Product_ID
-- ORDER BY turnover_rate DESC;



-- Store-wise performance across sales and profit
SELECT
	st.Store_Name,
    SUM(s.Units * p.Product_Price) as sales,
    SUM((s.Units * p.Product_Price) - (s.Units * p.Product_Cost)) as profit
FROM toys.sales s
LEFT JOIN toys.stores st
	ON s.Store_ID = st.Store_ID
    LEFT JOIN toys.products p
		ON s.Product_ID = p.Product_ID
GROUP BY st.Store_Name
ORDER BY sales DESC;

