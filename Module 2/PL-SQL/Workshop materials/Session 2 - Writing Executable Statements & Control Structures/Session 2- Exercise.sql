/*********** Exemplu practic: Searched CASE (condiții complexe) ***********/
SET SERVEROUTPUT ON
DECLARE
   v_scor NUMBER := 72;
BEGIN
   CASE 
      WHEN v_scor >= 90 THEN DBMS_OUTPUT.PUT_LINE('Excelent');
      WHEN v_scor >= 75 THEN DBMS_OUTPUT.PUT_LINE('Bine');
      WHEN v_scor >= 60 THEN DBMS_OUTPUT.PUT_LINE('Suficient');
      ELSE DBMS_OUTPUT.PUT_LINE('Insuficient');
   END CASE;
END;

/*********** Exemplu practic: Simple CASE (comparare directă a unei expresii) ***********/
SET SERVEROUTPUT ON
DECLARE
   v_zi VARCHAR2(10) := 'luni';
BEGIN
   CASE v_zi
      WHEN 'luni' THEN DBMS_OUTPUT.PUT_LINE('Început de săptămână');
      WHEN 'vineri' THEN DBMS_OUTPUT.PUT_LINE('Sfârșit de săptămână');
      ELSE DBMS_OUTPUT.PUT_LINE('Zi obișnuită');
   END CASE;
END;

/*********** Exemplu practic: Simple CASE (comparare directă a unei expresii) ***********/
SELECT
    first_name,
    last_name,
     CASE 
         WHEN salary >= 5000 THEN 'Bun'
         ELSE 'Mediu'
       END AS evaluare
FROM employees;


/*****************  Recomandări *********************************************
Folosește CASE când ai mai multe valori de comparat pentru o singură expresie.
Alege searched CASE când condițiile sunt diferite și complexe.
CASE este extrem de util și în SQL simplu sau în atribuiri directe de variabile.
*******************************************************************************************/

/*********** Exemplu practic: IF simplu ***********/
SET SERVEROUTPUT ON
DECLARE
   v_nota NUMBER := 9;
BEGIN
   IF v_nota >= 5 THEN
      DBMS_OUTPUT.PUT_LINE('Student promovat');
   END IF;
END;

/*********** Exemplu practic: IF...ELSE ***********/
DECLARE
   v_varsta NUMBER := 16;
BEGIN
   IF v_varsta >= 18 THEN
      DBMS_OUTPUT.PUT_LINE('Major');
   ELSE
      DBMS_OUTPUT.PUT_LINE('Minor');
   END IF;
END;

/*********** Exemplu practic: IF...ELSIF...ELSE ***********/
DECLARE
   v_scor NUMBER := 78;
BEGIN
   IF v_scor >= 90 THEN
      DBMS_OUTPUT.PUT_LINE('Excelent');
   ELSIF v_scor >= 75 THEN
      DBMS_OUTPUT.PUT_LINE('Foarte bine');
   ELSIF v_scor >= 60 THEN
      DBMS_OUTPUT.PUT_LINE('Acceptabil');
   ELSE
      DBMS_OUTPUT.PUT_LINE('Respins');
   END IF;
END;
/*********** Exemplu practic: bloc imbricat ***********/
SET SERVEROUTPUT ON
DECLARE
   v_global_var NUMBER := 10;
BEGIN
   DBMS_OUTPUT.PUT_LINE('Bloc exterior: ' || v_global_var);

   DECLARE
      v_local_var NUMBER := 5;
   BEGIN
      DBMS_OUTPUT.PUT_LINE('Bloc interior: ' || v_local_var);
      DBMS_OUTPUT.PUT_LINE('Accesare v_global_var din interior: ' || v_global_var);
   END;

   -- DBMS_OUTPUT.PUT_LINE(v_local_var);  -- Aceasta va produce eroare!
END;

