-- ************************************************************
-- Course Registration Queries Script
-- ************************************************************

USE Pj2_09;
GO

-- 3.8.1
-- View available (open and not full) classes for registration.
-- Users may search by:
--   � Course prefix (e.g., 'COP')
--   � Course prefix AND course number (e.g., 'COP' and '3514 ')
--   � Course credit hours (e.g., 3)
--   � Course level (e.g., 4000)
-- Replace example values as needed.

SELECT
    CS.TermCode,
    CS.CRN,
    CS.CoursePrefix,
    CS.CourseNumber,
    C.CourseTitle,
    C.CreditHours,
    C.CourseLevel,
    CS.SectionNumber,
    CS.Schedule,
    CS.Location,
    CS.Capacity,
    CS.EnrollmentCount,
    CS.Status
FROM Bellini.ClassSection CS
JOIN Bellini.Course C
    ON CS.CoursePrefix = C.CoursePrefix
   AND CS.CourseNumber = C.CourseNumber
WHERE CS.Status = 'Open'               -- class not closed
  AND CS.EnrollmentCount < CS.Capacity -- not full
  AND CS.TermCode = '2026SP'           -- example term
  AND (
        CS.CoursePrefix = 'COP'                         -- search by prefix
     OR (CS.CoursePrefix = 'COP' AND CS.CourseNumber = '3514') -- prefix + number
     OR C.CreditHours = 3                              -- search by credit hours
     OR C.CourseLevel = 4000                          -- search by course level
  );

  -- 3.8.2
-- View courses and total required credit hours for a given major (example: BSCS, CatalogYear = 2023)

-- List required courses with hours
SELECT
    MCR.MajorCode,
    MCR.CatalogYear,
    MCR.RequirementType,
    C.CoursePrefix,
    C.CourseNumber,
    C.CourseTitle,
    C.CreditHours
FROM Bellini.MajorCourseRequirement MCR
JOIN Bellini.Course C
    ON MCR.CoursePrefix = C.CoursePrefix
   AND MCR.CourseNumber = C.CourseNumber
WHERE MCR.MajorCode = 'BSCS'
  AND MCR.CatalogYear = 2023;

-- Total credit hours required for that major
SELECT
    MCR.MajorCode,
    MCR.CatalogYear,
    SUM(C.CreditHours) AS TotalRequiredHours
FROM Bellini.MajorCourseRequirement MCR
JOIN Bellini.Course C
    ON MCR.CoursePrefix = C.CoursePrefix
   AND MCR.CourseNumber = C.CourseNumber
WHERE MCR.MajorCode = 'BSCS'
  AND MCR.CatalogYear = 2023
GROUP BY MCR.MajorCode, MCR.CatalogYear;

-- 3.8.3
-- View required courses a student has NOT yet registered or completed,
-- and total remaining credit hours.
-- Example: Student U00000004 (BSCS, 2023 Catalog)

-- List missing required courses
SELECT
    SP.StudentNumber,
    MCR.MajorCode,
    MCR.CatalogYear,
    C.CoursePrefix,
    C.CourseNumber,
    C.CourseTitle,
    C.CreditHours
FROM Bellini.Student SP
JOIN Bellini.MajorCourseRequirement MCR
    ON SP.MajorCode = MCR.MajorCode
   AND SP.CatalogYearStart = MCR.CatalogYear
JOIN Bellini.Course C
    ON MCR.CoursePrefix = C.CoursePrefix
   AND MCR.CourseNumber = C.CourseNumber
WHERE SP.StudentNumber = 'U00000004'
  AND NOT EXISTS (
        SELECT 1
        FROM Bellini.Enrollment E
        JOIN Bellini.ClassSection CS
            ON E.TermCode = CS.TermCode
           AND E.CRN = CS.CRN
        WHERE E.StudentNumber = SP.StudentNumber
          AND CS.CoursePrefix = C.CoursePrefix
          AND CS.CourseNumber = C.CourseNumber
    );

