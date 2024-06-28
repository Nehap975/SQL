/* Query Warriors - Team 24 */

-- 1.Write a query to get a list of patients with event type of EGV and  glucose (mgdl) greater than 155 .
 
SELECT DISTINCT d.patientid AS patient_id, e.event_type, MAX(d.glucose_value_mgdl) AS max_glucose_value
FROM dexcom AS d INNER JOIN eventtype AS e ON d.eventid = e.id
WHERE e.event_type = 'EGV' AND d.glucose_value_mgdl > 155
GROUP BY patient_id, e.event_type
ORDER BY patient_id

-----------------------------------------------------------------------------------------------------------
-- 2.How many patients consumed meals with at least 20 grams of protein in it?

SELECT COUNT (*) AS no_of_patients 
FROM foodlog
WHERE protein > 20

-----------------------------------------------------------------------------------------------------------
-- 3.Who consumed maximum calories during dinner? (assuming the dinner time is after 6pm-8pm)

select d.patientid,d.firstname||' '||d.lastname as full_name,sum(f.calorie)as total_calorie from public.foodlog f 
join public.demographics d on f.patientid=d.patientid where 
EXTRACT(HOUR FROM "datetime")>=18 or EXTRACT(HOUR FROM "datetime")>=20 
group by f.patientid,d.firstname,d.patientid
order by total_calorie desc limit 1;

-----------------------------------------------------------------------------------------------------------
--4.Which patient showed a high level of stress on most days recorded for him/her?

WITH Stress_Days AS (
 SELECT d.patientid, d.firstname || ' ' || d.lastname AS full_name,
 DATE(i.datestamp) AS observation_date, (AVG(i.rmssd_ms) * 600) AS hrv,
 MAX(h.max_hr) AS max_hr, MAX(e.max_eda) AS max_eda
 FROM demographics d
 INNER JOIN ibi i ON d.patientid = i.patientid
 INNER JOIN hr h ON d.patientid = h.patientid
 INNER JOIN eda e ON d.patientid = e.patientid
 GROUP BY d.patientid, full_name, observation_date
 HAVING (AVG(i.rmssd_ms) * 600) < 20 OR MAX(h.max_hr) > 100 OR MAX(e.max_eda) > 40
 )
 SELECT patientid, full_name,
 COUNT(*) AS stress_days
 FROM Stress_Days
 GROUP BY patientid, full_name
 ORDER BY stress_days DESC limit 5
 ;
 
-----------------------------------------------------------------------------------------------------------
--5.Based on mean HR and HRV alone, which patient would be considered least healthy?
-- -- when evaluated with ‘or’ condition,
-- mean_hr<60 or mean_hr>100 or hrs <20 - patient health rank as follows

WITH PatientHealth AS (
SELECT h.patientid, h.mean_hr,(AVG(i.rmssd_ms) * 600) AS hrv,
CASE 
WHEN h.mean_hr < 60 THEN 100 - h.mean_hr
WHEN h.mean_hr > 100 THEN h.mean_hr - 100
ELSE 0
END AS hr_score
FROM hr AS h INNER JOIN ibi AS i ON h.patientid = i.patientid
GROUP BY h.patientid, h.mean_hr
HAVING h.mean_hr < 60 OR h.mean_hr > 100 or (AVG(i.rmssd_ms) * 600) < 20
)
SELECT patientid, mean_hr, hrv, hr_score,
RANK() OVER (ORDER BY hr_score DESC) AS health_rank
FROM PatientHealth
ORDER BY health_rank 

-- when evaluated with 'or' and ‘and’ condition,
-- mean_hr<60 or mean_hr>100 and hrv <20 - - no patient met the condition

WITH PatientHealth AS (
SELECT h.patientid, h.mean_hr,(AVG(i.rmssd_ms) * 600) AS hrv,
CASE 
WHEN h.mean_hr < 60 THEN 100 - h.mean_hr
WHEN h.mean_hr > 100 THEN h.mean_hr - 100
ELSE 0
END AS hr_score
FROM hr AS h INNER JOIN ibi AS i ON h.patientid = i.patientid
GROUP BY h.patientid, h.mean_hr
HAVING h.mean_hr < 60 OR h.mean_hr > 100 and (AVG(i.rmssd_ms) * 600) < 20
)
SELECT patientid, mean_hr, hrv, hr_score,
RANK() OVER (ORDER BY hr_score DESC) AS health_rank
FROM PatientHealth
ORDER BY health_rank 

-----------------------------------------------------------------------------------------------------------
--6.Create a table that stores any Patient Demographics of your choice as the parent table. 
-- Create a child table that contains max_EDA and mean_HR per patient and inherits all columns from the parent table

CREATE TABLE patient_demographic
(patient_id int NOT NULL, patient_name varchar(100), gender varchar(10), dob date ); 

insert into patient_demographic(patient_id,patient_name,gender,dob) 
values(18,'kail','Male','1990-01-01')
	
CREATE TABLE child_patient_demographic
(max_eda double precision , mean_hr double precision)INHERITS (patient_demographic); 
select * from public.demographics
SELECT * FROM patient_demographic

SELECT * FROM child_patient_demographic

-- Drop table patient_demographic

-----------------------------------------------------------------------------------------------------------
--7.What percentage of the dataset is male vs what percentage is female?

