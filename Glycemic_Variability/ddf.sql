CREATE OR REPLACE FUNCTION min_glu(pid bigint, givendate date)
RETURNS TABLE (patient_id bigint, min_glucose real)
LANGUAGE plpgsql
AS
$$
BEGIN
  -- Declare variables
  DECLARE 
    glumin real;
  -- Logic
  SELECT
    pid,
    min(glucose_value_mgdl) INTO patient_id, glumin
  FROM dexcom
  WHERE patientid = pid
    AND date(datestamp) = givendate
    AND glucose_value_mgdl IS NOT NULL
  GROUP BY pid;
  RETURN QUERY SELECT patient_id, glumin;
END;
$$;