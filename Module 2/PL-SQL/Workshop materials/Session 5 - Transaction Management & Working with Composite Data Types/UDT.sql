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