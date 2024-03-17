SELECT *
FROM PortfolioProject..covidDeaths
WHERE continent is not null
ORDER BY 3,4

SELECT *
FROM PortfolioProject..covidVaccinations
ORDER BY 3,4

--Select Data that we are going to be using
SELECT location,date,total_cases,new_cases,total_deaths,population
FROM PortfolioProject..covidDeaths
WHERE continent is not null
ORDER BY 1,2

--Looking at Total Cases vs Total Deaths
SELECT location,date,total_cases,total_deaths,(CAST(total_deaths AS FLOAT)/CAST(total_cases AS FLOAT))*100 AS DeathPercentage
FROM PortfolioProject..covidDeaths
WHERE location LIKE '%states%'
AND continent is not null
ORDER BY 1,2

--Total Cases vs Population
--Shows what percentage of population infected with Covid
SELECT location,date,population,total_cases,(total_cases/population)*100 AS PercentPopulationInfected
FROM PortfolioProject..covidDeaths
ORDER BY 1,2

--Countries with Highest Infection Rate compared to Population
SELECT location,population,MAX(total_cases) AS HighestInfectionCount,MAX((total_cases/population))*100 AS PercentPopulationInfected
FROM PortfolioProject..covidDeaths
GROUP BY location,population
ORDER BY PercentPopulationInfected desc

--Countries with Highest Death Count per Population
SELECT location,MAX(cast(Total_deaths AS int)) AS TotalDeathCount
FROM PortfolioProject..covidDeaths
WHERE continent is not null
GROUP BY location
ORDER BY TotalDeathCount desc

--Breaking things down by Continent
--Showing Continents with the Highest Death Count per Population
SELECT continent,MAX(cast(Total_deaths AS int)) AS TotalDeathCount
FROM PortfolioProject..covidDeaths
WHERE continent is not null
GROUP BY continent
ORDER BY TotalDeathCount desc

--Global Numbers
SELECT SUM(new_cases) AS TotalCases, SUM(CAST(new_deaths AS int)) AS TotalDeaths, SUM(CAST(new_deaths AS int))/SUM(new_cases)*100 AS DeathPercentage
FROM PortfolioProject..covidDeaths
WHERE continent is not null
ORDER BY 1,2

--Total Population VS Vaccinations
--Shows Percentage of Population that has received at least one Covid Vaccine
SELECT dea.continent,dea.location,dea.date,dea.population,vac.new_vaccinations, SUM(CONVERT(Bigint,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location,dea.date)
AS RollingPeopleVaccinated
FROM PortfolioProject..covidDeaths AS dea
JOIN PortfolioProject..covidVaccinations AS vac
ON dea.location=vac.location AND dea.date=vac.date
WHERE dea.continent is not null
ORDER BY 2,3

--Using CTE to perform Calculation on Partition By in previous query
WITH PopvsVac (continent,location,date,population,new_vaccinations,RollingPeopleVaccinated) AS
(SELECT dea.continent,dea.location,dea.date,dea.population,vac.new_vaccinations,SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location,dea.date)
AS RollingPeopleVaccinated
FROM PortfolioProject..covidDeaths AS dea
JOIN PortfolioProject..covidVaccinations AS vac
ON dea.location=vac.location AND dea.date=vac.date
WHERE dea.continent is not null
)
SELECT * ,(RollingPeopleVaccinated/population)*100 AS PercentPeopleVaccinated
FROM PopvsVac

--Using Temp Table to perform Calculation on Partition By in previous query
DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
RollingPeopleVaccinated numeric)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent,dea.location,dea.date,dea.population,vac.new_vaccinations,SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location,dea.date)
AS RollingPeopleVaccinated
FROM PortfolioProject..covidDeaths AS dea
JOIN PortfolioProject..covidVaccinations AS vac
ON dea.location=vac.location AND dea.date=vac.date
WHERE dea.continent is not null

SELECT  *,(RollingPeopleVaccinated/population)*100
FROM #PercentPopulationVaccinated

--Creating View to store data for later Visualizations
CREATE VIEW PercentPeopleVaccinated AS
SELECT dea.continent,dea.location,dea.date,dea.population,vac.new_vaccinations,SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location,dea.date)
AS RollingPeopleVaccinated
FROM PortfolioProject..covidDeaths AS dea
JOIN PortfolioProject..covidVaccinations AS vac
ON dea.location=vac.location AND dea.date=vac.date
WHERE dea.continent is not null

SELECT * , (RollingPeopleVaccinated/Population)*100 
FROM PercentPeopleVaccinated
