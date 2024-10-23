use wheels;
select * from customer_t;
select * from order_t;
select * from product_t;
select * from shipper_t;

/*

-----------------------------------------------------------------------------------------------------------------------------------
													    Guidelines
-----------------------------------------------------------------------------------------------------------------------------------

The provided document is a guide for the project. Follow the instructions and take the necessary steps to finish
the project in the SQL file			

-----------------------------------------------------------------------------------------------------------------------------------
                                                         Queries
                                               
-----------------------------------------------------------------------------------------------------------------------------------*/
  
/*-- QUESTIONS RELATED TO CUSTOMERS
     [Q1] What is the distribution of customers across states?
     Hint: For each state, count the number of customers.*/

select state,count(customer_id) from customer_t group by state;

/* Inference:
1. States with the Most Customers:
California and Texas, each with 97 customers, are the largest markets, followed by Florida (86), New York (69), 
and the District of Columbia (35). These states are critical for business growth and revenue, indicating strong demand. 
Focusing on customer retention and expansion in these regions is essential, as they represent significant opportunities 
for further market penetration and increased sales.

2. States with Moderate Customer Base:
States like Washington (28), Indiana (21), Virginia (24), Illinois (25), and Ohio (33) have moderate customer numbers, 
offering growth potential. Targeted marketing and service improvements in these areas could help boost customer engagement 
and drive expansion.*/

-- ---------------------------------------------------------------------------------------------------------------------------------

/* [Q2] What is the average rating in each quarter?
-- Very Bad is 1, Bad is 2, Okay is 3, Good is 4, Very Good is 5.

Hint: Use a common table expression and in that CTE, assign numbers to the different customer ratings. 
      Now average the feedback for each quarter. */
 
with average_rating as (select order_id,customer_feedback,
Case when customer_feedback = 'Very Bad' then 1 
when customer_feedback = 'Bad' then 2  
when customer_feedback = 'Okay' then 3 
when customer_feedback = 'Good' then 4
when customer_feedback = 'Very Good' then 5 end as feedback_score, quarter_number
from order_t)

select quarter_number, avg(feedback_score) as avg_rating
from average_rating group by quarter_number order by quarter_number;

/*
Quarter 1 (3.5548): The average rating is just above "Good" (4), indicating relatively positive customer sentiment at the start.
Quarter 2 (3.3550): The rating drops slightly, suggesting a small decline in customer satisfaction, but still around the "Okay" to "Good" range.
Quarter 3 (2.9563): The rating dips further, nearing "Okay" (3), signaling growing customer dissatisfaction.
Quarter 4 (2.3970): This significant drop indicates considerable dissatisfaction, with ratings close to "Bad" (2).*/

-- ---------------------------------------------------------------------------------------------------------------------------------

/* [Q3] Are customers getting more dissatisfied over time?

Hint: Need the percentage of different types of customer feedback in each quarter. Use a common table expression and
	  determine the number of customer feedback in each category as well as the total number of customer feedback in each quarter.
	  Now use that common table expression to find out the percentage of different types of customer feedback in each quarter.
      Eg: (total number of very good feedback/total customer feedback)* 100 gives you the percentage of very good feedback.
      
*/
      
WITH CTE_feedback AS (
    SELECT QUARTER_NUMBER, 
           CUSTOMER_FEEDBACK, 
           COUNT(*) AS feedback_count, 
           (SELECT COUNT(*) FROM order_t WHERE QUARTER_NUMBER = o.QUARTER_NUMBER) AS total_feedback
    FROM order_t o
    GROUP BY QUARTER_NUMBER, CUSTOMER_FEEDBACK
)
SELECT QUARTER_NUMBER, CUSTOMER_FEEDBACK, 
       (feedback_count * 100.0 / total_feedback) AS feedback_percentage
FROM CTE_feedback;

/*In Quarter 1, positive feedback (Good + Very Good) makes up nearly 59%, 
while negative feedback (Very Bad + Bad) is only around 22%. This indicates relatively high customer satisfaction.

In Quarter 2, dissatisfaction rises slightly, with negative feedback (Very Bad + Bad) increasing to 29%. 
However, positive feedback remains stable at around 50%.

In Quarter 3, dissatisfaction increases further, with negative feedback (Very Bad + Bad) totaling over 40%. 
Positive feedback drops to around 37.5%, showing a clear decline in customer satisfaction.

In Quarter 4, dissatisfaction reaches its peak, with nearly 60% of feedback being either "Very Bad" or "Bad." 
Positive feedback (Good + Very Good) plummets to just 20%, indicating significant dissatisfaction.*/
-- ---------------------------------------------------------------------------------------------------------------------------------

/*[Q4] Which are the top 5 vehicle makers preferred by the customer.

Hint: For each vehicle make what is the count of the customers.*/

select vehicle_maker, count(customer_id) as customer_count from product_t p 
join order_t o on p.product_id = o.product_id
group by vehicle_maker order by customer_count desc
limit 5;

/*
Chevrolet dominates customer preferences, with Ford and Toyota also maintaining strong positions. 
These vehicle makers should be prioritized for promotions or partnerships based on their popularity.*/
-- ---------------------------------------------------------------------------------------------------------------------------------

/*[Q5] What is the most preferred vehicle maker in each state?

*/

WITH CTE_rank AS (
    SELECT STATE, VEHICLE_MAKER, COUNT(*) AS maker_count,
           RANK() OVER (PARTITION BY STATE ORDER BY COUNT(*) DESC) AS maker_rank
    FROM customer_t c
    JOIN order_t o ON c.CUSTOMER_ID = o.CUSTOMER_ID
    JOIN product_t p ON o.PRODUCT_ID = p.PRODUCT_ID
    GROUP BY STATE, VEHICLE_MAKER
)
SELECT STATE, VEHICLE_MAKER
FROM CTE_rank
WHERE maker_rank = 1;

