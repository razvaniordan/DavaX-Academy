/*********** Example : Appelare/utiliazare packete ***********/
-- Verificarea stare actuala
SELECT *
FROM employees
WHERE employee_id=150;

--appel procedura
BEGIN
   employee_pkg.update_salary(150, 500);
END;

--appel functie
SELECT   employee_pkg.get_full_name(150) 
FROM dual;

SELECT   employee_pkg.calc_bonus(150) 
FROM dual;

--utilizare variabila de packet --CORRECT???
SELECT first_name , 
        last_name , 
        salary , 
        round(salary*employee_pkg.g_bonus_rate,2)
FROM employees

DECLARE
   v_BR NUMBER:=employee_pkg.g_bonus_rate;
BEGIN
   DBMS_OUTPUT.PUT_LINE('Commision: ' || v_BR);
END;