-- Total remaining credit hours
SELECT
    SP.StudentNumber,
    MCR.MajorCode,
    MCR.CatalogYear,
    SUM(C.CreditHours) AS TotalRemainingHours
FROM Bellini.Student SP
JOIN Bellini.MajorCourseRequirement MCR
    ON SP.MajorCode = MCR.MajorCode
   AND SP.CatalogYearStart = MCR.CatalogYear
JOIN Bellini.Course C
    ON MCR.CoursePrefix = C.CoursePrefix
   AND MCR.CourseNumber = C.CourseNumber
WHERE SP.StudentNumber = 'U00000004'
  AND NOT EXISTS (
        SELECT 1
        FROM Bellini.Enrollment E
        JOIN Bellini.ClassSection CS
            ON E.TermCode = CS.TermCode
           AND E.CRN = CS.CRN
        WHERE E.StudentNumber = SP.StudentNumber
          AND CS.CoursePrefix = C.CoursePrefix
          AND CS.CourseNumber = C.CourseNumber
    )
GROUP BY SP.StudentNumber, MCR.MajorCode, MCR.CatalogYear;

-- 3.8.4
-- View the four-year study plan for a student, semester by semester.
-- Example: Student U00000004

SELECT
    SP.StudentNumber,
    STP.MajorCode,
    STP.CatalogYear,
    STP.PlanYear,
    STP.PlanTerm,
    STP.SequenceInTerm,
    C.CoursePrefix,
    C.CourseNumber,
    C.CourseTitle,
    C.CreditHours
FROM Bellini.Student SP
JOIN Bellini.StudyPlan STP
    ON SP.MajorCode = STP.MajorCode
   AND SP.CatalogYearStart = STP.CatalogYear
JOIN Bellini.Course C
    ON STP.CoursePrefix = C.CoursePrefix
   AND STP.CourseNumber = C.CourseNumber
WHERE SP.StudentNumber = 'U00000004'
ORDER BY
    STP.PlanYear,
    CASE STP.PlanTerm
        WHEN 'Fall' THEN 1
        WHEN 'Spring' THEN 2
        ELSE 3
    END,
    STP.SequenceInTerm;

-- 3.8.5
-- View complete information about a specific course including prerequisites and corequisites.
-- Example: Course 'COP' '4530 '

-- Basic course information
SELECT
    C.CoursePrefix,
    C.CourseNumber,
    C.CourseTitle,
    C.CreditHours,
    C.CourseLevel,
    C.Description
FROM Bellini.Course C
WHERE C.CoursePrefix = 'COP'
  AND C.CourseNumber = '4530';

-- List all prerequisite courses
SELECT
    C.CoursePrefix AS CoursePrefix,
    C.CourseNumber AS CourseNumber,
    C.CourseTitle AS CourseTitle,
    PR.PreCoursePrefix AS PrerequisitePrefix,
    PR.PreCourseNumber AS PrerequisiteNumber,
    C2.CourseTitle AS PrerequisiteTitle
FROM Bellini.CoursePreReq PR
JOIN Bellini.Course C
    ON PR.CoursePrefix = C.CoursePrefix
   AND PR.CourseNumber = C.CourseNumber
JOIN Bellini.Course C2
    ON PR.PreCoursePrefix = C2.CoursePrefix
   AND PR.PreCourseNumber = C2.CourseNumber
WHERE PR.CoursePrefix = 'COP'
  AND PR.CourseNumber = '4530';

-- List all corequisite courses
SELECT
    C.CoursePrefix AS CoursePrefix,
    C.CourseNumber AS CourseNumber,
    C.CourseTitle AS CourseTitle,
    CR.CoCoursePrefix AS CorequisitePrefix,
    CR.CoCourseNumber AS CorequisiteNumber,
    C3.CourseTitle AS CorequisiteTitle
