create database project;

use project;

show tables;
alter table feeedback rename to feedback;

update refund as r 
join orders as o on o.oid = r.order_id
set r.return_date = adddate(r.return_date,7)
where r.return_date < o.ETA;

select * from customers; 
select * from orders; 
select * from products; 
select * from transaction; 
select * from feedback; 
select * from refund; 

-- Table Structure 
# customers   (cid, cname ,city, age, address, contact, email)
# orders      (oid, cid, pid, order_date, order_time, ETA)
# products    (pid, pname, price, desc)
# transaction (oid, payment_mode)
# feedback    (oid, prod_rating, delivery_rating)
# refund      (orderid, Return_Type, Reason, return_date)

--  Customers KPI's

# 1)  Total Customers

select count(distinct cid) as Total_Customers from customers;

-- Insight - The platform currently serves 2000 unique customers across 5 major cities.

# 2) Average Orders per Customer

select round((Total_Orders / Total_Customers),2) as Avg_Order_Per_Csutomer from
(select count(oid) as Total_Orders, count(distinct cid) as Total_Customers
from orders) as dt;

-- Insight - Each customer places an average of 2.74 orders. 

# 3) Repeat Customer Rate

with cte1 as 
(select count(cid) as Repeat_Customers from
(select cid, count(cid) as Customers_Count
from orders group by cid
having Customers_Count > 1) as dt),
cte2 as 
(select count(distinct cid) as Total_Customers from orders)
select concat(round((cte1.Repeat_Customers / cte2.Total_Customers)*100,2),'%') as Repeat_Customer_Rate
from cte1, cte2;

-- Insight -  Around 78.44% customers are repeat buyers.

# 4) Avg age of Customers

select avg(age) as Avg_Age from customers;

-- Insight -  With an average age of 39 years,
--            the customer base consists mainly of mature working professionals. 

# 5) New Customers per Month
	
select Year, Month, count(distinct cid) as Customers from    
(select cid, year(First_Order_Date) as Year, month(First_Order_Date) as Month from   
(select cid, min(order_date) as First_Order_Date from orders group by cid) as dt
order by Year, Month) as dt2
group by Year,Month;

-- Insight -  The number of new customers ranged from 16 to 346,
--            with an average of approximately 150 new customers. 

-- Customers Insights 

# 1)  Top 3 Cities by Total Customer Distribution. 

select c.City, count(o.cid) as Customer_Count 
from customers as c join orders as o on c.cid = o.cid
group by c.city
order by Customer_Count desc
limit 3 ;

-- Insight: Noida, Pune and Kolkata record the highest customer volumes,
--          highlighting them as key markets for customer engagement and growth. 

# 2) Average Orders per Customer by City.

select City, round((Total_Orders / Total_Customers),2) as `Average Order per Customer by City` from
(select c.city, count(o.oid) as Total_Orders, count(distinct o.cid) as Total_Customers
from customers as c join orders as o
on c.cid = o.cid
group by c.city) as dt
order by `Average Order per Customer by City` desc ;

-- Insight: Customers from Kolkata show the highest purchase frequency,
--          averaging 2.83 orders per customer, followed by Noida and Pune,
--          indicating strong customer engagement in these regions.

# 3) Age group analysis → Which age group (e.g., 20–30, 30–40) orders the most. 

select min(age) as Min_Age from customers; # 18
select max(age) as Max_Age from customers; # 60

select Age_Group, count(oid) as Orders from
(select c.age, o.oid, case 
when age>=18 and age<=25 then '18-25'
when age>=26 and age<=35 then '26-35'
when age>=36 and age<=45 then '36-45'
when age>=46 and age<=55 then '46-55'
else '56-60'
end as Age_Group
from customers as c join orders as o
on c.cid = o.cid
order by age) as dt
group by Age_Group
order by Orders desc;

-- Insight: The 36–45 age group represents a high-value customer segment,
--                   contributing the largest share of total orders (1,445).
--                   This indicates that mid-aged professionals are the most engaged buyers.

# 4) Monthly Contribution to New Customer Acquisition

select Year, Month_Name, New_Customers from
(select year(Join_Date) as Year,month (Join_Date) as Month ,
monthname(Join_Date) as Month_name,
count(cid) as New_Customers from 

(select  cid, min(order_date) as Join_Date
from orders group by cid ) as dt
group by Year, Month, Month_Name
order by year, Month) as dt2;

-- Insight: Customer acquisition has shown consistent month-over-month growth,
--          with October 2024 recording the highest number of new customers (346),
--          with (18.98%) new customer share.

# 5) City-wise Active Customer Distribution (Orders Placed)

select c.City, count(distinct o.cid) as Active_Customers
from customers as c join orders as o on c.cid = o.cid
group by c.city
order by Active_Customers desc;

-- Insight: Noida has the highest number of active customers,
--          followed by Pune and Kolkata, indicating stronger engagement in metro regions.

# 6) Preferred Payment Mode by City

select City, Payment_Mode from
(select City, Payment_Mode, Mode_Count,
row_number() over (partition by city order by Mode_Count desc) as Ranked from
(select c.city, t.payment_mode,
count(payment_mode)  as Mode_Count
from customers as c join orders as o on c.cid = o.cid
join transaction as t on o.oid = t.oid
group by c.city, t.payment_mode
order by city) as dt) as dt2
where Ranked=1 ;

-- Insight: Credit Card emerges as the most preferred payment mode across most cities

 # 7) Average Product & Delivery Rating by City

select * from 
(select c.City, round(avg(f.prod_rating),2) as Avg_Product_Rating,
round(avg(f.delivery_rating),2) as Avg_Delivery_Rating
from customers as c join orders as o on c.cid = o.cid
join feedback as f on o.oid = f.oid
group by c.city) as dt
where city != 'Not Provided'
order by Avg_Product_Rating desc;

-- Insight: Mumbai records the highest average product rating,
--          while Noida leads in delivery experience.
--          This indicates that while product quality satisfaction is strongest in Mumbai,
--          Noida customers are most satisfied with delivery service.

