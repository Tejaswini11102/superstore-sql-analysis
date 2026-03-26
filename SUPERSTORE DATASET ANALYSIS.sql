CREATE TABLE IF NOT EXISTS orders (
    row_id INT,
    order_id TEXT,
    order_date DATE,
    ship_date DATE,
    ship_mode TEXT,
    customer_id TEXT,
    customer_name TEXT,
    segment TEXT,
    country TEXT,
    city TEXT,
    state TEXT,
    postal_code TEXT,
    region TEXT,
    product_id TEXT,
    category TEXT,
    sub_category TEXT,
    product_name TEXT,
    sales NUMERIC,
    quantity INT,
    discount NUMERIC,
    profit NUMERIC
);

COPY orders 
FROM 'C:\Users\DELL\Desktop\Sales clean.csv' 
WITH CSV HEADER;

SELECT * FROM orders;

--LEVEL 1:BASIC ANALYSIS--
--TOTAL SALES--
SELECT SUM(sales) AS total_sales
FROM orders;

--TOTAL PROFIT--
SELECT SUM(profit) AS total_profit
FROM orders;

--TOTAL NUMBERS OF ORDERS--
SELECT COUNT(DISTINCT order_id) AS total_number_of_orders
FROM orders;

--TOTAL QUANTITY SOLD--
SELECT SUM(quantity) AS total_quantity
FROM orders;

--SALES BY REGION--
SELECT region, SUM(sales) AS total_sales
FROM orders
GROUP BY region
ORDER BY total_sales DESC;

--SALES BY CATEGORY--
SELECT category, SUM(sales) AS total_sales
FROM orders
GROUP BY category
ORDER BY total_sales DESC;

--AVERAGE SALES PER ORDER--
SELECT AVG(total)
FROM (
    SELECT order_id, SUM(sales) AS total
    FROM orders
    GROUP BY order_id
) sub;

--NUMBER OF CUSTOMERS--
SELECT COUNT(DISTINCT customer_id) AS number_of_customers
FROM orders;

--HIGHEST SINGLE ORDER VALUE--
SELECT order_id, SUM(sales) AS total_sales
FROM orders
GROUP BY order_id
ORDER BY total_sales DESC LIMIT 1;

--LOWEST PROFIT--
SELECT min(profit) AS lowest_profit
FROM orders
ORDER BY lowest_profit;

--TOTAL DISCOUNT--
SELECT ROUND(AVG(discount),2) AS total_discount
FROM orders;

--LEVEL 2:INTERMEDIATE ANALYSIS--
--TOP 5 CUSTOMERS BY REVENUE--
SELECT customer_name, SUM(sales) AS total_revenue
FROM orders
GROUP BY customer_name
ORDER BY total_revenue DESC LIMIT 5;

--TOP 10 PRODUCTS BY SALES--
SELECT product_name, SUM(sales) AS total_revenue
FROM orders
GROUP BY product_name
ORDER BY total_revenue DESC LIMIT 10;

--REGION WISE PROFIT--
SELECT region, SUM(profit) AS total_profit
FROM orders
GROUP BY region
ORDER BY total_profit DESC;

--MONTHLY SALES TREND--
SELECT 
      EXTRACT(MONTH FROM order_date) AS month,
      SUM(sales) AS total_sales
FROM orders
GROUP BY month
ORDER BY month;

--AVERAGE PROFIT PER CATEGORY--
SELECT category, ROUND(AVG(profit),2) AS average_profit
FROM orders
GROUP BY category
ORDER BY average_profit DESC;

--ORDERS WITH HIGH DISCOUNT OF 20%--
SELECT order_id, profit
FROM orders
WHERE discount>0.2;

--TOP CITIES BY SALES--
SELECT city, SUM(sales) AS total_sales
FROM orders
GROUP BY city
ORDER BY total_sales DESC LIMIT 10;

--CUSTOMER ORDER FREQUENCY--
SELECT customer_name, COUNT(order_id) AS total_order
FROM orders
GROUP BY customer_name
ORDER BY total_order DESC;


--PROFIT MARGIN BY CATEGORY--
SELECT 
    category,
    SUM(sales) AS total_sales,
    SUM(profit) AS total_profit,
    ROUND((SUM(profit) / SUM(sales)) * 100, 2) AS profit_margin
FROM orders
GROUP BY category
ORDER BY profit_margin DESC;