FROM Bellini.CourseCoReq CR
JOIN Bellini.Course C
    ON CR.CoursePrefix = C.CoursePrefix
   AND CR.CourseNumber = C.CourseNumber
JOIN Bellini.Course C3
    ON CR.CoCoursePrefix = C3.CoursePrefix
   AND CR.CoCourseNumber = C3.CourseNumber
WHERE CR.CoursePrefix = 'COP'
  AND CR.CourseNumber = '4530';

-- 3.8.6
-- View detailed information of a specific class section.
-- Example: CIS4622.001 in Spring 2026 (TermCode='2026SP', CRN=93003)

-- Main class details
SELECT
    CS.TermCode,
    CS.CRN,
    CS.CoursePrefix,
    CS.CourseNumber,
    CS.SectionNumber,
    C.CourseTitle,
    CS.Schedule,
    CS.Location,
    CS.ClassType,
    CS.Capacity,
    CS.EnrollmentCount,
    CS.Status,
    I.FirstName + ' ' + I.LastName AS InstructorName,
    I.Email AS InstructorEmail,
    I.OfficeLocation,
    I.OfficeHours
FROM Bellini.ClassSection CS
JOIN Bellini.Course C
    ON CS.CoursePrefix = C.CoursePrefix
   AND CS.CourseNumber = C.CourseNumber
LEFT JOIN Bellini.Instructor I
    ON CS.InstructorID = I.InstructorID
WHERE CS.TermCode = '2026SP'
  AND CS.CRN = 93003;

-- TA assigned to this class
SELECT
    TA.TermCode,
    TA.CRN,
    TA.StudentNumber AS TA_StudentNumber,
    S.FirstName + ' ' + S.LastName AS TA_Name,
    S.Email AS TA_Email,
    S.MajorCode AS TA_Major
FROM Bellini.TA_Assignment TA
JOIN Bellini.Student S
    ON TA.StudentNumber = S.StudentNumber
WHERE TA.TermCode = '2026SP'
  AND TA.CRN = 93003;

-- 3.8.7
-- View instructor information (example: InstructorID = 1)

SELECT
    I.InstructorID,
    I.FirstName + ' ' + I.LastName AS InstructorName,
    I.Email,
    I.OfficeLocation,
    I.OfficeHours,
    I.Phone
FROM Bellini.Instructor I
WHERE I.InstructorID = 1;

-- View student information (example: Student U00000003)

SELECT
    S.StudentNumber,
    S.FirstName + ' ' + S.LastName AS StudentName,
    S.Email,
    S.Phone,
    S.MajorCode,
    S.CatalogYearStart,
    S.StartSemester,
    S.StartYear,
    S.EarnedHours,
    S.GPA,
    S.Standing
FROM Bellini.Student S
WHERE S.StudentNumber = 'U00000003';

-- 3.8.8
-- Modify class data of Spring 2026 (example modifications)
-- Must be executed by authorized users only.

-- 1. Update schedule & location
UPDATE Bellini.ClassSection
SET Schedule = 'MW 12:30-13:45',
    Location = 'ENG 220'
WHERE TermCode = '2026SP'
  AND CRN = 93001;

-- 2. Change instructor
UPDATE Bellini.ClassSection
SET InstructorID = 2             -- Assigning to instructor ID 2
WHERE TermCode = '2026SP'
  AND CRN = 93001;

-- 3. Increase total capacity
UPDATE Bellini.ClassSection
SET Capacity = 50
WHERE TermCode = '2026SP'
  AND CRN = 93001;

-- 4. Close registration for the class
UPDATE Bellini.ClassSection
SET Status = 'Closed'
WHERE TermCode = '2026SP'
  AND CRN = 93001;

-- 3.8.9 (Part 1)
-- GPA summary for all students of the same major
-- Example: BSCS

SELECT
    S.MajorCode,
    COUNT(*) AS TotalStudents,
    AVG(S.GPA) AS AverageGPA,
    MAX(S.GPA) AS HighestGPA,
    MIN(S.GPA) AS LowestGPA