# 8) Top - 10 High-Value Customers (Top Spenders)
 
select o.cid as Customer_ID ,sum(p.price) as Total_Spending
from customers as c join orders as o on o.cid = c.cid
join products as p on o.pid = p.pid
group by o.cid
order by Total_Spending desc
limit 10; 

-- Insight: The top 10 customers generate a major portion of total revenue,
--          reflecting high-value repeat buyers who are key to business profitability.

# 9) Refund Rate by City

with cte1 as 
(select c.city,  count(o.oid) as Total_Orders 
from customers as c join orders as o on c.cid = o.cid
group by c.city
order by c.city),

cte2 as 
(select c.city, count(r.return_type) as Total_Refunds
from customers as c join orders as o on c.cid = o.cid
join refund as r on r.order_id = o.oid
where r.return_type='Refund'
group by c.city
order by c.city)

select cte1.City, concat(round((cte2.Total_Refunds / cte1.Total_Orders)*100,2),'%') as Refund_Rate
from cte1 join cte2 on cte1.city = cte2.city
order by Refund_Rate desc;

-- Insight: Pune reports the highest refund rate (6.24%),
--         while Mumbai records the lowest (4.43%),
--         indicating relatively consistent post-purchase experiences across cities.

# 10) Exchange Rate by City

with cte1 as 
(select c.city, count(o.oid) as Total_Customers 
from customers as c join orders as o on c.cid = o.cid
group by c.city
order by c.city),

cte2 as 
(select c.city, count(r.order_id) as Total_Exchange
from customers as c join orders as o on o.cid = c.cid
join refund as r on r.order_id = o.oid
where r.return_type = 'Exchange'
group by c.city
order by c.city)

select cte1.City, concat(round((cte2.Total_Exchange / cte1.Total_Customers)*100,2),'%') as Exchange_Rate
from cte1 join cte2 on cte1.city = cte2.city
order by Exchange_Rate desc;

-- Insight: Delhi records the highest exchange rate (5.96%),
--          while Noida has the lowest (3.70%),
--          indicating relatively stable product satisfaction across cities.

# 11) Top 3 Customers per Year and Month.

select Year, Month, CID as Customer_ID, Total_Spent from
(select *, 
row_number() over (partition by Year, Month order by Total_Spent desc ) as Rnk from
(select  year(order_date) as Year, month(order_date) as Month, cid,
sum(Price) as Total_Spent from
(select o.cid, o.order_date, p.price
from orders as o join products as p on o.pid = p.pid) as dt
group by  Year, Month, cid
order by Year asc, month asc) as dt2) as dt3
where dt3.Rnk<4;
;

-- Insight: Each month features different top-spending customers,
--          showing that Amazon’s sales are driven by a wide and diverse customer base.
--          However, no customer consistently remains in the top tier,
--          suggesting an opportunity to strengthen loyalty among premium buyers.

# 12) Customer Retention Rate (Repeat Customers %) (Month-wise)

with cte1 as 
(select distinct(cid), year(order_date) as Year, month(order_date) as Prev_Month
from orders ),

cte2 as 
(select distinct(cid), year(order_date) as Year, month(order_date) as Curr_Month
from orders ),

cte3 as 
# select cte1.*, cte2.* from cte1 join cte2 on cte1.cid = cte2.cid
(select cte2.Year, cte2.Curr_Month, count(distinct cte2.cid) as Retained_Customers
from cte1 join cte2 on cte1.cid = cte2.cid
and (
(cte1.Year = cte2.Year and cte2.Curr_Month - cte1.Prev_Month = 1)
                       OR 
(cte1.Year+1 = cte2.Year and cte1.Prev_Month=12 and cte2.Curr_Month=1) )
group by cte2.Year, cte2.Curr_Month),

cte4 as 
(select Year, Month, Total_Customers, lag(Total_Customers,1,0) over(order by Year, Month) as Prev_Month_Customer
from 
(select year(order_date) as Year, month(order_date) as Month,
count(distinct cid) as Total_Customers from orders group by Year, Month) as dt)

select cte3.*, cte4.Prev_Month_Customer,
concat(round((cte3.Retained_Customers / cte4.Prev_Month_Customer) *100,2),'%') as Retention_Rate
from cte3 join cte4 on cte3.Curr_Month = cte4.Month
and cte3.Year= cte4.Year;

-- Insight - The month-over-month customer retention rate averaged 18%,
--           fluctuating between 15.03% and 21.77%, indicating steady customer engagement with
--           moderate loyalty. 

-- Orders KPI's

# 1) Total Orders

select count(oid) as Total_Orders from orders;

-- Insight -  A total of 5,000 orders have been placed across all customers.

# 2) Total Revenue

select sum(price) as Revenue from
(select o.oid, p.price from orders as o join products as p
on p.pid = o.pid) as dt;

-- Insight - Total revenue generated is 58.4 million. 

# 3) Average Order Value (AOV)

select round((Total_Spent / Orders_Count),2) as Avg_Order_Value from
(select count(o.oid) as Orders_Count, sum(p.price) as Total_Spent
from products as p join orders as o on o.pid = p.pid) as dt;

-- Insight - Average order value is 11,707 ,
--           reflecting moderately high transactions values, 
--           and healthy customer purchasing power.
 
# 4) Total Customers Who Ordered

select count(distinct cid) as Total_Customers from orders;

-- Insight - 1,823 unique customers placed at least one order, 
--           indicating strong customer engagement.

# 5) Average Delivery Time(Days)

select round((Days_To_Deliver  / Total_Orders),2) as Avg_Delivery_Time from
(select count(oid) as Total_Orders,
sum(datediff(ETA,order_date)) as Days_To_Deliver
from orders) as dt; 

-- Insight - Average delivery time is 3.78 days, reflecting efficient and timely deliveries.

# 6) Orders per city

select c.City, count(o.oid) as Total_Orders
from customers as c join orders as o on c.cid = o.cid group by c.city
order by Total_Orders desc;