SELECT
    100 * SUM(CASE WHEN gender = 'MALE' THEN 1 ELSE 0 END) / COUNT(*) AS male_perc,
    100 * SUM(CASE WHEN gender = 'FEMALE' THEN 1 ELSE 0 END) / COUNT(*) AS female_perc
FROM public.demographics;

-----------------------------------------------------------------------------------------------------------
--8.Which patient has the highest max eda?


SELECT patientid AS patient_id, MAX(max_eda) AS max_eda FROM eda 
GROUP BY patient_id ORDER BY max_eda DESC LIMIT 1

-----------------------------------------------------------------------------------------------------------
--9.Display details of the prediabetic patients.

select * from public.demographics where hba1c between 5.7 and 6.4 


-----------------------------------------------------------------------------------------------------------
-- 10.List the patients that fall into the highest EDA category by name, gender and age

SELECT d.patientid, d.firstname AS name, d.gender, 
DATE_PART('year', AGE(now(), d.dob)) AS age, CAST(e.max_eda AS NUMERIC (10,2)),
CASE
  WHEN e.max_eda >= threshold_high THEN 'High'
  WHEN e.max_eda >= threshold_medium THEN 'Medium'
  ELSE 'Low'
  END AS "EDA Category"
FROM eda AS e INNER JOIN demographics AS d ON e.patientid = d.patientid
CROSS JOIN (
SELECT
  45 AS threshold_high,
  20 AS threshold_medium
) AS thresholds
WHERE e.max_eda >= threshold_high
ORDER BY e.max_eda DESC;

-----------------------------------------------------------------------------------------------------------
-- 11.How many patients have names starting with 'A'?

SELECT COUNT(*) AS no_of_patients 
FROM demographics WHERE firstname like 'A%'

-----------------------------------------------------------------------------------------------------------
--12.Show the distribution of patients across age.

SELECT
  CASE
    WHEN age BETWEEN 0 AND 19 THEN '0-19'
    WHEN age BETWEEN 20 AND 39 THEN '20-39'
    WHEN age BETWEEN 40 AND 59 THEN '40-59'
    WHEN age BETWEEN 60 AND 79 THEN '60-79'
    ELSE '80+'
  END AS age_range,
  COUNT(*) AS no_of_patients
FROM (
 SELECT DATE_PART('year', AGE( NOW(), dob)) AS age
 FROM demographics ) AS patient_age
GROUP BY age_range
ORDER BY age_range;


-----------------------------------------------------------------------------------------------------------
--13.Display the Date and Time in 2 seperate columns for the patient who consumed only Egg



SELECT patientid, logged_food,
CAST (to_char(datetime,'YYYY-MM-DD')AS date)AS date,
CAST (to_char(datetime,'HH24:MI:SS')AS time)AS time
FROM foodlog WHERE logged_food LIKE 'egg'

-----------------------------------------------------------------------------------------------------------
--14.Display list of patients along with the gender and hba1c for whom the glucose value is null.

SELECT DISTINCT dem.patientid AS patient_id, dem.firstname AS first_name, dem.gender, 
dem.hba1c, dex.glucose_value_mgdl
FROM demographics AS dem INNER JOIN dexcom AS dex 
ON dem.patientid = dex.patientid
WHERE dex.glucose_value_mgdl IS NULL

-----------------------------------------------------------------------------------------------------------
--15.Rank patients in descending order of Max blood glucose value per day

WITH daily_max_blood_sugar AS (
  SELECT patientid,
  DATE(datestamp) AS day,
  MAX(glucose_value_mgdl) AS max_blood_sugar
  FROM dexcom
  GROUP BY patientid,
  DATE(datestamp)
)
SELECT patientid, day,max_blood_sugar,
  RANK() OVER (ORDER BY max_blood_sugar DESC) AS rank
FROM daily_max_blood_sugar
ORDER BY max_blood_sugar DESC;
-----------------------------------------------------------------------------------------------------------
--16 Assuming the IBI per patient is for every 10 milliseconds, calculate Patient-wise HRV from RMSSD.

Select * from ibi

select patientid,Avg(rmssd_ms*600) as hrv from public.ibi group by patientid


-----------------------------------------------------------------------------------------------------------
---17.What is the % of total daily calories consumed by patient 14 after 3pm Vs Before 3pm?
--Using common table expression

select cast(to_char(datetime,'HH:MI:SS') as time),* from public.foodlog where  
			cast(to_char(datetime,'HH24:MI:SS') as time) < '15:00:00';-- THEN '1' ELSE 0 END

WITH calorie_summary AS (
    SELECT
        patientid,
        SUM(CASE WHEN  cast(to_char(datetime,'HH24:MI:SS')as time)< '15:00:00' THEN calorie ELSE 0 END) AS calories_before_3pm,
        SUM(CASE WHEN  cast(to_char(datetime,'HH24:MI:SS')as time)>= '15:00:00' THEN calorie ELSE 0 END) AS calories_after_3pm
    FROM
       public.foodlog 
    WHERE
        patientid = 14
    GROUP BY
        patientid
)

-- Calculate the percentage
SELECT
    patientid,
    calories_before_3pm,
    calories_after_3pm,
    CASE
        WHEN calories_before_3pm + calories_after_3pm > 0 THEN
        Round((calories_after_3pm * 100.0) / (calories_before_3pm + calories_after_3pm),2)
        ELSE
            0  -- To handle division by zero
    END AS percentage_after_3pm,
	 CASE
        WHEN calories_before_3pm + calories_after_3pm > 0 THEN
        Round((calories_before_3pm * 100.0) / (calories_before_3pm + calories_after_3pm),2)
        ELSE
            0  -- To handle division by zero
    END AS percentage_before_3pm
	
