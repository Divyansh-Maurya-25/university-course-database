# University Course Registration Database

> A fully normalized relational database for a university course registration system, built in T-SQL (SQL Server). Covers schema design with referential integrity, seed data across 4 majors, and 16 real-world query scenarios including what-if GPA analysis.

[![SQL Server](https://img.shields.io/badge/SQL_Server-T--SQL-CC2927)](https://www.microsoft.com/en-us/sql-server)

---

## Overview

This project models the complete academic data domain for a university college (Bellini College of Engineering at USF), from course catalogs and degree requirements through student enrollment, grading, and transcript generation. The schema was designed to enforce correctness at the database level — not just in application code.

---

## Schema Design

### 13 Tables, 4 Schemas of Concern

```
Bellini.Major                  ← degree programs (BSCS, BSCP, BSIT, BSCyS)
Bellini.Term                   ← academic terms (Fall 2023 → Spring 2026)
Bellini.Course                 ← course catalog (prefix + number composite PK)
Bellini.CoursePreReq           ← prerequisite relationships (self-referencing FK)
Bellini.CourseCoReq            ← corequisite relationships (self-referencing FK)
Bellini.MajorCourseRequirement ← which courses each major requires + type + min grade
Bellini.StudyPlan              ← 4-year plan (major + year + term + sequence)
Bellini.Instructor             ← faculty with office/hours info
Bellini.Student                ← 20 students across 4 majors
Bellini.MajorChange            ← audit log of major switches
Bellini.Grade                  ← grade scale (A → F, IP, W) with GPA values
Bellini.ClassSection           ← course sections per term (CRN, schedule, capacity)
Bellini.TA_Assignment          ← student TA assignments per section
Bellini.Enrollment             ← student registrations with grades and scores
```

### Key Design Decisions

**Composite primary keys** — `Course(CoursePrefix, CourseNumber)` avoids surrogate keys that would allow orphaned references; `Enrollment(StudentNumber, TermCode, CRN)` enforces one registration per student per section.

**Self-referencing FKs** — `CoursePreReq` and `CourseCoReq` both reference `Course` twice (the course and its prerequisite/corequisite), with `ON DELETE NO ACTION` to prevent cascade deletion of a course from accidentally removing its own prerequisite listings.

**CHECK constraints** — `RequirementType IN ('core','elective','state-mandated')`, `ClassType IN ('Lecture','Lab','Other')`, `Status IN ('Open','Closed')` — domain validation enforced at the DB level.

**Cascades** — `Student → Major` uses `ON DELETE CASCADE` (dropping a major removes its students, which removes their enrollment history). `ClassSection → Instructor` uses `ON DELETE SET NULL` (removing an instructor nullifies the section's instructor field without losing the section).

---

## Seed Data

- **4 majors** — BSCS, BSCP, BSIT, BSCyS (2023 catalog year)
- **42 courses** — full course catalogs for all four degrees with real USF course numbers
- **Full prerequisite/corequisite chains** — e.g., COP2510 → COP3514 → COP4530; PHY2048 ↔ PHY2048L (corequisite)
- **4-year study plans** — term-by-term course sequences for BSCS, BSCP, BSIT
- **4 instructors**, **20 students**, **12 class sections** across Fall 2025 and Spring 2026
- **55+ enrollment records** with final scores and grade letters

---

## Query Scenarios (16 total)

| # | Query |
|---|---|
| 3.8.1 | Search open sections by prefix, number, credit hours, or level |
| 3.8.2 | List required courses + total credit hours for a major |
| 3.8.3 | Find courses a student still needs to complete |
| 3.8.4 | Display a student's 4-year study plan |
| 3.8.5 | Full course detail including all prerequisites and corequisites |
| 3.8.6 | Class section details with instructor, TA, and roster |
| 3.8.7 | Instructor and student profile lookups |
| 3.8.8 | Admin updates: schedule, instructor, capacity, status |
| 3.8.9 | GPA summary by major and by enrolled class |
| **3.8.10** | **What-if GPA analysis** — project GPA under different grade scenarios |
| 3.8.11 | Semester transcript and cumulative transcript with GPA |
| 3.8.12 | Course registration with duplicate-check validation |
| 3.8.13 | Course drop with enrollment count update and validation |
| 3.8.14 | Instructor grade entry with proof query |
| 3.8.15 | Full class roster with student GPA and standing |
| 3.8.16 | Grade distribution histogram (score bands) for a section |

### Notable Query — What-If GPA Analysis (3.8.10)

The most technically complex query. Uses two correlated LEFT JOINs with conditional `SUM` aggregation to project a student's GPA under two scenarios without any application code:

```sql
-- Scenario A: all current in-progress courses → grade A
-- Scenario B: one specific CRN → grade F, all others → grade A

CASE WHEN S.EarnedHours + ISNULL(X.InProgressCredits, 0) = 0 THEN S.GPA
     ELSE (S.GPA * S.EarnedHours + ISNULL(X.InProgressCredits, 0) * 4.0)
          / (S.EarnedHours + ISNULL(X.InProgressCredits, 0))
END AS WhatIf_All_A_GPA
```

---

## Setup

Requires SQL Server (or Azure SQL). Run scripts in order:

```sql
-- 1. Create schema, tables, constraints, and seed data
-- Run: Pj2_09_build.sql

-- 2. Run all 16 query scenarios
-- Run: Pj2_09_query.sql
```

---

## File Structure

```
university-course-database/
├── Pj2_09_build.sql    # DDL + referential integrity + all seed data
├── Pj2_09_query.sql    # 16 query scenarios
└── README.md
```

---

## Course Context

Project 2 for **CIS 4301 — Information and Database Systems** at the University of South Florida. Group 9 (Divyansh Maurya).
