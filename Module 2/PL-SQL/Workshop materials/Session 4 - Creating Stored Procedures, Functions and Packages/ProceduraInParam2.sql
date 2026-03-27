/*********** Exemplu practic: Creare procedura cu 2 parametri  ***********/
CREATE OR REPLACE PROCEDURE AddCommissionToSalary (p_emp_id IN employees.employee_id%TYPE,
                                                   p_new_salary in out employees.salary%TYPE )
IS
v_Commission employees.salary%TYPE;
BEGIN
   /****** Calculam comision  ****/
   calculateComision(150, v_Commission);
   DBMS_OUTPUT.PUT_LINE('Commision: ' || v_Commission);
   
   /****** Modificam Salariul  ****/
   UPDATE employees
   SET salary = COALESCE(p_new_salary,salary)+v_Commission
   WHERE employee_id = p_emp_id
   RETURNING salary into p_new_salary ;
   DBMS_OUTPUT.PUT_LINE('Salariul+Commision: ' || p_new_salary);

   COMMIT;
   DBMS_OUTPUT.PUT_LINE ('Salariul a fost modificat!!!'); 
 EXCEPTION
  WHEN OTHERS THEN
  ROLLBACK;
  DBMS_OUTPUT.PUT_LINE ('Atentie!!! Salariul nu a fost modificat!!!');   
END;
/

/*********** Exemplu practic: Apelarea procedurii  ***********/
-- Verificarea stare actuala
SELECT *
FROM employees
WHERE employee_id=150;

--Apelam procedura methoda 2 Block anonim
SET SERVEROUTPUT ON
DECLARE
   v_newSalary employees.salary%TYPE;
BEGIN
   DBMS_OUTPUT.PUT_LINE('Salariul nou: ' || v_newSalary);

   AddCommissionToSalary(150, v_newSalary);
   DBMS_OUTPUT.PUT_LINE('Salariul nou: ' || v_newSalary);
END;








