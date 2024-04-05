SELECT *
  FROM [UCT_SQL].[dbo].[Undergraduate]

go
--Renaming the Columns
--since this was not working lets try option b
EXEC sp_rename 'Undergraduates.[Catalog#Nbr]', 'Catalog_Number', 'COLUMN';

---Altering a Table and adding a new column with the corrected name
ALTER TABLE Undergraduate
ADD Catalog_Number varchar(5);

---Then updating it to with the old name data
UPDATE Undergraduate
SET Catalog_Number = [Catalog#Nbr]

---Then dropping the column
ALTER TABLE Undergraduate
DROP COLUMN Catalog#Nbr;
go

---Altering a Table and adding a new column with the corrected name
ALTER TABLE Undergraduate
ADD Academic_Program varchar(10);

---Then updating it to with the old name data
UPDATE Undergraduate
SET Academic_Program = [Acad#Prog]

---Then dropping the column
ALTER TABLE Undergraduate
DROP COLUMN [Acad#Prog];



----What is the total number and percentage of students for each year who pass both
---the 1st and the 2nd year courses in the same year?
with num as(
SELECT 
[Term]
,[StudentPass] = count(Case
						when ( Grade_numeric >= 50)  OR
								( Grade_character in ('PA','UP'))
						THEN 1
						ELSE NULL
					END)
					
,[NumberofStudents] = count((ID) )
FROM Undergraduate
GROUP BY Term)

SELECT 
[Term]
,[StudentPass]
,[NumberofStudents]
,[PercentagePass] = ROUND((CAST([StudentPass] AS FLOAT) / [NumberofStudents]) * 100,2)
FROM num
ORDER BY Term
go

---. What is the pass rate for the 1st and 2nd year courses for each year? Are there
--any differences between A1 and A2?
With passrate12 as(
SELECT
[Term]
,[FirstYearPass]= COUNT( CASE
					WHEN (Grade_numeric >= 50 AND Catalog_number in ('A1','A2'))
					OR (Catalog_number in ('A1','A2') AND Grade_character in ('PA','UP'))
					THEN 1
					END)

,[SecondYearPass]= COUNT( CASE
					WHEN (Grade_numeric >= 50 AND Catalog_number in ('B1','B2'))
					OR (Catalog_number in ('B1','B2') AND Grade_character in ('PA','UP'))
					THEN 1
					END)
,[FirstYearStudents] = count(CASE
							WHEN (Catalog_number in ('A1','A2'))
							THEN 1
							END)
,[SecondYearStudents] = count(CASE
							WHEN (Catalog_number in ('B1','B2'))
							THEN 1
							END)
FROM Undergraduate
GROUP BY Term)

select 
[Term]
,[FirstYearPass%]=ROUND((CAST([FirstYearPass]AS FLOAT)/[FirstYearStudents])*100,2)
,[FirstYearPass%]=ROUND((CAST([SecondYearPass] AS FLOAT)/[SecondYearStudents])*100,2)

FROM passrate12
ORDER BY Term
go

---How many students fail B1 even if they pass A1 or A2?

--so here we first have to filter the students who failed B1 
--and passed both A1 and A2 the use an inner join
WITH asm AS (
    SELECT 
        a.[Term],
        a.[ID],
        a.[Grade_numeric],
        a.[Catalog_number],
        a.[Grade_character],
        b.[Term] AS [Term_b],
        b.[ID] AS [ID_b],
        b.[Grade_numeric] AS [Grade_numeric_b],
        b.[Catalog_number] AS [Catalog_number_b],   
        b.[Grade_character] AS [Grade_character_b]
    FROM 
        Undergraduate a
    INNER JOIN 
        Undergraduate b ON a.ID = b.ID
    WHERE 
        (
            (a.[Catalog_number] IN ('A1','A2') AND a.[Grade_numeric] >= 50) OR  -- Passed A1 or A2 with numeric grade >= 50
            (a.[Catalog_number] IN ('A1','A2') AND a.[Grade_character] IN ('PA','UP')AND b.[Grade_numeric] IS NULL) -- Passed A1 or A2 with character grade 'PA' or 'UP'
        )
        AND 
        (
            (b.[Catalog_number] = 'B1' AND b.[Grade_numeric] < 50 ) OR -- Failed B1 with numeric grade < 50
            (b.[Catalog_number] = 'B1' AND b.[Grade_numeric] IS NULL AND b.Grade_character NOT IN ('UP','PA')) -- Failed B1 with character grade not 'PA' or 'UP'
        )
)

SELECT 
[PassedA1_A2_FailedB1]=COUNT(*)
FROM asm;
GO

--- What would you suggest the minimum mark obtained should be from 1st year
--courses so that the student is able to pass B1?

WITH NXT AS(
   SELECT 
        a.[Term],
        a.[ID],
        a.[Grade_numeric],
        a.[Catalog_number],
        a.[Grade_character],
        b.[Term] AS [Term_b],
        b.[ID] AS [ID_b],
        b.[Grade_numeric] AS [Grade_numeric_b],
        b.[Catalog_number] AS [Catalog_number_b],   
        b.[Grade_character] AS [Grade_character_b]
    FROM 
        Undergraduate a
    INNER JOIN 
        Undergraduate b ON a.ID = b.ID
    WHERE 
        (
            (a.[Catalog_number] IN ('A1','A2') AND a.[Grade_numeric] >= 50) OR  -- Passed A1 or A2 with numeric grade >= 50
            (a.[Catalog_number] IN ('A1','A2') AND a.[Grade_character] IN ('PA','UP')AND b.[Grade_numeric] IS NULL) -- Passed A1 or A2 with character grade 'PA' or 'UP'
        )
        AND 
        (
            (b.[Catalog_number] = 'B1' AND b.[Grade_numeric] >= 50 ) OR -- Failed B1 with numeric grade < 50
            (b.[Catalog_number] = 'B1' AND b.[Grade_numeric] IS NULL AND b.Grade_character  IN ('UP','PA')) -- passed B1 with character grade not 'PA' or 'UP'
        )

)
SELECT 
[AverageFor1sYear]= ROUND(AVG(Grade_numeric),0)
FROM NXT
where Grade_numeric is NOT NULL
GO

----. What would you suggest the minimum mark obtained should be for B1 so that
--the student is able to pass B2?WITH NXT AS(
   SELECT 
        a.[Term],
        a.[ID],
        a.[Grade_numeric],
        a.[Catalog_number],
        a.[Grade_character],
        b.[Term] AS [Term_b],
        b.[ID] AS [ID_b],
        b.[Grade_numeric] AS [Grade_numeric_b],
        b.[Catalog_number] AS [Catalog_number_b],   
        b.[Grade_character] AS [Grade_character_b]
    FROM 
        Undergraduate a
    INNER JOIN 
        Undergraduate b ON a.ID = b.ID
    WHERE 
        (
            (a.[Catalog_number] ='B1' AND a.[Grade_numeric] >= 50) OR  -- Passed B1 with numeric grade >= 50
            (a.[Catalog_number] ='B1' AND a.[Grade_character] IN ('PA','UP')AND b.[Grade_numeric] IS NULL) -- Passed A1 or A2 with character grade 'PA' or 'UP'
        )
        AND 
        (
            (b.[Catalog_number] = 'B2' AND b.[Grade_numeric] >= 50 ) OR -- Failed B2 with numeric grade < 50
            (b.[Catalog_number] = 'B2' AND b.[Grade_numeric] IS NULL AND b.Grade_character  IN ('UP','PA')) -- PASSED B2 with character grade not 'PA' or 'UP'
        )

)
SELECT 
[AverageFor1sYear]= ROUND(AVG(Grade_numeric),0)
FROM NXT
where Grade_numeric is NOT NULL
GO

---Is there any hope for students with a UP (supplementary exam) for A1 or A2 to
--make it to the 3rd year of their studies without failing B1 and/or B2?WITH NXT AS(
   SELECT 
        a.[Term],
        a.[ID],
        a.[Grade_numeric],
        a.[Catalog_number],
        a.[Grade_character],
        b.[Term] AS [Term_b],
        b.[ID] AS [ID_b],
        b.[Grade_numeric] AS [Grade_numeric_b],
        b.[Catalog_number] AS [Catalog_number_b],   
        b.[Grade_character] AS [Grade_character_b]
    FROM 
        Undergraduate a
    INNER JOIN 
        Undergraduate b ON a.ID = b.ID
    WHERE 
        (
         
            (a.[Catalog_number] in ('A1','A2') AND a.[Grade_character] ='UP' AND b.[Grade_numeric] IS NULL) -- Passed A1 or A2 with character grade 'PA' or 'UP'
        )
        AND 
        (
            (b.[Catalog_number] in ('B1','B2') AND b.[Grade_numeric] >= 50 ) OR -- Failed B1 with numeric grade < 50
            (b.[Catalog_number] in ('B1','B2') AND b.[Grade_numeric] IS NULL AND b.Grade_character  IN ('UP','PA')) -- Failed B1 with character grade not 'PA' or 'UP'
        )

)
SELECT 
[SuppFirstIn2ndyear]= count(*)
FROM NXT
---There is hope because there are 15 of them in B1 and B2