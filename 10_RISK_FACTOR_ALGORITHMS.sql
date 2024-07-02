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
-- Script:			10_RISK_FACTOR_ALGORITHMS.sql
-- SAIL project:	1483 - Cardiovascular disease risk prediction and optimisation of risk factor management
--
-- About:			Running algorithms for identifying primary care records for smoking history, and primary and secondary care records for BMI
-- Author:			Daniel King
------------------------------------------
--
-- BMI Algorithm
------------------------------------------
--
-- Code by: m.j.childs@swansea.ac.uk
-- Modified from code by: s.j.aldridge@swansea.ac.uk
--
-- Extracting all BMI related entries between 2000-2021.
-----------------------------------------------------------------------------------------------------------------
-- CREATE AN ALIAS FOR THE MOST RECENT VERSIONS OF THE WLGP AND PEDW EVENT TABLES AS BELOW:
CREATE OR REPLACE ALIAS SAILW1483V.BMI_ALG_GP
FOR SAILW1483V.EXTRACT_WLGP_GP_EVENT_CLEANSED ;
--
CREATE OR REPLACE ALIAS SAILW1483V.BMI_ALG_PEDW_SPELL
FOR SAILW1483V.EXTRACT_PEDW_SPELL ;
--
CREATE OR REPLACE ALIAS SAILW1483V.BMI_ALG_PEDW_DIAG
FOR SAILW1483V.EXTRACT_PEDW_DIAG ;
--
CREATE OR REPLACE ALIAS SAILW1483V.BMI_ALG_WDSD
FOR SAILW1483V.EXTRACT_WDSD_PER_RESIDENCE_GPREG ;
--
-----------------------------------------------------------------------------------------------------------------
-- CREATE VARIABLES FOR THE EARLIEST AND LATEST DATES YOU WANT THE BMI VALUES FOR (REPLACE DATES AS NECESSARY)
CREATE OR REPLACE VARIABLE SAILW1483V.BMI_DATE_FROM  DATE;
SET SAILW1483V.BMI_DATE_FROM = '2000-01-01' ; -- 'YYYY-MM-DD'

CREATE OR REPLACE VARIABLE SAILW1483V.BMI_DATE_TO  DATE;
SET SAILW1483V.BMI_DATE_TO = '2022-12-31' ; -- 'YYYY-MM-DD'

--5. OPTIONAL -- ASSIGN YOUR ACCEPTABLE RANGES FOR BMI AT:
-- SAME DAY VARIATION - DEFAULT = 0.05
CREATE OR REPLACE VARIABLE SAILW1483V.BMI_SAME_DAY DOUBLE DEFAULT 0.05;

-- RATE OF CHANGE - DEFAULT = 0.003
CREATE OR REPLACE VARIABLE SAILW1483V.BMI_RATE DOUBLE DEFAULT 0.003; 

-----------------------------------------------------------------------------------------------------------------
-- OPTIONAL --- CREATE LOOKUP TABLE 

CALL FNC.DROP_IF_EXISTS ('SAILW1483V.BMI_LOOKUP');

CREATE TABLE SAILW1483V.BMI_LOOKUP
(
        BMI_CODE        CHAR(5),
        DESCRIPTION		VARCHAR(300),
        COMPLEXITY		VARCHAR(51),
        CATEGORY		VARCHAR(20)
);

--GRANTING ACCESS TO TEAM MATES
GRANT ALL ON TABLE SAILW1483V.BMI_LOOKUP TO ROLE NRDASAIL_SAIL_1483_ANALYST;

--WORTH DOING FOR LARGE CHUNKS OF DATA
ALTER TABLE SAILW1483V.BMI_LOOKUP ACTIVATE NOT LOGGED INITIALLY;

-- THIS LOOKUP TABLE CONTAINS THE GP LOOK UP CODES RELEVENT TO HEIGHT, WEIGHT AND BMI, THEY ARE CATEGORISED AS SUCH.
INSERT INTO SAILW1483V.BMI_LOOKUP
VALUES
('2293.', 'O/E -height within 10% average', 'where event_val between x and y (depending on unit)', 'height'),
('229..', 'O/E - height', 'where event_val between x and y (depending on unit)', 'height'),
('229Z.', 'O/E - height NOS', 'where event_val between x and y (depending on unit)', 'height'),
('2292.', 'O/E - height 10-20% < average', 'height', 'height'),
('2294.', 'O/E - height 10-20% over average', 'height', 'height'),
('2295.', 'O/E - height > 20% over average', 'height', 'height'),
('2291.', 'O/E - height > 20% below average', 'height', 'height'),
('22A..', 'O/E - weight', 'where event_val between 32 and 250', 'weight'),
('22A1.', 'O/E - weight > 20% below ideal', 'where event_val between 32 and 250', 'weight'),
('22A2.', 'O/E - weight 10-20% below ideal', 'where event_val between 32 and 250', 'weight'),
('22A3.', 'O/E - weight within 10% ideal', 'where event_val between 32 and 250', 'weight'),
('22A4.', 'O/E - weight 10-20% over ideal', 'where event_val between 32 and 250', 'weight'),
('22A5.', 'O/E - weight > 20% over ideal', 'where event_val between 32 and 250', 'weight'),
('22A6.', 'O/E - Underweight', 'where event_val between 32 and 250', 'weight'),
('22AA.', 'Overweight', 'where event_val between 32 and 250', 'weight'),
('22AZ.', 'O/E - weight NOS', 'where event_val between 32 and 250', 'weight'),
('1266.', 'FH: Obesity', 'Obese', 'obese'),
('1444.', 'H/O: obesity', 'Obese', 'obese'),
('22K3.', 'Body Mass Index low K/M2', 'Underweight', 'underweight'),
('22K..', 'Body Mass Index', 'BMI', 'BMI'),
('22K1.', 'Body Mass Index normal K/M2', 'Normal weight', 'normal weight'),
('22K2.', 'Body Mass Index high K/M2', 'Overweight/Obese', 'obese'),
('22K4.', 'Body mass index index 25-29 - overweight', 'Overweight', 'overweight'),
('22K5.', 'Body mass index 30+ - obesity', 'Obese', 'obese'),
('22K6.', 'Body mass index less than 20', 'Underweight', 'underweight'),
('22K7.', 'Body mass index 40+ - severely obese', 'Obese', 'obese'),
('22K8.', 'Body mass index 20-24 - normal', 'Normal weight', 'normal weight'),
('22K9.', 'Body mass index centile', 'BMI', 'BMI'),
('22KC.', 'Obese class I (body mass index 30.0 - 34.9)', 'Obese', 'obese'),
('22KC.', 'Obese class I (BMI 30.0-34.9)', 'Obese', 'obese'),
('22KD.', 'Obese class II (body mass index 35.0 - 39.9)', 'Obese', 'obese'),
('22KD.', 'Obese class II (BMI 35.0-39.9)', 'Obese', 'obese'),
('22KE.', 'Obese class III (BMI equal to or greater than 40.0)', 'Obese', 'obese'),
('22KE.', 'Obese cls III (BMI eq/gr 40.0)', 'Obese', 'obese'),
('66C4.', 'Has seen dietician - obesity', 'Obese', 'obese'),
('66C6.', 'Treatment of obesity started', 'Obese', 'obese'),
('66CE.', 'Reason for obesity therapy - occupational', 'Obese', 'obese'),
('8CV7.', 'Anti-obesity drug therapy commenced', 'Obese', 'obese'),
('8T11.', 'Rfrrl multidisip obesity clin', 'Obese', 'obese'),
('C38..', 'Obesity/oth hyperalimentation', 'Obese', 'obese'),
('C380.', 'Obesity', 'Obese', 'obese'),
('C3800', 'Obesity due to excess calories', 'Obese', 'obese'),
('C3801', 'Drug-induced obesity', 'Obese', 'obese'),
('C3802', 'Extrem obesity+alveol hypovent', 'Obese', 'obese'),
('C3803', 'Morbid obesity', 'Obese', 'obese'),
('C3804', 'Central obesity', 'Obese', 'obese'),
('C3805', 'Generalised obesity', 'Obese', 'obese'),
('C3806', 'Adult-onset obesity', 'Obese', 'obese'),
('C3807', 'Lifelong obesity', 'Obese', 'obese'),
('C38z.', 'Obesity/oth hyperalimentat NOS', 'Obese', 'obese'),
('C38z0', 'Simple obesity NOS', 'Obese', 'obese'),
('Cyu7.', '[X]Obesity+oth hyperalimentatn', 'Obese', 'obese'),
('22K4.', 'BMI 25-29 - overweight', 'Overweight', 'overweight'),
('22A1.', 'O/E - weight > 20% below ideal', 'Underweight', 'underweight'),
('22A2.', 'O/E -weight 10-20% below ideal', 'Underweight', 'underweight'),
('22A3.', 'O/E - weight within 10% ideal', 'Normal weight', 'normal weight'),
('22A4.', 'O/E - weight 10-20% over ideal', 'Overweight', 'overweight'),
('22A5.', 'O/E - weight > 20% over ideal', 'Overweight', 'overweight'),
('22A6.', 'O/E - Underweight', 'Underweight', 'underweight'),
('22AA.', 'Overweight', 'Overweight', 'overweight'),
('R0348', '[D] Underweight', 'Underweight', 'underweight'),
('66C1.','Itinital obesity assessment','Obese','obese'),
('66C2.','Follow-up obesity assessment','Obese','obese'),
('66C5.','Treatment of obesity changed','Obese','obese'),
('66CX.','Obesity multidisciplinary case review','Obese','obese'),
('66CZ.','Obesity monitoring NOS','Obese','obese'),
('9hN..','Exception reporting: obesity quality indicators','Obese','obese'),
('9OK..','Obesity monitoring admin.','Obese','obese'),
('9OK1.','Attends obesity monitoring','Obese','obese'),
('9OK3.','Obesity monitoring default','Obese','obese'),
('9OK2.','Refuses obesity monitoring','Obese','obese'),
('9OK4.','Obesity monitoring 1st letter','Obese','obese'),
('9OK5.','Obesity monitoring 2nd letter','Obese','obese'),
('9OK6.','Obesity monitoring 3rd letter','Obese','obese'),
('9OK7.','Obesity monitoring verbal inv.','Obese','obese'),
('9OK8.','Obesity monitor phone invite','Obese','obese'),
('9OKA.','Obesity monitoring check done','Obese','obese'),
('9OKZ.','Obesity monitoring admin.NOS','Obese','obese'),
('C38y0','Pickwickian syndrome','Obese','obese')
;

-- END OF READ CODES

-----------------------------------------------------------------------------------------------------------------
-- DROP FINAL BMI TABLE IF IT EXISTS USING THE CODE BELOW
-----------------------------------------------------------------------------------------------------------------
CALL FNC.DROP_IF_EXISTS ('SAILW1483V.BMI_UNCLEAN_ADULTS');
CALL FNC.DROP_IF_EXISTS ('SAILW1483V.BMI_CLEAN_ADULTS');

------------------------------------------------------------------------------------------------------------------
------------------------------- ALGORITHM RUNS FROM HERE ---------------------------------------------------------
------------------------------------------------------------------------------------------------------------------
--1. CREATING SUBTABLES OF BMI CATEGORY
-- THERE WILL BE A TABLE FOR UNDERWEIGHT, NORMAL WEIGHT, OVERWEIGHT, AND OBESE.
-- THESE WILL THEN BE PUT TOGETHER USING UNION ALL TO MAKE THE BMI_CAT TABLE.
------------------------------------------------------------------------------------------------------------------
--1A. TABLE FOR NORMAL UNDERWEIGHT
CALL FNC.DROP_IF_EXISTS ('SAILW1483V.UNDERWEIGHT');

CREATE TABLE SAILW1483V.UNDERWEIGHT
(
		ALF_PE        	BIGINT,
		BMI_DT     		DATE,
		BMI_CAT			VARCHAR(13),
		BMI_C			CHAR(1),
		BMI_VAL			DECIMAL(5),
		SOURCE_DB		VARCHAR(12)
)
DISTRIBUTE BY HASH(ALF_PE);
COMMIT;

INSERT INTO SAILW1483V.UNDERWEIGHT
SELECT -- EXTRACTING THOSE CATEGORISED AS UNDERWEIGHT
	DISTINCT (ALF_PE), 
	event_dt AS BMI_dt, 
	'Underweight' AS BMI_cat, 
	'1' AS BMI_c,
	CASE 
		WHEN event_val >= 12 	AND event_val < 18.50 	THEN event_val 
		WHEN event_val IS NULL 							THEN NULL
		ELSE 9999
		END AS BMI_val,
	'WLGP' AS source_db
FROM 
	SAILW1483V.BMI_ALG_GP a
INNER JOIN 
	SAILW1483V.BMI_lookup b
ON a.event_cd = b.BMI_code AND b.category = 'underweight'
WHERE 
	a.event_dt BETWEEN SAILW1483V.BMI_DATE_FROM AND SAILW1483V.BMI_DATE_TO
AND	alf_sts_cd IN ('1', '4', '39')
AND ALF_PE IN (SELECT ALF_PE FROM SAILW1483V.COHORT_ALFS)
;

COMMIT;


--1b. table for normal weight
CALL FNC.DROP_IF_EXISTS ('SAILW1483V.NORMALWEIGHT');

CREATE TABLE SAILW1483V.NORMALWEIGHT
(
		ALF_PE        	BIGINT,
		BMI_dt     		DATE,
		BMI_cat			VARCHAR(13),
		BMI_c			CHAR(1),
		BMI_val			DECIMAL(5),
		source_db		VARCHAR(12)
)
DISTRIBUTE BY HASH(ALF_PE);
COMMIT;

INSERT INTO SAILW1483V.NORMALWEIGHT
SELECT
	DISTINCT (ALF_PE), 
	event_dt AS BMI_dt, 
	'Normal weight' AS BMI_cat, 
	'2' AS BMI_c,
	CASE 
		WHEN event_val >= 18.5 AND event_val < 25 		THEN event_val 
		WHEN event_val IS NULL 							THEN NULL
		ELSE 9999
		END AS BMI_val,
	'WLGP' AS source_db
FROM 
	SAILW1483V.BMI_ALG_GP a
RIGHT JOIN 
	SAILW1483V.BMI_lookup b
ON a.event_cd = b.BMI_code AND b.category = 'normal weight'
WHERE 
	a.event_dt BETWEEN SAILW1483V.BMI_DATE_FROM AND SAILW1483V.BMI_DATE_TO
	AND	alf_sts_cd IN ('1', '4', '39')
	AND ALF_PE IN (SELECT ALF_PE FROM SAILW1483V.COHORT_ALFS)
;


--1c. creating table for overweight
CALL FNC.DROP_IF_EXISTS ('SAILW1483V.OVERWEIGHT');

CREATE TABLE SAILW1483V.OVERWEIGHT
(
		ALF_PE        	BIGINT,
		BMI_dt     		DATE,
		BMI_cat			VARCHAR(13),
		BMI_c			CHAR(1),
		BMI_val			DECIMAL(5),
		source_db		VARCHAR(12)
)
DISTRIBUTE BY HASH(ALF_PE);
COMMIT;

INSERT INTO SAILW1483V.OVERWEIGHT
SELECT 
	DISTINCT (ALF_PE), 
	event_dt AS BMI_dt, 
	'Overweight' AS BMI_cat, 
	'3' AS BMI_c,
	CASE 
		WHEN event_val >= 25 AND event_val < 30 		THEN event_val 
		WHEN event_val IS NULL 							THEN NULL
		ELSE 9999
		END AS BMI_val,
	'WLGP' AS source_db
FROM 
	SAILW1483V.BMI_ALG_GP a
RIGHT JOIN 
	SAILW1483V.BMI_lookup b
ON a.event_cd = b.BMI_code AND b.category = 'overweight'
WHERE 
	a.event_dt BETWEEN SAILW1483V.BMI_DATE_FROM AND SAILW1483V.BMI_DATE_TO
AND	alf_sts_cd IN ('1', '4', '39')
AND ALF_PE IN (SELECT ALF_PE FROM SAILW1483V.COHORT_ALFS)
;

COMMIT;

--1d. creating table for obese
CALL FNC.DROP_IF_EXISTS ('SAILW1483V.OBESE');

CREATE TABLE SAILW1483V.OBESE
(
		ALF_PE        	BIGINT,
		BMI_dt     		DATE,
		BMI_cat			VARCHAR(13),
		BMI_c			CHAR(1),
		BMI_val			DECIMAL(5),
		source_db		VARCHAR(12)
)
DISTRIBUTE BY HASH(ALF_PE);
COMMIT;

ALTER TABLE SAILW1483V.OBESE activate not logged INITIALLY;

INSERT INTO SAILW1483V.OBESE
SELECT 
	DISTINCT (ALF_PE), 
	event_dt AS BMI_dt, 
	'Obese' AS BMI_cat, 
	'4' AS BMI_c,
	CASE 
		WHEN event_val > 30 AND event_val < 100 		THEN event_val 
		WHEN event_val IS NULL 							THEN NULL
		ELSE 9999
		END AS BMI_val,
	'WLGP' AS source_db
FROM SAILW1483V.BMI_ALG_GP a
RIGHT JOIN 
	SAILW1483V.BMI_lookup b
ON a.event_cd = b.BMI_code AND b.category = 'obese'
WHERE 
	a.event_dt BETWEEN SAILW1483V.BMI_DATE_FROM AND SAILW1483V.BMI_DATE_TO
AND	alf_sts_cd IN ('1', '4', '39')
AND ALF_PE IN (SELECT ALF_PE FROM SAILW1483V.COHORT_ALFS)
;


--1e. Pulling ALL entries from WLGP that have BMI category allocated between the time-frame specified.
CALL FNC.DROP_IF_EXISTS ('SAILW1483V.BMI_CAT');

CREATE TABLE SAILW1483V.BMI_CAT
(
		ALF_PE        	BIGINT,
		BMI_dt     		DATE,
		BMI_cat			VARCHAR(13),
		BMI_c			CHAR(1),
		BMI_val			DECIMAL(5),
		source_db		VARCHAR(12)
)
DISTRIBUTE BY HASH(ALF_PE);
COMMIT;

CALL SYSPROC.ADMIN_CMD('runstats on table SAILW1483V.BMI_CAT with distribution and detailed indexes all');  
COMMIT;	

ALTER TABLE SAILW1483V.BMI_CAT activate not logged INITIALLY;

INSERT INTO SAILW1483V.BMI_CAT
SELECT DISTINCT -- now we join all these tables together
	*
