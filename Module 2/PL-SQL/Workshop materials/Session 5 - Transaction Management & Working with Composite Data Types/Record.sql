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

