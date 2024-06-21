--
--
------------------------------------------
--
-- DISABLE AUTO-COMMIT BEFORE RUNNING THIS SCRIPT
--
-- ENABLE ONCE COMPLETE
--
------------------------------------------
--
-- Script:			05_ASCVD_DIAGNOSES.sql
-- SAIL project:	1483 - Cardiovascular disease risk prediction and optimisation of risk factor management
--
-- About:			Identifies cases of ASCVD from primary and secondary care data
-- Author:			Daniel King
------------------------------------------
--
-- Diagnoses from secondary care
------------------------------------------
--
-- Create alias' for PEDW tables
CREATE OR REPLACE ALIAS SAILW1483V.PEDW_DIAG_DATA
	FOR SAIL1483V.PEDW_DIAG_20230605;
--
CREATE OR REPLACE ALIAS SAILW1483V.PEDW_EPI_DATA
	FOR SAIL1483V.PEDW_EPISODE_20230605;
--
CREATE OR REPLACE ALIAS SAILW1483V.PEDW_SPELL_DATA
	FOR SAIL1483V.PEDW_SPELL_20230605;
------------------------------------------
--
-- Declare variables for start and end dates
CREATE OR REPLACE VARIABLE SAILW1483V.START_DATE DATE DEFAULT '2000-01-01';
CREATE OR REPLACE VARIABLE SAILW1483V.END_DATE DATE DEFAULT '2022-12-31';
------------------------------------------   
--
--Drop Table
CALL FNC.DROP_IF_EXISTS('SAILW1483V.PREP_ALF_PEDW');
COMMIT;
------------------------------------------
--
--Create Table
--
CREATE TABLE SAILW1483V.PREP_ALF_PEDW
(
	ALF_PE		BIGINT
)
;
COMMIT;
--
------------------------------------------
--
ALTER TABLE SAILW1483V.PREP_ALF_PEDW ACTIVATE NOT LOGGED INITIALLY;
--
INSERT INTO SAILW1483V.PREP_ALF_PEDW
(
--
-- Returning ALFs from PEDW with an ASCVD diagnosis between 2000-2022
--
SELECT
	DISTINCT SPELL.ALF_PE
FROM SAILW1483V.PEDW_DIAG_DATA DIAG

LEFT JOIN SAILW1483V.PEDW_EPI_DATA EPI
	ON EPI.PROV_UNIT_CD = DIAG.PROV_UNIT_CD
	AND EPI.SPELL_NUM_PE = DIAG.SPELL_NUM_PE
	AND EPI.EPI_NUM = DIAG.EPI_NUM

LEFT JOIN SAILW1483V.PEDW_SPELL_DATA SPELL
	ON SPELL.PROV_UNIT_CD = EPI.PROV_UNIT_CD 
	AND SPELL.SPELL_NUM_PE = EPI.SPELL_NUM_PE
	
JOIN SAILW1483V.PHEN_ASCVD_ICD10 ICD
	ON DIAG.DIAG_CD_123  = ICD.DIAG_CD_123 

WHERE 
	SPELL.ADMIS_DT BETWEEN SAILW1483V.START_DATE AND SAILW1483V.END_DATE
);
COMMIT;
--
------------------------------------------
--
-- Select all results
SELECT 
	* 
FROM 
	SAILW1483V.PREP_ALF_PEDW
ORDER BY ALF_PE
FETCH FIRST 100 ROWS ONLY;
--
-- Count all results
SELECT 
	COUNT(*)
FROM 
	SAILW1483V.PREP_ALF_PEDW
;
--
-- Count distinct alfs
SELECT 
	COUNT(DISTINCT ALF_PE)
FROM 
	SAILW1483V.PREP_ALF_PEDW
;
------------------------------------------
--
-- Diagnoses from primary care
------------------------------------------
--
-- Create alias for GP table
CREATE OR REPLACE ALIAS SAILW1483V.GP_DATA
	FOR SAIL1483V.WLGP_GP_EVENT_CLEANSED_20230401;
------------------------------------------   
--
--Drop Table
CALL FNC.DROP_IF_EXISTS('SAILW1483V.PREP_ALF_WLGP');
COMMIT;
------------------------------------------
--
--Create Table
CREATE TABLE SAILW1483V.PREP_ALF_WLGP
(
	ALF_PE		BIGINT
)
;
COMMIT;
------------------------------------------
--
--Insert into Table
--
ALTER TABLE SAILW1483V.PREP_ALF_WLGP ACTIVATE NOT LOGGED INITIALLY;
--
INSERT INTO SAILW1483V.PREP_ALF_WLGP
(
--
-- Returning ALFs from WLGP with an ASCVD diagnosis between 2000-2022
--
SELECT
	DISTINCT GP.ALF_PE
FROM 
	SAILW1483V.GP_DATA GP

JOIN SAILW1483V.PHEN_ASCVD_READ C
	ON GP.EVENT_CD = C.READ_CODE
	
WHERE 
	GP.EVENT_DT BETWEEN SAILW1483V.START_DATE AND SAILW1483V.END_DATE
);
COMMIT;
--
------------------------------------------
--
-- Select all results
SELECT 
	* 
