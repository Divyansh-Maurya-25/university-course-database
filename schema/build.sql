------------------------------------------------------------
-- DDL with Referential Integrity (No Data)
------------------------------------------------------------

CREATE DATABASE Pj2_09;
GO
USE Pj2_09;
GO

------------------------------------------------------------
-- 1. Create Schema (Bellini)
------------------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'Bellini')
    EXEC('CREATE SCHEMA Bellini');
GO

/* =========================================================
   TABLE: Major
========================================================= */
CREATE TABLE Bellini.Major (
    MajorCode      CHAR(5)       NOT NULL PRIMARY KEY,
    MajorName      NVARCHAR(100) NOT NULL,
    CatalogYearStart SMALLINT    NOT NULL,
    CatalogYearEnd   SMALLINT    NOT NULL
);

/* =========================================================
   TABLE: Term
========================================================= */
CREATE TABLE Bellini.Term (
    TermCode   CHAR(6)      NOT NULL PRIMARY KEY,
    TermName   NVARCHAR(20) NOT NULL,
    TermYear   INT          NOT NULL,
    Semester   NVARCHAR(10) NOT NULL
);

/* =========================================================
   TABLE: Course
========================================================= */
CREATE TABLE Bellini.Course (
    CoursePrefix     CHAR(4)       NOT NULL,
    CourseNumber     CHAR(5)       NOT NULL,  -- FIXED: Changed from CHAR(4) to CHAR(5)
    CourseTitle      NVARCHAR(200) NOT NULL,
    CreditHours      DECIMAL(3,1)  NOT NULL,
    CourseLevel      INT           NOT NULL,
    Description      NVARCHAR(MAX) NULL,
    PrerequisiteText NVARCHAR(400) NULL,
    CorequisiteText  NVARCHAR(400) NULL,
    CONSTRAINT PK_Course PRIMARY KEY (CoursePrefix, CourseNumber)
);

------------------------------------------------------------
-- Course PreReq 
------------------------------------------------------------
CREATE TABLE Bellini.CoursePreReq (
    CoursePrefix     CHAR(4) NOT NULL,
    CourseNumber     CHAR(5) NOT NULL,  
    PreCoursePrefix  CHAR(4) NOT NULL,
    PreCourseNumber  CHAR(5) NOT NULL,  
    CONSTRAINT PK_CoursePreReq PRIMARY KEY (CoursePrefix, CourseNumber, PreCoursePrefix, PreCourseNumber),
    CONSTRAINT FK_CoursePreReq_Course 
        FOREIGN KEY (CoursePrefix, CourseNumber)
        REFERENCES Bellini.Course(CoursePrefix, CourseNumber)
        ON UPDATE NO ACTION ON DELETE NO ACTION,  
    CONSTRAINT FK_CoursePreReq_PreCourse
        FOREIGN KEY (PreCoursePrefix, PreCourseNumber)
        REFERENCES Bellini.Course(CoursePrefix, CourseNumber)
        ON UPDATE NO ACTION ON DELETE NO ACTION 
);

------------------------------------------------------------
-- Course CoReq 
------------------------------------------------------------
CREATE TABLE Bellini.CourseCoReq (
    CoursePrefix   CHAR(4) NOT NULL,
    CourseNumber   CHAR(5) NOT NULL,  
    CoCoursePrefix CHAR(4) NOT NULL,
    CoCourseNumber CHAR(5) NOT NULL,  
    CONSTRAINT PK_CourseCoReq PRIMARY KEY (CoursePrefix, CourseNumber, CoCoursePrefix, CoCourseNumber),
    CONSTRAINT FK_CourseCoReq_Course 
        FOREIGN KEY (CoursePrefix, CourseNumber)
        REFERENCES Bellini.Course(CoursePrefix, CourseNumber)
        ON UPDATE NO ACTION ON DELETE NO ACTION, 
    CONSTRAINT FK_CourseCoReq_CoCourse
        FOREIGN KEY (CoCoursePrefix, CoCourseNumber)
        REFERENCES Bellini.Course(CoursePrefix, CourseNumber)
        ON UPDATE NO ACTION ON DELETE NO ACTION 
);

------------------------------------------------------------
-- MajorCourseRequirement
------------------------------------------------------------
CREATE TABLE Bellini.MajorCourseRequirement (
    MajorCode CHAR(5) NOT NULL,
    CoursePrefix CHAR(4) NOT NULL,
    CourseNumber CHAR(5) NOT NULL,  -- FIXED: Changed from CHAR(4) to CHAR(5)
    CatalogYear SMALLINT NOT NULL,
    RequirementType VARCHAR(20) NOT NULL CHECK (RequirementType IN ('core','elective','state-mandated')),
    MinGradeRequired CHAR(2) NULL,
    CONSTRAINT PK_MCR PRIMARY KEY (MajorCode, CoursePrefix, CourseNumber, CatalogYear),
    CONSTRAINT FK_MCR_Major FOREIGN KEY (MajorCode)
        REFERENCES Bellini.Major(MajorCode)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT FK_MCR_Course FOREIGN KEY (CoursePrefix, CourseNumber)
        REFERENCES Bellini.Course(CoursePrefix, CourseNumber)
        ON UPDATE CASCADE ON DELETE CASCADE
);

------------------------------------------------------------
-- StudyPlan
------------------------------------------------------------
CREATE TABLE Bellini.StudyPlan (
    MajorCode CHAR(5) NOT NULL,
    CatalogYear SMALLINT NOT NULL,
    PlanYear TINYINT NOT NULL,
    PlanTerm NVARCHAR(10) NOT NULL,
    SequenceInTerm TINYINT NOT NULL,
    CoursePrefix CHAR(4) NOT NULL,
    CourseNumber CHAR(5) NOT NULL,  
    CONSTRAINT PK_StudyPlan PRIMARY KEY (MajorCode, CatalogYear, PlanYear, PlanTerm, SequenceInTerm),
    CONSTRAINT FK_SP_Major FOREIGN KEY (MajorCode)
        REFERENCES Bellini.Major(MajorCode)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT FK_SP_Course FOREIGN KEY (CoursePrefix, CourseNumber)
        REFERENCES Bellini.Course(CoursePrefix, CourseNumber)
        ON UPDATE CASCADE ON DELETE CASCADE
);