FROM
    calorie_summary;
-----------------------------------------------------------------------------------------------------------------
--18.Display 5 random patients with HbA1c less than 6.

select patientid, firstname,hba1c from public.demographics where hba1c<6 order by random() limit 5
-----------------------------------------------------------------------------------------------------------------
--19.Generate a random series of data using any column from any table as the base

select * from public.demographics where gender='FEMALE' order by random() 
-----------------------------------------------------------------------------------------------------------------
--20.Display the foods consumed by the youngest patient

select d.patientid,d.dob,l.logged_food  
from public.demographics d join public.foodlog l on d.patientid=l.patientid  
and l.patientid=(select patientid from foodlog order by dob desc limit 1)
-----------------------------------------------------------------------------------------------------------------
--21.Identify the patients that has letter 'h' in their first name and print the last letter of their first name.

select firstname,right(firstname,1)as lastletter from public.demographics where firstname like '%h%'  
-----------------------------------------------------------------------------------------------------------------
--22.Calculate the time spent by each patient outside the recommended blood glucose range

select patientid,count(*) as cnt from public.dexcom group by patientid order by cnt asc;

WITH CTE_Range as
(
SELECT patientid, glucose_value_mgdl, CAST(datestamp as  DATE) OUT_DATE, CAST(datestamp as  TIME) OUT_TIME,
CASE
WHEN glucose_value_mgdl <55 then 'Out Of Range'
WHEN glucose_value_mgdl > 200 then 'Out Of Range' END as Glucose_Level
FROM public.dexcom
)
--SELECT * FROM CTE_Range
,

CTE_MAX_MIN
 as
 (
SELECT patientid, OUT_DATE, MAX(out_time) max, MIN(out_time) min --DATE_PART('minute', MAX(out_time) - MIN(out_time)) /60) as Min_Diff 
FROM CTE_Range
WHERE Glucose_Level IS NOT NULL
GROUP BY patientid, OUT_DATE
ORDER BY patientid
)

SELECT patientid, SUM(DATE_PART('minute', (max - min))) as Min_Diff  FROM CTE_MAX_MIN
GROUP BY patientid
ORDER BY SUM(DATE_PART('minute', (max - min))) DESC
-----------------------------------------------------------------------------------------------------------------
--23.Show the time in minutes recorded by the Dexcom for every patient

SELECT patientid,round(sum(EXTRACT(hour FROM datestamp)*60+EXTRACT(minute FROM datestamp)+
EXTRACT(second FROM datestamp)/60),2) as minutes from public.dexcom
group by patientid ;
-----------------------------------------------------------------------------------------------------------------
--24.List all the food eaten by patient Phill Collins

select d.firstname,f.logged_food from demographics d 
join foodlog f on d.patientid=f.patientid 
where firstname='Phill';
-----------------------------------------------------------------------------------------------------------------
--25.Create a stored procedure to delete the min_EDA column in the table EDA

select * from eda;

create procedure storedprotable()
Language 'plpgsql'
as $$
begin

     alter table eda 
	 drop column min_eda;
	 commit;
	 end;
	 $$;
	 
end  

call storedprotable();

select * from eda;

-- select min_eda from eda 
-----------------------------------------------------------------------------------------------------------------
--26.When is the most common time of day for people to consume spinach?

WITH CTE_Time as
(
SELECT CAST(DATETIME as TIME) EAT_TIME
from public.foodlog 
where logged_food like '%pinach%' 
ORDER BY EAT_TIME
),

CTE_EATING_TIME
as (

SELECT EAT_TIME, 
CASE 
WHEN EAT_TIME Between '06:00:00' and '12:00:00' then 'Morning'
WHEN EAT_TIME Between '12:00:00' and '18:00:00' then 'Afternoon'
WHEN EAT_TIME Between '18:00:00' and '21:00:00' then 'Evening' 
ELSE 'Night' end  as Eating_time
FROM CTE_Time
)

--SELECT * FROM CTE_EATING_TIME

SELECT Eating_time, COUNT(*) MAX_COUNT
FROM CTE_EATING_TIME
GROUP BY Eating_time
ORDER BY MAX_COUNT DESC 
LIMIT 1
-----------------------------------------------------------------------------------------------------------------
--27.Classify each patient based on their HRV range as high, low or normal

--HRV > 70-high
--HRV between 20 and 70-normal
--HRV < 20-low

select patientid,case when AVG(rmssd_ms* 600)>70 then 'high'
                      when AVG(rmssd_ms* 600) between 20 and 70 then 'normal'
					  else 'low'
					  end as hrvvariations from ibi
					  group by patientid
					  order by patientid;
					  
-----------------------------------------------------------------------------------------------------------------
--28.List full name of all patients with 'an' in either their first or last names

select CONCAT(d."firstname", ' ', d."lastname") as fullname from demographics d where d.firstname like '%an%' or d.lastname like '%an%';
-------------------------------------------------------------------------------------------------------------------
--29.Display a pie chart of gender vs average HbA1c

select gender,avg(hba1c) as averagehba1c from public.demographics
group by gender;
-------------------------------------------------------------------------------------------------------------------
--30.The recommended daily allowance of fiber is approximately 25 grams a day.
--What % of this does every patient get on average?

