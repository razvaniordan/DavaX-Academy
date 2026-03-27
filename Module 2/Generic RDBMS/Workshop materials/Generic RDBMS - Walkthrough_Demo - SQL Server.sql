/*
Key components for an RDBMS System - SQL Server:
| ----------------------- | ---------------------------------------------------------------------------------------------------- |
| **Relational Engine**   | Also called the **Query Processor**, responsible for parsing, optimizing, and executing SQL queries. |
| **Storage Engine**      | Handles reading/writing data to disk, manages pages, extents, and filegroups.                        |
| **Buffer Manager**      | Caches data pages in memory to reduce disk I/O – vital for performance.                              |
| **Transaction Manager** | Controls transaction boundaries and ensures **ACID compliance**.                                     |
| **Lock Manager**        | Handles concurrency via locks, ensuring **isolation** and deadlock detection.                        |
| **Log Manager**         | Writes to the transaction **log file** (`.ldf`) for durability and recovery.                         |
| **SQL OS**              | Internal abstraction over OS resources: scheduling, memory, I/O, and workers.                        |
| **Protocol Layer**      | Manages communication via TDS (Tabular Data Stream) between clients and SQL Server.                  |

*/


-- PAS 1: Creare baza de date in locatie specifica
create database DavaX
on primary (
    name = 'DavaX_Data',
    filename = 'C:\\SQL_Database\\DavaX_Data.mdf',
    size = 100mb,
    filegrowth = 50mb
)
log on (
    name = 'DavaX_Log',
    filename = 'C:\\SQL_Database\\DavaX_Log.ldf',
    size = 50mb,
    filegrowth = 50mb
);
go

-- PAS 2: Adaugare FILEGROUP pentru indecsi
alter database DavaX add filegroup FG_Index;

alter database DavaX
add file (name = 'DavaX_Index', filename = 'C:\\SQL_Database\\DavaX_Index.ndf')
  to filegroup FG_Index;
go

select * from sys.databases
go

select * from sys.filegroups
go
select * from sys.database_files
go

use DavaX;
go

-- PAS 3: Creare schema si tabele pentru teste
create schema shop;
go

create schema sales;
go

create table shop.Categorii (
    categorie_id int primary key,
    nume varchar(100) not null
);
go

create table shop.Articole (
    articol_id int primary key,
    nume varchar(100) not null,
    pret decimal(10,2) check (pret > 0),
    stoc int check (stoc >= 0)
);
go

create table shop.ArticolCategorie (
    articol_id int,
    categorie_id int,
    primary key (articol_id, categorie_id),
    foreign key (articol_id) references shop.Articole(articol_id),
    foreign key (categorie_id) references shop.Categorii(categorie_id)
);
go

create table shop.Vanzari (
    vanzare_id int primary key,
    articol_id int,
    data_vanzare date check (data_vanzare <= getdate()),
    cantitate int check (cantitate > 0),
    foreign key (articol_id) references shop.Articole(articol_id)
);
go

-- PAS 5: Populare tabele cu date
insert into shop.Categorii values (1, 'Scule'), (2, 'Materiale'), (3, 'Electrice');
go

insert into shop.Articole
select top 500 row_number() over (order by (select null)), concat('Articol_', row_number() over (order by (select null))), rand()*100+10, 100+row_number() over (order by (select null))
from sys.all_objects;
go

insert into shop.ArticolCategorie
select a.articol_id, (a.articol_id % 3) + 1 from shop.Articole a;
go
--select * from shop.Vanzari
-- truncate table shop.Vanzari
insert into shop.Vanzari
select top 20000 row_number() over (order by (select null)),
       a.articol_id,
       dateadd(day, -abs(checksum(newid()) % 365), getdate()),
       (row_number() over (order by a.articol_id)%10 )+ a.articol_id
from shop.Articole a
cross apply (select top 50 * from sys.all_objects) x
go

-- PAS 6: Creare view-uri
create or alter view sales.View_ArticoleVanzari as
select a.nume, v.vanzare_id, v.data_vanzare, v.cantitate
from shop.Articole a
left join shop.Vanzari v on a.articol_id = v.articol_id;
go

create or alter view sales.View_Vanzari_Lunare as
select a.nume, format(v.data_vanzare, 'yyyy-MM') as luna,
       sum(v.cantitate) as total_cantitate
from shop.Articole a
	inner join shop.Vanzari v on a.articol_id = v.articol_id
group by a.nume, format(v.data_vanzare, 'yyyy-MM');
go

create or alter view sales.View_Vanzari_Categorii as
select c.nume as categorie, sum(v.cantitate) as total_cantitate
from shop.Vanzari v
	inner join shop.Articole a on v.articol_id = a.articol_id
	inner join shop.ArticolCategorie ac on a.articol_id = ac.articol_id
	inner join shop.Categorii c on ac.categorie_id = c.categorie_id
