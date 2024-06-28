 
WITH STRESS_Value
as
(
select e.patientid,e.MAX_eda,avg(rmssd_ms)*600 as HRV,
CASE 
WHEN ( avg(rmssd_ms)*600 <20 OR e.MAX_eda > 40  ) then 'High Stress' 
end as Stress_Value 
from eda e
join public.ibi i
on e.patientid=i.patientid 
	group by e.MAX_eda,e.patientid
)

SELECT * FROM STRESS_Value
WHERE Stress_Value IS NOT NULL
ORDER BY hrv DESC
