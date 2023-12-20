
--Count all rows in info_v2 table
--Counts non-null values for description, listing_price, and last_visited
--inner join of info_v2, finance and traffic_v3
SELECT COUNT(*) AS TOTAL_ROWS, 
COUNT(info_v2.description) AS COUNT_DESCRIPTION,
COUNT(finance.listing_price) AS COUNT_LISTING_PRICE,
COUNT(traffic_v3.last_visited) AS COUNT_LAST_VISITED
FROM info_v2
INNER JOIN finance
ON info_v2.product_id=finance.product_id
INNER JOIN traffic_v3 
ON info_v2.product_id=traffic_v3.product_id
-- Databese contains of 3179 rows
--Last_visited is missing more than 5 percent of its value
--Now we will see how the price of Nike and Addidas shoes are different

SELECT brand,cast(listing_price as int) AS LISTING_PRICE,COUNT(*) AS "COUNT"
FROM brands_v2
INNER JOIN finance
on finance.product_id=brands_v2.product_id
WHERE listing_price>0
GROUP BY brand, listing_price
ORDER BY LISTING_PRICE DESC
--the below query shows we have 77 different price of shoes most expenisve ones are from Adidas
--We've discovered that there are 77 distinct prices for the products in our database, complicating the analysis of the output from our recent query.
--To refine our previous query, we'll now categorize these prices into different ranges, assign labels, and group the data by both brand and label. Additionally, we'll incorporate the total revenue figures for each price range within each brand category.


SELECT brand,COUNT(*) AS count_per_category,SUM(revenue) AS Total_revenue,
	CASE
		WHEN sale_price<42 THEN 'Budget'
		WHEN sale_price>=42 AND sale_price<74 THEN 'Average'
		WHEN sale_price>=74 AND sale_price<129 THEN 'Expensive'
		Else 'Elite'
	END AS 'Price_category'
from brands_v2
inner join finance on finance.product_id=brands_v2.product_id
GROUP By brand, CASE
		WHEN sale_price<42 THEN 'Budget'
		WHEN sale_price>=42 AND sale_price<74 THEN 'Average'
		WHEN sale_price>=74 AND sale_price<129 THEN 'Expensive'
		Else 'Elite'
		END
HAVING brand IS NOT NULL
ORDER BY Total_revenue DESC
--Remarkably, when products are grouped by both brand and price range, a noteworthy observation emerges: Adidas items consistently outperform others in terms of total revenue, irrespective of the price category. This insight suggests that strategically increasing the proportion of such Adidas products in the stock could potentially lead to a substantial revenue boost for the company.
--Please note that our analysis has focused on the listing_price thus far, but it's essential to recognize that the listing_price may not accurately reflect the final sale price of the product. To gain a deeper understanding of revenue dynamics, we will delve into the discount percentage, representing the reduction from the listing_price when a product is sold. Our aim is to investigate whether there are variations in the discount rates among different brands, as this factor could potentially impact overall revenue outcomes.
Select brand,AVG( discount)
From brands_v2
INNER JOIN finance on finance.product_id=brands_v2.product_id
WHERE brand IS NOT NULL
GROUP BY brand
--An intriguing observation reveals a 34 percent average discount on Adidas shoes, while no discounts are applied to Nike products. Despite this, Adidas shoes emerge as the highest-selling and most revenue-generating product. In response, the manager is considering canceling the sale on Adidas to assess the impact on revenue. Additionally, a decision has been made to introduce a sale on Nike products to monitor its effect on sales and revenue. This strategic move aims to optimize the sales performance of both Adidas and Nike products.

SELECT Correlation(reviews,revenue) AS review_revenue_correlation
FROM finance 
INNER JOIN reviews_v2 on finance.product_id=reviews_v2.product_id
--Lets explore whether a relationship exist between revenue and revie.(strength and direction)
--correlation=Cov/std_review*std_revenue
--cov=Avg((revenue-revenue.mu)*(review-review.mu))
--std=sqrt(Avg(revenue-revenue.mu)**2))
WITH mean AS(
	--CALCULATE MEAN
	SELECT 
		AVG(revenue) over() as revenue_mean,
		AVG(reviews) over() as reviews_mean
	FROM finance 
		INNER JOIN reviews_v2 on finance.product_id=reviews_v2.product_id
	),
	stdDev AS(
	SELECT
	SQRT(AVG(POWER(revenue-revenue_mean,2))) AS std_revenue,
	SQRT(AVG(POWER(reviews-reviews_mean,2))) AS std_reviews
	FROM mean, finance 
		INNER JOIN reviews_v2 on finance.product_id=reviews_v2.product_id
	),
	Covariance AS(
	SELECT
	AVG((revenue-revenue_mean)*(reviews-reviews_mean)) AS cov_revenue_reviews
	FROM mean, finance 
		INNER JOIN reviews_v2 on finance.product_id=reviews_v2.product_id
		)
	SELECT cov_revenue_reviews/(std_revenue*std_reviews) 
	from Covariance,stdDev
--Remarkably, a robust positive correlation exists between the number of reviews and revenue. This implies that an increase in website reviews enhances the likelihood of selling items with a high number of reviews."

SELECT brand, MONTH(last_visited) as 'month' ,count(reviews) as reviews_number
FROM reviews_v2
INNER JOIN traffic_v3 
ON traffic_v3.product_id=reviews_v2.product_id
INNER JOIN brands_v2
ON traffic_v3.product_id=brands_v2.product_id
GROUP BY MONTH(last_visited),brand
HAVING  MONTH(last_visited) IS NOT NULL 
AND brand IS NOT NULL
ORDER BY reviews_number DESC
--It seems like product reviews peak in the first quarter of the calendar year, presenting an opportunity to explore strategies that could boost review volumes during the remaining nine months!

--Shifting our focus from the Adidas vs Nike analysis, let's delve into the product types. Given the absence of explicit labels for product types, we'll employ a Common Table Expression (CTE) to filter descriptions for keywords. Subsequently, we'll leverage these findings to determine the proportion of the company's inventory dedicated to footwear products and assess the median revenue generated by this category.

WITH footwear AS(
	SELECT i.description,f.revenue
	from info_v2 as i
	INNER JOIN finance as f
	ON f.product_id=i.product_id
	WHERE description LIKE '%foot%'
	OR description LIKE '%trainer%'
    OR description LIKE '%foot%'
	AND description IS NOT NULL
	)
	SELECT  count(*)over(),percentile_disc(0.5)
	WITHIN GROUP (ORDER BY revenue) over()
	AS median_footwear_revenue
	FROM footwear

WITH footwear AS(
	SELECT i.description,f.revenue
	from info_v2 as i
	INNER JOIN finance as f
	ON f.product_id=i.product_id
	WHERE description LIKE '%foot%'
	OR description LIKE '%trainer%'
    OR description LIKE '%foot%'
	AND description IS NOT NULL
	)
SELECT count(*)over() AS num_clothing_products,
PERCENTILE_DISC(0.5) WITHIN GROUP (ORDER BY revenue)over() AS median_clothing_revenue
FROM info_v2
INNER JOIN finance
ON info_v2.product_id = finance.product_id
WHERE description NOT IN (SELECT description from footwear)

