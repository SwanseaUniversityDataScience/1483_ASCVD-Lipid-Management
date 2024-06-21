------------------------------------------
--
-- Script:			01_ASCVD_CODES.sql
-- SAIL project:	1483 - Cardiovascular disease risk prediction and optimisation of risk factor management
--
-- About:			ASCVD diagnostic codes for primary and secondary care data
-- Author:			Daniel King
------------------------------------------
--
-- ASCVD diagnosic codes for primary care
------------------------------------------
--
--Drop Table
CALL FNC.DROP_IF_EXISTS('SAILW1483V.PHEN_ASCVD_READ');
COMMIT;
------------------------------------------ 
--
-- Create Table
CREATE TABLE SAILW1483V.PHEN_ASCVD_READ
(
	READ_CODE		VARCHAR(5),
	DESC			VARCHAR(198),
	READ_TYPE		VARCHAR(6)
) 
;
COMMIT;
------------------------------------------
--
--Insert into Table
INSERT INTO SAILW1483V.PHEN_ASCVD_READ
--
WITH A AS
(
--STROKE  
SELECT
	R.READ_CODE,
	CASE
		WHEN R.PREF_TERM_198 IS NULL AND R.PREF_TERM_60 IS NULL THEN R.PREF_TERM_30
		WHEN R.PREF_TERM_198 IS NULL THEN R.PREF_TERM_60
		ELSE PREF_TERM_198
	END AS DESC,
	'STROKE' AS READ_TYPE
FROM
	SAILUKHDV.READ_CD_CV2_SCD R
WHERE
	READ_CODE IN
	('14A7.','G66..','G660,','G661.',
 	 'G662.','G663.','G664.','G665.',
 	 'G666.','G667.','G668.','G65z',
 	 'G66..','G65..','G65y.','G650.',
 	 'G651.','G6510','G652','G653.',
 	 'G654.','G656.','G657.','G65y.',	 
 	 'G72y0','G72y1','G72y2','G72y3',
	 'G72yC','G670.','G671.','G6710',
	 'G6711','G671z','G675.','G677.',
	 'G70y0','G65..','G650.','G651.',
	 'G6510','G653.','G654.','G656.',
	 'G657.','G65y.','G65z0','G6770',
	 'G6771','G6772','G6773','G6774',
	 'G6W..','G6X..','G65z1','G65zz'
 	 )
	OR READ_CODE LIKE 'G64%'
	OR READ_CODE LIKE 'G66%'
	OR READ_CODE LIKE 'G64%' 
	OR READ_CODE LIKE 'G63%'
	OR READ_CODE LIKE 'G65z.%'
	AND IS_LATEST = 1
UNION
--
--IHD
SELECT
	R.READ_CODE,
	CASE
		WHEN R.PREF_TERM_198 IS NULL AND R.PREF_TERM_60 IS NULL THEN R.PREF_TERM_30
		WHEN R.PREF_TERM_198 IS NULL THEN R.PREF_TERM_60
		ELSE PREF_TERM_198
	END AS DESC,
	'IHD' AS READ_TYPE
FROM
	SAILUKHDV.READ_CD_CV2_SCD R
WHERE 
	READ_CODE IN 
	('G3...','G3..','G30..','G300.',
	'G301.','G3010','G3011','G301z',
	'G302.','G303.','G304.','G305.',
	'G306.','G307.','G3070','G3071',
	'G308.','G30B.','G30x.','G30X0',
	'G30y.','G30y0','G30y1','G30y2',
	'G30yz','G30z.','G31..','G310.',
	'G311.','G3111','G3112','G3113',
	'G3114','G3115','G311z','G312.',
	'G31y.','G31y0','G31y1','G31y2',
	'G31y3','G31yz','G32..','G33..',
	'G330.','G3300','G330z','G332.',
	'G33z.','G33z0','G33z1','G704.',
	'G33z2','G33z3','G33z4','G33z5',
	'G33z7','G33zz','G34..','G3400',
	'G3401','G342.','G343.','G344.',
	'G34y0','G34y.','G34y0','G34y1',
	'G34yz','G34z.','G34z0','G35..',
	'G351.','G353.','G35X.','G36..',
	'G360.','G361.','G362.','G363.',
	'G364.','G365.','G362.','G363.',
	'G364.','G365.','G38..','G381.',
	'G382.','G383.','G384.','G38z.',
	'G3y..','G3z..','G309.','G30A.',
	'14AA.','14A5.','14AA.','14AH.',
	'14AJ.','14A3.','14A4.','14AJ.',
	'14AL.','14AT.','662N.','8B27.',
	'187..','G300.','G30B.') 
	OR READ_CODE  LIKE 'G307%'
	OR READ_CODE  LIKE 'G30X.%'
	OR READ_CODE  LIKE 'G30y%'
	OR READ_CODE  LIKE 'G31%'
	OR READ_CODE  LIKE 'G33%'
	OR READ_CODE  LIKE 'G35%'
	OR READ_CODE  LIKE 'G36%'
	OR READ_CODE  LIKE 'G38%'
	OR READ_CODE  LIKE '662K%'
	OR READ_CODE  LIKE 'G301%'
	OR READ_CODE  LIKE 'G30%'
	OR READ_CODE  LIKE 'G34%'
	AND IS_LATEST = 1
UNION
--
--PAD
SELECT
	R.READ_CODE,
	CASE
		WHEN R.PREF_TERM_198 IS NULL AND R.PREF_TERM_60 IS NULL THEN R.PREF_TERM_30
		WHEN R.PREF_TERM_198 IS NULL THEN R.PREF_TERM_60
		ELSE PREF_TERM_198
	END AS DESC,
	'PAD' AS READ_TYPE
FROM
	SAILUKHDV.READ_CD_CV2_SCD R
WHERE
	READ_CODE IN 
 	('G700.','G734.','G73..','G73z.',
 	 'G73z0','G73zz','G73y.','G76z1',
 	 'G76z2','G76z0','Gyu74','14NB.',
 	 '662U.','C109F','C10FF','C10EG',
 	 '7A223','7A27.','7A27C','7A27D',
 	 '7A27F','7A27C','7A27D','7A27E',
 	 '7A27F','7A28C','7A28G','7A281',
 	 '7A282','7A280','7A34C','7A34D',
 	 '7A34E','7A34F','7A34K','7A350',
 	 '7A351','7A352','7A353','7A35D',
 	 '7A35E','7A432','7A433','7A440',
 	 '7A443','7A444','7A4A4','7A4A5',
 	 '7A4B0','7A4B1','7A4B8','7A4B9',
 	 '7A540','7A544','7A545','7A548',
 	 '7A561','7A564','7A566','7A220',
 	 '7A222','7A223','7A22y','7A22z',
 	 '7A4B0','7A4B1','7A4B8','791C.',
	 '791C0','791C1','791C2','791C3',
	 '791C4','791Cy','791Cz','7A27E',
	 'G701.','G72yA','G72y8','G72y9',
	 'G7010','G702.','G702z','G703.',
	 'G70y.','G70z.','G71..','G710.',
	 'G711.','G712.','G713.','G7130',
	 'G714.','G7140','G7141','G7142',
	 'G7143','G715.','G7150','G716.',
	 'G7160','G718.','G719.','G71A.',
	 'G71z.','G72..','G720.','G7200',
	 'G7201','G7202','G720z','G721.',
	 'G7210','G7211','G722.','G7220',
	 'G7221','G7222','G722z','G723.',
	 'G7230','G7231','G7232','G7233',
	 'G7234','G7235','G7236','G723z',
	 'G724.','G725.','G726.','G727.',
	 'G728.','G729.','G72A.','G72B.',
	 'G72y.','G72y4','G72y5','G72y6',
	 'G72y7','G72yB','G72yz','G72z.',
	 'G652.')
 	 OR READ_CODE LIKE '7A10%' 
	 OR READ_CODE LIKE '7A11%'  
	 OR READ_CODE LIKE '7A12%' 
	 OR READ_CODE LIKE '7A13%'
	 OR READ_CODE LIKE '7A14%'  
	 OR READ_CODE LIKE '7A1B%'   
	 OR READ_CODE LIKE '7A1C%'  
	 OR READ_CODE LIKE '7A40%'
	 OR READ_CODE LIKE '7A41%'
	 OR READ_CODE LIKE '7A42%'
	 OR READ_CODE LIKE '7A45%'
	 OR READ_CODE LIKE '7A46%'
	 OR READ_CODE LIKE '7A47%'
	 OR READ_CODE LIKE '7A48%'
	 OR READ_CODE LIKE '7A49%'
	 OR READ_CODE LIKE '7A58%'
	 OR READ_CODE LIKE '7A59%'
	 OR READ_CODE LIKE '7A5A%'
	 OR READ_CODE LIKE '7A5B%'
	 AND IS_LATEST = 1
)

