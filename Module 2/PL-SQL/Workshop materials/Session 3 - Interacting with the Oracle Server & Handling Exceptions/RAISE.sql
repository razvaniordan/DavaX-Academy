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
   IF SYSDATE > TO_DATE('2025-01-31', 'YYYY-MM-DD') THEN
      RAISE_APPLICATION_ERROR(-20001, 'Data este prea târzie.');
   END IF;
EXCEPTION
   WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('Am prins excepția definită de utilizator.');
END;


