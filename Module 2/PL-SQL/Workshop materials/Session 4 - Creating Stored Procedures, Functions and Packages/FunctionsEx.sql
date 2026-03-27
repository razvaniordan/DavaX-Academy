/*********** Example : Standalone Functions ***********/
CREATE OR REPLACE FUNCTION get_tax(p_salary NUMBER) 
RETURN NUMBER 
IS
BEGIN
   RETURN p_salary * 0.2;
END;

SELECT get_tax(150) FROM dual;

/*********** Example : Deterministic Functions ***********/
CREATE OR REPLACE FUNCTION area_of_circle(radius NUMBER)
RETURN NUMBER 
DETERMINISTIC 
IS
BEGIN
   RETURN 3.14 * radius * radius;
END;

/**O sa studiem saptamana viitoare acesta tema -doar pentru a putea crea functia Pipe**/
CREATE OR REPLACE TYPE number_table_type AS TABLE OF NUMBER;

/*********** Example : Pipelined Table Functions (Advanced) ***********/
CREATE OR REPLACE FUNCTION get_numbers 
RETURN number_table_type
PIPELINED 
IS
BEGIN
   FOR i IN 1..10 LOOP
      PIPE ROW(i);
   END LOOP;
   RETURN;
END;

SELECT * FROM TABLE(get_numbers);

/*********** Example : Recursive Functions ***********/
CREATE OR REPLACE FUNCTION factorial(n NUMBER) RETURN NUMBER IS
BEGIN
   IF n = 1 THEN
      RETURN 1;
   ELSE
      RETURN n * factorial(n - 1);
   END IF;
END;

SELECT factorial(5) FROM dual;