-- ---------------------------------------------------------------------------------------------------------------------------------

/*QUESTIONS RELATED TO REVENUE and ORDERS 

-- [Q6] What is the trend of number of orders by quarters?

Hint: Count the number of orders for each quarter.*/

SELECT QUARTER_NUMBER, COUNT(ORDER_ID) AS order_count
FROM order_t
GROUP BY QUARTER_NUMBER;

/* The output indicates the average customer ratings for each quarter: Q1 has the highest rating of 310, 
while Q4 has the lowest at 199. Q2 and Q3 show ratings of 262 and 229, respectively. This trend suggests 
that customer satisfaction peaked in Q1, indicating potential improvements in product offerings or service 
quality during that time. The decline in Q4 may warrant further investigation to identify factors contributing to reduced satisfaction.*/
-- ---------------------------------------------------------------------------------------------------------------------------------

/* [Q7] What is the quarter over quarter % change in revenue? 

Hint: Quarter over Quarter percentage change in revenue means what is the change in revenue from the subsequent quarter to the previous quarter in percentage.
      To calculate you need to use the common table expression to find out the sum of revenue for each quarter.
      Then use that CTE along with the LAG function to calculate the QoQ percentage change in revenue.
*/
	WITH CTE_revenue AS (
    SELECT QUARTER_NUMBER, SUM(VEHICLE_PRICE * QUANTITY) AS total_revenue
    FROM order_t
    GROUP BY QUARTER_NUMBER
)
SELECT QUARTER_NUMBER, 
       LAG(total_revenue) OVER (ORDER BY QUARTER_NUMBER) AS prev_quarter_revenue,
       ((total_revenue - LAG(total_revenue) OVER (ORDER BY QUARTER_NUMBER)) / LAG(total_revenue) OVER (ORDER BY QUARTER_NUMBER)) * 100 AS revenue_change_percentage
FROM CTE_revenue;

/* 
Q1 had a revenue of approximately $39.64 million with a decrease of 16.96% in Q2.
Q3's revenue was about $32.91 million, reflecting a smaller decline of 10.57%, followed by Q4 
at approximately $29.44 million, with a notable drop of 20.18%. This trend indicates declining revenue across the quarters, 
suggesting potential challenges in sales or market conditions that need to be addressed.*/

-- ---------------------------------------------------------------------------------------------------------------------------------

/* [Q8] What is the trend of revenue and orders by quarters?

Hint: Find out the sum of revenue and count the number of orders for each quarter.*/
SELECT QUARTER_NUMBER, 
       SUM(VEHICLE_PRICE * QUANTITY) AS total_revenue, 
       COUNT(ORDER_ID) AS order_count
FROM order_t
GROUP BY QUARTER_NUMBER;

/*
The output presents revenue figures and average customer ratings for each quarter. 
Q1 shows the highest revenue at approximately $39.64 million with a rating of 310.
Q2's revenue is around $32.91 million with a rating of 262, followed by Q3 at about $29.44 million with a rating of 229. 
Q4 has the lowest revenue of approximately $23.50 million, with a rating of 199. 
This indicates a decline in both revenue and customer satisfaction towards the end of the year, 
suggesting potential areas for improvement.*/
-- ---------------------------------------------------------------------------------------------------------------------------------

/* QUESTIONS RELATED TO SHIPPING 
    [Q9] What is the average discount offered for different types of credit cards?

Hint: Find out the average of discount for each credit card type.*/
SELECT CREDIT_CARD_TYPE, AVG(DISCOUNT) AS average_discount
FROM customer_t c
JOIN order_t o ON c.CUSTOMER_ID = o.CUSTOMER_ID
GROUP BY CREDIT_CARD_TYPE;

/* 
Notably, "solo" has the lowest average discount at 0.585, while "jcb" offers the highest at 0.607. 
Other cards like "visa-electron" and "switch" also show competitive averages around 0.623 and 0.610, respectively.
This data suggests differing discount strategies across card types, which could inform marketing and promotional efforts 
aimed at optimizing sales based on credit card usage.*/
-- ---------------------------------------------------------------------------------------------------------------------------------

/* [Q10] What is the average time taken to ship the placed orders for each quarters?
	Hint: Use the dateiff function to find the difference between the ship date and the order date.
*/
SELECT QUARTER_NUMBER, AVG(DATEDIFF(SHIP_DATE, ORDER_DATE)) AS avg_shipping_time
FROM order_t
GROUP BY QUARTER_NUMBER;

/* 
Q1 averages 57.17 days, Q2 is 71.11 days, Q3 is 117.76 days, and Q4 shows the longest average at 174.10 days. 
This trend indicates a significant increase in shipping times over the year, particularly in Q4, which could point 
to operational challenges or increased demand. Addressing these delays may enhance customer satisfaction and 
improve overall service efficiency.


-- --------------------------------------------------------CONCLUSION-----------------------------------------------------------------

In summary, New-Wheels faces significant challenges with declining sales and customer satisfaction. 
Our analysis indicates that while customer bases are strong in key states, there is an alarming trend of increased 
dissatisfaction, particularly evident in shipping times and negative feedback. The company must prioritize operational 
improvements and enhance after-sales service to regain customer trust. By focusing on popular vehicle makers and addressing
feedback through targeted marketing and strategic initiatives, New-Wheels can improve its service offerings and foster a more
loyal customer base, ultimately reversing the sales decline.

-- --------------------------------------------------------Done----------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------------------------------------------



