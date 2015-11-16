/*
all trace files are C:\SQL_traces
run copy_from_prod.cmd to copy the files from all PROD servers
*/

use trace_collector
go
set nocount on;

DECLARE @name VARCHAR(500) 
DECLARE @sql NVARCHAR(max)
DECLARE @command VARCHAR(1000) 

truncate table _tmp
truncate table _tmp_traces
truncate table _tmp_traces_cleaned
truncate table _tmp_traces_textdata_distinct

declare @Directory sysname = 'd:\SQL_traces\'
DECLARE @DirectoryArchived sysname = 'd:\SQL_traces\archived\'


IF OBJECT_ID('tempdb..#DirTree') IS NOT NULL
DROP TABLE #DirTree

IF OBJECT_ID('tempdb..#DirTreeFiles') IS NOT NULL
DROP TABLE #DirTreeFiles

CREATE TABLE #DirTree (
    MyFile nvarchar(255),
    Depth smallint,
    FileFlag bit
   )
   
INSERT INTO #DirTree (MyFile, Depth, FileFlag)
EXEC master..xp_dirtree @Directory, 10, 1

select myfile INTO #DirTreeFiles FROM #DirTree WHERE Depth=1 AND FileFlag=1 and MyFile like '%.trc' and MyFile like '%over_10_sec%'
--SELECT * FROM #DirTreeFiles

-----------get the files----------------
DECLARE db_cursor CURSOR FOR  
select myfile From #DirTreeFiles

OPEN db_cursor  
FETCH NEXT FROM db_cursor INTO @name  

WHILE @@FETCH_STATUS = 0  
BEGIN  
       --print @name
       INSERT INTO trace_files (tracefilename) VALUES (@name)
       set @sql = 'insert into _tmp (TextData,BinaryData,DatabaseID,TransactionID,LineNumber,NTUserName,NTDomainName,HostName,ClientProcessID,ApplicationName,LoginName,SPID,Duration,StartTime,EndTime,Reads,Writes,CPU,Permissions,Severity,EventSubClass,ObjectID,Success,IndexID,IntegerData,ServerName,EventClass,ObjectType,NestLevel,State,Error,Mode,Handle,ObjectName,DatabaseName,FileName,OwnerName,RoleName,TargetUserName,DBUserName,LoginSid,TargetLoginName,TargetLoginSid,ColumnPermissions,LinkedServerName,ProviderName,MethodName,RowCounts,RequestID,XactSequence,EventSequence,BigintData1,BigintData2,GUID,IntegerData2,ObjectID2,Type,OwnerID,ParentName,IsSystem,Offset,SourceDatabaseID,SqlHandle,SessionLoginName,PlanHandle,GroupID,tracefilename)
       select TextData,BinaryData,DatabaseID,TransactionID,LineNumber,NTUserName,NTDomainName,HostName,ClientProcessID,ApplicationName,LoginName,SPID,Duration,StartTime,EndTime,Reads,Writes,CPU,Permissions,Severity,EventSubClass,ObjectID,Success,IndexID,IntegerData,ServerName,EventClass,ObjectType,NestLevel,State,Error,Mode,Handle,ObjectName,DatabaseName,FileName,OwnerName,RoleName,TargetUserName,DBUserName,LoginSid,TargetLoginName,TargetLoginSid,ColumnPermissions,LinkedServerName,ProviderName,MethodName,RowCounts,RequestID,XactSequence,EventSequence,BigintData1,BigintData2,GUID,IntegerData2,ObjectID2,Type,OwnerID,ParentName,IsSystem,Offset,SourceDatabaseID,SqlHandle,SessionLoginName,PlanHandle,GroupID, '''+@name+'''
       FROM fn_trace_gettable('''+@Directory+''+@name+''', default);'
       --print @sql
       exec sp_executesql @sql	
       
       FETCH NEXT FROM db_cursor INTO @name  
END  

CLOSE db_cursor  
DEALLOCATE db_cursor

delete from _tmp where textdata is null
--select * From _tmp

insert into _tmp_traces (TextData,HostName,LoginName,SPID,Duration,StartTime,EndTime,Reads,Writes,CPU,ServerName,ObjectName,DatabaseName,tracefilename)
select TextData,HostName,LoginName,SPID,Duration,StartTime,EndTime,Reads,Writes,CPU,ServerName,ObjectName,DatabaseName,tracefilename 
from _tmp