------------------------------------------------------------
-- Instructor
------------------------------------------------------------
CREATE TABLE Bellini.Instructor (
    InstructorID INT IDENTITY(1,1) PRIMARY KEY,
    FirstName NVARCHAR(50) NOT NULL,
    LastName NVARCHAR(50) NOT NULL,
    Email NVARCHAR(100) NOT NULL,
    OfficeLocation NVARCHAR(100) NOT NULL,
    OfficeHours NVARCHAR(100) NOT NULL,
    Phone NVARCHAR(20) NULL
);

------------------------------------------------------------
-- Student 
------------------------------------------------------------
CREATE TABLE Bellini.Student (
    StudentNumber CHAR(9) NOT NULL PRIMARY KEY,
    FirstName NVARCHAR(50) NOT NULL,
    LastName NVARCHAR(50) NOT NULL,
    MajorCode CHAR(5) NOT NULL,
    CatalogYearStart SMALLINT NOT NULL,
    CatalogYearEnd SMALLINT NOT NULL,
    StartSemester NVARCHAR(10) NOT NULL,
    StartYear INT NOT NULL,
    Birthdate DATE NULL,
    Email NVARCHAR(100) NOT NULL,
    Phone NVARCHAR(20) NULL,
    Address NVARCHAR(200) NULL,
    EarnedHours DECIMAL(4,1) NOT NULL DEFAULT 0,
    GPA DECIMAL(3,2) NOT NULL DEFAULT 0,
    Standing NVARCHAR(20) NULL,
    CONSTRAINT FK_Student_Major FOREIGN KEY (MajorCode)
        REFERENCES Bellini.Major(MajorCode)
        ON UPDATE CASCADE ON DELETE CASCADE
);

------------------------------------------------------------
-- MajorChange
------------------------------------------------------------
CREATE TABLE Bellini.MajorChange (
    StudentNumber CHAR(9) NOT NULL,
    OldMajorCode CHAR(5) NOT NULL,
    NewMajorCode CHAR(5) NOT NULL,
    ChangeDate DATE NOT NULL,
    TermCode CHAR(6) NOT NULL,
    CatalogYearAtChange SMALLINT NOT NULL,
    CONSTRAINT PK_MajorChange PRIMARY KEY (StudentNumber, ChangeDate),
    CONSTRAINT FK_MC_Student FOREIGN KEY (StudentNumber)
        REFERENCES Bellini.Student(StudentNumber)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT FK_MC_OldMajor FOREIGN KEY (OldMajorCode)
        REFERENCES Bellini.Major(MajorCode)
        ON UPDATE NO ACTION ON DELETE NO ACTION,
    CONSTRAINT FK_MC_NewMajor FOREIGN KEY (NewMajorCode)
        REFERENCES Bellini.Major(MajorCode)
        ON UPDATE NO ACTION ON DELETE NO ACTION,
    CONSTRAINT FK_MC_Term FOREIGN KEY (TermCode)
        REFERENCES Bellini.Term(TermCode)
        ON UPDATE CASCADE ON DELETE CASCADE
);

------------------------------------------------------------
-- Grade
------------------------------------------------------------
CREATE TABLE Bellini.Grade (
    GradeLetter CHAR(2) NOT NULL PRIMARY KEY,
    GPAValue DECIMAL(3,2) NULL,  
    MinPercentage TINYINT NULL     
);

------------------------------------------------------------
-- ClassSection
------------------------------------------------------------
CREATE TABLE Bellini.ClassSection (
    TermCode CHAR(6) NOT NULL,
    CRN INT NOT NULL,
    CoursePrefix CHAR(4) NOT NULL,
    CourseNumber CHAR(5) NOT NULL,  
    SectionNumber VARCHAR(3) NOT NULL,
    InstructorID INT NULL,
    Schedule NVARCHAR(100) NOT NULL,
    Location NVARCHAR(100) NOT NULL,
    ClassType VARCHAR(20) NOT NULL CHECK (ClassType IN ('Lecture','Lab','Other')),
    Capacity INT NOT NULL,
    EnrollmentCount INT NOT NULL,
    Status VARCHAR(10) NOT NULL CHECK (Status IN ('Open','Closed')),
    CONSTRAINT PK_ClassSection PRIMARY KEY (TermCode, CRN),
    CONSTRAINT FK_CS_Term FOREIGN KEY (TermCode)
        REFERENCES Bellini.Term(TermCode)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT FK_CS_Course FOREIGN KEY (CoursePrefix, CourseNumber)
        REFERENCES Bellini.Course(CoursePrefix, CourseNumber)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT FK_CS_Instructor FOREIGN KEY (InstructorID)
        REFERENCES Bellini.Instructor(InstructorID)
        ON UPDATE CASCADE ON DELETE SET NULL
);

------------------------------------------------------------
-- TA_Assignment
------------------------------------------------------------
CREATE TABLE Bellini.TA_Assignment (
    StudentNumber CHAR(9) NOT NULL,
    TermCode CHAR(6) NOT NULL,
    CRN INT NOT NULL,
    CONSTRAINT PK_TA_Assignment PRIMARY KEY (StudentNumber, TermCode, CRN),
    CONSTRAINT FK_TA_Student FOREIGN KEY (StudentNumber)
        REFERENCES Bellini.Student(StudentNumber)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT FK_TA_Section FOREIGN KEY (TermCode, CRN)
        REFERENCES Bellini.ClassSection(TermCode, CRN)
        ON UPDATE CASCADE ON DELETE CASCADE
);

------------------------------------------------------------
-- Enrollment
------------------------------------------------------------
CREATE TABLE Bellini.Enrollment (
    StudentNumber CHAR(9) NOT NULL,
    TermCode CHAR(6) NOT NULL,
    CRN INT NOT NULL,
    GradeLetter CHAR(2) NULL,
    RegisterDate DATE NOT NULL,
    EnrollmentStatus NVARCHAR(20) NOT NULL,
    FinalScore DECIMAL(5,2) NULL,
    CONSTRAINT PK_Enrollment PRIMARY KEY (StudentNumber, TermCode, CRN),
    CONSTRAINT FK_ENR_Student FOREIGN KEY (StudentNumber)
        REFERENCES Bellini.Student(StudentNumber)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT FK_ENR_Section FOREIGN KEY (TermCode, CRN)
        REFERENCES Bellini.ClassSection(TermCode, CRN)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT FK_ENR_Grade FOREIGN KEY (GradeLetter)
        REFERENCES Bellini.Grade(GradeLetter)
        ON UPDATE CASCADE ON DELETE SET NULL
);
GO

