## Provide the list of markets in which customer "Atliq Exclusive" operates its business in the APAC region

SELECT
	distinct(market) as Markets
from
	dim_customer
where
	customer="Atliq Exclusive" and region="APAC"
order by
	Markets asc;

##What is the percentage of unique product increase in 2021 vs. 2020?
#The final output contains these fields,
#unique_products_2020
#unique_products_2021
#percentage_chg

with Product_count as (
select 
	count(distinct(case when sm.fiscal_year=2020 then sm.product_code end)) as unique_products_2020,
    count(distinct(case when sm.fiscal_year=2021 then sm.product_code end)) as unique_products_2021
from
	fact_sales_monthly sm)

select
	unique_products_2020, unique_products_2021,
	round((unique_products_2021-unique_products_2020)*100/unique_products_2020,1) as percentage_chg
from
	Product_count;

#Alternate method

select
	sm.a as unique_products_2020, s.b as unique_products_2020, (s.b-sm.a)*100/sm.a as percentage_chg
from
	((select count(distinct(product_code)) as a from fact_sales_monthly where fiscal_year=2020) sm,
	(select count(distinct(product_code)) as b from fact_sales_monthly where fiscal_year=2021) s);


##Provide a report with all the unique product counts for each segment and sort them in descending order of product counts.
#The final output contains,
#segment
#product_count
 
SELECT 
	segment, count(distinct(product_code)) as Product_count
from 
	dim_product
group by
	segment
order by
	Product_count desc;


##Which segment had the most increase in unique products in 2021 vs 2020?
#The final output contains these fields,
#segment
#product_count_2020
#product_count_2021
#difference

with Product_count as(
select
	p.segment,
	count(distinct case when sm.fiscal_year=2020 then p.product_code end) as product_count_2020,
    count(distinct case when sm.fiscal_year=2021 then p.product_code end) as product_count_2021
    from dim_product p
    join fact_sales_monthly sm
    using(product_code)
    group by p.segment)

select segment,
	product_count_2020,
    product_count_2021,
    coalesce(product_count_2021,0)-coalesce(product_count_2020,0) as Difference
from
		Product_count
order by Difference DESC;


##Get the products that have the highest and lowest manufacturing costs.
#The final output should contain these fields,
#product_code
#product
#manufacturing_cost
with Cost as(
	select
    max(manufacturing_cost) as Max_cost,
    min(manufacturing_cost) as Min_cost
from fact_manufacturing_cost
)

select
	p.product_code,
    p.product,
    m.manufacturing_cost
from
	dim_product p
join
	fact_manufacturing_cost m
Using (product_code)
join
	Cost c
on m.manufacturing_cost=c.Max_cost
or m.manufacturing_cost=c.Min_cost
order by m.manufacturing_cost desc;

#Alternate Method

select
	p.product_code,
	p.product,
    m.manufacturing_cost
from dim_product p
join fact_manufacturing_cost m
using (product_code)
where manufacturing_cost in
(select max(manufacturing_cost) from fact_manufacturing_cost
union
select min(manufacturing_cost) from fact_manufacturing_cost)
order by manufacturing_cost DESC;

##Generate a report which contains the top 5 customers who received an average high pre_invoice_discount_pct for the fiscal year 2021 and in the Indian market
#The final output contains these fields
#customer_code
#customer
#average_discount_percentage
select
	 c.customer_code,
	c.customer, round(avg(id.pre_invoice_discount_pct)*100,1) as average_discount_percentage
from
	dim_customer c
join 
	fact_pre_invoice_deductions id
using
	(customer_code)
where
	c.market="India" and id.fiscal_year=2021
group by
	c.customer_code, c.customer
order by
	average_discount_percentage desc
limit 5;

##Get the complete report of the Gross sales amount for the customer “Atliq Exclusive” for each month. This analysis helps to get an idea of low and high-performing months and take strategic decisions
#The final report contains these columns
#Month
#Year
#Gross sales Amount

select
	monthname(sm.date) as Month , g.fiscal_year,
	Concat(round(sum(sm.sold_quantity*g.gross_price)/1000000,2), "M") as Gross_sales_amount_mln
from fact_gross_price g 
join fact_sales_monthly sm
using(product_code, fiscal_year)
join dim_customer c
on c.customer_code=sm.customer_code
where customer="Atliq Exclusive"
group by Month, g.fiscal_year;


##In which quarter of 2020, got the maximum total_sold_quantity?
# The final output contains these fields sorted by the total_sold_quantity,
#Quarter
#total_sold_quantity

select
	case
	when month(s.date) in (9,10,11) then "Q1"
	when month(s.date) in (12,1,2) then "Q2"
	when month(s.date) in (3,4,5) then "Q3"
	else "Q4"
end as Quarter,
	sum(s.sold_quantity) as Total_sold_quantity
from
	fact_sales_monthly s
where
	fiscal_year=2020
group by Quarter
order by Total_sold_quantity Desc;


##Which channel helped to bring more gross sales in the fiscal year 2021 and the percentage of contribution?
#The final output contains these fields,
#channel
#gross_sales_mln
#percentage


with bb as (
	select
		c.channel, round(Sum(sm.sold_quantity*g.gross_price)/1000000,1) as Gross_sales_in_mln
	from
		fact_sales_monthly sm
	join
		fact_gross_price g
	using(product_code, fiscal_year)
	join
		dim_customer c
	on sm.customer_code=c.customer_code
	where fiscal_year=2021
	Group by c.channel)

select 
	channel, Gross_sales_in_mln,
	round(Gross_sales_in_mln*100/(select sum(Gross_sales_in_mln) from bb),1) as PCT
from bb
;
    
##Get the Top 3 products in each division that have a high total_sold_quantity in the fiscal_year 2021?
#The final output contains these fields,
#division
#product_code
#product
#total_sold_quantity
#rank_order

with Rank_order as(    
	select 
		p.division, p.product_code, p.product, sum(sm.sold_quantity) as QTY,
		dense_rank() over( partition by p.division order by sum(sm.sold_quantity) desc) as Rank_order
	from
		fact_sales_monthly sm
	join
		dim_product p
	using (product_code)
	where
		fiscal_year=2021
	group by p.division, p.product_code,p.product)

select *
from Rank_order
where Rank_order in (1,2,3)
order by division;