select patientid,round((sum(dietary_fiber)/25)*100,2) as percentfiber,cast(to_char("datetime", 'YYYY-MM-DD') as date) from public.foodlog
group by to_char("datetime", 'YYYY-MM-DD'),patientid
order by patientid;
-------------------------------------------------------------------------------------------------------------------
-- 31.What is the relationship between EDA and Mean HR?
WITH CTE_STRESS_Value
as
(
select e.MAX_eda, h.mean_hr ,
CASE 
WHEN (e.MAX_eda > 40 and h.mean_hr > 100 ) then 'High Stress' 
end as Stress_Value 
from eda e
join hr h
on e.patientid=h.patientid 
)

SELECT * FROM CTE_STRESS_Value
WHERE Stress_Value IS NOT NULL

-- On evaluating the query, we found there is no rellationship between mean HR and  EDA

-------------------------------------------------------------------------------------------------------------------
-- 32. Show the patient that spent the maximum time out of range

WITH CTE_Range as
(
SELECT patientid, glucose_value_mgdl, CAST(datestamp as  DATE) OUT_DATE, CAST(datestamp as  TIME) OUT_TIME,
CASE
WHEN glucose_value_mgdl <55 then 'Out Of Range'
WHEN glucose_value_mgdl > 200 then 'Out Of Range' END as Glucose_Level
FROM public.dexcom
)
--SELECT * FROM CTE_Range
,

CTE_MAX_MIN
 as
 (
SELECT patientid, OUT_DATE, MAX(out_time) max, MIN(out_time) min --DATE_PART('minute', MAX(out_time) - MIN(out_time)) /60) as Min_Diff 
FROM CTE_Range
WHERE Glucose_Level IS NOT NULL
GROUP BY patientid, OUT_DATE
ORDER BY patientid
)

SELECT patientid, SUM(DATE_PART('minute', (max - min))) as Minute_Diff  FROM CTE_MAX_MIN
GROUP BY patientid
ORDER BY SUM(DATE_PART('minute', (max - min))) DESC Limit 1;
					  
-----------------------------------------------------------------------------------------------------------------


--33.Create a User Defined function that returns min glucose value and patient ID for any date entered
     --select min_glu(1,'2020-02-13');
	 
	 
	 create or replace function min_glu(pid bigint, givendate date)
     returns real 
     language plpgsql
     as
     $$
     declare 
     -- variable declaration
    glumin real;
    begin
    -- logic
    select min(glucose_value_mgdl) into glumin from dexcom where patientid=pid and date(datestamp)=givendate and glucose_value_mgdl is not NULL;
 return glumin;
  end;
  $$
  
  
  
  --34. Write a query to find the day of highest mean HR value for each patient and display it along with the patient id.
SELECT * from hr;
select patientid,datestamp from hr hr1 where mean_hr = (
	 select  max(mean_hr) from hr hr2 where hr2.patientid=hr1.patientid);
	 
	 
	 --35.Create view to store Patient ID, Date, Avg Glucose value and Patient Day to every patient,
--ranging from 1-11 based on every patients minimum date and maximum date (eg: Day1,Day2 for each patient)
-- select * from dexcom;
create view vwavglucose as select patientid,date(datestamp),avg(glucose_value_mgdl) 
from dexcom group by patientid,date(datestamp) order by patientid,date(datestamp) ;

select * from vwavglucose;


--36.Using width bucket functions, group patients into 4 HRV categories

create or replace view hrvview as select patientid, avg(rmssd_ms)*600 as hrv 
from ibi group by patientid order by patientid;
SELECT
    width_bucket(hrv, 0, 80, 4) AS bucket_number,
    count(*) AS count_in_bucket
FROM
    hrvview
GROUP BY
    bucket_number
ORDER BY
    bucket_number;
	
	
	------------------------------------------------------------------------
--37. Is there a correlation between High EDA and  HRV. If so, display this data by querying 
--the relevant tables?

WITH HRV_Patients AS (
  SELECT i.patientid, AVG(i.rmssd_ms) * 600 AS hrv
  FROM ibi AS i GROUP BY i.patientid
),
High_EDA_Patients AS (
  SELECT DISTINCT e.patientid, e.max_eda FROM eda AS e
  WHERE e.max_eda > 40
)
SELECT
  HRV_Patients.patientid AS patient_id,
  CAST(HRV_Patients.hrv AS Numeric (10,2))AS hrv,
  High_EDA_Patients.max_eda AS max_eda
FROM HRV_Patients
INNER JOIN High_EDA_Patients
ON HRV_Patients.patientid = High_EDA_Patients.patientid
ORDER BY hrv DESC;

-- After querying the database ,we found no co-relation between Max EDA and HRV
	
	
--38.List hypoglycemic patients by age and gender


SELECT d.patientid,EXTRACT(year FROM age(current_date,dob)) :: int as age,d.gender, b.glucose_value_mgdl FROM 
public.demographics d
inner join  public.dexcom b
on d.patientid = b.patientid
where  b.glucose_value_mgdl <55
group by d.patientid,EXTRACT(year FROM age(current_date,dob)) ,d.gender,b.glucose_value_mgdl
order by d.patientid;

