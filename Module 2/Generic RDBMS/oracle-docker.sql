--------------------------------------------------
-- SECTION 1. TABLE CREATION
--------------------------------------------------

-- departments like HR IT etc. that have multiple employees, one manager, and there is one unique department per city (one office per city)
CREATE TABLE Departments (
    department_id       NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    department_name     VARCHAR2(100) NOT NULL,
    city_location       VARCHAR2(100) NOT NULL,
    manager_id          NUMBER UNIQUE,
    
    CONSTRAINT unique_department_location
        UNIQUE (department_name, city_location)
);

CREATE TABLE Employees (
    employee_id   NUMBER PRIMARY KEY,
    first_name    VARCHAR2(50) NOT NULL,
    last_name     VARCHAR2(50) NOT NULL,
    job_title     VARCHAR2(100) NOT NULL,
    birth_date    DATE NOT NULL,
    hire_date     DATE NOT NULL,
    gender        VARCHAR2(10) CHECK (gender IN ('M','F')),
    cnp           VARCHAR2(13) UNIQUE NOT NULL CHECK (LENGTH(cnp) = 13),
    email         VARCHAR2(100) UNIQUE NOT NULL,
    phone         VARCHAR2(15) UNIQUE,
    salary        NUMBER(10,2) NOT NULL CHECK (salary > 0),
    status        VARCHAR2(20) DEFAULT 'ACTIVE' NOT NULL 
                  CHECK (status IN ('ACTIVE','INACTIVE','ON_LEAVE')),
    department_id NUMBER NOT NULL,
    manager_id    NUMBER,
    extra_info    CLOB CHECK (extra_info IS JSON),

    CONSTRAINT check_employee_birth_hire
        CHECK (hire_date >= ADD_MONTHS(birth_date, 12 * 18)),

    CONSTRAINT fk_employee_department
        FOREIGN KEY (department_id) REFERENCES Departments(department_id),

    CONSTRAINT fk_employee_manager
        FOREIGN KEY (manager_id) REFERENCES Employees(employee_id)
);

ALTER TABLE Departments
ADD CONSTRAINT fk_department_manager
FOREIGN KEY (manager_id) REFERENCES Employees(employee_id);

-- in this table are stored the weeks of the submitted timesheets of an employee (to which the entries are linked to)
CREATE TABLE Timesheets (
    timesheet_id     NUMBER PRIMARY KEY,
    employee_id      NUMBER NOT NULL,
    week_start_date  DATE NOT NULL,
    week_end_date    DATE NOT NULL,
    status           VARCHAR2(20) DEFAULT 'PENDING' NOT NULL
                     CHECK (status IN ('PENDING', 'ACCEPTED', 'REJECTED')),
    submitted_at     DATE NOT NULL,
    reviewed_at      DATE,

    CONSTRAINT unique_timesheet_employee_week
        UNIQUE (employee_id, week_start_date, week_end_date),

    CONSTRAINT check_timesheet_week_interval
        CHECK (week_end_date = week_start_date + 6),
        
    CONSTRAINT check_first_day
        CHECK (TO_CHAR(week_start_date, 'DY', 'NLS_DATE_LANGUAGE=ENGLISH') = 'MON'),

    CONSTRAINT fk_timesheet_employee
        FOREIGN KEY (employee_id) REFERENCES Employees(employee_id)
);

-- the entries for the weeks stored in Timesheet table
CREATE TABLE Timesheet_Entries (
    entry_id            NUMBER PRIMARY KEY,
    timesheet_id        NUMBER NOT NULL,
    project_code        VARCHAR(50) NOT NULL,
    task_details        VARCHAR2(50) NOT NULL,
    time_type           VARCHAR2(50) NOT NULL,
    location_work       VARCHAR2(50) NOT NULL,
    absence_type        VARCHAR2(50),
    relocated_country   VARCHAR2(50),

    CONSTRAINT check_location_work
        CHECK (location_work IN ('HOME', 'OFFICE', 'RELOCATED')),

    CONSTRAINT fk_entries_timesheet
        FOREIGN KEY (timesheet_id) REFERENCES Timesheets(timesheet_id)
);