FROM 
	SAILW1483V.PREP_ALF_WLGP
ORDER BY ALF_PE
FETCH FIRST 100 ROWS ONLY;
--
-- Count all results
SELECT 
	COUNT(*)
FROM 
	SAILW1483V.PREP_ALF_WLGP
;
--
-- Count distinct alfs
SELECT 
	COUNT(DISTINCT ALF_PE)
FROM 
	SAILW1483V.PREP_ALF_WLGP
;
------------------------------------------
--
-- Returning all available patients with primary care registration in Wales
------------------------------------------
--
-- Create alias for WDSD table
CREATE OR REPLACE ALIAS SAILW1483V.WDSD_DATA
	FOR SAIL1483V.WDSD_PER_RESIDENCE_GPREG_20230605;
------------------------------------------   
--
--Drop Table
CALL FNC.DROP_IF_EXISTS('SAILW1483V.PREP_ALF_WDSD');
COMMIT;
------------------------------------------
--
--Create Table
CREATE TABLE SAILW1483V.PREP_ALF_WDSD
(
	ALF_PE		BIGINT
)	
;
COMMIT;	
------------------------------------------
--
--Insert into TABLE
--
ALTER TABLE SAILW1483V.PREP_ALF_WDSD ACTIVATE NOT LOGGED INITIALLY;
--
INSERT INTO SAILW1483V.PREP_ALF_WDSD
(
--
-- Returning all ALFs from WDSD between 2000-2022
--
SELECT
	DISTINCT WDS.ALF_PE
FROM SAILW1483V.WDSD_DATA WDS
WHERE 
	WDS.ACTIVEFROM BETWEEN SAILW1483V.START_DATE AND SAILW1483V.END_DATE
	OR WDS.ACTIVETO BETWEEN SAILW1483V.START_DATE AND SAILW1483V.END_DATE
	OR (WDS.ACTIVETO IS NULL AND WDS.ACTIVEFROM <= SAILW1483V.START_DATE)
);
COMMIT;
--
------------------------------------------
--
-- Select all results
SELECT 
	* 
FROM 
	SAILW1483V.PREP_ALF_WDSD
ORDER BY ALF_PE
FETCH FIRST 100 ROWS ONLY;
--
-- Count all results
SELECT 
	COUNT(*)
FROM 
	SAILW1483V.PREP_ALF_WDSD
;
--
-- Count distinct alfs
SELECT 
	COUNT(DISTINCT ALF_PE)
FROM 
	SAILW1483V.PREP_ALF_WDSD
;
------------------------------------------
--
-- Limiting captured ASCVD diagnoses to those with GP registration
------------------------------------------
--
--Drop Table
CALL FNC.DROP_IF_EXISTS('SAILW1483V.PREP_ALF_TOP_CONSORT');
COMMIT;
------------------------------------------
--
--Create Table
CREATE TABLE SAILW1483V.PREP_ALF_TOP_CONSORT
(
	ALF_PE		BIGINT
)
;
COMMIT;
------------------------------------------
--
--Insert into Table
--
ALTER TABLE SAILW1483V.PREP_ALF_TOP_CONSORT ACTIVATE NOT LOGGED INITIALLY;
--
INSERT INTO SAILW1483V.PREP_ALF_TOP_CONSORT
--
-- Checking ALFs with ASCVD diagnoses from PEDW & WLGP have a record in WDSD
--
WITH GP_PEDW AS
(
SELECT
	*
FROM SAILW1483V.PREP_ALF_WLGP

UNION

SELECT
	*
FROM SAILW1483V.PREP_ALF_PEDW
)

SELECT 
	GP_PEDW.ALF_PE
FROM GP_PEDW

JOIN SAILW1483V.PREP_ALF_WDSD WDS
ON GP_PEDW.ALF_PE = WDS.ALF_PE
;
COMMIT;
--
------------------------------------------
--
-- Select all results
SELECT 
	* 
FROM 
	SAILW1483V.PREP_ALF_TOP_CONSORT
ORDER BY ALF_PE
FETCH FIRST 100 ROWS ONLY;
--
-- Count all results
SELECT 
	COUNT(*)
FROM 
	SAILW1483V.PREP_ALF_TOP_CONSORT
;
--
-- Count distinct alfs
SELECT 
	COUNT(DISTINCT ALF_PE)
FROM 
	SAILW1483V.PREP_ALF_TOP_CONSORT
;
------------------------------------------