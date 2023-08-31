--Link to Dataset: https://ourworldindata.org/covid-deaths

--Top 3 countries by infection rate per continent
with infection_rate as (
select rank() over(partition by continent order by max(total_cases)/max(population) desc) as continent_rank,
continent,location,population,round(max(total_cases)/max(population)*100,2) as infection_rate
from CovidDeaths
where continent is not Null
group by location,continent,population)

select *
from infection_rate
where continent_rank<=3
order by avg(infection_rate) over(partition by continent) desc --order by the highest rate in the continent level

--Check vaccinations/population ratio for specific country
with popVSvac as (
select vac.continent,vac.location,vac.date,population,
sum(convert(int,new_vaccinations)) over(partition by vac.location order by vac.location,vac.date) as cumulative_vaccinations_num
from CovidVaccinations as vac
join CovidDeaths as dea on vac.location=dea.location and vac.date=dea.date)

select *,round(cumulative_vaccinations_num/population*100,2) as vaccinations_population_ratio
from popVSvac
where location='United Kingdom'
order by 3

-- Rank months by number of countries where each month was the deadliest
with deaths_by_month as(
select location, format(date,'yyyy-MM') as 'Month',sum(convert(int,new_deaths)) as total_deaths
from CovidDeaths
where continent is not null
group by location,format(date,'yyyy-MM'))

select Month,count(*) as Deadliest_Month_Countries_Count
from(
select location,Month,total_deaths
from deaths_by_month as t1
where total_deaths=(select max(total_deaths) from deaths_by_month t2 where t1.location=t2.location)) as sub
where total_deaths is not null --exclude countries that have 0 deaths
group by Month
order by count(*) desc

--Vaccine Rollout Efficiency (check number of days to reach vaccination/population ratio of 10%)
with first_vac as(
select location,min(date) as date
from CovidVaccinations
where (total_vaccinations is not null or total_vaccinations!=0)  and continent is not null
group by location),

ten_percent_vac as (
select vac.location,min(vac.date) as date
from CovidVaccinations as vac
join CovidDeaths as dea
on vac.location=dea.location and vac.date=dea.date
where convert(int,total_vaccinations)/population*100>=10
group by vac.location)

select first_vac.location, DATEDIFF(DAY,first_vac.date,ten_percent_vac.date) as 'days_to_reach_10_percent_vac/pop_ratio'
from first_vac 
join ten_percent_vac on first_vac.location=ten_percent_vac.location
order by DATEDIFF(DAY,first_vac.date,ten_percent_vac.date)