/*********** Exemplu practic: Exemplu de mascare ***********/
SET SERVEROUTPUT ON
DECLARE
   var_name VARCHAR2(20) := 'Exterior';
BEGIN
   DBMS_OUTPUT.PUT_LINE('Exterior: ' || var_name);

   DECLARE
      var_name VARCHAR2(20) := 'Interior';
   BEGIN
      DBMS_OUTPUT.PUT_LINE('Interior: ' || var_name); -- Va afișa "Interior"
   END;

   DBMS_OUTPUT.PUT_LINE('După interior: ' || var_name); -- Va afișa "Exterior"
END;

/*****************  Recomandări  *********************************************
* Folosește variabile locale în blocuri interioare pentru a evita conflictele de nume.
* Adoptă o convenție de denumire clară dacă ai blocuri imbricate, pentru a evita confuziile legate de vizibilitate.
* Testează codul folosind DBMS_OUTPUT.PUT_LINE pentru a urmări valorile și domeniul de vizibilitate al variabilelor.
*******************************************************************************************/
/*********** Exemplu practic: IF simplu ***********/
SET SERVEROUTPUT ON
DECLARE
   v_nota NUMBER := 9;
BEGIN
   IF v_nota >= 5 THEN
      DBMS_OUTPUT.PUT_LINE('Student promovat');
   END IF;
END;

/*********** Exemplu practic: IF...ELSE ***********/
DECLARE
   v_varsta NUMBER := 16;
BEGIN
   IF v_varsta >= 18 THEN
      DBMS_OUTPUT.PUT_LINE('Major');
   ELSE
      DBMS_OUTPUT.PUT_LINE('Minor');
   END IF;
END;

/*********** Exemplu practic: IF...ELSIF...ELSE ***********/
DECLARE
   v_scor NUMBER := 78;
BEGIN
   IF v_scor >= 90 THEN
      DBMS_OUTPUT.PUT_LINE('Excelent');
   ELSIF v_scor >= 75 THEN
      DBMS_OUTPUT.PUT_LINE('Foarte bine');
   ELSIF v_scor >= 60 THEN
      DBMS_OUTPUT.PUT_LINE('Acceptabil');
   ELSE
      DBMS_OUTPUT.PUT_LINE('Respins');
   END IF;
END;


/*****************  Recomandări *********************************************
* Condițiile pot folosi operatori logici: =, !=, <, >, <=, >=, AND, OR, NOT.
* Pentru compararea șirurilor, se folosește operatorul = (ex: IF nume = 'Ion' THEN ...).
* IF poate fi imbricat în alte IF, LOOP, CASE, sau funcții.
*******************************************************************************************/


/*********** Exemplu practic: Basic Loops - Loop simplu ***********/
SET SERVEROUTPUT ON
DECLARE
  v_nr		  NUMBER(2) := 1;
BEGIN
  LOOP
     IF MOD(v_nr, 2) = 0 THEN
         DBMS_OUTPUT.PUT_LINE(v_nr || ' este numar par ');
      ELSE
         DBMS_OUTPUT.PUT_LINE(v_nr || ' este numar impar ');
      END IF;
      v_nr := v_nr + 1;
    EXIT WHEN v_nr > 3;
  END LOOP;
END;
/

/*********** Exemplu practic: WHILE ***********/
DECLARE
   v_contor NUMBER := 1;
BEGIN
   WHILE v_contor <= 5 LOOP
      DBMS_OUTPUT.PUT_LINE('Valoarea contorului: ' || v_contor);
      v_contor := v_contor + 1;
   END LOOP;
END;

/*********** Exemplu practic: WHILE and IF ***********/
DECLARE
   v_nr NUMBER := 1;
BEGIN
   WHILE v_nr <= 5 LOOP
      IF MOD(v_nr, 2) = 0 THEN
         DBMS_OUTPUT.PUT_LINE(v_nr || ' este par');
      ELSE
         DBMS_OUTPUT.PUT_LINE(v_nr || ' este impar');
      END IF;
      v_nr := v_nr + 1;
   END LOOP;