--40.Create a stored procedure that adds a column to table IBI. 
--The column should just be the date part extracted from IBI.Date
create procedure storedprotable()
Language 'plpgsql'
as $$
begin
     alter table ibi add column ididate date;
	 update ibi set ididate=date(datestamp);
	 commit;
end;
$$;
call storedprotable();
select * from ibi;

--41.Fetch the list of Patient ID's whose sugar consumption exceeded 30 grams on a meal from FoodLog table.

SELECT distinct patientid
FROM foodlog
WHERE sugar > 30 order by patientid;


	--42.How many patients are celebrating their birthday this month?

SELECT count(*) from demographics where EXTRACT(MONTH FROM dob)=extract(MONTH from current_date) ;


--43.How many different types of events were recorded in the 
--Dexcom tables? Display counts against each Event type

select count(e.eventid),et.event_type from dexcom e 
join eventtype et on e.eventid=et.id group by e.eventid,event_type

--44.How many prediabetic/diabetic patients also had a high level of stress? 

with stress as
(
select i.patientid,avg(i.rmssd_ms*600)as hrv,h.mean_hr as hr ,e.max_eda as ed from public.ibi i
 join eda e on i.patientid=e.patientid  
 join hr h on h.patientid=i.patientid group by i.patientid,h.mean_hr,e.max_eda
 ),
 pre as
 (
 select d.patientid,
case 
 when d.hba1c between 5.6 and 6.4  then 1 end as prediabetic,
case when d.hba1c>6.5 then 1 end as diabetic 
 from public.demographics d join stress s on  d.patientid=s.patientid 
 where ed>40 or hr>100 or hrv<20
 group by d.patientid
 )
 select count(prediabetic) as prediabetic,count(diabetic) as diabetic from pre 
 


--45.List the food that coincided with the time of highest blood sugar for every patient
WITH MaxGlucoseTime AS (
  SELECT dx.patientid,
    MAX(dx.glucose_value_mgdl) AS max_glucose,
    MAX(dx.datestamp) AS max_glucose_time
  FROM dexcom AS dx
  GROUP BY dx.patientid
)
SELECT
  dx.patientid,
  fl.logged_food,
  dx.max_glucose AS max_glucose,
  dx.max_glucose_time AS gv_time
FROM foodlog AS fl
INNER JOIN MaxGlucoseTime AS dx ON fl.patientid = dx.patientid
ORDER BY dx.patientid, dx.max_glucose DESC;

--46.How many patients have first names with length >7 letters?
--select * from demographics;
SELECT count(*) FROM demographics WHERE LENGTH(firstname) > 7



--47.List all foods logged that end with 'se'. Ensure that the output is in Title Case
--select * from foodlog;
select initcap(logged_food) from foodlog where logged_food similar to '%se';



--48 List the patients who had a birthday the same week as their glucose or IBI readings

with dob_week as
(
select   x.patientid,date_part('week',x.datestamp) as week_dex ,date_part('week',i.datestamp)
from dexcom x join ibi i on x.patientid=i.patientid group by x.patientid ,x.datestamp,i.datestamp
)
select distinct d.patientid,date_part('week',d.dob) from public.demographics d join dob_week dw on d.patientid=dw.patientid
where dw.week_dex=date_part('week',d.dob)




-- 49. Assuming breakfast is between 8 am and 11 am. How many patients ate a meal with bananas in it?

SELECT   Count(*) as Patient_Count
FROM public.foodlog
Where cast(Datetime as  time) Between '08:00:00' and '11:00:00'  AND Logged_Food LIKE '%anana%'

-----------------------------------------------------------------------------------------------------------------
-- 51. Based on Number of hyper and hypoglycemic incidents per patient,
--which patient has the least control over their blood sugar?

with Glucose_levels as
(select patientid , glucose_value_mgdl,
case
when glucose_value_mgdl >= 126 then '1'
when glucose_value_mgdl<70 then '2'
end as Glucose_levels
from public.dexcom
group by patientid,glucose_value_mgdl
order by patientid),
 hyper as
(SELECT patientid, COUNT(Glucose_levels) Hyper FROM glucose_levels
WHERE Glucose_levels = '1'
GROUP BY patientid),
 HYPO as
(SELECT patientid, COUNT(Glucose_levels) Hypo FROM glucose_levels
WHERE Glucose_levels = '2'
GROUP BY patientid),
 FINAL as
(SELECT A.patientid, Hyper, Hypo  FROM Hyper A
INNER JOIN HYPO B
ON A.patientid = B.patientid)
SELECT patientid, SUM(Hyper + Hypo) TOTL_EVNT  FROM  FINAL
GROUP BY patientid
ORDER BY TOTL_EVNT DESC LIMIT 1;

-----------------------------------------------------------------------------------------------------------------
-- 52. Display patients details with event details and minimum heart rate
WITH Event_Details as
(
select C.patientid,C.firstname, C.lastname, A.event_type, d.min_hr
FROM public.eventtype A
INNER JOIN public.dexcom B
ON A.id = B.eventid
INNER JOIN public.demographics C
ON B.patientid = C.patientid
INNER JOIN public.hr D
ON C.patientid = D.patientid
)
SELECT patientid,firstname,lastname, event_type, MIN (min_hr) FROM Event_Details
GROUP BY firstname,lastname, event_type,patientid

-----------------------------------------------------------------------------------------------------------------
-- 53. Display a list of patients whose daily max_eda lies between 40 and 50.

