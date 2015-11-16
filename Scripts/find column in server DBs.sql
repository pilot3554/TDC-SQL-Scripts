use master

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
		set @sql ='use ['+@name+']; if exists(select * from sys.columns where name like ''%billingsta%'') select @@servername, db_name(), * from sys.columns where name like ''%billingsta%'' '
		--PRINT @sql
		exec sp_executesql @sql
       FETCH NEXT FROM db_cursor INTO @name  
END  

CLOSE db_cursor  
DEALLOCATE db_cursor