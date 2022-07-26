/* 데이터 : Instacart 라는 e-commerce 회사의 데이터 (kaggle)
[Table]
aisles, departments : 상품 카테고리
order_products__prior : 각 주문 번호의 상세 구매 내역
orders : 주문 대표 정보
products : 상품 정보	*/

## 1. 지표 추출

#	1) 전체 구매 건수
SELECT COUNT(DISTINCT order_id) F
FROM instacart.orders;

#	2) 구매자 수
SELECT COUNT(DISTINCT user_id) BU
FROM instacart.orders;

#	3) 상품별 주문 건수
SELECT b.product_name, COUNT(DISTINCT a.order_id) F
FROM instacart.order_products__prior a
INNER JOIN instacart.products b ON a.product_id = b.product_id
GROUP BY 1;

#	4) 장바구니에 가장 먼저 넣는 상품 10개
#		a) order_products__prior의 product_id 별로 가장 먼저 담긴 경우 1을 출력
SELECT product_id,
CASE WHEN add_to_cart_order = 1 THEN 1 ELSE 0 END f_1st
FROM instacart.order_products__prior;

#		b) product_id로 그룹핑, f_1st 칼럼 합해서 상품별로 장바구니에 가장 먼저 담긴 건수 계산
SELECT product_id,
SUM(CASE WHEN add_to_cart_order = 1 THEN 1 ELSE 0 END) f_1st
FROM instacart.order_products__prior
GROUP BY 1;

#		c) f_1st로 순서 매기기
SELECT *,
ROW_NUMBER() OVER(ORDER BY f_1st DESC) RNK
FROM (SELECT product_id,
SUM(CASE WHEN add_to_cart_order = 1 THEN 1 ELSE 0 END) f_1st
FROM instacart.order_products__prior
GROUP BY 1) a;

#		d) 1~10위의 상품 번호 뽑기
SELECT *
FROM (SELECT *,
ROW_NUMBER() OVER(ORDER BY f_1st DESC) RNK
FROM (SELECT product_id,
SUM(CASE WHEN add_to_cart_order = 1 THEN 1 ELSE 0 END) f_1st
FROM instacart.order_products__prior
GROUP BY 1) a) a
WHERE RNK BETWEEN 1 AND 10;

#		e) order by 사용해 간단히 상위 10개 데이터 호출 가능
SELECT product_id,
SUM(CASE WHEN add_to_cart_order = 1 THEN 1 ELSE 0 END) f_1st
FROM instacart.order_products__prior
GROUP BY 1
ORDER BY 2 DESC
LIMIT 10;

#	5) 시간별 주문 건수
SELECT order_hour_of_day, COUNT(DISTINCT order_id) F
FROM instacart.orders
GROUP BY 1
ORDER BY 1;

#	6) 첫 구매 후 다음 구매까지 걸린 평균 일수
SELECT AVG(days_since_prior_order) avg_recency
FROM instacart.orders
WHERE order_number = 2;

#	7) 주문 건당 평균 구매 상품 수 (UPT, Unit Per Transaction)
SELECT COUNT(product_id)/COUNT(DISTINCT order_id) UPT
FROM instacart.order_products__prior;

#	8) 인당 평균 주문 건수
SELECT COUNT(DISTINCT order_id)/COUNT(DISTINCT user_id) avg_f
FROM instacart.orders;

#	9) 재구매율이 가장 높은 상품 10개
#		a) 상품별 재구매율 계산
SELECT product_id,
SUM(CASE WHEN reordered = 1 THEN 1 ELSE 0 END)/COUNT(*) ret_ratio
FROM instacart.order_products__prior
GROUP BY 1;

#		b) 재구매율로 랭크 열 생성하기
SELECT *,
ROW_NUMBER() OVER(ORDER BY ret_ratio DESC) RNK
FROM (SELECT product_id,
SUM(CASE WHEN reordered = 1 THEN 1 ELSE 0 END)/COUNT(*) ret_ratio
FROM instacart.order_products__prior
GROUP BY 1) a;

#		c) Top 10(재구매율) 상품 추출
SELECT *
FROM (SELECT *,
ROW_NUMBER() OVER(ORDER BY ret_ratio DESC) RNK
FROM (SELECT product_id,
SUM(CASE WHEN reordered = 1 THEN 1 ELSE 0 END)/COUNT(*) ret_ratio
FROM instacart.order_products__prior
GROUP BY 1) a) a
WHERE RNK BETWEEN 1 AND 10;