-- Insight - Metro cities like Noida and Kolkata drive most platform sales.

--  Orders Insights

 # 1) Monthly / Yearly Order Trend

select  year(order_date) as Year, month(order_date) as Month,
count(oid) as Total_Orders
from orders group by Year, Month
order by Year, Month;

-- Insight - Orders increased steadily from late 2024 through mid-2025 peaking at (457)
--           orders in August 2025, before a short term decline in September 2025.  
 
# 2) Orders Trend by Weekday vs Weekend

with cte1 as 
(select count(oid) as Total_Orders from orders),

cte2 as 
(select count(Day_Name) as Weekend_Orders from
(select *, dayname(order_date) as Day_Name from orders) as dt
where dt.Day_Name in ('Saturday','Sunday'))

select cte1.Total_Orders, cte2.Weekend_Orders, 
(cte1.Total_Orders - cte2.Weekend_Orders) as Weekday_Orders 
from cte1,cte2; 

-- Insight - Weekday orders (3,567) exceed Weekend orders (1,433),
--           showing customers are more active during working days. 
  
# 3) High-Value Orders (Premium Transactions),
-- Total premium revenue, Average price of premium products

select count(oid) as High_Value_Orders,
sum(price) as Total_PremiumOrd_Revenue, round(avg(price),2) as Avg_Premium_Price from
(select o.oid, p.price
from orders as o join products as p on o.pid = p.pid
where p.price >
(select  round(avg(price),2) as Avg_Amount 
from products)) as dt;  

-- Insight - A total of 1,799 high value(premium) orders were recorded,
--           generating 41.03 million in revenue and 
--           these orders have an average value of 22,982.

# 4) Peak ordering hours

select distinct(Hour) as Hour, count(oid) as Orders_Count from
(select oid, order_time, hour(order_time) as Hour from orders) as dt
group by Hour 
order by Orders_Count desc
limit 3;

-- Insight - The peak ordering hour is 12pm with the highest order volume,
--           followed by 9-10pm, indicating a strong midday and evening customer activity.

# 5) Payment Mode wise Percentage Contribution.

select Payment_Mode, Orders_Count,
concat(round((Orders_Count / Total_Orders)*100,2),'%') as Percentage_Contribution from
(select Payment_Mode, Orders_Count,
sum(Orders_Count) over () as Total_Orders from
(select t.Payment_Mode, count(o.oid) as Orders_Count
from orders as o join transaction as t on o.oid = t.oid
group by t.payment_mode) 
as dt) as dt2;

-- Insight - Digital payments dominate with 92% share, led by Credit Card, UPI,
--           while 8% of transactions have missing payment informations.

# 6) City-wise Order Volume & Average Order Value

select City, Order_Volume, round((Total_Orders_Value / Order_Volume),2) as Avg_Order_Value from
(select c.city , count(o.oid) as Order_Volume, sum(p.price) as Total_Orders_Value
from customers as c join orders as o on c.cid = o.cid
join products as p on p.pid = o.pid
group by c.city) as dt
order by Avg_Order_Value desc;

-- Insight - Kolkata city records the highest average order value(12,200),
--           reflecting strong purchasing power and higher customer spending. 

# 7) Customer Segmentation by Order Frequency and Revenue Contribution

with cte1 as 
(select CID, Orders_Count, Revenue, (Revenue/ Total_Revenue)*100 as Revenue_Contribution from
(select *, sum(Revenue) over () as Total_Revenue from
(select o.cid ,count(o.oid) as Orders_Count, sum(p.price) as Revenue
from orders as o join products as p on o.pid = p.pid group by cid) as dt) as dt2),

cte2 as 
(select count(cte1.cid) as One_Time_Buyers,
sum(Revenue_Contribution) as Revenue_Contribution_OTB from cte1 where cte1.Orders_Count=1),
 # 50,46,984

cte3 as 
(select count(cte1.cid) as Repeat_Customers,
sum(Revenue_Contribution) as Revenue_Contribution_RC from cte1 where cte1.Orders_Count>1)

select cte2.One_Time_Buyers, concat(round(cte2.Revenue_Contribution_OTB,2),'%') as OTB_Rev_Cont,
cte3.Repeat_Customers, concat(round(cte3.Revenue_Contribution_RC,2),'%') as RC_Rev_Cont 
from cte2,cte3;

-- Insight - Repeat Customers (1,430) contribute over 91.38% of total revenue, highlighting
--           strong customer loyalty and the critical role of retention in driving the sales. 


# 8) City wise revenue contribution.

select City, concat(round((Revenue / Total_Revenue)*100,2),'%') as Revenue_Contribution from
(select *, sum(Revenue) over() as Total_Revenue from
(select c.city, sum(p.price) as Revenue
from customers as c join orders as o on c.cid = o.cid
join products as p on o.pid = p.pid
group by c.city) as dt) as dt2
order by Revenue desc; 

-- Insight - Kolkata contributes the highest revenue share (22.05%) followed by Noida and Pune,
--           while Delhi and Mumbai show comparatively lower performance. 
           
# 9) Repeat Order Rate

with cte1 as 
(select cid , count(oid) as Orders_Count from orders group by cid
having Orders_Count > 1 
order by cid asc),

cte2 as
(select sum(Repeat_Order) as Repeat_Orders from
(select c.cid, c.Orders_Count, (c.Orders_Count)-1 as Repeat_Order
from cte1 as c) as dt),

cte3 as
(select count(oid) as Total_Orders from orders) 

select concat(round((cte2.Repeat_Orders / cte3.Total_Orders)*100,2),'%') as Repeat_Order_Rate
from cte2,cte3;

# 10) Top 10 Products by Order Volume and Revenue Contribution.

with cte1 as 
(select p.pname as Product, count(o.oid) as Order_Volume, sum(p.price) as Revenue
from orders as o join products as p on p.pid = o.pid
group by Product),

cte2 as 
(select *, sum(Revenue) over () as Total_Revenue from cte1 ),