FROM Bellini.Student S
WHERE S.MajorCode = 'BSCS'
GROUP BY S.MajorCode;

-- 3.8.9 (Corrected Part 2)
-- GPA summary for students enrolled in a specific class
-- Example: COP3514.001 (Term 2025FA, CRN 92001)

SELECT
    E.TermCode,
    E.CRN,
    COUNT(*) AS TotalStudents,
    AVG(S.GPA) AS AverageGPA,
    MAX(S.GPA) AS HighestGPA,
    MIN(S.GPA) AS LowestGPA
FROM Bellini.Enrollment E
JOIN Bellini.Student S
    ON E.StudentNumber = S.StudentNumber
WHERE E.TermCode = '2025FA'
  AND E.CRN = 92001
  AND S.GPA IS NOT NULL     -- ensures valid GPA
GROUP BY E.TermCode, E.CRN;

-- 3.8.10
-- What-if GPA analysis for student:
--   U00000004, current Spring 2026 enrollment
-- Scenario A: all current registered courses receive grade A
-- Scenario B: CRN = 93003 receives grade F, all others receive A

SELECT
    S.StudentNumber,
    S.EarnedHours AS CurrentEarnedHours,
    S.GPA AS CurrentGPA,

    -- Total credits of current in-progress courses
    ISNULL(X.InProgressCredits, 0) AS InProgressCredits,

    -- Scenario A: All A
    CASE 
        WHEN S.EarnedHours + ISNULL(X.InProgressCredits, 0) = 0 
            THEN S.GPA
        ELSE 
            (S.GPA * S.EarnedHours 
                + ISNULL(X.InProgressCredits, 0) * 4.0)  -- A = 4.0 GPA
            / (S.EarnedHours + ISNULL(X.InProgressCredits, 0))
    END AS WhatIf_All_A_GPA,

    -- Scenario B: Course CRN 93003 = F, others = A
    CASE 
        WHEN S.EarnedHours 
             + ISNULL(Y.CreditsAsA, 0) 
             + ISNULL(Y.CreditsAsF, 0) = 0
            THEN S.GPA
        ELSE
            (S.GPA * S.EarnedHours
              + ISNULL(Y.CreditsAsA, 0) * 4.0   -- A
              + ISNULL(Y.CreditsAsF, 0) * 0.0)  -- F
            / (S.EarnedHours 
                + ISNULL(Y.CreditsAsA, 0) 
                + ISNULL(Y.CreditsAsF, 0))
    END AS WhatIf_One_F_GPA

FROM Bellini.Student S

-- Calculate total credits currently "enrolled" this term
LEFT JOIN (
    SELECT
        E.StudentNumber,
        SUM(C.CreditHours) AS InProgressCredits
    FROM Bellini.Enrollment E
    JOIN Bellini.ClassSection CS
        ON E.TermCode = CS.TermCode
       AND E.CRN = CS.CRN
    JOIN Bellini.Course C
        ON CS.CoursePrefix = C.CoursePrefix
       AND CS.CourseNumber = C.CourseNumber
    WHERE E.TermCode = '2026SP'
      AND E.EnrollmentStatus = 'Enrolled'
    GROUP BY E.StudentNumber
) X
    ON S.StudentNumber = X.StudentNumber

-- Separate credits where CRN = 93003 (fail) and others (pass with A)
LEFT JOIN (
    SELECT
        E.StudentNumber,
        SUM(CASE WHEN E.CRN = 93003 THEN C.CreditHours ELSE 0 END) AS CreditsAsF,
        SUM(CASE WHEN E.CRN <> 93003 THEN C.CreditHours ELSE 0 END) AS CreditsAsA
    FROM Bellini.Enrollment E
    JOIN Bellini.ClassSection CS
        ON E.TermCode = CS.TermCode
       AND E.CRN = CS.CRN
    JOIN Bellini.Course C
        ON CS.CoursePrefix = C.CoursePrefix
       AND CS.CourseNumber = C.CourseNumber
    WHERE E.TermCode = '2026SP'
      AND E.EnrollmentStatus = 'Enrolled'
    GROUP BY E.StudentNumber
) Y
    ON S.StudentNumber = Y.StudentNumber