--SALES CONTRIBUTION BY SEGMENT--
SELECT segment, SUM(sales) AS total_sales,
ROUND((SUM(sales)/(SELECT SUM(sales) FROM orders))*100, 2) AS contribution_percentage
FROM orders
GROUP BY segment
ORDER BY contribution_percentage;

--LOSS MAKING PRODUCT--
SELECT product_name, SUM(profit) AS total_profit
FROM orders
GROUP BY product_name
HAVING SUM(profit)<0
ORDER BY total_profit ASC;

--WHICH CATEGORY CONTRIBUTES MOST TO LOSS--
SELECT category, SUM(profit) AS total_profit
FROM orders
GROUP BY category
HAVING SUM(profit)<0
ORDER BY total_profit ASC LIMIT 1;


--FIND ORDERS WITH NEGATIVE PROFIT--
SELECT order_id, SUM(profit) AS total_profit
FROM orders
GROUP BY order_id
HAVING SUM(profit)<0
ORDER BY total_profit ASC;

--HIGH SALES BUT LOW PROFIT--
SELECT region, 
       SUM(sales) AS total_sales,
	   SUM(profit) AS total_profit
FROM orders
GROUP BY region
ORDER BY total_sales DESC;


--CUSTOMERS GENERATES LOSS OVERALL--
SELECT customer_name, SUM(profit) AS total_profit
FROM orders
GROUP BY customer_name
HAVING SUM(profit)<0
ORDER BY total_profit ASC LIMIT 5;

--SEGMENT WHICH IS MORE PROFITABLE--
SELECT segment, SUM(profit) AS total_profit
FROM orders
GROUP BY segment 
ORDER BY total_profit DESC LIMIT 1;

--SUB CATEGORY PERFOMRS WORST--
SELECT sub_category, SUM(profit) AS total_profit
FROM orders
GROUP BY sub_category
HAVING SUM(profit)<0
ORDER BY total_profit ASC LIMIT 1;

--HIGH DISCOUNT LOW PROFIT--
SELECT 
    product_name,
    discount,
    profit
FROM orders
WHERE discount > 0.2
AND profit < 0
ORDER BY discount DESC;

--LEVEL 3:ADVANCED ANALYSIS--
--TOP 3 PROFITABLE CATEGORIES--
SELECT category, SUM(profit) AS total_profit
FROM orders
GROUP BY category
ORDER BY total_profit DESC LIMIT 3;


--TOP 3 BY REGION--
SELECT customer_name, region, total_profit, rank_in_region
FROM (
    SELECT customer_name, region, total_profit,
           RANK() OVER (PARTITION BY region ORDER BY total_profit DESC) AS rank_in_region
    FROM (
        SELECT customer_name, region, SUM(profit) AS total_profit
        FROM orders
        GROUP BY customer_name, region
    ) AS sub
) AS ranked_data
WHERE rank_in_region <= 3;


--MONTH OVER MONTH SALES GROWTH--
SELECT region, month, total_sales,
       total_sales - LAG(total_sales) OVER (PARTITION BY region ORDER BY month) AS mom_growth
FROM (
    SELECT region,
           DATE_TRUNC('month', order_date) AS month,
           SUM(sales) AS total_sales
    FROM orders
    GROUP BY region, DATE_TRUNC('month', order_date)
) sub;

--CATEGORY CONTRIBUTION TO REGIONAL SALES--
SELECT region, category, total_sales,
       ROUND(100.0 * total_sales / SUM(total_sales) OVER (PARTITION BY region), 2) AS contribution_pct
FROM (
    SELECT region, category, SUM(sales) AS total_sales
    FROM orders
    GROUP BY region, category
) sub;

--CUSTOMER GENERATING LOSS--
SELECT customer_name, region,
       SUM(sales) AS total_sales,
       SUM(profit) AS total_profit
FROM orders
GROUP BY customer_name, region
HAVING SUM(profit) < 0;

--SHIPPING PERFORMANCE ANALYSIS--
SELECT ship_mode,
       AVG(ship_date - order_date) AS avg_delivery_days
FROM orders
GROUP BY ship_mode;

--CUMULATIVE SALES FOR EACH PRODUCT--
SELECT product_name, order_date, sales,
       SUM(sales) OVER (PARTITION BY product_name ORDER BY order_date) AS cumulative_sales
FROM orders;

--STATE WISE PROFIT TREND--
SELECT state, order_date,
       SUM(profit) OVER (PARTITION BY state ORDER BY order_date) AS cumulative_profit
FROM orders;