cte3 as 
(select Product, Order_Volume, Revenue,
concat(round((Revenue / Total_Revenue)*100,2),'%') as Revenue_Contribution
from cte2
)
select * from cte3 order by Revenue desc limit 10;

-- Insight - Mi Power Bank Air recorded the maximum revenue contribution (1.60%),
--           reflecting its strong performance in overall sales.   

-- Product KPI's 

# 1) Total Products Sold

select count(distinct pid) as Total_Products_Sold from orders;

-- Insight - A total of 500 products were sold, indicating strong overall sales coverage. 

# 2) Total Product Revenue

select sum(price) as Total_Product_Revenue from
(select p.pid, o.oid, p.price from orders as o join products as p on p.pid = o.pid) as dt;

-- Insight - Total product revenue stands at ₹58.4 million,
--           indicating strong overall sales performance across the product range. 

# 3) Average Product Rating

select round(avg(prod_rating),2) as Avg_Product_Rating from feedback;

-- Insight - Average product rating is 2.99 out of 5, reflecting moderate satisfaction
--           and a need for quality improvement.  

# 4) Top 10 Best Performing Products

select pname as Product_Name, sum(price) as Revenue from
(select p.pname , o.oid, p.price
from products as p join orders as o on p.pid = o.pid) as dt 
group by pname
order by sum(price) desc
limit 10;

-- 	Insight - Products like Mi Power Bank Air and Sennheiser Earbuds Plus recorded the
--            highest revenue, reflecting strong demand for electronics and accessories.

-- Product Insights 

# 1) Top 10 Performing Products by Revenue Contribution

with cte1 as 
(select Pid, Product, sum(price) as Revenue from
(select p.pid, p.pname as Product, o.oid, p.price    # check questions based on oid(KPI)   
from products as p join orders as o on p.pid = o.pid) as dt
group by Pid, Product),

cte2 as 
(select Pid, Product, Revenue, sum(Revenue) over () as Total_Revenue from cte1)

select Pid as Product_ID, Product as Product_Name, Revenue,
concat(round((Revenue / Total_Revenue)*100,2),'%') as Revenue_Contribution 
from cte2
order by Revenue desc limit 10;

-- Insight - Several top products contribute over 1% each to total revenue,
--           highlighting strong sales performance in electronics and accessories.

--  Top 10 Highest Rated Products

select p.pname as Product_Name, round(avg(f.prod_rating),2) as Avg_Rating
from products as p join orders as o on p.pid = o.pid
join feedback as f on f.oid = o.oid 
group by p.pname
order by Avg_Rating desc
limit 10;  

-- Insight - Products like Lavie Handbag Prime and Prestige Induction Cooktop Pro
--           achieved top ratings (4.5) , reflecting high customer satisfaction and trust. 

# 3) Top 10 Products with highest Refund Rate

with cte1 as 
(select p.pname, count(o.oid) as Orders_Count
from products as p join orders as o on p.pid = o.pid
group by p.pname),

cte2 as 
(select p.pname, count(r.return_type) as Refunded_Orders
from products as p join orders as o on p.pid = o.pid
join refund as r on r.order_id = o.oid
where r.return_type = 'Refund'
group by p.pname),

cte3 as 
(select cte1.pname as Product,
round((cast(Refunded_Orders as decimal(10,2))/ Orders_Count)*100,2) as Prod_Wise_Refund_Rate
from cte1 join cte2 on cte1.pname = cte2.pname
order by Prod_Wise_Refund_Rate desc limit 10 )


select Product as Product_Name, concat(Prod_Wise_Refund_Rate,'%') as Refund_Rate from cte3 ;

-- Insight - Products like Realme Power Bank Max and Su-kam Mixer Grinder Call
--           show the highest refund rates (up to 40%), 
--           reflecting quality or expectation gaps in electronics and appliances. 

# 4) Top 10 products with highest Exchange Rate

with cte1 as 
(select p.pname, count(o.oid) as Orders_Count
from products as p join orders as o on p.pid = o.pid
group by p.pname),

cte2 as 
(select p.pname, count(r.return_type) as Exchanged_Orders
from products as p join orders as o on p.pid = o.pid
join refund as r on r.order_id = o.oid
where r.return_type = 'Exchange'
group by p.pname),

cte3 as 
(select cte1.pname as Product,
round((cast(Exchanged_Orders as decimal(10,2))/ Orders_Count)*100,2) as Prod_Wise_Exchange_Rate
from cte1 join cte2 on cte1.pname = cte2.pname
order by Prod_Wise_Exchange_Rate desc limit 10 )

select Product as Product_Name, concat(Prod_Wise_Exchange_Rate,'%') as Exchange_Rate from cte3;

-- Insight - Products such as Karcher Vacuum Cleaner Mini, Philips Hair Dryer 659,
--           Gopro Camera Series 5, and Itel Smartphone Mini record the highest exchange rates (over 30%),
--           indicating potential quality or performance concerns in electronic and appliance categories.

# 5) Top 10 Products by Orders and Their Top Cities

with cte1 as 
(select p.pname as Product, c.City, count(oid) as Orders_Count
from customers as c join orders as o on c.cid = o.cid
join products as p on p.pid = o.pid
group by p.pname, c.city),

cte2 as 
(select *, rank() over (partition by Product order by Orders_Count desc) as Rnk
from cte1),

cte3 as 
(select Product, group_concat(City separator ',') as Top_Cities  from cte2 where Rnk=1
group by Product),

cte4 as 
(select p.pname as Product, count(oid) as Total_Orders
from products as p join orders as o on p.pid = o.pid
group by p.pname)

select cte3.Product as Product_Name, cte4.Total_Orders, cte3.Top_Cities
from cte3 join cte4 on cte3.Product = cte4.Product
order by cte4.Total_Orders desc limit 10;

-- Insight - Top 10 products show peak order volumes concentrated in metro cities
--           like Noida, Kolkata, Pune reflecting strong urban market demand.

