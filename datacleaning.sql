-- Encoding: UTF-8
-- Record delimiter: CRLF
-- Text qualifier: "
-- Import the .csv and set all the field data types to VARCHAR

-- LOOKING FOR ERRORS FIRST

-- DISTINCT() gives you every unique value in a single column. Look for misspellings, inconsistent formattings, etc.
SELECT DISTINCT (openpayments.Recipient_City)
FROM openpayments
ORDER BY 1 ASC;

-- Fixing non-cities in the city column
SELECT *
FROM openpayments
WHERE recipient_city IN("0","1101 SAM PERRY BLVD");

-- Find what the cities actually should be.
-- https://openpaymentsdata.cms.gov/physician/189219/summary
SELECT *
FROM openpayments
WHERE Physician_Profile_ID LIKE "189219";

UPDATE openpayments
SET Recipient_City = "FREDERICKSBURG"
WHERE openpayments.Physician_Profile_ID LIKE "189219" AND Recipient_City LIKE "1101 SAM PERRY BLVD";

-- https://openpaymentsdata.cms.gov/physician/836689/summary
SELECT *
FROM openpayments
WHERE Physician_Profile_ID LIKE "836689";

UPDATE openpayments
SET Recipient_City = "INDIANAPOLIS"
WHERE openpayments.Physician_Profile_ID LIKE "836689" AND Recipient_City LIKE "0";



-- CONVERTING DATA TYPES

SELECT *
FROM openpayments
ORDER BY Total_Amount_of_Payment_USDollars DESC;
-- What looks funny here? 1000 isn't less than 900.

SELECT sum(Total_Amount_of_Payment_USDollars)
FROM openpayments;
-- 8149429.859999988? Huh?

SELECT SUM(CAST(Total_Amount_of_Payment_USDollars AS decimal(11,2)))
FROM openpayments;
-- 8149429.86 is much better!

ALTER TABLE openpayments
MODIFY Total_Amount_of_Payment_USDollars decimal(11,2);

-- Run this query again.
SELECT sum(Total_Amount_of_Payment_USDollars)
FROM openpayments;


-- HANDLING MULTIPLE SPELLINGS

-- Check out places like NYC that might have multiple spellings. Anything with a "Saint" or "Fort" i.e. FORT LAUDERDALE vs. Ft Lauderdale
SELECT DISTINCT (openpayments.Recipient_City)
FROM openpayments
WHERE Recipient_City LIKE "N%" AND Recipient_State LIKE "NY"
ORDER BY 1 ASC;

-- Identify all the spellings you can.
SELECT *
FROM openpayments
WHERE Recipient_City IN("New York City","NYC","New York","NY","New  York","Newyork","New City")
ORDER BY Recipient_City ASC;

UPDATE openpayments
SET Recipient_City = "New York City"
WHERE Recipient_State LIKE "NY" AND Recipient_City IN ("NYC","New York City","New York","NY","New  York","Newyork");


-- DEALING WITH DATES
-- Our format here is stored as a value. 11052015 is 11,052,015 instead of November 5, 2015, so sorting by date won't work. For the purpose of this class, we're going to break the date all the way apart. Then we're gonna put it right back together with some separators.

ALTER TABLE openpayments
ADD COLUMN Payment_month varchar(2) AFTER Payment_date,
ADD COLUMN Payment_day varchar(2) AFTER Payment_month,
ADD COLUMN Payment_year varchar(4) AFTER Payment_day;

UPDATE openpayments
SET Payment_month = LEFT(Payment_date,2);

-- You want to start with the position of the first character you want to include.
UPDATE openpayments
SET Payment_day = MID(Payment_date,3,2);

UPDATE openpayments
SET Payment_year = RIGHT(Payment_date,4);




-- PUTTING THE DATES BACK TOGETHER
-- This sets the column to whatever the system default is for a date format. Probably YYYY-MM-DD or MM/DD/YYYY.
ALTER TABLE openpayments
ADD COLUMN Cleaned_payment_date date AFTER payment_date;

-- Like order of operations, you have to concatenate the date first, then perform the STR_TO_DATE(str,format). We could make a new column here with MM/DD/YYYY as a string and then perform STR_TO_DATE on that, but this saves us a step.
UPDATE openpayments
SET Cleaned_payment_date = STR_TO_DATE(CONCAT(Payment_month,"/",Payment_day,"/",Payment_year),'%m/%d/%Y');

-- Your where statement can now handle dates!
SELECT *
FROM openpayments
WHERE Cleaned_payment_date > '2015-12-09';

SELECT *
FROM openpayments
WHERE Cleaned_payment_date <= '2015-01-02';

SELECT *
FROM openpayments
WHERE Cleaned_payment_date BETWEEN '2015-07-03' AND '2015-07-05';
-- Using "between" will capture both the start and end date in the data, like => and =<


ALTER TABLE openpayments
DROP COLUMN Payment_month,
DROP COLUMN Payment_day ,
DROP COLUMN Payment_year;
-- Delete the extra columns for cleaner data!

-- CREATING A CATEGORY CODE
SELECT DISTINCT(openpayments.Physician_Primary_Type)
FROM openpayments;

SELECT *
FROM openpayments
WHERE openpayments.Physician_Primary_Type LIKE "Doctor of Dentistry";

CREATE TABLE doctor_types (
SELECT DISTINCT(openpayments.Physician_Primary_Type)
FROM openpayments);

ALTER TABLE doctor_types
ADD COLUMN doctor_type_code varchar(2);

-- Populate column with sequential numbers.
SELECT @i:=0;
UPDATE doctor_types SET doctor_types.doctor_type_code = @i:=@i+1;

ALTER TABLE openpayments
ADD COLUMN Doctor_type_code varchar(2) AFTER Physician_Primary_Type

UPDATE openpayments, doctor_types
SET openpayments.Doctor_type_code = doctor_types.doctor_type_code
WHERE doctor_types.Physician_Primary_Type = openpayments.Physician_Primary_Type;
