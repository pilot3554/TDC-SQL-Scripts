-- Create a Queue
declare @rc int
declare @TraceID int
declare @maxfilesize bigint
declare @DateTime datetime
declare @filename nvarchar(256)
declare @minutestorun int

set @minutestorun = 60*7
set @DateTime = dateadd(mi,@minutestorun,GETDATE())
set @maxfilesize = 20
set @filename = 'B:\Traces\'+replace(replace(@@servername,'-',''),'\','_')+'_Over_10_sec_Trace_'+CONVERT(varchar,@DateTime,112)+'_'+replace(CONVERT(varchar,@DateTime,108),':','')
select @filename+'.trc'

exec @rc = sp_trace_create @TraceID output, 0, @filename, @maxfilesize, @Datetime
if (@rc != 0) goto error


-- Client side File and Table cannot be scripted

-- Set the events
declare @on bit
set @on = 1
exec sp_trace_setevent @TraceID, 10, 15, @on
exec sp_trace_setevent @TraceID, 10, 8, @on
exec sp_trace_setevent @TraceID, 10, 16, @on
exec sp_trace_setevent @TraceID, 10, 17, @on
exec sp_trace_setevent @TraceID, 10, 2, @on
exec sp_trace_setevent @TraceID, 10, 18, @on
exec sp_trace_setevent @TraceID, 10, 34, @on
exec sp_trace_setevent @TraceID, 10, 11, @on
exec sp_trace_setevent @TraceID, 10, 35, @on
exec sp_trace_setevent @TraceID, 10, 12, @on
exec sp_trace_setevent @TraceID, 10, 13, @on
exec sp_trace_setevent @TraceID, 10, 14, @on
exec sp_trace_setevent @TraceID, 12, 15, @on
exec sp_trace_setevent @TraceID, 12, 8, @on
exec sp_trace_setevent @TraceID, 12, 16, @on
exec sp_trace_setevent @TraceID, 12, 1, @on
exec sp_trace_setevent @TraceID, 12, 17, @on
exec sp_trace_setevent @TraceID, 12, 14, @on
exec sp_trace_setevent @TraceID, 12, 18, @on
exec sp_trace_setevent @TraceID, 12, 11, @on
exec sp_trace_setevent @TraceID, 12, 35, @on
exec sp_trace_setevent @TraceID, 12, 12, @on
exec sp_trace_setevent @TraceID, 12, 13, @on


-- Set the Filters
declare @intfilter int
declare @bigintfilter bigint

--1,000,000 = 1 sec
set @bigintfilter = 10000000 -- 10 sec
exec sp_trace_setfilter @TraceID, 13, 0, 4, @bigintfilter

-- Set the trace status to start
exec sp_trace_setstatus @TraceID, 1

-- display trace id for future references
select TraceID=@TraceID
goto finish

error: 
select ErrorCode=@rc

finish: 
go



/*
select *
FROM fn_trace_gettable('B:\Traces\Over_10_sec_Trace_20150127_162300.trc', default);

--trace info
SELECT * FROM sys.fn_trace_getinfo(0) ;
SELECT * FROM ::fn_trace_getinfo(NULL)

--stop trace
EXEC sp_trace_setstatus @traceid = 5 , @status = 0
--close trace
EXEC sp_trace_setstatus @traceid = 5 , @status = 2

*/
