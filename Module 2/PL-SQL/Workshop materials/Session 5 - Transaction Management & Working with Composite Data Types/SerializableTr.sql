/*********** Exemplu practic: TRANSACTION SERIALIZABLE  ***********/
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
SELECT *
FROM employees
WHERE employee_id=150;

SELECT *
FROM employees
WHERE department_id=20;

UPDATE employees
SET salary=10000
WHERE employee_id=150;