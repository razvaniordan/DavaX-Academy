 
-- PAS 1: Creare tablespace si user
CREATE TABLESPACE davax_data DATAFILE 'davax_data.dbf' SIZE 100M AUTOEXTEND ON NEXT 10M;
CREATE TABLESPACE davax_index DATAFILE 'davax_index.dbf' SIZE 50M AUTOEXTEND ON NEXT 5M;

CREATE USER davax IDENTIFIED BY davax_pass DEFAULT TABLESPACE davax_data TEMPORARY TABLESPACE temp;
GRANT CONNECT, RESOURCE TO davax;
ALTER USER davax QUOTA UNLIMITED ON davax_data;
ALTER USER davax QUOTA UNLIMITED ON davax_index;


-- PAS 2: Creare tabele (schema implicita: user)
CREATE TABLE Categorii (
    categorie_id NUMBER PRIMARY KEY,
    nume VARCHAR2(100) NOT NULL
) TABLESPACE davax_data;

CREATE TABLE Articole (
    articol_id NUMBER PRIMARY KEY,
    nume VARCHAR2(100) NOT NULL,
    pret NUMBER(10,2) CHECK (pret > 0),
    stoc NUMBER CHECK (stoc >= 0)
) TABLESPACE davax_data; 


CREATE TABLE ArticolCategorie (
    articol_id NUMBER,
    categorie_id NUMBER,
    PRIMARY KEY (articol_id, categorie_id),
    FOREIGN KEY (articol_id) REFERENCES Articole(articol_id),
    FOREIGN KEY (categorie_id) REFERENCES Categorii(categorie_id)
) TABLESPACE davax_data;

CREATE TABLE Vanzari (
    vanzare_id NUMBER PRIMARY KEY,
    articol_id NUMBER,
    data_vanzare DATE CHECK (data_vanzare <= SYSDATE), ---!!!
    cantitate NUMBER CHECK (cantitate > 0),
    FOREIGN KEY (articol_id) REFERENCES Articole(articol_id)
) TABLESPACE davax_data;

CREATE OR REPLACE TRIGGER trg_check_data_vanzare
BEFORE INSERT OR UPDATE ON Vanzari
FOR EACH ROW
BEGIN
    IF :NEW.data_vanzare > SYSDATE THEN
        RAISE_APPLICATION_ERROR(-20001, 'Data vanzarii nu poate fi in viitor.');
    END IF;
END;
/

-- PAS 3: Populare Categorii
INSERT INTO Categorii VALUES (1, 'Scule');
INSERT INTO Categorii VALUES (2, 'Materiale');
INSERT INTO Categorii VALUES (3, 'Electrice');

-- PAS 4: Populare Articole (simulare bulk insert)
BEGIN
  FOR i IN 1..500 LOOP
    INSERT INTO Articole (
      articol_id, nume, pret, stoc
    ) VALUES (
      i,
      'Articol_' || i,
      DBMS_RANDOM.VALUE(10, 110),
      100 + i
    );
  END LOOP;
END;
/

-- PAS 5: Populare ArticolCategorie
INSERT INTO ArticolCategorie
SELECT articol_id, MOD(articol_id, 3) + 1 FROM Articole;

-- PAS 6: Populare Vanzari (simulare bulk)
DECLARE
  v_id NUMBER := 1;
BEGIN
  FOR a IN (SELECT articol_id FROM Articole) LOOP
    FOR j IN 1..20 LOOP
      INSERT INTO Vanzari (
        vanzare_id,
        articol_id,
        data_vanzare,
        cantitate
      ) VALUES (
        v_id,
        a.articol_id,
        SYSDATE - DBMS_RANDOM.VALUE(1, 365),
        MOD(j,10) + a.articol_id
      );
      v_id := v_id + 1;
    END LOOP;
  END LOOP;
END;
/

-- PAS 7: View-uri
CREATE OR REPLACE VIEW View_ArticoleVanzari AS
SELECT a.nume, v.vanzare_id, v.data_vanzare, v.cantitate
FROM Articole a
LEFT JOIN Vanzari v ON a.articol_id = v.articol_id;

CREATE OR REPLACE VIEW View_Vanzari_Lunare AS
SELECT a.nume, TO_CHAR(v.data_vanzare, 'YYYY-MM') AS luna,
       SUM(v.cantitate) AS total_cantitate
FROM Articole a
JOIN Vanzari v ON a.articol_id = v.articol_id
GROUP BY a.nume, TO_CHAR(v.data_vanzare, 'YYYY-MM');

CREATE OR REPLACE VIEW View_Vanzari_Categorii AS
SELECT c.nume AS categorie, SUM(v.cantitate) AS total_cantitate
FROM Vanzari v
JOIN Articole a ON v.articol_id = a.articol_id
JOIN ArticolCategorie ac ON a.articol_id = ac.articol_id
JOIN Categorii c ON ac.categorie_id = c.categorie_id
GROUP BY c.nume;

-- PAS 8: Testare constraint
BEGIN
  INSERT INTO Vanzari VALUES (99990, 1, TO_DATE('2030-01-01', 'YYYY-MM-DD'), 5);
EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK;
END;
/

-- PAS 9: Insert valid
BEGIN
  INSERT INTO Vanzari VALUES (100000, 1, SYSDATE, 3);
  COMMIT;
END;
/

-- PAS 10: Index pe articol_id
CREATE INDEX IX_Vanzari_Articol ON Vanzari(articol_id) TABLESPACE davax_index;

-- PAS 11: View materializat
CREATE MATERIALIZED VIEW View_Materializat_VanzariArticole
BUILD IMMEDIATE
REFRESH COMPLETE ON DEMAND
ENABLE QUERY REWRITE
AS
SELECT a.articol_id, a.nume, COUNT(*) AS nr_vanzari
FROM Articole a
JOIN Vanzari v ON a.articol_id = v.articol_id
GROUP BY a.articol_id, a.nume;

-- Optional: EXEC plan, statistici
EXEC DBMS_STATS.GATHER_TABLE_STATS('DAVAX', 'VANZARI');

--=====================
--modificari
----===================

ALTER TABLE Articole
ADD moneda VARCHAR2(10) DEFAULT 'RON' NOT NULL;

--sau
ALTER TABLE Articole ADD moneda VARCHAR2(10);

UPDATE Articole
SET moneda = 'RON';

ALTER TABLE Articole MODIFY moneda DEFAULT 'RON' NOT NULL;

alter table Articole add desciere clob;

ALTER TABLE Articole ADD photo BLOB;

ALTER TABLE Articole MODIFY LOB (photo)
  (STORE AS SECUREFILE DEDUPLICATE CACHE); --???
  
create table Articole2 as 
select * from Articole;

Drop table Articole purge;--!!!



CREATE TABLE Articole (
    articol_id NUMBER PRIMARY KEY,
    denumire   VARCHAR2(100),
    pret       NUMBER(10, 2),
	moneda 	varchar2(3) default 'RON',
	desciere clob,
    photo      BLOB
)
LOB (photo) STORE AS SECUREFILE photo_lob (
    DEDUPLICATE
    COMPRESS HIGH
    CACHE
);


SELECT table_name, column_name, securefile, deduplication
FROM dba_lobs
WHERE table_name = 'ARTICOLE';

insert /*+append*/ into Articole -- atentie sa fie aceiasi proiectie
select * from articole2;
commit;

ALTER TABLE VANZARI ADD CONSTRAINT fk_articol
FOREIGN KEY (articol_id) REFERENCES ARTICOLE(articol_id);
