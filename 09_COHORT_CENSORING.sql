--
--
------------------------------------------
--
-- Script:			09_COHORT_CENSORING.sql
-- SAIL project:	1483 - Cardiovascular disease risk prediction and optimisation of risk factor management
--
-- About:			Determining censor dates for patients during the study period
-- Author:			Daniel King
------------------------------------------   
--
-- Censoring at point of migration out of Wales for > 90 days
------------------------------------------   
--
--Drop Table
CALL FNC.DROP_IF_EXISTS('SAILW1483V.PREP_CENSOR_MIGR');
COMMIT;
------------------------------------------
--
--Create Table
CREATE TABLE SAILW1483V.PREP_CENSOR_MIGR
(
	ALF_PE		BIGINT,
	START_DATE	DATE
)
;
COMMIT;
------------------------------------------
--
--Insert into Table
INSERT INTO SAILW1483V.PREP_CENSOR_MIGR
--
WITH A AS
(
SELECT
W.ALF_PE,
W.START_DATE,
W.END_DATE,
DAYS(W.END_DATE) - DAYS(W.START_DATE) AS RES_DURATION,
W.WELSH_ADDRESS
FROM SAILW1483V.EXTRACT_WDSD_SINGLE_CLEAN_GEO_WALES W

JOIN SAILW1483V.COHORT_ALFS F
ON W.ALF_PE = F.ALF_PE

WHERE W.START_DATE BETWEEN SAILW1483V.STUDY_START_DATE AND SAILW1483V.END_DATE
AND ((W.END_DATE BETWEEN SAILW1483V.STUDY_START_DATE AND SAILW1483V.END_DATE) OR W.END_DATE = '9999-01-01')
),

B AS
(
SELECT
*,
CASE 
	WHEN WELSH_ADDRESS = 0 AND RES_DURATION >=90 THEN 1 
	ELSE 0 
END AS EXCLUDED
FROM A
),

C AS
(
SELECT
ALF_PE,
START_DATE
FROM B

WHERE EXCLUDED = 1
)

SELECT
ALF_PE,
MIN(START_DATE) AS START_DATE
FROM C

GROUP BY ALF_PE
;
COMMIT;
--
------------------------------------------
--
-- Select all results
SELECT 
	* 
FROM 
	SAILW1483V.PREP_CENSOR_MIGR
ORDER BY ALF_PE
FETCH FIRST 100 ROWS ONLY;
--
-- Count all results
SELECT 
	COUNT(*)
FROM 
	SAILW1483V.PREP_CENSOR_MIGR
;
--
-- Count distinct alfs
SELECT 
	COUNT(DISTINCT ALF_PE)
FROM 
	SAILW1483V.PREP_CENSOR_MIGR
;
------------------------------------------
--
-- Censoring at point of loss of SAIL-providing GP registration for >90 days
------------------------------------------   
--
--Drop Table
CALL FNC.DROP_IF_EXISTS('SAILW1483V.PREP_CENSOR_GP_LOSS');
COMMIT;
------------------------------------------
--
--Create Table
CREATE TABLE SAILW1483V.PREP_CENSOR_GP_LOSS
(
	ALF_PE		BIGINT,
	START_DATE	DATE
)
;
COMMIT;
------------------------------------------
--
--Insert into Table
INSERT INTO SAILW1483V.PREP_CENSOR_GP_LOSS
--
WITH A AS
(
SELECT
G.ALF_PE,
G.START_DATE,
G.END_DATE,
DAYS(G.END_DATE) - DAYS(G.START_DATE) AS REG_DURATION,
G.GP_DATA_FLAG AS SAIL_PROV_PRAC
FROM SAILW1483V.EXTRACT_WLGP_CLEAN_GP_REG_BY_PRAC_INCLNONSAIL_MEDIAN G

JOIN SAILW1483V.COHORT_ALFS F
ON G.ALF_PE = F.ALF_PE

WHERE G.START_DATE BETWEEN SAILW1483V.STUDY_START_DATE AND SAILW1483V.END_DATE
AND ((G.END_DATE BETWEEN SAILW1483V.STUDY_START_DATE AND SAILW1483V.END_DATE) OR G.END_DATE = '9999-12-31')
),

B AS
(
SELECT
*,
CASE 
	WHEN SAIL_PROV_PRAC = 0 AND REG_DURATION >=90 THEN 1 
	ELSE 0 
END AS EXCLUDED
FROM A
),

C AS
(
SELECT
ALF_PE,
START_DATE
FROM B

WHERE EXCLUDED = 1
)

SELECT
ALF_PE,
MIN(START_DATE) AS START_DATE
FROM C

GROUP BY ALF_PE
;
COMMIT;
--
------------------------------------------
--
-- Select all results
SELECT 
	* 
FROM 
	SAILW1483V.PREP_CENSOR_GP_LOSS
ORDER BY ALF_PE
FETCH FIRST 100 ROWS ONLY;
--
-- Count all results
SELECT 
	COUNT(*)
FROM 
	SAILW1483V.PREP_CENSOR_GP_LOSS
;
--
-- Count distinct alfs
SELECT 
	COUNT(DISTINCT ALF_PE)
FROM 
	SAILW1483V.PREP_CENSOR_GP_LOSS
;
------------------------------------------
