/*********** Exemplu practic: Creare procedura cu 2 parametri  ***********/
CREATE OR REPLACE PROCEDURE calculateComision (
   p_emp_id IN employees.employee_id%TYPE,
   p_commision out employees.salary%TYPE
)
AUTHID DEFINER
ACCESSIBLE BY(PROCEDURE  updateSalary, AddCommissionToSalary)
IS
BEGIN
    SELECT round(salary*commission_pct,2)--14.56->14.5/14.6
    INTO p_commision
    FROM employees
    WHERE employee_id=p_emp_id;

   DBMS_OUTPUT.PUT_LINE (' Commisionul a fost calculat!!!'); 
 EXCEPTION
  WHEN OTHERS THEN
  DBMS_OUTPUT.PUT_LINE ('Atentie!!! Commisionul nu a fost calculat!!!');   
END;
/

/*********** Exemplu practic: Apelarea procedurii  ***********/
-- Verificarea stare actuala
SELECT *
FROM employees
WHERE employee_id=150;

--Apelam procedura methoda 2
DECLARE
   v_Commission employees.salary%TYPE;
BEGIN
   calculateComision(150, v_Commission);
   DBMS_OUTPUT.PUT_LINE('Commision: ' || v_Commission);
END;

