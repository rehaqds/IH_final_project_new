################################# Initialization

# Create a new database
# create database cvd;

select * from state_code limit 10;
select * from brfss2021_cleaned limit 10;

select count(sex) from brfss2021_cleaned;

# To import a big csv file very quickly
SET GLOBAL local_infile=1;
show variables like '%INFILE%';

LOAD DATA LOCAL INFILE 'C:/Users/PC/Ironhack/Course/IH_final_project/Scripts/brfss2021_cleaned.csv'
INTO TABLE brfss2021_cleaned
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

### Primary and Foreign keys

# BRFSS
ALTER TABLE brfss2021_cleaned 
RENAME COLUMN MyUnknownColumn TO person_id;

ALTER TABLE brfss2021_cleaned 
DROP PRIMARY KEY;
#ALTER TABLE brfss2021_cleaned 
#ADD CONSTRAINT PK_brfss PRIMARY KEY (person_id, state_id);
ALTER TABLE brfss2021_cleaned
ADD PRIMARY KEY (person_id);

ALTER TABLE brfss2021_cleaned
ADD CONSTRAINT FK_brfss_state
FOREIGN KEY (state_id) REFERENCES state_code(`Numeric code`);

# Pollution
ALTER TABLE pollution_2021 MODIFY COLUMN `ID State` int;
ALTER TABLE pollution_2021
ADD PRIMARY KEY (`ID State`);

ALTER TABLE pollution_2021
ADD CONSTRAINT FK_pollution_state
FOREIGN KEY (`ID State`) REFERENCES state_code(`Numeric code`);

# Population
ALTER TABLE population_2021 MODIFY COLUMN `ID State` int;
ALTER TABLE population_2021
ADD PRIMARY KEY (`ID State`);

ALTER TABLE population_2021
ADD CONSTRAINT FK_population_state
FOREIGN KEY (`ID State`) REFERENCES state_code(`Numeric code`);

# State code
ALTER TABLE state_code MODIFY COLUMN `Numeric code` int;
ALTER TABLE state_code
ADD PRIMARY KEY (`Numeric code`);

ALTER TABLE state_code
ADD CONSTRAINT FK_state_brfss
FOREIGN KEY (`Numeric code`) REFERENCES brfss2021_cleaned(state_id);


 
################################# Queries
 
 # Test to read some values anywhere
SELECT * FROM brfss2021_cleaned b 
ORDER BY person_id
LIMIT 5
OFFSET 2000;

# Script to select all the columns except 1
SELECT CONCAT_WS(' ',
                 'SELECT',
                 GROUP_CONCAT(' ', column_name),
                 'FROM cvd.brffss2021_cleaned') query_text
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE table_schema = 'cvd' 
  AND table_name = 'brfss2021_cleaned' 
  AND column_name NOT IN ('state_id');
  

# Join all the tables together ********
create view final_table as (
SELECT -- s.`Numeric code` AS state_num,
       s.Name AS state_name,
       ROUND(pop.Population / 1E6, 3) AS `state_population(M)`, 
	   ROUND(pol.`Air Pollution`, 1) AS state_polution, 
       b.* 
FROM brfss2021_cleaned b 
JOIN state_code s
  ON b.state_id = s.`Numeric code`
JOIN population_2021 pop
  ON b.state_id = pop.`ID State`
JOIN pollution_2021 pol
  ON b.state_id = pol.`ID State`
);                                                                                    
DROP VIEW final_table;

SELECT * FROM final_table
ORDER BY education, age #person_id
LIMIT 15
OFFSET 2132;


# Get the number and % of CVD per State    **********
# Using a view with a subquery
create view count_cvd as (
SELECT sq.state_id,
       sq.state_name,
       sq.count_cvd,
       sq.count_persons,
       ROUND(100 * sq.count_cvd / sq.count_persons, 1)  AS `% cvd`
FROM 
(SELECT state_name, 
       state_id,
       SUM(cvd) AS count_cvd,
       COUNT(cvd) AS count_persons
FROM final_table
GROUP BY state_name, state_id
) sq
);
drop view count_cvd;

