/*********** Exemplu practic: READ COMMITTED  ***********/
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
SELECT *
FROM employees
WHERE employee_id=150;

SELECT *
FROM employees
WHERE employee_id=213;

SELECT *
FROM employees
WHERE department_id=20;


UPDATE employees
SET salary=13000
WHERE employee_id=213;

SAVEPOINT test1;

UPDATE employees
SET salary=15000
WHERE employee_id=150;


SAVEPOINT test2;
DELETE FROM employees WHERE employee_id=213;


ROLLBACK TO test1;


--DELETE FROM employees WHERE employee_id=213;
COMMIT ;

 