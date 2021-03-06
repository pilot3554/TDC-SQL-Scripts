use msdb
go

DECLARE @name VARCHAR(500) -- database name  
declare @sql nvarchar(max)

DECLARE db_cursor CURSOR FOR  
select name
From sysjobs
where notify_level_email = 0
order by name

OPEN db_cursor  
FETCH NEXT FROM db_cursor INTO @name  

WHILE @@FETCH_STATUS = 0  
BEGIN  
       print @name
  --     set @sql = 'EXEC msdb.dbo.sp_update_job @job_name=N'''+@name+''', 
		--@notify_level_email=2, 
		--@notify_level_netsend=2, 
		--@notify_level_page=2'
		
		
		set @sql = 'EXEC msdb.dbo.sp_update_job @job_name=N'''+@name+''', 
		@notify_level_email=2, 
		@notify_level_netsend=2, 
		@notify_level_page=2, 
		@notify_email_operator_name=N''Prod DBA'''
		
		print @sql
		exec sp_executesql @sql
		

       FETCH NEXT FROM db_cursor INTO @name  
END  

CLOSE db_cursor  
DEALLOCATE db_cursor