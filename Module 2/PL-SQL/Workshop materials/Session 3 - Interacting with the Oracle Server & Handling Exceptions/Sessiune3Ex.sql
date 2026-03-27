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

/*********** Exemplu practic: Cursor implicit (FOR LOOP) pe baza de query ***********/
SET SERVEROUTPUT ON
DECLARE 
    departmentId DEPARTMENTS.department_id%TYPE:=&depId;
    departmentName DEPARTMENTS.department_name%TYPE;
BEGIN
   /*Identificam numele departamentului*/
   SELECT department_name 
   INTO departmentName 
   FROM DEPARTMENTS 
   WHERE department_id=departmentId;
 
       
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
/*********** Exemplu practic: INSERT folosind variabile PL/SQL ***********/
SET SERVEROUTPUT ON
DECLARE
   v_countryId  NUMBER := 26;
   v_nume       VARCHAR2(50) := 'Romania';
   v_region     VARCHAR2(50) := 10;
BEGIN
   INSERT INTO countries (country_id, country_name, region_id)
   VALUES (v_countryId, v_nume, v_region);
   COMMIT;
END;

/*******Verificam daca avem asa date ********/
SELECT
    country_id,
    country_name,
    region_id
FROM  countries
where country_name='Romania';

/*********** Exemplu practic: SQL Cursor Attributes for Implicit Cursors ***********/
VARIABLE rows_deleted VARCHAR2(30)
DECLARE
  empno employees.employee_id%TYPE := 176;
BEGIN
  DELETE FROM  employees 
  WHERE employee_id = empno;
  :rows_deleted := (SQL%ROWCOUNT ||' row deleted.');
END;
/
PRINT rows_deleted

/*********** Exemplu practic: SQL Cursor Attributes for Implicit Cursors Sterge Tara***********/
VARIABLE rows_deleted VARCHAR2(30)
DECLARE
  v_countryId countries.country_id%TYPE := 26;
BEGIN
  DELETE FROM  countries 
  WHERE country_id = v_countryId;
  :rows_deleted := (SQL%ROWCOUNT ||' row deleted.');
  commit;
END;
/
PRINT rows_deleted

/*********** Exemplu practic: Cream tabelul countries_copy in  countries***********/
create table countries_copy
as
select *
from countries;


/*********** Exemplu practic: Verificam tabelul countries_copy in  countries***********/
select *
from countries_copy;


/*********** Exemplu practic: Truncate tabelul countries_copy in  PL/SQL BLOCK***********/
BEGIN
  Truncate table countries_copy;
END;

/*********** Exemplu practic: Truncate tabelul countries_copy in  SQL***********/
Truncate table countries_copy;

/*****************  Important de știut *********************************************
*
* TRUNCATE este o instrucțiune DDL (Data Definition Language) folosită pentru a șterge rapid toate rândurile dintr-un tabel, 
* fără a înregistra fiecare ștergere în jurnalul de tranzacții (așa cum face DELETE).
* 
* Deoarece TRUNCATE este o instrucțiune DDL, trebuie rulată folosind EXECUTE IMMEDIATE în cadrul unui bloc PL/SQL.
*******************************************************************************************/
/*********** Exemplu practic: Predefined Oracle Server ZERO_DIVIDE ***********/
SET SERVEROUTPUT ON
DECLARE
   v_x NUMBER := 10;
   v_y NUMBER := 0;
   v_rezultat NUMBER;
BEGIN
   v_rezultat := v_x / v_y; -- împărțire la 0
   DBMS_OUTPUT.PUT_LINE('Rezultat: ' || v_rezultat);
EXCEPTION
   WHEN ZERO_DIVIDE THEN
      DBMS_OUTPUT.PUT_LINE('Eroare: Împărțire la zero!');
END;

/*********** Exemplu practic: Predefined Oracle Server TOO_MANY_ROWS ***********/
SET SERVEROUTPUT ON
DECLARE
  lname VARCHAR2(15);
BEGIN
  BEGIN
      SELECT last_name 
      INTO lname 
      FROM employees 
      WHERE  first_name='John'; 
  EXCEPTION
  WHEN TOO_MANY_ROWS THEN
    DBMS_OUTPUT.PUT_LINE (' Your select statement   retrieved multiple rows. Consider using a  cursor.');
  END;
  
  DBMS_OUTPUT.PUT_LINE ('John''s last name is : ' ||lname);
EXCEPTION
  WHEN OTHERS THEN
  DBMS_OUTPUT.PUT_LINE (' Your select statement   retrieved multiple rows. Consider using a  cursor.');
END;
/

SELECT last_name 
FROM employees 
WHERE first_name='John';

/*********** Exemplu practic: Predefined Oracle Server ZERO_DIVIDE ***********/
SET SERVEROUTPUT ON
DECLARE
   Eroare_Personalizata EXCEPTION;
BEGIN
   RAISE Eroare_Personalizata;
EXCEPTION
   WHEN Eroare_Personalizata THEN
      DBMS_OUTPUT.PUT_LINE('Am prins excepția definită de utilizator.');
END;


/*********** Exemplu practic: Predefined Oracle Server RAISE_APPLICATION_ERROR ***********/
SET SERVEROUTPUT ON
BEGIN
   IF SYSDATE > TO_DATE('2025-12-31', 'YYYY-MM-DD') THEN
      RAISE_APPLICATION_ERROR(-20001, 'Data este prea târzie.');
   END IF;
   DBMS_OUTPUT.PUT_LINE('Ura.');
   
EXCEPTION
   
   WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('Am prins excepția definită de utilizator.');
END;

/*****************  Recomandări *********************************************
De ce să folosești RAISE_APPLICATION_ERROR
Pentru a semnala reguli de afaceri încălcate.
Pentru a menține consistența datelor și a aplicației.
Pentru a furniza mesaje de eroare clare și specifice utilizatorilor aplicației sau dezvoltatorilor.
Pentru a declanșa rollback automat dacă eroarea este necapturată.
*******************************************************************************************/

/*****************  Domeniul codurilor de eroare personalizate *********************************************
* Coduri rezervate Oracle:  ORA-00000 la ORA-20999	
* Coduri pentru utilizator: ORA-20000 la ORA-20999
* ⚠️ Nu folosi valori în afara intervalului -20000 ... -20999, altfel vei primi o eroare la compilare.
*******************************************************************************************/

/*********** Exemplu practic: excepții personalizate ***********/
SET SERVEROUTPUT ON
DECLARE
   ex_nume_gol     EXCEPTION;
   ex_salariu_zero EXCEPTION;

   v_nume    VARCHAR2(50) := 'Mihai';
   v_salariu NUMBER ;
BEGIN
   IF v_nume IS NULL OR TRIM(v_nume) = '' THEN
      RAISE ex_nume_gol;
   END IF;

   IF nvl(v_salariu,0) <= 0   THEN
      RAISE ex_salariu_zero;
   END IF;

   DBMS_OUTPUT.PUT_LINE('Date validate cu succes!');
EXCEPTION
   WHEN ex_nume_gol THEN
      DBMS_OUTPUT.PUT_LINE('Eroare: Numele nu poate fi gol!');
   WHEN ex_salariu_zero THEN
      DBMS_OUTPUT.PUT_LINE('Eroare: Salariul trebuie să fie mai mare decât 0!');
END;