group by c.nume;
go

-- PAS 7: exec plan
select * from sales.View_ArticoleVanzari;
go
select * from sales.View_Vanzari_Lunare;
go
select * from sales.View_Vanzari_Categorii;
go

-- PAS 8: check constraint failure
begin transaction;
insert into shop.Vanzari values (99990, 1, '2030-01-01', 5); -- data in viitor, nu respecta CK

--select * from shop.Vanzari where vanzare_id = 99990
rollback;
go


-- PAS 9: ACID
-- Atomicitate: insert-ul fie reuseste complet, fie este anulat
-- Consistenta: se respecta regulile de validare (CK, FK)
-- Izolare: tranzactia nu interfereaza cu altele
-- Durabilitate: la commit, modificarile sunt persistente

-- PAS 10: Insert valid
begin transaction;
	insert into shop.Vanzari values (100000, 1, getdate(), 3);
	--select * from shop.Vanzari where vanzare_id = 100000
commit
go

-- PAS 11: Transactions
-- Sesiunea 1:
begin transaction;
insert into shop.Vanzari values (100012, 1, getdate(), 2);

--SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
-- SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
--select * from shop.Vanzari where vanzare_id = 100012;

-- Sesiunea 2:
-- select * from shop.Vanzari where vanzare_id = 100013;
-- rollback transaction
commit transaction
go
/*
-- blocking sessions
SELECT 
    blocking_session_id AS blocker,
    r.session_id AS blocked,
    wait_type,
    wait_time,
    wait_resource,
    text AS sql_text
FROM 
    sys.dm_exec_requests r
JOIN 
    sys.dm_exec_sessions s ON r.session_id = s.session_id
CROSS APPLY 
    sys.dm_exec_sql_text(r.sql_handle)
WHERE 
    blocking_session_id <> 0
*/

--select articol_id, count(*) from shop.Vanzari group by articol_id
-- PAS 12: Query fara index si cu index
select * from shop.Vanzari where articol_id = 1;
go
create nonclustered index IX_Vanzari_Articol on shop.Vanzari(articol_id) ON FG_Index;
go


select * from shop.Vanzari where articol_id = 1;

select * from shop.Vanzari where articol_id = 19;

UPDATE STATISTICS shop.Vanzari
--	drop index IX_Vanzari_Articol on shop.Vanzari
go

delete TOP (90) PERCENT
from shop.Vanzari 
where articol_id = 19

-- check statistics in object explorer

go

-- PAS 13: View materializat (Indexed View)
create view shop.View_Materializat_VanzariArticole
with schemabinding
as
select a.articol_id, a.nume, count_big(*) as nr_vanzari
from shop.Articole a
join shop.Vanzari v on a.articol_id = v.articol_id
group by a.articol_id, a.nume;
go

create unique clustered index IX_View_Materializat
on shop.View_Materializat_VanzariArticole(articol_id);
go

--PAS 14: Proceduri stocate
create or alter procedure shop.show_articol_sale_count
	@nume_articol varchar(100)
AS
BEGIN
	DECLARE @articol_id int
	SET @articol_id = (select articol_id from shop.Articole where nume = @nume_articol )

	select * FROM shop.View_Materializat_VanzariArticole where articol_id = @articol_id order by 1

END

EXEC shop.show_articol_sale_count @nume_articol = 'Articol_20'

-- PAS 15: tabele temporare
DROP TABLE IF EXISTS #temp_view_articole
SELECT *
INTO #temp_view_articole
FROM shop.View_Materializat_VanzariArticole

DROP TABLE IF EXISTS ##temp_view_articole
SELECT *
INTO ##temp_view_articole
FROM shop.View_Materializat_VanzariArticole
SELECT top 10 * FROM #temp_view_articole
SELECT top 10 * FROM ##temp_view_articole


-- PAS 16 - User nou cu acces limitat

-- 1. Creează login la nivel de server
CREATE LOGIN sales_dummy_user 
WITH PASSWORD = 'StrongPassword123!', CHECK_POLICY = ON;
GO

-- 2. Creează user în baza de date Davax
USE Davax;
GO
CREATE USER sales_dummy_user FOR LOGIN sales_dummy_user;
GO

-- 3. Creează un rol read-only pentru schema sales dacă nu există
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'SalesReadOnly')
BEGIN
    CREATE ROLE SalesReadOnly;
END
GO

-- 4. Acordă permisiuni de SELECT pe toate obiectele din schema sales
GRANT SELECT ON SCHEMA::sales TO SalesReadOnly;
GO

-- 5. Adaugă userul în rol
EXEC sp_addrolemember 'SalesReadOnly', 'sales_dummy_user';
GO