------------------------------------------------------------
--  SEED DATA RESET + CORE ENTITY INSERTS
------------------------------------------------------------


IF OBJECT_ID('Bellini.Enrollment', 'U') IS NOT NULL DELETE FROM Bellini.Enrollment;
IF OBJECT_ID('Bellini.TA_Assignment', 'U') IS NOT NULL DELETE FROM Bellini.TA_Assignment;
IF OBJECT_ID('Bellini.ClassSection', 'U') IS NOT NULL DELETE FROM Bellini.ClassSection;
IF OBJECT_ID('Bellini.MajorChange', 'U') IS NOT NULL DELETE FROM Bellini.MajorChange;
IF OBJECT_ID('Bellini.Student', 'U') IS NOT NULL DELETE FROM Bellini.Student;
IF OBJECT_ID('Bellini.StudyPlan', 'U') IS NOT NULL DELETE FROM Bellini.StudyPlan;
IF OBJECT_ID('Bellini.MajorCourseRequirement', 'U') IS NOT NULL DELETE FROM Bellini.MajorCourseRequirement;
IF OBJECT_ID('Bellini.CourseCoReq', 'U') IS NOT NULL DELETE FROM Bellini.CourseCoReq;
IF OBJECT_ID('Bellini.CoursePreReq', 'U') IS NOT NULL DELETE FROM Bellini.CoursePreReq;
IF OBJECT_ID('Bellini.Course', 'U') IS NOT NULL DELETE FROM Bellini.Course;
IF OBJECT_ID('Bellini.Instructor', 'U') IS NOT NULL DELETE FROM Bellini.Instructor;
IF OBJECT_ID('Bellini.Grade', 'U') IS NOT NULL DELETE FROM Bellini.Grade;
IF OBJECT_ID('Bellini.Term', 'U') IS NOT NULL DELETE FROM Bellini.Term;
IF OBJECT_ID('Bellini.Major', 'U') IS NOT NULL DELETE FROM Bellini.Major;
GO

------------------------------------------------------------
-- Insert Majors
------------------------------------------------------------
INSERT INTO Bellini.Major
(MajorCode, MajorName, CatalogYearStart, CatalogYearEnd)
VALUES
 ('BSCS','B.S. Computer Science',2023,2024),
 ('BSCP','B.S. Computer Engineering',2023,2024),
 ('BSIT','B.S. Information Technology',2023,2024),
 ('BSCyS','B.S. Cybersecurity',2023,2024);

------------------------------------------------------------
-- Insert Terms
------------------------------------------------------------
INSERT INTO Bellini.Term
(TermCode, TermName, TermYear, Semester)
VALUES
 ('2023FA','Fall 2023',2023,'Fall'),
 ('2024SP','Spring 2024',2024,'Spring'),
 ('2024FA','Fall 2024',2024,'Fall'),
 ('2025SP','Spring 2025',2025,'Spring'),
 ('2025FA','Fall 2025',2025,'Fall'),
 ('2026SP','Spring 2026',2026,'Spring');

------------------------------------------------------------
-- Insert Grade Table EARLY (needed before Students)
------------------------------------------------------------
INSERT INTO Bellini.Grade (GradeLetter, GPAValue, MinPercentage)
VALUES
 ('A', 4.00, 90),
 ('A-', 3.67, 87),
 ('B+', 3.33, 84),
 ('B', 3.00, 80),
 ('B-', 2.67, 77),
 ('C+', 2.33, 74),
 ('C', 2.00, 70),
 ('D+', 1.33, 67),
 ('D', 1.00, 60),
 ('F', 0.00, 0),
 ('IP', NULL, NULL),
 ('W', NULL, NULL);

------------------------------------------------------------
-- Insert Instructors EARLY (needed before ClassSection)
------------------------------------------------------------
INSERT INTO Bellini.Instructor
(FirstName, LastName, Email, OfficeLocation, OfficeHours, Phone)
VALUES
 ('Utkarsh','Ojha','uojha@usf.edu','ENG 300','MW 2:00-4:00 PM','813-974-0001'),
 ('Grace','Bayliss','gbayliss@usf.edu','ENG 310','TR 10:00-12:00 PM','813-974-0002'),
 ('Maria','Lopez','mlopez@usf.edu','ENG 320','MW 9:00-11:00 AM','813-974-0003'),
 ('David','Chen','dchen@usf.edu','ENG 330','TR 1:00-3:00 PM','813-974-0004');