-- a table for the number of hours of each day of an entry from a specific week
CREATE TABLE Entry_Daily_Hours (
    entry_id         NUMBER NOT NULL,
    work_date        DATE NOT NULL,
    hours_quantity   NUMBER(4,2) NOT NULL
                     CHECK (hours_quantity >= 0 AND hours_quantity <= 24),

    CONSTRAINT pk_entry_daily_hours
        PRIMARY KEY (entry_id, work_date),

    CONSTRAINT fk_day_entry
        FOREIGN KEY (entry_id) REFERENCES Timesheet_Entries(entry_id)
        ON DELETE CASCADE
);

-- almost the same thing as the timesheets, but for storing templates
CREATE TABLE Timesheet_Templates (
    template_id      NUMBER PRIMARY KEY,
    employee_id      NUMBER NOT NULL,
    template_name    VARCHAR2(100) NOT NULL,
    created_at       DATE DEFAULT SYSDATE NOT NULL,

    CONSTRAINT fk_template_employee
        FOREIGN KEY (employee_id) REFERENCES Employees(employee_id)
        ON DELETE CASCADE,

    CONSTRAINT unique_template_name_per_employee
        UNIQUE (employee_id, template_name)
);

CREATE TABLE Timesheet_Template_Entries (
    template_entry_id    NUMBER PRIMARY KEY,
    template_id          NUMBER NOT NULL,
    project_code         VARCHAR(50) NOT NULL,
    task_details         VARCHAR2(50) NOT NULL,
    time_type            VARCHAR2(50) NOT NULL,
    location_work        VARCHAR2(50) NOT NULL,
    absence_type         VARCHAR2(50),
    relocated_country    VARCHAR2(50),

    CONSTRAINT check_template_location_work
        CHECK (location_work IN ('HOME', 'OFFICE', 'RELOCATED')),

    CONSTRAINT fk_template_entries_template
        FOREIGN KEY (template_id) REFERENCES Timesheet_Templates(template_id)
        ON DELETE CASCADE
);

CREATE TABLE Template_Daily_Hours (
    template_entry_id    NUMBER NOT NULL,
    day_of_week          NUMBER NOT NULL,
    hours_quantity       NUMBER(4,2) NOT NULL
                         CHECK (hours_quantity >= 0 AND hours_quantity <= 24),

    CONSTRAINT pk_template_daily_hours
        PRIMARY KEY (template_entry_id, day_of_week),

    CONSTRAINT check_template_day_of_week
        CHECK (day_of_week BETWEEN 1 AND 7),

    CONSTRAINT fk_template_daily_hours_entry
        FOREIGN KEY (template_entry_id) REFERENCES Timesheet_Template_Entries(template_entry_id)
        ON DELETE CASCADE
);

--------------------------------------------------
-- SECTION 2. INDEX & TRIGGER CREATION
--------------------------------------------------
CREATE INDEX idx_timesheets_week_start ON Timesheets(week_start_date);

CREATE INDEX idx_timesheets_status ON Timesheets(status);

CREATE INDEX idx_entry_daily_hours ON Entry_Daily_Hours(work_date);

CREATE SEARCH INDEX idx_employee_extra_info_json ON Employees(extra_info) FOR JSON;

CREATE OR REPLACE TRIGGER trg_check_daily_total_hours
BEFORE INSERT OR UPDATE ON Entry_Daily_Hours
FOR EACH ROW
DECLARE
    v_total_hours NUMBER(4,2);
BEGIN
    SELECT NVL(SUM(edh.hours_quantity), 0)
    INTO v_total_hours
    FROM Entry_Daily_Hours edh
    JOIN Timesheet_Entries te
      ON edh.entry_id = te.entry_id
    WHERE te.timesheet_id = (
        SELECT timesheet_id
        FROM Timesheet_Entries
        WHERE entry_id = :NEW.entry_id
    )
      AND edh.work_date = :NEW.work_date
      AND edh.entry_id <> :NEW.entry_id;

    v_total_hours := v_total_hours + :NEW.hours_quantity;

    IF v_total_hours > 24 THEN
        RAISE_APPLICATION_ERROR(
            -20002,
            'Total number of hours on this day is higher than 24'
        );
    END IF;
END;
/


--------------------------------------------------
-- SECTION 3. TABLES POPULATING
--------------------------------------------------

-- filling Departments table with values
INSERT INTO Departments (department_name, city_location, manager_id)
VALUES ('IT', 'Bucharest', NULL);

