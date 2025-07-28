-- #0. Duplicate the layoffs table

CREATE TABLE layoffs_staging AS TABLE layoffs WITH DATA;

-- DROP TABLE IF EXISTS layoffs_staging;

SELECT * FROM layoffs_staging;

-- #1. Make sure there are no duplicates

WITH layoffs_cte AS (
    SELECT *,
    ROW_NUMBER() OVER(
        PARTITION BY company, location, date, country, funds_raised, total_laid_off, percentage_laid_off, funds_raised, stage
    ) AS row_number
    FROM layoffs_staging
)

SELECT *
FROM layoffs_cte
WHERE row_number > 1;

SELECT *
FROM layoffs_staging
WHERE company IN ('Beyond Meat', 'Cazoo');

CREATE TABLE layoffs_staging2 AS 
SELECT *,
    ROW_NUMBER() OVER(
        PARTITION BY company, location, date, funds_raised, total_laid_off, funds_raised, stage
    ) AS row_number
FROM layoffs_staging;

-- DROP TABLE IF EXISTS layoffs_staging2;

DELETE
-- SELECT *
FROM layoffs_staging2 WHERE row_number > 1;

ALTER TABLE layoffs_staging2
DROP COLUMN row_number;

-- #2. Standarizing data

-- Standarize locations

SELECT DISTINCT location
FROM layoffs_staging2
ORDER BY 1;

-- Standarize locations without Non-U.S. suffix (1st part)

SELECT location, country
FROM layoffs_staging2
WHERE location LIKE 'Vancouver%';

WITH layoffs_cte2 AS (
    SELECT location, country, SPLIT_PART(location, ',', 1) AS city, SPLIT_PART(location, ',', 2) as suffix
    FROM layoffs_staging2
)

/*
SELECT DISTINCT suffix
FROM layoffs_cte2
WHERE suffix;
*/

SELECT city, COUNT(DISTINCT suffix)
FROM layoffs_cte2
GROUP BY city
HAVING COUNT(DISTINCT suffix) > 1;

UPDATE layoffs_staging2
SET location = 'Auckland,Non-U.S.'
WHERE location = 'Auckland';

UPDATE layoffs_staging2
SET location = 'Bengaluru,Non-U.S.'
WHERE location = 'Bengaluru';

UPDATE layoffs_staging2
SET location = 'Buenos Aires,Non-U.S.'
WHERE location = 'Buenos Aires';

UPDATE layoffs_staging2
SET location = 'Cayman Islands,Non-U.S.'
WHERE location = 'Cayman Islands';

UPDATE layoffs_staging2
SET location = 'Gurugram,Non-U.S.'
WHERE location = 'Gurugram';

UPDATE layoffs_staging2
SET location = 'Kuala Lumpur,Non-U.S.'
WHERE location = 'Kuala Lumpur';

UPDATE layoffs_staging2
SET location = 'London,Non-U.S.'
WHERE location = 'London';

UPDATE layoffs_staging2
SET location = 'Luxembourg,Non-U.S.'
WHERE location = 'Luxembourg,Raleigh';

UPDATE layoffs_staging2
SET location = 'Melbourne,Non-U.S.'
WHERE location = 'Melbourne,Victoria';

UPDATE layoffs_staging2
SET location = 'Montreal,Non-U.S.'
WHERE location = 'Montreal';

UPDATE layoffs_staging2
SET location = 'Mumbai,Non-U.S.'
WHERE location = 'Mumbai';

UPDATE layoffs_staging2
SET location = 'Singapore,Non-U.S.'
WHERE location = 'Singapore';

UPDATE layoffs_staging2
SET location = 'Tel Aviv,Non-U.S.'
WHERE location = 'Tel Aviv';

SELECT *
FROM layoffs_staging2
WHERE location = 'Vancouver' AND country <> 'United States';

UPDATE layoffs_staging2
SET location = 'Vancouver,Non-U.S.'
WHERE location = 'Vancouver' AND country <> 'United States';

-- Standarize locations without Non-U.S. suffix (2nd part)

