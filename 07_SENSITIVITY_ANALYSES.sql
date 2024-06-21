--
--
------------------------------------------
--
-- Script:			07_SENSITIVITY_ANALYSES.sql
-- SAIL project:	1483 - Cardiovascular disease risk prediction and optimisation of risk factor management
--
-- About:			Conducting sensitivity analyses
-- Author:			Daniel King
------------------------------------------
--
-- Creating table of first ASCVD diagnoses in primary care to re-use in later scripts
------------------------------------------   
--
--Drop Table
CALL FNC.DROP_IF_EXISTS('SAILW1483V.PREP_GP_FIRST_EVENT');
COMMIT;
------------------------------------------
--
--Create Table
CREATE TABLE SAILW1483V.PREP_GP_FIRST_EVENT
(
	ALF_PE		BIGINT,
	FIRST_DATE	DATE,
	READ_TYPE	VARCHAR(6)
)
;
COMMIT;
------------------------------------------
--
--Insert into Table
INSERT INTO SAILW1483V.PREP_GP_FIRST_EVENT
--
-- Creating table of first ASCVD diagnoses in WLGP to re-use in later scripts
--
WITH RANKED AS 
(
SELECT 
	A.ALF_PE,
	A.EVENT_DT,
	C.READ_TYPE,
	ROW_NUMBER() OVER(PARTITION BY A.ALF_PE ORDER BY A.EVENT_DT ASC) AS TYPE_RANK
FROM SAILW1483V.EXTRACT_WLGP_GP_EVENT_CLEANSED A

JOIN SAILW1483V.PHEN_ASCVD_READ C
	ON A.EVENT_CD = C.READ_CODE

WHERE 
	A.EVENT_DT BETWEEN SAILW1483V.START_DATE AND SAILW1483V.END_DATE
)

SELECT
	RANKED.ALF_PE,
	RANKED.EVENT_DT AS FIRST_DATE,
	RANKED.READ_TYPE
FROM RANKED
WHERE RANKED.TYPE_RANK = 1
;
COMMIT;
--
------------------------------------------
--
-- Select all results
SELECT 
	* 
FROM 
	SAILW1483V.PREP_GP_FIRST_EVENT
ORDER BY ALF_PE
FETCH FIRST 100 ROWS ONLY;
--
-- Count all results
SELECT 
	COUNT(*)
FROM 
	SAILW1483V.PREP_GP_FIRST_EVENT
;
--
-- Count distinct alfs
SELECT 
	COUNT(DISTINCT ALF_PE)
FROM 
	SAILW1483V.PREP_GP_FIRST_EVENT
;
------------------------------------------
--
-- Creating table of first ASCVD diagnoses in secondary care to re-use in later scripts
------------------------------------------   
--
--Drop Table
CALL FNC.DROP_IF_EXISTS('SAILW1483V.PREP_PEDW_FIRST_EVENT');
COMMIT;
------------------------------------------
--
--Create Table
CREATE TABLE SAILW1483V.PREP_PEDW_FIRST_EVENT
(
	ALF_PE		BIGINT,
	FIRST_DATE	DATE,
	ICD_TYPE	VARCHAR(6)
)
;
COMMIT;
------------------------------------------
--
--Insert into Table
INSERT INTO SAILW1483V.PREP_PEDW_FIRST_EVENT
--
WITH RANKED AS
(
SELECT 
	SPELL.ALF_PE,
	SPELL.ADMIS_DT,		
	ICD.ICD_TYPE,
	SPELL.DISCH_MTHD_CD,
	ROW_NUMBER() OVER(PARTITION BY SPELL.ALF_PE ORDER BY SPELL.ADMIS_DT ASC) AS TYPE_RANK
FROM SAILW1483V.EXTRACT_PEDW_DIAG DIAG

LEFT JOIN SAILW1483V.EXTRACT_PEDW_EPISODE EPI
	ON EPI.PROV_UNIT_CD = DIAG.PROV_UNIT_CD
	AND EPI.SPELL_NUM_PE = DIAG.SPELL_NUM_PE
	AND EPI.EPI_NUM = DIAG.EPI_NUM

LEFT JOIN SAILW1483V.EXTRACT_PEDW_SPELL SPELL
	ON SPELL.PROV_UNIT_CD = EPI.PROV_UNIT_CD 
	AND SPELL.SPELL_NUM_PE = EPI.SPELL_NUM_PE

JOIN SAILW1483V.PHEN_ASCVD_ICD10 ICD
	ON DIAG.DIAG_CD_123  = ICD.DIAG_CD_123

WHERE SPELL.ADMIS_DT BETWEEN SAILW1483V.START_DATE AND SAILW1483V.END_DATE
)

