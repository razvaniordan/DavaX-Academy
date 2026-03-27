/*********** Exemplu practic: TRANSACTION READ ONLY  ***********/
SET TRANSACTION READ ONLY;
SELECT *
FROM employees
WHERE employee_id=150;

UPDATE employees
SET salary=10000
WHERE employee_id=150;


/*********** Exemplu practic: TRANSACTION READ ONLY  ***********/
SET TRANSACTION READ ONLY;
SELECT *
FROM employees
WHERE employee_id=150;

UPDATE employees
SET salary=10000
WHERE employee_id=150;


/*********** Exemplu practic: READ COMMITTED  ***********/
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
SELECT *
FROM employees
WHERE employee_id=150;

SELECT *
FROM employees
WHERE employee_id=213;

SELECT *
FROM employees
WHERE department_id=20;


UPDATE employees
SET salary=13000
WHERE employee_id=213;

SAVEPOINT test1;

UPDATE employees
SET salary=15000
WHERE employee_id=150;


SAVEPOINT test2;
DELETE FROM employees WHERE employee_id=213;


ROLLBACK TO test1;


--DELETE FROM employees WHERE employee_id=213;
COMMIT ;

 /*********** Exemplu practic: Record  ***********/
SET SERVEROUTPUT ON;
DECLARE
   TYPE emp_record_type IS RECORD (
                                      emp_id     NUMBER,
                                      emp_name   VARCHAR2(100),
                                      emp_salary NUMBER
                                   );

   emp_rec emp_record_type;
BEGIN
   emp_rec.emp_id := 101;
   emp_rec.emp_name := 'Alice';
   emp_rec.emp_salary := 5000;
   
   DBMS_OUTPUT.PUT_LINE('Employee: ' || emp_rec.emp_name);
END;

/*********** Exemplu practic: Record %ROWTYPE for table-based records:  ***********/
DECLARE
   emp_row employees%ROWTYPE;
BEGIN
   SELECT * INTO emp_row FROM employees WHERE employee_id = 100;
   DBMS_OUTPUT.PUT_LINE('Name: ' || emp_row.first_name);
END;
 SELECT * 
 FROM employees 
 WHERE employee_id = 100

/*********** Exemplu practic: Associative array INDEX INTEGER  ***********/
SET SERVEROUTPUT ON;
DECLARE
   TYPE NameArray IS TABLE OF VARCHAR2(50) INDEX BY BINARY_INTEGER;
   v_names NameArray;
BEGIN
   v_names(1) := 'Alice';
   v_names(2) := 'Bob';
   DBMS_OUTPUT.PUT_LINE(v_names(1));
END;
/*********** Exemplu practic: Associative array  INDEX STRING  ***********/
DECLARE
   TYPE phone_book IS TABLE OF VARCHAR2(15) INDEX BY VARCHAR2(50);
   contacts phone_book;
BEGIN
   contacts('Alice') := '1234567890';
   contacts('Bob') := '9876543210';

   DBMS_OUTPUT.PUT_LINE('Bob''s number: ' || contacts('Bob'));
END;
/*********** Exemplu practic: Associative array  Using Methods  ***********/
DECLARE
   TYPE WordList IS TABLE OF VARCHAR2(20) INDEX BY BINARY_INTEGER;
   words WordList;
   i INTEGER;
BEGIN
   words(1) := 'apple';
   words(2) := 'banana';
   words(5) := 'cherry'; -- sparse element

   i := words.FIRST;
   WHILE i IS NOT NULL LOOP
      DBMS_OUTPUT.PUT_LINE('Index: ' || i || ' Value: ' || words(i));
      i := words.NEXT(i);
   END LOOP;
END;

/*********** Exemplu practic: Nested Table  ***********/
SET SERVEROUTPUT ON;
DECLARE
   TYPE NumList IS TABLE OF NUMBER;
   numbers NumList := NumList(10, 20, 30);
BEGIN
   numbers.EXTEND;
   numbers(4) := 40;
   FOR i IN 1..numbers.COUNT LOOP
      DBMS_OUTPUT.PUT_LINE(numbers(i));
   END LOOP;
END;

DECLARE
   TYPE num_table IS TABLE OF NUMBER;
   nt num_table := num_table(10, 20, 30);
