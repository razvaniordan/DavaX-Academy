/*********** Exemplu practic: TRANSACTION READ ONLY  ***********/
SET TRANSACTION READ ONLY;
SELECT *
FROM employees
WHERE employee_id=150;

UPDATE employees
SET salary=10000
WHERE employee_id=150;