------------------------------------------------------------
-- Insert Courses
------------------------------------------------------------
INSERT INTO Bellini.Course
(CoursePrefix, CourseNumber, CourseTitle, CreditHours, CourseLevel, Description, PrerequisiteText, CorequisiteText)
VALUES
 -- BSCS & BSCP Core
 ('COP','2510 ','Programming Concepts',3,2000,'Introductory programming.','MAC 2281 or MAC 2311',NULL),
 ('COP','3514 ','Program Design',3,3000,'Intermediate programming.','COP 2510',NULL),
 ('COP','4530 ','Data Structures',3,4000,'DS + algorithms.','COP 3514, CDA 3103, COT 3100',NULL),
 ('COT','3100 ','Discrete Structures',3,3000,'Logic, sets, proof.','MAC 2281 or MAC 2311',NULL),
 ('COT','4400 ','Analysis of Algorithms',3,4000,'Algorithmic complexity.','COT 3100 AND COP 4530',NULL),
 ('CDA','3103 ','Computer Organization',3,3000,'Architecture fundamentals.','COP 2510 AND PHY 2048',NULL),
 ('CDA','3201 ','Logic and Design',3,3000,'Digital circuits.','CDA 3103 AND COP 3514','CDA 3201L'),
 ('CDA','3201L','Logic and Design Lab',1,3000,'Lab course.',NULL,NULL),
 ('CIS','4250 ','Ethics & Professional Conduct',3,4000,'Computing ethics.','Senior standing',NULL),
 ('EGN','3000 ','Foundations of Engineering',3,3000,'Engineering intro.',NULL,NULL),
 ('EGN','3443 ','Probability & Statistics',3,3000,'Stats with applications.','MAC 2282 or MAC 2312',NULL),
 ('MAC','2281 ','Engineering Calculus I',4,2000,'Calculus for engineers.',NULL,NULL),
 ('MAC','2311 ','Calculus I',4,2000,'Calculus course.',NULL,NULL),
 ('MAC','2282 ','Engineering Calculus II',4,2000,'Continuation of Calculus I.',NULL,NULL),
 ('MAC','2312 ','Calculus II',4,2000,'Advanced calculus topics.',NULL,NULL),
 ('PHY','2048 ','General Physics I',3,2000,'Mechanics.','MAC 2281 or MAC 2311','PHY 2048L'),
 ('PHY','2048L','Physics I Lab',1,2000,'Lab component.',NULL,NULL),
 ('ENC','1101 ','Composition I',3,1000,'Academic writing.',NULL,NULL),
 ('ENC','1102 ','Composition II',3,1000,'Research writing.','ENC 1101',NULL),
 ('ENC','3246 ','Communication for Engineers',3,3000,'Technical writing.','ENC 1102',NULL),

 -- BSIT & BSCyS Core
 ('STA','2023 ','Statistics I',3,2000,'Intro to statistics.',NULL,NULL),
 ('MAD','2104 ','Discrete Math',3,2000,'Discrete math basics.',NULL,NULL),
 ('PHY','2020 ','Conceptual Physics',3,2000,'Non-calculus physics.',NULL,NULL),
 ('MAC','1105 ','College Algebra',3,1000,'Algebra basics.',NULL,NULL),
 ('MAC','1147 ','Precalculus',4,1000,'Prep for calculus.','MAC 1105',NULL),
 ('PSY','2012 ','Psychological Science',3,2000,'Psychology concepts.',NULL,NULL),
 ('ECO','2013 ','Macroeconomics',3,2000,'Economic principles.',NULL,NULL),
 ('CGS','1540 ','Databases for IT',3,1000,'Database fundamentals.',NULL,NULL),
 ('CGS','3303 ','IT Concepts',3,3000,'IT fundamentals.',NULL,NULL),
 ('CGS','3853 ','Web Systems',3,3000,'Web technologies.','COP 2512',NULL),
 ('CIS','3213 ','Foundations of Cybersecurity',3,3000,'Security principles.','COP 2512',NULL),
 ('CIS','3363 ','IT Systems Security',3,3000,'System-level security.','CIS 3213',NULL),
 ('CIS','4622 ','Hands-on Cybersecurity',3,4000,'Practical cybersecurity.','CIS 3213 AND CNT 4403',NULL),
 ('CIS','4253 ','Ethics for IT',3,4000,'Ethics in IT.',NULL,NULL),
 ('LIS','4414 ','Information Policy & Ethics',3,4000,'Privacy, access.',NULL,NULL),
 ('ISM','4323 ','IT Risk Management',3,4000,'Risk analysis.', 'CIS 3213',NULL),

 -- IT Programming & Networking
 ('COP','2512 ','Programming Fundamentals',3,2000,'Intro programming.',NULL,NULL),
 ('COP','2513 ','OOP for IT',3,2000,'Object-Oriented Programming.','COP 2512',NULL),
 ('COP','3515 ','Advanced Programming',3,3000,'Advanced techniques.','COP 2513',NULL),
 ('COP','4538 ','Data Structures for IT',3,4000,'Algorithms and DS.','COP 3515',NULL),
 ('CNT','4104 ','IT Networks',3,4000,'Networking basics.','COP 2513',NULL),
 ('CNT','4403 ','Network Security',3,4000,'Network defense.','CNT 4104 AND CIS 3213',NULL);

 ------------------------------------------------------------
-- Course Prerequisites 
------------------------------------------------------------
INSERT INTO Bellini.CoursePreReq
(CoursePrefix, CourseNumber, PreCoursePrefix, PreCourseNumber)
VALUES
 -- Programming sequence
 ('COP','3514 ','COP','2510'),
 ('COP','4530 ','COP','3514'),
 ('COP','4530 ','CDA','3103'),
 ('COP','4530 ','COT','3100'),
 
 -- IT Programming sequence
 ('COP','2513 ','COP','2512'),
 ('COP','3515 ','COP','2513'),
 ('COP','4538 ','COP','3515'),
 
 -- Computer Engineering/Organization
 ('CDA','3201 ','CDA','3103'),
 ('CDA','3201 ','COP','3514'),
 ('CDA','3103 ','COP','2510'),
 ('CDA','3103 ','PHY','2048'),
 
 -- Algorithms
 ('COT','4400 ','COT','3100'),
 ('COT','4400 ','COP','4530'),
 
 -- Networking & Security
 ('CNT','4104 ','COP','2513'),
 ('CNT','4403 ','CNT','4104'),
 ('CNT','4403 ','CIS','3213'),
 
 -- Cybersecurity sequence
 ('CIS','3213 ','COP','2512'),
 ('CIS','3363 ','CIS','3213'),
 ('CIS','4622 ','CIS','3213'),
 ('CIS','4622 ','CNT','4403'),

 -- Additional Cybersecurity logic
 ('CIS','4622 ','CGS','3303'),
 
 -- IT courses
 ('CGS','3853 ','COP','2512'),
 ('ISM','4323 ','CIS','3213'),

 -- Statistics sequence
 ('STA','2023 ','MAC','1105'),
 
 -- Writing sequence
 ('ENC','1102 ','ENC','1101'),
 ('ENC','3246 ','ENC','1102'),

 -- Engineering prerequisites
 ('EGN','3000 ','MAC','2281'),

 -- Math prerequisites
 ('EGN','3443 ','MAC','2282'),
 ('MAC','1147 ','MAC','1105'),

 -- Physics alternate pathway
 ('PHY','2048 ','MAC','2311');


------------------------------------------------------------
-- Course Corequisites 
------------------------------------------------------------
INSERT INTO Bellini.CourseCoReq
(CoursePrefix, CourseNumber, CoCoursePrefix, CoCourseNumber)
VALUES
 ('PHY','2048 ','PHY','2048L'),
 ('PHY','2048L','PHY','2048'),
 ('CDA','3201 ','CDA','3201L');



------------------------------------------------------------
-- MajorCourseRequirement + StudyPlan + Instructor
------------------------------------------------------------