FROM 
	SAILW1483V.UNDERWEIGHT
UNION ALL
SELECT DISTINCT
	*
FROM 
	SAILW1483V.NORMALWEIGHT
UNION ALL
SELECT DISTINCT
	*
FROM SAILW1483V.OVERWEIGHT
UNION ALL
SELECT DISTINCT
	*
FROM SAILW1483V.OBESE

COMMIT;


-----------------------------------------------------------------------------------------------------------------
---2. Extracting BMI VALUES
-----------------------------------------------------------------------------------------------------------------
-- Here we extract ALL entries with BMI values from the time-frame specified.

CALL FNC.DROP_IF_EXISTS ('SAILW1483V.BMI_VAL');

CREATE TABLE SAILW1483V.BMI_VAL
(
		ALF_PE        	BIGINT,
		BMI_dt     		DATE,
		BMI_val			DECIMAL(5),
		BMI_cat			CHAR(20),
		BMI_c			CHAR(1),
		source_db		VARCHAR(12)
)
DISTRIBUTE BY HASH(ALF_PE);
COMMIT;

CALL SYSPROC.ADMIN_CMD('runstats on table SAILW1483V.BMI_VAL with distribution and detailed indexes all');  
COMMIT;	


INSERT INTO SAILW1483V.BMI_VAL
SELECT DISTINCT 
    ALF_PE, 
	BMI_dt,
	BMI_val,
CASE  
	WHEN BMI_val < 18.5 					THEN 'Underweight'
	WHEN BMI_val >=18.5   AND BMI_val < 25 	THEN 'Normal weight'
	WHEN BMI_val >= 25.0  AND BMI_val < 30 	THEN 'Overweight'
	WHEN BMI_val >= 30.0 					THEN 'Obese'
	ELSE NULL 
	END AS BMI_cat, -- all the appropriate values will be assigned these categories. 
CASE  
	WHEN BMI_val < 18.5 					THEN '1'
	WHEN BMI_val >=18.5   AND BMI_val < 25 	THEN '2'
	WHEN BMI_val >= 25.0  AND BMI_val < 30 	THEN '3'
	WHEN BMI_val >= 30.0 					THEN '4'
	ELSE NULL 
	END AS BMI_c, -- all the appropriate values will be assigned these numerical categories. 
	'WLGP' AS source_db
FROM 
	(
	SELECT DISTINCT 
        ALF_PE, 
		event_dt    AS BMI_dt, 
		event_val   AS BMI_val
	FROM 
		SAILW1483V.BMI_ALG_GP a -- all of the WLGP data which has event_cd
	RIGHT JOIN 
		SAILW1483V.BMI_LOOKUP b -- that matches up the BMI_code in this table
	ON a.event_cd = b.BMI_code
	WHERE 
		category = 'BMI' -- all entries relating to 'BMI' which have:
	AND alf_sts_cd 	IN ('1', '4', '39') -- all the acceptable sts_cd
	AND event_val 	BETWEEN 12 AND 100 -- all the acceptable BMI values
	AND event_dt	BETWEEN SAILW1483V.BMI_DATE_FROM AND SAILW1483V.BMI_DATE_TO -- we want to capture the study date.
	AND ALF_PE IN (SELECT ALF_PE FROM SAILW1483V.COHORT_ALFS)
	)
; 

COMMIT;

-----------------------------------------------------------------------------------------------------------------
--3. extracting height and weight values from WLGP database.
-----------------------------------------------------------------------------------------------------------------
-- For each table, we want ALF_PE, height_dt/bmi_dt, height/weight, and source_db.
	-- We only want valid readings, so not include NULL values.
	-- We want to limit the extraction to our start and end dates.

--3.1.a. Extracting height from WLGP
CALL FNC.DROP_IF_EXISTS ('SAILW1483V.BMI_HEIGHT_WLGP');

CREATE TABLE SAILW1483V.BMI_HEIGHT_WLGP
(
		ALF_PE        	BIGINT,
		height_dt      	DATE,
		height     		DECIMAL(31,8),
		source_db		CHAR(4)
)
DISTRIBUTE BY HASH(ALF_PE);

CALL SYSPROC.ADMIN_CMD('runstats on table SAILW1483V.BMI_HEIGHT_WLGP with distribution and detailed indexes all');
COMMIT; 

ALTER TABLE SAILW1483V.BMI_HEIGHT_WLGP activate not logged INITIALLY;

INSERT INTO SAILW1483V.BMI_HEIGHT_WLGP
SELECT DISTINCT 
	ALF_PE,  
	event_dt AS height_dt, 
	event_val AS height,
	'WLGP' AS source_db
FROM 
	SAILW1483V.BMI_ALG_GP a
RIGHT JOIN
	SAILW1483V.BMI_LOOKUP b
ON a.event_cd = b.BMI_code AND b.category = 'height'
WHERE 
	(event_dt BETWEEN SAILW1483V.BMI_DATE_FROM AND SAILW1483V.BMI_DATE_TO)
	AND alf_sts_cd IN ('1', '4', '39')
	AND event_val IS NOT NULL
	AND ALF_PE IN (SELECT ALF_PE FROM SAILW1483V.COHORT_ALFS);

--3.1.b. Extracting weight from WLGP.	
CALL FNC.DROP_IF_EXISTS ('SAILW1483V.BMI_WEIGHT_WLGP');

CREATE TABLE SAILW1483V.BMI_WEIGHT_WLGP
(
		ALF_PE        	BIGINT,
		bmi_dt      	DATE,
		weight     		INTEGER,
		source_db		CHAR(4)
)
DISTRIBUTE BY HASH(ALF_PE);

CALL SYSPROC.ADMIN_CMD('runstats on table SAILW1483V.BMI_WEIGHT_WLGP with distribution and detailed indexes all');
COMMIT; 

ALTER TABLE SAILW1483V.BMI_WEIGHT_WLGP activate not logged INITIALLY;

INSERT INTO SAILW1483V.BMI_WEIGHT_WLGP
SELECT DISTINCT 
	ALF_PE,   
	event_dt	AS bmi_dt,
	event_val 	AS weight,
	'WLGP' 		AS source_db
FROM 
	SAILW1483V.BMI_ALG_GP a
RIGHT JOIN
	SAILW1483V.BMI_LOOKUP b
ON a.event_cd = b.BMI_code AND b.category = 'weight'
WHERE 
	(event_dt BETWEEN SAILW1483V.BMI_DATE_FROM AND SAILW1483V.BMI_DATE_TO)
	AND alf_sts_cd IN ('1', '4', '39')
	AND event_val IS NOT NULL
	AND ALF_PE IN (SELECT ALF_PE FROM SAILW1483V.COHORT_ALFS)
;

COMMIT; 

--3.4.a. Union all  height tables
CALL FNC.DROP_IF_EXISTS ('SAILW1483V.BMI_HEIGHT');

CREATE TABLE SAILW1483V.BMI_HEIGHT
(
		ALF_PE        	BIGINT,
		height_dt      	DATE,
		height     		DECIMAL(31,8),
		source_db		CHAR(4)
)
DISTRIBUTE BY HASH(ALF_PE);

CALL SYSPROC.ADMIN_CMD('runstats on table SAILW1483V.BMI_HEIGHT with distribution and detailed indexes all');
COMMIT; 

INSERT INTO SAILW1483V.BMI_HEIGHT -- creating a long table with all the height values from WLGP.
SELECT DISTINCT
	*
FROM 
	SAILW1483V.BMI_HEIGHT_WLGP;

COMMIT;

--3.4.b. Union all weight tables
CALL FNC.DROP_IF_EXISTS ('SAILW1483V.BMI_WEIGHT');

CREATE TABLE SAILW1483V.BMI_WEIGHT
(
		ALF_PE        	BIGINT,
		bmi_dt      	DATE,
		weight     		INTEGER,
		source_db		CHAR(4)
)
DISTRIBUTE BY HASH(ALF_PE);

CALL SYSPROC.ADMIN_CMD('runstats on table SAILW1483V.BMI_WEIGHT with distribution and detailed indexes all');
COMMIT; 

ALTER TABLE SAILW1483V.BMI_WEIGHT activate not logged INITIALLY;

INSERT INTO SAILW1483V.BMI_WEIGHT --creating a long table with all the weight values from WLGP.
SELECT DISTINCT
	*
FROM 
	SAILW1483V.BMI_WEIGHT_WLGP;

COMMIT;

-----------------------------------------------------------------------------------------------------------------
---4. extracting ALF_PEs WITH code FROM PEDW
-----------------------------------------------------------------------------------------------------------------
CALL FNC.DROP_IF_EXISTS ('SAILW1483V.BMI_PEDW');

CREATE TABLE SAILW1483V.BMI_PEDW
(
		ALF_PE        	BIGINT,
		BMI_dt     		DATE,
		BMI_cat			VARCHAR(13),
		BMI_c			CHAR(1),
		source_db		CHAR(4)
)
DISTRIBUTE BY HASH(ALF_PE);

CALL SYSPROC.ADMIN_CMD('runstats on table SAILW1483V.BMI_PEDW with distribution and detailed indexes all');
COMMIT; 

INSERT INTO SAILW1483V.BMI_PEDW 
SELECT distinct ALF_PE, 
	ADMIS_DT 	AS BMI_dt, 
	'Obese' 	AS BMI_cat,
	'4' 		AS BMI_c,
	'PEDW' 		AS source_db
FROM 
	SAILW1483V.BMI_ALG_PEDW_SPELL a 
INNER JOIN 
	SAILW1483V.BMI_ALG_PEDW_DIAG b 
USING 
	(SPELL_NUM_PE)
WHERE 
	(ADMIS_DT  BETWEEN SAILW1483V.BMI_DATE_FROM AND SAILW1483V.BMI_DATE_TO)
	AND DIAG_CD LIKE 'E66%' -- ICD-10 codes that match this have obesity diagnoses.
	AND alf_sts_cd IN ('1', '4', '39')
	AND ALF_PE IN (SELECT ALF_PE FROM SAILW1483V.COHORT_ALFS);

COMMIT;

--------------------------------------------------------------
------------ Putting all BMI data in one table.
--------------------------------------------------------------
-- 5.1 Here we put all the BMI data in one table. We allocate a hierarchical rank based on source type.
CALL FNC.DROP_IF_EXISTS ('SAILW1483V.BMI_COMBO_STAGE_1');

CREATE TABLE SAILW1483V.BMI_COMBO_STAGE_1
(
		ALF_PE        	BIGINT,
		BMI_dt     		DATE,
		BMI_cat			VARCHAR(13),
		BMI_c			CHAR(1),
		BMI_val			DECIMAL(5),
		height			DECIMAL(31,8),
		weight			INTEGER,
		source_type		VARCHAR(50),
		source_rank		SMALLINT,
		source_db		CHAR(4)
)
DISTRIBUTE BY HASH(ALF_PE);

CALL SYSPROC.ADMIN_CMD('runstats on table SAILW1483V.BMI_COMBO_STAGE_1 with distribution and detailed indexes all');
COMMIT; 

ALTER TABLE SAILW1483V.BMI_COMBO_STAGE_1 activate not logged INITIALLY;

INSERT INTO SAILW1483V.BMI_COMBO_STAGE_1
SELECT  DISTINCT -- removes duplicates
	*
FROM 
	(
		SELECT 
			ALF_PE, 
			BMI_dt, 
			BMI_cat, 
			BMI_c,
			BMI_val, 
			NULL 			AS height, 
			NULL 			AS weight, 
			'BMI category' 	AS source_type, 
			'5' 			AS source_rank,
			source_db
		FROM 
			SAILW1483V.BMI_CAT 
		UNION ALL
		SELECT 
			ALF_PE, 
			BMI_dt, 
			BMI_cat, 
			BMI_c,
			BMI_val, 
			NULL 			AS height, 
			NULL 			AS weight, 
			'BMI value' 	AS source_type, 
			'1' 			AS source_rank,
			source_db 
		FROM 
			SAILW1483V.BMI_VAL
		UNION ALL
		SELECT 
			ALF_PE, 
			height_dt 	AS BMI_dt, 
			NULL		AS BMI_cat,
			NULL		AS BMI_c,
			NULL		AS BMI_val, 
			height, 
			NULL 		AS weight, 
			'height' 	AS source_type, 
			'2' 		AS source_rank,
			source_db
		FROM SAILW1483V.BMI_HEIGHT
		WHERE 
			source_db = 'WLGP'
		UNION ALL
			SELECT 
			ALF_PE, 
			bmi_dt 	AS BMI_dt, 
			NULL		AS BMI_cat,
			NULL		AS BMI_c,
			NULL		AS BMI_val, 
			NULL 		AS height, 
			weight, 
			'weight' 	AS source_type, 
			'2' 		AS source_rank,
			source_db
		FROM SAILW1483V.BMI_WEIGHT
		WHERE 
			source_db = 'WLGP'
		UNION ALL 
		SELECT 
			ALF_PE, 
			BMI_dt,
			BMI_cat,
			BMI_c,
			NULL				AS BMI_val, 
			NULL 				AS height, 
			NULL 				AS weight, 
			'ICD-10' 			AS source_type, 
			'6' 				AS source_rank,
			source_db			
		FROM 
			SAILW1483V.BMI_PEDW
	)
;

---------------------------------------------
-- Stage 2. Linking WDSD tables.
--------------------------------------------
-- we only want to select ALFs with valid WOB, valid gndr_cd, and those who were alive after the start date.
-- we also calculate how many days each ALF has contributed to the data so we created a follow_up_dod (when they died) and follow_up_res (when they moved out of Wales)
CALL FNC.DROP_IF_EXISTS ('SAILW1483V.BMI_COMBO_STAGE_2');

CREATE TABLE SAILW1483V.BMI_COMBO_STAGE_2
(
		ALF_PE        	BIGINT,
		sex				CHAR(1),
		wob				DATE,
		bmi_dt     		DATE,
		bmi_cat			VARCHAR(13),
		bmi_c			CHAR(1),
		bmi_val			DECIMAL(5),
		height			DECIMAL(31,8),
		weight			INTEGER,
		source_type		VARCHAR(50),
		source_rank		SMALLINT,
		source_db		CHAR(4),
		active_from		DATE,
		active_to		DATE,
		dod				DATE,
		follow_up_dod	INTEGER,
		follow_up_res	INTEGER
)
DISTRIBUTE BY HASH(ALF_PE);

CALL SYSPROC.ADMIN_CMD('runstats on table SAILW1483V.BMI_COMBO_STAGE_2 with distribution and detailed indexes all');
COMMIT; 

ALTER TABLE SAILW1483V.BMI_COMBO_STAGE_2 activate not logged INITIALLY;

INSERT INTO SAILW1483V.BMI_COMBO_STAGE_2 -- attaching dod, from_dt, to_dt to BMI_COMBO and creating the follow_up field.
SELECT
	*,
	-- counting how many days they contributed to the data before death
	-- this creates a flag which counts the difference between study start date and DOD.
	-- we will remove those with > 31 days follow up in the next stage.
	abs(DAYS_BETWEEN(dod, SAILW1483V.BMI_DATE_FROM)) AS follow_up_dod,
	-- counting how many days they contributed to the data before moving out
	abs(DAYS_BETWEEN(active_from, SAILW1483V.BMI_DATE_TO)) AS follow_up_res
FROM
	(
	SELECT DISTINCT 
		a.ALF_PE,
		b.sex,
		b.wob,
		bmi_dt, 
		bmi_cat, 
		bmi_c,
		bmi_val, 
		height, 
		weight, 
		source_type, 
		source_rank,
		source_db,
		b.active_from_2 AS active_from,
		b.active_to_2 AS active_to,
		CASE
			WHEN b.dod IS NOT NULL THEN b.DOD
			ELSE '9999-01-01'
			END AS dod
	FROM 
		SAILW1483V.BMI_COMBO_STAGE_1 a
	LEFT JOIN
		(
		SELECT DISTINCT
		*, 
		CASE -- if they lived in Wales before the study start date, this is changed to the study start date for the calculation of follow_up_res
			WHEN active_from < SAILW1483V.BMI_DATE_FROM THEN SAILW1483V.BMI_DATE_FROM
			ELSE active_from
			END AS active_from_2,
		CASE -- if they are still living in Wales at present, change to end of study date.
			WHEN active_to IS NULL THEN SAILW1483V.BMI_DATE_TO
			ELSE active_to
			END AS active_to_2
		FROM
			(
			SELECT
				ALF_PE,
				gndr_cd AS sex,
				wob,
				death_dt AS dod,
				CAST(activefrom AS date) AS active_from,
				CAST(activeto AS date) AS active_to
			FROM
				SAILW1483V.BMI_ALG_WDSD -- the single view wdsd table.
				WHERE ALF_PE IN (SELECT ALF_PE FROM SAILW1483V.COHORT_ALFS)
			)
		) b
	ON a.ALF_PE = b.ALF_PE AND a.bmi_dt BETWEEN b.active_from AND b.active_to_2
	WHERE 
		b.wob IS NOT NULL -- we only want to keep ALFs that have WOB
		AND (b.sex IN ('1', '2') AND b.sex IS NOT NULL) -- we want ALFs with valid gndr_cd
		OR 	b.dod > SAILW1483V.BMI_DATE_FROM -- we want ALFs who were alive after the start date.
		-- we want ALFs who were alive after the start date. NOTE if I use 'AND', this returns 0 entries. 'OR' function works.
	);


------- selecting only those with 31 days follow up
CALL FNC.DROP_IF_EXISTS ('SAILW1483V.BMI_COMBO');
-- this creates the general combo table.

CREATE TABLE SAILW1483V.BMI_COMBO
(
		ALF_PE        	BIGINT,
		sex				CHAR(1),
		wob				DATE,
		bmi_dt     		DATE,
		bmi_cat			VARCHAR(13),
		bmi_c			CHAR(1),
		bmi_val			DECIMAL(5),
		height			DECIMAL(31,8),
		weight			INTEGER,
		source_type		VARCHAR(50),
		source_rank		SMALLINT,
		source_db		CHAR(4),
		active_from		DATE,
		active_to		DATE,
		dod				DATE,
		follow_up_dod	INTEGER,
		follow_up_res	INTEGER
)
DISTRIBUTE BY HASH(ALF_PE);

CALL SYSPROC.ADMIN_CMD('runstats on table SAILW1483V.BMI_COMBO with distribution and detailed indexes all');
COMMIT; 