# 6) Average Delivery Rating per Product

select p.pname as Product_Name, round(avg(f.Delivery_Rating),2) as Avg_Delivery_Rating 
from products as p join orders as o on p.pid = o.pid
join feedback as f on o.oid = f.oid
group by Product_Name
order by Avg_Delivery_Rating desc;

-- Insight - Delivery rating across 500 products range from 1.82(minimum) to 5.00(maximum),
--           showing overall strong logistics performance, with few low-rated exceptions.

# 7) Repeat Purchase Frequency by Product

with cte1 as 
(select o.cid as Customer_ID, o.Pid as Product_ID, p.pname as Product_Name,
count(o.pid) as Total_Orders  
from orders as o join products as p on p.pid = o.pid
group by o.cid,o. pid, p.pname
having Total_Orders>1),

cte2 as 
(select *, (Total_Orders)-1 as Repeat_Orders from cte1)

select Product_ID, Product_Name, sum(Repeat_Orders) as Total_Repeat_Orders_Frequency
from cte2
group by Product_ID, Product_Name;

-- Insight - All listed products record a repeat purchase frequency of 1,
--           reflecting one-time buying patterns common among durable goods.  

# Transaction KPI's

# 1) Total Transactions

select count(oid) as Total_Transactions from transaction;

-- Insight - A total of 5000 transactions were completed, representing the overall volume of
--           customer purchases.  

# 2) Payment Mode Share

select Payment_Mode, Transaction_Count,
concat(round((Transaction_Count / Total_Transactions)*100,2),'%') as Transaction_Share  from
(select *, sum(Transaction_Count) over () as Total_Transactions from
(select Payment_Mode , count(oid) as Transaction_Count 
from transaction
group by Payment_Mode) as dt) as dt2
order by Transaction_Count desc;

-- Insight - Credit Card (31.26%) and UPI (30.86%) lead payment mode share, together forming
--           over 60% of total transactions followed by Net Banking (28.88%), 
--           About 8% lack payment mode details.       

# 3) Average Transaction Value

select round((Total_Revenue / Total_Transactions),2) as Average_Transaction_Value from
(select sum(p.price) as Total_Revenue, count(t.oid) as Total_Transactions
from products as p join orders as o on p.pid = o.pid
join transaction as t on t.oid = o.oid) as dt;

-- Insight - The average transaction value stands at ₹11,708, indicating that customers 
--           typically spend around ₹11,708 on average per order.

-- Transaction Insights

# 1) Payment Mode Revenue Contribution

with cte1 as 
(select t.Payment_Mode, p.price
from products as p join orders as o on o.pid = p.pid
join transaction as t on t.oid = o.oid),

cte2 as 
(select *, sum(Revenue) over () as Total_Revenue from
(select cte1.Payment_Mode, sum(cte1.price) as Revenue
from cte1 group by cte1.Payment_Mode) as dt)

select cte2.Payment_Mode, cte2.Revenue,
concat(round((cte2.Revenue / cte2.Total_Revenue)*100,2),'%') as Revenue_Contribution
from cte2 order by Revenue desc;

-- Insight - UPI (31.06%) and Credit Card (30.54%) contribute nearly equal revenue shares,
--           jointly driving over 60% of total revenue, while Net Banking adds another (29.56%).  

# 2) City-wise Payment Preference

with cte1 as 
(select c.City, t.Payment_Mode , count(t.Payment_Mode)as Payment_Mode_Count
from customers as c join orders as o on c.cid = o.cid
join transaction as t on t.oid = o.oid
group by c.city, t.payment_mode
order by c.city),

cte2 as 
(select cte1.*, 
sum(cte1.Payment_Mode_Count) over (partition by cte1.City) as Total_PM_Count
from cte1)

select City, Payment_Mode,
concat(round((Payment_Mode_Count / Total_PM_Count)*100,2),'%') as Payment_Mode_Share
from cte2;

-- Insight - UPI leads city wise payments, while Credit card and Net banking follow closely,
--           Around 6-10% lack city or payment mode details.  

# 3) Payment Mode Trend Over Time (Year and Month).

with cte1 as 
(select year(o.order_date) as Year, month(o.order_date) as Month, t.payment_mode
from orders as o join transaction as t on t.oid = o.oid
order by Year, Month),

cte2 as 
(select *, sum(Payment_Count) over(partition by Year, Month) as Total_Payments from
(select Year, Month, Payment_Mode, count(payment_mode) as Payment_Count
from cte1 group by Year, Month, Payment_Mode) as dt)

select Year, Month, Payment_Mode,
concat(round((Payment_Count / Total_Payments)*100,2),'%') as Payment_Mode_Trend
from cte2;

--  Insight - UPI share rose from 27.6% to 34.9% between Sept 2024 and Sept 2025,
--            while Credit Card and Net banking usage remained stable. 

# 4) Refund Rate by Payment Mode.

select Payment_Mode, Refund_Orders,
concat(round((Refund_Orders / Total_Refund_Orders)*100,2),'%') as Refund_Rate from
(select *, sum(Refund_Orders) over () as Total_Refund_Orders from 
(select t.Payment_Mode, count(r.Return_Type) as Refund_Orders
from transaction as t join refund as r on r.order_id = t.oid
where r.return_type='Refund'
group by t.Payment_Mode) as dt) as dt2
order by Refund_Orders desc;

-- Insight - Refunds are highest for Credit Card transactions (34.75%), followed by UPI (28.96%)
--           and Net Banking (27.80%), indicating slightly higher return activity among card users.

# 5) Exchange Rate by Payment Mode.

with cte1 as 
(select t.Payment_Mode, count(r.Return_Type) as Exchange_Orders
from transaction as t join refund as r on t.oid = r.order_id
where r.return_type = 'Exchange'
group by t.Payment_Mode),

cte2 as 
(select *, sum(exchange_orders) over () as Total_Exchange_Orders
from cte1)

