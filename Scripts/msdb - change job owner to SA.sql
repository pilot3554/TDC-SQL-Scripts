USE [msdb]
GO

DECLARE @name VARCHAR(50), @id uniqueidentifier
DECLARE @SQL nVARCHAR(4000) =''

DECLARE db_cursor CURSOR FOR  
select job_id, name from sysjobs

OPEN db_cursor  
FETCH NEXT FROM db_cursor INTO @id, @name  

WHILE @@FETCH_STATUS = 0  
BEGIN  
       print @name
       print @id

       set @SQL = 'EXEC msdb.dbo.sp_update_job @job_id=N'''+convert(nvarchar(100),@id)+''', 
		@owner_login_name=N''sa'''


		print @sql
		exec sp_executeSQL @sql

       FETCH NEXT FROM db_cursor INTO @id, @name  
END  

CLOSE db_cursor  
DEALLOCATE db_cursor