select A.firstname,A.lastname ,B.max_eda from public.demographics as A
inner join public.eda as B
on A.patientid = B.patientid
where max_eda between 40 and 50
-----------------------------------------------------------------------------------------------------------------
-- 54. Count the number of hyper and hypoglycemic incidents per patient
with Glucose_levels as 
(
select patientid , glucose_value_mgdl, 
case 
when glucose_value_mgdl >= 126 then '1'
when glucose_value_mgdl<70 then '2'
end as Glucose_levels
from public.dexcom
group by patientid,glucose_value_mgdl
order by patientid),

hyper as
(
SELECT patientid, COUNT(Glucose_levels) Hyper FROM glucose_levels
WHERE Glucose_levels = '1' 
GROUP BY patientid
),

HYPO as
(
SELECT patientid, COUNT(Glucose_levels) Hypo FROM glucose_levels
WHERE Glucose_levels = '2' 
GROUP BY patientid
),
FINAL as
(
SELECT A.patientid, Hyper, Hypo  FROM Hyper A
INNER JOIN HYPO B
ON A.patientid = B.patientid
)
SELECT patientid, Hyper , Hypo  FROM  FINAL
GROUP BY patientid, hyper ,hypo


-----------------------------------------------------------------------------------------------------------------
-- 55. What is the variance from mean for all patients for the table IBI?
SELECT patientid,
       VARIANCE(mean_ibi_ms) AS variance_from_mean
FROM public.ibi
GROUP BY patientid
order by patientid
-----------------------------------------------------------------------------------------------------------------
-- 56. Create a view that combines all relevant patient demographics and lab markers into one. Call this view ‘Patient_Overview’.	
create view  patient_overview as 
 
 select a.patientid,a.gender,a.firstname,a.lastname,a.dob,b.glucose_value_mgdl, c.mean_eda,d.mean_hr, e.mean_ibi_ms
from public.demographics as A
INNER JOIN public.dexcom as B
on a.patientid =b.patientid

INNER JOIN public.eda as C
on b.patientid = c.patientid

INNER JOIN public.hr as D
on c.patientid = d.patientid

INNER JOIN public.ibi as E
on D.patientid = E.Patientid

select * from  patient_overview
order by patientid limit 50000

-- Rows limited to 50,000 to display
-----------------------------------------------------------------------------------------------------------------

-- 58. Assuming lunch is between 12pm and 2pm.
--Calculate the total number of calories consumed by each patient for lunch on "2020-02-24"

SELECT patientid, SUM(calorie)
FROM public.foodlog
Where EXTRACT(HOUR FROM "datetime") Between '12' and '14'
and cast (to_char(datetime,'YYYY-MM-DD')as date) = '2020-02-24'
GROUP BY patientid

-----------------------------------------------------------------------------------------------------------------

-- 59. What is the total length of time recorded for each patient(in hours) in the Dexcom table?

WITH DATETIME_MIN_MAX as
(
SELECT patientid, MIN(datestamp) MIN_datestamp, MAX(datestamp) MAX_datestamp  FROM public.dexcom
GROUP BY patientid
ORDER BY patientid 
),

HRS as
(
	SELECT patientid, (DATE_PART('day', MAX_datestamp - MIN_datestamp ) * 24 + DATE_PART('hour', MAX_datestamp - MIN_datestamp)
	+  DATE_PART('minute', MAX_datestamp - MIN_datestamp) /60) as Hrs_Diff
	FROM DATETIME_MIN_MAX 
	
	
)

SELECT *  FROM HRS

-----------------------------------------------------------------------------------------------------------------

-- 60. Display the first, last name, patient age and max glucose reading in one string for every patient
WITH CTE_DETAILS
as (
SELECT A.firstname, A.lastname, DATE_PART('YEAR', AGE(CURRENT_DATE, A.dob)) as AGE, MAX(glucose_value_mgdl) as max_glucose
FROM public.demographics A
INNER JOIN public.dexcom B
ON A.patientid = B.patientid
GROUP BY A.firstname, A.lastname, DATE_PART('YEAR', AGE(CURRENT_DATE, A.dob))
)
select CONCAT(firstname || '_' || lastname || '_' || AGE|| '_' || max_glucose ) concat_demo FROM CTE_DETAILS

-----------------------------------------------------------------------------------------------------------------

-- 61. What is the average age of all patients in the database?
select avg(DATE_PART('YEAR', AGE(CURRENT_DATE, dob))) as avg_age FROM public.demographics

-----------------------------------------------------------------------------------------------------------------

-- 62. Display All female patients with age less than 50
select DATE_PART('YEAR', AGE(CURRENT_DATE, dob)),GENDER FROM public.demographics
where gender like 'FEMALE' and DATE_PART('YEAR', AGE(CURRENT_DATE, dob)) < 50

-----------------------------------------------------------------------------------------------------------------

-- 63. Display count of Event ID, Event Subtype and the first letter of the event subtype. Display all events
SELECT 
   id,
  event_subtype  ,
    COUNT(*) AS EventCount,
    LEFT( event_subtype , 1) AS FirstLetter
FROM public.eventtype
GROUP BY ID, Event_Subtype
order by Id
-----------------------------------------------------------------------------------------------------------------

-- 64.	List the foods consumed by  the patient(s) whose eventype is "Estimated Glucose Value".

-- Selected Event_subtype as it has 'Estimated Glucose Value' whereas Event_type has' EGV' value