------------------------------------------------------------
-- 1. Major Course Requirements (2023 Catalog)
------------------------------------------------------------
INSERT INTO Bellini.MajorCourseRequirement
(MajorCode, CoursePrefix, CourseNumber, CatalogYear, RequirementType, MinGradeRequired)
VALUES
 -- === BSCS ===
 ('BSCS','MAC','2281 ',2023,'state-mandated','C'),
 ('BSCS','MAC','2282 ',2023,'state-mandated','C'),
 ('BSCS','COP','2510 ',2023,'core','B'),
 ('BSCS','COP','3514 ',2023,'core','B'),
 ('BSCS','COP','4530 ',2023,'core',NULL),
 ('BSCS','COT','3100 ',2023,'core',NULL),
 ('BSCS','COT','4400 ',2023,'core',NULL),
 ('BSCS','CDA','3103 ',2023,'core','B'),
 ('BSCS','CDA','3201 ',2023,'core',NULL),
 ('BSCS','CIS','4250 ',2023,'core',NULL),
 ('BSCS','EGN','3000 ',2023,'core',NULL),
 ('BSCS','EGN','3443 ',2023,'core',NULL),
 ('BSCS','PHY','2048 ',2023,'core','C'),
 ('BSCS','ENC','1101 ',2023,'core',NULL),
 ('BSCS','ENC','1102 ',2023,'core',NULL),
 ('BSCS','ENC','3246 ',2023,'core',NULL),

 -- === BSCP ===
 ('BSCP','MAC','2281 ',2023,'state-mandated','C'),
 ('BSCP','MAC','2282 ',2023,'state-mandated','C'),
 ('BSCP','COP','2510 ',2023,'core','B'),
 ('BSCP','COP','3514 ',2023,'core','B'),
 ('BSCP','COP','4530 ',2023,'core',NULL),
 ('BSCP','COT','3100 ',2023,'core',NULL),
 ('BSCP','COT','4400 ',2023,'core',NULL),
 ('BSCP','CDA','3103 ',2023,'core','B'),
 ('BSCP','CDA','3201 ',2023,'core',NULL),
 ('BSCP','CIS','4250 ',2023,'core',NULL),
 ('BSCP','EGN','3000 ',2023,'core',NULL),
 ('BSCP','EGN','3443 ',2023,'core',NULL),
 ('BSCP','PHY','2048 ',2023,'core','C'),
 ('BSCP','ENC','1101 ',2023,'core',NULL),
 ('BSCP','ENC','1102 ',2023,'core',NULL),
 ('BSCP','ENC','3246 ',2023,'core',NULL),

 -- === BSIT ===
 ('BSIT','STA','2023 ',2023,'state-mandated','C'),
 ('BSIT','MAC','1147 ',2023,'core','C'),
 ('BSIT','MAD','2104 ',2023,'core','C'),
 ('BSIT','PHY','2020 ',2023,'core','C'),
 ('BSIT','PSY','2012 ',2023,'core',NULL),
 ('BSIT','ECO','2013 ',2023,'core',NULL),
 ('BSIT','CGS','1540 ',2023,'core','B'),
 ('BSIT','CGS','3303 ',2023,'core',NULL),
 ('BSIT','CGS','3853 ',2023,'core',NULL),
 ('BSIT','CIS','3213 ',2023,'core',NULL),
 ('BSIT','CIS','3363 ',2023,'core',NULL),
 ('BSIT','CNT','4104 ',2023,'core',NULL),
 ('BSIT','CNT','4403 ',2023,'core',NULL),
 ('BSIT','COP','2512 ',2023,'core',NULL),
 ('BSIT','COP','2513 ',2023,'core',NULL),
 ('BSIT','COP','3515 ',2023,'core',NULL),
 ('BSIT','COP','4538 ',2023,'core',NULL),
 ('BSIT','CIS','4253 ',2023,'core',NULL),
 ('BSIT','LIS','4414 ',2023,'core',NULL),
 ('BSIT','ISM','4323 ',2023,'core',NULL),
 ('BSIT','ENC','1101 ',2023,'core',NULL),
 ('BSIT','ENC','1102 ',2023,'core',NULL),
 ('BSIT','ENC','3246 ',2023,'core',NULL),
 ('BSIT','COP','4530 ',2023,'elective',NULL),
 ('BSIT','COT','3100 ',2023,'elective',NULL),

 -- === BSCyS ===
 ('BSCyS','MAD','2104 ',2023,'core','C'),
 ('BSCyS','STA','2023 ',2023,'core','C'),
 ('BSCyS','PHY','2020 ',2023,'core','C'),
 ('BSCyS','MAC','1147 ',2023,'core','C'),
 ('BSCyS','PSY','2012 ',2023,'core',NULL),
 ('BSCyS','ECO','2013 ',2023,'core',NULL),
 ('BSCyS','EGN','3000 ',2023,'core',NULL),
 ('BSCyS','CGS','1540 ',2023,'core','B'),
 ('BSCyS','CGS','3303 ',2023,'core',NULL),
 ('BSCyS','CIS','3213 ',2023,'core',NULL),
 ('BSCyS','CIS','3363 ',2023,'core',NULL),
 ('BSCyS','CNT','4104 ',2023,'core',NULL),
 ('BSCyS','CNT','4403 ',2023,'core',NULL),
 ('BSCyS','CIS','4622 ',2023,'core',NULL),
 ('BSCyS','COP','2512 ',2023,'core',NULL),
 ('BSCyS','COP','2513 ',2023,'core',NULL),
 ('BSCyS','COP','3515 ',2023,'core',NULL),
 ('BSCyS','COP','4538 ',2023,'core',NULL),
 ('BSCyS','ENC','1101 ',2023,'core',NULL),
 ('BSCyS','ENC','1102 ',2023,'core',NULL),
 ('BSCyS','ENC','3246 ',2023,'core',NULL),
 ('BSCyS','ISM','4323 ',2023,'elective',NULL),
 ('BSCyS','LIS','4414 ',2023,'elective',NULL);


------------------------------------------------------------
-- 2. Study Plan (minimal valid sample)
------------------------------------------------------------
INSERT INTO Bellini.StudyPlan
(MajorCode, CatalogYear, PlanYear, PlanTerm, SequenceInTerm, CoursePrefix, CourseNumber)
VALUES
 
/* ========================== BSCS ========================== */
-- Year 1
('BSCS',2023,1,'Fall',1,'MAC','2281'),
('BSCS',2023,1,'Fall',2,'COP','2510'),
('BSCS',2023,1,'Fall',3,'ENC','1101'),

('BSCS',2023,1,'Spring',1,'MAC','2282'),
('BSCS',2023,1,'Spring',2,'COP','3514'),
('BSCS',2023,1,'Spring',3,'ENC','1102'),

-- Year 2
('BSCS',2023,2,'Fall',1,'CDA','3103'),
('BSCS',2023,2,'Fall',2,'COT','3100'),
('BSCS',2023,2,'Fall',3,'EGN','3000'),