INSERT INTO Departments (department_name, city_location, manager_id)
VALUES ('HR', 'Cluj-Napoca', NULL);

INSERT INTO Departments (department_name, city_location, manager_id)
VALUES ('Finance', 'Bucharest', NULL);

--    filling Employees table with values (100 employees)
--    Department distribution:
--    1-40   -> IT
--    41-70  -> HR
--    71-100 -> Finance
BEGIN
    FOR i IN 1..100 LOOP
        INSERT INTO Employees (
            employee_id,
            first_name,
            last_name,
            job_title,
            birth_date,
            hire_date,
            gender,
            cnp,
            email,
            phone,
            salary,
            status,
            department_id,
            manager_id,
            extra_info
        )
        VALUES (
            i,
            'FirstName_' || i,
            'LastName_' || i,
            CASE
                WHEN MOD(i, 10) = 0 THEN 'Senior Specialist'
                WHEN MOD(i, 5) = 0 THEN 'Team Lead'
                WHEN MOD(i, 7) = 0 THEN 'DavaX Junior'
                ELSE 'Specialist'
            END,
            ADD_MONTHS(DATE '1980-01-01', i * 3),
            ADD_MONTHS(DATE '2015-01-01', i),
            CASE
                WHEN MOD(i, 2) = 0 THEN 'M'
                ELSE 'F'
            END,
            LPAD(1800101000000 + i, 13, '0'),
            'employee' || i || '@endava.com',
            '07' || LPAD(i, 8, '0'),
            ROUND(DBMS_RANDOM.VALUE(3500, 12000), 2),
            CASE
                WHEN MOD(i, 15) = 0 THEN 'ON_LEAVE'
                WHEN MOD(i, 22) = 0 THEN 'INACTIVE'
                ELSE 'ACTIVE'
            END,
            CASE
                WHEN i BETWEEN 1 AND 40 THEN 1
                WHEN i BETWEEN 41 AND 70 THEN 2
                ELSE 3
            END,
            CASE
                WHEN i BETWEEN 2 AND 40 THEN 1
                WHEN i BETWEEN 42 AND 70 THEN 41
                WHEN i BETWEEN 72 AND 100 THEN 71
                ELSE NULL
            END,
            '{"skills":["SQL","Oracle"],"work_mode":"hybrid","has_laptop":true}'
        );
    END LOOP;
END;
/

--    set department managers
--    Department 1 -> employee 1
--    Department 2 -> employee 41
--    Department 3 -> employee 71
UPDATE Departments
SET manager_id = 1
WHERE department_id = 1;

UPDATE Departments
SET manager_id = 41
WHERE department_id = 2;

UPDATE Departments
SET manager_id = 71
WHERE department_id = 3;

--    filling Timesheets table with values
--    only employees 1..30 will have submitted timesheets
--    the others will have no submitted timesheet yet
--
--    we create 2 weeks per employee:
--    Week 1: 2026-03-02 -> 2026-03-08 (Monday -> Sunday)
--    Week 2: 2026-03-09 -> 2026-03-15 (Monday -> Sunday)
BEGIN
    FOR i IN 1..30 LOOP
        INSERT INTO Timesheets (
            timesheet_id,
            employee_id,
            week_start_date,
            week_end_date,
            status,
            submitted_at,
            reviewed_at
        )
        VALUES (
            1000 + i,
            i,
            DATE '2026-03-02',
            DATE '2026-03-08',
            CASE
                WHEN MOD(i, 3) = 0 THEN 'ACCEPTED'
                WHEN MOD(i, 5) = 0 THEN 'REJECTED'
                ELSE 'PENDING'
            END,
            DATE '2026-03-09',
            CASE
                WHEN MOD(i, 3) = 0 OR MOD(i, 5) = 0 THEN DATE '2026-03-10'
                ELSE NULL
            END
        );

        INSERT INTO Timesheets (
            timesheet_id,
            employee_id,
            week_start_date,
            week_end_date,
            status,
            submitted_at,
            reviewed_at
        )
        VALUES (
            2000 + i,
            i,
            DATE '2026-03-09',
            DATE '2026-03-15',
            CASE
                WHEN MOD(i, 4) = 0 THEN 'ACCEPTED'
                ELSE 'PENDING'
            END,
            DATE '2026-03-16',
            CASE
                WHEN MOD(i, 4) = 0 THEN DATE '2026-03-17'
                ELSE NULL
            END
        );
    END LOOP;
