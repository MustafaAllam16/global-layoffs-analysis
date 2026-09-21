SELECT COUNTRY , SUM(total_laid_off) AS 'TOTAL LAID OFF' 
FROM layoffs_staging2 
group by COUNTRY 
ORDER BY SUM(total_laid_off) DESC;

SELECT * FROM layoffs_staging2 
WHERE percentage_laid_off =1 
ORDER BY total_laid_off DESC;

SELECT COMPANY , SUM(TOTAL_LAID_OFF) 
FROM layoffs_staging2 
GROUP BY COMPANY 
ORDER BY 2 DESC;


SELECT MIN(`DATE`) , MAX(`DATE`) FROM layoffs_staging2;

SELECT YEAR(`DATE`) , SUM(TOTAL_LAID_OFF) , INDUSTRY
FROM layoffs_staging2 
# WHERE YEAR(`DATE`) < 2025
GROUP BY YEAR(`DATE`) , INDUSTRY
ORDER BY 1 DESC;


select substring(`date`,1,7) as `MONTH` , SUM(total_laid_off)
from layoffs_staging2
WHERE substring(`date`,1,7) IS NOT NULL
GROUP BY `MONTH`
ORDER BY 1 ;


WITH ROLLING_TOTAL AS
( 
select substring(`date`,1,7) as `MONTH` , SUM(total_laid_off) AS TOTAL
from layoffs_staging2
WHERE substring(`date`,1,7) IS NOT NULL
GROUP BY `MONTH`
ORDER BY 1 
) 
SELECT `MONTH`, TOTAL 
,SUM(TOTAL) OVER(ORDER BY `MONTH`) AS ROLLING_TOTAL
FROM ROLLING_TOTAL;

WITH COMPANY_YEAR(COMPANY,YEARS,TOTAL_LAYOFFS) AS 
(
SELECT company , YEAR(`DATE`),SUM(total_laid_off) AS 'TOTAL LAID OFF' 
FROM layoffs_staging2 
group by COMPANY , year(`DATE`)
),
COMPANY_YEAR_RANK AS 
(
SELECT*, dense_rank() OVER(PARTITION BY YEARS ORDER BY TOTAL_LAYOFFS DESC) AS RANKING
FROM COMPANY_YEAR
WHERE YEARS IS NOT NULL
)
SELECT*FROM COMPANY_YEAR_RANK
WHERE RANKING <= 5 ;

SELECT*FROM LAYOFFS_STAGING2;

-- Full EDA :-
-- 1. Overall scale
-- 1.1 Total layoffs recorded (SUM of total_laid_off)
SELECT SUM(TOTAL_LAID_OFF) `TOTAL LAID OFF` FROM layoffs_staging2; 

-- 1.2 Number of distinct companies
SELECT COUNT(DISTINCT company) FROM layoffs_staging2;

-- 1.3 Number of layoff events (rows)
SELECT COUNT(*) FROM layoffs_staging2;

-- 1.4 Average and median layoffs per event
SELECT AVG(TOTAL_LAID_OFF)
FROM LAYOFFS_STAGING2
WHERE TOTAL_LAID_OFF IS NOT NULL;

WITH RANKED AS 
(
SELECT TOTAL_LAID_OFF, 
ROW_NUMBER() OVER(ORDER BY TOTAL_LAID_OFF) AS ROW_NUM ,
COUNT(*) OVER() AS TOTAL_ROWS
FROM LAYOFFS_STAGING2
WHERE TOTAL_LAID_OFF IS NOT NULL 
)
SELECT AVG(TOTAL_LAID_OFF) 
FROM RANKED
WHERE ROW_NUM IN (FLOOR( (TOTAL_ROWS + 1) / 2 ),CEIL( (TOTAL_ROWS + 1) / 2) );


-- 2. Time trends
-- 2.1 Layoffs by year
SELECT YEAR(`DATE`) , SUM(TOTAL_LAID_OFF) 
FROM LAYOFFS_STAGING2
GROUP BY YEAR(`DATE`) ORDER BY 1; 

-- 2.2 Layoffs by month/year
SELECT YEAR(`DATE`)`YEAR` , MONTH(`DATE`)`MONTH`, SUM(TOTAL_LAID_OFF) 
FROM LAYOFFS_STAGING2
WHERE `DATE` IS NOT NULL
GROUP BY `MONTH`,`YEAR`
ORDER BY 1 ,2;


