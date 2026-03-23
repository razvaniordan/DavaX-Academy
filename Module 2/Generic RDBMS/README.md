# Timesheet Management System - Oracle SQL

---

## Project Overview

The system models a company timesheet workflow where:

- employees belong to departments
- departments have managers (which are employees)
- employees can submit weekly timesheets
- each timesheet contains multiple entries (project code, task details, location etc.)
- each entry contains daily hours (the hours of each day of that respective timesheet's week)
- employees can also save reusable timesheet templates

---

## Implemented Features

This project includes:

- table creation in Oracle SQL
- examples of database constraints:
  - `PRIMARY KEY`
  - `FOREIGN KEY`
  - `NOT NULL`
  - `UNIQUE`
  - `CHECK`
  - `COMPOSITE PRIMARY KEY`
- semistructured data using a JSON column
- additional indexes besides primary keys and foreign keys
- at least one `VIEW`
- at least one `MATERIALIZED VIEW`
- a `TRIGGER` for business rule validation
- sample data for:
  - departments
  - employees
  - timesheets
  - timesheet entries
  - entry daily hours
  - timesheet templates
  - timesheet template entries
  - timesheet daily hours
- example `SELECT` statements using:
  - `GROUP BY`
  - `ORDER BY`
  - `INNER JOIN`
  - `LEFT JOIN`
  - analytic function (`RANK()`)

---

## Database Structure

The main entities are:

- `Departments`
- `Employees`
- `Timesheets`
- `Timesheet_Entries`
- `Entry_Daily_Hours`
- `Timesheet_Templates`
- `Timesheet_Template_Entries`
- `Template_Daily_Hours`

### Main relationships

- one department can have multiple employees
- one department has one manager
- one employee can have another employee as manager
- one employee can submit multiple timesheets
- one timesheet can contain multiple entries
- one entry can contain daily hours for multiple days
- one employee can have multiple reusable templates

---

## Business Rules Implemented

Some of the main business rules implemented in the schema are:

- employees must be at least 18 years old at hiring date
- one department name can repeat in different cities, but the pair `(department_name, city_location)` must be unique
- one employee can manage at most one department
- a timesheet week must start on **Monday**
- a timesheet week must contain exactly **7 days**
- one employee cannot have duplicate timesheets for the same week
- daily hours in one entry must be between `0` and `24`
- JSON data stored in employee metadata must be valid
- the trigger prevents the total hours for the same timesheet day from exceeding `24`

---

## Views and Materialized View

### 1. `View_Employees_Timesheets`
This view is used to monitor the timesheets of active employees from the **DavaX** program.

It displays:
- employee name
- job title
- department
- timesheet week
- project code
- task details
- work location (`HOME` / `OFFICE`)
- work date
- number of worked hours

Because it uses `LEFT JOIN`, it also includes DavaX employees who have **not submitted any timesheet yet**.

This view filters:
- employees with `job_title = 'DavaX Junior'`
- employees with `status = 'ACTIVE'` (which means that they are not fired, did not resign or they are not on leave)

### 2. `MV_Employee_Weekly_Hours`
This materialized view stores precomputed weekly worked hours per employee.

It contains:
- employee identity
- week interval
- timesheet status
- total worked hours for that week

This is useful for faster reporting and weekly summary analysis.

### 3. `View_Employees_Accepted_Weekly_Hours`
This view aggregates only the hours from timesheets with status `ACCEPTED`.

It is used as the source for ranking employees by total accepted worked hours.

---

## Reporting Queries Included

The SQL script also contains reporting queries for the following scenarios:

### Search inside `View_Employees_Timesheets`
A query that tests the main view by filtering for a specific DavaX employee by last name.

### Employee ranking by accepted worked hours
A query using the analytic function `RANK()` to rank employees based on the total number of accepted worked hours.

### Employees working in hybrid mode
A query that extracts information from the JSON column `extra_info` and displays employees whose `work_mode` is set to `hybrid`.

### Timesheet templates for a specific employee
A query that displays:
- employee name
- employee job title
- template name
- template creation date
- template entries
- location of work
- absence/relocation information
- number of hours for each day of the week

This query is filtered by employee ID in the `WHERE` clause.

---

## Trigger

A trigger is included to enforce a business validation rule that cannot be handled by a simple `CHECK` constraint:

- the total hours recorded for the same day inside a timesheet cannot exceed `24`

---

## Sample Data

The script populates the database with:

- `3` departments
- `100` employees
- timesheets for only some employees
- templates for only some employees

This allows testing scenarios where:
- some employees submitted timesheets
- some employees did not submit anything yet
- some employees have reusable templates
- trigger validation can be demonstrated

---

## Files

- `oracle-docker.sql` - main SQL script containing the full project
- `Generic_RDBMS___exercise.docx` - task requirements

---