#	10) Department 별 재구매율이 가장 높은 상품 10개
SELECT *
FROM (SELECT *,
ROW_NUMBER() OVER(ORDER BY ret_ratio DESC) RNK
FROM (SELECT c.department, b.product_id,
SUM(CASE WHEN reordered = 1 THEN 1 ELSE 0 END)/COUNT(*) ret_ratio
FROM instacart.order_products__prior a
INNER JOIN instacart.products b ON a.product_id = b.product_id
INNER JOIN instacart.departments c ON b.department_id = c.department_id
GROUP BY 1,2) A) A
WHERE RNK BETWEEN 1 AND 10;


## 2. 구매자 분석 (10분위 분석)

#	1) 주문 건수에 따른 Rank 생성
SELECT *,
ROW_NUMBER() OVER(ORDER BY f DESC) RNK
FROM (SELECT user_id, COUNT(DISTINCT order_id) f
FROM instacart.orders
GROUP BY 1) A;

#	2) 전체 고객 수 계산
SELECT COUNT(DISTINCT user_id)
FROM (SELECT user_id, COUNT(DISTINCT order_id) f
FROM instacart.orders
GROUP BY 1) A;		# 3159명

#	3) 각 등수에 따른 분위 수 설정
SELECT *,
CASE WHEN RNK <= 316 THEN 'Quantile_1'
WHEN RNK <= 632 THEN 'Quantile_2'
WHEN RNK <= 948 THEN 'Quantile_3'
WHEN RNK <= 1264 THEN 'Quantile_4'
WHEN RNK <= 1580 THEN 'Quantile_5'
WHEN RNK <= 1895 THEN 'Quantile_6'
WHEN RNK <= 2211 THEN 'Quantile_7'
WHEN RNK <= 2527 THEN 'Quantile_8'
WHEN RNK <= 2843 THEN 'Quantile_9'
WHEN RNK <= 3159 THEN 'Quantile_10' END quantile
FROM (SELECT *,
ROW_NUMBER() OVER(ORDER BY f DESC) RNK
FROM (SELECT user_id, COUNT(DISTINCT order_id) f
FROM instacart.orders
GROUP BY 1) A) A;

#	4) 위 조회 결과를 테이블로 생성 user_id 별 분위수 정보 생성
CREATE TEMPORARY TABLE instacart.user_quantile
AS
SELECT *,
CASE WHEN RNK <= 316 THEN 'Quantile_1'
WHEN RNK <= 632 THEN 'Quantile_2'
WHEN RNK <= 948 THEN 'Quantile_3'
WHEN RNK <= 1264 THEN 'Quantile_4'
WHEN RNK <= 1580 THEN 'Quantile_5'
WHEN RNK <= 1895 THEN 'Quantile_6'
WHEN RNK <= 2211 THEN 'Quantile_7'
WHEN RNK <= 2527 THEN 'Quantile_8'
WHEN RNK <= 2843 THEN 'Quantile_9'
WHEN RNK <= 3159 THEN 'Quantile_10' END quantile
FROM (SELECT *,
ROW_NUMBER() OVER(ORDER BY f DESC) RNK
FROM (SELECT user_id, COUNT(DISTINCT order_id) f
FROM instacart.orders
GROUP BY 1) A) A;

#	5) 각 분위 수별 전체 주문 건수의 합 구하기
SELECT quantile, SUM(f) f
FROM instacart.user_quantile
GROUP BY 1;

#	6) 전체 주문 건수 계산, 각 분위 수의 주문 건수를 전체 주문 건수로 나누기
SELECT SUM(f) FROM instacart.user_quantile;		#3220

SELECT quantile, SUM(f)/3220 f
FROM instacart.user_quantile
GROUP BY 1;


## 3. 상품 분석 : 재구매 비중이 높은 상품 찾기

#	1) 상품별 재구매 비중(%)과 주문 건수 계산
SELECT product_id,
SUM(reordered)/SUM(1) reordered_rate,
COUNT(DISTINCT order_id) f
FROM instacart.order_products__prior
GROUP BY product_id
ORDER BY reordered_rate DESC;