SELECT  A.event_subtype, D.logged_food FROM public.eventtype A
INNER JOIN public.dexcom B
ON A.id = B.eventid
INNER JOIN public.demographics C
ON B.patientid = C.patientid
INNER JOIN public.foodlog D
ON C.patientid = D.patientid
WHERE A.event_subtype LIKE 'Estimated Glucose Value'


-----------------------------------------------------------------------------------------------------------------
-- 65: Rank the patients' health based on HRV and Control of blood sugar (AKA min time spent out of range)
/*ranked best to worst - patient_id #6 is best, and patient_id #14 is worst */

WITH hrv_and_blood_sugar AS 
(
  SELECT
    i.patientid AS patient_id,
    SUM(CASE WHEN d.glucose_value_mgdl < 55 OR d.glucose_value_mgdl > 200 THEN EXTRACT(EPOCH FROM (d.next_timestamp - d.datestamp)) ELSE 0 END) AS time_out_of_range,
    SUM(CASE WHEN d.glucose_value_mgdl >= 55 AND d.glucose_value_mgdl <= 200 THEN EXTRACT(EPOCH FROM (d.next_timestamp - d.datestamp)) ELSE 0 END) AS time_in_range,
    AVG(i.rmssd_ms)*600 AS hrv
  FROM ibi AS i
  INNER JOIN (
    SELECT
      patientid,
      datestamp,
      LEAD(datestamp) OVER (PARTITION BY patientid ORDER BY datestamp) AS next_timestamp,
      glucose_value_mgdl
    FROM dexcom
  ) AS d ON i.patientid = d.patientid AND i.datestamp = d.datestamp
 GROUP BY i.patientid
)

SELECT
  patient_id,
  RANK() OVER (ORDER BY hrv DESC, time_out_of_range) AS health_rank
FROM hrv_and_blood_sugar;

-----------------------------------------------------------------------------------------------------------
-- 66: Create a trigger on the food log table that warns a person about any food logged that has more than 20 grams of sugar. 
-- The user should not be stopped from inserting the row. Only a warning is needed.*/

CREATE OR REPLACE FUNCTION sugar_content_check()
RETURNS TRIGGER AS 
$$
BEGIN 
IF NEW.sugar > 20 THEN
RAISE NOTICE 'High Sugar Content Warning';
RETURN NEW;
END IF;
END;
$$
LANGUAGE plpgsql

CREATE TRIGGER sugar_content_trigger
BEFORE INSERT ON foodlog
FOR EACH ROW
EXECUTE FUNCTION sugar_content_check()

/* check trigger works */

SELECT * FROM foodlog 

SELECT DISTINCT patientid FROM foodlog
ORDER BY patientid

INSERT INTO foodlog (logged_food, calorie, total_carb, dietary_fiber, sugar, protein, total_fat, patientid)
VALUES ('dummy_food', 500, 80, 2, 220, 30, 5, 1)

SELECT * FROM foodlog
WHERE logged_food = 'dummy_food'

/*end of trigger check*/

-----------------------------------------------------------------------------------------------------------
-- 67: Display all the patients with high heart rate and prediabetic.

SELECT h.patientid AS patient_id, d.hba1c, MAX(h.max_hr) AS max_heart_rate
FROM hr AS h INNER JOIN demographics AS d
ON h.patientid = d.patientid
WHERE h.max_hr > 100 AND d.hba1c BETWEEN 5.7 AND 6.4
GROUP BY h.patientid, d.hba1c
ORDER BY h.patientid

-----------------------------------------------------------------------------------------------------------
-- 68: Display patients’ information who have tachycardia HR and a glucose value greater than 200.

SELECT h.patientid AS patient_id, MAX(h.max_hr) AS max_heart_rate, MAX(dex.glucose_value_mgdl) AS max_glucose_value
FROM hr AS h
INNER JOIN dexcom AS dex ON h.patientid = dex.patientid
WHERE h.max_hr > 100 
AND dex.glucose_value_mgdl > 200
GROUP BY h.patientid
ORDER by h.patientid

-----------------------------------------------------------------------------------------------------------
-- 69: Calculate the number of hypoglycemic incident per patient per day where glucose drops under 55.

SELECT
  patientid AS patient_id,
  DATE_TRUNC('day', datestamp) AS day,
  COUNT(*) AS hypoglycemic_incidents
FROM dexcom
WHERE glucose_value_mgdl < 55
GROUP BY patient_id, day
ORDER BY patient_id, day

-----------------------------------------------------------------------------------------------------------
-- 70: List the day wise calories intake for each patient.

SELECT patientid AS patient_id, DATE(datetime) AS intake_date, SUM (calorie) AS total_calories
FROM foodlog
GROUP BY patientid, DATE(datetime)
ORDER BY patientid, DATE(datetime)

-----------------------------------------------------------------------------------------------------------
-- 71: Display the demographic details for the patient that had the maximum time below recommended blood glucose range

WITH GlucoseChanges AS 
  (
  SELECT patientid, datestamp, glucose_value_mgdl,
  LAG(glucose_value_mgdl) OVER (PARTITION BY patientid ORDER BY datestamp) AS prev_glucose_value_mgdl
  FROM dexcom
  ),
