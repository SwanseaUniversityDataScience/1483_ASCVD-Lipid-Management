------------------------------------------
--
-- Script:			03_LIPID_TEST_CODES.sql
-- SAIL project:	1483 - Cardiovascular disease risk prediction and optimisation of risk factor management
--
-- About:			Lipid testing codes for primary care data
-- Author:			Daniel King
------------------------------------------
--
--Drop Table
CALL FNC.DROP_IF_EXISTS('SAILW1483V.PHEN_LIPID_READ');
COMMIT;
------------------------------------------ 
--
-- Create Table
CREATE TABLE SAILW1483V.PHEN_LIPID_READ
(
	READ_CODE		VARCHAR(5),
	DESC			VARCHAR(198),
	READ_TYPE		VARCHAR(7)
) 
;
COMMIT;
------------------------------------------
--
--Insert into Table
INSERT INTO SAILW1483V.PHEN_LIPID_READ
(
--
--HDL CHOLESTEROL
SELECT
	R.READ_CODE,
	CASE
		WHEN R.PREF_TERM_198 IS NULL AND R.PREF_TERM_60 IS NULL THEN R.PREF_TERM_30
		WHEN R.PREF_TERM_198 IS NULL THEN R.PREF_TERM_60
		ELSE PREF_TERM_198
	END AS DESC,
	'HDL' AS READ_TYPE
FROM
	SAILUKHDV.READ_CD_CV2_SCD R
WHERE
READ_CODE = '44P5.'
AND IS_LATEST = 1

UNION
--
--LDL CHOLESTEROL
SELECT
	R.READ_CODE,
	CASE
		WHEN R.PREF_TERM_198 IS NULL AND R.PREF_TERM_60 IS NULL THEN R.PREF_TERM_30
		WHEN R.PREF_TERM_198 IS NULL THEN R.PREF_TERM_60
		ELSE PREF_TERM_198
	END AS DESC,
	'LDL' AS READ_TYPE
FROM
	SAILUKHDV.READ_CD_CV2_SCD R
WHERE 
READ_CODE = '44P6.'
AND IS_LATEST = 1

UNION
--
--TOTAL CHOLESTEROL
SELECT
	R.READ_CODE,
	CASE
		WHEN R.PREF_TERM_198 IS NULL AND R.PREF_TERM_60 IS NULL THEN R.PREF_TERM_30
		WHEN R.PREF_TERM_198 IS NULL THEN R.PREF_TERM_60
		ELSE PREF_TERM_198
	END AS DESC,
	'TC' AS READ_TYPE
FROM
	SAILUKHDV.READ_CD_CV2_SCD R
WHERE
READ_CODE = '44P..'
AND IS_LATEST = 1
 
UNION
--
--TRIGLYCERIDE CHOLESTEROL
SELECT
	R.READ_CODE,
	CASE
		WHEN R.PREF_TERM_198 IS NULL AND R.PREF_TERM_60 IS NULL THEN R.PREF_TERM_30
		WHEN R.PREF_TERM_198 IS NULL THEN R.PREF_TERM_60
		ELSE PREF_TERM_198
	END AS DESC,
	'TG' AS READ_TYPE
FROM
	SAILUKHDV.READ_CD_CV2_SCD R
WHERE
READ_CODE = '44Q..'
AND IS_LATEST = 1
  
UNION
--
--TOTAL CHOLESTEROL TO HDL CHOLESTEROL RATIO
SELECT
	R.READ_CODE,
	CASE
		WHEN R.PREF_TERM_198 IS NULL AND R.PREF_TERM_60 IS NULL THEN R.PREF_TERM_30
		WHEN R.PREF_TERM_198 IS NULL THEN R.PREF_TERM_60
		ELSE PREF_TERM_198
	END AS DESC,
	'TC_HDL' AS READ_TYPE
FROM
	SAILUKHDV.READ_CD_CV2_SCD R
WHERE
READ_CODE = '44PF.'
AND IS_LATEST = 1
  
UNION
--
--NON-HDL CHOLESTEROL
SELECT
	R.READ_CODE,
	CASE
		WHEN R.PREF_TERM_198 IS NULL AND R.PREF_TERM_60 IS NULL THEN R.PREF_TERM_30
		WHEN R.PREF_TERM_198 IS NULL THEN R.PREF_TERM_60
		ELSE PREF_TERM_198
	END AS DESC,
	'NON_HDL' AS READ_TYPE
FROM
	SAILUKHDV.READ_CD_CV2_SCD R
WHERE
READ_CODE = '44PL.'
AND IS_LATEST = 1
) 
; 
COMMIT;
--
------------------------------------------
--
-- Select all results
SELECT 
	* 
FROM 
	SAILW1483V.PHEN_LIPID_READ;
--
-- Count all results
SELECT 
	COUNT(*)
FROM 
	SAILW1483V.PHEN_LIPID_READ;
------------------------------------------