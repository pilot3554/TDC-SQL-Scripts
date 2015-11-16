--top 5 by AVG CPU
SELECT TOP 5 query_stats.query_hash AS "Query Hash", 
    SUM(query_stats.total_worker_time) / SUM(query_stats.execution_count) AS "Avg CPU Time",
    MIN(query_stats.statement_text) AS "Statement Text"
FROM 
    (SELECT QS.*, 
    SUBSTRING(ST.text, (QS.statement_start_offset/2) + 1,
    ((CASE statement_end_offset 
        WHEN -1 THEN DATALENGTH(ST.text)
        ELSE QS.statement_end_offset END 
            - QS.statement_start_offset)/2) + 1) AS statement_text
     FROM sys.dm_exec_query_stats AS QS
     CROSS APPLY sys.dm_exec_sql_text(QS.sql_handle) as ST) as query_stats
GROUP BY query_stats.query_hash
ORDER BY 2 DESC;

--top 5 by execution count
SELECT top 5 qs.execution_count,
    SUBSTRING(qt.text,qs.statement_start_offset/2 +1, 
                 (CASE WHEN qs.statement_end_offset = -1 
                       THEN LEN(CONVERT(nvarchar(max), qt.text)) * 2 
                       ELSE qs.statement_end_offset end -
                            qs.statement_start_offset
                 )/2
             ) AS query_text, 
     qt.dbid, dbname= DB_NAME (qt.dbid), qt.objectid, 
     qs.total_rows, qs.last_rows, qs.min_rows, qs.max_rows
FROM sys.dm_exec_query_stats AS qs 
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS qt 
WHERE qt.text like '%SELECT%' 
ORDER BY qs.execution_count DESC;

--top 10 queries by total time / average time / user count
SELECT top 100 
DB_NAME(st.dbid) DBName
,OBJECT_SCHEMA_NAME(objectid,st.dbid) SchemaName
,OBJECT_NAME(objectid,st.dbid) StoredProcedure
,max(cp.usecounts) execution_count
,sum(qs.total_elapsed_time) total_elapsed_time
,sum(qs.total_elapsed_time) / max(cp.usecounts) avg_elapsed_time
FROM sys.dm_exec_query_stats qs CROSS APPLY sys.dm_exec_sql_text(qs.plan_handle) st
join sys.dm_exec_cached_plans cp on qs.plan_handle = cp.plan_handle
where  cp.objtype = 'proc'
group by DB_NAME(st.dbid),OBJECT_SCHEMA_NAME(objectid,st.dbid), OBJECT_NAME(objectid,st.dbid) 
--order by sum(qs.total_elapsed_time) desc
order by sum(qs.total_elapsed_time) / max(cp.usecounts) desc
--order by max(cp.usecounts) desc


--------------------------
-- ONLY PROCS
--------------------------
if object_id('tempdb..#x')>1
	drop table #x
	
CREATE TABLE #x(
    database_id INT, 
    DatabaseName SYSNAME, 
    SchemaName SYSNAME, 
    ProcedureName SYSNAME, 
    [object_id] INT);