ALTER TABLE SAILW1483V.BMI_COMBO activate not logged INITIALLY;

INSERT INTO SAILW1483V.BMI_COMBO
SELECT
	ALF_PE,
	sex,
	wob,
	bmi_dt, 
	bmi_cat, 
	bmi_c,
	bmi_val, 
	height, 
	weight, 
	source_type, 
	source_rank,
	source_db,
	CASE 
		WHEN active_from IS NULL		THEN SAILW1483V.BMI_DATE_FROM
		WHEN active_from IS NOT NULL	THEN active_from
		END AS active_from,
	CASE
		WHEN active_to IS NOT NULL 		THEN active_to
		WHEN active_to IS NULL 			THEN SAILW1483V.BMI_DATE_TO
		END AS active_to,
	dod,
	follow_up_dod,
	follow_up_res
FROM 
	SAILW1483V.BMI_COMBO_STAGE_2
WHERE 
	follow_up_dod > 31; -- we only want ALFs who were alive/in the study after 31 days of the study start date.

COMMIT;

-------------------------------------------------------------------------------
---- Stage 3. Calculating age and pairing height and weight for ADULT COHORT
-------------------------------------------------------------------------------
CALL FNC.DROP_IF_EXISTS ('SAILW1483V.BMI_COMBO_ADULTS_STAGE_1');

CREATE TABLE SAILW1483V.BMI_COMBO_ADULTS_STAGE_1
(
		ALF_PE        	BIGINT,
		sex				CHAR(1),
		wob				DATE,
		bmi_dt     		DATE,
		bmi_cat			VARCHAR(13),
		bmi_c			CHAR(1),
		bmi_val			DECIMAL(5),
		height			DECIMAL(31,8),
		weight			INTEGER,
		source_type		VARCHAR(50),
		source_rank		SMALLINT,
		source_db		CHAR(4),
		active_from		DATE,
		active_to		DATE,
		dod				DATE,
		follow_up_dod	INTEGER,
		follow_up_res	INTEGER
)
DISTRIBUTE BY HASH(ALF_PE);

CALL SYSPROC.ADMIN_CMD('runstats on table SAILW1483V.BMI_COMBO_ADULTS_STAGE_1 with distribution and detailed indexes all');
COMMIT; 

ALTER TABLE SAILW1483V.BMI_COMBO_ADULTS_STAGE_1 activate not logged INITIALLY;

INSERT INTO SAILW1483V.BMI_COMBO_ADULTS_STAGE_1
WITH height_table AS
-- creating the height table
-- 1.standardising measurements
-- 2. taking only height that is recorded in adulthood
-- 3. taking only the most recent height for adults.
	(
	SELECT
		ALF_PE,
		sex,
		wob,
		bmi_dt, 
		bmi_cat, 
		bmi_c,
		bmi_val, 
		height_standard AS height, 
		source_type, 
		source_rank,
		source_db,
		active_from,
		active_to,
		dod,
		follow_up_dod,
		follow_up_res
	FROM
		(
		SELECT
			*,
			CASE 
				WHEN height BETWEEN 1.2 	AND 2.13 	THEN height 
				WHEN height BETWEEN 120 	AND 213 	THEN height/100 -- converts centimeters to meters
				WHEN height BETWEEN 48 		AND 84 		THEN (height*2.54)/100  -- converts inches to meters
				ELSE NULL 
				END AS height_standard,
			ROW_NUMBER() OVER (PARTITION BY ALF_PE ORDER BY bmi_dt desc) AS event_order, -- to get the most recent height reading
			DAYS_BETWEEN (bmi_dt, wob)/365.25 AS age_height
		FROM 
			SAILW1483V.BMI_COMBO
		WHERE
			source_type = 'height' -- selecting entries that are only height values
			AND height != 0 -- it will not calculate if 0 is used as denominator.
		)
	WHERE 
		event_order = 1 -- select only the latest reading for adults
		AND age_height BETWEEN 19 AND 100 -- only height readings done when they were adults are kept to be used to calculate BMI.
	),
weight_table AS-- weight TABLE
-- extracting weight measurements from BMI_COMBO table.
	(
	SELECT
		ALF_PE,
		sex,
		wob,
		bmi_dt, 
		bmi_cat, 
		bmi_c,
		bmi_val,  
		weight, 
		source_type, 
		source_rank,
		source_db,
		active_from,
		active_to,
		dod,
		follow_up_dod,
		follow_up_res
	FROM 
		SAILW1483V.BMI_COMBO
	WHERE 
        source_type = 'weight'
		AND DAYS_BETWEEN (bmi_dt, wob)/365.25 BETWEEN 19 AND 100 -- want to include ALFs who were aged 19 and 100 at the time of BMI reading.
	),
height_weight AS
-- calculating BMI value from the latest height reading for each ALF and the weight entries.
	(
	SELECT
		ALF_PE,
		sex,
		wob,
		bmi_dt,
		CASE  
			WHEN bmi_val < 18.5 					THEN 'Underweight'
			WHEN bmi_val >=18.5   AND bmi_val < 25 	THEN 'Normal weight'
			WHEN bmi_val >= 25.0  AND bmi_val < 30 	THEN 'Overweight'
			WHEN bmi_val >= 30.0 					THEN 'Obese'
			ELSE NULL 
			END AS bmi_cat, -- all the appropriate values will be assigned these categories. 
		CASE  
			WHEN bmi_val < 18.5 					THEN '1'
			WHEN bmi_val >=18.5   AND bmi_val < 25 	THEN '2'
			WHEN bmi_val >= 25.0  AND bmi_val < 30 	THEN '3'
			WHEN bmi_val >= 30.0 					THEN '4'
			ELSE NULL 
			END AS bmi_c,
		bmi_val,
		height,
		weight,
		source_type,
		source_rank,
		source_db,
		active_from,
		active_to,
		dod,
		follow_up_dod,
		follow_up_res
	FROM 
		(
		SELECT 
			a.ALF_PE,
			a.sex,
			a.wob,
			b.bmi_dt,
			DEC(DEC(weight, 10, 2)/(height*height),10) AS bmi_val, -- calculates BMI_VAL from height and weight values
			height,
			weight,
			b.source_type,
			b.source_rank,
			b.source_db,
			b.active_from,
			b.active_to,
			b.dod,
			b.follow_up_dod,
			b.follow_up_res
		FROM
			HEIGHT_TABLE a -- the latest height reading for each ALF. 
		INNER JOIN
			weight_table b -- all the weight readings for each ALF.
		USING (ALF_PE)
		WHERE 
			DEC(DEC(weight, 10, 2)/(height*height),10) BETWEEN 12 AND 100 -- only keeping values that are within our range.
		)
	)
-- getting the table where BMI value has been calculated from height and weight data.
SELECT 
    * 
FROM 
    height_weight;
    
 
--- now adding the other SOURCE types
-- we also allocate the age band in this section.
CALL FNC.DROP_IF_EXISTS ('SAILW1483V.BMI_COMBO_ADULTS');

CREATE TABLE SAILW1483V.BMI_COMBO_ADULTS
(
		ALF_PE        	BIGINT,
		sex				CHAR(1),
		wob				DATE,
		age_months		INTEGER,
		age_years		INTEGER,
		age_band		VARCHAR(100),
		bmi_dt     		DATE,
		bmi_cat			VARCHAR(13),
		bmi_c			CHAR(1),
		bmi_val			DECIMAL(5),
		height			DECIMAL(31,8),
		weight			INTEGER,
		source_type		VARCHAR(50),
		source_rank		SMALLINT,
		source_db		CHAR(4),
		active_from		DATE,
		active_to		DATE,
		dod				DATE,
		follow_up_dod	INTEGER,
		follow_up_res	INTEGER
)
DISTRIBUTE BY HASH(ALF_PE);

CALL SYSPROC.ADMIN_CMD('runstats on table SAILW1483V.BMI_COMBO_ADULTS with distribution and detailed indexes all');
COMMIT; 

ALTER TABLE SAILW1483V.BMI_COMBO_ADULTS activate not logged INITIALLY;

INSERT INTO SAILW1483V.BMI_COMBO_ADULTS
	SELECT
		ALF_PE,
		sex,
		wob,
		ROUND(DAYS_BETWEEN(BMI_DT, WOB)/30.44)			AS age_months,
		ROUND(DAYS_BETWEEN(BMI_DT, WOB)/365.25)			AS age_years,
		CASE 
			WHEN ROUND(DAYS_BETWEEN(BMI_DT, WOB)/365.25) BETWEEN 19 AND 29		THEN '19-29'
			WHEN ROUND(DAYS_BETWEEN(BMI_DT, WOB)/365.25) = 19 					THEN '19-29'
			WHEN ROUND(DAYS_BETWEEN(BMI_DT, WOB)/365.25) = 29					THEN '19-29'
			WHEN ROUND(DAYS_BETWEEN(BMI_DT, WOB)/365.25) BETWEEN 30 AND 39		THEN '30-39'
			WHEN ROUND(DAYS_BETWEEN(BMI_DT, WOB)/365.25) = 30 					THEN '30-39'
			WHEN ROUND(DAYS_BETWEEN(BMI_DT, WOB)/365.25) = 39					THEN '30-39'
			WHEN ROUND(DAYS_BETWEEN(BMI_DT, WOB)/365.25) BETWEEN 40 AND 49		THEN '40-49'
			WHEN ROUND(DAYS_BETWEEN(BMI_DT, WOB)/365.25) = 40 					THEN '40-49'
			WHEN ROUND(DAYS_BETWEEN(BMI_DT, WOB)/365.25) = 49					THEN '40-49'
			WHEN ROUND(DAYS_BETWEEN(BMI_DT, WOB)/365.25) BETWEEN 50 AND 59		THEN '50-59'
			WHEN ROUND(DAYS_BETWEEN(BMI_DT, WOB)/365.25) = 50 					THEN '50-59'
			WHEN ROUND(DAYS_BETWEEN(BMI_DT, WOB)/365.25) = 59					THEN '50-59'
			WHEN ROUND(DAYS_BETWEEN(BMI_DT, WOB)/365.25) BETWEEN 60 AND 69		THEN '60-69'
			WHEN ROUND(DAYS_BETWEEN(BMI_DT, WOB)/365.25) = 60 					THEN '60-69'
			WHEN ROUND(DAYS_BETWEEN(BMI_DT, WOB)/365.25) = 69					THEN '60-69'
			WHEN ROUND(DAYS_BETWEEN(BMI_DT, WOB)/365.25) BETWEEN 70 AND 79		THEN '70-79'
			WHEN ROUND(DAYS_BETWEEN(BMI_DT, WOB)/365.25) = 70 					THEN '70-79'
			WHEN ROUND(DAYS_BETWEEN(BMI_DT, WOB)/365.25) = 79					THEN '70-79'
			WHEN ROUND(DAYS_BETWEEN(BMI_DT, WOB)/365.25) BETWEEN 80 AND 89		THEN '80-89'
			WHEN ROUND(DAYS_BETWEEN(BMI_DT, WOB)/365.25) = 80 					THEN '80-89'
			WHEN ROUND(DAYS_BETWEEN(BMI_DT, WOB)/365.25) = 89					THEN '80-89'
			WHEN ROUND(DAYS_BETWEEN(BMI_DT, WOB)/365.25) >= 90					THEN '90 -100'
			ELSE NULL 
		END AS age_band,
		bmi_dt,
		bmi_cat, -- all the appropriate values will be assigned these categories. 
		bmi_c,
		bmi_val,
		height,
		weight,
		source_type,
		source_rank,
		source_db,
		active_from,
		active_to,
		dod,
		follow_up_dod,
		follow_up_res
	FROM 
		(
		SELECT
			*
		FROM 
			SAILW1483V.BMI_COMBO_ADULTS_STAGE_1-- table which calculated the BMI value and assigned BMI categories from the height and weight values.
		UNION
		SELECT 
			ALF_PE,
			sex,
			wob,
			bmi_dt, 
			bmi_cat, 
			bmi_c,
			bmi_val,
			height,
			weight, 
			source_type, 
			source_rank,
			source_db,
			active_from,
			active_to,
			dod,
			follow_up_dod,
			follow_up_res
		FROM 
			SAILW1483V.BMI_COMBO
		WHERE source_type IN ('bmi category', 'bmi value', 'ICD-10') 
		-- adding all the other entries from BMI_COMBO that were from other sources.
		)
	WHERE 
	 	DAYS_BETWEEN (bmi_dt, wob)/365.25 BETWEEN 19 AND 100 -- getting readings when ALF are 19-100yo.
;

--------------------------------------------
--- Stage 4. Identifying inconsistencies
--------------------------------------------
CALL FNC.DROP_IF_EXISTS ('SAILW1483V.BMI_UNCLEAN_ADULTS_STAGE_1');

CREATE TABLE SAILW1483V.BMI_UNCLEAN_ADULTS_STAGE_1
(
		ALF_PE        	BIGINT,
		sex				CHAR(1),
		wob				DATE,
		age_months		INTEGER,
		age_years		INTEGER,
		age_band		VARCHAR(100),
		bmi_dt     		DATE,
		bmi_cat			VARCHAR(13),
		bmi_c			CHAR(1),
		bmi_val			DECIMAL(5),
		height			DECIMAL(31,8),
		weight			INTEGER,
		source_type		VARCHAR(50),
		source_rank		SMALLINT,
		source_db		CHAR(4),
		active_from		DATE,
		active_to		DATE,
		dod				DATE,
		follow_up_dod	INTEGER,
		follow_up_res	INTEGER,
		bmi_flg			CHAR(1)
)
DISTRIBUTE BY HASH(ALF_PE);

CALL SYSPROC.ADMIN_CMD('runstats on table SAILW1483V.BMI_UNCLEAN_ADULTS_STAGE_1 with distribution and detailed indexes all');
COMMIT; 

ALTER TABLE SAILW1483V.BMI_UNCLEAN_ADULTS_STAGE_1 activate not logged INITIALLY;

-- first step of cleaning - flags same-day inconsistencies
INSERT INTO SAILW1483V.BMI_UNCLEAN_ADULTS_STAGE_1
	SELECT 
		a.ALF_PE,
		sex,
		wob,
		age_months,
		age_years,
		age_band,
		bmi_dt,
		bmi_cat,
		bmi_c,
		bmi_val,
		height,
		weight,
		source_type,
		source_rank,
		source_db,
		active_from,
		active_to,
		dod,
		follow_up_dod,
		follow_up_res,
	CASE 	
		WHEN BMI_VAL IS NULL THEN -- only BMI categories recorded
			CASE 
				WHEN (dt_diff_before = 0 	AND cat_diff_before > 1) OR  (dt_diff_after = 0 AND cat_diff_after > 1) 						THEN 1 -- same day readings,  different bmi categories
				ELSE NULL END 
		WHEN BMI_VAL IS NOT NULL THEN -- BMI values were recorded.
			CASE 	
				-- same day readings with more than 5% difference in bmi_value BUT has same BMI_recorded, keep the first reading.
				WHEN (dt_diff_after = 0 	AND (val_diff_after/bmi_val) > SAILW1483V.BMI_SAME_DAY AND cat_diff_after = 0) 		THEN 5 -- same day readings, more than 5% BMI value, but same category recording -- we want to keep this record.
				-- same day readings with more than 5% difference in bmi_value AND has different categories recorded
				WHEN (dt_diff_before = 0 	AND (val_diff_before/bmi_val) > SAILW1483V.BMI_SAME_DAY)
					OR (dt_diff_after = 0 	AND (val_diff_after/bmi_val) > SAILW1483V.BMI_SAME_DAY)	
					AND cat_diff_after != 0																								THEN 3 -- more than 5% weight difference on same day reading, and different category
				-- same day reading, less than 5% BMI difference in BMI value, BUT has change of 1 BMI category. We want to keep, but flag them in case:
				WHEN ((dt_diff_before = 0 	AND (val_diff_before/bmi_val) < SAILW1483V.BMI_SAME_DAY)
					and (dt_diff_after = 0 	AND (val_diff_after/bmi_val) < SAILW1483V.BMI_SAME_DAY))
					AND (cat_diff_before = 1 OR cat_diff_after = 1)																		THEN 6	
				ELSE NULL END
		END AS bmi_flg				
	FROM 
		(
		SELECT DISTINCT 
			ALF_PE -- all the ALFs on our adult cohort.
		FROM
			SAILW1483V.BMI_COMBO_ADULTS
		) a
	LEFT JOIN
		( -- identifying the changes in BMI categories/BMI values for same-day / over time period.
		  -- we sequence entries on BMI_DT, BMI_VAL and BMI_C in order to compare the values in a more standardised manner
		  -- same day readings will be sequenced in ascending order and changes between entries will be calculated.
		SELECT 
			*,
			abs(bmi_val - (lag(bmi_val) 			OVER (PARTITION BY ALF_PE ORDER BY bmi_dt, bmi_val, bmi_c)))		AS val_diff_before, 	-- identifies changes in bmi value from previous reading
			abs(dec(bmi_val - (lead(bmi_val) 		OVER (PARTITION BY ALF_PE ORDER BY bmi_dt, bmi_val, bmi_c)))) 	AS val_diff_after, 		-- identifies changes in bmi_value with next reading
			abs(bmi_c - (lag(bmi_c) 				OVER (PARTITION BY ALF_PE ORDER BY bmi_dt, bmi_val, bmi_c))) 	AS cat_diff_before, 	-- identifies changes in bmi category from previous reading
			abs(bmi_c - (lead(bmi_c) 				OVER (PARTITION BY ALF_PE ORDER BY bmi_dt, bmi_val, bmi_c))) 	AS cat_diff_after, 		-- identifies changes in bmi category with next reading
			abs(DAYS_BETWEEN(bmi_dt,(lag(bmi_dt)	OVER (PARTITION BY ALF_PE ORDER BY bmi_dt, bmi_val, bmi_c)))) 	AS dt_diff_before, 		-- identifies number of days passed from previous reading
			abs(DAYS_BETWEEN(bmi_dt,(lead(bmi_dt) 	OVER (PARTITION BY ALF_PE ORDER BY bmi_dt, bmi_val, bmi_c)))) 	AS dt_diff_after 		-- identifies number of days passed with next reading
		FROM 
			SAILW1483V.BMI_COMBO_ADULTS
		) b
	USING (ALF_PE)
;

COMMIT;


-- Now we do the second stage of flagging, where we remove entries flagged as 1 or 3 in UNCLEAN_STAGE_1
CALL FNC.DROP_IF_EXISTS ('SAILW1483V.BMI_UNCLEAN_ADULTS');

