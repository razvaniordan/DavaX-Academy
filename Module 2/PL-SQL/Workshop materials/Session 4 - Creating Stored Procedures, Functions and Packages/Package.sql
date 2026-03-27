/*********** Example : Package Specification – declares public elements ***********/
CREATE OR REPLACE PACKAGE employee_pkg 
IS
   g_bonus_rate NUMBER := 0.20; -- global variable

   PROCEDURE update_salary(p_id NUMBER, p_amount NUMBER );
   PROCEDURE add_bonus_salary(p_id NUMBER);
   FUNCTION get_full_name(p_id NUMBER) RETURN VARCHAR2;

END employee_pkg;
/

/*********** Example : Package Body – implements the declared elements ***********/
CREATE OR REPLACE PACKAGE BODY employee_pkg 
IS
   FUNCTION calc_bonus(p_id varchar) 
   RETURN employees.salary%TYPE 
   IS
      v_salary employees.salary%TYPE;
   BEGIN
          SELECT round(salary*g_bonus_rate)
          INTO v_salary
          FROM employees 
          WHERE employee_id = to_number(p_id);
          RETURN v_salary;
    END;
    
   PROCEDURE update_salary(p_id NUMBER, p_amount NUMBER) 
   IS
   BEGIN
      UPDATE employees 
      SET salary = salary + p_amount
      WHERE employee_id = p_id;
   END;
   
   PROCEDURE add_bonus_salary(p_id NUMBER) 
   IS
    v_bonus employees.salary%TYPE;
   BEGIN   
      v_bonus:=calc_bonus(p_id);
      
      UPDATE employees 
      SET salary = salary + v_bonus
      WHERE employee_id = p_id;
   END;
  
   FUNCTION get_full_name(p_id NUMBER) 
   RETURN VARCHAR2 
   IS
      v_name VARCHAR2(100);
   BEGIN
      SELECT first_name || ' ' || last_name 
      INTO v_name
      FROM employees 
      WHERE employee_id = p_id;
      RETURN v_name;
   END;
END employee_pkg;
/