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
