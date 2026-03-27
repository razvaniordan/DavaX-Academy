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
  SELECT last_name 
  INTO lname 
  FROM employees 
  WHERE  first_name='John'; 
  
  DBMS_OUTPUT.PUT_LINE ('John''s last name is : ' ||lname);
EXCEPTION
  WHEN TOO_MANY_ROWS THEN
  DBMS_OUTPUT.PUT_LINE (' Your select statement   retrieved multiple rows. Consider using a  cursor.');
END;
/

SELECT last_name 
FROM employees 
WHERE first_name='John';
