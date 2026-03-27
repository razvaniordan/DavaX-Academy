# ETL Assignment – Timesheet and Absence Activity Warehouse

## Overview

This task extends the **Generic RDBMS – Timesheet System** assignment by building a simple **ETL flow** and a **star schema** for reporting employee activities.

The goal of this task is to integrate data from different structures and transform it into a format suitable for analysis, so that activity logs can be reported **by day** and **by employee**.

The solution reuses the main source tables from the previous assignment and adds an extra source for absences imported from a CSV file.

---

## Source Data

The main source of data comes from the tables already created in the **Generic RDBMS** assignment:

- `Employees`
- `Departments`
- `Timesheets`
- `Timesheet_Entries`
- `Entry_Daily_Hours`

These tables provide the operational data for work activities:
- who performed the activity
- in which department they belong
- on which day the activity took place
- where the work was performed (`HOME`, `OFFICE`, `RELOCATED`)
- how many hours were logged

To support the ETL requirement of integrating another data source, this project adds:

- `STG_ABSENCE_LOG_RAW`
- `Absence_Log`

---

## Why an Additional Absence Source Was Added

The original Timesheet System already stores work-related activity, but it does not contain a separate operational source for employee absences.

To cover this missing area, an `Absence_Log` source table was added. This allows the warehouse to combine:

- **WORK** activities from timesheet data
- **ABSENCE** activities from a separate absence source

This keeps the model simple while still demonstrating integration of multiple sources.

---

## CSV to Staging to Source Flow

A CSV file is used as the raw external source for absences.

Because CSV files may contain inconsistent or invalid values, the data is not loaded directly into the final absence source table. Instead, the ETL flow uses two steps:

### 1. Raw staging table
The CSV file is first loaded into `STG_ABSENCE_LOG_RAW`.

This table stores the raw imported values exactly as they come from the file, without enforcing the final structure. This makes it possible to validate and transform the data before inserting it into the clean source table.

Examples of issues handled at this stage include:
- text durations instead of numeric values
- invalid or inconsistent date formats
- missing employee identifiers
- rows that do not match expected formats

### 2. Clean source table
After validation and transformation, the valid rows are inserted into `Absence_Log`.

At this stage:
- the employee is validated
- the date is standardized
- the duration is converted into a usable numeric value
- bad rows are excluded from the clean dataset

This step makes the raw file usable for reporting and further loading into the warehouse.

---

## ETL Transformation Logic

The ETL process focuses on making messy raw data usable.

The main transformations performed for the absence source are:

- converting text-based duration values into numeric hours
- standardizing date values
- filtering out invalid rows
- keeping only the rows that can be safely loaded into the final absence source

This demonstrates the general ETL idea:
- **Extract** data from source systems and files
- **Transform** it into a consistent structure
- **Load** it into a clean source table and then into the warehouse schema

---

## Warehouse Design

After preparing the source data, the next step is building a simple warehouse using a **star schema**.

### Dimension tables
The solution uses the following dimensions:

- `DIM_EMPLOYEE`
- `DIM_DEPARTMENT`
- `DIM_DATE`
- `DIM_LOCATION`

These tables contain the descriptive information needed for analysis.

They are populated from the operational source tables:
- employees are loaded from `Employees`
- departments are loaded from `Departments`
- dates are built from the distinct dates found in work and absence data
- locations are loaded as the possible reporting values used in the activity logs

### Fact table
The central fact table is:

- `FACT_EMPLOYEE_ACTIVITY`

This table stores the activity records at a daily level and contains:
- employee reference
- department reference
- date reference
- location reference
- relocated country where applicable
- activity type (`WORK` or `ABSENCE`)
- number of hours

The fact table is the analytical core of the solution.

---

## How the Warehouse Is Populated

The loading order is important.

### 1. Populate dimensions first
The dimension tables are loaded before the fact table because the fact table depends on their keys.

At this stage:
- employee information is loaded into `DIM_EMPLOYEE`
- department information is loaded into `DIM_DEPARTMENT`
- all dates used in work and absence activities are loaded into `DIM_DATE`
- location values are loaded into `DIM_LOCATION`

### 2. Populate the fact table
After the dimensions exist, the fact table is loaded using the source tables.

The fact table is populated from two logical activity sources:

#### Work activities
Work rows are built from the timesheet-related tables:
- `Entry_Daily_Hours`
- `Timesheet_Entries`
- `Timesheets`
- `Employees`

This provides:
- the day of work
- the employee
- the department
- the work location
- relocated country where relevant
- the number of worked hours

These rows are loaded into the fact table with activity type `WORK`.

#### Absence activities
Absence rows are built from:
- `Absence_Log`
- `Employees`

This provides:
- the date of absence
- the employee
- the department
- the absence hours

These rows are loaded into the fact table with activity type `ABSENCE`.

---

## Reporting Logic

Once the warehouse is populated, the fact table can be joined with the dimensions to answer reporting questions such as:

- activity logs of a specific employee
- activity logs on a specific day
- absence-only logs
- work-only logs
- logs filtered by location
- total activity hours by employee or by day

---

## Why a View Was Created

To avoid repeating the same long join between the fact table and all dimensions, a reporting view was created:

- `VW_EMPLOYEE_ACTIVITY_LOGS`

This view provides a ready-to-use joined result that includes:
- date information
- employee details
- department information
- location
- activity type
- hours quantity

Using this view makes the reporting queries simpler and easier to read.

Instead of rewriting the same join logic in every report, the view is queried and filtered depending on the reporting need.

This keeps the SQL cleaner and makes the reporting layer more maintainable.

---

## Examples of Reporting Scenarios

The final reporting layer supports queries such as:

- display all logs of a specific employee by employee ID
- display all logs from a specific calendar day
- display only absence records
- display only work records
- display logs by work location
- display total hours grouped by employee or by date

These reports are based on the same warehouse structure and use the view to simplify access to the joined analytical data.

---

## Summary

This task demonstrates a complete high-level ETL and warehouse flow built on top of the previous Timesheet System assignment.

In summary, the solution:
- reuses the source tables from the Generic RDBMS assignment
- adds an absence source loaded from a CSV file
- stages raw CSV data before cleaning it
- transforms messy raw values into usable structured data
- loads analytical dimensions and a central fact table
- creates a reporting view to simplify report queries
- supports activity analysis by day and by employee

The final result is a simple but clear example of how operational data can be transformed into a warehouse model for reporting.
