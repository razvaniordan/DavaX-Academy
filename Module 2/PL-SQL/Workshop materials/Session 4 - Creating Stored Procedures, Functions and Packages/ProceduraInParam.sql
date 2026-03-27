/*********** Exemplu practic: Creare procedura cu 2 parametri  ***********/
/********************************************************************************
* Nume procedură     : update_salary
* Descriere          : Modifica salariul angajatul cu noul salariu.
* Parametri          :
*   p_emp_id (IN)      - ID-ul angajatului 
*   p_new_salary (IN)  - Salariul nou al angajatului
* Autor              : Svetlana Sura
* Data creării       : 10.06.2025
* Modificări         : 12.06.2025 - S. Sura - Adăugat tratament pentru excepții
*
********************************************************************************/
CREATE OR REPLACE PROCEDURE updateSalary (
   p_emp_id IN employees.employee_id%TYPE,
   p_new_salary IN employees.salary%TYPE DEFAULT null
)
IS
    v_Commission  employees.salary%TYPE;
BEGIN
   /****** E doar pentru a ilistra ACCESSIBLE by calculeaza comisionul dar nu se utilizeaza ****/ 
   calculateComision(150, v_Commission);
   DBMS_OUTPUT.PUT_LINE('Commision: ' || v_Commission);
   
   UPDATE employees
   SET salary = COALESCE(p_new_salary,salary)
   WHERE employee_id = p_emp_id;
 
   COMMIT;
   DBMS_OUTPUT.PUT_LINE (' Salariul a fost modificat!!!'); 
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

--Apelam procedura methoda 1 
    SET SERVEROUTPUT ON
    --cu valori pentru ambii parametrii
    exec updateSalary(150, 11000);
    
    --cu valori pentru primul parametru
    exec updateSalary('150fff');
    
    exec updateSalary(p_emp_id=>150 );
    
    --cu appel pe nume si ordinea nu e respectata
    exec updateSalary( p_new_salary=>11000, p_emp_id=>150);

--Apelam procedura methoda 2
SET SERVEROUTPUT ON
BEGIN
   updateSalary(150, 12000);
END;

--Apelam procedura methoda 3
SET SERVEROUTPUT ON
call updateSalary(150, 14000);

/*****************  Recomandări *********************************************
* Parametrii IN la început, OUT la final – clar și ordonat.
* De ce este bine să pui OUT la final?
* - Este mai ușor de înțeles că acei parametri ies din procedură
* - Urmată de majoritatea dezvoltatorilor PL/SQL
* - Evită confuzii la apel mai ales când folosești apel pozițional, nu pe nume
* Dacă folosești apel cu nume, ordinea nu mai contează
*******************************************************************************************/


