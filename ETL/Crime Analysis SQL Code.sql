--creating DIM_STATE

create table DIM_STATE(
STATE_ID int identity(1,1) primary key,
STATE_NAME varchar(50)
)

--Inserting DIM_STATE

insert into DIM_STATE(STATE_NAME) select state_ut from [dbo].[crime_by_district] group by STATE_UT having count(*) > 1;

--removing unwanted data

delete from DIM_STATE where state_id = 24

delete from DIM_STATE where state_id = 13

--creating DIM_DISTRICT

create table DIM_DISTRICT(
DISTRICT_ID int,
DISTRICT_NAME varchar(50),
STATE_ID int FOREIGN KEY REFERENCES DIM_STATE(STATE_ID)
)

--inserting DIM_DISTRICT

insert into DIM_DISTRICT (DISTRICT_ID, DISTRICT_Name, STATE_ID)
select  DENSE_RANK() over(order by district, state_ut) as district_id, district,state_id from [dbo].[crime_by_district]
join DIM_STATE on [dbo].[crime_by_district].STATE_UT = DIM_STATE.STATE_NAME


--creating FACT_STATE

create table FACT_STATE (state_id int, year int, Murder int, Assault_on_women int, Kidnapping_and_Abduction int,
Dacoity int, Robbery int, Arson int, Hurt int, Prevention_of_atrocities_POA_Act int, Protection_of_Civil_Rights_PCR_Act int,
Other_Crimes_Against_SCs int
)

--inserting FACT_STATE

insert into FACT_STATE
select f1.state_id, f2.Year, sum(f2.Murder), sum( f2.Assault_on_women), sum(f2.Kidnapping_and_Abduction), sum(f2.Dacoity), sum(f2.Robbery), sum(f2.Arson),
sum(f2.Hurt), sum(f2.Prevention_of_atrocities_POA_Act), sum(f2.Protection_of_Civil_Rights_PCR_Act), sum(f2.Other_Crimes_Against_SCs) from DIM_STATE as f1 inner join
[dbo].[crime_by_district] as f2 on f1.state_name = f2.state_ut group by f1.State_Id, f2.year

--creating FACT_DISTRICT

create table FACT_DISTRICT (state_id int FOREIGN KEY REFERENCES DIM_STATE(STATE_ID),district_id int, year int, Murder int, Assault_on_women int, Kidnapping_and_Abduction int,
Dacoity int, Robbery int, Arson int, Hurt int, Prevention_of_atrocities_POA_Act int, Protection_of_Civil_Rights_PCR_Act int,
Other_Crimes_Against_SCs int
)

--Inserting FACT_DISTRICT

insert into FACT_DISTRICT
select s1.state_id,s1.District_Id,s2.year,s2.[Murder],s2.[Assault_on_women], s2.[Kidnapping_and_Abduction],
s2.[Dacoity],s2.[Robbery],s2.[Arson],s2.[Hurt],s2.[Prevention_of_atrocities_POA_Act],
s2.[Protection_of_Civil_Rights_PCR_Act], s2.[Other_Crimes_Against_SCs]
from DIM_DISTRICT as s1 inner join [dbo].[crime_by_district] as s2 on s1.District_Name = s2.DISTRICT
group by District_Id,State_Id,Year,Murder,Assault_on_women,Kidnapping_and_Abduction,Dacoity,Robbery,Arson,
Hurt,Prevention_of_atrocities_POA_Act,Protection_of_Civil_Rights_PCR_Act,Other_Crimes_Against_SCs;

--creating some calculated tables for answering question 3 and 4
--creating table TOTAL_CRIME_BY_DISTRICT

create table Total_crimes_by_district(
Total_crimes_by_district int,
district_id int,
state_id int,
)

--Inserting Total_crimes_by_district

insert into Total_crimes_by_district
select sum(Murder) + sum(Assault_on_women) + sum(Kidnapping_and_Abduction) + sum(Dacoity) + sum(Robbery) +
sum(Arson) + sum(Hurt) + sum(Prevention_of_atrocities_POA_Act) + sum(Protection_of_Civil_Rights_PCR_Act) + sum(Other_Crimes_Against_SCs) as Total_crimes_by_district,
district_id, state_id 
from fact_district group by district_id, state_id order by  state_id

--creating min crime table for district 

create table min_crime(
min_total_crime int,
state_id int,
)

--Inserting min_crime

insert into min_crime
select min(Total_crimes_by_district) as min_total_crime, state_id from Total_crimes_by_district group by state_id 
order by state_id


--creating max crime table for district

create table max_crime(
max_total_crime int,
state_id int,
)

--Inserting max_crime

insert into max_crime
select max(Total_crimes_by_district) as max_total_crime, state_id from Total_crimes_by_district group by state_id 
order by state_id

--using the below query in power BI for inserting calucated tables for answering question 3 and 4

select f1.district_id, f2.min_total_crime from Total_crimes_by_district as f1 inner join min_crime as f2
on f1.state_id = f2.state_id where f1.Total_crimes_by_district = f2.min_total_crime

select f1.district_id, f2.max_total_crime from Total_crimes_by_district as f1 inner join max_crime as f2
on f1.state_id = f2.state_id where f1.Total_crimes_by_district = f2.max_total_crime and f2.max_total_crime >= 30

--creating some calculated tables for answering question 1 and 2
--creating avg crime by district table

create table avg_crime(
Total_crimes_by_state int, 
state_id int,
state_name varchar(50),
)
--Inserting avg_crime

insert into avg_crime
select sum(f1.Murder) + sum(f1.Assault_on_women) + sum(f1.Kidnapping_and_Abduction) + sum(f1.Dacoity) + sum(f1.Robbery) +
sum(f1.Arson) + sum(f1.Hurt) + sum(f1.Prevention_of_atrocities_POA_Act) + sum(f1.Protection_of_Civil_Rights_PCR_Act) + sum(f1.Other_Crimes_Against_SCs) as Total_crimes_by_state, f1.state_id, f2.state_name 
from FACT_STATE as f1 inner join DIM_STATE as f2 on f2.STATE_ID = f1.state_id
group by f1.state_id, f2.STATE_NAME order by f1.state_id asc

--using the below query in power BI for inserting calucated tables for answering question 1 and 2

select state_name,state_id,Total_crimes_by_state from avg_crime where Total_crimes_by_state < (select AVG(Total_crimes_by_state) from avg_crime)

select state_name,state_id,Total_crimes_by_state from avg_crime where Total_crimes_by_state > (select AVG(Total_crimes_by_state) from avg_crime)
