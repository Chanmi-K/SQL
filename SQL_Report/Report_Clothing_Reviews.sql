# 데이터 : dataset2
# 상품 리뷰 데이터를 이용한 리포트 작성

# 1.Division별 평점 분포 계산 2.평점이 낮은 상품의 주요 Complain 3.연령별 Worst Department 4.Size Complain 5.Clothing ID별 Size Review


## 1.Division별 평점 분포 계산

#	1) Division별 평균 평점 계산
#		a) Division Name 별 평균 평점
SELECT divisionname, AVG(rating) avg_rate
FROM mydata.dataset2
GROUP BY 1
ORDER BY 2 DESC;

#		b) Department 별 평균 평점
SELECT departmentname, AVG(rating) avg_rate
FROM mydata.dataset2
GROUP BY 1
ORDER BY 2 DESC;

#		c) Trend의 평점 3점 이하 리뷰
SELECT *
FROM mydata.dataset2
WHERE departmentname = 'Trend'
AND rating <= 3;

#	2) case when 연령을 10세 단위로 그룹핑
SELECT CASE WHEN age BETWEEN 0 AND 9 THEN '0009'
WHEN age BETWEEN 10 AND 19 THEN '1019'
WHEN age BETWEEN 20 AND 29 THEN '2029'
WHEN age BETWEEN 30 AND 39 THEN '3039'
WHEN age BETWEEN 40 AND 49 THEN '4049'
WHEN age BETWEEN 50 AND 59 THEN '5059'
WHEN age BETWEEN 60 AND 69 THEN '6069'
WHEN age BETWEEN 70 AND 79 THEN '7079'
WHEN age BETWEEN 80 AND 89 THEN '8089'
WHEN age BETWEEN 90 AND 99 THEN '9099' END ageband,
age
FROM mydata.dataset2
WHERE departmentname = 'Trend'
AND rating <= 3;

#	3) FLOOR
SELECT FLOOR(AGE/10)*10 ageband, age
FROM mydata.dataset2
WHERE departmentname = 'Trend'
AND rating <= 3;

#		a) Trend의 평점 3점 이하 리뷰의 연령 분포
SELECT FLOOR(AGE/10)*10 ageband, COUNT(*) cnt
FROM mydata.dataset2
WHERE departmentname = 'Trend'
AND rating <= 3
GROUP BY 1
ORDER BY 2 DESC;

#		b) Department별 연령별 리뷰 수
SELECT FLOOR(AGE/10)*10 ageband, COUNT(*) cnt
FROM mydata.dataset2
WHERE departmentname = 'Trend'
GROUP BY 1
ORDER BY 2 DESC;

#		c) 50대 3점 이하 Trend 리뷰
SELECT *
FROM mydata.dataset2
WHERE departmentname = 'Trend'
AND rating <= 3
AND age BETWEEN 50 AND 59
LIMIT 10;


## 2.평점이 낮은 상품의 주요 Complain

#	1) Department Name, Clothing Name 별 평균 평점 계산
SELECT departmentname, clothingid, AVG(rating) avg_rate
FROM mydata.dataset2
GROUP BY 1,2;

#	2) Department 별 순위 생성
SELECT *,
ROW_NUMBER() OVER(PARTITION BY departmentname ORDER BY avg_rate) RNK
FROM (SELECT departmentname, clothingid, AVG(rating) avg_rate
FROM mydata.dataset2
GROUP BY 1,2) A;

#	3) 1~10위 데이터 조회
SELECT *
FROM (SELECT *,
ROW_NUMBER() OVER(PARTITION BY departmentname ORDER BY avg_rate) RNK
FROM (SELECT departmentname, clothingid, AVG(rating) avg_rate
FROM mydata.dataset2
GROUP BY 1,2) A) A
WHERE RNK <= 10;

#		a) Department별 평균 평점이 낮은 10개 상품
CREATE TEMPORARY TABLE mydata.stat
AS
SELECT *
FROM (SELECT *,
ROW_NUMBER() OVER(PARTITION BY departmentname ORDER BY avg_rate) RNK
FROM (SELECT departmentname, clothingid, AVG(rating) avg_rate
FROM mydata.dataset2
GROUP BY 1,2) A) A
WHERE RNK <= 10;

SELECT clothingid
FROM mydata.stat
WHERE departmentname = 'Bottoms';

#		b) 위의 clothingid에 해당하는 리뷰 내용 조회 방법
SELECT title, reviewtext
FROM mydata.dataset2
WHERE clothingid IN (SELECT clothingid
FROM mydata.stat
WHERE departmentname = 'Bottoms')
ORDER BY clothingid;


## 3. 연령별 Worst Department

#	1) 연령, department별 가장 낮은 점수 계산
SELECT departmentname, FLOOR(age/10)*10 ageband, AVG(rating) avg_rate
FROM mydata.dataset2
GROUP BY 1,2;

#	2) 연령별로 생성한 점수를 기준으로 Rank 계산
SELECT *,
ROW_NUMBER() OVER(PARTITION BY ageband ORDER BY avg_rate) RNK
FROM (SELECT departmentname, FLOOR(age/10)*10 ageband, AVG(rating) avg_rate
FROM mydata.dataset2
GROUP BY 1,2) a;