SELECT
	RANKED.ALF_PE,
	RANKED.ADMIS_DT AS FIRST_DATE,
	RANKED.ICD_TYPE
FROM RANKED

WHERE RANKED.TYPE_RANK = 1
;
COMMIT;
--
------------------------------------------
--
-- Select all results
SELECT 
	* 
FROM 
	SAILW1483V.PREP_PEDW_FIRST_EVENT
ORDER BY ALF_PE
FETCH FIRST 100 ROWS ONLY;
--
-- Count all results
SELECT 
	COUNT(*)
FROM 
	SAILW1483V.PREP_PEDW_FIRST_EVENT
;
--
-- Count distinct alfs
SELECT 
	COUNT(DISTINCT ALF_PE)
FROM 
	SAILW1483V.PREP_PEDW_FIRST_EVENT
;
------------------------------------------
--
-- Finding first ASCVD diagnoses between both primary and secondary care to find first true diagnosis
------------------------------------------   
--
--Drop Table
CALL FNC.DROP_IF_EXISTS('SAILW1483V.PREP_FIRST_EVENT');
COMMIT;
------------------------------------------
--
--Create Table
CREATE TABLE SAILW1483V.PREP_FIRST_EVENT
(
	ALF_PE		BIGINT,
	FIRST_DATE	DATE,
	TYPE		VARCHAR(6),
	PEDW_FIRST	INTEGER,
	GP_FIRST	INTEGER
)
;
COMMIT;
------------------------------------------
--
--Insert into Table
INSERT INTO SAILW1483V.PREP_FIRST_EVENT
--
WITH UNION AS
(
SELECT
	ALF_PE,
	FIRST_DATE,
	READ_TYPE AS TYPE,
	0 AS PEDW_FIRST,
	1 AS GP_FIRST
FROM SAILW1483V.PREP_GP_FIRST_EVENT

UNION

SELECT
	ALF_PE,
	FIRST_DATE,
	ICD_TYPE AS TYPE,
	1 AS PEDW_FIRST,
	0 AS GP_FIRST
FROM SAILW1483V.PREP_PEDW_FIRST_EVENT
),

RANK AS
(
SELECT 
	*,
	ROW_NUMBER() OVER(PARTITION BY ALF_PE ORDER BY FIRST_DATE ASC) AS RANK
FROM UNION
)

SELECT 
	ALF_PE,
	FIRST_DATE,
	TYPE,
	PEDW_FIRST,
	GP_FIRST
FROM RANK

WHERE RANK = 1
;
COMMIT;
--
------------------------------------------
--
-- Select all results
SELECT 
	* 
FROM 
	SAILW1483V.PREP_FIRST_EVENT
ORDER BY ALF_PE
FETCH FIRST 100 ROWS ONLY;
--
-- Count all results
SELECT 
	COUNT(*)
FROM 
	SAILW1483V.PREP_FIRST_EVENT
;
--
-- Count distinct alfs
SELECT 
	COUNT(DISTINCT ALF_PE)
FROM 
	SAILW1483V.PREP_FIRST_EVENT
;
------------------------------------------
--
-- Sensitivity check #1 - Number of primary care diagnoses
------------------------------------------   
--
--Drop Table
CALL FNC.DROP_IF_EXISTS('SAILW1483V.SENS_GROUP_1');
COMMIT;
------------------------------------------
--
--Create Table
CREATE TABLE SAILW1483V.SENS_GROUP_1
(
	ALF_PE		BIGINT,
	FIRST_DATE	DATE,
	READ_TYPE	VARCHAR(6)
)
;
COMMIT;
------------------------------------------
--
--Insert into Table
INSERT INTO SAILW1483V.SENS_GROUP_1
--
SELECT
	*
FROM SAILW1483V.PREP_GP_FIRST_EVENT
;
COMMIT;
--
------------------------------------------
--
-- Select all results
SELECT 
	* 
FROM 
	SAILW1483V.SENS_GROUP_1