SELECT 
* 
FROM A

WHERE 
READ_CODE <> 'G331.'
AND 
READ_CODE NOT IN
(
SELECT 
READ_CODE 
FROM A 
WHERE DESC LIKE('%neurysm%') 
AND READ_TYPE IN('IHD','STROKE')
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
	SAILW1483V.PHEN_ASCVD_READ;
--
-- Count all results
SELECT 
	COUNT(*)
FROM 
	SAILW1483V.PHEN_ASCVD_READ;
------------------------------------------
--
-- ASCVD diagnosic codes for secondary care
------------------------------------------
--
--Drop Table
CALL FNC.DROP_IF_EXISTS('SAILW1483V.PHEN_ASCVD_ICD10');
COMMIT;
------------------------------------------ 
--
-- Create Table
CREATE TABLE SAILW1483V.PHEN_ASCVD_ICD10
(
	DIAG_CD_123		VARCHAR(3),
	DIAG_CD_4		CHARACTER(4),
	DIAG_DESC_4		VARCHAR(60),
	ICD_TYPE		VARCHAR(6)
)
;
COMMIT;
------------------------------------------
--
--Insert into Table
INSERT INTO SAILW1483V.PHEN_ASCVD_ICD10
--
WITH ICDJOINED AS
(
SELECT
	THREE.*,
	FOUR.DIAG_CD_4,
	FOUR.DIAG_DESC_4
FROM
	SAILREFRV.ICD10_DIAG_CD_123 THREE
	
INNER JOIN SAILREFRV.ICD10_DIAG_CD_4 FOUR 
ON THREE.DIAG_CD_123 = SUBSTR(FOUR.DIAG_CD_4,1,3) 
),

A AS
(
--
--STROKE
SELECT
	R.DIAG_CD_123,
	R.DIAG_CD_4,
	R.DIAG_DESC_4,
	'STROKE' AS ICD_TYPE
FROM
	ICDJOINED R
WHERE
	DIAG_CD_4 IN 
	('G450','G451','G452','G453',
	 'G458','G459','I693','I694',
	 'G452','G453','G450','G451')
	OR DIAG_CD_123 LIKE 'I63%' 
	OR DIAG_CD_123 LIKE 'I64%'   
	OR DIAG_CD_123 LIKE 'I65%'    
	OR DIAG_CD_123 LIKE 'I66%'    		
UNION
--
--IHD
SELECT
	R.DIAG_CD_123,
	R.DIAG_CD_4,
	R.DIAG_DESC_4,
	'IHD' AS ICD_TYPE
FROM
	ICDJOINED R
WHERE
	DIAG_CD_4 IN 
	('I201','I208','I209','I240',
	 'I248','I250','I251','I258',
	 'I200','I249','I241','I252',
	 'I253','I256','I259')
	OR DIAG_CD_123 LIKE 'I23%'
	OR DIAG_CD_123 LIKE 'I22%'	
	OR DIAG_CD_123 LIKE 'I21%'
UNION
--
--PAD
SELECT
	R.DIAG_CD_123,
	R.DIAG_CD_4,
	R.DIAG_DESC_4,
	'PAD' AS ICD_TYPE
FROM
	ICDJOINED R
WHERE 
	DIAG_CD_4 IN 
	('I739','I738','I700','I702',
	 'I710','I711','I712','I713',
	 'I714','I715','I716','I718',
	 'I719','I720','I722','I723',
	 'I724','I728','I729','I701',
	 'I708','I709')
)

SELECT 
* 
FROM A
WHERE DIAG_CD_4 <> 'I253'
;
COMMIT;
--
------------------------------------------
--
-- Select all results
SELECT 
	* 
FROM 
	SAILW1483V.PHEN_ASCVD_ICD10;
--
-- Count all results
SELECT 
	COUNT(*)
FROM 
	SAILW1483V.PHEN_ASCVD_ICD10;
------------------------------------------