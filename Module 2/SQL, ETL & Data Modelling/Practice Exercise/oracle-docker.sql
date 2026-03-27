-- we will use the previous tables, and create here new needed tables to complete the missing info
CREATE TABLE Absence_Log (
    absence_id         NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    employee_id        NUMBER NOT NULL,
    absence_date       DATE NOT NULL,
    absence_hours      NUMBER(4,2) NOT NULL CHECK (absence_hours >= 0 AND absence_hours <= 24),
    absence_type       VARCHAR2(50) NOT NULL,

    CONSTRAINT fk_absence_employee FOREIGN KEY (employee_id) REFERENCES Employees(employee_id)
);

-- the table with the unsanitized values from the csv file
CREATE TABLE STG_ABSENCE_LOG_RAW (
    employee_id_text      VARCHAR2(20),
    absence_date_text     VARCHAR2(30),
    absence_duration_text VARCHAR2(30),
    absence_type          VARCHAR2(50)
);

-- inserting the valid rows from the csv file in the Absence log table
INSERT INTO Absence_Log (
    employee_id,
    absence_date,
    absence_hours,
    absence_type
)
SELECT
    TO_NUMBER(employee_id_text) AS employee_id,

    CASE
        WHEN REGEXP_LIKE(absence_date_text, '^\d{4}-\d{2}-\d{2}$') THEN TO_DATE(absence_date_text, 'YYYY-MM-DD')
        WHEN REGEXP_LIKE(absence_date_text, '^\d{4}/\d{2}/\d{2}$') THEN TO_DATE(absence_date_text, 'YYYY/MM/DD')
        WHEN REGEXP_LIKE(absence_date_text, '^\d{2}-\d{2}-\d{4}$') THEN TO_DATE(absence_date_text, 'DD-MM-YYYY')
    END AS absence_date,

    NVL(TO_NUMBER(REGEXP_SUBSTR(absence_duration_text, '([0-9]+)h', 1, 1, NULL, 1)), 0)
    +
    NVL(TO_NUMBER(REGEXP_SUBSTR(absence_duration_text, '([0-9]+)m', 1, 1, NULL, 1)), 0) / 60
    AS absence_hours,

    absence_type
FROM STG_ABSENCE_LOG_RAW
WHERE
    employee_id_text IS NOT NULL
    AND TRIM(employee_id_text) IS NOT NULL
    AND REGEXP_LIKE(employee_id_text, '^[0-9]+$')
    AND EXISTS (
        SELECT 1
        FROM Employees e
        WHERE e.employee_id = TO_NUMBER(employee_id_text)
    )
    AND (
        REGEXP_LIKE(absence_date_text, '^\d{4}-\d{2}-\d{2}$')
        OR REGEXP_LIKE(absence_date_text, '^\d{4}/\d{2}/\d{2}$')
        OR REGEXP_LIKE(absence_date_text, '^\d{2}-\d{2}-\d{4}$')
    )
    AND REGEXP_LIKE(absence_duration_text, '^([0-9]+h)? ?([0-9]+m)?$')
    AND (
        NVL(TO_NUMBER(REGEXP_SUBSTR(absence_duration_text, '([0-9]+)h', 1, 1, NULL, 1)), 0)
        +
        NVL(TO_NUMBER(REGEXP_SUBSTR(absence_duration_text, '([0-9]+)m', 1, 1, NULL, 1)), 0) / 60
    ) <= 24;
 
 
-- creating the dim tables
CREATE TABLE DIM_EMPLOYEE (
    employee_key         NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    source_employee_id   NUMBER NOT NULL UNIQUE,
    first_name           VARCHAR2(50) NOT NULL,
    last_name            VARCHAR2(50) NOT NULL,
    email                VARCHAR2(100),
    job_title            VARCHAR2(100)
);

