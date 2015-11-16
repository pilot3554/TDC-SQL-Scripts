IF(OBJECT_ID('tempdb..#tmp')>1)
	DROP TABLE #tmp
CREATE TABLE #tmp ( 
servername NVARCHAR(256)
,DatabaseName NVARCHAR(256)
,TableName NVARCHAR(256)
,SchemaName NVARCHAR(256)
,RowCounts NVARCHAR(256)
,TotalSpaceKB NVARCHAR(256)
,UsedSpaceKB NVARCHAR(256)
,UnusedSpaceKB NVARCHAR(256)
)


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
       set @sql = 'use ['+@name+'];
       INSERT INTO #tmp
SELECT 
	@@servername as servername,
	DB_NAME() as DatabaseName,
    t.NAME AS TableName,
    s.Name AS SchemaName,
    p.rows AS RowCounts,
    SUM(a.total_pages) * 8 AS TotalSpaceKB, 
    SUM(a.used_pages) * 8 AS UsedSpaceKB, 
    (SUM(a.total_pages) - SUM(a.used_pages)) * 8 AS UnusedSpaceKB
FROM sys.tables t
INNER JOIN sys.indexes i ON t.OBJECT_ID = i.object_id
INNER JOIN sys.partitions p ON i.object_id = p.OBJECT_ID AND i.index_id = p.index_id
INNER JOIN sys.allocation_units a ON p.partition_id = a.container_id
LEFT OUTER JOIN sys.schemas s ON t.schema_id = s.schema_id
GROUP BY 
    t.Name, s.Name, p.Rows
ORDER BY 
    t.Name

'
       print @sql
       exec sp_executesql @sql	

       FETCH NEXT FROM db_cursor INTO @name  
END  

CLOSE db_cursor  
DEALLOCATE db_cursor

SELECT * FROM #tmp




SELECT @@servername, DB_NAME(database_id) AS DatabaseName,
Name AS Logical_Name,
Physical_Name, (size*8)/1024 SizeMB
FROM sys.master_files