BEGIN
   nt.DELETE(2); -- Sparse now
   nt.EXTEND;
   nt(4) := 40;
   FOR i IN 1 .. nt.COUNT LOOP
      IF nt.EXISTS(i) THEN
         DBMS_OUTPUT.PUT_LINE(nt(i));
      END IF;
   END LOOP;
END;

/*********** Exemplu practic: Nested Table as SQL Column Type  ***********/
-- Step 1: Create the Nested Table Type in SQL  
CREATE OR REPLACE TYPE number_list AS TABLE OF NUMBER;
--Step 2: Use in a Table
CREATE TABLE project_tasks (
   project_id NUMBER,
   task_ids   number_list
) NESTED TABLE task_ids STORE AS task_ids_table;
--Step 3: Insert Data
INSERT INTO project_tasks VALUES (101, number_list(1, 2, 3, 4));

/*********** Exemplu practic: Nested Operatori  ***********/
--MULTISET EXCEPT
SET SERVEROUTPUT ON
DECLARE
	TYPE list_of_names_t IS TABLE OF varchar2(255);
	happyfamily list_of_names_t := list_of_names_t();
	children list_of_names_t 	:= list_of_names_t();
	parents list_of_names_t 	:= list_of_names_t();
	
BEGIN
	happyfamily.EXTEND(4); -- unlimited

	happyfamily(1) := 'Eli';
	happyfamily(2) := 'Steven';
	happyfamily(3) := 'Chris';
	happyfamily(4) := 'Veva';

	children.EXTEND;
	children(1) := 'Chris';
	children.EXTEND;
	children(2) := 'Eli';

	-- http://www.oracle.com/technetwork/issue-archive/o53plsql-083350.html
	parents := happyfamily MULTISET EXCEPT children;

	FOR l_row IN parents.FIRST .. parents.LAST
	LOOP
		DBMS_OUTPUT.put_line(parents(l_row));
	END LOOP;
END;

--MULTISET UNION
DECLARE
   TYPE num_table IS TABLE OF NUMBER;
   a num_table := num_table(10, 20, 30);
   b num_table := num_table(20, 30, 40);

   c num_table;
BEGIN
   c := a MULTISET UNION b;

   FOR i IN 1 .. c.COUNT LOOP
      DBMS_OUTPUT.PUT_LINE('Element: ' || c(i));
   END LOOP;
END;
/*********** Exemplu practic: VARRAY  ***********/
SET SERVEROUTPUT ON;
DECLARE
   TYPE grade_array IS VARRAY(3) OF NUMBER;
   grades grade_array := grade_array(null, 85, 88);
BEGIN
   FOR i IN 1 .. grades.COUNT LOOP
      DBMS_OUTPUT.PUT_LINE(grades(i));
   END LOOP;
END;

/*********** Exemplu practic: VARRAY Type in SQL (Persistent)  ***********/
--1. Create Type in SQL
CREATE OR REPLACE TYPE phone_list AS VARRAY(3) OF VARCHAR2(15);

--2. Use in a Table
CREATE TABLE contacts (
   name        VARCHAR2(50),
   phones      phone_list
);

--3. Insert Data
INSERT INTO contacts VALUES ('Alice', phone_list('123-456', '789-012'));

--4. Query Data
SELECT name, phones(1) AS primary_phone FROM contacts;

/*********** Exemplu practic:  User Define  Type   ***********/
-- Type Specification

CREATE OR REPLACE TYPE employee_obj AS OBJECT (
   emp_id     NUMBER,
   emp_name   VARCHAR2(100),
   salary     NUMBER,

   MEMBER FUNCTION annual_salary RETURN NUMBER,
   MEMBER PROCEDURE display_info
);

--Type Body (Implement Methods)
CREATE OR REPLACE TYPE BODY employee_obj 
AS

   MEMBER FUNCTION annual_salary RETURN NUMBER IS
   BEGIN
      RETURN salary * 12;
   END;
   
   MEMBER PROCEDURE display_info IS
   BEGIN
      DBMS_OUTPUT.PUT_LINE('ID: ' || emp_id || ', Name: ' || emp_name);
   END;

END;

--Using Object Methods
DECLARE
   emp employee_obj;
BEGIN
   emp := employee_obj(101, 'Alice', 5000);

   DBMS_OUTPUT.PUT_LINE('Annual Salary: ' || emp.annual_salary);

   emp.display_info;
END;