SELECT * FROM count_cvd
ORDER BY `% cvd` DESC
;

# Effect of air pollution  *************
SELECT sq_rank.*,
       rank() over (ORDER BY sq_rank.cvd_norm) as cvd_rank
FROM
(
SELECT c.state_name, sq_pol.pollution_norm,  # c.`% cvd`,
       ROUND((`% cvd` - min(`% cvd`) OVER ()) 
       / (max(`% cvd`) OVER () - min(`% cvd`) OVER ()), 2) AS cvd_norm
       , rank() over (ORDER BY sq_pol.pollution_norm) as pollution_rank
       #, rank() over (ORDER BY cvd_norm) as cvd_rank
FROM (
SELECT `ID State`,
       ROUND(`Air Pollution`, 1) AS pollution, 
       ROUND((`Air Pollution` - min(`Air Pollution`) OVER ()) 
       / (max(`Air Pollution`) OVER () - min(`Air Pollution`) OVER ()), 2) AS pollution_norm
# over () means over the full column
FROM pollution_2021 
) sq_pol
JOIN count_cvd c
ON c.state_id = sq_pol.`ID State`
) sq_rank
ORDER BY pollution_norm DESC
;


# Check if the quuestionnaire spread accross the states is representative ********
SELECT SUM(Population)
FROM population_2021;

SELECT State, 
       ROUND(Population / 1e6, 3) AS `Population(M)`, 
       ROUND(100 * Population 
             / (SELECT SUM(Population) FROM population_2021) *333/308, 1) AS `% pop_table_pop`,
		pop_cvd.`% pop_table_cvd` 
FROM population_2021 pop
JOIN (
SELECT state_name, `state_population(M)`,
       COUNT(cvd) AS count_persons,
       ROUND(100 * COUNT(cvd) 
             / (SELECT COUNT(cvd) FROM final_table), 1) AS `% pop_table_cvd`       
FROM final_table
GROUP BY state_name, `state_population(M)`) pop_cvd
ON pop.State = pop_cvd.state_name
ORDER BY pop_cvd.`% pop_table_cvd` DESC
;

# Florida (and Puerto-Rico) is missing in the survey
select distinct(state_name) from final_table; #brfss2021_cleaned;


# Correlation of cvd with income, age, education  ***********
SELECT income, 
       SUM(cvd) AS cvd_cases, 
       COUNT(cvd) AS nb_participants, 
       ROUND(100 * SUM(cvd) / COUNT(cvd), 1) AS `% with cvd`,
	   ROUND(100 * SUM(cvd) / 
             (SELECT SUM(cvd) from brfss2021_cleaned), 1) AS `% of cvd`
FROM brfss2021_cleaned
GROUP BY income 
ORDER BY `% with cvd` DESC;

SELECT age, 
       SUM(cvd) AS cvd_cases, 
       COUNT(cvd) AS nb_participants, 
       ROUND(100 * SUM(cvd) / COUNT(cvd), 1) AS `% with cvd`,
	   ROUND(100 * SUM(cvd) / 
             (SELECT SUM(cvd) from brfss2021_cleaned), 1) AS `% of cvd`
FROM brfss2021_cleaned
GROUP BY age 
ORDER BY `% with cvd` DESC;

SELECT education, 
       SUM(cvd) AS cvd_cases, 
       COUNT(cvd) AS nb_participants, 
       ROUND(100 * SUM(cvd) / COUNT(cvd), 1) AS `% with cvd`,
	   ROUND(100 * SUM(cvd) / (SELECT SUM(cvd) from brfss2021_cleaned), 1) AS `% of cvd`
FROM brfss2021_cleaned
GROUP BY education 
ORDER BY `% with cvd` DESC;



# Testing
SELECT p.`Air Pollution`
FROM pollution_2021 p
WHERE p.State = 'california';