WHERE S.StudentNumber = 'U00000004';

-- 3.8.11
-- (a) Semester transcript
SELECT 
    E.StudentNumber,
    T.TermName,
    CS.CRN,
    C.CoursePrefix,
    C.CourseNumber,
    C.CourseTitle,
    C.CreditHours,
    E.GradeLetter,
    E.FinalScore,
    G.GPAValue AS GradeGPA
FROM Bellini.Enrollment E
JOIN Bellini.ClassSection CS
    ON E.TermCode = CS.TermCode AND E.CRN = CS.CRN
JOIN Bellini.Course C
    ON CS.CoursePrefix = C.CoursePrefix AND CS.CourseNumber = C.CourseNumber
JOIN Bellini.Term T
    ON CS.TermCode = T.TermCode
LEFT JOIN Bellini.Grade G
    ON E.GradeLetter = G.GradeLetter
WHERE E.StudentNumber = 'U00000004'
  AND E.TermCode = '2025FA'    -- change this for another semester
  AND E.EnrollmentStatus = 'Completed'
ORDER BY CS.CoursePrefix, CS.CourseNumber;

-----------------------------------------------------------

-- (b) Overall transcript (incl. GPA summary)
SELECT 
    E.StudentNumber,
    COUNT(*) AS TotalCoursesCompleted,
    SUM(C.CreditHours) AS TotalCreditsCompleted,
    AVG(G.GPAValue) AS AverageGPA,
    MIN(G.GPAValue) AS LowestGPA,
    MAX(G.GPAValue) AS HighestGPA
FROM Bellini.Enrollment E
JOIN Bellini.ClassSection CS
    ON E.TermCode = CS.TermCode AND E.CRN = CS.CRN
JOIN Bellini.Course C
    ON CS.CoursePrefix = C.CoursePrefix AND CS.CourseNumber = C.CourseNumber
LEFT JOIN Bellini.Grade G
    ON E.GradeLetter = G.GradeLetter
WHERE E.StudentNumber = 'U00000004'
  AND E.EnrollmentStatus = 'Completed'
  AND E.GradeLetter IS NOT NULL
GROUP BY E.StudentNumber;


-- 3.8.12 - Course Registration & Weekly Class Schedule
-- Example: Student U00000004 attempts to register CNT 4403 (93004) in 2026SP

-- 3.8.12: Course registration attempt and weekly class schedule
-- Student: U00000004 requesting to register CRN 93004 in term 2026SP

-- Check if already registered (inform user accordingly)
SELECT 
    'U00000004' AS StudentNumber,
    '2026SP' AS TermCode,
    93004 AS CRN,
    CASE 
        WHEN EXISTS (
            SELECT 1
            FROM Bellini.Enrollment
            WHERE StudentNumber = 'U00000004'
              AND TermCode = '2026SP'
              AND CRN = 93004
        ) THEN 'Registration rejected: already registered for this class.'
        ELSE 'Registration allowed.'
    END AS RegistrationStatus;

-- If registration allowed (not in this case), then:
-- INSERT INTO Bellini.Enrollment (StudentNumber, TermCode, CRN, GradeLetter, RegisterDate, EnrollmentStatus, FinalScore)
-- VALUES ('U00000004', '2026SP', 93004, NULL, GETDATE(), 'Enrolled', NULL);
-- UPDATE Bellini.ClassSection SET EnrollmentCount = EnrollmentCount + 1
-- WHERE TermCode = '2026SP' AND CRN = 93004;

-- Show weekly schedule (existing registered courses)
SELECT
    E.StudentNumber,
    CS.TermCode,
    CS.CRN,
    CS.CoursePrefix,
    CS.CourseNumber,
    C.CourseTitle,
    CS.Schedule,
    CS.Location