WITH layoffs_cte2 AS (
    SELECT location, country, SPLIT_PART(location, ',', 1) AS city, SPLIT_PART(location, ',', 2) as suffix
    FROM layoffs_staging2
)

SELECT location, country, suffix
FROM layoffs_cte2
-- WHERE suffix = '' AND country <> 'United States'
WHERE suffix = '' AND country NOT IN('United States', 'Seychelles', 'China');

SELECT location, COUNT(DISTINCT country)
FROM layoffs_staging2
GROUP BY location
HAVING COUNT(DISTINCT country) > 1;

UPDATE layoffs_staging2
SET country = 'United States'
WHERE location IN('Boston', 'SF Bay Area', 'New York City') AND country <> 'United States';

UPDATE layoffs_staging2
SET location = CONCAT(location,',Non-U.S.')
WHERE location = 'Nicosia' AND country = 'Cyprus';

UPDATE layoffs_staging2
SET location = CONCAT(location,',Non-U.S.')
WHERE location = 'Trondheim' AND country = 'Norway';

-- Standarize locations with different countries associated

SELECT location, COUNT(DISTINCT country)
FROM layoffs_staging2
GROUP BY location
HAVING COUNT(DISTINCT country) > 1;

SELECT DISTINCT country
FROM layoffs_staging2
WHERE country = 'U%';

SELECT location, country
FROM layoffs_staging2
WHERE country IN ('UAE', 'United Arab Emirates');

UPDATE layoffs_staging2
SET country = 'United Arab Emirates'
WHERE country = 'UAE';

SELECT location, country, source
FROM layoffs_staging2
WHERE location LIKE 'Jakarta%';

UPDATE layoffs_staging2
SET country = 'Indonesia'
WHERE location = 'Jakarta,Non-U.S.' AND country = 'India';

SELECT location, country
FROM layoffs_staging2
WHERE location LIKE 'London%';

SELECT location, country, source
FROM layoffs_staging2
WHERE location LIKE 'Oslo%';

UPDATE layoffs_staging2
SET country = 'Norway'
WHERE location = 'Oslo,Non-U.S.' AND country = 'Sweden';

SELECT t1.company, t1.location, t1.country, t2.location
FROM layoffs_staging2 AS t1
INNER JOIN layoffs_staging2 AS t2
    ON t1.company = t2.company
WHERE t1.location = 'Non-U.S.';

-- Avoid duplicated location by mispelling

SELECT DISTINCT location
FROM layoffs_staging2
ORDER BY 1;

SELECT location, country
FROM layoffs_staging2
WHERE location LIKE 'Malm%';

UPDATE layoffs_staging2
SET location = 'Malmö,Non-U.S.'
WHERE location = 'Malmo,Non-U.S.';

SELECT location, country
FROM layoffs_staging2
WHERE location LIKE '%sseldorf%';

UPDATE layoffs_staging2
SET location = 'Düsseldorf,Non-U.S.'
WHERE location = 'Dusseldorf,Non-U.S.';

-- Standarize countries

SELECT DISTINCT country
FROM layoffs_staging2
ORDER BY 1;

-- Standarize industry

SELECT DISTINCT industry
FROM layoffs_staging2
ORDER BY 1;

-- Standarize company

SELECT DISTINCT company, TRIM(company)
FROM layoffs_staging2
ORDER BY company;

UPDATE layoffs_staging2
SET company = TRIM(company);

-- Standarize date and date_added

SELECT DISTINCT date, date_added
FROM layoffs_staging2
ORDER BY 1;

ALTER TABLE layoffs_staging2
ALTER COLUMN date TYPE DATE
USING TO_DATE(date, '%MM/%DD/%YYYY'),
ALTER COLUMN date_added TYPE DATE
USING TO_DATE(date_added, '%MM/%DD/%YYYY');

-- Standarize total_laid_off

SELECT DISTINCT SPLIT_PART(total_laid_off, '.',2) AS decimal_part
FROM layoffs_staging2
WHERE total_laid_off IS NOT NULL;

