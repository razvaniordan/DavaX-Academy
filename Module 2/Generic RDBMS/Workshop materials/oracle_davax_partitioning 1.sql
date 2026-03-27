CREATE TABLE Vanzari_Range (
    vanzare_id NUMBER PRIMARY KEY,
    articol_id NUMBER,
    data_vanzare DATE,
    cantitate NUMBER,
    FOREIGN KEY (articol_id) REFERENCES Articole(articol_id)
)
PARTITION BY RANGE (data_vanzare) (
    PARTITION p_2022 VALUES LESS THAN (TO_DATE('2023-01-01', 'YYYY-MM-DD')),
    PARTITION p_2023 VALUES LESS THAN (TO_DATE('2024-01-01', 'YYYY-MM-DD')),
    PARTITION p_2024 VALUES LESS THAN (TO_DATE('2025-01-01', 'YYYY-MM-DD')),
    PARTITION p_max VALUES LESS THAN (MAXVALUE)
);
ALTER TABLE Vanzari_Range
ADD PARTITION p_2024_07 VALUES LESS THAN (TO_DATE('2024-08-01', 'YYYY-MM-DD'));

--sau interval
CREATE TABLE Vanzari_Interval (
    vanzare_id NUMBER PRIMARY KEY,
    articol_id NUMBER,
    data_vanzare DATE,
    cantitate NUMBER,
   FOREIGN KEY (articol_id) REFERENCES Articole(articol_id)
)
PARTITION BY RANGE (data_vanzare) INTERVAL (NUMTOYMINTERVAL(1,'MONTH')) (
    PARTITION p_2022 VALUES LESS THAN (TO_DATE('2023-01-01', 'YYYY-MM-DD'))
);

insert /*+append*/ into  Vanzari_Interval 
select * from Vanzari;

--limitate la partitie daca nu stiu numele dar stiu o valoare
SELECT * FROM Vanzari_Interval PARTITION FOR (DATE '2022-04-15');


select * from vanzari_interval AS of timestamp sysdate - 1/24/60;

drop table vanzari_interval;
flashback table vanzari_interval to before drop;


CREATE TABLE Vanzari_List (
    vanzare_id NUMBER PRIMARY KEY,
    articol_id NUMBER,
    data_vanzare DATE,
    cantitate NUMBER,
    FOREIGN KEY (articol_id) REFERENCES Articole(articol_id)
)
PARTITION BY LIST (articol_id) (
    PARTITION p_art_1_10 VALUES (1,2,3,4,5,6,7,8,9,10),
    PARTITION p_art_11_20 VALUES (11,12,13,14,15,16,17,18,19,20),
    PARTITION p_rest VALUES (DEFAULT)
);


CREATE TABLE Vanzari_Hash (
    vanzare_id NUMBER PRIMARY KEY,
    articol_id NUMBER,
    data_vanzare DATE,
    cantitate NUMBER,
    FOREIGN KEY (articol_id) REFERENCES Articole(articol_id)
)
PARTITION BY HASH (articol_id)
PARTITIONS 4;