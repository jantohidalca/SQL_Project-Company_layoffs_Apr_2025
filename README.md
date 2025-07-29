# SQL Project: Data Cleaning a Company Layoff Dataset (April 2025 Update)

![project_thumbnail](SQL_Project-Company-layoffs.png)

## Introduction

While I was watching YouTube to review SQL topics, I came across a video of [Alex The Analyst](https://www.youtube.com/watch?v=OT1RErkfLNQ&ab_channel=AlexTheAnalyst) on YouTube where he was cleaning a dataset. Essentially, the dataset consisted of layoffs from tech companies around the world.

Since that video was uploaded, the dataset has been updated to include the most recent data until April 2025. So that gave me a reason to try to use SQL, featuring PostgreSQL and Visual Studio Code, to clean the updated dataset of company layoffs.

### Crucial tasks in data cleaning

To do data cleaning properly, I usually follow the following steps:

1. Eliminate duplicate entries
2. Standarize the data
3. Address the NULL and blank values

### SQL Skills and Tools Used

The following SQL Skills were used throughout this project:

- **PostgreSQL:** the chosen database management system, ideal for handling the layoffs dataset.
- **Common Table Expressions (CTE's):** crucial for creating auxilar columns for some of the queries
- **Tables Manipulation:** essential for updating the tables and changing variable types within the columns
- **String Functions:** featuring `SPLIT_PART` and `CONCAT`, my most reliable functions to extract or add in text columns
- **Date Functions**: the `TO_DATE()` function played a key role in order to standarize DATE columns
- **Join Operators:** without them, I could not have filter specific insights

I also used Visual Code Studio as the code editor because of its ease to work with git simultaneously.

### Dashboard Files

You can feel free to use the same files as me here below:

- SQL files to create the database and import the dataset: [CREATING_DATABASE](CREATING_DATABASE_TABLE)
- SQL file to clean the dataset: [clean_data.sql](clean_data.sql)
- Original CSV Dataset (April 2025 version):  [layoffs.csv](layoffs.csv)

### Layoffs Dataset

The dataset used for this project contains real-world company layoffs around the globe from 11 March 2020 to 21 April 2025. It comes from [Kaggle](https://www.kaggle.com/datasets/swaptr/layoffs-2022). The dataset are covered by the [ODC Open Database License](https://opendatacommons.org/licenses/odbl/odbl-10.txt).

Overall, it includes detailed information of a huge number of layoffs:

- **Data from the company** (name, location, country, industry and stage)
- **Data of the layoff in question** (number and percentage of affected employees, date and funds raised in dollars)
- **Technical data:** web source and date added into the data set

For more information for each attribute, feel free to consult [here](https://www.kaggle.com/datasets/swaptr/layoffs-2022).

# Step #0: Establish the work environment

Before doing data cleaning, the first thing I needed to do was to stablish the proper connections with the database to work between PostgreSQL and Visual Studio Code.

Then, I ran all the code in the [CREATING_DATABASE](CREATING_DATABASE_TABLE) folder to create the database and import the dataset into a SQL table named `layoffs`. It is important to remark that all the columns from the table were set to contain `TEXT` variables as the data was not cleaned yet.

Finally, I duplicated the `layoffs` table in case of wrong manipulation with the data. I named the new table `layoffs_staging`.

# Step #1: Eliminate duplicate entries

To detect possible duplicated rows, I used the following subquery:

```sql
WITH layoffs_cte AS (
    SELECT *,
    ROW_NUMBER() OVER(
        PARTITION BY company, location, date,
         country, funds_raised,
         total_laid_off, percentage_laid_off, 
         funds_raised, stage
    ) AS row_number
    FROM layoffs_staging
)

SELECT *
FROM layoffs_cte
WHERE row_number > 1;
```

It adds a new column, `row_number`, into `layoffs_staging` that assigns a different number to every row that differs in at least one of the columns, with exception of the `date_added` column as it is not so relevant. As a result, a column is duplicated if and only if its associated `row_number` is greater than 1.

By selecting `row_number` greater than 1, I ended up with two duplicated column from a two companies named *Beyond Meat* and *Cazoo*. Their duplication was because they were added into the dateset in different days. 

Once I was sure there were not more duplicate columns, I duplicated `layoffs_staging` into a new table called `layoffs_staging2` to preserve the column `row_number`. After that, I delete the duplicates with this command:

```sql
DELETE
FROM layoffs_staging2
WHERE row_number > 1;
```

Finally, I deleted the `row_number` column as it was no longer necessary.

# Step #2: Standarize the data

In this step, I first search for data that might be wrong or makes no sense (excluding NULL and blank spaces) and then I transform every column in the most convenient variable type. 

## Standarize locations

The only data that I actually needed to fix was the one corresponding to the `location` and `country` columns. To detect it, I mainly used string functions. I will break down this process.

### Recognize the suffixes among `location`
When I was selecting locations, I noticed that there were a lot of entries which have a *Non-U.S.* suffix after a comma. I was wonderig how many suffixes there were.

To this end, I used the `SPLIT_PART()` function of PostgreSQL to break down `location` into its main location and its suffix, in case it exists. I also combined it with the following CTE for better flexibility.

```sql
    WITH layoffs_cte2 AS (
    SELECT location, country, 
        SPLIT_PART(location, ',', 1) AS city, 
        SPLIT_PART(location, ',', 2)  AS suffix
    FROM layoffs_staging2
)
```

Here it is a portion of the outcome:

| location           | country       | city        | suffix |
|--------------------|---------------|-------------|-----|
| Toronto,Non-U.S.   | Canada        | Toronto     | Non-U.S. |
| Helsinki,Non-U.S.  | Finland       | Helsinki    | Non-U.S. |
| SF Bay Area        | United States | SF Bay Area |  |
| Toronto,Non-U.S.   | Canada        | Toronto     | Non-U.S. |

When I selected the distinct suffixes I obtained the following list:

- NULL          
- Victoria      
- Non-U.S.      
-              
- Raleigh       
- New York City 

I found the suffixes *Victoria*, *Raleigh* and *New York City* strange, so I decided to investigate what the `location` entries of these suffixes.

After I had added in `layoffs_staging2` the columns `city` and `suffix` based on the previous CTE, I obtained the following list:

| location                  | country       |
|---------------------------|---------------|
| Melbourne, Victoria       | Australia     |
| Luxembourg, Raleigh       | Luxembourg    |
| New Delhi, New York City  | United States |

I had no problems with the *New Delhi, New York City* location as it does actually exist and it is located within the U.S. On the other hand, I decided to change the remaining two entries to the *Non-U.S.* suffix because of its relevance among the data. To that end, I ran this code to update them:

```sql
UPDATE layoffs_staging2
SET location = CONCAT(city,',Non-U.S.'),
    suffix = 'Non-U.S.'
WHERE country <> 'United States'
    AND suffix NOT IN ('','Non-U.S.');
```

### Add the *Non-U.S.* suffix to those locations outside the U.S.

Firstly, I focused on fixing those locations which have some entries without any suffix and other ones with the *Non-U.S.* suffix, all of them outside the United States. This is the list:

- Auckland
- Bengaluru
- Buenos Aires
- Cayman Islands
- Gurugram
- Kuala Lumpur
- London
- Montreal
- Mumbai
- Singapore
- Tel Aviv
- Vancouver

In order to get that list and to update the table, I ran the following update statement using a CTE:
```sql
WITH layoffs_cte3 AS (
    SELECT city, COUNT(DISTINCT suffix)
    FROM layoffs_staging2
    WHERE country <> 'United States'
    GROUP BY city
    HAVING COUNT(DISTINCT suffix) > 1
)

UPDATE layoffs_staging2 AS t1
SET location = CONCAT(t1.city,',Non-U.S.'),
    suffix = 'Non-U.S.'
FROM layoffs_cte3 AS t2
WHERE t1.city = t2.city
    AND country <> 'United States' 
    AND suffix = '';
```
While I tried to inspect non-U.S. locations that only appeared a single time in `layoffs_staging2`, I got the following output:

| location      | country |
|---------------|---------|
| Nicosia       | Cyprus  |
| SF Bay Area   | Israel  |
| SF Bay Area   | India   |
| SF Bay Area   | India   |
| New York City | France  |
| SF Bay Area   | Ireland |
| Trondheim     | Norway  |
| Boston        | Germany |

Most of the locations seem to be wrong, so I had to change their associated country.

### Standarize locations with different associated countries 

By running the statement
```sql
SELECT location, COUNT(DISTINCT country)
FROM layoffs_staging2
WHERE location <> 'Non-U.S.'
GROUP BY location
HAVING COUNT(DISTINCT country) > 1;
```

I analyzed the locations that appeared in more than one country. This is the list with the explanation:

- **Dubai,Non-U.S.**: associated with United Arab Emirates and UAE, which is the same
- **Jakarta,Non-U.S.**: associated with Indonesia and India, the latter making no sense
- **London,Non-U.S.**: there is the London from UK and the London from Canada
- **Oslo,Non-U.S.**: associated with Norway and Sweeden, the latter making no sense

### Avoid duplicated location by umlauts
The final step was I fixing duplicated the locations by umlauts. By this I refer to Malmo vs *Malmö* and Dusseldorf vs *Düsseldorf*.

After the locations (and country) standarization was concluded, I dropped the `city` and `suffix` columns as they were no longer necessary.

## Standarize dates

I used the `TO_DATE` function to express the `date` and `date_added` columns like DATE types are in SQL.

```sql
ALTER TABLE layoffs_staging2
ALTER COLUMN date TYPE DATE
USING TO_DATE(date, '%MM/%DD/%YYYY'),
ALTER COLUMN date_added TYPE DATE
USING TO_DATE(date_added, '%MM/%DD/%YYYY');
```

## Standarize `total_laid_off`

The `total_laid_off` column always had all the entries with 0 as its decimal part, so I could turn that column into a INTEGER column if got rid of those 0's using the `SPLIT_PART` function.

```sql
UPDATE layoffs_staging2
SET total_laid_off = SPLIT_PART(total_laid_off, '.', 1);

ALTER TABLE layoffs_staging2
ALTER COLUMN total_laid_off TYPE INTEGER
USING total_laid_off::INTEGER;
```

## Standarize `percentage_laid_off`

To turn `percentage_laid_off` into a decimal column, I followed certain steps. First of all, I got rid of the percentage as it is not relevant. Then, I was able to turn it into a decimal column. Lastly, I divided it by 100.

```sql
UPDATE layoffs_staging2
SET percentage_laid_off = SPLIT_PART(percentage_laid_off, '%', 1);

ALTER TABLE layoffs_staging2
ALTER COLUMN percentage_laid_off TYPE DECIMAL(5,2)
USING percentage_laid_off::DECIMAL(5,2);

UPDATE layoffs_staging2
SET percentage_laid_off = percentage_laid_off/100;

-- Command optional yet recommendable to optimize byte storage

ALTER TABLE layoffs_staging2
ALTER COLUMN percentage_laid_off TYPE DECIMAL(3,2);
```

## Standarize `funds_raised`
To turn `funds_raised` into an integer column, I got rid of the $ symbol. 
```sql
UPDATE layoffs_staging2
SET funds_raised = SPLIT_PART(funds_raised, '$', 2);

ALTER TABLE layoffs_staging2
ALTER COLUMN funds_raised_dollars TYPE INTEGER
USING funds_raised_dollars::INTEGER;
```

I also renamed the column to `funds_raised_dollars` in abscense of the dollar sign.

The remaining columns of `layoffs_staging2` needed no standarization process.

# Step #3: Address the NULL and blank values

Although I could have consulted the `source` column to obtain the data for the NULL values, I did not do it as it is not part of the data cleaning process.

Said that, between all the columns with NULL and blank values, the only one I was able to repoblate with values was `location`. I only got an entry with a NULL value in it and was related to the *Product Hunt* company. Taking advantage of the fact that there were more entries involving *Product Hunt*, I was able to address this issue with the following statement:

```sql
UPDATE layoffs_staging2 AS t1
SET country = t2.country
FROM layoffs_staging2 AS t2
WHERE t1.location = t2.location
  AND t1.country IS NULL
  AND t2.country IS NOT NULL;
```

# Conclusions

As a junior data analyst, I embarked on this SQL-based project to practice my data cleaning skills. Using a dataset I have curated from real-world company layoffs, I analyzed each column meticulously.

By leveraging SQL features like CTE's, join operators and string and date functions, I was able to remove duplicates, standarize the data and addressing NULL/blank values.

Finally, I hope this project serves as a guide for other users that are trying to get into this awesome programing language called SQL.