('BSCS',2023,2,'Spring',1,'COP','4530'),
('BSCS',2023,2,'Spring',2,'EGN','3443'),
('BSCS',2023,2,'Spring',3,'CDA','3201'),

-- Year 3
('BSCS',2023,3,'Fall',1,'COT','4400'),
('BSCS',2023,3,'Fall',2,'CIS','4250'),
('BSCS',2023,3,'Fall',3,'PHY','2048'),

('BSCS',2023,3,'Spring',1,'PHY','2048L'),
('BSCS',2023,3,'Spring',2,'ENC','3246'),
('BSCS',2023,3,'Spring',3,'MAC','2312'),

-- Year 4
('BSCS',2023,4,'Fall',1,'COP','4530'),
('BSCS',2023,4,'Fall',2,'COT','4400'),
('BSCS',2023,4,'Fall',3,'EGN','3000'),

('BSCS',2023,4,'Spring',1,'CDA','3201L'),
('BSCS',2023,4,'Spring',2,'MAC','2282'),
('BSCS',2023,4,'Spring',3,'CDA','3103'),


/* ========================== BSCP ========================== */
-- Year 1
('BSCP',2023,1,'Fall',1,'MAC','2281'),
('BSCP',2023,1,'Fall',2,'COP','2510'),
('BSCP',2023,1,'Fall',3,'ENC','1101'),

('BSCP',2023,1,'Spring',1,'MAC','2282'),
('BSCP',2023,1,'Spring',2,'COP','3514'),
('BSCP',2023,1,'Spring',3,'ENC','1102'),

-- Year 2
('BSCP',2023,2,'Fall',1,'CDA','3103'),
('BSCP',2023,2,'Fall',2,'EGN','3000'),
('BSCP',2023,2,'Fall',3,'COT','3100'),

('BSCP',2023,2,'Spring',1,'CDA','3201'),
('BSCP',2023,2,'Spring',2,'EGN','3443'),
('BSCP',2023,2,'Spring',3,'CDA','3201L'),

-- Year 3
('BSCP',2023,3,'Fall',1,'COP','4530'),
('BSCP',2023,3,'Fall',2,'COT','4400'),
('BSCP',2023,3,'Fall',3,'PHY','2048'),

('BSCP',2023,3,'Spring',1,'PHY','2048L'),
('BSCP',2023,3,'Spring',2,'CIS','4250'),
('BSCP',2023,3,'Spring',3,'ENC','3246'),

-- Year 4
('BSCP',2023,4,'Fall',1,'EGN','3000'),
('BSCP',2023,4,'Fall',2,'COP','3514'),
('BSCP',2023,4,'Fall',3,'CDA','3103'),

('BSCP',2023,4,'Spring',1,'MAC','2312'),
('BSCP',2023,4,'Spring',2,'MAC','2282'),
('BSCP',2023,4,'Spring',3,'COT','4400'),


/* ========================== BSIT ========================== */
-- Year 1
('BSIT',2023,1,'Fall',1,'MAC','1105'),
('BSIT',2023,1,'Fall',2,'STA','2023'),
('BSIT',2023,1,'Fall',3,'ENC','1101'),

('BSIT',2023,1,'Spring',1,'MAD','2104'),
('BSIT',2023,1,'Spring',2,'MAC','1147'),
('BSIT',2023,1,'Spring',3,'ENC','1102'),

-- Year 2
('BSIT',2023,2,'Fall',1,'CGS','1540'),
('BSIT',2023,2,'Fall',2,'COP','2512'),
('BSIT',2023,2,'Fall',3,'PSY','2012'),

('BSIT',2023,2,'Spring',1,'COP','2513'),
('BSIT',2023,2,'Spring',2,'CGS','3303'),
('BSIT',2023,2,'Spring',3,'CIS','3213'),

-- Year 3
('BSIT',2023,3,'Fall',1,'COP','3515'),
('BSIT',2023,3,'Fall',2,'CGS','3853'),
('BSIT',2023,3,'Fall',3,'CIS','3363'),

('BSIT',2023,3,'Spring',1,'CNT','4104'),
('BSIT',2023,3,'Spring',2,'ISM','4323'),
('BSIT',2023,3,'Spring',3,'COP','4538'),

-- Year 4
('BSIT',2023,4,'Fall',1,'CNT','4403'),
('BSIT',2023,4,'Fall',2,'CIS','4253'),
('BSIT',2023,4,'Fall',3,'PSY','2012'),

('BSIT',2023,4,'Spring',1,'ECO','2013'),
('BSIT',2023,4,'Spring',2,'ENC','3246'),
('BSIT',2023,4,'Spring',3,'COP','4530');


------------------------------------------------------------
-- Includes: Student, MajorChange, ClassSection, 
--           TA_Assignment, Enrollment
------------------------------------------------------------

------------------------------------------------------------
-- 1. Students (20 hypothetical)
------------------------------------------------------------
INSERT INTO Bellini.Student
(StudentNumber, FirstName, LastName, MajorCode, CatalogYearStart, CatalogYearEnd,
 StartSemester, StartYear, Birthdate, Email, Phone, Address, EarnedHours, GPA, Standing)
