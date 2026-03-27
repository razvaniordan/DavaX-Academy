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