END;
/

--    filling Timesheet_Entries able with values
--    for each timesheet we create 2 entries:
--    - one HOME entry
--    - one OFFICE entry
--    in this PL/SQL block we wrote the first entry fill for working from home and second entry for working from office
BEGIN
    FOR i IN 1..30 LOOP
        -- week 1, entry 1 (work from home)
        INSERT INTO Timesheet_Entries (
            entry_id,
            timesheet_id,
            project_code,
            task_details,
            time_type,
            location_work,
            absence_type,
            relocated_country
        )
        VALUES (
            10000 + i * 10 + 1,
            1000 + i,
            'BHD something',
            '0' || (MOD(i, 5) + 1) || ' - something',
            'REGULAR',
            'HOME',
            NULL,
            NULL
        );

        -- week 1, entry 2 (work from office)
        INSERT INTO Timesheet_Entries (
            entry_id,
            timesheet_id,
            project_code,
            task_details,
            time_type,
            location_work,
            absence_type,
            relocated_country
        )
        VALUES (
            10000 + i * 10 + 2,
            1000 + i,
            'BHD something',
            '0' || (MOD(i, 5) + 1) || ' - something',
            'REGULAR',
            'OFFICE',
            NULL,
            NULL
        );

        -- week 2, entry 1 (work from home)
        INSERT INTO Timesheet_Entries (
            entry_id,
            timesheet_id,
            project_code,
            task_details,
            time_type,
            location_work,
            absence_type,
            relocated_country
        )
        VALUES (
            20000 + i * 10 + 1,
            2000 + i,
            'BHD something',
            '0' || (MOD(i, 5) + 1) || ' - something',
            'REGULAR',
            'HOME',
            NULL,
            NULL
        );

        -- week 2, entry 2 (work from office)
        INSERT INTO Timesheet_Entries (
            entry_id,
            timesheet_id,
            project_code,
            task_details,
            time_type,
            location_work,
            absence_type,
            relocated_country
        )
        VALUES (
            20000 + i * 10 + 2,
            2000 + i,
            'BHD something',
            '0' || (MOD(i, 5) + 1) || ' - something',
            'REGULAR',
            'OFFICE',
            NULL,
            NULL
        );
    END LOOP;
END;
/

--    filling Entry_Daily_Hours table with values
--    this is just a simulated example to fill the tables with values (so it's not necessarily a rule 
--    that these are the specific days for home/office days)
--
--    for every entry:
--    - OFFICE entry gets 8h on Thursday only for DavaX and 8h on Wednesday and Thursday for the rest of the roles
--    - HOME entry gets 8h for the rest of the week
--    Weekend = 0h (we do not insert weekend rows)
BEGIN
    FOR r IN (
        SELECT te.entry_id,
               t.week_start_date,
               te.location_work,
               e.job_title
        FROM Timesheet_Entries te
        JOIN Timesheets t
          ON te.timesheet_id = t.timesheet_id
        JOIN Employees e
          ON t.employee_id = e.employee_id
    ) LOOP
        -- d = 0 Monday, 1 Tuesday, 2 Wednesday, 3 Thursday, 4 Friday
        FOR d IN 0..4 LOOP
            IF r.job_title = 'DavaX Junior' THEN
                IF (r.location_work = 'HOME'   AND d IN (0,1,2,4))
                   OR
                   (r.location_work = 'OFFICE' AND d = 3)
                THEN
                    INSERT INTO Entry_Daily_Hours (
                        entry_id,
                        work_date,
                        hours_quantity
                    )
                    VALUES (
                        r.entry_id,
                        r.week_start_date + d,
                        8
                    );
                END IF;
            ELSE
                IF (r.location_work = 'HOME'   AND d IN (0,1,4))
                   OR
                   (r.location_work = 'OFFICE' AND d IN (2,3))
                THEN
                    INSERT INTO Entry_Daily_Hours (
                        entry_id,
                        work_date,
                        hours_quantity
                    )
                    VALUES (
                        r.entry_id,
                        r.week_start_date + d,
                        8
                    );
                END IF;
            END IF;
        END LOOP;
    END LOOP;
