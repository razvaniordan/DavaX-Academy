/*********** Exemplu practic: Cursor implicit (FOR LOOP) pe baza de query ***********/
SET SERVEROUTPUT ON
DECLARE 
    departmentId DEPARTMENTS.department_id%TYPE:=&depId;
    departmentName DEPARTMENTS.department_name%TYPE;
BEGIN
   /*Identificam numele departamentului*/
   SELECT department_name INTO departmentName 
   FROM DEPARTMENTS WHERE department_id=departmentId;
 
       
   DBMS_OUTPUT.PUT_LINE(' Lista anagajatilor din departamentul  '||departmentName);
   /*Identificam angajatii din departamentul dat si salariul lor*/
   FOR rec IN ( SELECT first_name,last_name, salary   
                FROM employees
                where department_id=departmentId) 
   LOOP
      DBMS_OUTPUT.PUT_LINE(rec.first_name ||' '||rec.last_name|| ' - ' || rec.salary);
   END LOOP;
END;
/


/*****************  Recomandări *********************************************
*
* Folosește %TYPE pentru a declara variabile în funcție de coloane.
* Tratează excepțiile NO_DATA_FOUND și TOO_MANY_ROWS.
* Pentru interogări care returnează mai multe rânduri, nu folosi SELECT INTO, ci cursori sau LOOP.
*
*******************************************************************************************/