USE [msdb]
GO

IF  NOT EXISTS (SELECT name FROM msdb.dbo.sysoperators WHERE name = N'DBA')
--EXEC msdb.dbo.sp_delete_operator @name=N'DBA'
BEGIN

EXEC msdb.dbo.sp_add_operator @name=N'DBA', 
		@enabled=1, 
		@weekday_pager_start_time=90000, 
		@weekday_pager_end_time=180000, 
		@saturday_pager_start_time=90000, 
		@saturday_pager_end_time=180000, 
		@sunday_pager_start_time=90000, 
		@sunday_pager_end_time=180000, 
		@pager_days=0, 
		@email_address=N'patrick.alexander@technicolor.com;sylvain.delporte@technicolor.com;john.baek@technicolor.com', 
		@category_name=N'[Uncategorized]'
END
GO

DECLARE @name VARCHAR(50), @id uniqueidentifier
DECLARE @SQL nVARCHAR(4000) =''

DECLARE db_cursor CURSOR FOR  
select job_id, name from sysjobs  where notify_email_operator_id = 0

OPEN db_cursor  
FETCH NEXT FROM db_cursor INTO @id, @name  

WHILE @@FETCH_STATUS = 0  
BEGIN  
       print @name
       print @id
       set @SQL = 'EXEC msdb.dbo.sp_update_job @job_id=N'''+convert(nvarchar(100),@id)+''', 
		@notify_level_email=2, 
		@notify_level_netsend=2, 
		@notify_level_page=2, 
		@notify_email_operator_name=N''DBA'''
		print @sql
		exec sp_executeSQL @sql

       FETCH NEXT FROM db_cursor INTO @id, @name  
END  

CLOSE db_cursor  
DEALLOCATE db_cursor