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

