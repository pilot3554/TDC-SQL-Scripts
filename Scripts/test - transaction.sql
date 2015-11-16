USE test
GO

DROP table testTran 
CREATE table testTran (id int, Name varchar(100))
go

-- 85 sec
-- Autocommit transaction
declare @i int
set @i = 0
while @i < 10000
begin 
insert into testTran values (1,'test record')
set @i = @i+1
END

-- 1< sec
-- Implicit transaction
SET IMPLICIT_TRANSACTIONS ON
declare @i int
set @i = 0
while @i < 1000
begin 
insert into testTran values (1,'test record')
set @i = @i+1
end
COMMIT;
SET IMPLICIT_TRANSACTIONS OFF


----------------------------------------------------
-- 1< sec
-- Explicit transaction
declare @i int
set @i = 0
BEGIN TRAN
WHILE @i < 1000
Begin
INSERT INTO testTran values (1,'test record')
set @i = @i+1
End
COMMIT TRAN

--http://dba.stackexchange.com/questions/43254/is-it-a-bad-practice-to-always-create-a-transaction-