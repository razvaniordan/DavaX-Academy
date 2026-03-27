/*********** Exemplu practic: Initianlizare variabila pe baza de query ***********/
SET SERVEROUTPUT ON
DECLARE    
   sum_sal  NUMBER(10,2); 
   deptno   DEPARTMENTS.department_id%TYPE:=60;--&depId;           
BEGIN
   SELECT  SUM(salary)  -- group function
   INTO sum_sal 
   FROM employees
   WHERE  department_id = deptno;
   DBMS_OUTPUT.PUT_LINE ('The sum of salary is ' || sum_sal);
END;
/

/*****************  ATENȚIE: *********************************************
* SELECT INTO trebuie să returneze exact un rând.
* Erori posibile:
* 1. NO_DATA_FOUND	- Dacă nu există niciun rând care corespunde
* 2. TOO_MANY_ROWS	- Dacă sunt mai multe rânduri decât se așteaptă
*******************************************************************************************/