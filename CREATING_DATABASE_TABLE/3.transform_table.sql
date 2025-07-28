-- Run the following into PSQL Tool in PgAdmin: \copy layoffs FROM '<GLOBAL PATH OF THE CSV FILE>' WITH (FORMAT csv, HEADER true, DELIMITER ',', ENCODING 'UTF8');

SELECT * FROM layoffs;