HypoglycemicPatients AS (
  SELECT gp.patientid,
  SUM(CASE WHEN gp.glucose_value_mgdl < 55 THEN EXTRACT(EPOCH FROM (gp.datestamp - gp.prev_datestamp)) ELSE 0 END) AS total_time_below_55
  FROM (
    SELECT patientid, datestamp, glucose_value_mgdl,
    LAG(datestamp) OVER (PARTITION BY patientid ORDER BY datestamp) AS prev_datestamp
    FROM dexcom
  ) AS gp
  GROUP BY gp.patientid
)

SELECT
  d.patientid, d.firstname, d.lastname,
  d.gender, d.dob, d.hba1c
FROM demographics AS d
INNER JOIN HypoglycemicPatients AS hgp ON d.patientid = hgp.patientid
ORDER BY hgp.total_time_below_55 DESC
LIMIT 1;

-----------------------------------------------------------------------------------------------------------
-- 72: How many patients have a minimum HR below the medically recommended level?

SELECT COUNT (DISTINCT patientid) AS no_of_patients 
FROM hr
WHERE min_hr < 60

-----------------------------------------------------------------------------------------------------------
-- 73: Create a trigger to raise notice and prevent the deletion of a record from ‘Patient_Overview’.

CREATE OR REPLACE FUNCTION prevent_patient_deletion()
RETURNS TRIGGER AS 
$$
BEGIN
RAISE NOTICE 'Deletion of Patient Records is Not Allowed';
RETURN OLD;
END;
$$
LANGUAGE plpgsql

CREATE TRIGGER prevent_patient_deletion_trigger
BEFORE DELETE ON demographics
FOR EACH ROW
EXECUTE FUNCTION prevent_patient_deletion()

/* check trigger works */

SELECT * FROM demographics
ORDER BY patientid

DELETE FROM demographics 
WHERE patientid = 1

/* end of trigger check */

-----------------------------------------------------------------------------------------------------------
-- 74: What is the average heart rate, age and gender of every patient in the dataset?

SELECT dem.patientid AS patient_id, dem.gender, 
EXTRACT (YEAR FROM (AGE (current_date, dem.dob))) AS age,
CAST (AVG(h.mean_hr) AS numeric (10,2)) AS average_heart_rate
FROM hr AS h 
INNER JOIN demographics AS dem ON h.patientid = dem.patientid
GROUP BY dem.patientid, dem.gender
ORDER BY dem.patientid

-----------------------------------------------------------------------------------------------------------
-- 75: What is the daily total calories consumed by every patient?


SELECT patientid AS patient_id, DATE(datetime) AS intake_date, SUM (calorie) AS calories_consumed
FROM foodlog
GROUP BY patientid, DATE(datetime)
ORDER BY patientid, DATE(datetime)

-----------------------------------------------------------------------------------------------------------
-- 76: Write a query to classify max EDA into 5 categories and display the number of patients in each category.

SELECT 
 CASE 
  WHEN max_eda >=0 AND max_eda <=14 THEN 'Very Low Stress'
  WHEN max_eda >14 AND max_eda <=28 THEN 'Low Stress'
  WHEN max_eda >28 AND max_eda <=42 THEN 'Moderate Stress'
  WHEN max_eda >42 AND max_eda <=56 THEN 'High Stress'
  WHEN max_eda >56 AND max_eda <=72 THEN 'Very High Stress'
 ELSE 'Unknown'
 END AS eda_category,
COUNT (patientid) AS patient_count
FROM eda 
GROUP BY eda_category
ORDER BY patient_count DESC

-----------------------------------------------------------------------------------------------------------
-- 77: List the daily max HR for patient with event type Exercise.

SELECT hr.datestamp AS date, hr.patientid AS patient_id, etype.event_type, MAX(hr.max_hr) AS max_heart_rate
FROM hr AS hr 
INNER JOIN demographics AS dem ON hr.patientid = dem.patientid
INNER JOIN dexcom AS dex ON dem.patientid = dex.patientid
INNER JOIN eventtype AS etype ON dex.eventid = etype.id
WHERE etype.event_type = 'Exercise'
GROUP BY hr.datestamp, hr.patientid, etype.event_type
ORDER BY hr.datestamp

-----------------------------------------------------------------------------------------------------------
-- 78: What is the standard deviation from mean for all patients for the table HR?

SELECT patientid AS patient_id, CAST(STDDEV(mean_hr) AS Numeric (10,2)) AS std_deviation_from_mean
FROM hr
GROUP BY patientid
ORDER BY patient_id;

-----------------------------------------------------------------------------------------------------------
-- 79: Give the demographic details of the patient with event type ID of 16.

SELECT DISTINCT dem.patientid AS patient_id, etype.id AS event_id,
dem.firstname AS first_name, dem.lastname AS last_name, dem.gender, 
EXTRACT (YEAR FROM (AGE (current_date, dem.dob))) AS age,
dem.hba1c
FROM demographics AS dem
INNER JOIN dexcom AS dex ON dem.patientid = dex.patientid
INNER JOIN eventtype AS etype ON dex.eventid = etype.id
WHERE etype.id = 16

-----------------------------------------------------------------------------------------------------------
-- 80: Display list of patients along with their gender having a tachycardia mean HR.

SELECT h.patientid AS patient_id, dem.gender, 
CAST(MAX (h.mean_hr) AS Numeric (10,2)) AS average_heart_rate
FROM hr AS h
INNER JOIN demographics AS dem ON h.patientid = dem.patientid
WHERE h.mean_hr > 100
GROUP BY h.patientid, dem.gender
ORDER BY h.patientid
