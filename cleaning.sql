-- 1. remove duplicates 
-- 2. standardize the date
-- 3. null or blank 
-- 4. remove any columns that are not necessary or irrelevant 

-- 1. remove duplicates 

create table layoffs_staging 
like layoffs;

select * from layoffs_staging where company = 'oda';

insert layoffs_staging
select * 
from layoffs;

with temp as 
(
 select *,
 row_number() over(
 partition by company,location, industry, total_laid_off,
 percentage_laid_off, 'date', 'source' , stage , country , date_added) as count
 from layoffs_staging
)
select * from temp where count > 1;

-- u cant delete from a cte 

CREATE TABLE `layoffs_staging2` (
  `company` text,
  `location` text,
  `total_laid_off` text,
  `date` text,
  `percentage_laid_off` text,
  `industry` text,
  `source` text,
  `stage` text,
  `funds_raised` text,
  `country` text,
  `date_added` text,
  `row_num` INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

select * from layoffs_staging2;

INSERT INTO layoffs_staging2
 select *,
 row_number() over(
 partition by company,location, industry, total_laid_off,
 percentage_laid_off, 'date', 'source' , stage , country , date_added) as count
 from layoffs_staging;


SET SQL_SAFE_UPDATES = 0; -- enabling delete/update OR MANUALLY EDIT > PREFERENCES > SAFEUPDATES UNCHECK

delete from layoffs_staging2 where row_num > 1;

SET SQL_SAFE_UPDATES = 1; -- back on 

select * from layoffs_staging2 where NOT row_num = 1 ;

-- 2. standardize the date(FINDING ISSUES THEN FIXING IT )

select company from layoffs_staging2;

update layoffs_staging2
set company = trim(company); -- successful 16 rows affected 

select * from layoffs_staging2 where industry = '';

select distinct country , trim(trailing '.' from country) from layoffs_staging2 order by 1 ;

select `date` from layoffs_staging2 where `date` is not null order by 1 ;

UPDATE layoffs_staging2
set `date` = str_to_date(`date`, '%m/%d/%Y'); -- NEEDED TO CONVERT TO DATE FORMAT TO BE ABLE TO CHANGE COLUMN TYPE TO DATE LATER 

ALTER TABLE layoffs_staging2 
modify column `date` DATE;

SELECT * FROM layoffs_staging2;

SELECT date_added, str_to_date(date_added, '%m/%d/%Y') from layoffs_staging2;

update layoffs_staging2
set date_added = str_to_date(date_added, '%m/%d/%Y');

alter table layoffs_staging2
modify column date_added Date;

-- 3. null or blank :-

SELECT count(*)FROM layoffs_staging2 where total_laid_off = '' and percentage_laid_off = '';


update layoffs_staging2 set industry = Null where industry ='';
 
select * from layoffs_staging2 where industry is null or industry ='' ;
select*from layoffs_staging2 where industry is null;

select *,t1.industry , t2.industry
from layoffs_staging2 t1 
join layoffs_staging2 t2 
	on t1.company = t2.company
    where t1.industry is null 
    and t2.industry is not null 
    order by 1;


SELECT count(*)FROM layoffs_staging2 where total_laid_off is null and percentage_laid_off is null;

delete FROM layoffs_staging2 where total_laid_off = '' and percentage_laid_off = '';

alter table layoffs_staging2
drop column row_num; 

select * from layoffs_staging2 where percentage_laid_off < 0.01;

update layoffs_staging2
set FUNDS_RAISED = NULL where FUNDS_RAISED = '';

select * from layoffs_staging2;

alter table layoffs_staging2
modify column total_laid_off INT;

alter table layoffs_staging2
modify column funds_raised INT;

alter table layoffs_staging2
modify column percentage_laid_off DECIMAL(5,2);

SHOW WARNINGS;

SELECT * FROM LAYOFFS WHERE COMPANY = 'TASKUS';


SELECT INDUSTRY , COUNT(total_laid_off) AS 'TOTAL LAID OFF' FROM layoffs_staging2 group by INDUSTRY ORDER BY COUNT(total_laid_off) DESC LIMIT 3,1;

SELECT * FROM layoffs_staging2 WHERE percentage_laid_off =1 ORDER BY total_laid_off DESC;

SELECT COMPANY , SUM(TOTAL_LAID_OFF) 
FROM layoffs_staging2 
GROUP BY COMPANY 
ORDER BY 2 DESC;