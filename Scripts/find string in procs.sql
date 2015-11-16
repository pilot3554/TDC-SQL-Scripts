--SELECT DISTINCT o.name AS Object_Name,o.type_desc, m.definition
--FROM sys.sql_modules m 
--INNER JOIN sys.objects o 
--ON m.object_id=o.object_id
--WHERE m.definition Like '%sp_send_dbmail%'


use master
GO

IF object_id('tempdb..#tmp') >1
DROP TABLE #tmp

CREATE TABLE #tmp (servername  varchar(100), dbname  varchar(100), objectname  varchar(100), objecttype varchar(100))

DECLARE @name VARCHAR(50) , @sql nvarchar(4000)


DECLARE db_cursor CURSOR FOR  
SELECT name
FROM MASTER.dbo.sysdatabases
WHERE name NOT IN ('master','model','msdb','tempdb')  

OPEN db_cursor  
FETCH NEXT FROM db_cursor INTO @name  

WHILE @@FETCH_STATUS = 0  
BEGIN  
       print @name
		set @sql ='use ['+@name+']; SELECT DISTINCT @@servername as servername, db_name() as dbname, o.name AS Object_Name,o.type_desc FROM sys.sql_modules m  INNER JOIN sys.objects o  ON m.object_id=o.object_id WHERE m.definition Like ''%@technicolor.com%'''
		PRINT @sql
		INSERT INTO #tmp
		exec sp_executesql @sql
       FETCH NEXT FROM db_cursor INTO @name  
END  

CLOSE db_cursor  
DEALLOCATE db_cursor

SELECT * FROM #tmp
Go