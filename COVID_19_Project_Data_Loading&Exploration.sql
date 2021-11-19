#--------------------BULK LOADING--------------------------
CREATE DATABASE project_portfolio;
USE project_portfolio;
#----------------LOADING ONLY COLUMN OF THE TABLE USING IMPORT TABLE WIZARD METHOD
SELECT * FROM covid_Vaccination;
TRUNCATE TABLE covid_Vaccination;
SELECT * FROM covid_Death;
TRUNCATE TABLE covid_Death;

LOAD DATA  INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/covid_Death.csv' 
INTO TABLE covid_Death CHARACTER SET latin1  FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
IGNORE 1 LINES;

LOAD DATA  INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/covid_Vaccination.csv' 
INTO TABLE covid_Vaccination CHARACTER SET latin1  FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
IGNORE 1 LINES;
#-------------------------------------------------------------------------------------------------
# ---------Converting date(text type) to datetime format-----
#converting to Date
SELECT STR_TO_DATE(mydate, '%d-%m-%Y') as mydate FROM covid_death;

# Applying this changes to the entire table
UPDATE covid_death
SET mydate=STR_TO_DATE(mydate, '%d-%m-%Y');

# converting to datetime
UPDATE covid_death
SET  mydate = CAST(mydate AS DATETIME );

ALTER TABLE covid_death
RENAME COLUMN Mydate to Date_time;
-------------------------------------------------------------------------------------------------------------------------------------------------------------
# Applying same to covid_vaccination table
#-------------------------------------
#converting to Date
SELECT STR_TO_DATE(date, '%d-%m-%Y') as date_time FROM covid_death;

# Applying this changes to the entire table
UPDATE covid_vaccination
SET date=STR_TO_DATE(date, '%d-%m-%Y');

# converting to datetime
UPDATE covid_vaccination
SET  date = CAST(date AS DATETIME );

ALTER TABLE covid_vaccination
RENAME COLUMN date to Date_time;

#---------------------------------------------------------------------------------------------------------------------------------------
# Select Data that we are going to be starting with

Select Location, date_time, total_cases, new_cases, total_deaths, population
From Covid_Death
Where continent is not null 
order by 1,2;
#----------------------------------------------------------------------------------------------------------------------------------------

#Total Cases vs Total Deaths

SELECT location,date_time,total_cases,total_deaths,population
FROM covid_death
GROUP BY location
HAVING total_cases AND total_deaths IS NOT NULL
ORDER BY 2,3 DESC ;
#------------------------------------------------------------------------------------------------------------------------
#-- Total Cases vs Total Deaths
#-- Shows likelihood of dying if you contract covid in your country

SELECT location,date_time,total_cases,total_deaths,(total_deaths/total_cases)*100 as Mortality_rate
FROM covid_death
WHERE location LIKE "%states" 
AND continent IS NOT NULL
ORDER BY Mortality_rate DESC;

#---------------------------------------------------------------------------------------------------------------------------------
SELECT location,date_time,total_cases,total_deaths,(total_deaths/total_cases)*100 as Mortality_rate
FROM covid_death
WHERE location = 'India' 
AND continent IS NOT NULL
ORDER BY Mortality_rate DESC;

# Mortality rate in india is less than the US During the entire duration
# US has a mortality rate of approximately 10% whereas India has a mortality rate of approximately 4%. 
#-------------------------------------------------------------------------------------------------------------------------------

# Percentage of people inflected with covid in India 

SELECT location,date_time,total_cases,population,(total_cases/population)*100 as rate_of_infection
FROM covid_death
WHERE location = 'India'
AND continent IS NOT NULL
ORDER BY rate_of_infection DESC;

#---------------------------------------------------------------------------------------------------------------------------------

# Percentage of people inflected with covid all over the world
SELECT location,date_time,total_cases,population,(total_cases/population)*100 as rate_of_infection
FROM covid_death
ORDER BY 1,rate_of_infection DESC;

#---------------------------------------------------------------------------------------------------------------------------------
# Country with the highest percentage infection rate as compare to population of that country

SELECT location,date_time,max(total_cases) as HighestCase,population,max((total_cases/population)*100) as rate_of_infection
FROM covid_death
GROUP BY location,population
ORDER BY rate_of_infection DESC;

#------------------------------------------------------------------------------------------------------------------------------
#country with the highest death count

SELECT location,date_time,max(total_deaths) as total_deaths,max((total_deaths/population)*100) as Mortality_Rate
FROM covid_death
GROUP BY location,population
ORDER BY 3 DESC;
#--------------------------------------------------------------------------------------------------------------------------------------
#---------this is an issue because by default the data type of the total_deaths column is text. Now, we need to convert it into INT
# Converting to DOUBLE Data type

UPDATE covid_death
SET  Total_deaths = CAST(Total_deaths AS DOUBLE );

# Converting to INT but cast is not converting with INT but we can use unsigned which is same as INT
# The type for the result can be one of the following values:

#BINARY[(N)]
#CHAR[(N)]
#DATE
#DATETIME
#DECIMAL[(M[,D])]
#SIGNED [INTEGER]
#TIME
#UNSIGNED [INTEGER]

