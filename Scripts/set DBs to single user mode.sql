USE [master]
GO


DECLARE @name VARCHAR(500) 
DECLARE @sql NVARCHAR(max)

DECLARE db_cursor CURSOR FOR  
SELECT name
FROM MASTER.sys.databases
WHERE name NOT IN ('master','model','msdb','tempdb','distribution','ReportServer','ReportServerTempDB') AND user_access_desc != 'SINGLE_USER'

OPEN db_cursor  
FETCH NEXT FROM db_cursor INTO @name  

WHILE @@FETCH_STATUS = 0  
BEGIN  
       print @name
	   set @sql = 'ALTER DATABASE ['+@name+'] SET  SINGLE_USER WITH ROLLBACK IMMEDIATE'
       print @sql
       exec sp_executesql @sql	

       FETCH NEXT FROM db_cursor INTO @name  
END  

CLOSE db_cursor  
DEALLOCATE db_cursor