END;
/

--    filling Timesheet_templates table with values
--    only employees 1..10 will have templates
BEGIN
    FOR i IN 1..10 LOOP
        INSERT INTO Timesheet_Templates (
            template_id,
            employee_id,
            template_name,
            created_at
        )
        VALUES (
            5000 + i,
            i,
            'Standard Template ' || i,
            SYSDATE
        );
    END LOOP;
END;
/

--    filling Timesheet template entries table with values
--    each template gets 2 entries:
--    - HOME
--    - OFFICE
BEGIN
    FOR i IN 1..10 LOOP
        INSERT INTO Timesheet_Template_Entries (
            template_entry_id,
            template_id,
            project_code,
            task_details,
            time_type,
            location_work,
            absence_type,
            relocated_country
        )
        VALUES (
            6000 + i * 10 + 1,
            5000 + i,
            'BHD sth',
            '0' || (MOD(i, 5) + 1) || ' - something',
            'REGULAR',
            'HOME',
            NULL,
            NULL
        );

        INSERT INTO Timesheet_Template_Entries (
            template_entry_id,
            template_id,
            project_code,
            task_details,
            time_type,
            location_work,
            absence_type,
            relocated_country
        )
        VALUES (
            6000 + i * 10 + 2,
            5000 + i,
            'BHD sth',
            '0' || (MOD(i, 5) + 1) || ' - something',
            'REGULAR',
            'OFFICE',
            NULL,
            NULL
        );
    END LOOP;
END;
/

