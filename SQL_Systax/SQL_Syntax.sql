## SELECT

# 1) 칼럼 조회
SELECT customernumber
FROM classicmodels.customers;

# 2) 집계 함수
SELECT SUM(amount), COUNT(checknumber)
FROM classicmodels.payments;

# 3) *(모든 결과 조회)
SELECT *
FROM classicmodels.products;

# 4) AS 칼럼명 변겅
SELECT COUNT(productcode) AS n_products, COUNT(productcode) n_products
FROM classicmodels.products;

# 5) DISTINCT 중복 제외
SELECT DISTINCT ordernumber
FROM classicmodels.orderdetails;


## FROM

# 1)
SELECT *
FROM classicmodels.products;

# 2)
USE classicmodels;
SELECT *
FROM products;


## WHERE

# 1) BETWEEN
SELECT *
FROM classicmodels.orderdetails
WHERE priceeach BETWEEN 30 AND 50;

# 2) 대소 관계 표현
SELECT *
FROM classicmodels.orderdetails
WHERE priceeach >= 30;

# 3) IN
SELECT customernumber
FROM classicmodels.customers
WHERE country IN ('USA','Canada');

# 4) NOT IN
SELECT customernumber
FROM classicmodels.customers
WHERE country NOT IN ('USA','Canada');

# 5) IS NULL
SELECT employeenumber
FROM classicmodels.employees
WHERE reportsto IS NULL;

# 6) LIKE '%TEXT%'
SELECT addressline1
FROM classicmodels.customers
WHERE addressline1 LIKE '%ST%';


## GROUP BY
SELECT country, city, COUNT(customernumber) n_customers
FROM classicmodels.customers
GROUP BY country, city;


## JOIN

# 1) LEFT JOIN (LEFT OUTER JOIN)
SELECT a.ordernumber, b.country
FROM classicmodels.orders a
LEFT JOIN classicmodels.customers b ON a.customernumber = b.customernumber;

SELECT a.ordernumber, b.country
FROM classicmodels.orders a
LEFT JOIN classicmodels.customers b ON a.customernumber = b.customernumber
WHERE b.country = 'USA';

# 2) INNER JOIN
SELECT a.ordernumber, b.country
FROM classicmodels.orders a
INNER JOIN classicmodels.customers b ON a.customernumber = b.customernumber
WHERE b.country = 'USA';


## CASE WHEN
SELECT country,
CASE WHEN country IN ('USA','Canada') THEN 'North America' ELSE 'OTHERS' END AS region
FROM classicmodels.customers;

SELECT CASE WHEN country IN ('USA','Canada') THEN 'North America' ELSE 'OTHERS' END AS region,
COUNT(customernumber) n_customers
FROM classicmodels.customers
GROUP BY CASE WHEN country IN ('USA','Canada') THEN 'North America' ELSE 'OTHERS' END;

SELECT CASE WHEN country IN ('USA','Canada') THEN 'North America' ELSE 'OTHERS' END AS region,
COUNT(customernumber) n_customers
FROM classicmodels.customers
GROUP BY 1;  #바로 위 쿼리와 동일 (1:첫번쨰 칼럼으로 그룹핑 하겠다)


## RANK, DENSE_RANK, ROW_NUMBER

# 1) buyprice 컬럼으로 순위 매기기
SELECT buyprice,
ROW_NUMBER() OVER(ORDER BY buyprice) rownumber,
RANK() OVER(ORDER BY buyprice) rnk,
DENSE_RANK() OVER(ORDER BY buyprice) denserank
FROM classicmodels.products;

# 2) buyprice 컬럼 기준. productline 별로 순위 매기기
SELECT buyprice,
ROW_NUMBER() OVER(PARTITION BY productline ORDER BY buyprice) rownumber,
RANK() OVER(PARTITION BY productline ORDER BY buyprice) rnk,
DENSE_RANK() OVER(PARTITION BY productline ORDER BY buyprice) denserank
FROM classicmodels.products;


## SUBQUERY
SELECT ordernumber
FROM classicmodels.orders
WHERE customernumber IN (SELECT customernumber 
FROM classicmodels.customers
WHERE country = 'USA');