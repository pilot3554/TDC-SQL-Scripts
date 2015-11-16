



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
       --print @name
       set @sql = 'EXEC ['+@name+'].dbo.sp_changedbowner @loginame = N''sa'', @map = false'
       print @sql
       print 'go'
       --exec sp_executesql @sql	

       FETCH NEXT FROM db_cursor INTO @name  
END  

CLOSE db_cursor  
DEALLOCATE db_cursor