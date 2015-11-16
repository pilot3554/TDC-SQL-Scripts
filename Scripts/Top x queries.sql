-- Import all the trace files/events into the mytable table
SELECT * INTO mytable
FROM ::fn_trace_gettable('c:\mytracefiles\mytrace.trc', default)

-- Find out the top 100 queries that had the biggest duration
select top 100 textdata as TSQL_Statement,
(duration/1000000) as Duration_in_Seconds, reads as IO_Reads, writes as IO_Writes, cpu as IO_CPU,
loginname as Login_Name, ApplicationName as Application_Name, starttime as Start_Time, endtime as End_Time
from mytable
order by duration desc

-- Find out the top 100 queries by IO (Reads)
-- Each Read is 8 KB and these are logical Reads, not physical
select top 100 textdata as TSQL_Statement,
(duration/1000000) as Duration_in_Seconds, reads as IO_Reads, writes as IO_Writes, cpu as IO_CPU,
loginname as Login_Name, ApplicationName as Application_Name, starttime as Start_Time, endtime as End_Time
from mytable
order by reads desc

-- Find out the top 100 queries by CPU (CPU Cycles)
select top 100 textdata as TSQL_Statement,
(duration/1000000) as Duration_in_Seconds, reads as IO_Reads, writes as IO_Writes, cpu as IO_CPU,
loginname as Login_Name, ApplicationName as Application_Name, starttime as Start_Time, endtime as End_Time
from mytable
order by CPU desc