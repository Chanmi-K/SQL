# data : mysqlsampledatabase
# 자동차 매출 데이터를 이용한 리포트 작성

# 1.구매 지표 추출 2.그룹별 구매 지표 구하기 3.재구매율 4.Best Seller 5.Churn Rate(%)


## 1.구매 지표 추출

#	1) 매출액 (일자별, 월별, 연도별)
#		a) 일별 매출액 조회
SELECT a.orderdate, SUM(priceeach*quantityordered) AS sales
FROM classicmodels.orders a
INNER JOIN classicmodels.orderdetails b ON a.ordernumber = b.ordernumber
GROUP BY 1
ORDER BY 1;

#		b) 월별 매출액 조회
SELECT SUBSTR(a.orderdate,1,7) MM, SUM(priceeach*quantityordered) AS sales
FROM classicmodels.orders a
INNER JOIN classicmodels.orderdetails b ON a.ordernumber = b.ordernumber
GROUP BY 1
ORDER BY 1;

#		c) 연도별 매출액 조회
SELECT SUBSTR(a.orderdate,1,4) YY, SUM(priceeach*quantityordered) AS sales
FROM classicmodels.orders a
INNER JOIN classicmodels.orderdetails b ON a.ordernumber = b.ordernumber
GROUP BY 1
ORDER BY 1;

#	2) 구매자 수, 구매 건수(일자별) (월별, 연도별 : 매출액 처럼 substr 사용)
SELECT orderdate, 
COUNT(DISTINCT customernumber) n_purchaser,
COUNT(ordernumber) n_orders
FROM classicmodels.orders
GROUP BY 1
ORDER BY 1;

#	3) 인당 매출액(연도별)
SELECT SUBSTR(a.orderdate,1,4) YY,
COUNT(DISTINCT a.customernumber) n_purchaser,
SUM(priceeach*quantityordered) sales,
SUM(priceeach*quantityordered) / COUNT(DISTINCT a.customernumber) AMV
FROM classicmodels.orders a
INNER JOIN classicmodels.orderdetails b ON a.ordernumber = b.ordernumber
GROUP BY 1
ORDER BY 1;

#	4) 건당 구매 금액(ATV) (연도별)
SELECT SUBSTR(a.orderdate,1,4) YY,
COUNT(DISTINCT a.ordernumber) n_purchaser,
SUM(priceeach*quantityordered) sales,
SUM(priceeach*quantityordered) / COUNT(DISTINCT a.ordernumber) ATV
FROM classicmodels.orders a
INNER JOIN classicmodels.orderdetails b ON a.ordernumber = b.ordernumber
GROUP BY 1
ORDER BY 1;


## 2.그룹별 구매 지표 구하기

#	1) 국가별, 도시별 매출액
SELECT c.country, c.city, SUM(priceeach*quantityordered) sales
FROM classicmodels.orders a
INNER JOIN classicmodels.orderdetails b ON a.ordernumber = b.ordernumber
INNER JOIN classicmodels.customers c ON a.customernumber = c.customernumber
GROUP BY 1, 2
ORDER BY 1, 2;

#	2) 북미(USA, Canada) vs 비북미 매출액 비교
SELECT CASE WHEN country IN ('USA','Canada') THEN 'North America' ELSE 'Others' END country_grp,
SUM(priceeach*quantityordered) sales
FROM classicmodels.orders a
INNER JOIN classicmodels.orderdetails b ON a.ordernumber = b.ordernumber
INNER JOIN classicmodels.customers C ON a.customernumber = c.customernumber
GROUP BY 1
ORDER BY 2 DESC;

#	3) 매출 Top 5 국가 및 매출
SELECT *
FROM (SELECT country, sales, DENSE_RANK() OVER(ORDER BY sales DESC) RNK
FROM (SELECT c.country, SUM(priceeach*quantityordered) sales
FROM classicmodels.orders a
INNER JOIN classicmodels.orderdetails b ON a.ordernumber = b.ordernumber
INNER JOIN classicmodels.customers C ON a.customernumber = c.customernumber
GROUP BY 1) A) A
WHERE RNK <= 5;