#	2) 주문 건수가 일정 건수(10건) 이하인 상품 제외
SELECT a.product_id,
SUM(reordered)/SUM(1) reordered_rate,
COUNT(DISTINCT order_id) F
FROM instacart.order_products__prior a
INNER JOIN instacart.products b ON a.product_id = b.product_id
GROUP BY product_id
HAVING COUNT(DISTINCT order_id) > 10;

#	3) 재구매율 높은 상품 찾기
SELECT a.product_id, b.product_name,
SUM(reordered)/SUM(1) reordered_rate,
COUNT(DISTINCT order_id) f
FROM instacart.order_products__prior a
INNER JOIN instacart.products b ON a.product_id = b.product_id
GROUP BY a.product_id, b.product_name
HAVING COUNT(DISTINCT order_id) > 10;


## 4. 다음 구매까지의 소요 기간과 재구매 관계
# 가정 : '고객이 자주 재구매하는 상품은 그렇지 않은 상품보다 일정한 주기를 가질 것이다'

#	1) 상품별 재구매율 계산, 가장 높은 순서대로 순위 매기기
SELECT *
FROM (SELECT *,
ROW_NUMBER() OVER(ORDER BY ret_ratio DESC) RNK
FROM (SELECT product_id,
SUM(CASE WHEN reordered = 1 THEN 1 ELSE 0 END)/COUNT(*) ret_ratio
FROM instacart.order_products__prior
GROUP BY 1) A) A;

#	2) 각 삼품을 10개의 그룹으로 나누기
CREATE TEMPORARY TABLE instacart.product_repurchase_quantile
AS
SELECT a.product_id,
CASE WHEN RNK <= 929 THEN 'Q_1'
WHEN RNK <= 1858 THEN 'Q_2'
WHEN RNK <= 2786 THEN 'Q_3'
WHEN RNK <= 3715 THEN 'Q_4'
WHEN RNK <= 4644 THEN 'Q_5'
WHEN RNK <= 5573 THEN 'Q_6'
WHEN RNK <= 6502 THEN 'Q_7'
WHEN RNK <= 7430 THEN 'Q_8'
WHEN RNK <= 8359 THEN 'Q_9'
WHEN RNK <= 9288 THEN 'Q_10' END rnk_grp
FROM (SELECT *,
ROW_NUMBER() OVER(ORDER BY ret_ratio DESC) RNK
FROM (SELECT product_id,
SUM(CASE WHEN reordered = 1 THEN 1 ELSE 0 END)/COUNT(*) ret_ratio
FROM instacart.order_products__prior
GROUP BY 1) A) A
GROUP BY 1,2;

#	3) 각 분위 수별로 재구매 소요 시간의 분산 구하기
/* 각 분위 수별 재구매 소요 시간의 분산을 구하려면 다음과 같은 정보를 결합해 구해야 함
1. 상품별 분위 수 : product_repurchase_quantile
2. 주문 소요 시간 : instacart.orders
3. 주문 번호와 상품 번호 : instacart.order_products__prior */

#		a) product_id의 days_since_prior_order 테이블 생성
CREATE TEMPORARY TABLE instacart.order_products__prior2
AS
SELECT a.product_id, b.days_since_prior_order
FROM instacart.order_products__prior a
INNER JOIN instacart.orders b ON a.order_id = b.order_id;

#		b) 결합한 테이블에서 분위수, 상품별 구매 소요 기간의 분산 계산
SELECT a.rnk_grp, a.product_id,
VARIANCE(days_since_prior_order) var_days
FROM instacart.product_repurchase_quantile a
INNER JOIN instacart.order_products__prior2 b ON a.product_id = b.product_id
GROUP BY 1,2
ORDER BY 1;

#	4) 각 분위 수의 상품 소요 기간 분산의 중위 수 계산 (MySQL에서는 Median 함수 제공 X -> 평균으로 대체)
SELECT rnk_grp, AVG(var_days) avg_var_days
FROM (SELECT a.rnk_grp, a.product_id,
VARIANCE(days_since_prior_order) var_days
FROM instacart.product_repurchase_quantile a
INNER JOIN instacart.order_products__prior2 b ON a.product_id = b.product_id
GROUP BY 1,2) A
GROUP BY 1
ORDER BY 1;