VALUES
 ('U00000001','Alex','Johnson','BSCS',2023,2024,'Fall',2023,'2004-05-12','alex.johnson@usf.edu','813-555-0001','Tampa, FL',45.0,3.40,'Junior'),
 ('U00000002','Brianna','Smith','BSCS',2023,2024,'Fall',2023,'2004-01-21','brianna.smith@usf.edu','813-555-0002','Tampa, FL',60.0,3.75,'Junior'),
 ('U00000003','Caleb','Brown','BSCS',2023,2024,'Fall',2023,'2003-11-02','caleb.brown@usf.edu','813-555-0003','Tampa, FL',90.0,3.90,'Senior'),
 ('U00000004','Danielle','Nguyen','BSCS',2023,2024,'Spring',2024,'2004-08-16','danielle.nguyen@usf.edu','813-555-0004','Tampa, FL',30.0,3.10,'Sophomore'),
 ('U00000005','Ethan','Lewis','BSIT',2023,2024,'Fall',2023,'2004-03-03','ethan.lewis@usf.edu','813-555-0005','Tampa, FL',50.0,3.20,'Junior'),
 ('U00000006','Fatima','Ali','BSIT',2023,2024,'Fall',2023,'2004-09-09','fatima.ali@usf.edu','813-555-0006','Tampa, FL',35.0,3.00,'Sophomore'),
 ('U00000007','Gabriel','Miller','BSIT',2023,2024,'Spring',2024,'2004-10-14','gabriel.miller@usf.edu','813-555-0007','Tampa, FL',25.0,2.90,'Sophomore'),
 ('U00000008','Hannah','Wilson','BSIT',2023,2024,'Fall',2023,'2003-07-22','hannah.wilson@usf.edu','813-555-0008','Tampa, FL',80.0,3.60,'Senior'),
 ('U00000009','Ian','Garcia','BSCP',2023,2024,'Fall',2023,'2003-12-30','ian.garcia@usf.edu','813-555-0009','Tampa, FL',70.0,3.45,'Senior'),
 ('U00000010','Jasmine','Hall','BSCP',2023,2024,'Spring',2024,'2004-04-04','jasmine.hall@usf.edu','813-555-0010','Tampa, FL',28.0,3.05,'Sophomore'),
 ('U00000011','Kevin','Wright','BSCP',2023,2024,'Fall',2023,'2003-02-18','kevin.wright@usf.edu','813-555-0011','Tampa, FL',84.0,3.55,'Senior'),
 ('U00000012','Lily','Martinez','BSCS',2023,2024,'Fall',2023,'2004-06-11','lily.martinez@usf.edu','813-555-0012','Tampa, FL',55.0,3.30,'Junior'),
 ('U00000013','Marcus','Davis','BSCyS',2023,2024,'Fall',2023,'2004-09-27','marcus.davis@usf.edu','813-555-0013','Tampa, FL',40.0,3.15,'Junior'),
 ('U00000014','Natalie','Young','BSCyS',2023,2024,'Spring',2024,'2004-12-01','natalie.young@usf.edu','813-555-0014','Tampa, FL',20.0,3.00,'Sophomore'),
 ('U00000015','Owen','Perez','BSCyS',2023,2024,'Fall',2023,'2003-08-19','owen.perez@usf.edu','813-555-0015','Tampa, FL',75.0,3.65,'Senior'),
 ('U00000016','Priya','Shah','BSCyS',2023,2024,'Fall',2023,'2004-02-02','priya.shah@usf.edu','813-555-0016','Tampa, FL',32.0,3.25,'Sophomore'),
 ('U00000017','Quentin','Lee','BSCP',2023,2024,'Fall',2023,'2003-03-29','quentin.lee@usf.edu','813-555-0017','Tampa, FL',65.0,3.35,'Senior'),
 ('U00000018','Riley','Thomas','BSIT',2023,2024,'Fall',2023,'2003-11-07','riley.thomas@usf.edu','813-555-0018','Tampa, FL',85.0,3.80,'Senior'),
 ('U00000019','Sophia','Rivera','BSCS',2023,2024,'Fall',2023,'2003-01-13','sophia.rivera@usf.edu','813-555-0019','Tampa, FL',92.0,3.92,'Senior'),
 ('U00000020','Tyler','Baker','BSCyS',2023,2024,'Spring',2024,'2004-07-05','tyler.baker@usf.edu','813-555-0020','Tampa, FL',27.0,2.85,'Sophomore');

------------------------------------------------------------
-- 2. Major Change History
------------------------------------------------------------
INSERT INTO Bellini.MajorChange
(StudentNumber, OldMajorCode, NewMajorCode, ChangeDate, TermCode, CatalogYearAtChange)
VALUES
 ('U00000005','BSIT','BSCyS','2025-01-10','2025SP',2024),
 ('U00000012','BSCS','BSCP','2024-08-20','2024FA',2024),
 ('U00000017','BSCP','BSCS','2024-01-15','2024SP',2023);

------------------------------------------------------------
-- 3. ClassSection
------------------------------------------------------------
INSERT INTO Bellini.ClassSection
(TermCode, CRN, CoursePrefix, CourseNumber, SectionNumber, InstructorID, Schedule, Location,
 ClassType, Capacity, EnrollmentCount, Status)
VALUES
 -- Fall 2025
 ('2025FA',92001,'COP','3514 ','001',1,'MW 10:00-11:15','ENG 201','Lecture',40,1,'Open'),
 ('2025FA',92002,'CDA','3103 ','001',2,'TR 09:30-10:45','ENG 205','Lecture',35,0,'Open'),
 ('2025FA',92003,'COP','4530 ','001',3,'MW 13:00-14:15','ENG 204','Lecture',30,0,'Closed'),
 ('2025FA',92004,'CIS','3213 ','001',4,'TR 14:00-15:15','ENG 207','Lecture',30,0,'Open'),
 ('2025FA',92005,'COP','2510 ','002',2,'TR 14:00-15:15','ENG 103','Lecture',40,15,'Open'),
 ('2025FA',92006,'COT','3100 ','001',3,'MW 10:00-11:15','ENG 205','Lecture',35,12,'Open'),
 ('2025FA',92007,'CDA','3103 ','002',4,'TR 11:00-12:15','ENG 206','Lecture',30,10,'Closed'),
 ('2025FA',92008,'CGS','1540 ','001',1,'MW 13:00-14:15','LIB 120','Lecture',40,18,'Open'),

 -- Spring 2026
 ('2026SP',93001,'COP','3514 ','001',1,'MW 10:00-11:15','ENG 201','Lecture',40,0,'Open'),
 ('2026SP',93002,'COP','4530 ','001',3,'MW 13:00-14:15','ENG 204','Lecture',30,0,'Open'),
 ('2026SP',93003,'CIS','4622 ','001',4,'TR 16:00-18:00','CYB 310','Lab',25,0,'Open'),
 ('2026SP',93004,'CNT','4403 ','001',4,'TR 11:00-12:15','ENG 308','Lecture',25,0,'Open');

------------------------------------------------------------
-- 4. TA_Assignment
------------------------------------------------------------
INSERT INTO Bellini.TA_Assignment
(StudentNumber, TermCode, CRN)
VALUES
 ('U00000003','2025FA',92001),
 ('U00000019','2025FA',92001);

