
# load libraries ----------------------------------------------------------

library(tidyverse) # data science package
library(lubridate) # to work with dates and times
library(RH2) # to connect to H2 database
library(sqldf) # to run SQL statements
library(janitor) # to clean df after reading a file


#sqldf supports the SQLite backend database (by default),the H2 java database, the PostgreSQL database and 
#sqldf 0.4-0 onwards also supports MySQL.

# set working directory ---------------------------------------------------

setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

df<-read.csv("sample_superstore.csv") %>%
  clean_names() %>% # janitor library function whicl cleans up columns names
  mutate(ship_date=mdy(ship_date), # convert date columns into date format
         order_date=mdy(order_date)) %>%
  mutate_if(is.factor, as.character) # convert factor columns into character cols
  
#1.What are the customer IDs of customers having ever received a shipment in LA--------

query1<- "SELECT DISTINCT customer_id
FROM df
WHERE LOWER(city) = 'los angeles'"

#automatic conversion of unmatched character columns to factor, can be disabled while still 
#performing the first step by setting the stringsAsFactors argument to FALSE
results1<-sqldf(query1,stringsAsFactors = FALSE)
head(results1)


# 2.What is the total sales value of the shipments in region West? --------------

query2<- "SELECT SUM(sales) AS total_value_west
FROM df
WHERE LOWER(region) = 'west'"

results2<-sqldf(query2,stringsAsFactors = FALSE)
head(results2)

#3. What is the number of units shipped for the subcategory phones in 2014?

query3<-"SELECT SUM(quantity) as phones_units
FROM df
WHERE LOWER(sub_category) = 'phones'
AND YEAR(ship_date) = 2014"

results3<-sqldf(query3,stringsAsFactors = FALSE)
head(results3)

#4. Which region has the highest total sales value for products shipped in 2016?

query4<-"SELECT region
FROM (SELECT region, SUM(sales) as tot_value
      FROM df
      WHERE YEAR(ship_date) =2016
      GROUP BY region
      ORDER BY 2 DESC)
WHERE tot_value =(SELECT MAX(tot_value) as max_value
FROM (SELECT region, SUM(sales) as tot_value
      FROM df
      WHERE YEAR(ship_date) =2016
      GROUP BY region
      ORDER BY 2 DESC)
)
"

results4<-sqldf(query4,stringsAsFactors = FALSE)
head(results4)

#option 2 using HAVING
query4_2<-"
SELECT region
FROM (SELECT region,SUM(sales) as tot_value
      FROM df
      WHERE YEAR(ship_date) =2016
      GROUP BY region
      HAVING tot_value = (SELECT MAX(tot_value) as max_value
      FROM (SELECT region, SUM(sales) as tot_value
      FROM df
      WHERE YEAR(ship_date) =2016
      GROUP BY region)
      )
) 
"
results4_2<-sqldf(query4_2,stringsAsFactors = FALSE)
head(results4_2)


# 5.For each order, list products, their sales value and their contribution to the overall sales amount for the related subcategory --------

query5<-"
SELECT order_id,product_id,product_name,category,df.sub_category,sales,tot_sales_subcat,
ROUND((sales/tot_sales_subcat)*100,2) as rate
FROM df
LEFT JOIN (SELECT sub_category,SUM(sales) as tot_sales_subcat
FROM df
GROUP BY sub_category) as subcat 
ON subcat.sub_category=df.sub_category
"
results5<-sqldf(query5,stringsAsFactors = FALSE)
head(results5)

# 6. What was the best month for sales in 2017? How much was earned that month? --------

query6<- "
SELECT month,tot_sales,tot_profit
FROM
(
SELECT MONTH(order_date) as month, SUM(sales) as tot_sales, SUM(profit) as tot_profit
FROM df
WHERE YEAR(order_date) = 2017
GROUP BY MONTH(order_date)
)
WHERE tot_sales = (SELECT MAX(tot_sales) FROM (SELECT MONTH(order_date) as month, SUM(sales) as tot_sales, SUM(profit) as tot_profit
FROM df
WHERE YEAR(order_date) = 2017
GROUP BY MONTH(order_date))
)

"

results6<-sqldf(query6,stringsAsFactors = FALSE)
head(results6)