CREATE TABLE DIM_DEPARTMENT (
    department_key         NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    source_department_id   NUMBER NOT NULL UNIQUE,
    department_name        VARCHAR2(100) NOT NULL,
    city_location          VARCHAR2(100) NOT NULL
);

CREATE TABLE DIM_DATE (
    date_key        NUMBER PRIMARY KEY,   -- YYYYMMDD
    full_date       DATE NOT NULL,
    day_number      NUMBER NOT NULL,
    month_number    NUMBER NOT NULL,
    year_number     NUMBER NOT NULL,
    day_name        VARCHAR2(20) NOT NULL,
    is_weekend      CHAR(1) CHECK (is_weekend IN ('Y','N'))
);

CREATE TABLE DIM_LOCATION (
    location_key      NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    location_name     VARCHAR2(20) NOT NULL UNIQUE
);

-- creating fact table
CREATE TABLE FACT_EMPLOYEE_ACTIVITY (
    fact_id             NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    date_key            NUMBER NOT NULL,
    employee_key        NUMBER NOT NULL,
    department_key      NUMBER NOT NULL,
    location_key        NUMBER NOT NULL,
    relocated_country   VARCHAR2(50),
    activity_type       VARCHAR2(20) NOT NULL CHECK (activity_type IN ('WORK', 'ABSENCE')),
    hours_quantity      NUMBER(4,2) NOT NULL CHECK (hours_quantity >= 0 AND hours_quantity <= 24),

    CONSTRAINT fk_fact_date FOREIGN KEY (date_key) REFERENCES DIM_DATE(date_key),
    CONSTRAINT fk_fact_employee FOREIGN KEY (employee_key) REFERENCES DIM_EMPLOYEE(employee_key),
    CONSTRAINT fk_fact_department FOREIGN KEY (department_key) REFERENCES DIM_DEPARTMENT(department_key),
    CONSTRAINT fk_fact_location FOREIGN KEY (location_key) REFERENCES DIM_LOCATION(location_key)
);


-- populate the dim tables
-- dim_department
INSERT INTO DIM_DEPARTMENT (source_department_id, department_name, city_location)
SELECT
    department_id,
    department_name,
    city_location
FROM Departments;

-- dim_employee
INSERT INTO DIM_EMPLOYEE (source_employee_id, first_name, last_name, email, job_title)
SELECT
    employee_id,
    first_name,
    last_name,
    email,
    job_title
FROM Employees;

-- dim_location
INSERT INTO DIM_LOCATION (location_name) VALUES ('HOME');
INSERT INTO DIM_LOCATION (location_name) VALUES ('OFFICE');
INSERT INTO DIM_LOCATION (location_name) VALUES ('RELOCATED');
INSERT INTO DIM_LOCATION (location_name) VALUES ('ABSENCE');

-- dim_date
INSERT INTO DIM_DATE (date_key, full_date, day_number, month_number, year_number, day_name, is_weekend)
SELECT DISTINCT
    TO_NUMBER(TO_CHAR(dt, 'YYYYMMDD')) AS date_key,
    dt AS full_date,
    TO_NUMBER(TO_CHAR(dt, 'DD')) AS day_number,
    TO_NUMBER(TO_CHAR(dt, 'MM')) AS month_number,
    TO_NUMBER(TO_CHAR(dt, 'YYYY')) AS year_number,
    TRIM(TO_CHAR(dt, 'DAY', 'NLS_DATE_LANGUAGE=ENGLISH')) AS day_name,
    CASE
        WHEN TO_CHAR(dt, 'DY', 'NLS_DATE_LANGUAGE=ENGLISH') IN ('SAT', 'SUN') THEN 'Y'
        ELSE 'N'
    END AS is_weekend
FROM (
    SELECT work_date AS dt FROM Entry_Daily_Hours
    UNION
    SELECT absence_date AS dt FROM Absence_Log
);

