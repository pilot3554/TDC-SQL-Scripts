DECLARE @name VARCHAR(50) 
declare @account nvarchar(100) = 'am\mentak'
declare @sql nvarchar(4000) 

DECLARE db_cursor CURSOR FOR  
SELECT name
From sys.procedures
UNION ALL
SELECT name
From sys.tables
UNION ALL
SELECT name
From sys.views
UNION ALL
SELECT name
FROM sys.objects
WHERE type IN ('FN', 'IF', 'TF','FS')


OPEN db_cursor  
FETCH NEXT FROM db_cursor INTO @name  

WHILE @@FETCH_STATUS = 0  
BEGIN  
       print @name
       set @sql = 'GRANT VIEW DEFINITION ON [dbo].['+@name+'] TO ['+@account+']'
       PRINT @SQL
       EXEC SP_EXECUTESQL @SQL

       FETCH NEXT FROM db_cursor INTO @name  
END  

CLOSE db_cursor  
DEALLOCATE db_cursor