FROM Bellini.Enrollment E
JOIN Bellini.ClassSection CS
    ON E.TermCode = CS.TermCode 
   AND E.CRN = CS.CRN
JOIN Bellini.Course C
    ON CS.CoursePrefix = C.CoursePrefix
   AND CS.CourseNumber = C.CourseNumber
WHERE E.StudentNumber = 'U00000004'
  AND E.TermCode = '2026SP'
ORDER BY CS.Schedule;

------------------------------------------------------------
-- 3.8.13 Drop Course Request with Validation
------------------------------------------------------------

DECLARE @StudentNumber CHAR(9) = 'U00000004';
DECLARE @TermCode      CHAR(6) = '2026SP';
DECLARE @CRN           INT     = 93001;  -- COP 3514 (valid drop)

-- 1?? Check if the student is registered in the class
IF EXISTS (
    SELECT 1
    FROM Bellini.Enrollment
    WHERE StudentNumber = @StudentNumber
      AND TermCode = @TermCode
      AND CRN = @CRN
)
BEGIN
    -- Drop course
    DELETE FROM Bellini.Enrollment
    WHERE StudentNumber = @StudentNumber
      AND TermCode = @TermCode
      AND CRN = @CRN;

    -- Update enrollment count in section
    UPDATE Bellini.ClassSection
    SET EnrollmentCount = EnrollmentCount - 1
    WHERE TermCode = @TermCode AND CRN = @CRN;

    PRINT CONCAT(@StudentNumber, ' successfully dropped class ', @CRN, '.');
END
ELSE
BEGIN
    PRINT CONCAT(@StudentNumber, ' drop rejected: not registered in class ', @CRN, '.');
END;

------------------------------------------------------------
-- 2?? Display Updated Schedule After Drop
------------------------------------------------------------
SELECT E.StudentNumber, E.TermCode, E.CRN, C.CoursePrefix, C.CourseNumber,
       C.CourseTitle, CS.Schedule, CS.Location
FROM Bellini.Enrollment E
JOIN Bellini.ClassSection CS ON E.CRN = CS.CRN AND E.TermCode = CS.TermCode
JOIN Bellini.Course C ON CS.CoursePrefix = C.CoursePrefix AND CS.CourseNumber = C.CourseNumber
WHERE E.StudentNumber = @StudentNumber AND E.TermCode = @TermCode;

------------------------------------------------------------
-- 3?? Invalid Drop Test (course not registered)
------------------------------------------------------------
DECLARE @InvalidCRN INT = 93099; -- invalid example

IF NOT EXISTS (
    SELECT 1
    FROM Bellini.Enrollment
    WHERE StudentNumber = @StudentNumber
      AND TermCode = @TermCode
      AND CRN = @InvalidCRN
)
BEGIN
    PRINT CONCAT(@StudentNumber, ' drop rejected: not registered in class ', @InvalidCRN, '.');
END;

------------------------------------------------------------
-- 3.8.14 Instructor Updates Grades (Fall 2025)
-- Assume instructor assigns new grades.
------------------------------------------------------------

-- Example: Update grades for CDA 3103 (CRN 92007 � InstructorID = 4)
UPDATE Bellini.Enrollment
SET GradeLetter = 'A', FinalScore = 95.0
WHERE TermCode = '2025FA' AND CRN = 92007 AND StudentNumber = 'U00000003';

UPDATE Bellini.Enrollment
SET GradeLetter = 'B+', FinalScore = 88.0
WHERE TermCode = '2025FA' AND CRN = 92007 AND StudentNumber = 'U00000012';

UPDATE Bellini.Enrollment
SET GradeLetter = 'C', FinalScore = 75.0
WHERE TermCode = '2025FA' AND CRN = 92007 AND StudentNumber = 'U00000001';

