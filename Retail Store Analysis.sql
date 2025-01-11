-- EXPLORARY DATA ANALYSIS

	-- Number of customers
	SELECT COUNT(DISTINCT customer_id) FROM customers;
	-- Number of different products
	SELECT COUNT(DISTINCT product_name) FROM products;
	-- Number of products category
	SELECT COUNT(DISTINCT category) FROM products;
	-- Number of suppliers
	SELECT COUNT(DISTINCT supplier_id) FROM suppliers;
	-- Number of orders
	SELECT COUNT(order_id) FROM orders;

-- RETAIL STORE ANALYSIS
	-- Retrieve all customers who live in a specific country (e.g., "France").
	SELECT * FROM customers
	WHERE country = 'France';
	
	-- List all products that belong to a specific category (e.g., "Electronics").
	SELECT * FROM products
	WHERE category = 'Electronics';	
	
	-- Find the total number of orders placed in the system.
	SELECT COUNT(DISTINCT order_id) FROM orders;
	
	-- Calculate the total revenue generated by all orders.
	SELECT ROUND(SUM(total_price)::NUMERIC,2) AS total_revenue FROM order_details;
	
	-- Find Orders by Customer: List all orders placed by a customer with customer_id = 5.
	SELECT * FROM orders
	WHERE customer_id = 5;
	
	-- Join Orders and Customers: Retrieve a list of orders along with the corresponding customer names.
	SELECT first_name, last_name, order_id FROM customers 
	INNER JOIN orders on customers.customer_id = orders.customer_id
	ORDER BY 1,2;
	
	-- Top 5 Products by Sales: Identify the top 5 products generating the highest total sales.
	SELECT product_name, ROUND(SUM(total_price)::NUMERIC,2) FROM products INNER JOIN order_details ON products.product_id = order_details.product_id
	GROUP BY 1 
	ORDER BY 2 DESC
	LIMIT 5;
	
	-- Monthly Sales Analysis: Calculate total sales for each month using the order_date.
	SELECT EXTRACT(YEAR FROM order_date) AS year,
		   EXTRACT(MONTH FROM order_date) AS month,
		   ROUND(SUM(total_price)::NUMERIC,2) as total_sale  
	FROM orders INNER JOIN order_details ON orders.order_id = order_details.order_id
	GROUP BY 1,2
	ORDER BY 1,2;
	
	-- Pending Orders: List all orders with a status of "Pending."
	SELECT * FROM orders
	WHERE order_status = 'Pending';
	
	-- Identify the top 5 customers based on total spending.
	SELECT customers.customer_id, first_name, last_name, ROUND(SUM(total_price)::NUMERIC,2) AS total_spending FROM customers 
	INNER JOIN orders ON customers.customer_id = orders.customer_id 
	INNER JOIN order_details ON orders.order_id = order_details.order_id
	GROUP BY 1
	ORDER BY 4 DESC
	LIMIT 5;
	
	-- List all products with low stock (stock quantity < 10).
	SELECT * FROM products
	WHERE stock_quantity < 10;	
	
	-- Calculate the total number of products sold by category.
	SELECT category, COUNT(DISTINCT product_id) AS total_number_of_product_sold FROM products
	GROUP BY 1;
	
	-- Use a window function to rank customers based on total spending.
	SELECT first_name, last_name, ROUND(SUM(total_price)::NUMERIC,2) AS total_spending, RANK() OVER(ORDER BY SUM(total_price) DESC) FROM customers 
	INNER JOIN orders ON customers.customer_id = orders.customer_id
	INNER JOIN order_details ON orders.order_id = order_details.order_id
	GROUP BY 1, 2;
	
	-- Analyze monthly sales trends by calculating the total revenue for each month.
	SELECT EXTRACT (YEAR FROM order_date) AS year,
	       EXTRACT (MONTH FROM ordeR_date) AS month,
		   ROUND(SUM(total_price)::NUMERIC,2) AS total_revenue		  
	FROM orders INNER JOIN order_details ON orders.order_id = order_details.order_id
	GROUP BY 1,2
	ORDER BY 1,2;

	-- Analyze monthly trend by comparing the difference of sales per month
	WITH cte_sales AS (SELECT EXTRACT (YEAR FROM order_date) AS year,
	       EXTRACT (MONTH FROM ordeR_date) AS month,
		   ROUND(SUM(total_price)::NUMERIC,2) AS current_revenue,
		   COALESCE (LAG(ROUND(SUM(total_price)::NUMERIC,2)) OVER(PARTITION BY EXTRACT (YEAR FROM order_date) ORDER BY EXTRACT (MONTH FROM ordeR_date)),0) AS previous_revenue
		FROM orders INNER JOIN order_details ON orders.order_id = order_details.order_id
		GROUP BY 1,2
		ORDER BY 1,2)
	SELECT *, current_revenue - previous_revenue AS revenue_difference, ROUND(((current_revenue - previous_revenue)/ current_revenue) * 100,2) AS growth_rate 
	FROM cte_sales;
	
	-- Identify repeat customers (customers with more than one order).
	SELECT first_name, last_name, COUNT(*) AS number_of_orders FROM orders INNER JOIN customers ON orders.customer_id = customers.customer_id
	GROUP BY 1, 2
	HAVING COUNT(*) > 1;	
	
	-- Create a stored procedure that automatically reduces product stock after an order is placed.
	CREATE OR REPLACE PROCEDURE stock_reduced (pr_product_name varchar, pr_quantity integer)
	language plpgsql
	AS $$
	DECLARE
	v_product_name VARCHAR(100);
	v_stock_quantity INTEGER;
	v_count INTEGER;
	
	BEGIN 
		SELECT COUNT(1) FROM products
		INTO v_count
		WHERE product_name = pr_product_name AND
		stock_quantity >= pr_quantity;
		
		IF v_count > 0 THEN 

			SELECT product_name, stock_quantity FROM products
			INTO v_product_name, v_stock_quantity
			WHERE product_name = pr_product_name; 
	
			UPDATE products 
			SET stock_quantity = stock_quantity - pr_quantity
			WHERE product_name = pr_product_name;
	
			RAISE NOTICE 'Product Sold';

		ELSE
			RAISE NOTICE 'Insufficient stock quantity';

		END IF;

	END; 
	$$;
	
	CALL stock_reduced('buy Home & Kitchen', 1);	
	
	-- Average Order Value: Compute the average order value across all orders.
	SELECT ROUND(AVG(total_price)::NUMERIC,2) FROM orders INNER JOIN order_details ON orders.order_id = order_details.order_id;	
	
	-- Product Stock Alert: List all products where the stock quantity is below 10.
	SELECT product_name, stock_quantity FROM products
	WHERE stock_quantity < 10;
	
	-- Sales by Country: Compute total sales by country using customer location.
	SELECT country, ROUND(SUM(total_price):: NUMERIC,1) AS total_sales FROM customers
	INNER JOIN orders ON customers.customer_id = orders.customer_id
	INNER JOIN order_details ON orders.order_id = order_details.order_id
	GROUP BY 1 
	ORDER BY 2 DESC;
	
	-- Year-over-Year Sales Growth: Calculate the percentage growth in sales year-over-year.
	WITH cte_sales_growth AS 
	(
		SELECT EXTRACT(YEAR FROM order_date) AS year,
			   EXTRACT(month FROM order_date) AS month,
			   ROUND(SUM(total_price)::NUMERIC,2) AS current_month_sales,
			   COALESCE(LAG(ROUND(SUM(total_price)::NUMERIC,2)) OVER( PARTITION BY EXTRACT(YEAR FROM order_date) ORDER BY EXTRACT(month FROM order_date)),0) AS previous_month_sales
		FROM orders INNER JOIN order_details ON orders.order_id = order_details.order_id
		GROUP BY 1,2 
		ORDER BY 1,2 
	)
	
	SELECT *, ROUND(((current_month_sales - previous_month_sales) / current_month_sales) * 100,0)  AS percentage_growth
	FROM cte_sales_growth 

	
	