ORDER BY ALF_PE
FETCH FIRST 100 ROWS ONLY;
--
-- Count all results
SELECT 
	COUNT(*)
FROM 
	SAILW1483V.SENS_GROUP_1
;
--
-- Count distinct alfs
SELECT 
	COUNT(DISTINCT ALF_PE)
FROM 
	SAILW1483V.SENS_GROUP_1
;
------------------------------------------
--
-- Sensitivity check #2 - Number of secondary care diagnoses that died within 90 days
------------------------------------------   
--
--Drop Table
CALL FNC.DROP_IF_EXISTS('SAILW1483V.SENS_GROUP_2');
COMMIT;
------------------------------------------
--
--Create Table
CREATE TABLE SAILW1483V.SENS_GROUP_2
(
	ALF_PE		BIGINT,
	FIRST_DATE	DATE,
	ICD_TYPE	VARCHAR(6)
)
;
COMMIT;
------------------------------------------
--
--Insert into Table
INSERT INTO SAILW1483V.SENS_GROUP_2
--
WITH RANKED AS
(
SELECT 
	SPELL.ALF_PE,
	SPELL.ADMIS_DT,		
	ICD.ICD_TYPE,
	SPELL.DISCH_MTHD_CD,
	ROW_NUMBER() OVER(PARTITION BY SPELL.ALF_PE ORDER BY SPELL.ADMIS_DT ASC) AS TYPE_RANK
FROM SAILW1483V.EXTRACT_PEDW_DIAG DIAG

LEFT JOIN SAILW1483V.EXTRACT_PEDW_EPISODE EPI
	ON EPI.PROV_UNIT_CD = DIAG.PROV_UNIT_CD
	AND EPI.SPELL_NUM_PE = DIAG.SPELL_NUM_PE
	AND EPI.EPI_NUM = DIAG.EPI_NUM

LEFT JOIN SAILW1483V.EXTRACT_PEDW_SPELL SPELL
	ON SPELL.PROV_UNIT_CD = EPI.PROV_UNIT_CD 
	AND SPELL.SPELL_NUM_PE = EPI.SPELL_NUM_PE

JOIN SAILW1483V.PHEN_ASCVD_ICD10 ICD
	ON DIAG.DIAG_CD_123  = ICD.DIAG_CD_123

WHERE SPELL.ADMIS_DT BETWEEN SAILW1483V.START_DATE AND SAILW1483V.END_DATE
)

SELECT
	RANKED.ALF_PE,
	RANKED.ADMIS_DT AS FIRST_DATE,
	RANKED.ICD_TYPE
FROM RANKED

LEFT JOIN SAILW1483V.EXTRACT_ADDE_DEATHS ADDE
	ON RANKED.ALF_PE = ADDE.ALF_PE	

WHERE RANKED.TYPE_RANK = 1
	AND (RANKED.DISCH_MTHD_CD = 4 OR (ADDE.DEATH_DT < RANKED.ADMIS_DT+90))
;
COMMIT;
--
------------------------------------------
--
-- Select all results
SELECT 
	* 
FROM 
	SAILW1483V.SENS_GROUP_2
ORDER BY ALF_PE
FETCH FIRST 100 ROWS ONLY;
--
-- Count all results
SELECT 
	COUNT(*)
FROM 
	SAILW1483V.SENS_GROUP_2
;
--
-- Count distinct alfs
SELECT 
	COUNT(DISTINCT ALF_PE)
FROM 
	SAILW1483V.SENS_GROUP_2
;
------------------------------------------
--
-- Sensitivity check #3 - Number of secondary care diagnoses who had a record of diagnosis in primary care within 90 days
------------------------------------------   
--
--Drop Table
CALL FNC.DROP_IF_EXISTS('SAILW1483V.SENS_GROUP_3');
COMMIT;
------------------------------------------
--
--Create Table
CREATE TABLE SAILW1483V.SENS_GROUP_3
(
	ALF_PE		BIGINT,
	FIRST_DATE	DATE,
	ICD_TYPE	VARCHAR(6)
)
;
COMMIT;
------------------------------------------
--
--Insert into Table
INSERT INTO SAILW1483V.SENS_GROUP_3
--
SELECT
	PEDW.*
FROM SAILW1483V.PREP_PEDW_FIRST_EVENT PEDW