#	3) Rank 값이 1인 값 조회, 연령별 가장 낮은 평점을 준 Department 찾을 수 있음
SELECT *
FROM (SELECT *,
ROW_NUMBER() OVER(PARTITION BY ageband ORDER BY avg_rate) RNK
FROM (SELECT departmentname, FLOOR(age/10)*10 ageband, AVG(rating) avg_rate
FROM mydata.dataset2
GROUP BY 1,2) a) a
WHERE RNK = 1;


# 4. Size Complain

#	1) size 단어가 포함된 리뷰 구하기
SELECT reviewtext,
CASE WHEN reviewtext LIKE '%size%' THEN 1 ELSE 0 END size_yn
FROM mydata.dataset2;

#	2) size가 포함된 리뷰 수 구하기
SELECT SUM(CASE WHEN reviewtext LIKE '%size%' THEN 1 ELSE 0 END) n_size,
COUNT(*) n_total
FROM mydata.dataset2;	# 약 30% 가량이 size와 관련된 리뷰

#	3) 사이즈를 Large, Loose, Small, Tight로 상세히 나누기
SELECT SUM(CASE WHEN reviewtext LIKE '%size%' THEN 1 ELSE 0 END) n_size,
SUM(CASE WHEN reviewtext LIKE '%large%' THEN 1 ELSE 0 END) n_large,
SUM(CASE WHEN reviewtext LIKE '%loose%' THEN 1 ELSE 0 END) n_loose,
SUM(CASE WHEN reviewtext LIKE '%small%' THEN 1 ELSE 0 END) n_small,
SUM(CASE WHEN reviewtext LIKE '%tight%' THEN 1 ELSE 0 END) n_tight,
SUM(1) n_total
FROM mydata.dataset2;

#	4) 카테고리별 사이즈 리뷰 수
SELECT departmentname,
SUM(CASE WHEN reviewtext LIKE '%size%' THEN 1 ELSE 0 END) n_size,
SUM(CASE WHEN reviewtext LIKE '%large%' THEN 1 ELSE 0 END) n_large,
SUM(CASE WHEN reviewtext LIKE '%loose%' THEN 1 ELSE 0 END) n_loose,
SUM(CASE WHEN reviewtext LIKE '%small%' THEN 1 ELSE 0 END) n_small,
SUM(CASE WHEN reviewtext LIKE '%tight%' THEN 1 ELSE 0 END) n_tight,
SUM(1) n_total
FROM mydata.dataset2
GROUP BY 1;

#	5) 이를 연령별로 나누어 구하기
SELECT FLOOR(age/10)*10 ageband,
departmentname,
SUM(CASE WHEN reviewtext LIKE '%size%' THEN 1 ELSE 0 END) n_size,
SUM(CASE WHEN reviewtext LIKE '%large%' THEN 1 ELSE 0 END) n_large,
SUM(CASE WHEN reviewtext LIKE '%loose%' THEN 1 ELSE 0 END) n_loose,
SUM(CASE WHEN reviewtext LIKE '%small%' THEN 1 ELSE 0 END) n_small,
SUM(CASE WHEN reviewtext LIKE '%tight%' THEN 1 ELSE 0 END) n_tight,
SUM(1) n_total
FROM mydata.dataset2
GROUP BY 1,2
ORDER BY 1,2;

#	6) 각 리뷰 개수의 비율로 구하기
SELECT FLOOR(age/10)*10 ageband,
departmentname,
SUM(CASE WHEN reviewtext LIKE '%size%' THEN 1 ELSE 0 END)/SUM(1) n_size,
SUM(CASE WHEN reviewtext LIKE '%large%' THEN 1 ELSE 0 END)/SUM(1) n_large,
SUM(CASE WHEN reviewtext LIKE '%loose%' THEN 1 ELSE 0 END)/SUM(1) n_loose,
SUM(CASE WHEN reviewtext LIKE '%small%' THEN 1 ELSE 0 END)/SUM(1) n_small,
SUM(CASE WHEN reviewtext LIKE '%tight%' THEN 1 ELSE 0 END)/SUM(1) n_tight
FROM mydata.dataset2
GROUP BY 1,2
ORDER BY 1,2;


## 5. Clothing ID별 Size Review

#	1) 상품 ID 별 사이즈 관련된 리뷰 수 계산
SELECT clothingid,
SUM(CASE WHEN reviewtext LIKE '%size%' THEN 1 ELSE 0 END) n_size
FROM mydata.dataset2
GROUP BY 1;

#	2) 사이즈를 Large, Loose, Small, Tight로 상세히 나눠 비율 구하기
SELECT clothingid,
SUM(CASE WHEN reviewtext LIKE '%size%' THEN 1 ELSE 0 END) n_size_t,
SUM(CASE WHEN reviewtext LIKE '%size%' THEN 1 ELSE 0 END)/SUM(1) n_size,
SUM(CASE WHEN reviewtext LIKE '%large%' THEN 1 ELSE 0 END)/SUM(1) n_large,
SUM(CASE WHEN reviewtext LIKE '%loose%' THEN 1 ELSE 0 END)/SUM(1) n_loose,
SUM(CASE WHEN reviewtext LIKE '%small%' THEN 1 ELSE 0 END)/SUM(1) n_small,
SUM(CASE WHEN reviewtext LIKE '%tight%' THEN 1 ELSE 0 END)/SUM(1) n_tight
FROM mydata.dataset2
GROUP BY 1;