DECLARE @sql NVARCHAR(MAX) = '';
SELECT 
    @sql = @sql + N'INSERT INTO #x SELECT ' + CONVERT(VARCHAR(50), d.database_id) + ', ''' + name + ''', s.name, p.name, p.[object_id]
    FROM ' + QUOTENAME(d.name) + '.sys.schemas AS s
    INNER JOIN ' + QUOTENAME(d.name) + '.sys.procedures AS p ON p.schema_id = s.schema_id;' FROM sys.databases d WHERE d.database_id > 4;
EXEC sp_executesql @sql;
--select * from #x

WITH PlanData AS (
SELECT
    st.[dbid] AS database_id,
    st.objectid AS [object_id],
    DB_NAME(st.[dbid]) AS DBName,
    OBJECT_SCHEMA_NAME(st.objectid, st.[dbid]) AS SchemaName,
    OBJECT_NAME(st.objectid, st.[dbid]) AS StoredProcedure,
    MAX(cp.usecounts) AS execution_count,
    SUM(qs.total_elapsed_time) AS total_elapsed_time,
    SUM(qs.total_elapsed_time) / MAX(cp.usecounts) AS avg_elapsed_time
 FROM
    sys.dm_exec_query_stats qs
    CROSS APPLY sys.dm_exec_sql_text(qs.plan_handle) st
    LEFT JOIN sys.dm_exec_cached_plans cp on cp.plan_handle = qs.plan_handle
WHERE
    cp.objtype = 'PROC'
GROUP BY
    st.[dbid],
    st.objectid,
    DB_NAME(st.[dbid]),
    OBJECT_SCHEMA_NAME(st.objectid, st.[dbid]), 
    OBJECT_NAME(st.objectid, st.[dbid]))
    
SELECT 
    x.DatabaseName,
    x.SchemaName,
    x.ProcedureName,
    pd.execution_count,
    pd.total_elapsed_time,
    pd.avg_elapsed_time
FROM 
    #x x
    LEFT JOIN PlanData pd ON pd.database_id = x.database_id AND pd.[object_id] = x.[object_id]
 
DROP TABLE #x;


-------------------------------------------
--top queries by IO
--http://blog.sqlauthority.com/2014/07/29/sql-server-ssms-top-queries-by-cpu-and-io/
SELECT TOP 10
creation_time
,       last_execution_time
,       total_logical_reads AS [LogicalReads]
,       total_logical_writes AS [LogicalWrites]
,       execution_count
,       total_logical_reads+total_logical_writes AS [AggIO]
,       (total_logical_reads+total_logical_writes)/(execution_count+0.0) AS [AvgIO]
,      st.TEXT
,       DB_NAME(st.dbid) AS database_name
,       st.objectid AS OBJECT_ID
FROM sys.dm_exec_query_stats  qs
CROSS APPLY sys.dm_exec_sql_text(sql_handle) st
WHERE total_logical_reads+total_logical_writes > 0
AND sql_handle IS NOT NULL
ORDER BY [AggIO] DESC


-------------------------------------------
--top queries by CPU
--http://blog.sqlauthority.com/2014/07/29/sql-server-ssms-top-queries-by-cpu-and-io/
SELECT TOP(10)
creation_time
,       last_execution_time
,       (total_worker_time+0.0)/1000 AS total_worker_time
,       (total_worker_time+0.0)/(execution_count*1000) AS [AvgCPUTime]
,       execution_count
,      st.TEXT
,       DB_NAME(st.dbid) AS database_name
,       st.objectid AS OBJECT_ID
FROM sys.dm_exec_query_stats  qs
CROSS APPLY sys.dm_exec_sql_text(sql_handle) st
WHERE total_worker_time > 0
ORDER BY total_worker_time DESC

-------------------------------------------
--top most expensive queries 
--http://blog.sqlauthority.com/2010/05/14/sql-server-find-most-expensive-queries-using-dmv/
SELECT TOP 10 
@@servername as servername,
DB_NAME(qt.dbid) AS database_name,
qt.objectid AS OBJECT_ID,
SUBSTRING(qt.TEXT, (qs.statement_start_offset/2)+1,
((CASE qs.statement_end_offset
WHEN -1 THEN DATALENGTH(qt.TEXT)
ELSE qs.statement_end_offset
END - qs.statement_start_offset)/2)+1),
qs.execution_count,
qs.total_logical_reads, qs.last_logical_reads,
qs.total_logical_writes, qs.last_logical_writes,
qs.total_worker_time,
qs.last_worker_time,
qs.total_elapsed_time/1000000 total_elapsed_time_in_S,
qs.last_elapsed_time/1000000 last_elapsed_time_in_S,
qs.last_execution_time
--qp.query_plan
FROM sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) qt
CROSS APPLY sys.dm_exec_query_plan(qs.plan_handle) qp
ORDER BY qs.total_logical_reads DESC -- logical reads
--ORDER BY qs.total_logical_writes DESC -- logical writes
--ORDER BY qs.total_worker_time DESC -- CPU time