## 3.재구매율

#	재구매 파악 데이터
SELECT a.customernumber, a.orderdate,
b.customernumber, b.orderdate
FROM classicmodels.orders a
LEFT JOIN classicmodels.orders b ON a.customernumber = b.customernumber
AND SUBSTR(a.orderdate,1,4) = SUBSTR(b.orderdate,1,4)-1;

#	1) 국가별 2004, 2005 Retention Rate(%)
SELECT c.country,
SUBSTR(a.orderdate,1,4) YY,
COUNT(DISTINCT a.customernumber) BU_1,
COUNT(DISTINCT b.customernumber) BU_2,
COUNT(DISTINCT b.customernumber) / COUNT(DISTINCT a.customernumber) retention_rate
FROM classicmodels.orders a
LEFT JOIN classicmodels.orders b ON a.customernumber = b.customernumber
AND SUBSTR(a.orderdate,1,4) = SUBSTR(b.orderdate,1,4)-1
LEFT JOIN classicmodels.customers c ON a.customernumber = c.customernumber
GROUP BY 1,2;


## 4.Best Seller

#	미국의 연도별 Top 5 차량 모델 추출
CREATE TABLE classicmodels.product_sales
AS
SELECT d.productname, SUM(priceeach*quantityordered) sales
FROM classicmodels.orders a
INNER JOIN classicmodels.customers b ON a.customernumber = b.customernumber
INNER JOIN classicmodels.orderdetails c ON a.ordernumber = c.ordernumber
INNER JOIN classicmodels.products d ON c.productcode = d.productcode
WHERE b.country = 'USA'
GROUP BY 1;

SELECT *
FROM (SELECT *, ROW_NUMBER() OVER(ORDER BY sales DESC) RNK
FROM classicmodels.product_sales) A
WHERE RNK <= 5
ORDER BY RNK;


## 5.Churn Rate(%) : 비활동 고객 전환 비율
# Churn : max(구매일, 접속일) 이후 일정 기간(ex.3개월) 구매, 접속하지 않은 상태

#	1) Churn Rate(%) 구하기
SELECT CASE WHEN DIFF >= 90 THEN 'CHURN' ELSE 'NON-CHURN' END CHURN_TYPE,
COUNT(DISTINCT CUSTOMERNUMBER) N_CUS
FROM (SELECT customernumber, mx_order, '2005-06-01' end_point, DATEDIFF('2005-06-01', mx_order) DIFF
FROM (SELECT customernumber, MAX(orderdate) mx_order
FROM classicmodels.orders
GROUP BY 1) BASE) BASE
GROUP BY 1;
#Churn Rate = CHURN / (CHURN + NON-CHURN) = 69 / (69+29) = 0.70... => 약 70%

#	2) Churn 고객이 가장 많이 구매한 Productline
CREATE TABLE classicmodels.churn_list
AS
SELECT CASE WHEN DIFF >= 90 THEN 'CHURN' ELSE 'NON-CHURN' END CHURN_TYPE, customernumber
FROM (SELECT customernumber, mx_order, '2005-06-01' end_point, DATEDIFF('2005-06-01', mx_order) DIFF
FROM (SELECT customernumber, MAX(orderdate) mx_order
FROM classicmodels.orders
GROUP BY 1) BASE) BASE;

SELECT d.CHURN_TYPE, c.productline, COUNT(DISTINCT b.customernumber) BU
FROM classicmodels.orderdetails a
INNER JOIN classicmodels.orders b ON a.ordernumber = b.ordernumber
INNER JOIN classicmodels.products c ON a.productcode = c.productcode
INNER JOIN classicmodels.churn_list d ON b.customernumber = d.customernumber
GROUP BY 1, 2
ORDER BY 1, 3 DESC;