END;

/*********** Exemplu practic:  buclă crescătoare ***********/
SET SERVEROUTPUT ON
BEGIN
   FOR i IN 1..5 LOOP
      DBMS_OUTPUT.PUT_LINE('Valoarea lui i: ' || i);
   END LOOP;
END;

/*********** Exemplu practic: buclă descrescătoare cu REVERSE ***********/
SET SERVEROUTPUT ON
BEGIN
   FOR i IN REVERSE 5..1 LOOP
      DBMS_OUTPUT.PUT_LINE('i descrescător: ' || i);
   END LOOP;
END;

/*********** Exemplu practic: buclelor îmbinate ***********/
SET SERVEROUTPUT ON
DECLARE
   i NUMBER := 1;
   j NUMBER;
BEGIN
   LOOP  -- buclă exterioară
      j := 1;

      LOOP  -- buclă interioară
         IF MOD(i + j, 2) = 0 THEN
            DBMS_OUTPUT.PUT_LINE('Suma lui ' || i || ' + ' || j || ' este pară');
         END IF;

         j := j + 1;
         EXIT WHEN j > 3;
      END LOOP;

      i := i + 1;
      EXIT WHEN i > 3;
   END LOOP;
END;

/*********** Exemplu practic: tabel de înmulțire ***********/
SET SERVEROUTPUT ON
DECLARE
   i NUMBER := 1;
   j NUMBER;
BEGIN
   LOOP  -- bucla pentru rânduri (1 la 5)
      j := 1;

      LOOP  -- bucla pentru coloane (1 la 10)
         DBMS_OUTPUT.PUT_LINE(i || ' x ' || j || ' = ' || (i * j));
         j := j + 1;
         EXIT WHEN j > 10;
      END LOOP;  -- bucla pentru coloane 

      i := i + 1;
      EXIT WHEN i > 5;
   END LOOP; -- bucla pentru rânduri 
END;
/*****************  Recomandări *********************************************
* Folosește EXIT WHEN în LOOP simplu pentru controlul fluxului.
* FOR LOOP este ideal pentru un număr cunoscut de iterații.
* WHILE LOOP este mai potrivit când condiția este dinamică.
* Combinarea IF cu LOOP îți permite să controlezi execuția fiecărei iterații.
*******************************************************************************************/

/*********** Exemplu practic: etichete pentru bucle imbricate ***********/
SET SERVEROUTPUT ON
DECLARE
   i NUMBER := 1;
   j NUMBER;
BEGIN
   <<outer_loop>>
   LOOP
      j := 1;

      <<inner_loop>>
      LOOP
         EXIT inner_loop WHEN j > 2;
         DBMS_OUTPUT.PUT_LINE('i=' || i || ', j=' || j);
         j := j + 1;
      END LOOP;

      i := i + 1;
      EXIT outer_loop WHEN i > 2;
   END LOOP;
END;


/*********** Exemplu practic: GOTO ***********/
SET SERVEROUTPUT ON
DECLARE
   v_x NUMBER := 5;
BEGIN
   IF v_x < 10 THEN
      GOTO prea_mic;
   END IF;

   DBMS_OUTPUT.PUT_LINE('Număr acceptabil');

   <<prea_mic>>
   DBMS_OUTPUT.PUT_LINE('Numărul este prea mic');
END;

/*********** Exemplu practic:  ieșire forțată dintr-un LOOP ***********/
SET SERVEROUTPUT ON
DECLARE
   i NUMBER := 1;
BEGIN
   LOOP
      DBMS_OUTPUT.PUT_LINE('i = ' || i);
      i := i + 1;
      IF i > 3 THEN
         GOTO iesire;
      END IF;
   END LOOP;

   <<iesire>>
   DBMS_OUTPUT.PUT_LINE('Am ieșit din buclă');
END;