-- 2.3 Which month/year had the highest layoffs
WITH COMPANY_YEARS (YEARS,MONTHS,TOTAL) AS 
(
SELECT YEAR(`DATE`)`YEAR` , MONTH(`DATE`)`MONTH`, SUM(TOTAL_LAID_OFF) 
FROM LAYOFFS_STAGING2
WHERE `DATE` IS NOT NULL
GROUP BY `MONTH`,`YEAR`
-- ORDER BY 1 ,2
), RANKING AS 
(
SELECT *, DENSE_RANK() OVER(PARTITION BY YEARS ORDER BY TOTAL DESC ) AS MONTHRANK FROM COMPANY_YEARS 
) 
SELECT*FROM RANKING  WHERE MONTHRANK = 1 ORDER BY YEARS , MONTHRANK;

-- SELECT * FROM COMPANY_YEARS ORDER BY TOTAL DESC LIMIT 1; ANOTHER VERSION

-- 3. Company analysis
-- 3.1 Top 10 companies by total layoffs
SELECT COMPANY , SUM(TOTAL_LAID_OFF) AS TOTAL FROM layoffs_staging2 group by COMPANY ORDER BY TOTAL DESC LIMIT 10;

-- 3.2 Companies with more than one layoff event
SELECT COMPANY , COUNT(*) AS TOTAL FROM layoffs_staging2 group by COMPANY HAVING TOTAL > 1 ORDER BY TOTAL DESC;


-- 3.3 Largest single layoff events (top 10 rows by total_laid_off)
SELECT COMPANY, (TOTAL_LAID_OFF) AS TOTAL FROM layoffs_staging2 ORDER BY TOTAL DESC LIMIT 10;


-- 4. Industry analysis
-- 4.1 Total layoffs by industry
SELECT INDUSTRY , SUM(TOTAL_LAID_OFF) AS TOTAL FROM layoffs_staging2 WHERE INDUSTRY IS NOT NULL GROUP BY INDUSTRY ORDER BY 2 DESC;


-- 4.2 Number of companies/events per industry
SELECT INDUSTRY , COUNT(DISTINCT COMPANY) NUM_COMPANIES , COUNT(*)NUM_EVENTS FROM LAYOFFS_STAGING2 GROUP BY INDUSTRY ORDER BY NUM_COMPANIES DESC;


-- 5. Geographic analysis
-- 5.1 Total layoffs by country
SELECT COUNTRY , SUM(total_laid_off) FROM layoffs_staging2 WHERE total_laid_off IS NOT NULL GROUP BY COUNTRY ORDER BY 2 DESC;

-- 5.2 Top countries by total layoffs
SELECT COUNTRY , SUM(total_laid_off) FROM layoffs_staging2 WHERE total_laid_off IS NOT NULL GROUP BY COUNTRY ORDER BY 2 DESC LIMIT 10;


-- 6. Interesting cases
-- 6.1 Companies with 100% layoffs (percentage_laid_off = 1)
SELECT COMPANY FROM layoffS_STAGING2 WHERE PERCENTAGE_LAID_OFF =1;

-- 6.2 Among those, which had raised the most funding before shutting down
SELECT COMPANY , FUNDS_RAISED , INDUSTRY , dense_rank()OVER(PARTITION BY INDUSTRY) FROM layoffS_STAGING2 WHERE PERCENTAGE_LAID_OFF =1 ORDER BY 2 DESC LIMIT 5 ;
SELECT INDUSTRY , COUNT(DISTINCT COMPANY) , STAGE FROM layoffs_staging2 WHERE PERCENTAGE_LAID_OFF = 1 GROUP BY INDUSTRY , STAGE ORDER BY 2 DESC ; 


-- 6.3 Any unusual patterns (repeat companies across years, spikes in a specific month)
WITH COMPANY_YEAR(COMPANY,YEARS,TOTAL_LAYOFFS) AS 
(
SELECT company , YEAR(`DATE`),SUM(total_laid_off) AS 'TOTAL LAID OFF' 
FROM layoffs_staging2 
group by COMPANY , year(`DATE`)
),
COMPANY_YEAR_RANK AS 
(
SELECT*, dense_rank() OVER(PARTITION BY YEARS ORDER BY TOTAL_LAYOFFS DESC) AS RANKING
FROM COMPANY_YEAR
WHERE YEARS IS NOT NULL
)
SELECT*FROM COMPANY_YEAR_RANK
WHERE RANKING <= 5 ;

-- 6.4 Stage analysis: Are layoffs concentrated in certain stages (e.g., post-IPO vs. Series C vs. Seed)?

SELECT stage, SUM(total_laid_off) AS total, COUNT(*) AS events
FROM layoffs_staging2
GROUP BY stage
ORDER BY total DESC;

SELECT stage, SUM(total_laid_off) AS total, COUNT(*) AS events, COUNT(DISTINCT company) AS companies
FROM layoffs_staging2
GROUP BY stage
ORDER BY total DESC;