SELECT DISTINCT total_laid_off, SPLIT_PART(total_laid_off, '.', 1) AS integer_part
FROM layoffs_staging2;

UPDATE layoffs_staging2
SET total_laid_off = SPLIT_PART(total_laid_off, '.', 1);

SELECT DISTINCT LENGTH(total_laid_off)
FROM layoffs_staging2;

SELECT DISTINCT total_laid_off
FROM layoffs_staging2
WHERE LENGTH(total_laid_off) = 5
ORDER BY 1 DESC;

ALTER TABLE layoffs_staging2
ALTER COLUMN total_laid_off TYPE INTEGER
USING total_laid_off::INTEGER;

-- Standarize percentage_laid_off

SELECT DISTINCT RIGHT(percentage_laid_off, 1), POSITION('.' IN percentage_laid_off)
FROM layoffs_staging2;

SELECT DISTINCT percentage_laid_off, LENGTH(percentage_laid_off)
FROM layoffs_staging2
WHERE LENGTH(percentage_laid_off) >= 4;

SELECT percentage_laid_off, SPLIT_PART(percentage_laid_off, '%', 1)
FROM layoffs_staging2;

UPDATE layoffs_staging2
SET percentage_laid_off = SPLIT_PART(percentage_laid_off, '%', 1);

ALTER TABLE layoffs_staging2
ALTER COLUMN percentage_laid_off TYPE DECIMAL(5,2)
USING percentage_laid_off::DECIMAL(5,2);

SELECT percentage_laid_off/100
FROM layoffs_staging2;

UPDATE layoffs_staging2
SET percentage_laid_off = percentage_laid_off/100;

-- Command optional yet recommendable to optimize byte storage

ALTER TABLE layoffs_staging2
ALTER COLUMN percentage_laid_off TYPE DECIMAL(3,2);

-- Standarize funds_raised

SELECT DISTINCT LEFT(funds_raised, 1), SPLIT_PART(funds_raised, '.', 2)
FROM layoffs_staging2;

SELECT funds_raised, SPLIT_PART(funds_raised, '$', 2)
FROM layoffs_staging2;

UPDATE layoffs_staging2
SET funds_raised = SPLIT_PART(funds_raised, '$', 2);

ALTER TABLE layoffs_staging2
RENAME COLUMN funds_raised TO funds_raised_dollars;

ALTER TABLE layoffs_staging2
ALTER COLUMN funds_raised_dollars TYPE INTEGER
USING funds_raised_dollars::INTEGER;

-- Standarize stage

SELECT DISTINCT stage
FROM layoffs_staging2;

-- #3. Adressing NULL and blank values

-- Company

SELECT company
FROM layoffs_staging2
WHERE company IS NULL OR company = '';

-- Industry

SELECT DISTINCT industry
FROM layoffs_staging2
ORDER BY 1;

SELECT company, industry, source
FROM layoffs_staging2
WHERE industry IS NULL OR company = 'Appsmith';

-- Stage

SELECT DISTINCT stage
FROM layoffs_staging2
ORDER BY 1;

-- Dates

SELECT date, date_added
FROM layoffs_staging2
WHERE date IS NULL OR date_added IS NULL;

-- Location and country

SELECT company, location, country, source
FROM layoffs_staging2
WHERE location IS NULL OR country is NULL;

SELECT t1.location, t1.country, t2.country
FROM layoffs_staging2 AS t1
INNER JOIN layoffs_staging2 AS t2
    ON t1.location = t2.location
WHERE t1.country IS NULL
    AND t2.country IS NOT NULL;

UPDATE layoffs_staging2 AS t1
SET country = t2.country
FROM layoffs_staging2 AS t2
WHERE t1.location = t2.location
  AND t1.country IS NULL
  AND t2.country IS NOT NULL;

SELECT company, location, country, source
FROM layoffs_staging2
WHERE company = 'Product Hunt';

-- total_laid_off and percentage_laid_off

SELECT *
FROM layoffs_staging2
WHERE total_laid_off IS NULL 
    OR percentage_laid_off IS NULL;