select Payment_Mode, Exchange_Orders,
concat(round((Exchange_Orders / Total_Exchange_Orders)*100,2),'%') as Exchange_Rate
from cte2
order by Exchange_Orders desc;

-- Insight - Exchange transactions are higher for credit card users (34.44%), followed by 
--           UPI(31.54%) and Net Banking(26.56%) indicating slightly higher product replacement   
--           among card users.

# 6) High-Value Customers Payment Split

with cte1 as 
(select o.cid as Customer_ID, sum(p.price) as Total_Spend 
from orders as o join products as p on p.pid = o.pid
group by o.cid
having Total_Spend >

(select round(sum(p.price) / count(distinct o.oid),2) as Avg_Spend
from orders as o join products as p on p.pid = o.pid)), 

cte2 as 
(select o.Cid as Customer_ID, t.Payment_Mode, count(t.Payment_Mode) as PaymentMode_Count
from transaction as t join orders as o
on t.oid = o.oid
group by o.Cid,t.Payment_Mode),

cte3 as 
(select cte2.Payment_Mode, cte2.PaymentMode_Count
from cte1 join cte2 on cte1.Customer_ID = cte2.Customer_ID),

cte4 as 
(select Payment_Mode, Transactions, sum(Transactions) over () as Total_Transactions from
(select cte3.Payment_Mode, sum(PaymentMode_Count) as Transactions
from cte3
group by cte3.Payment_Mode) as dt)

select cte4.Payment_Mode,
concat(round((cte4.Transactions / cte4.Total_Transactions)*100,2),'%') as Payment_Split_Percentage
from cte4;

-- Insight - UPI slightly leads as the preferred payment modes among high value customers,
--           followed closely by Credit Card and Net banking. 

-- Refund KPI's

# 1) Total Returns

select count(return_type) as Total_Returns from Refund;

-- Insight - A total of 500 product returns were recorded, reflecting the overall volume of 
--           refund and exchange requests during the period.   

# 2) Refund vs Exchange Ratio

with cte1 as 
(select count(Return_Type) as Total_Exchanges from refund
where Return_Type = 'Exchange'),
cte2 as 
(select count(Return_Type) as Total_Refunds from refund
where Return_Type = 'Refund'),
cte3 as 
(select count(return_type) as Total_Returns
from refund)
select concat(round((cte1.Total_Exchanges / cte3.Total_Returns)*100,2),'%') as Exchange_Rate,
concat(round((cte2.Total_Refunds / cte3.Total_Returns)*100,2),'%') as Refund_Rate
from cte1, cte2, cte3;

-- Insight - Refund_Rate (51.80%) exceed Exchange_Rate (48.20%), showing  relatively 
--           higher customer preference for monetery returns over product replacements.  

# 3) Most common return reason.

select Reason from
(select reason, count(reason) as Reason_Count
from refund
group by reason
order by Reason_Count desc
limit 1) as dt;

-- Insight - The most common return reason is "Ordered by Mistake",
--           indicating frequent accidental purcahses       

--  Average Refund Value

select round((Total_Return_Value / Total_Returns),2) as Average_Return_Value from
(select count(r.order_id) as Total_Returns , sum(p.price) as Total_Return_Value 
from refund as r join orders as o on o.oid = r.order_id
join products as p on p.pid = o.pid
where r.return_type='Refund') as dt;

-- Insight - The average return value is ₹11,742 slightly higher than the
--           average transaction value (₹11,708), indicating that the customers are more
--           likely to return high-value purchases.

# 5) Product with Highest Returns.

select Product from
(select p.pname as Product, count(r.Order_ID) as Total_Returns
from refund as r join orders as o on o.oid = r.order_id
join products as p on p.pid = o.pid
group by p.pname
order by Total_Returns desc
limit 1) as dt;

-- Insight - The product with the highest number of returns is "Roadster T-Shirt X",
--           indicating possible issues related to size, fit or product expectations.  

-- Refund Insights 

# 1) Return Reason Contribution

select Reason, concat(round((Reason_Count / Total_Returns)*100,2),'%') as Return_Reason_Share from
(select *, sum(Reason_Count) over () as Total_Returns from
(select Reason, count(Reason) as Reason_Count
from refund
group by Reason) as dt) as dt2
order by Reason_Count desc;

-- Insight - "Ordered by Mistake" (19.80%) is the top return reason,
--            followed by "Item Missing" (17.60%) and "Late Delivery" (16.20%), indicating
--            frequent order errors and fulfillment delays. 
select * from refund;

# 2) Monthly Return Trend

with cte1 as 
(select year(return_date) as Year, month(return_date) as Month, count(order_id) as Refund_Count
from refund
where Return_Type = 'Refund'
group by Year, Month
order by Year, Month
),

cte2 as 
(select year(return_date) as Year, month(return_date) as Month, count(order_id) as Exchange_Count
from refund
where Return_Type = 'Exchange'
group by Year, Month
order by Year, Month),

cte3 as 
(select ifnull(cte1.Year,cte2.Year) as Year, ifnull(cte1.Month,cte2.Month) as Month,
ifnull(cte1.Refund_Count,0) as Refund_Count, ifnull(cte2.Exchange_Count,0) as Exchange_Count
from cte1 left join cte2 on cte1.Year = cte2.Year and cte1.Month = cte2.Month
union
select ifnull(cte1.Year,cte2.Year) as Year, ifnull(cte1.Month,cte2.Month) as Month,
ifnull(cte1.Refund_Count,0) as Refund_Count, ifnull(cte2.Exchange_Count,0) as Exchange_Count
from cte1 right join cte2 on cte1.Year = cte2.Year and cte1.Month = cte2.Month)

select Year, Month, 
concat(round((Refund_Count / Month_Total_Retruns)*100,2),'%') as Refund_Rate,
concat(round((Exchange_Count / Month_Total_Retruns)*100,2),'%') as Exchange_Rate from
(select *, (Refund_Count + Exchange_Count) as Month_Total_Retruns
from cte3) as dt
order by Year, Month;

