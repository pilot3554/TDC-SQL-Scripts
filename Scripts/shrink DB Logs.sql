
DECLARE @name VARCHAR(500) 
DECLARE @sql NVARCHAR(max)

DECLARE db_cursor CURSOR FOR  
SELECT name
FROM MASTER.dbo.sysdatabases
WHERE name NOT IN ('master','model','msdb','tempdb','distribution','ReportServer','ReportServerTempDB')  

OPEN db_cursor  
FETCH NEXT FROM db_cursor INTO @name  

WHILE @@FETCH_STATUS = 0  
BEGIN  
       print @name
       set @sql = '
       USE [master]
ALTER DATABASE ['+@name+'] SET RECOVERY SIMPLE WITH NO_WAIT

USE ['+@name+']
DBCC SHRINKFILE (2 , 0, TRUNCATEONLY)
DBCC SHRINKFILE (2 , 0)
DBCC SHRINKFILE (2 , EMPTYFILE)
'
       print @sql
       exec sp_executesql @sql	

       FETCH NEXT FROM db_cursor INTO @name  
END  

CLOSE db_cursor  
DEALLOCATE db_cursor