insert into _tmp_traces_cleaned (textdata,HostName,LoginName,SPID,Duration,StartTime,EndTime,Reads,Writes,CPU,ServerName,ObjectName,DatabaseName,tracefilename)
select convert(varchar(4000),textdata),HostName,LoginName,SPID,Duration,StartTime,EndTime,Reads,Writes,CPU,ServerName,ObjectName,DatabaseName,tracefilename 
from _tmp_traces

insert into _tmp_traces_textdata_distinct (textdata,tracefilename)
select distinct(textdata), tracefilename From dbo._tmp_traces_cleaned

update _tmp_traces_cleaned
set Duration = CAST(Duration/1000000. AS decimal(16, 2))


-----------clean up----------------
DECLARE db_cursor CURSOR FOR  
SELECT textdata
FROM excempts
where removefromprocess = 1


OPEN db_cursor  
FETCH NEXT FROM db_cursor INTO @name  

WHILE @@FETCH_STATUS = 0  
BEGIN  
       --print @name
       delete from _tmp_traces_textdata_distinct where textdata like '%'+@name+'%'
       delete from _tmp_traces_cleaned where textdata like '%'+@name+'%'

       FETCH NEXT FROM db_cursor INTO @name  
END  

CLOSE db_cursor  
DEALLOCATE db_cursor


/*
select * 
from excempts

select *
from _tmp_traces_textdata_distinct

select * 
from _tmp_traces_cleaned

select CAST(Duration/1000000. AS decimal(16, 2)) AS [Duration (in Seconds)], *
from _tmp_traces_cleaned
order by duration desc

select COUNT(*), servername 
from _tmp_traces_cleaned
group by servername

select COUNT(*), servername , objectname
from _tmp_traces_cleaned
group by servername, objectname

select COUNT(*), servername , textdata
from _tmp_traces_cleaned
group by servername, textdata
order by COUNT(*) desc

select 
max(duration) max_duration, min(duration) min_duration,avg(duration) as avg_duration,
max(reads) as max_read, avg(reads) as avg_reads, 
max(cpu) as max_cpu, avg(cpu) as avg_cpu,
COUNT(*) as exec_count, servername , textdata
from _tmp_traces_cleaned
group by servername, textdata
--order by COUNT(*) desc
order by max(duration) desc


*/

set nocount off;
INSERT INTO dbo.trace_commands (textdata,HostName,LoginName,SPID,Duration,StartTime,EndTime,Reads,Writes,CPU,ServerName,ObjectName,DatabaseName,commandid,tracefilename)
SELECT textdata,HostName,LoginName,SPID,Duration,StartTime,EndTime,Reads,Writes,CPU,ServerName,ObjectName,DatabaseName,commandid,tracefilename FROM dbo.[_tmp_traces_cleaned]


INSERT INTO dbo.trace_commands_aggrigates (max_duration,min_duration,avg_duration,max_read,avg_reads,max_writes,avg_writes,max_cpu,avg_cpu,exec_count,servername,DatabaseName,textdata)
select 
max(duration) max_duration, min(duration) min_duration,avg(duration) as avg_duration,
max(reads) as max_read, avg(reads) as avg_reads, 
max(writes) as max_writes, avg(writes) as avg_writes, 
max(cpu) as max_cpu, avg(cpu) as avg_cpu,
COUNT(*) as exec_count, servername ,DatabaseName, textdata
from _tmp_traces_cleaned
group by servername,DatabaseName, textdata
--order by COUNT(*) desc
order by max(duration) desc


-----------move the files----------------
DECLARE db_cursor CURSOR FOR  
select myfile From #DirTreeFiles

OPEN db_cursor  
FETCH NEXT FROM db_cursor INTO @name  

WHILE @@FETCH_STATUS = 0  
BEGIN  
       --print @name
       UPDATE dbo.trace_files SET archivedate = GETDATE() WHERE tracefilename = @name
       SET @command='MOVE /Y '+@Directory+@name+' ' +@DirectoryArchived
       --print @command
       exec sys.xp_cmdshell  @command	,no_output
       
       FETCH NEXT FROM db_cursor INTO @name  
END  

CLOSE db_cursor  
DEALLOCATE db_cursor



/*
SELECT * FROM trace_files
SELECT * FROM trace_commands
SELECT * FROM trace_commands_aggrigates
*/