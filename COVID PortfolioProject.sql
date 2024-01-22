-- Select Data that we are going to be using

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
ORDER BY 1, 2;

-- Looking at Total Cases vs Total Deaths
-- Likelihood of dying if COVID is contracted in Barbados
SELECT location, date, total_cases, total_deaths, ROUND((CAST(total_deaths AS float)/CAST(total_cases AS float)), 4)* 100 AS death_percentage
FROM PortfolioProject..CovidDeaths
WHERE location LIKE 'Barbados'
ORDER BY 1, 2;


-- Total Cases vs Population (What percentage of population got COVID?)
SELECT location, date, total_cases, population, ROUND((CAST(total_cases AS float)/CAST(population AS float)), 4)* 100 AS percentage_covid
FROM PortfolioProject..CovidDeaths
WHERE location LIKE 'Barbados'
ORDER BY 1, 2;

-- Looking at countries with highest Infection Rate compared to Population
SELECT location, MAX(total_cases) AS highest_infection_count, population, ROUND(MAX((CAST(total_cases AS float)/CAST(population AS float))), 4)* 100 AS percentage_covid
FROM PortfolioProject..CovidDeaths
GROUP BY location, population
ORDER BY percentage_covid DESC;

-- Countries with Highest Death Count per Population
SELECT location, MAX(CAST(total_deaths AS int)) AS total_death_count
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL 
GROUP BY location, population
ORDER BY total_death_count DESC;

-- Let's break things down by continent
SELECT location, MAX(CAST(total_deaths AS int)) AS total_death_count
FROM PortfolioProject..CovidDeaths
WHERE continent IS NULL AND location NOT IN ('High income', 'Upper middle income', 'Lower middle income', 'Low income')
GROUP BY location
ORDER BY total_death_count DESC;

-- Global numbers
SELECT SUM(new_cases) AS cases, SUM(CAST(new_deaths AS int)) AS deaths, ROUND(SUM(CAST(new_deaths AS int))/SUM(new_cases),4)*100  AS death_percentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1, 2
SET ARITHIGNORE OFF; -- To avoid divide by NULL error

-- Joins
-- Total pop vs Vaccinations (per day)
SELECT death.continent, death.location, death.date, death.population, vac.new_vaccinations
FROM PortfolioProject..CovidDeaths AS death
JOIN PortfolioProject..CovidVaccinations AS vac
ON death.location = vac.location
AND death.date = vac.date
WHERE death.continent IS NOT NULL
ORDER BY 2, 3;

SELECT death.continent, death.location, death.date, death.population, vac.new_vaccinations, 
SUM(CONVERT(int,vac.new_vaccinations)) OVER (PARTITION BY death.location ORDER BY death.location, death.date) AS rolling_ppl_vac,
FROM PortfolioProject..CovidDeaths AS death
JOIN PortfolioProject..CovidVaccinations AS vac
ON death.location = vac.location
AND death.date = vac.date
WHERE death.continent IS NOT NULL
ORDER BY 2, 3;

-- USE CTE

WITH pop_vs_vac(continent, location, date, population, new_vaccinations, rolling_ppl_vac)
AS
(
SELECT death.continent, death.location, death.date, death.population, vac.new_vaccinations, 
SUM(CONVERT(int,vac.new_vaccinations)) OVER (PARTITION BY death.location ORDER BY death.location, death.date) AS rolling_ppl_vac
FROM PortfolioProject..CovidDeaths AS death
JOIN PortfolioProject..CovidVaccinations AS vac
ON death.location = vac.location
AND death.date = vac.date
WHERE death.continent IS NOT NULL
)

SELECT *, (rolling_ppl_vac/population)*100
FROM pop_vs_vac
ORDER BY location;


-- TEMP TABLE

DROP TABLE IF EXISTS #percent_pop_vac
CREATE TABLE #percent_pop_vac
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
rolling_ppl_vac numeric
)

INSERT INTO #percent_pop_vac
SELECT death.continent, death.location, death.date, death.population, vac.new_vaccinations, 
SUM(CONVERT(int,vac.new_vaccinations)) OVER (PARTITION BY death.location ORDER BY death.location, death.date) AS rolling_ppl_vac
FROM PortfolioProject..CovidDeaths AS death
JOIN PortfolioProject..CovidVaccinations AS vac
ON death.location = vac.location
AND death.date = vac.date
WHERE death.continent IS NOT NULL

SELECT *, ROUND((rolling_ppl_vac/population),4)*100
FROM #percent_pop_vac
ORDER BY location;


-- Creating view to store dat for later visualisations 

CREATE VIEW percent_pop_vac AS
SELECT death.continent, death.location, death.date, death.population, vac.new_vaccinations, 
SUM(CONVERT(int,vac.new_vaccinations)) OVER (PARTITION BY death.location ORDER BY death.location, death.date) AS rolling_ppl_vac
FROM PortfolioProject..CovidDeaths AS death
JOIN PortfolioProject..CovidVaccinations AS vac
ON death.location = vac.location
AND death.date = vac.date
WHERE death.continent IS NOT NULL;

SELECT *
FROM percent_pop_vac