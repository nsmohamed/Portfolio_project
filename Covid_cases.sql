USE PortfolioProject
GO
SELECT*
FROM PortfolioProject..covid_deaths
WHERE continent is not NULL
ORDER BY 3,4


--SELECT *
--FROM PortfolioProject..covid_vac
--ORDER BY 3,4

SELECT location, date, total_cases, new_cases, total_deaths, population 
FROM PortfolioProject..covid_deaths
ORDER BY 1,2;

--Looking at total cases vs total deaths
-- shows the likelihood of dying if you contract covid in egypt
SELECT location, date, total_cases,  total_deaths, (total_deaths/total_cases)*100 AS deathpercentage
FROM PortfolioProject..covid_deaths
WHERE location like 'Egypt' AND  continent is not NULL
ORDER BY 1,2;

-- Looking at Total Case vs Population
-- shows what percentage of population got COVID
SELECT location, date, total_cases,  population ,(total_cases/population)*100 cases_population
FROM PortfolioProject..covid_deaths
WHERE location like 'Egypt' AND  continent is not NULL
ORDER BY 1,2;


--countries with highest infection rate compared to population.
SELECT location, population, MAX(total_cases) HighesInfectionCount, MAX(total_cases/population)*100 population_infected
FROM PortfolioProject..covid_deaths
WHERE continent is not NULL
GROUP BY location, population
ORDER BY 3 DESC;

--showing countries with Highest Death Count per population
SELECT location, population, MAX(CAST(total_deaths AS int))max_deaths, MAX(total_deaths/population)*100 death_percentage
FROM PortfolioProject..covid_deaths
WHERE continent is not NULL
GROUP BY location, population
ORDER BY 3 DESC;

--Break things down to continents
SELECT location,  CAST(total_deaths AS int)max_deaths
FROM PortfolioProject..covid_deaths
WHERE continent is not NULL
GROUP BY location, CAST(total_deaths AS int)
ORDER BY 2 DESC;

--Showing continents with highest death count
SELECT continent,  MAX(CAST(total_deaths AS int))max_deaths, MAX(total_deaths/population)*100 death_percentage
FROM PortfolioProject..covid_deaths
WHERE continent is Not NULL
GROUP BY continent
ORDER BY 2 DESC;

----Fill in the NULL values in continent for more thorough data
--UPDATE a
--SET a.continent = a.location
--FROM PortfolioProject..covid_deaths a
--WHERE a.continent IS NULL

-- Global numbers
SELECT SUM(new_cases) AS total_cases, SUM(CAST(new_deaths AS int))total_deaths, SUM(CAST(new_deaths AS int))/SUM(new_cases+1) Death_percentage
FROM PortfolioProject..covid_deaths
WHERE continent is NOT NULL
--GROUP BY date
ORDER BY 1,2;

-- Looking at total population vs vaccinations

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(BIGINT,vac.new_vaccinations )) OVER (partition BY dea.location ORDER BY dea.location, dea.date) AS rolling_people_vaccinated
FROM PortfolioProject..covid_vac vac
JOIN PortfolioProject..covid_deaths dea
	ON  dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null
ORDER BY 1,2,3;

--USE CTE

WITH t1 ( Continent, Location, Date, Population,New_Vaccinations, rolling_people_vaccinated)
AS(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(BIGINT,vac.new_vaccinations )) OVER (partition BY dea.location ORDER BY dea.location, dea.date) AS rolling_people_vaccinated
FROM PortfolioProject..covid_vac vac
JOIN PortfolioProject..covid_deaths dea
	ON  dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null
--ORDER BY 1,2,3
)

SELECT Location, Population, New_Vaccinations,(rolling_people_vaccinated/Population)
FROM t1

--TEMP Table
DROP table if exists #PercentagePopulationVaccinated
Create table #PercentagePopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_Vaccinations numeric,
rolling_people_vaccinated numeric
)

INSERT into #PercentagePopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(BIGINT,vac.new_vaccinations )) OVER (partition BY dea.location ORDER BY dea.location, dea.date) AS rolling_people_vaccinated
FROM PortfolioProject..covid_vac vac
JOIN PortfolioProject..covid_deaths dea
	ON  dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null
ORDER BY 1,2,3

--Creating view to store data for later visualization
Create view PercentagePopulationVaccinated as
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(BIGINT,vac.new_vaccinations )) OVER (partition BY dea.location ORDER BY dea.location, dea.date) AS rolling_people_vaccinated
FROM PortfolioProject..covid_vac vac
JOIN PortfolioProject..covid_deaths dea
	ON  dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null
--ORDER BY 1,2,3

SELECT *
From PercentagePopulationVaccinated