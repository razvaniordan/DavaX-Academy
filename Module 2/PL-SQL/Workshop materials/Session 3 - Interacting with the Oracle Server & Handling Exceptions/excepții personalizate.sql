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