-- Insight – Refund and exchange shares remained fairly balanced across months,
--           averaging around 55% refunds vs 45% exchanges, 
--           indicating consistent return patterns and effective post-purchase handling.
 
# 3) City-wise Return Rate

with cte1 as 
(select c.City, count(r.Return_Type) Refund_Orders
from customers as c join orders as o on c.cid = o.cid
join refund as r on r.order_id = o.oid
where r.Return_Type = 'Refund'
group by c.City),

cte2 as 
(select c.City, count(r.Return_Type) Exchange_Orders
from customers as c join orders as o on c.cid = o.cid
join refund as r on r.order_id = o.oid
where r.Return_Type = 'Exchange'
group by c.City),

cte3 as 
(select *, (Refund_Orders + Exchange_Orders) as Total_Return_Orders from
(select cte1.City, cte1.Refund_Orders, cte2.Exchange_Orders
from cte1 join cte2 on cte1.City = cte2.City) as dt)
select City, 
concat(round((Refund_Orders / Total_Return_Orders)*100,2),'%') as City_wise_Refund_Rate,
concat(round((Exchange_Orders / Total_Return_Orders)*100,2),'%') as City_wise_Exchange_Rate 
from cte3;

-- Insight - Refunds dominate in Noida (59.14%) and Pune (53.15%), while exchanges are higher in
--           Delhi (56.52%) and Kolkata (52.69%), Mumbai shows a balanced return pattern (50%-50%).

# 4) Top 5 Most Returned Products

select p.pname as Product_Name,  count(r.return_type) as Product_Returns
from refund as r join orders as o on r.order_id = o.oid
join products as p on p.pid = o.pid
group by p.pname
order by Product_Returns desc
limit 5;

-- Insight - "Roadster T-Shirt X" has the highest returns (5), followed by "Bajaj Mixer Grinder Prime",
--           "Inalsa Air Fryer Max", "Mi Power Bank Air", and "Maybelline Lipstick Prime"
--   (4 each), indicating returns are concentrated among a few key products across categories.

# 5) Return (Refund and Exchange)-to-sales ratio trend (monthly)

with cte1 as 
(select Year(o.order_date) as Year, Month(o.order_date) as Month, sum(p.price) as Month_wise_Sales 
from orders as o join products as p on p.pid = o.pid
group by Year,Month),

cte2 as 
(select year(r.return_date) as Year, month(r.return_date) as Month,
sum(p.price) as Month_wise_Refund_Amt 
from refund as r join orders as o on o.oid = r.order_id
join products as p on o.pid = p.pid
where r.return_type='Refund'
group by Year, Month),
# order by Year, Month

cte3 as 
(select year(r.return_date) as Year, month(r.return_date) as Month,
sum(p.price) as Month_wise_Exchange_Amt 
from refund as r join orders as o on o.oid = r.order_id
join products as p on o.pid = p.pid
where r.return_type='Exchange'
group by Year, Month),
# order by Year, Month

cte4 as 
(select 
ifnull(cte1.Year,cte3.Year) as Year,
ifnull(cte1.Month,cte3.Month) as Month,
ifnull(cte1.Month_wise_Sales,0) as Month_wise_Sales ,
ifnull(cte2.Month_wise_Refund_Amt,0) as Month_wise_Refund_Amt ,
ifnull(cte3.Month_wise_Exchange_Amt,0) as Month_wise_Exchange_Amt
from cte1
left join cte2 on cte1.Year = cte2.Year and cte1.Month = cte2.Month
left join cte3 on cte1.Year = cte3.Year and  cte1.Month = cte3.Month

union

select 
ifnull(cte1.Year,cte3.Year) as Year, 
ifnull(cte1.Month,cte3.Month) as Month,
ifnull(cte1.Month_wise_Sales,0) as Month_wise_Sales ,
ifnull(cte2.Month_wise_Refund_Amt,0) as Month_wise_Refund_Amt ,
ifnull(cte3.Month_wise_Exchange_Amt,0) as Month_wise_Exchange_Amt
from cte1 
right join cte2 on cte1.Year = cte2.Year and cte1.Month = cte2.Month
right join cte3 on cte1.Year = cte3.Year and  cte1.Month = cte3.Month)

select Year, Month, 
ifnull(concat(round((Month_wise_Refund_Amt / Month_wise_Sales)*100,2),'%'),'N/A') as Refund_to_Sales_Ratio,
ifnull(concat(round((Month_wise_Exchange_Amt / Month_wise_Sales)*100,2),'%'),'N/A') as Exchange_to_Sales_Ratio
from cte4
order by Year, Month;

-- Insight - Refund and exchange shares averaged around 5% of monthly sales, while refunds
--           peaking in April 2025 (7.23%) and exchanges in January 2025 (7.80%), reflecting
--           fluctuating customer return activity over time.

# 6) Refund Rate by Payment Mode

with cte1 as
(select *, sum(Refund_Transactions) over () as Total_Refund_Transactions from
(select t.Payment_Mode, count(r.return_type) as Refund_Transactions
from transaction as t join refund as r on r.order_id = t.oid
where r.return_type='Refund'
group by  t.payment_mode) as dt)

select Payment_Mode,
concat(round((Refund_Transactions / Total_Refund_Transactions)*100,2),'%') as Refund_Rate 
from cte1
order by Refund_Transactions desc; 

-- Insight - Credit Card refunds lead at (34.75%), followed closely by UPI (28.96%) and
--           Net Banking (27.80%), showing relatively even refund distribution across payment modes.   

# 7) Repeat Returners (One-time and Occasional)

with cte1 as 
(select c.CID , count(c.cid)  as No_of_returns
from customers as c join orders as o on c.cid = o.cid
join refund as r on r.order_id = o.oid
group by c.cid),

cte2 as 
(select *, case
when No_of_returns = 1 then 'One_Time Returner'
when No_of_returns = 2 or No_of_returns = 3  then 'Occasional Returner'
end as Returner_Type
from cte1),

