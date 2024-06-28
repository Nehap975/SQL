-- Create a table to store the biomarker data
CREATE TABLE PatientBiomarkers (
    patient_id INT PRIMARY KEY,
    Min_Glucose_Value NUMERIC,
    Avg_Mean_HR NUMERIC,
    Max_EDA NUMERIC
);

-- Insert biomarkers into the PatientBiomarkers
INSERT INTO PatientBiomarkers (patient_id, Min_Glucose_Value, Avg_Mean_HR, Max_EDA)
SELECT
    p.patient_id,
    MIN(d.glucose_value_mgdl) AS Min_Glucose_Value,
    AVG(hr.mean_hr) AS Avg_Mean_HR,
    MAX(eda.max_eda) AS Max_EDA
FROM
    PatientBiomarkers p
inner JOIN
  dexcom as d  
  ON p.patient_id = d.patientid
JOIN
    hr as hr
	ON p.patient_id = hr.patientid
JOIN
     eda as eda
	 ON p.patient_id = eda.patientid
GROUP BY
    p.patient_id;
	
	select * from public.patientbiomarkers
	
	select * 