SELECT location,date_time, MAX(cast(Total_deaths as unsigned)) as total_deaths,max((total_deaths/population)*100) as Mortality_Rate
FROM covid_death
GROUP BY location,population
ORDER BY 3 DESC;

#----------------------------------------------------------------------------------------------------------------------------------------

#BREAKING UP BASED ON THE CONTINENT

SELECT continent,location,date_time, MAX(cast(Total_deaths as unsigned)) as total_deaths,max((total_deaths/population)*100) as Mortality_Rate
FROM covid_death
where continent is  null
GROUP BY location
ORDER BY 1 DESC;


#-----------------------------------------------------------------------------------------------------------------------------------
# GLOBAL NUMBER

SELECT date_time,sum(total_cases) as total_cases,sum(total_deaths) as total_deaths,sum(new_deaths) as total_new_deaths,sum(total_deaths)/sum(total_cases)*100 as Mortality_rate
FROM covid_death
WHERE continent IS NOT NULL
GROUP BY date_time
ORDER BY 2 ;

#--------------------------------------------------------------------------------------------------------------------------------------

#Using the other vaccination table to find out the total number of people got vaccinated against their population

#first we need to join both the table death and vaccinated table
#STEP-1
SELECT *
FROM covid_death AS  DEATHS
INNER JOIN covid_vaccination AS VACC
ON DEATHS.location=VACC.location
AND 
DEATHS.date_time=VACC.date_time;
#STEP-2
# FROM THESE QUERY WE WILL GET TO KNOW WHNE THE VACCINATION OF PARTICULAR COUNTY HAS STARTED

SELECT DEATHS.LOCATION,DEATHS.DATE_TIME,DEATHS.POPULATION,VACC.NEW_VACCINATIONS,VACC.TOTAL_VACCINATIONS
FROM COVID_DEATH AS DEATHS
JOIN COVID_VACCINATION AS VACC
ON DEATHS.location=VACC.location
AND 
DEATHS.date_time=VACC.date_time
ORDER BY 1,2 ASC;

#STEP-3
#We caanot use the just created column for the use and for that we can use temp table or CTE

SELECT DEATHS.LOCATION,DEATHS.DATE_TIME,DEATHS.POPULATION,VACC.NEW_VACCINATIONS,
SUM(CAST(VACC.NEW_VACCINATIONS AS SIGNED)) OVER (PARTITION BY DEATHS.LOCATION ORDER BY DEATHS.DATE_TIME ) AS RollingPeopleVaccinated
,(RollingPeopleVaccinated/population)*100
FROM COVID_DEATH AS DEATHS
JOIN COVID_VACCINATION AS VACC
ON DEATHS.location=VACC.location
AND 
DEATHS.date_time=VACC.date_time
ORDER BY 1,2 ASC;
#---------------------------------------------------------------------
# WITH CTE
WITH VaccinationVSpopulation (Location,deaths,population,new_vaccinations,RollingPopepleVaccinations)
AS (
SELECT DEATHS.LOCATION,DEATHS.DATE_TIME,DEATHS.POPULATION,VACC.NEW_VACCINATIONS,
SUM(CAST(VACC.NEW_VACCINATIONS AS SIGNED)) OVER (PARTITION BY DEATHS.LOCATION ORDER BY DEATHS.DATE_TIME ) AS RollingPeopleVaccinated
FROM COVID_DEATH AS DEATHS
JOIN COVID_VACCINATION AS VACC
ON DEATHS.location=VACC.location
AND 
DEATHS.date_time=VACC.date_time
)
SELECT *,(RollingPopepleVaccinations/population )*100 FROM VaccinationVSpopulation
ORDER BY 2;

# WITH TEMP TABLE
DROP TABLE IF EXISTS VaccinationVSpopulation;
CREATE TEMPORARY TABLE VaccinationVSpopulation
(SELECT DEATHS.LOCATION,DEATHS.DATE_TIME,DEATHS.POPULATION,VACC.NEW_VACCINATIONS,
SUM(CAST(VACC.NEW_VACCINATIONS AS SIGNED)) OVER (PARTITION BY DEATHS.LOCATION ORDER BY DEATHS.DATE_TIME ) AS RollingPeopleVaccinated
FROM COVID_DEATH AS DEATHS
JOIN COVID_VACCINATION AS VACC
ON DEATHS.location=VACC.location
AND 
DEATHS.date_time=VACC.date_time);
SELECT * ,(RollingPeopleVaccinated/population )*100 FROM VaccinationVSpopulation
WHERE LOCATION LIKE "%STATES%"
ORDER BY 2 DESC ;

#CREATING A VIEW FOR LATE VISUALIZATION PART

CREATE VIEW VaccinationVSpopulation AS 
SELECT DEATHS.LOCATION,DEATHS.DATE_TIME,DEATHS.POPULATION,VACC.NEW_VACCINATIONS,
SUM(CAST(VACC.NEW_VACCINATIONS AS SIGNED)) OVER (PARTITION BY DEATHS.LOCATION ORDER BY DEATHS.DATE_TIME ) AS RollingPeopleVaccinated
FROM COVID_DEATH AS DEATHS
JOIN COVID_VACCINATION AS VACC
ON DEATHS.location=VACC.location
AND 
DEATHS.date_time=VACC.date_time
ORDER BY 1,2 ASC;