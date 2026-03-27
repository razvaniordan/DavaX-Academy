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