CREATE TABLE SAILW1483V.BMI_UNCLEAN_ADULTS
(
		ALF_PE        	BIGINT,
		sex				CHAR(1),
		wob				DATE,
		age_months		INTEGER,
		age_years		INTEGER,
		age_band		VARCHAR(100),
		bmi_dt     		DATE,
		bmi_cat			VARCHAR(13),
		bmi_c			CHAR(1),
		bmi_val			DECIMAL(5),
		height			DECIMAL(31,8),
		weight			INTEGER,
		source_type		VARCHAR(50),
		source_rank		SMALLINT,
		source_db		CHAR(4),
		active_from		DATE,
		active_to		DATE,
		dod				DATE,
		follow_up_dod	INTEGER,
		follow_up_res	INTEGER,
		bmi_flg			CHAR(1)
)
DISTRIBUTE BY HASH(ALF_PE);

CALL SYSPROC.ADMIN_CMD('runstats on table SAILW1483V.BMI_UNCLEAN_ADULTS with distribution and detailed indexes all');
COMMIT; 

ALTER TABLE SAILW1483V.BMI_UNCLEAN_ADULTS activate not logged INITIALLY;

-- second step of cleaning - flags different day inconsistencies
INSERT INTO SAILW1483V.BMI_UNCLEAN_ADULTS
	SELECT 
		a.ALF_PE,
		sex,
		wob,
		age_months,
		age_years,
		age_band,
		bmi_dt,
		bmi_cat,
		bmi_c,
		bmi_val,
		height,
		weight,
		source_type,
		source_rank,
		source_db,
		active_from,
		active_to,
		dod,
		follow_up_dod,
		follow_up_res,
	CASE 
		WHEN bmi_flg IS NOT NULL	THEN bmi_flg
		WHEN BMI_VAL IS NULL THEN -- only BMI categories recorded
			CASE
				WHEN (dt_diff_before != 0 		AND cat_diff_before/dt_diff_before > SAILW1483V.BMI_RATE 	AND cat_diff_before > 1) 
						OR 	 (dt_diff_after != 0 	AND cat_diff_after/dt_diff_after > SAILW1483V.BMI_RATE  	AND cat_diff_after > 1) 	THEN 2 -- more than 0.3% rate of CHANGE
			ELSE NULL END 
		WHEN BMI_VAL IS NOT NULL THEN -- BMI values were recorded.
			CASE
			-- different day readings with more than .3% change of BMI value per day AND more than 1 category change.
					WHEN (dt_diff_before != 0 	AND ((val_diff_before/bmi_val)/dt_diff_before) > SAILW1483V.BMI_RATE AND cat_diff_before > 1) 
						OR (dt_diff_after != 0 	AND ((val_diff_after/bmi_val)/dt_diff_after) > SAILW1483V.BMI_RATE  AND cat_diff_after > 1) 	THEN 4  -- more than 0.03% rate of change over time.
			ELSE NULL END
		END AS bmi_flg				
	FROM 
		(
		SELECT DISTINCT 
			ALF_PE -- all the ALFs on our adult cohort.
		FROM
			SAILW1483V.BMI_COMBO_ADULTS
		) a
	LEFT JOIN
		( -- identifying the changes in BMI categories/BMI values for same-day / over time period.
		  -- we sequence entries on BMI_DT, BMI_VAL and BMI_C in order to compare the values in a more standardised manner
		  -- same day readings will be sequenced in ascending order and changes between entries will be calculated.
		SELECT 
			*,
			abs(bmi_val - (lag(bmi_val) 			OVER (PARTITION BY ALF_PE ORDER BY bmi_dt, bmi_val, bmi_c)))		AS val_diff_before, 	-- identifies changes in bmi value from previous reading
			abs(dec(bmi_val - (lead(bmi_val) 		OVER (PARTITION BY ALF_PE ORDER BY bmi_dt, bmi_val, bmi_c)))) 	AS val_diff_after, 		-- identifies changes in bmi_value with next reading
			abs(bmi_c - (lag(bmi_c) 				OVER (PARTITION BY ALF_PE ORDER BY bmi_dt, bmi_val, bmi_c))) 	AS cat_diff_before, 	-- identifies changes in bmi category from previous reading
			abs(bmi_c - (lead(bmi_c) 				OVER (PARTITION BY ALF_PE ORDER BY bmi_dt, bmi_val, bmi_c))) 	AS cat_diff_after, 		-- identifies changes in bmi category with next reading
			abs(DAYS_BETWEEN(bmi_dt,(lag(bmi_dt)	OVER (PARTITION BY ALF_PE ORDER BY bmi_dt, bmi_val, bmi_c)))) 	AS dt_diff_before, 		-- identifies number of days passed from previous reading
			abs(DAYS_BETWEEN(bmi_dt,(lead(bmi_dt) 	OVER (PARTITION BY ALF_PE ORDER BY bmi_dt, bmi_val, bmi_c)))) 	AS dt_diff_after 		-- identifies number of days passed with next reading
		FROM 
			SAILW1483V.BMI_UNCLEAN_ADULTS_STAGE_1
		-- these are the entries we want to keep:
		WHERE 
			bmi_flg = 5 OR bmi_flg = 6 OR bmi_flg IS NULL
		) b
	USING (ALF_PE)
;

COMMIT;


SELECT '1' AS row_no, count(DISTINCT ALF_PE) AS ALFs, count(*) AS counts FROM SAILW1483V.BMI_UNCLEAN_ADULTS_STAGE_1
WHERE bmi_flg = 1
UNION 
SELECT '2' AS row_no, count(DISTINCT ALF_PE) AS ALFs, count(*) AS counts FROM SAILW1483V.BMI_UNCLEAN_ADULTS_STAGE_1
WHERE bmi_flg = 3
UNION 
SELECT '5' AS row_no, count(DISTINCT ALF_PE) AS ALFs, count(*) AS counts FROM SAILW1483V.BMI_UNCLEAN_ADULTS_STAGE_1
WHERE bmi_flg = 5
UNION 
SELECT '6' AS row_no, count(DISTINCT ALF_PE) AS ALFs, count(*) AS counts FROM SAILW1483V.BMI_UNCLEAN_ADULTS_STAGE_1
WHERE bmi_flg = 6;


SELECT '3' AS row_no, count(DISTINCT ALF_PE) AS ALFs, count(*) AS counts FROM SAILW1483V.BMI_UNCLEAN_ADULTS
WHERE bmi_flg = 2
UNION 
SELECT '4' AS row_no, count(DISTINCT ALF_PE) AS ALFs, count(*) AS counts FROM SAILW1483V.BMI_UNCLEAN_ADULTS
WHERE bmi_flg = 4
UNION
SELECT '5' AS row_no, count(DISTINCT ALF_PE) AS ALFs, count(*) AS counts FROM SAILW1483V.BMI_UNCLEAN_ADULTS
WHERE bmi_flg = 5
UNION 
SELECT '6' AS row_no, count(DISTINCT ALF_PE) AS ALFs, count(*) AS counts FROM SAILW1483V.BMI_UNCLEAN_ADULTS
WHERE bmi_flg = 6;


----------------------------------------
-- Stage 5. Output table
----------------------------------------
CALL FNC.DROP_IF_EXISTS ('SAILW1483V.BMI_CLEAN_ADULTS');

CREATE TABLE SAILW1483V.BMI_CLEAN_ADULTS  -- this table selects entries that are NOT flagged in the previous step.
(
		ALF_PE        	BIGINT,
		sex				CHAR(1),
		wob				DATE,
		age_months		INTEGER,
		age_years		INTEGER,
		age_band		VARCHAR(100),
		bmi_dt     		DATE,
		bmi_cat			VARCHAR(20),
		bmi_val			DECIMAL(5),
		height			DECIMAL(31,8),
		weight			INTEGER,
		source_type		VARCHAR(50),
		source_rank		SMALLINT,
		source_db		CHAR(4),
		active_from		DATE,
		active_to		DATE,
		dod				DATE,
		follow_up_dod	INTEGER,
		follow_up_res	INTEGER,
		bmi_flg			CHAR(1)
)
DISTRIBUTE BY HASH(ALF_PE);

CALL SYSPROC.ADMIN_CMD('runstats on table SAILW1483V.BMI_CLEAN_ADULTS  with distribution and detailed indexes all');
COMMIT; 

INSERT INTO SAILW1483V.BMI_CLEAN_ADULTS
SELECT
	ALF_PE,
	sex,
	wob,
	age_months,
	age_years,
	age_band,
	bmi_dt,
	CASE
		WHEN bmi_val IS NOT NULL THEN -- reiterating the BMI categories for BMI values.
		CASE
			WHEN bmi_val < 18.5 									THEN 'Underweight'
			WHEN bmi_val >=18.5   AND bmi_val < 25 					THEN 'Normal weight'
			WHEN bmi_val >= 25.0  AND bmi_val < 30 					THEN 'Overweight'
			WHEN bmi_val >= 30.0 									THEN 'Obese'
			ELSE NULL END
		WHEN bmi_val IS NULL THEN -- reiterating the BMI categories from source types.
		CASE
			WHEN source_type = 'bmi category'						THEN BMI_CAT
			WHEN source_type = 'ICD-10'								THEN 'Obese'
			ELSE NULL END
	END AS bmi_cat,
	bmi_val,
	height,
	weight,
	source_type,
	source_rank,
	source_db,
	active_from,
	active_to,
	dod,
	follow_up_dod,
	follow_up_res,
	bmi_flg
