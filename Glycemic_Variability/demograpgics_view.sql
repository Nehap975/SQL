Create VIEW Patient_Overview as

select 
A.patientid,a.gender, a.dob,a.firstname,a.lastname,b.glucose_value_mgdl, 
c.min_eda,c.mean_eda,c.max_eda ,d.min_hr,d.mean_hr,d.max_hr, E.mean_ibi_ms,E.meanibi_patient_ms,E.rmssd_ms

from  public.demographics A
INNER JOIN  public.dexcom as B
on a.patientid= b.patientid

INNER JOIN public.eda as C
on b.patientid = c.patientid

INNER JOIN public.hr as D
on c.patientid = d.Patientid

INNER JOIN public.ibi as E
on D.patientid = E.patientid


