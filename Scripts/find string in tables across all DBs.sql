SET NOCOUNT ON;
DECLARE @tblname VARCHAR(500), @colname VARCHAR(500), @sch VARCHAR(500) ,@dbname VARCHAR(100)
DECLARE @sql NVARCHAR(max), @string nvarchar(100)
SET @string = 'tdcinema.int'

-------------------
DECLARE server_cursor CURSOR FOR  
SELECT name
FROM MASTER.dbo.sysdatabases
WHERE name NOT IN ('master','model','msdb','tempdb','distribution','ReportServer','ReportServerTempDB')  

OPEN server_cursor  
FETCH NEXT FROM server_cursor INTO @dbname  

WHILE @@FETCH_STATUS = 0  
BEGIN  
		PRINT '--------------------------'
       print '--'+@dbname
       set @sql = 'use ['+@dbname+']
       GO

SET NOCOUNT ON;
DECLARE @tblname VARCHAR(500), @colname VARCHAR(500), @sch VARCHAR(500) ,@dbname VARCHAR(100)
DECLARE @sql NVARCHAR(max), @string nvarchar(100)
SET @string = ''tdcinema.int''

DECLARE db_cursor CURSOR FOR  
SELECT o.name, c.name, s.name
FROM sys.columns c
INNER JOIN sys.objects o ON c.object_id = o.object_id
INNER JOIN sys.types t ON t.system_type_id = c.system_type_id
INNER JOIN sys.schemas s ON s.schema_id = o.schema_id
WHERE 
o.type = ''U''
AND t.name IN (''varchar'',''nvarchar'',''text'',''ntext'',''char'',''ncahr'')


OPEN db_cursor  
FETCH NEXT FROM db_cursor INTO @tblname  ,@colname,@sch

WHILE @@FETCH_STATUS = 0  
BEGIN  
       --print @tblname+''.''+@colname
       set @sql = ''if exists(select * from [''+@sch+''].[''+@tblname+''] with (nolock) where [''+@colname+''] like ''''%''+@string+''%'''') 
       begin 
       --select * from [''+@sch+''].[''+@tblname+''] with (nolock) where [''+@colname+''] like ''''%''+@string+''%''''
       print ''''''+@@servername+''.''+DB_NAME()+''.''+@tblname+''.''+@colname+''''''
       end''
       --print @sql
       exec sp_executesql @sql	

       FETCH NEXT FROM db_cursor INTO @tblname  ,@colname,@sch
END  

CLOSE db_cursor  
DEALLOCATE db_cursor
PRINT ''--------------------------''
GO       
       '
       print @sql

       FETCH NEXT FROM server_cursor INTO @dbname  
END  

CLOSE server_cursor  
DEALLOCATE server_cursor
-------------------