--    filling Template daily hours table with values
--    this is just a simulated example to fill the tables with values 
--    (so it's not necessarily a rule that these are the specific days for home/office days)
-- 
--    for each template we did the same as in the submitted ones from Entry_Daily_Hours:
--    - OFFICE entry gets 8h on Thursday only for DavaX and 8h on Wednesday and Thursday for the rest of the roles
--    - HOME entry gets 8h for the rest of the week
--    Weekend = 0h
BEGIN
    FOR r IN (
        SELECT tte.template_entry_id,
               tte.location_work,
               e.job_title
        FROM Timesheet_Template_Entries tte
        JOIN Timesheet_Templates tt
          ON tte.template_id = tt.template_id
        JOIN Employees e
          ON tt.employee_id = e.employee_id
    ) LOOP
        FOR d IN 1..5 LOOP
            IF r.job_title = 'DavaX Junior' THEN
                IF (r.location_work = 'HOME'   AND d IN (1,2,3,5))
                   OR
                   (r.location_work = 'OFFICE' AND d = 4)
                THEN
                    INSERT INTO Template_Daily_Hours (
                        template_entry_id,
                        day_of_week,
                        hours_quantity
                    )
                    VALUES (
                        r.template_entry_id,
                        d,
                        8
                    );
                END IF;
            ELSE
                IF (r.location_work = 'HOME'   AND d IN (1,2,5))
                   OR
                   (r.location_work = 'OFFICE' AND d IN (3,4))
                THEN
                    INSERT INTO Template_Daily_Hours (
                        template_entry_id,
                        day_of_week,
                        hours_quantity
                    )
                    VALUES (
                        r.template_entry_id,
                        d,
                        8
                    );
                END IF;
            END IF;
        END LOOP;
    END LOOP;
END;
/

-- this is a view to monitorize the timesheets of the active (not fired/resigned/on holiday) employees that are in the DavaX program
-- basically it displays the every timesheet submitted by an employee (each day of that timesheet's week) 
-- so you can see in which days he worked from home or office and some information regarding that employee
-- by using left join we can also see the DavaX employees who didn't submit any timesheet yet
-- inner join is used on department because every employee has a department (not null constraint)
CREATE OR REPLACE VIEW View_Employees_Timesheets AS
SELECT
    e.first_name,
    e.last_name,
    e.job_title,
    d.department_name,
    t.week_start_date,
    t.week_end_date,
    te.project_code,
    te.task_details,
    te.location_work,
    edh.work_date,
    edh.hours_quantity
FROM EMPLOYEES e
LEFT JOIN TIMESHEETS t
ON e.employee_id = t.employee_id
INNER JOIN DEPARTMENTS d
ON e.department_id = d.department_id
LEFT JOIN TIMESHEET_ENTRIES te
ON t.timesheet_id = te.timesheet_id
LEFT JOIN ENTRY_DAILY_HOURS edh
ON te.entry_id = edh.entry_id  
WHERE e.job_title = 'DavaX Junior' AND e.status = 'ACTIVE';

-- here I tested the view by searching for a specific DavaX employee
SELECT * FROM View_Employees_Timesheets WHERE last_name = 'LastName_7';

-- in this materialized view we did a select to display the number of hours worked per week by an employee
CREATE MATERIALIZED VIEW MV_Employee_Weekly_Hours
BUILD IMMEDIATE
REFRESH COMPLETE ON DEMAND
AS
SELECT
    e.employee_id,
    e.first_name,
    e.last_name,
    t.week_start_date,
    t.week_end_date,
    t.status,
    NVL(SUM(edh.hours_quantity), 0) AS total_hours
FROM Employees e
JOIN Timesheets t
  ON e.employee_id = t.employee_id
LEFT JOIN Timesheet_Entries te
  ON t.timesheet_id = te.timesheet_id
LEFT JOIN Entry_Daily_Hours edh
  ON te.entry_id = edh.entry_id
GROUP BY
    e.employee_id,
    e.first_name,
    e.last_name,
    t.week_start_date,
    t.week_end_date,
    t.status;

-- view to be used below for ranking employees by number of hours worked
-- this view displays a table with the employees and their total accepted number of worked hours from the submitted timesheets
CREATE OR REPLACE VIEW View_Employees_Accepted_Weekly_Hours AS
SELECT
    e.employee_id,
    e.first_name || ' ' || e.last_name AS employee_name,
    NVL(SUM(edh.hours_quantity), 0) AS total_hours
FROM Employees e
LEFT JOIN Timesheets t
  ON e.employee_id = t.employee_id
 AND t.status = 'ACCEPTED'
LEFT JOIN Timesheet_Entries te
  ON t.timesheet_id = te.timesheet_id
LEFT JOIN Entry_Daily_Hours edh
  ON te.entry_id = edh.entry_id
GROUP BY
    e.employee_id,
    e.first_name,
    e.last_name;
    
-- this select displays a table with the employees ranked by the number of accepted hours from the submitted timesheets
SELECT
    employee_id,
    employee_name,
    total_hours,
    RANK() OVER (ORDER BY total_hours DESC) AS hours_rank
FROM View_Employees_Accepted_Weekly_Hours
ORDER BY hours_rank, employee_id;

-- displays employees that are working hybrid (set in the json file)
SELECT
    employee_id,
    first_name,
    last_name,
    JSON_VALUE(extra_info, '$.work_mode') AS work_mode
FROM Employees
WHERE JSON_VALUE(extra_info, '$.work_mode') = 'hybrid';

-- displays the timesheet templates of an employee based on his id in the WHERE clause 
-- alongside the entries and number of hours per day of the week
SELECT
    e.first_name || ' ' || e.last_name AS Name,
    e.job_title,
    tt.template_name,
    tt.created_at,
    tte.task_details,
    tte.time_type,
    tte.location_work,
    tte.absence_type,
    tte.relocated_country,
    tdh.day_of_week,
    tdh.hours_quantity
FROM Employees e
LEFT JOIN Timesheet_Templates tt
ON e.employee_id = tt.employee_id
LEFT JOIN Timesheet_Template_Entries tte
    ON tt.template_id = tte.template_id
LEFT JOIN Template_Daily_Hours tdh
    ON tte.template_entry_id = tdh.template_entry_id
WHERE e.employee_id = 7
ORDER BY tdh.day_of_week;

-- here we test the trigger for trying to put more than 24h on a day in a timesheet
INSERT INTO Timesheet_Entries (
    entry_id,
    timesheet_id,
    project_code,
    task_details,
    time_type,
    location_work,
    absence_type,
    relocated_country
)
VALUES (
    99999,
    1001,
    'proj code',
    'Trigger test entry',
    'WORK',
    'HOME',
    NULL,
    NULL
);
-- this entry will trigger the trigger
INSERT INTO Entry_Daily_Hours (
    entry_id,
    work_date,
    hours_quantity
)
VALUES (
    99999,
    DATE '2026-03-03',
    20
);