FROM
	(
	SELECT DISTINCT
		*,
		ROW_NUMBER() OVER (PARTITION BY ALF_PE, bmi_dt ORDER BY source_rank) AS counts -- to identify the duplicates
	FROM
		(
		SELECT DISTINCT 
			a.ALF_PE,
			sex,
			wob,
			age_months,
			age_years,
			age_band,
			a.bmi_dt,
			bmi_cat,
			bmi_val,
			height,
			weight,
			source_type,
			a.source_rank,
			source_db,
			active_from,
			active_to,
			dod,
			follow_up_dod,
			follow_up_res,
			bmi_flg	
		FROM
			(
	--		SELECT count(*)
	--		FROM
	--		(
			SELECT DISTINCT-- our ADULTS cohort
				ALF_PE,
				bmi_dt,
				min(source_rank) AS source_rank -- choose the entry with highest hierarchical rank
			FROM
				SAILW1483V.BMI_UNCLEAN_ADULTS
			GROUP BY
				ALF_PE,
				bmi_dt,
				bmi_flg
			ORDER BY
				ALF_PE,
				bmi_dt 
			) a
		LEFT JOIN 
			SAILW1483V.BMI_UNCLEAN_ADULTS c
		ON a.ALF_PE = c.ALF_PE AND a.bmi_dt=c.bmi_dt AND a.source_rank = c.source_rank
		WHERE 
			bmi_flg IS NULL OR bmi_flg = 5 OR bmi_flg = 6 -- we want to only include entries that are not flagged OR have bmi_flg 5 OR 6.
		) 
	)
WHERE 
	counts = 1 -- remove duplicates brought by the LEFT JOIN.
ORDER BY 
	ALF_PE, 
	bmi_dt;
--
SELECT * FROM SAILW1483V.BMI_CLEAN_ADULTS;
-----------------------------------------------------------------
--
-- Code by: Daniel King
-----------------------------------------------------------------
--
-- All weight-categorised BMI readings
-----------------------------------------------------------------
--
--Drop Table
CALL FNC.DROP_IF_EXISTS('SAILW1483V.TEMP_COHORT_BMI');
COMMIT;
------------------------------------------ 
--
-- Create Table
CREATE TABLE SAILW1483V.TEMP_COHORT_BMI
(
ALF_PE						BIGINT,	
EVENT_DT					DATE,
EVENT_VAL					DECIMAL(31,8),
WEIGHT						VARCHAR(5)
) 
;
COMMIT;
------------------------------------------
--
--Insert into Table
INSERT INTO SAILW1483V.TEMP_COHORT_BMI

WITH A AS
(
SELECT
ALF_PE,
BMI_DT AS EVENT_DT,
BMI_VAL AS EVENT_VAL,
BMI_CAT AS WEIGHT
FROM SAILW1483V.BMI_CLEAN_ADULTS
)

SELECT
ALF_PE,
EVENT_DT,
CASE 
	WHEN EVENT_VAL > 100 THEN NULL 
	ELSE EVENT_VAL 
END AS EVENT_VAL,
CASE 
	WHEN WEIGHT = 'Normal weight' THEN 'N'
	WHEN WEIGHT = 'Overweight' THEN 'OW'
	WHEN WEIGHT = 'Underweight' THEN 'UW'
	WHEN WEIGHT = 'Obese' THEN 'OB'
	ELSE 'UN' 
END AS WEIGHT
FROM A

WHERE EVENT_VAL IS NOT NULL
;
------------------------------------------

SELECT * FROM SAILW1483V.TEMP_COHORT_BMI;

SELECT COUNT(*) FROM SAILW1483V.TEMP_COHORT_BMI;

SELECT COUNT(DISTINCT ALF_PE) FROM SAILW1483V.TEMP_COHORT_BMI;

------------------------------------------
--
-- Most recent BMI record prior to entry to the study
------------------------------------------
--
--Drop Table
CALL FNC.DROP_IF_EXISTS('SAILW1483V.TEMP_COHORT_BMI_BASELINE');
COMMIT;
------------------------------------------ 
--
-- Create Table
CREATE TABLE SAILW1483V.TEMP_COHORT_BMI_BASELINE
(
ALF_PE						BIGINT,
FIRST_DATE					DATE,
EVENT_DT					DATE,
EVENT_VAL					DECIMAL(31,8),
WEIGHT						VARCHAR(5)
) 
;
COMMIT;
------------------------------------------
--
--Insert into Table
INSERT INTO SAILW1483V.TEMP_COHORT_BMI_BASELINE

WITH A AS
(
SELECT
B.ALF_PE,
FIRST_DATE,
EVENT_DT,
EVENT_VAL,
WEIGHT
FROM SAILW1483V.TEMP_COHORT_BMI B

JOIN SAILW1483V.COHORT_ALFS F
ON B.ALF_PE = F.ALF_PE

WHERE B.EVENT_DT <= FIRST_DATE
AND F.INCIDENT = 1
),

B AS
(
SELECT
B.ALF_PE,
SAILW1483V.STUDY_START_DATE AS FIRST_DATE,
EVENT_DT,
EVENT_VAL,
WEIGHT
FROM SAILW1483V.TEMP_COHORT_BMI B

JOIN SAILW1483V.COHORT_ALFS F
ON B.ALF_PE = F.ALF_PE

WHERE B.EVENT_DT <= SAILW1483V.STUDY_START_DATE
AND F.PREVALENT = 1
),

C AS
(
SELECT
F.ALF_PE,
CASE 
	WHEN F.INCIDENT = 1 THEN A.FIRST_DATE 
	ELSE B.FIRST_DATE 
END AS FIRST_DATE,
CASE 
	WHEN F.INCIDENT = 1 THEN A.EVENT_DT 
	ELSE B.EVENT_DT 
END AS EVENT_DT,
CASE
	WHEN F.INCIDENT = 1 THEN A.EVENT_VAL 
	ELSE B.EVENT_VAL 
END AS EVENT_VAL,
CASE 
	WHEN F.INCIDENT = 1 THEN A.WEIGHT 
	ELSE B.WEIGHT 
END AS WEIGHT

FROM SAILW1483V.COHORT_ALFS F

LEFT JOIN A
ON  F.ALF_PE = A.ALF_PE

LEFT JOIN B
ON  F.ALF_PE = B.ALF_PE
)


SELECT
ALF_PE,
FIRST_DATE,
EVENT_DT,
EVENT_VAL,
WEIGHT
FROM
(
SELECT
*,
ROW_NUMBER() OVER(PARTITION BY ALF_PE ORDER BY EVENT_DT DESC) AS RANK
FROM C
)
WHERE RANK = 1
;
------------------------------------------

SELECT * FROM SAILW1483V.TEMP_COHORT_BMI_BASELINE;

SELECT COUNT(*) FROM SAILW1483V.TEMP_COHORT_BMI_BASELINE;

SELECT COUNT(DISTINCT ALF_PE) FROM SAILW1483V.TEMP_COHORT_BMI_BASELINE;

------------------------------------------
--
-- Smoking algorithm for prevalent cases at entry to the study
-----------------------------------------------------------
--Smoking algorithm
--Code by: s.j.aldridge@swansea.ac.uk
-----------------------------------------------------------

-- THIS IS AN ALGORITHM TO ASSIGN SMOKER STATUS OF YOUR ALFS OF INTEREST USING
-- A BUILT IN CLASSIFICATION TABLE BASED OFF OF THE INDIVIDUALS GP RECORDS
-- THE SMOKER STATUSES ARE N - NEVER SMOKER, E - EX-SMOKER AND S - CURRENT SMOKER
-- A DETAILED DOCUMENTATION OF INSTRUCTIONS CAN BE FOUND IN THE README OF THE SMOKING_ALGORITHM REPOSITORY

-------------------------------------------------------------------------------
---------------------------- DECLARE VARIABLES --------------------------------

---DEFINE VARIABLES HERE:
------------------------------------------
CALL FNC.DROP_IF_EXISTS('SAILW1483V.TEMP_ALFS_INPUT_PREV');
COMMIT;
------------------------------------------
--CREATE TABLE
CREATE TABLE SAILW1483V.TEMP_ALFS_INPUT_PREV
(
PATIENT_ID		BIGINT,
DATE_OF_EVENT	DATE
)
;
COMMIT;
------------------------------------------
--INSERT INTO TABLE
INSERT INTO SAILW1483V.TEMP_ALFS_INPUT_PREV

SELECT 
ALF_PE AS PATIENT_ID,
'2010-01-01' AS DATE_OF_EVENT
FROM SAILW1483V.COHORT_ALFS
WHERE PREVALENT = 1
;
------------------------------------------

-- STEP 1 --
	-- FIND AND REPLACE ALL INSTANCES OF "1483" TO YOUR PROJECT CODE (E.G. 1234)
	-- USING CTRL + F

-- STEP 2 --
--	CREATE A USER TABLE SPECIFYING YOUR PATIENT_IDS AND THEIR DATE_OF_EVENT. THIS COULD BE THEIR DIAGNOSIS DATE,
--	THEIR 40TH BIRTHDAY, THE DATE OF SYMPTOM ONSET, WHATEVER YOU LIKE.
--	THE FIELDS NEED TO BE NAMED 'PATIENT_ID' AND 'DATE_OF_EVENT'.
--	AN EXAMPLE CODE FOR CREATING THIS TABLE CAN BE FOUND IN THE EXAMPLE FOLDER (EXAMPLE_1.SQL)
CREATE OR REPLACE ALIAS SAILW1483V.INPUT_USER_TABLE FOR SAILW1483V.TEMP_ALFS_INPUT_PREV; -- CHANGE TO USER TABLE

-- STEP 3 --
	--- SPECIFY YOUR GP TABLE
	--- THIS ALGORITHM WILL EXPAND YOUR INPUT TABLE TO OBTAIN THE NECESSARY DETAILS NEEDED TO RUN THE ALGORITHM, THESE
	--- ARE SOURCED FROM A GP TABLE. PLEASE SPECIFY THE TABLE YOU'D LIKE TO USE.
	--- NOTE - CHECK ID COLUMN NAME (ALF, ALF_PE OR ALF_PE ETC.) AND DEFINE IN 'INPUT_USER_SMOKING' TABLE
	--- DEFAULT ID COLUMN NAME IS ALF_PE
CREATE OR REPLACE ALIAS SAILW1483V.GP_DATABASE FOR SAILW1483V.EXTRACT_WLGP_GP_EVENT_CLEANSED; 

-- STEP 4 --
	-- SPECIFY FOR WHICH TIMEPOINT YOU WANT YOUR SMOKER STATUS TO BE ASSIGNED AT,
	-- SMOKER STATUS AT POINT OF DIAGNOSIS, UP UNTIL A DEFINED CUT-OFF DATE (STEP 5)
	-- IS THE DEFAULT.
	-- OPTION 1 - GIVES SMOKER_STATUS AT YOUR SPECIFIED CUT-OFF DATE, REGARDLESS OF DIAGNOSIS DATE
	-- OPTION 2 - GIVES SMOKER_STATUS BETWEEN DIAGNOSIS DATE AND YOUR CUT-OFF DATE
	-- OPTION 3 - GIVES MOST RECENT SMOKER STATUS WITH CUT-OFF APPLIED TO DATE_OF_EVENT
	--			- GIVES SMOKER STATUS AFTER DATE_OF_EVENT (IF USING DATE_OF_EVENT AS YOUR CUT-OFF I.E. NULL SETTING FROM STEP 5)
	-- SEE THE README FOR DETAILS AND INSTRUCTIONS ON HOW TO IMPLEMENT EACH OPTION.

-- STEP 5 --
	--- SPECIFY YOUR CUTOFF DATE (FORMATTED AS 'YYYY-MM-DD'): UN-COMMENT 5B AND REPLACE IT WITH YOUR DATE,
	--- OR USE 5A WITH 'NULL' TO OBTAIN SMOKER STATUS AT THE POINT OF DIAGNOSIS.
	--- NULL IS THE DEFAULT SETTING
	--5A
CREATE OR REPLACE VARIABLE SAILW1483V.INPUT_SMOKING_DATE_CUTOFF VARCHAR(100) DEFAULT 'NULL';
	--5B-
--CREATE OR REPLACE VARIABLE SAILW1483V.INPUT_SMOKING_DATE_CUTOFF VARCHAR(100) DEFAULT '2010-01-01';

-- STEP 6 --
	--- ASSIGN THE MINIMUM TIME SINCE THE LAST RECORDED 'SMOKER' EVENT FOR AN INDIVIDUAL TO BE CLASSIFIED AS AN EX-SMOKER.
	--- THE DEFAULT SETTING IS 180 DAYS (APPROX 6 MONTHS), SO ANY INDIVIDUAL WITH AN EVENT THAT WOULD CLASSIFY THEM AS A SMOKER DURING THAT
	--- PERIOD WILL BE RECORDED AS A 'SMOKER'. ANYONE WITHOUT A SMOKER EVENT IN THAT PERIOD WILL BE RECORDED AS AN EX-SMOKER
	--- OR NON-SMOKER, DEPENDING ON THEIR HISTORY.
	--- DEFAULT IS 180 DAYS - APPROX 6 MONTHS
	--- UNIT = DAYS
CREATE OR REPLACE VARIABLE SAILW1483V.EX_SMOKER_CUTOFF INTEGER DEFAULT 180;

-- STEP 7 --
	---DESIRED ALF_STS_CDS - SPECIFY THE ALF STS CODES WANTED FOR INCLUSION, DEFAULT IS 1, 4 AND 39.
	---IF YOU WANT MORE CODES INCLUDED, ADD THE VALUES TO THIS TABLE
CALL FNC.DROP_IF_EXISTS ('SAILW1483V.ALF_STS_CD_SMOKING');
--
CREATE TABLE SAILW1483V.ALF_STS_CD_SMOKING
	(ALF_STS_CD	BIGINT);
COMMIT;
--
INSERT INTO SAILW1483V.ALF_STS_CD_SMOKING
VALUES (1), (4), (39); -- REMOVE OR ADD ADDITIONAL CODES TO THIS LINE USING THE SAME FORMAT
COMMIT;
--
SELECT * FROM SAILW1483V.ALF_STS_CD_SMOKING;

-- STEP 8 --
	--- THE READ CODES FOR SMOKER STATUS HAVE BEEN DETERMINED IN THE DEVELOPMENT OF THIS ALGORITHM AND DO NOT REQUIRE INPUT.
	--- *HOWEVER*, IF YOU'D LIKE TO EDIT THIS TABLE, DO SO IN THE SECTION TITLED "CREATE LOOK UP TABLE".
	--- IF YOU'D LIKE TO SUPPLY A NEW TABLE OF YOUR OWN, COMMENT OUT THE "CREATE LOOK UP TABLE" SECTION AND INSERT A REFERENCE TO YOUR OWN TABLE BELOW
-- CREATE OR REPLACE ALIAS SAILW1483V.SMOKER_LOOKUP FOR SAILW1483V.YOUR_LOOK_UP_TABLE_GOES_HERE;

-- STEP 9 --
	-- SELECT ALL (CTRL A) AND RUN THIS ALGORITHM (RIGHT CLICK, EXECUTE --> EXECUTE SQL SCRIPT)

-- STEP 10 --
	-- RESULTS ARE GENERATED TO THE OUTPUT TABLE SAILW1483V.SMOKER_OUTPUT_PREV AND FEATURE
	-- THE PATIENT_ID, DATE_OF_EVENT, SMOKER STATUS AND SMOKER STATUS DETAILS

-------------------------- CREATE LOOK UP TABLE --------------------------------

-- THIS IS AN UPDATED LIST OF READ CODES PUT TOGETHER BY SA BASED ON THE CODES PUBLISHED BY MH,
-- AND WITH THE GUIDANCE OF AA, FT AND RL (JUNE 2021)

CALL FNC.DROP_IF_EXISTS ('SAILW1483V.SMOKER_LOOKUP');

CREATE TABLE SAILW1483V.SMOKER_LOOKUP
(
        SM_CODE         CHAR(6),
        DESCRIPTION		VARCHAR(300),
        SMOKING_STATUS  VARCHAR(1),
        COMPLEXITY		VARCHAR(20)
)
DISTRIBUTE BY HASH (SM_CODE); --PREVIOUSLY WAS BEST PRACTISE, BUT MIGHT BE OUTDATED NOW
COMMIT;

--GRANTING ACCESS TO TEAM MATES
GRANT ALL ON TABLE SAILW1483V.SMOKER_LOOKUP TO ROLE NRDASAIL_SAIL_1483_ANALYST;

--WORTH DOING FOR LARGE CHUNKS OF DATA
ALTER TABLE SAILW1483V.SMOKER_LOOKUP ACTIVATE NOT LOGGED INITIALLY;

--INSERTING READ CODES RELEVENT TO SMOKING
INSERT INTO SAILW1483V.SMOKER_LOOKUP
	(SM_CODE, DESCRIPTION, SMOKING_STATUS, COMPLEXITY)
VALUES
	('1371.'	,	'Never smoked tobacco'											,	'N'	,	'SIMPLE'	)	,
	('1372.'	,	'Trivial smoker - < 1 cig/day'									,	'S'	,	'SIMPLE'	)	,
	('1373.'	,	'Light smoker - 1-9 cigs/day'									,	'S'	,	'SIMPLE'	)	,
	('1374.'	,	'Moderate smoker - 10-19 cigs/d'								,	'S'	,	'SIMPLE'	)	,
	('1375.'	,	'Heavy smoker - 20-39 cigs/day'									,	'S'	,	'SIMPLE'	)	,
	('1376.'	,	'Very heavy smoker - 40+cigs/d'									,	'S'	,	'SIMPLE'	)	,
	('1377.'	,	'Ex-trivial smoker (<1/day)'									,	'E'	,	'SIMPLE'	)	,
	('1378.'	,	'Ex-light smoker (1-9/day)'										,	'E'	,	'SIMPLE'	)	,
	('1379.'	,	'Ex-moderate smoker (10-19/day)'								,	'E'	,	'SIMPLE'	)	,
	('6791.'	,	'Health ed. - smoking'											,	'S'	,	'SIMPLE'	)	,
	('67910'	,	'Health education - parental smoking'							,	'S'	,	'SIMPLE'	)	,
	('137..'	,	'Tobacco consumption'											,	'S'	,	'EVENT_VAL DEPENDENT'	),
	('137A.'	,	'Ex-heavy smoker (20-39/day)'									,	'E'	,	'SIMPLE'	)	,
	('137a.'	,	'Pipe tobacco consumption'										,	'S'	,	'SIMPLE'	)	,
	('137B.'	,	'Ex-very heavy smoker (40+/day)'								,	'E'	,	'SIMPLE'	)	,
	('137b.'	,	'Ready to stop smoking'											,	'S'	,	'SIMPLE'	)	,
	('137C.'	,	'Keeps trying to stop smoking'									,	'S'	,	'SIMPLE'	)	,
	('137c.'	,	'Thinking about stopping smoking'								,	'S'	,	'SIMPLE'	)	,
	('137D.'	,	'Admitted tobacco cons untrue ?'								,	'S'	,	'SIMPLE'	)	,
	('137d.'	,	'Not interested in stopping smoking'							,	'S'	,	'SIMPLE'	)	,
	('137e.'	,	'Smoking restarted'												,	'S'	,	'SIMPLE'	)	,
	('137E.'	,	'Tobacco consumption unknown'									,	'S'	,	'EVENT_VAL DEPENDENT'	),
	('137F.'	,	'Ex-smoker - amount unknown'									,	'E'	,	'SIMPLE'	)	,
	('137f.'	,	'Reason for restarting smoking'									,	'S'	,	'SIMPLE'	)	,
	('137G.'	,	'Trying to give up smoking'										,	'S'	,	'SIMPLE'	)	,
	('137g.'	,	'Cigarette pack-years'											,	'S'	,	'EVENT_VAL DEPENDENT'	),
	('137h.'	,	'Minutes from waking to first tobacco consumption'				,	'S'	,	'SIMPLE'	)	,
	('137H.'	,	'Pipe smoker'													,	'S'	,	'SIMPLE'	)	,
	('137j.'	,	'Ex-cigarette smoker'											,	'E'	,	'SIMPLE'	)	,
	('137J.'	,	'Cigar smoker'													,	'S'	,	'SIMPLE'	)	,
	('137K.'	,	'Stopped smoking'												,	'E'	,	'SIMPLE'	)	,
	('137K0'	,	'Recently stopped smoking'										,	'E'	,	'SIMPLE'	)	,
	('137l.'	,	'Ex roll-up cigarette smoker'									,	'E'	,	'SIMPLE'	)	,
	('137L.'	,	'Current non-smoker'											,	'N'	,	'SIMPLE'	)	,
	('137m.'	,	'Failed attempt to stop smoking'								,	'S'	,	'SIMPLE'	)	,
	('137M.'	,	'Rolls own cigarettes'                                 			,	'S'	,	'SIMPLE'	)	,
	('137N.'	,	'Ex pipe smoker'                                        		,	'E'	,	'SIMPLE'	)	,
	('137O.'	,	'Ex cigar smoker'                                               ,	'E'	,	'SIMPLE'	)	,
	('137P.'	,	'Cigarette smoker'                                    			,	'S'	,	'SIMPLE'	)	,
	('137Q.'	,	'Smoking started'                                               ,	'S'	,	'SIMPLE'	)	,
	('137R.'	,	'Current smoker'                                                ,	'S'	,	'SIMPLE'	)	,
	('137S.'	,	'Ex smoker'                                                     ,	'E'	,	'SIMPLE'	)	,
	('137T.'	,	'Date ceased smoking'                                           ,	'E'	,	'SIMPLE'	)	,
	('137V.'	,	'Smoking reduced'                                               ,	'S'	,	'SIMPLE'	)	,
	('137X.'	,	'Cigarette consumption'                                         ,	'S'	,	'EVENT_VAL DEPENDENT'	)	,
	('137Y.'	,	'Cigar consumption'                                             ,	'S'	,	'EVENT_VAL DEPENDENT'	)	,
	('137Z.'	,	'Tobacco consumption NOS'                                       ,	'S'	,	'EVENT_VAL DEPENDENT'	)	,
	('13cA.'	,	'Smokes drugs'													,	'S'	,	'SIMPLE'	)	,
	('13p..'	,	'Smoking cessation milestones'                                  ,	'S'	,	'SIMPLE'	)	,
	('13p0.'	,	'Negotiated date for cessation of smoking'	                    ,	'S'	,	'SIMPLE'	)	,
	('13p4.'	,	'Smoking free weeks'                                            ,	'E'	,	'SIMPLE'	)	,
	('13p5.'	,	'Smoking cessation programme start date'	                	,	'S'	,	'SIMPLE'	)	,
	('13p50'	,	'Practice based smoking cessation programme start date'         ,	'S'	,	'SIMPLE'	)	,
	('13p8.'	,	'Lost to smok cessation fllw-up'                                ,	'S'	,	'SIMPLE'	)	,
	('1V08.'	,	'Smokes drugs in cigarette form'								,	'S'	,	'SIMPLE'	)	,
	('1V09.'	,	'Smokes drugs through a pipe'									,	'S'	,	'SIMPLE'	)	,
	('38DH.'	,	'Fagerstrom test for nicotine dependence'	                    ,	'S'	,	'SIMPLE'	)	,
	('67A3.'	,	'Pregnancy smoking advice'                                      ,	'S'	,	'SIMPLE'	)	,
	('67H1.'	,	'Lifestyle advice regarding smoking'	                        ,	'S'	,	'SIMPLE'	)	,
	('67H6.'	,	'Brief intervention for smoking cessation'	                    ,	'S'	,	'SIMPLE'	)	,
	('745H.'	,	'Smoking cessation therapy'                                     ,	'S'	,	'SIMPLE'	)	,
	('745H0'	,	'Nicotine replacement therapy using nicotine patches'	        ,	'S'	,	'SIMPLE'	)	,
	('745H1'	,	'Nicotine replacement therapy using nicotine gum'	            ,	'S'	,	'SIMPLE'	)	,
	('745H2'	,	'Nicotine replacement therapy using nicotine inhalator'		    ,	'S'	,	'SIMPLE'	)	,
	('745H3'	,	'Nicotine replacement therapy using nicotine lozenges'	        ,	'S'	,	'SIMPLE'	)	,
	('745H4'	,	'Smoking cessation drug therapy'                                ,	'S'	,	'SIMPLE'	)	,
	('745H5'	,	'Varenicline therapy'                                           ,	'S'	,	'SIMPLE'	)	,
	('745Hy'	,	'Other specified smoking cessation therapy'		                ,	'S'	,	'SIMPLE'	)	,
	('745Hz'	,	'Smoking cessation therapy NOS'                                 ,	'S'	,	'SIMPLE'	)	,
	('8B2B.'	,	'Nicotine replacement therapy'                                  ,	'S'	,	'SIMPLE'	)	,
	('8B2B0'	,	'Issue of nicotine replacement therapy voucher'					,	'S'	,	'SIMPLE'	)	,
	('8B31G'	,	'Varenicline smoking cessation therapy offered'					,	'S'	,	'SIMPLE'	)	,
	('8B3f.'	,	'Nicotine replacement therapy provided free'	                ,	'S'	,	'SIMPLE'	)	,
	('8B3Y.'	,	'Over the counter nicotine replacement therapy'		            ,	'S'	,	'SIMPLE'	)	,
	('8BP3.'	,	'Nicotine replacement therapy provided by community pharmacis'	,	'S'	,	'SIMPLE'	)	,
	('8BPh.'	,	'Bupropion therapy'												,	'S'	,	'SIMPLE'	)	,
	('8CAg.'	,	'Smoking cessation advice provided by community pharmacist'		,	'S'	,	'SIMPLE'	)	,
	('8CAL.'	,	'Smoking cessation advice'                                      ,	'S'	,	'SIMPLE'	)	,
	('8CdB.'	,	'Stop smoking service opportunity signposted'	                ,	'S'	,	'SIMPLE'	)	,
	('8H7i.'	,	'Referral to smoking cessation advisor'		                    ,	'S'	,	'SIMPLE'	)	,
	('8HBM.'	,	'Stop smoking face to face follow-up'	                        ,	'S'	,	'SIMPLE'	)	,
	('8HBP.'	,	'Smoking cessation 12 week follow-up'							,	'S'	,	'SIMPLE'	)	,
	('8HkQ.'	,	'Referral to NHS stop smoking service'	                        ,	'S'	,	'SIMPLE'	)	,
	('8HTK.'	,	'Referral to stop-smoking clinic'	                            ,	'S'	,	'SIMPLE'	)	,
	('8I2I.'	,	'Nicotine replacement therapy contraindicated'	                ,	'S'	,	'SIMPLE'	)	,
	('8I2J.'	,	'Bupropion contraindicated'                                     ,	'S'	,	'SIMPLE'	)	,
	('8I39.'	,	'Nicotine replacement therapy refused'	                        ,	'S'	,	'SIMPLE'	)	,
	('8I3M.'	,	'Bupropion refused'                                             ,	'S'	,	'SIMPLE'	)	,
	('8I6H.'	,	'Smoking review not indicated'                                  ,	'S'	,	'SIMPLE'	)	,
	('8IAj.'	,	'Smoking cessation advice declined'		                        ,	'S'	,	'SIMPLE'	)	,
	('8IEK.'	,	'Smoking cessation programme declined'	                        ,	'S'	,	'SIMPLE'	)	,
	('8IEM.'	,	'Smoking cessation drug therapy declined'	                    ,	'S'	,	'SIMPLE'	)	,
	('8IEM0'	,	'Varenicline smoking cessation therapy declined'				,	'S'	,	'SIMPLE'	)	,
	('8IEo.'	,	'Referral to smoking cessation service declined'				,	'S'	,	'SIMPLE'	)	,
	('8T08.'	,	'Referral to smoking cessation service'							,	'S'	,	'SIMPLE'	)	,
	('9hG..'	,	'Exception reporting: smoking quality indicators'	            ,	'S'	,	'SIMPLE'	)	,
	('9hG0.'	,	'Excepted from smoking quality indicators: Patient unsuitable'	,	'S'	,	'SIMPLE'	)	,
	('9hG1.'	,	'Excepted from smoking quality indicators: Informed dissent'	,	'S'	,	'SIMPLE'	)	,
	('9kc..'	,	'Smoking cessation - enhanced services administration'	        ,	'S'	,	'SIMPLE'	)	,
	('9kc0.'	,	'Smoking cessatn monitor template complet - enhanc serv admin'	,	'S'	,	'SIMPLE'	)	,
	('9km..'	,	'Ex-smoker annual review - enhanced services administration'	,	'E'	,	'SIMPLE'	)	,
	('9kn..'	,	'Non-smoker annual review - enhanced services administration'	,	'N'	,	'SIMPLE'	)	,
	('9ko..'	,	'Current smoker annual review - enhanced services admin'	    ,	'S'	,	'SIMPLE'	)	,
	('9N2k.'	,	'Seen by smoking cessation advisor'		                        ,	'S'	,	'SIMPLE'	)	,
	('9N4M.'	,	'DNA - Did not attend smoking cessation clinic'		            ,	'S'	,	'SIMPLE'	)	,
	('9Ndf.'	,	'Consent given for follow-up by smoking cessation team'			,	'S'	,	'SIMPLE'	)	,
	('9Ndg.'	,	'Declined consent for follow-up by smoking cessation team'	    ,	'S'	,	'SIMPLE'	)	,
	('9NdV.'	,	'Consent given follow-up after smoking cessation intervention'	,	'S'	,	'SIMPLE'	)	,
	('9NdW.'	,	'Consent given for smoking cessation data sharing'	            ,	'S'	,	'SIMPLE'	)	,
	('9NdY.'	,	'Declin cons follow-up evaluation after smoking cess interven'	,	'S'	,	'SIMPLE'	)	,
	('9NdZ.'	,	'Declined consent for smoking cessation data sharing'	        ,	'S'	,	'SIMPLE'	)	,
	('9NS02'	,	'Referral for smoking cessation service offered'	            ,	'S'	,	'SIMPLE'	)	,
	('9OO..'	,	'Anti-smoking monitoring admin.'                                ,	'S'	,	'SIMPLE'	)	,
	('9OO1.'	,	'Attends stop smoking monitor.'                                 ,	'S'	,	'SIMPLE'	)	,
	('9OO2.'	,	'Refuses stop smoking monitor'                                  ,	'S'	,	'SIMPLE'	)	,
	('9OO3.'	,	'Stop smoking monitor default'                                  ,	'S'	,	'SIMPLE'	)	,
	('9OO4.'	,	'Stop smoking monitor 1st lettr'                                ,	'S'	,	'SIMPLE'	)	,
	('9OO5.'	,	'Stop smoking monitor 2nd lettr'                                ,	'S'	,	'SIMPLE'	)	,
	('9OO6.'	,	'Stop smoking monitor 3rd lettr'                                ,	'S'	,	'SIMPLE'	)	,
	('9OO7.'	,	'Stop smoking monitor verb.inv.'                                ,	'S'	,	'SIMPLE'	)	,
	('9OO8.'	,	'Stop smoking monitor phone inv'                                ,	'S'	,	'SIMPLE'	)	,
	('9OO9.'	,	'Stop smoking monitoring delete'                                ,	'S'	,	'SIMPLE'	)	,
	('9OOA.'	,	'Stop smoking monitor.chck done'                                ,	'S'	,	'SIMPLE'	)	,
	('9OOB.'	,	'Stop smoking invitation short message service text message'	,	'S'	,	'SIMPLE'	)	,
	('9OOB0'	,	'Stop smoking invitation first SMS text message'	            ,	'S'	,	'SIMPLE'	)	,
	('9OOB1'	,	'Stop smoking invitation second SMS text message'	            ,	'S'	,	'SIMPLE'	)	,
	('9OOB2'	,	'Stop smoking invitation third SMS text message'	            ,	'S'	,	'SIMPLE'	)	,
	('9OOZ.'	,	'Stop smoking monitor admin.NOS'                                ,	'S'	,	'SIMPLE'	)	,
	('du3..'	,	'NICOTINE'                                                      ,	'S'	,	'SIMPLE'	)	,
	('du31.'	,	'NICOTINE 2mg chewing gum'                                      ,	'S'	,	'SIMPLE'	)	,
	('du32.'	,	'NICOTINE 4mg chewing gum'                                      ,	'S'	,	'SIMPLE'	)	,
	('du33.'	,	'NICORETTE 2mg chewing gum'                                     ,	'S'	,	'SIMPLE'	)	,
	('du34.'	,	'NICORETTE 4mg chewing gum'                                     ,	'S'	,	'SIMPLE'	)	,
	('du35.'	,	'NICOTINELL TTS 10 patches'                                     ,	'S'	,	'SIMPLE'	)	,
	('du36.'	,	'NICOTINELL TTS 20 patches'                                     ,	'S'	,	'SIMPLE'	)	,
	('du37.'	,	'NICOTINELL TTS 30 patches'                                     ,	'S'	,	'SIMPLE'	)	,
	('du38.'	,	'NICOTINE 7mg/24hours patches'                                  ,	'S'	,	'SIMPLE'	)	,
	('du39.'	,	'NICOTINE 14mg/24hours patches'                                 ,	'S'	,	'SIMPLE'	)	,
	('du3a.'	,	'NICORETTE nasal spray'                                         ,	'S'	,	'SIMPLE'	)	,
	('du3A.'	,	'NICOTINE 21mg/24hours patches'                                 ,	'S'	,	'SIMPLE'	)	,
	('du3B.'	,	'*NICORETTE 5mg patches x7'                                     ,	'S'	,	'SIMPLE'	)	,
	('du3b.'	,	'NICOTINE 10mg/mL nasal spray'                                  ,	'S'	,	'SIMPLE'	)	,
	('du3C.'	,	'*NICORETTE 10mg patches x7'                                    ,	'S'	,	'SIMPLE'	)	,
	('du3c.'	,	'NICOTINELL ORIGINAL 2mg gum'                                   ,	'S'	,	'SIMPLE'	)	,
	('du3D.'	,	'*NICORETTE 15mg patches x7'                                    ,	'S'	,	'SIMPLE'	)	,
	('du3d.'	,	'NICOTINELL MINT 2mg gum'                                       ,	'S'	,	'SIMPLE'	)	,
	('du3E.'	,	'*NICORETTE 15mg patches x28'                                   ,	'S'	,	'SIMPLE'	)	,
	('du3e.'	,	'NICOTINE 10mg inhalator starter pack' 		                    ,	'S'	,	'SIMPLE'	)	,
	('du3f.'	,	'NICOTINE 10mg inhalator refill pack'	                        ,	'S'	,	'SIMPLE'	)	,
	('du3F.'	,	'NICOTINE 5mg/16hours patches'                                  ,	'S'	,	'SIMPLE'	)	,
	('du3g.'	,	'NICORETTE 10mg inhalator starter pack'		                    ,	'S'	,	'SIMPLE'	)	,
	('du3G.'	,	'NICOTINE 10mg/16hours patches'                                 ,	'S'	,	'SIMPLE'	)	,
	('du3h.'	,	'NICORETTE 10mg inhalator refill pack'	                        ,	'S'	,	'SIMPLE'	)	,
	('du3H.'	,	'NICOTINE 15mg/16hours patches'                                 ,	'S'	,	'SIMPLE'	)	,
	('du3i.'	,	'NICOTINELL ORIGINAL 4mg chewing gum'	                        ,	'S'	,	'SIMPLE'	)	,
	('du3I.'	,	'NIQUITIN CQ 2mg original lozenges'		                        ,	'S'	,	'SIMPLE'	)	,
	('du3J.'	,	'*NICABATE 7mg patches x14'                                     ,	'S'	,	'SIMPLE'	)	,
	('du3j.'	,	'NICOTINELL MINT 4mg chewing gum'	                            ,	'S'	,	'SIMPLE'	)	,
	('du3K.'	,	'*NICABATE 14mg patches x14'                                    ,	'S'	,	'SIMPLE'	)	,
	('du3k.'	,	'NIQUITIN CQ 7mg/24hours patches'	                            ,	'S'	,	'SIMPLE'	)	,
	('du3L.'	,	'*NICABATE 21mg patches x14'                                    ,	'S'	,	'SIMPLE'	)	,
	('du3l.'	,	'NIQUITIN CQ 14mg/24hours patches'	                            ,	'S'	,	'SIMPLE'	)	,
	('du3M.'	,	'*NICABATE 7mg patches x7'                                      ,	'S'	,	'SIMPLE'	)	,
	('du3m.'	,	'NIQUITIN CQ 21mg/24hours patches'	                            ,	'S'	,	'SIMPLE'	)	,
	('du3N.'	,	'*NICABATE 14mg patches x7'                                     ,	'S'	,	'SIMPLE'	)	,
	('du3n.'	,	'NICOTINE 2mg sublingual tablets'	                            ,	'S'	,	'SIMPLE'	)	,
	('du3o.'	,	'NICORETTE MICROTAB 2mg sublingual tablets'		                ,	'S'	,	'SIMPLE'	)	,
	('du3O.'	,	'NIQUITIN CQ 7mg/24hours clear patches'		                    ,	'S'	,	'SIMPLE'	)	,
	('du3P.'	,	'*NICABATE 21mg patches x7'                                     ,	'S'	,	'SIMPLE'	)	,
	('du3p.'	,	'*NICOTINE 1mg mint lozenges'                                   ,	'S'	,	'SIMPLE'	)	,
	('du3Q.'	,	'*NICORETTE 15mg patches x3'                                    ,	'S'	,	'SIMPLE'	)	,
	('du3q.'	,	'NICOTINELL MINT 1mg lozenges'                                  ,	'S'	,	'SIMPLE'	)	,
	('du3R.'	,	'*NICONIL-11 patches'                                           ,	'S'	,	'SIMPLE'	)	,
	('du3r.'	,	'NIQUITIN CQ 14mg/24hours clear patches'	                    ,	'S'	,	'SIMPLE'	)	,
	('du3S.'	,	'*NICONIL-22 patches'                                           ,	'S'	,	'SIMPLE'	)	,
	('du3s.'	,	'NIQUITIN CQ 21mg/24hours clear patches'	                    ,	'S'	,	'SIMPLE'	)	,
	('du3T.'	,	'*NICOTINE 11mg/24hours patches'                                ,	'S'	,	'SIMPLE'	)	,
	('du3t.'	,	'NICOTINE 2mg fruit chewing gum'                                ,	'S'	,	'SIMPLE'	)	,
	('du3U.'	,	'*NICOTINE 22mg/24hours patches'                                ,	'S'	,	'SIMPLE'	)	,
	('du3u.'	,	'NICOTINE 4mg fruit chewing gum'                                ,	'S'	,	'SIMPLE'	)	,
	('du3V.'	,	'NICORETTE 2mg mint chewing gum'                                ,	'S'	,	'SIMPLE'	)	,
	('du3v.'	,	'NICOTINE 2mg citrus chewing gum'	                            ,	'S'	,	'SIMPLE'	)	,
	('du3w.'	,	'NICORETTE CITRUS 2mg chewing gum'	                            ,	'S'	,	'SIMPLE'	)	,
	('du3W.'	,	'NICORETTE MINT PLUS 4mg chewing gum'	                        ,	'S'	,	'SIMPLE'	)	,
	('du3x.'	,	'NICOTINE 1mg lozenges'                                         ,	'S'	,	'SIMPLE'	)	,
	('du3X.'	,	'NICOTINE 2mg mint chewing gum'                                 ,	'S'	,	'SIMPLE'	)	,
	('du3y.'	,	'NICOTINE 2mg lozenges'                                         ,	'S'	,	'SIMPLE'	)	,
	('du3Y.'	,	'NICOTINE 4mg mint chewing gum'                                 ,	'S'	,	'SIMPLE'	)	,
	('du3Z.'	,	'*NICONIL 22 starter pack'                                      ,	'S'	,	'SIMPLE'	)	,
	('du3z.'	,	'NICOTINE 4mg lozenges'                                         ,	'S'	,	'SIMPLE'	)	,
	('du6..'	,	'BUPROPION'                                                     ,	'S'	,	'SIMPLE'	)	,
	('du61.'	,	'ZYBAN 150mg m/r tablets'                                       ,	'S'	,	'SIMPLE'	)	,
	('du6z.'	,	'BUPROPION HYDROCHLORIDE 150mg m/r tablets'		                ,	'S'	,	'SIMPLE'	)	,
	('du7..'	,	'NICOTINE 2'                                                    ,	'S'	,	'SIMPLE'	)	,
	('du71.'	,	'NIQUITIN CQ 4mg original lozenges'		                        ,	'S'	,	'SIMPLE'	)	,
	('du72.'	,	'NIQUITIN CQ 2mg mint chewing gum'	                            ,	'S'	,	'SIMPLE'	)	,
	('du73.'	,	'NIQUITIN CQ 4mg mint chewing gum'	                            ,	'S'	,	'SIMPLE'	)	,
	('du74.'	,	'*NICORETTE 15mg patches x2'                                    ,	'S'	,	'SIMPLE'	)	,
	('du75.'	,	'NICOTINELL 2mg liquorice chewing gum'	                        ,	'S'	,	'SIMPLE'	)	,
	('du76.'	,	'NICOTINELL 4mg liquorice chewing gum'	                        ,	'S'	,	'SIMPLE'	)	,
	('du77.'	,	'NICOTINELL 2mg mint lozenges'                                  ,	'S'	,	'SIMPLE'	)	,
	('du78.'	,	'NIQUITIN CQ 2mg mint lozenges'                                 ,	'S'	,	'SIMPLE'	)	,
	('du79.'	,	'NIQUITIN CQ 4mg mint lozenges'                                 ,	'S'	,	'SIMPLE'	)	,
	('du7A.'	,	'NICORETTE FRESHMINT 2mg chewing gum'	                        ,	'S'	,	'SIMPLE'	)	,
	('du7a.'	,	'NICOTINELL ICEMINT 4mg chewing gum'	                        ,	'S'	,	'SIMPLE'	)	,
	('du7b.'	,	'NICORETTE 15mg inhalator'                                      ,	'S'	,	'SIMPLE'	)	,
	('du7B.'	,	'NICORETTE FRESHMINT 4mg chewing gum'	                        ,	'S'	,	'SIMPLE'	)	,
	('du7c.'	,	'NICOTINE 15mg inhalator'                                       ,	'S'	,	'SIMPLE'	)	,
	('du7C.'	,	'NICOTINELL CLASSIC 2mg chewing gum'	                        ,	'S'	,	'SIMPLE'	)	,
	('du7d.'	,	'NICASSIST 7mg/24hours patches'                                 ,	'S'	,	'SIMPLE'	)	,
	('du7D.'	,	'NICOTINELL CLASSIC 4mg chewing gum'	                        ,	'S'	,	'SIMPLE'	)	,
	('du7e.'	,	'NICASSIST 14mg/24hours patches'                                ,	'S'	,	'SIMPLE'	)	,
	('du7E.'	,	'NICORETTE FRESHFRUIT 2mg chewing gum'	                        ,	'S'	,	'SIMPLE'	)	,
	('du7f.'	,	'NICASSIST 21mg/24hours patches'                                ,	'S'	,	'SIMPLE'	)	,
	('du7F.'	,	'NICORETTE FRESHFRUIT 4mg chewing gum'	                        ,	'S'	,	'SIMPLE'	)	,
	('du7G.'	,	'*NICOPATCH 7mg/24hours patches'                                ,	'S'	,	'SIMPLE'	)	,
	('du7g.'	,	'NICORETTE COOLS 2mg lozenges'                                  ,	'S'	,	'SIMPLE'	)	,
	('du7H.'	,	'NICOPATCH 14mg/24hours patches'	                            ,	'S'	,	'SIMPLE'	)	,
	('du7h.'	,	'NICORETTE COOLS 4mg lozenges'                                  ,	'S'	,	'SIMPLE'	)	,
	('du7I.'	,	'NICOPATCH 21mg/24hours patches'	                            ,	'S'	,	'SIMPLE'	)	,
	('du7i.'	,	'NIQUITIN PRE-QUIT 21mg/24 hours clear patches'		            ,	'S'	,	'SIMPLE'	)	,
	('du7J.'	,	'NICOPASS 1.5mg fresh mint lozenges'	                        ,	'S'	,	'SIMPLE'	)	,
	('du7j.'	,	'NICORETTE FRUITFUSION 2mg chewing gum'		                    ,	'S'	,	'SIMPLE'	)	,
	('du7K.'	,	'NICOPASS 1.5mg liquorice mint lozenges'	                    ,	'S'	,	'SIMPLE'	)	,
	('du7k.'	,	'NICORETTE FRUITFUSION 4mg chewing gum'		                    ,	'S'	,	'SIMPLE'	)	,
	('du7l.'	,	'NICORETTE FRUITFUSION 6mg chewing gum'		                    ,	'S'	,	'SIMPLE'	)	,
	('du7L.'	,	'NIQUITIN PRE-QUIT 4mg mint lozenges'	                        ,	'S'	,	'SIMPLE'	)	,
	('du7M.'	,	'NICORETTE INVISI 10mg patches'                                 ,	'S'	,	'SIMPLE'	)	,
	('du7N.'	,	'NICORETTE INVISI 15mg patches'                                 ,	'S'	,	'SIMPLE'	)	,
	('du7n.'	,	'NICOTINE 6mg fruit chewing gum'								,	'S'	,	'SIMPLE'	)	,
	('du7O.'	,	'NICORETTE INVISI 25mg patches'									,	'S'	,	'SIMPLE'	)	,
	('du7o.'	,	'NICOTINE 4mg icemint chewing gum'								,	'S'	,	'SIMPLE'	)	,
	('du7P.'	,	'NICORETTE ICY WHITE 2mg chewing gum'							,	'S'	,	'SIMPLE'	)	,
	('du7p.'	,	'NICOTINE 2mg icemint chewing gum'								,	'S'	,	'SIMPLE'	)	,
	('du7Q.'	,	'NICORETTE ICY WHITE 4mg chewing gum' 							,	'S'	,	'SIMPLE'	)	,
	('du7q.'	,	'NICOTINE 1mg oromucosal spray'									,	'S'	,	'SIMPLE'	)	,
	('du7r.'	,	'NICOTINE 1.5mg cherry lozenges'								,	'S'	,	'SIMPLE'	)	,
	('du7R.'	,	'NIQUITIN MINIS MINT 1.5mg lozenges'							,	'S'	,	'SIMPLE'	)	,
	('du7s.'	,	'NICOTINE 4mg cherry lozenges'									,	'S'	,	'SIMPLE'	)	,
	('du7S.'	,	'NIQUITIN MINIS MINT 4mg lozenges'								,	'S'	,	'SIMPLE'	)	,
	('du7T.'	,	'NICORETTE MICROTAB LEMON 2mg sublingual tablets'				,	'S'	,	'SIMPLE'	)	,
	('du7t.'	,	'NICOTINE 15mg/16hours patches and 2mg chewing gum'				,	'S'	,	'SIMPLE'	)	,
	('du7U.'	,	'NICORETTE COMBI 15mg patches and 2mg chewing gum'				,	'S'	,	'SIMPLE'	)	,
	('du7u.'	,	'NICOTINE 1.5mg lozenges'										,	'S'	,	'SIMPLE'	)	,
	('du7v.'	,	'NICOTINE 25mg/16hours patches'									,	'S'	,	'SIMPLE'	)	,
	('du7V.'	,	'NIQUITIN MINIS 1.5mg cherry lozenges'							,	'S'	,	'SIMPLE'	)	,
	('du7w.'	,	'NICOTINE 1.5mg fresh mint lozenges'							,	'S'	,	'SIMPLE'	)	,
	('du7W.'	,	'NIQUITIN MINIS 4mg cherry lozenges'							,	'S'	,	'SIMPLE'	)	,
	('du7X.'	,	'NICORETTE FRESHMINT 2mg lozenges'								,	'S'	,	'SIMPLE'	)	,
	('du7x.'	,	'NICOTINE 1.5mg liquorice mint lozenges'						,	'S'	,	'SIMPLE'	)	,
	('du7Y.'	,	'NICORETTE QUICKMIST 1mg oromucosal spray'						,	'S'	,	'SIMPLE'	)	,
	('du7y.'	,	'NICOTINE 4mg liquorice chewing gum'							,	'S'	,	'SIMPLE'	)	,
	('du7z.'	,	'NICOTINE 2mg liquorice chewing gum'							,	'S'	,	'SIMPLE'	)	,
	('du7Z.'	,	'NICOTINELL ICEMINT 2mg chewing gum'							,	'S'	,	'SIMPLE'	)	,
	('du8..'	,	'VARENICLINE'													,	'S'	,	'SIMPLE'	)	,
	('du81.'	,	'CHAMPIX 1mg tablets'											,	'S'	,	'SIMPLE'	)	,
	('du82.'	,	'CHAMPIX 500microgram tablets'									,	'S'	,	'SIMPLE'	)	,
	('du83.'	,	'CHAMPIX TREATMENT INITIATION pack'								,  	'S'	,	'SIMPLE'	)	,
	('du8x.'	,	'VARENICLINE 500micrograms+1mg tablets'							,  	'S'	,	'SIMPLE'	)	,
	('du8y.'	,	'VARENICLINE 500microgram tablets'								,	'S'	,	'SIMPLE'	)	,
	('du8z.'	,	'VARENICLINE 1mg tablets'										,	'S'	,	'SIMPLE'	)	,
	('du9..'	,	'NICOTINE WITHDRAWAL PRODUCTS'									,	'S'	,	'SIMPLE'	)	,
	('du91.'	,	'NICOBREVIN capsules'											,	'S'	,	'SIMPLE'	)	,
	('duB1.'	,	'NIQUITIN STRIPS 2.5mg mint oral film'							,	'S'	,	'SIMPLE'	)	,
	('duB2.'	,	'NIQUITIN MINIS 1.5mg orange lozenges'							,	'S'	,	'SIMPLE'	)	,
	('duB3.'	,	'NICOTINELL SUPPORT ICEMINT 2mg chewing gum'					,	'S'	,	'SIMPLE'	)	,
	('duB4.'	,	'NICOTINELL SUPPORT ICEMINT 4mg chewing gum'					,	'S'	,	'SIMPLE'	)	,
	('duBz.'	,	'NICOTINE 2.5mg oral film'										,	'S'	,	'SIMPLE'	)	,
	('E023.'	,	'Nicotine withdrawal'											,  	'S'	,	'SIMPLE'	)	,
	('E251.'	,	'Tobacco dependence'											,	'S'	,	'SIMPLE'	)	,
	('E2510'	,	'Tobacco dependence, unspecified'								,	'S'	,	'SIMPLE'	)	,
	('E2511'	,	'Tobacco dependence, continuous'								,	'S'	,	'SIMPLE'	)	,
	('E2512'	,	'Tobacco dependence, episodic'									,	'S'	,	'SIMPLE'	)	,
	('E2513'	,	'Tobacco dependence in remission'								,	'S'	,	'SIMPLE'	)	,
	('E251z'	,	'Tobacco dependence NOS'										,	'S'	,	'SIMPLE'	)	,
	('J0364'	,	'Tobacco deposit on teeth'										,	'S'	,	'SIMPLE'	)	,
	('SMC..'	,	'Toxic effect of tobacco and nicotine'							,	'S'	,	'SIMPLE'	)	,
	('U6099'	,	'[X]Bupropion causing adverse effects in therapeutic use'		,	'S'	,	'SIMPLE'	)	,
	('ZV4K0'	,	'[V]Tobacco use'												,	'S'	,	'SIMPLE'	)	,
	('ZV6D8'	,	'[V]Tobacco abuse counselling'									,	'S'	,	'SIMPLE'	)
	;
COMMIT;

CALL SYSPROC.ADMIN_CMD('runstats on table SAILW1483V.SMOKER_LOOKUP with distribution and detailed indexes all'); -- makes tables compatible with all functions e.g. avg etc

COMMIT;

--check
SELECT * FROM SAILW1483V.SMOKER_LOOKUP;

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
----------------------------- Expand the user table ----------------------------

-- this expands the user table to include EVENT_ details for the ALFs specified

CALL FNC.DROP_IF_EXISTS ('SAILW1483V.input_USER_smoking');
CREATE TABLE sailw1483v.input_USER_smoking
(
 	    PATIENT_ID          BIGINT,
        alf_sts_cd      INTEGER,
        DATE_OF_EVENT		DATE,
        event_dt        DATE,
        event_cd        CHAR(100),
        event_val		DECIMAL(31,8)
)
DISTRIBUTE BY HASH (PATIENT_ID); --previously was best practise, but might be outdated now
COMMIT;
GRANT ALL ON TABLE SAILW1483V.input_USER_smoking TO ROLE NRDASAIL_SAIL_1483_ANALYST; --granting access to team mates
alter table SAILW1483V.input_USER_smoking activate not logged INITIALLY; --worth doing for large chunks of data

insert into SAILW1483V.input_USER_smoking
select
 	    distinct
        US.PATIENT_ID,
        GP.ALF_STS_CD,
        US.DATE_OF_EVENT,
        GP.EVENT_DT,       
        GP.EVENT_CD,
        GP.EVENT_VAL
FROM    
(
	SELECT * FROM SAILW1483V.gp_database
		 WHERE
    		event_cd is not NULL
		AND
		    event_DT is not NULL
		AND
			event_DT >= DATE('2000-01-01')
		AND
			event_DT < CURRENT_DATE	
)	gp	
RIGHT OUTER JOIN
(
	SELECT * FROM SAILW1483V.input_USER_table
	-- additional step if large number in cohort to check time taken
	-- before running full cohort
	-- WHERE PATIENT_ID LIKE '%001'
) US
	ON
	ALF_PE = PATIENT_ID -- confirm ID column name from GP table

	;
COMMIT;
CALL SYSPROC.ADMIN_CMD('runstats on table SAILW1483V.input_USER_smoking with distribution and detailed indexes all'); -- makes tables compatible with all functions e.g. avg etc
COMMIT;

-- SELECT * FROM SAILW1483V.INPUT_USER_SMOKING;

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-------- Create event table that combines lookup table and user table ----------

-- combines selected tables using the variables declared above


--DROP TABLE SAILW1483V.GP_SMOKE_EVENT;
CALL FNC.DROP_IF_EXISTS ('SAILW1483V.GP_SMOKE_EVENT');

CREATE TABLE sailw1483v.gp_smoke_event
(
        PATIENT_ID				BIGINT,
        alf_sts_cd		        INTEGER,
        DATE_OF_EVENT				DATE,
        event_dt  		        VARCHAR(10),
        event_cd  		        CHAR(6),
        complexity				VARCHAR(20),
        event_val				DECIMAL(31,8),
        description  		    VARCHAR(300),
        smoking_status 			VARCHAR(1),
        diff_day				INTEGER, -- this is the difference between the diagnosis date and the event date
        row_seq					INTEGER, -- ranks the event dates in order from most recent per ALF
        dd_minus_smoker_period	DATE, -- diagnosis date - the ex-smoker cutoff period
        ss_during_cutoff		VARCHAR(20), -- whether or not there is a smoker recording during the period above
        ever_smoked				CHAR(1)
)
DISTRIBUTE BY HASH (PATIENT_ID); --previously was best practise, but might be outdated now
COMMIT;

--granting access to team mates
GRANT ALL ON TABLE SAILW1483V.GP_SMOKE_EVENT TO ROLE NRDASAIL_SAIL_1483_ANALYST;

--worth doing for large chunks of data
alter table SAILW1483V.GP_SMOKE_EVENT activate not logged INITIALLY;

insert into SAILW1483V.GP_SMOKE_EVENT
SELECT DISTINCT 	PATIENT_ID,
					ALF_STS_CD,
					DATE_OF_EVENT,
					EVENT_DT,
					EVENT_CD,
					COMPLEXITY,
					EVENT_VAL,
					DESCRIPTION,
					SMOKING_STATUS,
					DIFF_DAY,
					ROW_NUMBER() OVER(PARTITION BY PATIENT_ID ORDER BY DIFF_DAY), -- ranks the event dates in order from most recent per ALF
					DD_MINUS_SMOKER_PERIOD, -- diagnosis date - the ex-smoker cutoff period
					CASE 	WHEN SMOKING_STATUS = 'S'
							AND EVENT_DT BETWEEN DATE(DD_MINUS_SMOKER_PERIOD) AND DATE(DATE_OF_EVENT) THEN 'S'
							ELSE NULL END AS SS_DURING_CUTOFF,
							-- assigns smoker status to anyone with a smoker recording during the period above
					CASE 	WHEN SAILW1483V.input_smoking_date_cutoff <> 'NULL' THEN
								(CASE	WHEN SMOKING_STATUS = 'S' AND EVENT_DT<= SAILW1483V.input_smoking_date_cutoff THEN '1'
										WHEN SMOKING_STATUS = 'E' AND EVENT_DT<= SAILW1483V.input_smoking_date_cutoff THEN '1'
										ELSE NULL
										END)
							WHEN SAILW1483V.input_smoking_date_cutoff = 'NULL' THEN
								(CASE	WHEN SMOKING_STATUS = 'S' AND EVENT_DT<= DATE_OF_EVENT THEN '1'
										WHEN SMOKING_STATUS = 'E' AND EVENT_DT<= DATE_OF_EVENT THEN '1'
										ELSE NULL
										END)
							END AS EVER_SMOKED
				FROM
(select
    distinct
        US.PATIENT_ID,
        STS.ALF_STS_CD,
        US.DATE_OF_EVENT,
		US.EVENT_DT,
		US.EVENT_CD,
        US.EVENT_VAL,
        LU.DESCRIPTION,
		CASE	WHEN (COMPLEXITY = 'EVENT_VAL DEPENDENT' AND EVENT_VAL > 0) THEN 'S'
				WHEN (COMPLEXITY = 'EVENT_VAL DEPENDENT' AND EVENT_VAL = '0') THEN NULL
				WHEN (COMPLEXITY = 'EVENT_VAL DEPENDENT' AND EVENT_VAL IS NULL) THEN NULL
				ELSE LU.SMOKING_STATUS
				END AS SMOKING_STATUS, -- These cases are only classed as smoker when event_val > 0, otherwise they are unknown
		LU.COMPLEXITY,
		DAYS(US.DATE_OF_EVENT) - DAYS(US.EVENT_DT) AS DIFF_DAY, -- this is the difference between the diagnosis date and the event date
		US.DATE_OF_EVENT - SAILW1483V.ex_smoker_cutoff AS DD_MINUS_SMOKER_PERIOD -- ex smoker classification cutoff
FROM    SAILW1483V.input_USER_smoking US -- extract data from user table
RIGHT OUTER JOIN
(
	SELECT * FROM SAILW1483V.SMOKER_LOOKUP
) LU --extract data from Look up table (read codes)
	ON
	(US.EVENT_CD = LU.SM_CODE)
RIGHT OUTER JOIN
(
	SELECT * FROM SAILW1483V.ALF_STS_CD_SMOKING
) STS -- limit results to those that have the desired STS codes (default is 1, 4, 39)
	ON
	(US.ALF_STS_CD = STS.ALF_STS_CD)
 WHERE
    US.PATIENT_ID IS NOT NULL
AND  -- restrict to events before diagnosis
	CASE	WHEN SAILW1483V.input_smoking_date_cutoff <> 'NULL' THEN US.DATE_OF_EVENT <= SAILW1483V.input_smoking_date_cutoff -- only extract cases where diagnosis date is before the cutoff
			WHEN SAILW1483V.input_smoking_date_cutoff = 'NULL' THEN US.DATE_OF_EVENT = US.DATE_OF_EVENT
			END
AND --restrict to events before the cutoff
	CASE	WHEN SAILW1483V.input_smoking_date_cutoff = 'NULL' THEN US.EVENT_DT <= US.DATE_OF_EVENT
			WHEN SAILW1483V.input_smoking_date_cutoff <> 'NULL' THEN US.EVENT_DT <= SAILW1483V.input_smoking_date_cutoff
			END
GROUP BY PATIENT_ID, EVENT_DT, EVENT_CD, STS.ALF_STS_CD, DATE_OF_EVENT, EVENT_VAL, DESCRIPTION, SMOKING_STATUS, COMPLEXITY -- not entirely sure if necessary?
ORDER BY PATIENT_ID, EVENT_DT, EVENT_CD, STS.ALF_STS_CD, DATE_OF_EVENT, EVENT_VAL, DESCRIPTION, SMOKING_STATUS, COMPLEXITY
)
 WHERE DIFF_DAY >= 0 	-- limit data to entries with event_dt before diagnosis date
					-- IF YOU WANT TO CHANGE TO ENTRIES AFTER DIAGNOSIS REPLACE WITH 'DIFF_DAY < 0'
    ;
COMMIT;

CALL SYSPROC.ADMIN_CMD('runstats on table SAILW1483V.GP_SMOKE_EVENT with distribution and detailed indexes all'); -- makes tables compatible with all functions e.g. avg etc

COMMIT;

--checks
--SELECT * FROM SAILW1483V.GP_SMOKE_EVENT
--GROUP BY PATIENT_ID, EVENT_DT, EVENT_CD, ALF_STS_CD, DATE_OF_EVENT, EVENT_VAL, COMPLEXITY, DESCRIPTION, SMOKING_STATUS, DIFF_DAY, ROW_SEQ, DD_MINUS_SMOKER_PERIOD, SS_DURING_CUTOFF,EVER_SMOKED
--ORDER BY PATIENT_ID, DIFF_DAY;

--SELECT DISTINCT ALF_STS_CD FROM SAILW1483V.GP_SMOKE_EVENT;
SELECT MIN(EVENT_DT) AS MIN_EVENT_DT, MAX(EVENT_DT) AS MAX_EVENT_DT, MIN(DATE_OF_EVENT) AS MIN_DIAG_DT, MAX(DATE_OF_EVENT) AS MAX_DIAG_DT FROM SAILW1483V.GP_SMOKE_EVENT;
-- SELECT * FROM SAILW1483V.GP_SMOKE_EVENT WHERE DATE_OF_EVENT < EVENT_DT; -- check to see if the recorded events are within your specified time frame

-----------------------------------------------------------------------------
----------------------- Create Output table ---------------------------------


-- table takes data from the EVENT table and record one smoker status per ALF,
-- rewriting the status where necessary based on their smoking history within
-- the cutoff period

--DROP TABLE SAILW1483V.GP_SMOKE_EVENT;
CALL FNC.DROP_IF_EXISTS ('SAILW1483V.SMOKER_OUTPUT_PREV');

CREATE TABLE sailw1483v.SMOKER_OUTPUT_PREV
(
        PATIENT_ID					BIGINT,
        DATE_OF_EVENT					DATE,
        smoking_status 				CHAR(1),
        smoking_status_description	VARCHAR(15)
)
DISTRIBUTE BY HASH (PATIENT_ID); --previously was best practise, but might be outdated now
COMMIT;

--granting access to team mates
GRANT ALL ON TABLE SAILW1483V.SMOKER_OUTPUT_PREV TO ROLE NRDASAIL_SAIL_1483_ANALYST;

--worth doing for large chunks of data
alter table SAILW1483V.SMOKER_OUTPUT_PREV activate not logged INITIALLY;

--insert data
INSERT INTO SAILW1483V.SMOKER_OUTPUT_PREV

SELECT DISTINCT
	PATIENT_ID,
	DATE_OF_EVENT,
	SMOKER_STATUS,
	CASE	WHEN SMOKER_STATUS = 'S' THEN 'SMOKER'
			WHEN SMOKER_STATUS = 'E' THEN 'EX-SMOKER'
			WHEN SMOKER_STATUS = 'N' THEN 'NEVER SMOKED'
			END
			AS SMOKER_STATUS_DESCRIPTION
FROM
	(
	SELECT DISTINCT
		ES.PATIENT_ID,
		DATE_OF_EVENT,
		CASE	WHEN SS_DURING_CUTOFF = 'S' THEN 'S'
				WHEN SMOKING_STATUS = 'S' THEN 'S'
				WHEN SMOKING_STATUS = 'E' THEN 'E'
				WHEN SMOKING_STATUS = 'N' AND ES.EVER_SMOKED > 0 THEN 'E' -- if ALF has ever been recorded as smoker or ex smoker, then sum(ever_smoker) > 0
				WHEN SMOKING_STATUS IS NULL THEN NULL
				ELSE 'N' END	AS SMOKER_STATUS,
		ROW_SEQ,
		ES.EVER_SMOKED
	FROM SAILW1483V.GP_SMOKE_EVENT OP
	RIGHT OUTER JOIN
(
	SELECT DISTINCT a.PATIENT_ID, SUM(b.EVER_SMOKED) AS EVER_SMOKED --bring sum of values for ever smoking
		FROM	SAILW1483V.INPUT_USER_SMOKING AS a
		LEFT JOIN
		SAILW1483V.GP_SMOKE_EVENT b
		ON a.PATIENT_ID = b.PATIENT_ID
		GROUP BY a.PATIENT_ID
		ORDER BY a.PATIENT_ID
) ES
ON (OP.PATIENT_ID = ES.PATIENT_ID)
	GROUP BY es.PATIENT_ID, DATE_OF_EVENT, SMOKING_STATUS, SS_DURING_CUTOFF, OP.EVER_SMOKED, ES.EVER_SMOKED, ROW_SEQ
	ORDER BY es.PATIENT_ID, ROW_SEQ
	)
	WHERE
	ROW_SEQ = 1 OR ROW_SEQ IS NULL
GROUP BY PATIENT_ID, DATE_OF_EVENT, SMOKER_STATUS
ORDER BY PATIENT_ID, DATE_OF_EVENT;


-- CHECKS --
-- SELECT DISTINCT PATIENT_ID, SUM(EVER_SMOKED) AS EVER_SMOKED
--				FROM SAILW1483V.GP_SMOKE_EVENT
--				GROUP BY PATIENT_ID
--				ORDER BY PATIENT_ID;

DROP TABLE SAILW1483V.input_USER_smoking;
DROP TABLE SAILW1483V.GP_SMOKE_EVENT;

SELECT * FROM SAILW1483V.SMOKER_OUTPUT_PREV
ORDER BY PATIENT_ID;

-- summarise numbers in each class
SELECT smoking_status, smoking_status_description, count(*)
FROM SAILW1483V.SMOKER_OUTPUT_PREV
GROUP BY smoking_status, smoking_status_description
ORDER BY smoking_status ;

-----------------------------------------------------------
--
-- Smoking algorithm for incident cases at entry to the study
-----------------------------------------------------------
--
---define variables here:
--
CALL FNC.DROP_IF_EXISTS('SAILW1483V.TEMP_ALFS_INPUT');
COMMIT;
------------------------------------------
--Create Table
CREATE TABLE SAILW1483V.TEMP_ALFS_INPUT
(
PATIENT_ID		BIGINT,
DATE_OF_EVENT	DATE
)
;
COMMIT;
------------------------------------------
--Insert into Table
INSERT INTO SAILW1483V.TEMP_ALFS_INPUT

SELECT 
ALF_PE AS PATIENT_ID,
FIRST_DATE AS DATE_OF_EVENT
FROM SAILW1483V.COHORT_ALFS
;
------------------------------------------

-- STEP 1 --
	-- find and replace all instances of "1483" to your project code (e.g. 1234)
	-- using ctrl + f

-- STEP 2 --
--	create a user table specifying your PATIENT_IDs and their DATE_OF_EVENT. This could be their diagnosis date,
--	their 40th birthday, the date of symptom onset, whatever you like.
--	The fields need to be named 'PATIENT_ID' and 'DATE_OF_EVENT'.
--	An example code for creating this table can be found in the example folder (Example_1.sql)
CREATE OR REPLACE ALIAS SAILW1483V.input_USER_table FOR SAILW1483V.TEMP_ALFS_INPUT; -- change to user table

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
----------------------------- Expand the user table ----------------------------

-- this expands the user table to include EVENT_ details for the ALFs specified

CALL FNC.DROP_IF_EXISTS ('SAILW1483V.input_USER_smoking');
CREATE TABLE sailw1483v.input_USER_smoking
(
 	    PATIENT_ID          BIGINT,
        alf_sts_cd      INTEGER,
        DATE_OF_EVENT		DATE,
        event_dt        DATE,
        event_cd        CHAR(100),
        event_val		DECIMAL(31,8)
)
DISTRIBUTE BY HASH (PATIENT_ID); --previously was best practise, but might be outdated now
COMMIT;
GRANT ALL ON TABLE SAILW1483V.input_USER_smoking TO ROLE NRDASAIL_SAIL_1483_ANALYST; --granting access to team mates
alter table SAILW1483V.input_USER_smoking activate not logged INITIALLY; --worth doing for large chunks of data

insert into SAILW1483V.input_USER_smoking
select
 	    distinct
        US.PATIENT_ID,
        GP.ALF_STS_CD,
        US.DATE_OF_EVENT,
        GP.EVENT_DT,       
        GP.EVENT_CD,
        GP.EVENT_VAL
FROM    
(
	SELECT * FROM SAILW1483V.gp_database
		 WHERE
    		event_cd is not NULL
		AND
		    event_DT is not NULL
		AND
			event_DT >= DATE('2000-01-01')
		AND
			event_DT < CURRENT_DATE	
)	gp	
RIGHT OUTER JOIN
(
	SELECT * FROM SAILW1483V.input_USER_table
	-- additional step if large number in cohort to check time taken
	-- before running full cohort
	-- WHERE PATIENT_ID LIKE '%001'
) US
	ON
	ALF_PE = PATIENT_ID -- confirm ID column name from GP table

	;
COMMIT;
CALL SYSPROC.ADMIN_CMD('runstats on table SAILW1483V.input_USER_smoking with distribution and detailed indexes all'); -- makes tables compatible with all functions e.g. avg etc
COMMIT;

-- SELECT * FROM SAILW1483V.INPUT_USER_SMOKING;

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-------- Create event table that combines lookup table and user table ----------

-- combines selected tables using the variables declared above


--DROP TABLE SAILW1483V.GP_SMOKE_EVENT;
CALL FNC.DROP_IF_EXISTS ('SAILW1483V.GP_SMOKE_EVENT');

CREATE TABLE sailw1483v.gp_smoke_event
(
        PATIENT_ID				BIGINT,
        alf_sts_cd		        INTEGER,
        DATE_OF_EVENT				DATE,
        event_dt  		        VARCHAR(10),
        event_cd  		        CHAR(6),
        complexity				VARCHAR(20),
        event_val				DECIMAL(31,8),
        description  		    VARCHAR(300),
        smoking_status 			VARCHAR(1),
        diff_day				INTEGER, -- this is the difference between the diagnosis date and the event date
        row_seq					INTEGER, -- ranks the event dates in order from most recent per ALF
        dd_minus_smoker_period	DATE, -- diagnosis date - the ex-smoker cutoff period
        ss_during_cutoff		VARCHAR(20), -- whether or not there is a smoker recording during the period above
        ever_smoked				CHAR(1)
)
DISTRIBUTE BY HASH (PATIENT_ID); --previously was best practise, but might be outdated now
COMMIT;

--granting access to team mates
GRANT ALL ON TABLE SAILW1483V.GP_SMOKE_EVENT TO ROLE NRDASAIL_SAIL_1483_ANALYST;

--worth doing for large chunks of data
alter table SAILW1483V.GP_SMOKE_EVENT activate not logged INITIALLY;

insert into SAILW1483V.GP_SMOKE_EVENT
SELECT DISTINCT 	PATIENT_ID,
					ALF_STS_CD,
					DATE_OF_EVENT,
					EVENT_DT,
					EVENT_CD,
					COMPLEXITY,
					EVENT_VAL,
					DESCRIPTION,
					SMOKING_STATUS,
					DIFF_DAY,
					ROW_NUMBER() OVER(PARTITION BY PATIENT_ID ORDER BY DIFF_DAY), -- ranks the event dates in order from most recent per ALF
					DD_MINUS_SMOKER_PERIOD, -- diagnosis date - the ex-smoker cutoff period
					CASE 	WHEN SMOKING_STATUS = 'S'
							AND EVENT_DT BETWEEN DATE(DD_MINUS_SMOKER_PERIOD) AND DATE(DATE_OF_EVENT) THEN 'S'
							ELSE NULL END AS SS_DURING_CUTOFF,
							-- assigns smoker status to anyone with a smoker recording during the period above
					CASE 	WHEN SAILW1483V.input_smoking_date_cutoff <> 'NULL' THEN
								(CASE	WHEN SMOKING_STATUS = 'S' AND EVENT_DT<= SAILW1483V.input_smoking_date_cutoff THEN '1'
										WHEN SMOKING_STATUS = 'E' AND EVENT_DT<= SAILW1483V.input_smoking_date_cutoff THEN '1'
										ELSE NULL
										END)
							WHEN SAILW1483V.input_smoking_date_cutoff = 'NULL' THEN
								(CASE	WHEN SMOKING_STATUS = 'S' AND EVENT_DT<= DATE_OF_EVENT THEN '1'
										WHEN SMOKING_STATUS = 'E' AND EVENT_DT<= DATE_OF_EVENT THEN '1'
										ELSE NULL
										END)
							END AS EVER_SMOKED
				FROM
(select
    distinct
        US.PATIENT_ID,
        STS.ALF_STS_CD,
        US.DATE_OF_EVENT,
		US.EVENT_DT,
		US.EVENT_CD,
        US.EVENT_VAL,
        LU.DESCRIPTION,
		CASE	WHEN (COMPLEXITY = 'EVENT_VAL DEPENDENT' AND EVENT_VAL > 0) THEN 'S'
				WHEN (COMPLEXITY = 'EVENT_VAL DEPENDENT' AND EVENT_VAL = '0') THEN NULL
				WHEN (COMPLEXITY = 'EVENT_VAL DEPENDENT' AND EVENT_VAL IS NULL) THEN NULL
				ELSE LU.SMOKING_STATUS
				END AS SMOKING_STATUS, -- These cases are only classed as smoker when event_val > 0, otherwise they are unknown
		LU.COMPLEXITY,
		DAYS(US.DATE_OF_EVENT) - DAYS(US.EVENT_DT) AS DIFF_DAY, -- this is the difference between the diagnosis date and the event date
		US.DATE_OF_EVENT - SAILW1483V.ex_smoker_cutoff AS DD_MINUS_SMOKER_PERIOD -- ex smoker classification cutoff
FROM    SAILW1483V.input_USER_smoking US -- extract data from user table
RIGHT OUTER JOIN
(
	SELECT * FROM SAILW1483V.SMOKER_LOOKUP
) LU --extract data from Look up table (read codes)
	ON
	(US.EVENT_CD = LU.SM_CODE)
RIGHT OUTER JOIN
(
	SELECT * FROM SAILW1483V.ALF_STS_CD_SMOKING
) STS -- limit results to those that have the desired STS codes (default is 1, 4, 39)
	ON
	(US.ALF_STS_CD = STS.ALF_STS_CD)
 WHERE
    US.PATIENT_ID IS NOT NULL
AND  -- restrict to events before diagnosis
	CASE	WHEN SAILW1483V.input_smoking_date_cutoff <> 'NULL' THEN US.DATE_OF_EVENT <= SAILW1483V.input_smoking_date_cutoff -- only extract cases where diagnosis date is before the cutoff
			WHEN SAILW1483V.input_smoking_date_cutoff = 'NULL' THEN US.DATE_OF_EVENT = US.DATE_OF_EVENT
			END
AND --restrict to events before the cutoff
	CASE	WHEN SAILW1483V.input_smoking_date_cutoff = 'NULL' THEN US.EVENT_DT <= US.DATE_OF_EVENT
			WHEN SAILW1483V.input_smoking_date_cutoff <> 'NULL' THEN US.EVENT_DT <= SAILW1483V.input_smoking_date_cutoff
			END
GROUP BY PATIENT_ID, EVENT_DT, EVENT_CD, STS.ALF_STS_CD, DATE_OF_EVENT, EVENT_VAL, DESCRIPTION, SMOKING_STATUS, COMPLEXITY -- not entirely sure if necessary?
ORDER BY PATIENT_ID, EVENT_DT, EVENT_CD, STS.ALF_STS_CD, DATE_OF_EVENT, EVENT_VAL, DESCRIPTION, SMOKING_STATUS, COMPLEXITY
)
 WHERE DIFF_DAY >= 0 	-- limit data to entries with event_dt before diagnosis date
					-- IF YOU WANT TO CHANGE TO ENTRIES AFTER DIAGNOSIS REPLACE WITH 'DIFF_DAY < 0'
    ;
COMMIT;

CALL SYSPROC.ADMIN_CMD('runstats on table SAILW1483V.GP_SMOKE_EVENT with distribution and detailed indexes all'); -- makes tables compatible with all functions e.g. avg etc

COMMIT;

--checks
--SELECT * FROM SAILW1483V.GP_SMOKE_EVENT
--GROUP BY PATIENT_ID, EVENT_DT, EVENT_CD, ALF_STS_CD, DATE_OF_EVENT, EVENT_VAL, COMPLEXITY, DESCRIPTION, SMOKING_STATUS, DIFF_DAY, ROW_SEQ, DD_MINUS_SMOKER_PERIOD, SS_DURING_CUTOFF,EVER_SMOKED
--ORDER BY PATIENT_ID, DIFF_DAY;

--SELECT DISTINCT ALF_STS_CD FROM SAILW1483V.GP_SMOKE_EVENT;
SELECT MIN(EVENT_DT) AS MIN_EVENT_DT, MAX(EVENT_DT) AS MAX_EVENT_DT, MIN(DATE_OF_EVENT) AS MIN_DIAG_DT, MAX(DATE_OF_EVENT) AS MAX_DIAG_DT FROM SAILW1483V.GP_SMOKE_EVENT;
-- SELECT * FROM SAILW1483V.GP_SMOKE_EVENT WHERE DATE_OF_EVENT < EVENT_DT; -- check to see if the recorded events are within your specified time frame

-----------------------------------------------------------------------------
----------------------- Create Output table ---------------------------------

-- table takes data from the EVENT table and record one smoker status per ALF,
-- rewriting the status where necessary based on their smoking history within
-- the cutoff period

--DROP TABLE SAILW1483V.GP_SMOKE_EVENT;
CALL FNC.DROP_IF_EXISTS ('SAILW1483V.SMOKER_OUTPUT');

CREATE TABLE sailw1483v.SMOKER_OUTPUT
(
        PATIENT_ID					BIGINT,
        DATE_OF_EVENT					DATE,
        smoking_status 				CHAR(1),
        smoking_status_description	VARCHAR(15)
)
DISTRIBUTE BY HASH (PATIENT_ID); --previously was best practise, but might be outdated now
COMMIT;

--granting access to team mates
GRANT ALL ON TABLE SAILW1483V.SMOKER_OUTPUT TO ROLE NRDASAIL_SAIL_1483_ANALYST;

--worth doing for large chunks of data
alter table SAILW1483V.SMOKER_OUTPUT activate not logged INITIALLY;

--insert data
INSERT INTO SAILW1483V.SMOKER_OUTPUT

SELECT DISTINCT
	PATIENT_ID,
	DATE_OF_EVENT,
	SMOKER_STATUS,
	CASE	WHEN SMOKER_STATUS = 'S' THEN 'SMOKER'
			WHEN SMOKER_STATUS = 'E' THEN 'EX-SMOKER'
			WHEN SMOKER_STATUS = 'N' THEN 'NEVER SMOKED'
			END
			AS SMOKER_STATUS_DESCRIPTION
FROM
	(
	SELECT DISTINCT
		ES.PATIENT_ID,
		DATE_OF_EVENT,
		CASE	WHEN SS_DURING_CUTOFF = 'S' THEN 'S'
				WHEN SMOKING_STATUS = 'S' THEN 'S'
				WHEN SMOKING_STATUS = 'E' THEN 'E'
				WHEN SMOKING_STATUS = 'N' AND ES.EVER_SMOKED > 0 THEN 'E' -- if ALF has ever been recorded as smoker or ex smoker, then sum(ever_smoker) > 0
				WHEN SMOKING_STATUS IS NULL THEN NULL
				ELSE 'N' END	AS SMOKER_STATUS,
		ROW_SEQ,
		ES.EVER_SMOKED
	FROM SAILW1483V.GP_SMOKE_EVENT OP
	RIGHT OUTER JOIN
(
	SELECT DISTINCT a.PATIENT_ID, SUM(b.EVER_SMOKED) AS EVER_SMOKED --bring sum of values for ever smoking
		FROM	SAILW1483V.INPUT_USER_SMOKING AS a
		LEFT JOIN
		SAILW1483V.GP_SMOKE_EVENT b
		ON a.PATIENT_ID = b.PATIENT_ID
		GROUP BY a.PATIENT_ID
		ORDER BY a.PATIENT_ID
) ES
ON (OP.PATIENT_ID = ES.PATIENT_ID)
	GROUP BY es.PATIENT_ID, DATE_OF_EVENT, SMOKING_STATUS, SS_DURING_CUTOFF, OP.EVER_SMOKED, ES.EVER_SMOKED, ROW_SEQ
	ORDER BY es.PATIENT_ID, ROW_SEQ
	)
	WHERE
	ROW_SEQ = 1 OR ROW_SEQ IS NULL
GROUP BY PATIENT_ID, DATE_OF_EVENT, SMOKER_STATUS
ORDER BY PATIENT_ID, DATE_OF_EVENT;


-- CHECKS --
-- SELECT DISTINCT PATIENT_ID, SUM(EVER_SMOKED) AS EVER_SMOKED
--				FROM SAILW1483V.GP_SMOKE_EVENT
--				GROUP BY PATIENT_ID
--				ORDER BY PATIENT_ID;

DROP TABLE SAILW1483V.input_USER_smoking;
DROP TABLE SAILW1483V.GP_SMOKE_EVENT;

SELECT * FROM SAILW1483V.SMOKER_OUTPUT
ORDER BY PATIENT_ID;

-- summarise numbers in each class
SELECT smoking_status, smoking_status_description, count(*)
FROM SAILW1483V.SMOKER_OUTPUT
GROUP BY smoking_status, smoking_status_description
ORDER BY smoking_status ;
-----------------------------------------------------------------------------