------------------------------------------------------------
-- 5. Enrollment
------------------------------------------------------------
INSERT INTO Bellini.Enrollment
(StudentNumber, TermCode, CRN, GradeLetter, RegisterDate, EnrollmentStatus, FinalScore)
VALUES
 ('U00000004','2025FA',92005,'A','2025-08-15','Completed',94.5),
 ('U00000006','2025FA',92005,'B','2025-08-15','Completed',87.0),
 ('U00000007','2025FA',92005,'A','2025-08-15','Completed',91.5),
 ('U00000010','2025FA',92005,'B+','2025-08-15','Completed',88.5),
 ('U00000014','2025FA',92005,'A-','2025-08-15','Completed',90.0),
 ('U00000016','2025FA',92005,'C','2025-08-15','Completed',76.5),
 ('U00000020','2025FA',92005,'B','2025-08-15','Completed',83.0),
 ('U00000001','2025FA',92005,'A','2025-08-15','Completed',95.5),
 ('U00000002','2025FA',92005,'A','2025-08-15','Completed',93.0),
 ('U00000008','2025FA',92005,'B-','2025-08-15','Completed',80.5),
 ('U00000009','2025FA',92005,'C+','2025-08-15','Completed',77.5),
 ('U00000011','2025FA',92005,'B','2025-08-15','Completed',85.0),
 ('U00000013','2025FA',92005,'D','2025-08-15','Completed',65.0),
 ('U00000017','2025FA',92005,'B+','2025-08-15','Completed',89.0),
 ('U00000019','2025FA',92005,'A','2025-08-15','Completed',92.5),

 -- COT 3100.001 (CRN 92006) - 12 students
 ('U00000003','2025FA',92006,'A','2025-08-15','Completed',96.0),
 ('U00000005','2025FA',92006,'B','2025-08-15','Completed',84.0),
 ('U00000009','2025FA',92006,'A-','2025-08-15','Completed',90.5),
 ('U00000011','2025FA',92006,'B+','2025-08-15','Completed',88.0),
 ('U00000012','2025FA',92006,'A','2025-08-15','Completed',94.5),
 ('U00000015','2025FA',92006,'C+','2025-08-15','Completed',78.0),
 ('U00000017','2025FA',92006,'B','2025-08-15','Completed',82.5),
 ('U00000018','2025FA',92006,'A','2025-08-15','Completed',93.5),
 ('U00000019','2025FA',92006,'B-','2025-08-15','Completed',80.0),
 ('U00000002','2025FA',92006,'A','2025-08-15','Completed',95.0),
 ('U00000001','2025FA',92006,'C','2025-08-15','Completed',75.5),
 ('U00000008','2025FA',92006,'B','2025-08-15','Completed',86.0),

 -- CDA 3103.002 (CRN 92007) - 10 students
 ('U00000003','2025FA',92007,'A','2025-08-15','Completed',92.0),
 ('U00000009','2025FA',92007,'B+','2025-08-15','Completed',87.5),
 ('U00000011','2025FA',92007,'A-','2025-08-15','Completed',91.0),
 ('U00000012','2025FA',92007,'B','2025-08-15','Completed',83.5),
 ('U00000015','2025FA',92007,'A','2025-08-15','Completed',94.0),
 ('U00000017','2025FA',92007,'C+','2025-08-15','Completed',78.5),
 ('U00000018','2025FA',92007,'B','2025-08-15','Completed',85.0),
 ('U00000019','2025FA',92007,'A','2025-08-15','Completed',93.0),
 ('U00000002','2025FA',92007,'B-','2025-08-15','Completed',81.0),
 ('U00000001','2025FA',92007,'F','2025-08-15','Completed',58.0),

 -- CGS 1540.001 (CRN 92008) - 18 students  
 ('U00000004','2025FA',92008,'A','2025-08-15','Completed',95.0),
 ('U00000005','2025FA',92008,'B+','2025-08-15','Completed',89.0),
 ('U00000006','2025FA',92008,'A-','2025-08-15','Completed',90.5),
 ('U00000007','2025FA',92008,'B','2025-08-15','Completed',84.5),
 ('U00000008','2025FA',92008,'A','2025-08-15','Completed',93.5),
 ('U00000010','2025FA',92008,'C+','2025-08-15','Completed',77.5),
 ('U00000013','2025FA',92008,'B','2025-08-15','Completed',82.0),
 ('U00000014','2025FA',92008,'A','2025-08-15','Completed',92.5),
 ('U00000016','2025FA',92008,'B-','2025-08-15','Completed',80.5),
 ('U00000020','2025FA',92008,'A-','2025-08-15','Completed',91.0),
 ('U00000001','2025FA',92008,'B','2025-08-15','Completed',86.5),
 ('U00000002','2025FA',92008,'A','2025-08-15','Completed',94.0),
 ('U00000003','2025FA',92008,'C','2025-08-15','Completed',76.0),
 ('U00000009','2025FA',92008,'B+','2025-08-15','Completed',88.5),
 ('U00000011','2025FA',92008,'A','2025-08-15','Completed',95.5),
 ('U00000012','2025FA',92008,'D','2025-08-15','Completed',67.0),
 ('U00000015','2025FA',92008,'B','2025-08-15','Completed',83.5),
 ('U00000019','2025FA',92008,'A','2025-08-15','Completed',96.0),

 -- Spring 2026 in progress
 ('U00000004','2026SP',93001,'IP','2026-01-10','Enrolled',NULL),
 ('U00000005','2026SP',93001,'IP','2026-01-10','Enrolled',NULL),
 ('U00000006','2026SP',93001,'IP','2026-01-10','Enrolled',NULL),
 ('U00000007','2026SP',93001,'IP','2026-01-10','Enrolled',NULL),
 ('U00000012','2026SP',93002,'IP','2026-01-10','Enrolled',NULL),
 ('U00000008','2026SP',93002,'IP','2026-01-10','Enrolled',NULL),
 ('U00000009','2026SP',93002,'IP','2026-01-10','Enrolled',NULL),
 ('U00000010','2026SP',93002,'IP','2026-01-10','Enrolled',NULL),
 ('U00000011','2026SP',93002,'IP','2026-01-10','Enrolled',NULL),
 ('U00000013','2026SP',93003,'IP','2026-01-11','Enrolled',NULL),
 ('U00000017','2026SP',93004,'IP','2026-01-11','Enrolled',NULL),
 ('U00000004','2026SP',93003,'IP','2026-01-10','Enrolled',NULL),
 ('U00000005','2026SP',93003,'IP','2026-01-10','Enrolled',NULL),
 ('U00000006','2026SP',93003,'IP','2026-01-10','Enrolled',NULL),
 ('U00000007','2026SP',93004,'IP','2026-01-10','Enrolled',NULL),
 ('U00000008','2026SP',93004,'IP','2026-01-10','Enrolled',NULL),
 ('U00000009','2026SP',93004,'IP','2026-01-10','Enrolled',NULL);

GO