-- Example: Update grade for COP 3514.001 (CRN 92001 � InstructorID = 1)
UPDATE Bellini.Enrollment
SET GradeLetter = 'A-', FinalScore = 90.0
WHERE TermCode = '2025FA' AND CRN = 92001 AND StudentNumber = 'U00000003';

------------------------------------------------------------
-- Display updated grade data for proof
------------------------------------------------------------
SELECT E.StudentNumber, E.TermCode, E.CRN, E.GradeLetter, E.FinalScore,
       C.CoursePrefix, C.CourseNumber, C.CourseTitle
FROM Bellini.Enrollment E
JOIN Bellini.ClassSection CS ON E.CRN = CS.CRN AND E.TermCode = CS.TermCode
JOIN Bellini.Course C ON CS.CoursePrefix = C.CoursePrefix AND CS.CourseNumber = C.CourseNumber
WHERE E.TermCode = '2025FA' 
  AND (E.CRN = 92007 OR E.CRN = 92001);

------------------------------------------------------------
-- 3.8.15: Class roster with student details
------------------------------------------------------------
SELECT 
    CS.TermCode,
    CS.CRN,
    CS.CoursePrefix,
    CS.CourseNumber,
    C.CourseTitle,
    CS.Schedule,
    CS.Location,
    CS.Capacity,
    CS.EnrollmentCount,
    CS.Status,
    CS.InstructorID,
    I.FirstName + ' ' + I.LastName AS InstructorName,
    E.StudentNumber,
    S.FirstName + ' ' + S.LastName AS StudentName,
    S.MajorCode,
    S.EarnedHours,
    S.GPA
FROM Bellini.ClassSection CS
JOIN Bellini.Course C
    ON CS.CoursePrefix = C.CoursePrefix AND CS.CourseNumber = C.CourseNumber
LEFT JOIN Bellini.Instructor I
    ON CS.InstructorID = I.InstructorID
LEFT JOIN Bellini.Enrollment E
    ON CS.TermCode = E.TermCode AND CS.CRN = E.CRN
LEFT JOIN Bellini.Student S
    ON E.StudentNumber = S.StudentNumber
WHERE CS.TermCode IN ('2025FA', '2026SP')
ORDER BY CS.TermCode, CS.CRN, E.StudentNumber;


------------------------------------------------------------
-- 3.8.16: Grade distribution for Fall 2025 class
------------------------------------------------------------
SELECT
    E.TermCode,
    E.CRN,
    C.CoursePrefix,
    C.CourseNumber,
    COUNT(*) AS TotalEnrollment,
    AVG(E.FinalScore) AS AverageScore,
    MAX(E.FinalScore) AS HighestScore,
    MIN(E.FinalScore) AS LowestScore,
    SUM(CASE WHEN E.FinalScore >= 90 THEN 1 ELSE 0 END) AS ScoreAbove90,
    SUM(CASE WHEN E.FinalScore >= 80 AND E.FinalScore < 90 THEN 1 ELSE 0 END) AS Score80to90,
    SUM(CASE WHEN E.FinalScore >= 70 AND E.FinalScore < 80 THEN 1 ELSE 0 END) AS Score70to80,
    SUM(CASE WHEN E.FinalScore >= 60 AND E.FinalScore < 70 THEN 1 ELSE 0 END) AS Score60to70,
    SUM(CASE WHEN E.FinalScore < 60 THEN 1 ELSE 0 END) AS ScoreBelow60
FROM Bellini.Enrollment E
JOIN Bellini.ClassSection CS 
    ON E.TermCode = CS.TermCode AND E.CRN = CS.CRN
JOIN Bellini.Course C 
    ON CS.CoursePrefix = C.CoursePrefix AND CS.CourseNumber = C.CourseNumber
WHERE E.TermCode = '2025FA'
  AND E.EnrollmentStatus = 'Completed'
GROUP BY E.TermCode, E.CRN, C.CoursePrefix, C.CourseNumber
ORDER BY C.CoursePrefix, C.CourseNumber;