LEFT JOIN SAILW1483V.SENS_GROUP_1 GROUP_1
	ON PEDW.ALF_PE = GROUP_1.ALF_PE
	
WHERE GROUP_1.FIRST_DATE < PEDW.FIRST_DATE+90
;
COMMIT;
--
------------------------------------------
--
-- Select all results
SELECT 
	* 
FROM 
	SAILW1483V.SENS_GROUP_3
ORDER BY ALF_PE
FETCH FIRST 100 ROWS ONLY;
--
-- Count all results
SELECT 
	COUNT(*)
FROM 
	SAILW1483V.SENS_GROUP_3
;
--
-- Count distinct alfs
SELECT 
	COUNT(DISTINCT ALF_PE)
FROM 
	SAILW1483V.SENS_GROUP_3
;
------------------------------------------
--
-- Sensitivity check #4 - Number of secondary care diagnoses who had no record of diagnosis in primary care and did not die within 90 days
------------------------------------------   
--
--Drop Table
CALL FNC.DROP_IF_EXISTS('SAILW1483V.SENS_GROUP_4');
COMMIT;
------------------------------------------
--
--Create Table
CREATE TABLE SAILW1483V.SENS_GROUP_4
(
	ALF_PE		BIGINT,
	FIRST_DATE	DATE,
	ICD_TYPE	VARCHAR(6)
)
;
COMMIT;
------------------------------------------
--
--Insert into Table
INSERT INTO SAILW1483V.SENS_GROUP_4
--
SELECT
	PEDW.*
FROM SAILW1483V.PREP_PEDW_FIRST_EVENT PEDW

LEFT JOIN SAILW1483V.SENS_GROUP_1 GROUP_1
	ON PEDW.ALF_PE = GROUP_1.ALF_PE
	
LEFT JOIN SAILW1483V.EXTRACT_ADDE_DEATHS ADDE
	ON PEDW.ALF_PE = ADDE.ALF_PE	

WHERE ((GROUP_1.FIRST_DATE IS NULL OR GROUP_1.FIRST_DATE > PEDW.FIRST_DATE+90)
	OR (ADDE.DEATH_DT IS NULL OR ADDE.DEATH_DT >= PEDW.FIRST_DATE+90))
;
COMMIT;
--
------------------------------------------
--
-- Select all results
SELECT 
	* 
FROM 
	SAILW1483V.SENS_GROUP_4
ORDER BY ALF_PE
FETCH FIRST 100 ROWS ONLY;
--
-- Count all results
SELECT 
	COUNT(*)
FROM 
	SAILW1483V.SENS_GROUP_4
;
--
-- Count distinct alfs
SELECT 
	COUNT(DISTINCT ALF_PE)
FROM 
	SAILW1483V.SENS_GROUP_4
;
------------------------------------------
--
-- Sensitivity check #5 - Number of secondary care diagnoses who had no linked records with primary care
------------------------------------------   
--
--Drop Table
CALL FNC.DROP_IF_EXISTS('SAILW1483V.SENS_GROUP_5');
COMMIT;
------------------------------------------
--
--Create Table
CREATE TABLE SAILW1483V.SENS_GROUP_5
(
	ALF_PE		BIGINT,
	FIRST_DATE	DATE,
	ICD_TYPE	VARCHAR(6)
)
;
COMMIT;
------------------------------------------
--
--Insert into Table
INSERT INTO SAILW1483V.SENS_GROUP_5
--
-- Sensitivity checks for cohort - Group 5 (as outlined in protocol)
--
SELECT
	PEDW.*
FROM SAILW1483V.PREP_PEDW_FIRST_EVENT PEDW

LEFT JOIN SAILW1483V.EXTRACT_WLGP_GP_EVENT_CLEANSED GP
	ON PEDW.ALF_PE = GP.ALF_PE	

WHERE GP.ALF_PE IS NULL
;
COMMIT;
--
------------------------------------------
--
-- Select all results
SELECT 
	* 
FROM 
	SAILW1483V.SENS_GROUP_5
ORDER BY ALF_PE
FETCH FIRST 100 ROWS ONLY;
--
-- Count all results
SELECT 
	COUNT(*)
FROM 
	SAILW1483V.SENS_GROUP_5
;
--
-- Count distinct alfs
SELECT 
	COUNT(DISTINCT ALF_PE)
FROM 
	SAILW1483V.SENS_GROUP_5
;