-- fact table
-- inserting the work days from entry_daily_hours
INSERT INTO FACT_EMPLOYEE_ACTIVITY (
    date_key,
    employee_key,
    department_key,
    location_key,
    relocated_country,
    activity_type,
    hours_quantity
)
SELECT
    dd.date_key,
    de.employee_key,
    ddp.department_key,
    dl.location_key,
    te.relocated_country,
    'WORK' AS activity_type,
    edh.hours_quantity
FROM Entry_Daily_Hours edh
JOIN Timesheet_Entries te ON edh.entry_id = te.entry_id
JOIN Timesheets t ON te.timesheet_id = t.timesheet_id
JOIN Employees e ON t.employee_id = e.employee_id
JOIN DIM_EMPLOYEE de ON de.source_employee_id = e.employee_id
JOIN DIM_DEPARTMENT ddp ON ddp.source_department_id = e.department_id
JOIN DIM_DATE dd ON dd.full_date = edh.work_date
JOIN DIM_LOCATION dl ON dl.location_name = te.location_work;

-- inserting absence days from absence logs
INSERT INTO FACT_EMPLOYEE_ACTIVITY (
    date_key,
    employee_key,
    department_key,
    location_key,
    relocated_country,
    activity_type,
    hours_quantity
)
SELECT
    dd.date_key,
    de.employee_key,
    ddp.department_key,
    dl.location_key,
    NULL AS relocated_country,
    'ABSENCE' AS activity_type,
    al.absence_hours
FROM Absence_Log al
JOIN Employees e ON al.employee_id = e.employee_id
JOIN DIM_EMPLOYEE de ON de.source_employee_id = e.employee_id
JOIN DIM_DEPARTMENT ddp ON ddp.source_department_id = e.department_id
JOIN DIM_DATE dd ON dd.full_date = al.absence_date
JOIN DIM_LOCATION dl ON dl.location_name = 'ABSENCE';

-- queries/reports to show activities by day, by employees

-- view query for displaying the logs of every day for all employees
-- we will use this view later for specific contexts so we don't copy/paste the select everytime
CREATE OR REPLACE VIEW VW_EMPLOYEE_ACTIVITY_LOGS AS
SELECT
    f.fact_id,
    dd.full_date,
    dd.day_name,
    de.employee_key,
    de.source_employee_id,
    de.first_name,
    de.last_name,
    de.first_name || ' ' || de.last_name AS employee_name,
    ddep.department_name,
    dl.location_name,
    f.relocated_country,
    f.activity_type,
    f.hours_quantity
FROM FACT_EMPLOYEE_ACTIVITY f
JOIN DIM_DATE dd ON f.date_key = dd.date_key
JOIN DIM_EMPLOYEE de ON f.employee_key = de.employee_key
JOIN DIM_DEPARTMENT ddep ON f.department_key = ddep.department_key
JOIN DIM_LOCATION dl ON f.location_key = dl.location_key
ORDER BY dd.full_date, employee_name, f.activity_type;

SELECT * FROM VW_EMPLOYEE_ACTIVITY_LOGS

-- query for displaying the logs of the employee id
SELECT * FROM VW_EMPLOYEE_ACTIVITY_LOGS WHERE source_employee_id = 4

-- query for displaying the logs of the employee name
SELECT * FROM VW_EMPLOYEE_ACTIVITY_LOGS WHERE employee_name = 'FirstName_11 LastName_11'

-- query for displaying the logs of a specific day of all employees
SELECT * FROM VW_EMPLOYEE_ACTIVITY_LOGS WHERE full_date = '06-MAR-26'

-- query for displaying the logs of a specific employee on a specific day of the week for a specific employee
SELECT * FROM VW_EMPLOYEE_ACTIVITY_LOGS WHERE TRIM(day_name) = 'MONDAY' AND source_employee_id = 7

-- query for displaying the logs with absences
SELECT * FROM VW_EMPLOYEE_ACTIVITY_LOGS WHERE activity_type = 'ABSENCE'