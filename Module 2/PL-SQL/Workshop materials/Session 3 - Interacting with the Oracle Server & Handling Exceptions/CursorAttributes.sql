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