cte3 as 
(select count(cid) as Total_Returners from cte1),

cte4 as 
(select count(Returner_Type) as One_Time_Returners 
from cte2 where Returner_Type = 'One_Time Returner'),

cte5 as
(select count(Returner_Type) as Occasional_Returners 
from cte2 where Returner_Type = 'Occasional Returner')

select concat(round((cte4.One_Time_Returners / cte3.Total_Returners)*100,2),'%') as One_Time_Returners_Rate,
concat(round((cte5.Occasional_Returners / cte3.Total_Returners)*100,2),'%') as Ocassional_Returners_Rate 
from cte3,cte4,cte5;

-- Insight – The majority of customers (84.7%) return items only once,
--           while 15.3% are occasional returners, indicating overall strong customer 
--           satisfaction with minimal repeat return behavior.

-- Feedback KPI's

# 1) Average Product Rating

select round(avg(prod_rating),2) as Average_Product_Rating from feedback;

-- Insight - The average product rating is 2.99, indicating moderate product satisfaction. 

# 2) Average Delivery Rating

select round(avg(delivery_rating),2) as Average_Delivery_Rating from feedback;

-- Insight - The average delivery rating is 3, showing marginally better satisfaction with
--           delivery compared to products.  

# 3) Total Feedbacks Received

select count(distinct oid) as Total_Feedbacks from feedback;

-- Insight - A total of 5,000 feedback entries were received, reflecting strong
--           customer engagement and sentiment coverage.  

-- Feedback Insights 

# 1) Top 10 Highest Rated Products.

select p.pname as Product_Name, round(avg(f.prod_rating),2) as Average_Rating 
from products as p join orders as o on p.pid = o.pid
join feedback as f on f.oid = o.oid
group by p.pname
order by Average_Rating desc
limit 10;

-- Insight - "Lavie Handbag Prime" and "Prestige Induction Cooktop Pro" are the highest-
--            rated products (avg. 4.5), followed by "Pantene Shampoo S" and "Nokia Smartphone Mini"
--            (4.4), demonstrating strong customer satisfaction across fashion , personal care, 
--            electronics segments.

# 2) City wise Average Prod Rating and Delivery Rating. 

select c.City, round(avg(f.prod_rating),2) as Average_Product_Rating,
round(avg(f.delivery_rating),2) as Average_Delivery_Rating
from customers as c join orders as o on c.cid = o.cid
join feedback as f on f.oid = o.oid
group by c.City
order by c.City;

-- Insight - Mumbai has the highest product rating (3.06), and Delhi leads in
--           delivery experience (3.10). Overall ratings (2.9-3.1) indicate moderate but 
--           consistent satisfaction across cities.     
  
# 3) Product Rating wise Exchange Rate and Refund Rate

with cte1 as 
(select f.Prod_Rating, count(r.return_type) as Total_Returns
from feedback as f join refund as r on r.order_id = f.oid
group by f.prod_rating
order by prod_rating), 

cte2 as 
(select f.Prod_Rating, count(r.return_type) as Exchange_Returns
from feedback as f join refund as r on r.order_id = f.oid
where r.return_type = 'Exchange'
group by f.prod_rating
order by prod_rating),

cte3 as 
(select f.Prod_Rating, count(r.return_type) as Refund_Returns
from feedback as f join refund as r on r.order_id = f.oid
where r.return_type = 'Refund'
group by f.prod_rating
order by prod_rating),

cte4 as 
(select cte1.Prod_Rating, cte2.Exchange_Returns, cte3.Refund_Returns, cte1.Total_Returns
from cte1 join cte2 on cte1.prod_rating = cte2.prod_rating
join cte3 on cte1.prod_rating = cte3.prod_rating)

select concat(Prod_Rating,' star') as Product_Rating,
concat(round((Exchange_Returns / Total_Returns)*100,2),'%') as Exchange_Rate,
concat(round((Refund_Returns / Total_Returns)*100,2),'%') as Refund_Rate
from cte4;

-- Insight - Refunds are slightly higher for (1-2 star) items, while exchanges dominate for 
--           (3-5 star) ratings, showing loyalty-driven replacement behavior among satisfied customers.

# 4) Top 10 Lowest Rated Products

select p.pname as Product_Name, round(avg(f.prod_rating),2) as Product_Rating
from feedback as f join orders as o on o.oid = f.oid
join products as p on p.pid = o.pid
group by p.pname
order by Product_Rating
limit 10;

-- Insight - "Philips Bluetooth Speaker S" (1.33) and "Acer Monitor Fit" (1.4), 
--           are the lowest-rated products, with most products below 2 star,
--           indicating quality and performance concerns require attention.   

# 5) Product Rating Distribution (Customer Sentiment Spread).

with cte1 as
(select *, sum(Orders_Count) over () as Total_Orders from
(select concat(prod_rating,' star') as Product_Rating , count(prod_rating) as Orders_Count
from feedback
group by Product_Rating
order by Product_Rating desc) as dt)

select Product_Rating, Orders_Count,
concat(round((Orders_Count / Total_Orders)*100,2),'%') as Share
from cte1; 

-- Insight - The product rating is fairly balanced, with 3 star ratings leading at 20.7%.
--           Positive raings (4-5 star) and negative ratings (1-2 star) each contribute around 40%,
--           indicating a mixed customer sentiment with room for improvement in product satisfaction.     

# 6) Average Product and Delivery Rating Trend Over Time (Monthly/Yearly).

select year(o.order_date) as Year, month(o.order_date) as Month,
round(avg(f.prod_rating),2) as Average_Product_Rating,
round(avg(f.delivery_rating),2) as Average_Delivery_Rating
from orders as o join feedback as f on o.oid = f.oid 
group by Year, Month
order by Year, Month;

-- Insight - Product (2.82-3.22) and delivery (2.83-3.12) ratings remained steady around 3 star.
--           Product peaked in Sept 2024 (3.22) and delivery in Oct 2024 (3.12), reflecting 
--           consistent yet moderate satisfaction levels.
