USE [master]
GO

/****** Object:  StoredProcedure [dbo].[sp_alert_diskspace]    Script Date: 04/23/2015 11:14:09 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


/*
exec sp_alert_diskspace
exec sp_alert_diskspace 99
exec sp_alert_diskspace 25
*/
CREATE proc [dbo].[sp_alert_diskspace]
(
	@freelimit int = 50
)
as
begin


DECLARE @hr int
DECLARE @fso int
DECLARE @drive char(1)
DECLARE @odrive int
DECLARE @TotalSize varchar(20)
DECLARE @MB bigint ; 

SET @MB = 1048576

CREATE TABLE #drives (drive char(1) PRIMARY KEY,
FreeSpace int NULL,
TotalSize int NULL)
INSERT #drives(drive,FreeSpace)
EXEC master.dbo.xp_fixeddrives
EXEC @hr=sp_OACreate 'Scripting.FileSystemObject',@fso OUT
IF @hr <> 0 EXEC sp_OAGetErrorInfo @fso
DECLARE dcur CURSOR LOCAL FAST_FORWARD
FOR SELECT drive from #drives
ORDER by drive
OPEN dcur
FETCH NEXT FROM dcur INTO @drive
WHILE @@FETCH_STATUS=0
BEGIN
EXEC @hr = sp_OAMethod @fso,'GetDrive', @odrive OUT, @drive
IF @hr <> 0 EXEC sp_OAGetErrorInfo @fso
EXEC @hr = sp_OAGetProperty @odrive,'TotalSize', @TotalSize OUT
IF @hr <> 0 EXEC sp_OAGetErrorInfo @odrive

UPDATE #drives
SET TotalSize=@TotalSize/@MB
WHERE drive=@drive
FETCH NEXT FROM dcur INTO @drive
END

CLOSE dcur
DEALLOCATE dcur

EXEC @hr=sp_OADestroy @fso
IF @hr <> 0 EXEC sp_OAGetErrorInfo @fso

SELECT @@servername as ServerName, drive,
FreeSpace as 'Free(MB)',
TotalSize as 'Total(MB)',
CAST((FreeSpace/(TotalSize*1.0))*100.0 as int) as 'Free(%)',
GETDATE() as Date_Entered
into #result_set
FROM #drives

declare @servername nvarchar(100), @drive1 nvarchar(2), @freeMB int, @totalMB int, @free int, @date_entered nvarchar(50)
		
declare db_crsr_T cursor for
	SELECT [ServerName], [drive], [Free(MB)], [Total(MB)], [Free(%)], [Date_Entered] from #result_set

open db_crsr_T
fetch next from db_crsr_T into @servername, @drive1, @FreeMB, @totalMB, @free, @date_entered
while @@fetch_status = 0
begin	
	
	if @free < @freelimit and @free > 10 and CONVERT(CHAR(1),@drive1) != 'C'
		begin
		declare @msg1 nvarchar(500), @sbj1 nvarchar(100), @recpt1 nvarchar(500)
		set @recpt1 = 'patrickalexander@hotmail.com;kcinty@acheckamerica.com;'
		--set @recpt1 = 'patrickalexander@hotmail.com;'
		set @sbj1 = 'Disk space alert '+CONVERT(CHAR(1),@drive1)+': on '+RTRIM(@servername)
		SET @msg1 = 'Instance ' + RTRIM(@servername) + ' only has ' + CONVERT(NVARCHAR(9),@freeMB) + ' MB free on disk </br>' + CONVERT(CHAR(1),@drive1) + ':\ The percentage free is ' + CONVERT(NVARCHAR(3),@free) + '. </br>Drive ' + CONVERT(CHAR(1),@drive1) +':\ has a total size of ' + LTRIM(CONVERT(NVARCHAR(10),@totalMB)) + ' MB and ' + CONVERT(NVARCHAR(9),@freeMB) + ' MB free.'
		EXEC msdb.dbo.sp_send_dbmail
		    @recipients = @recpt1, 
			@body = @msg1,
			@subject = @sbj1,
			@body_format = 'HTML';
    
   
		end
	if @free < 10
		begin
		declare @msg2 nvarchar(500), @sbj2 nvarchar(100), @recpt2 nvarchar(500)
		set @recpt2 = 'patrickalexander@hotmail.com;kcinty@acheckamerica.com;'
		--set @recpt2 = 'patrickalexander@hotmail.com;'
		set @sbj2 = 'Disk space alert '+CONVERT(CHAR(1),@drive1)+': on '+RTRIM(@servername)
		SET @msg2 = 'WARNING!! </br>Instance ' + RTRIM(@servername) + ' only has ' + CONVERT(NVARCHAR(9),@freeMB) + ' MB free on disk </br>' + CONVERT(CHAR(1),@drive1) + ':\ The percentage free is ' + CONVERT(NVARCHAR(3),@free) + '.</br> Drive ' + CONVERT(CHAR(1),@drive1) +':\ has a total size of ' + LTRIM(CONVERT(NVARCHAR(10),@totalMB)) + ' MB and ' + CONVERT(NVARCHAR(9),@freeMB) + ' MB free.'
		EXEC msdb.dbo.sp_send_dbmail
		    @recipients = @recpt2, 
			@body = @msg2,
			@subject = @sbj2,
			@body_format = 'HTML';
		end		

	fetch next from db_crsr_T into @servername, @drive1, @FreeMB, @totalMB, @free, @date_entered
end

close db_crsr_T
deallocate db_crsr_T


DROP TABLE #drives
DROP TABLE #result_set

end


GO

/****** Object:  StoredProcedure [dbo].[sp_BlitzUpdate]    Script Date: 04/23/2015 11:14:10 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO




CREATE PROCEDURE [dbo].[sp_BlitzUpdate]
AS 
    SET NOCOUNT ON
    CREATE TABLE #Scripts ( ScriptDDL VARCHAR(MAX) ) ;
    DECLARE @ScriptDDL VARCHAR(MAX) ,
        @ScriptOpenRowset VARCHAR(MAX) ;


    IF EXISTS ( SELECT  *
                FROM    sys.configurations
                WHERE   name = 'Ad Hoc Distributed Queries'
                        AND value_in_use = 0 ) 
        BEGIN
            PRINT 'sp_BlitzUpdate requires Ad Hoc Distributed Queries to be turned on.'
            PRINT 'For more information, see http://www.BrentOzar.com/blitz/update'
            PRINT 'If you feel adventurous, you can turn it on by running these commands: '
            PRINT 'EXECUTE SP_CONFIGURE ''show advanced options'', 1;'
            PRINT 'RECONFIGURE WITH OVERRIDE;'
            PRINT 'GO'
            PRINT 'EXECUTE SP_CONFIGURE ''Ad Hoc Distributed Queries'', ''1'';'
            PRINT 'RECONFIGURE WITH OVERRIDE;'
            PRINT 'GO'
            PRINT 'Then, after you have run sp_BlitzUpdate, you can disable it again with:'
            PRINT 'EXECUTE SP_CONFIGURE ''Ad Hoc Distributed Queries'', ''0'';'
            PRINT 'RECONFIGURE WITH OVERRIDE;'
            PRINT 'GO'
            PRINT 'Also, keep in mind that RECONFIGURE will dump the plan cache, so you may'
            PRINT 'want to make these changes during a scheduled maintenance window.'
        END
    ELSE 
        BEGIN

            SET @ScriptOpenRowset = 'INSERT INTO #Scripts SELECT a.ScriptDDL FROM OPENROWSET(''SQLNCLI'', ''Server=publicsql.brentozar.com;UID=ReadOnly;PWD=PainRelief;'',
     ''SELECT TOP 1 ScriptDDL FROM dbo.Scripts WHERE ScriptName = ''''sp_Blitz'''' ORDER BY ScriptID DESC'') AS a;' ;
            EXEC(@ScriptOpenRowset) ;
            SELECT  @ScriptDDL = ScriptDDL
            FROM    #Scripts ;

/* Drop the existing Blitz script if it already exists */
            IF OBJECT_ID('master.dbo.sp_Blitz') IS NOT NULL 
                DROP PROC dbo.sp_Blitz ;

            EXEC(@ScriptDDL) ;

        END

    SET NOCOUNT OFF


GO

/****** Object:  StoredProcedure [dbo].[sp_block]    Script Date: 04/23/2015 11:14:10 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO




	
create proc [dbo].[sp_block] (@spid bigint=NULL)
as
select 
    t1.resource_type,
    'database'=db_name(resource_database_id),
    'blk object' = t1.resource_associated_entity_id,
    t1.request_mode,
    t1.request_session_id,
    t2.blocking_session_id    
from 
    sys.dm_tran_locks as t1, 
    sys.dm_os_waiting_tasks as t2
where 
    t1.lock_owner_address = t2.resource_address and
    t1.request_session_id = isnull(@spid,t1.request_session_id)



GO

/****** Object:  StoredProcedure [dbo].[sp_block_alert]    Script Date: 04/23/2015 11:14:10 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/*
exec sp_block_alert
*/
CREATE procedure [dbo].[sp_block_alert]
as
begin


declare @alerttreshhold int = 1
if(OBJECT_ID('tempdb..#Processes')>1)
	drop table #Processes
	

SELECT sc.session_id AS UserSPID, 
sr.blocking_session_id AS BlockingSPID, 
DB_NAME(st.dbid) AS DatabaseName,
ss.program_name AS AccessingProgram, 
ss.login_name AS LoginName, 
OBJECT_NAME(st.objectid, st.dbid) AS ObjectName, 
CAST(st.text AS VARCHAR(MAX)) AS RequestSQL
INTO #Processes 
FROM sys.dm_exec_sessions ss
JOIN sys.dm_exec_connections sc ON ss.session_ID = sc.session_ID
LEFT JOIN sys.dm_exec_requests sr ON sc.connection_ID = sr.connection_ID
CROSS APPLY sys.dm_exec_sql_text (sc.most_recent_sql_handle) AS st
WHERE sc.session_id > 50 --gets us user processes
and isnull(sr.blocking_session_id,0) >0

--sample record to test
--insert INTO #Processes select 1,1,'123','123','123','123','123'

if (select COUNT(*) from #Processes) >= @alerttreshhold
begin


		DECLARE @tableHTML  NVARCHAR(MAX) , @subjectstring nvarchar(200);

		SET @tableHTML =
			N'<H1>SQL Blocking on '+@@SERVERNAME+' </H1>' +
			N'<table border="1">' +
			N'<tr><th>UserSPID</th><th>BlockingSPID</th><th>DatabaseName</th>' +
			N'<th>AccessingProgram</th><th>LoginName</th><th>ObjectName</th>' +
			N'<th>RequestSQL</th></tr>' +
			CAST ( ( SELECT td = UserSPID,       '',
							td = BlockingSPID,       '',
							td = DatabaseName, '',
							td = AccessingProgram, '',
							td = LoginName, '',
							td = ObjectName, '',
							td = RequestSQL
					  FROM #Processes
					  FOR XML PATH('tr'), TYPE 
			) AS NVARCHAR(MAX) ) +
			N'</table>' ;
			
			print @tableHTML

		set @subjectstring = 'SQL Blocking on SQL Server '+@@SERVERNAME 
		EXEC msdb.dbo.sp_send_dbmail
			--@profile_name = 'default',
			@recipients ='patrickalexander@hotmail.com;qkong@acheckamerica.com;kcinty@acheckamerica.com', 
			@body = @tableHTML,
			@body_format = 'HTML' ,
			@subject = @subjectstring;		    
	
end

end



GO

/****** Object:  StoredProcedure [dbo].[sp_block_alert2]    Script Date: 04/23/2015 11:14:10 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO




/*
exec sp_block_alert2
*/
Create procedure [dbo].[sp_block_alert2]
as
begin

declare @alerttreshhold int = 1
if(OBJECT_ID('tempdb..#Processes')>1)
	drop table #Processes

	
SELECT
db.name DBName,
tl.request_session_id,
wt.blocking_session_id,
OBJECT_NAME(p.OBJECT_ID) BlockedObjectName,
tl.resource_type,
h1.TEXT AS RequestingText,
h2.TEXT AS BlockingText,
tl.request_mode
INTO #Processes 
FROM sys.dm_tran_locks AS tl
INNER JOIN sys.databases db ON db.database_id = tl.resource_database_id
INNER JOIN sys.dm_os_waiting_tasks AS wt ON tl.lock_owner_address = wt.resource_address
INNER JOIN sys.partitions AS p ON p.hobt_id = tl.resource_associated_entity_id
INNER JOIN sys.dm_exec_connections ec1 ON ec1.session_id = tl.request_session_id
INNER JOIN sys.dm_exec_connections ec2 ON ec2.session_id = wt.blocking_session_id
CROSS APPLY sys.dm_exec_sql_text(ec1.most_recent_sql_handle) AS h1
CROSS APPLY sys.dm_exec_sql_text(ec2.most_recent_sql_handle) AS h2

select * from #Processes 

if (select COUNT(*) from #Processes) >= @alerttreshhold
begin


		DECLARE @tableHTML  NVARCHAR(MAX) , @subjectstring nvarchar(200);

		SET @tableHTML =
			N'<H1>SQL Blocking on '+@@SERVERNAME+' </H1>' +
			N'<table border="1">' +
			N'<tr><th>DB</th><th>Request SPID</th><th>Blocking SPID</th>' +
			N'<th>Blocked Object</th><th>Resource Type</th><th>REquesting Text</th>' +
			N'<th>Blocking Text</th><th>Request Mode</th><</tr>' +
			CAST ( ( SELECT td = DBName,       '',
							td = request_session_id,       '',
							td = blocking_session_id, '',
							td = BlockedObjectName, '',
							td = resource_type, '',
							td = RequestingText, '',
							td = BlockingText, '',
							td = request_mode
					  FROM #Processes
					  FOR XML PATH('tr'), TYPE 
			) AS NVARCHAR(MAX) ) +
			N'</table>' ;
			
			print @tableHTML

		set @subjectstring = 'SQL Blocking on SQL Server '+@@SERVERNAME 
		EXEC msdb.dbo.sp_send_dbmail
			--@profile_name = 'default',
			@recipients ='patrickalexander@hotmail.com;qkong@acheckamerica.com;kcinty@acheckamerica.com', 
			@body = @tableHTML,
			@body_format = 'HTML' ,
			@subject = @subjectstring;	
end

end

GO

/****** Object:  StoredProcedure [dbo].[sp_block2]    Script Date: 04/23/2015 11:14:10 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO





Create Procedure [dbo].[sp_block2]
as
begin

	SELECT sc.session_id AS UserSPID, 
	sr.blocking_session_id AS BlockingSPID, 
	DB_NAME(st.dbid) AS DatabaseNm,
	ss.program_name AS AccessingProgram, 
	ss.login_name AS LoginNm, 
	OBJECT_NAME(st.objectid, st.dbid) AS ObjectNm, 
	CAST(st.text AS VARCHAR(MAX)) AS RequestSQL
	--INTO #Processes 
	FROM sys.dm_exec_sessions ss
	JOIN sys.dm_exec_connections sc ON ss.session_ID = sc.session_ID
	LEFT JOIN sys.dm_exec_requests sr ON sc.connection_ID = sr.connection_ID
	CROSS APPLY sys.dm_exec_sql_text (sc.most_recent_sql_handle) AS st
	WHERE sc.session_id > 50 --gets us user processes
	and isnull(sr.blocking_session_id,0) >0

end



GO

/****** Object:  StoredProcedure [dbo].[sp_blocker_pss80]    Script Date: 04/23/2015 11:14:10 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO




create procedure [dbo].[sp_blocker_pss80] (@latch int = 0, @fast int = 1)
as 
--version 14SP3
set nocount on
declare @spid varchar(6)
declare @blocked varchar(6)
declare @time datetime
declare @time2 datetime

set @time = getdate()
declare @probclients table(spid smallint, ecid smallint, blocked smallint, waittype binary(2), dbid smallint, ignore_app tinyint, primary key (blocked, spid, ecid))
insert @probclients select spid, ecid, blocked, waittype, dbid, case when convert(varchar(128),hostname) = 'PSSDIAG' then 1 else 0 end from sysprocesses where blocked!=0 or waittype != 0x0000

if exists (select spid from @probclients where ignore_app != 1 or waittype != 0x020B)
begin
   set @time2 = getdate()
   print ''
   print '8.2 Start time: ' + convert(varchar(26), @time, 121) + ' ' + convert(varchar(12), datediff(ms,@time,@time2))

   insert @probclients select distinct blocked, 0, 0, 0x0000, 0, 0 from @probclients
      where blocked not in (select spid from @probclients) and blocked != 0

   if (@fast = 1)
   begin
      print ''
      print 'SYSPROCESSES ' + ISNULL (@@servername,'(null)') + ' ' + str(@@microsoftversion)

      select spid, status, blocked, open_tran, waitresource, waittype, 
         waittime, cmd, lastwaittype, cpu, physical_io,
         memusage, last_batch=convert(varchar(26), last_batch,121),
         login_time=convert(varchar(26), login_time,121),net_address,
         net_library, dbid, ecid, kpid, hostname, hostprocess,
         loginame, program_name, nt_domain, nt_username, uid, sid,
         sql_handle, stmt_start, stmt_end
      from master..sysprocesses
      where blocked!=0 or waittype != 0x0000
         or spid in (select blocked from @probclients where blocked != 0)
         or spid in (select spid from @probclients where blocked != 0)

      print 'ESP ' + convert(varchar(12), datediff(ms,@time2,getdate())) 

      print ''
      print 'SYSPROC FIRST PASS'
      select spid, ecid, waittype from @probclients where waittype != 0x0000

      if exists(select blocked from @probclients where blocked != 0)
      begin
         print 'Blocking via locks at ' + convert(varchar(26), @time, 121)
         print ''
         print 'SPIDs at the head of blocking chains'
         select spid from @probclients
            where blocked = 0 and spid in (select blocked from @probclients where spid != 0)
         if @latch = 0
         begin
            print 'SYSLOCKINFO'
            select @time2 = getdate()

            select spid = convert (smallint, req_spid),
               ecid = convert (smallint, req_ecid),
               rsc_dbid As dbid,
               rsc_objid As ObjId,
               rsc_indid As IndId,
               Type = case rsc_type when 1 then 'NUL'
                                    when 2 then 'DB'
                                    when 3 then 'FIL'
                                    when 4 then 'IDX'
                                    when 5 then 'TAB'
                                    when 6 then 'PAG'
                                    when 7 then 'KEY'
                                    when 8 then 'EXT'
                                    when 9 then 'RID'
                                    when 10 then 'APP' end,
               Resource = substring (rsc_text, 1, 16),
               Mode = case req_mode + 1 when 1 then NULL
                                        when 2 then 'Sch-S'
                                        when 3 then 'Sch-M'
                                        when 4 then 'S'
                                        when 5 then 'U'
                                        when 6 then 'X'
                                        when 7 then 'IS'
                                        when 8 then 'IU'
                                        when 9 then 'IX'
                                        when 10 then 'SIU'
                                        when 11 then 'SIX'
                                        when 12 then 'UIX'
                                        when 13 then 'BU'
                                        when 14 then 'RangeS-S'
                                        when 15 then 'RangeS-U'
                                        when 16 then 'RangeIn-Null'
                                        when 17 then 'RangeIn-S'
                                        when 18 then 'RangeIn-U'
                                        when 19 then 'RangeIn-X'
                                        when 20 then 'RangeX-S'
                                        when 21 then 'RangeX-U'
                                        when 22 then 'RangeX-X'end,
               Status = case req_status when 1 then 'GRANT'
                                        when 2 then 'CNVT'
                                        when 3 then 'WAIT' end,
               req_transactionID As TransID, req_transactionUOW As TransUOW
            from master.dbo.syslockinfo s,
               @probclients p
            where p.spid = s.req_spid

            print 'ESL ' + convert(varchar(12), datediff(ms,@time2,getdate())) 
         end -- latch not set
      end
      else
         print 'No blocking via locks at ' + convert(varchar(26), @time, 121)
      print ''
   end  -- fast set

   else  
   begin  -- Fast not set
      print ''
      print 'SYSPROCESSES ' + ISNULL (@@servername,'(null)') + ' ' + str(@@microsoftversion)

      select spid, status, blocked, open_tran, waitresource, waittype, 
         waittime, cmd, lastwaittype, cpu, physical_io,
         memusage, last_batch=convert(varchar(26), last_batch,121),
         login_time=convert(varchar(26), login_time,121),net_address,
         net_library, dbid, ecid, kpid, hostname, hostprocess,
         loginame, program_name, nt_domain, nt_username, uid, sid,
         sql_handle, stmt_start, stmt_end
      from master..sysprocesses

      print 'ESP ' + convert(varchar(12), datediff(ms,@time2,getdate())) 

      print ''
      print 'SYSPROC FIRST PASS'
      select spid, ecid, waittype from @probclients where waittype != 0x0000

      if exists(select blocked from @probclients where blocked != 0)
      begin
         print 'Blocking via locks at ' + convert(varchar(26), @time, 121)
         print ''
         print 'SPIDs at the head of blocking chains'
         select spid from @probclients
         where blocked = 0 and spid in (select blocked from @probclients where spid != 0)
         if @latch = 0
         begin
            print 'SYSLOCKINFO'
            select @time2 = getdate()

            select spid = convert (smallint, req_spid),
               ecid = convert (smallint, req_ecid),
               rsc_dbid As dbid,
               rsc_objid As ObjId,
               rsc_indid As IndId,
               Type = case rsc_type when 1 then 'NUL'
                                    when 2 then 'DB'
                                    when 3 then 'FIL'
                                    when 4 then 'IDX'
                                    when 5 then 'TAB'
                                    when 6 then 'PAG'
                                    when 7 then 'KEY'
                                    when 8 then 'EXT'
                                    when 9 then 'RID'
                                    when 10 then 'APP' end,
               Resource = substring (rsc_text, 1, 16),
               Mode = case req_mode + 1 when 1 then NULL
                                        when 2 then 'Sch-S'
                                        when 3 then 'Sch-M'
                                        when 4 then 'S'
                                        when 5 then 'U'
                                        when 6 then 'X'
                                        when 7 then 'IS'
                                        when 8 then 'IU'
                                        when 9 then 'IX'
                                        when 10 then 'SIU'
                                        when 11 then 'SIX'
                                        when 12 then 'UIX'
                                        when 13 then 'BU'
                                        when 14 then 'RangeS-S'
                                        when 15 then 'RangeS-U'
                                        when 16 then 'RangeIn-Null'
                                        when 17 then 'RangeIn-S'
                                        when 18 then 'RangeIn-U'
                                        when 19 then 'RangeIn-X'
                                        when 20 then 'RangeX-S'
                                        when 21 then 'RangeX-U'
                                        when 22 then 'RangeX-X'end,
               Status = case req_status when 1 then 'GRANT'
                                        when 2 then 'CNVT'
                                        when 3 then 'WAIT' end,
               req_transactionID As TransID, req_transactionUOW As TransUOW
            from master.dbo.syslockinfo

            print 'ESL ' + convert(varchar(12), datediff(ms,@time2,getdate())) 
         end -- latch not set
      end
      else
        print 'No blocking via locks at ' + convert(varchar(26), @time, 121)
      print ''
   end -- Fast not set

   print 'DBCC SQLPERF(WAITSTATS)'
   dbcc sqlperf(waitstats)

   Print ''
   Print '*********************************************************************'
   Print 'Print out DBCC Input buffer for all blocked or blocking spids.'
   Print '*********************************************************************'

   declare ibuffer cursor fast_forward for
   select cast (spid as varchar(6)) as spid, cast (blocked as varchar(6)) as blocked
   from @probclients
   where (spid <> @@spid) and 
      ((blocked!=0 or (waittype != 0x0000 and ignore_app = 0))
      or spid in (select blocked from @probclients where blocked != 0))
   open ibuffer
   fetch next from ibuffer into @spid, @blocked
   while (@@fetch_status != -1)
   begin
      print ''
      print 'DBCC INPUTBUFFER FOR SPID ' + @spid
      exec ('dbcc inputbuffer (' + @spid + ')')

      fetch next from ibuffer into @spid, @blocked
   end
   deallocate ibuffer

   Print ''
   Print '*******************************************************************************'
   Print 'Print out DBCC OPENTRAN for active databases for all blocked or blocking spids.'
   Print '*******************************************************************************'
   declare ibuffer cursor fast_forward for
   select distinct cast (dbid as varchar(6)) from @probclients
   where dbid != 0
   open ibuffer
   fetch next from ibuffer into @spid
   while (@@fetch_status != -1)
   begin
      print ''
      print 'DBCC OPENTRAN FOR DBID ' + @spid
      exec ('dbcc opentran (' + @spid + ')')
      print ''
      if @spid = '2' select @blocked = 'Y'
      fetch next from ibuffer into @spid
   end
   deallocate ibuffer
   if @blocked != 'Y' 
   begin
      print ''
      print 'DBCC OPENTRAN FOR tempdb database'
      exec ('dbcc opentran (tempdb)')
   end

   print 'End time: ' + convert(varchar(26), getdate(), 121)
end -- All
else
  print '8 No Waittypes: ' + convert(varchar(26), @time, 121) + ' ' + convert(varchar(12), datediff(ms,@time,getdate())) + ' ' + ISNULL (@@servername,'(null)')




GO

/****** Object:  StoredProcedure [dbo].[sp_db_restore_status_report]    Script Date: 04/23/2015 11:14:10 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO





create procedure [dbo].[sp_db_restore_status_report]
as
begin

/*
select * 
from master.sys.databases a  WITH (nolock) 
where a.name like 'ces_%'
order by a.name

SELECT top 1 * FROM MSDB..RESTOREHISTORY WITH (nolock) 
WHERE (DESTINATION_DATABASE_NAME = 'ces_aaanational') 
ORDER BY RESTORE_DATE DESC 
*/
if(OBJECT_ID('tempdb..#tmp')>1)
	drop table #tmp
	
Create table #tmp (db nvarchar(1000), restore_Date datetime)

insert into #tmp
select a.name ,
(
SELECT top 1 restore_date FROM MSDB..RESTOREHISTORY WITH (nolock) 
WHERE (DESTINATION_DATABASE_NAME = a.name) 
ORDER BY RESTORE_DATE DESC 
) as last_restore_date
from master.sys.databases a  WITH (nolock) 
--where a.name like 'ces_%'

--select * From #tmp

if(OBJECT_ID('tempdb..#tmp_total')>1)
	drop table #tmp_total
	
select 
(
select COUNT(*) 
From #tmp
) as total_dbs,
(
select COUNT(*) 
From #tmp
where isnull(restore_Date,'01/01/1900') > DATEADD(hh,-2,getdate())
) as restored_last_2_hours,
(
select COUNT(*)
From #tmp
where isnull(restore_Date,'01/01/1900') > DATEADD(hh,-8,getdate())
) as restored_last_8_hours,
(
select COUNT(*) 
From #tmp
where isnull(restore_Date,'01/01/1900') > DATEADD(hh,-24,getdate())
) as restored_last_24_hours,
(
select COUNT(*) 
From #tmp
where isnull(restore_Date,'01/01/1900') < DATEADD(hh,-24,getdate())
)  as restored_older_24_hours
into #tmp_total

--select * From #tmp_total

DECLARE @tableHTML  NVARCHAR(MAX) , @subjectstring nvarchar(200);

SET @tableHTML =
	N'<H1>Database Restore Report from '+@@SERVERNAME+' </H1>' +
	N'<table border="1">' +
	N'<tr><th>Total Databases</th><th>Restored in last 2 hours</th><th>Restored in last 8 hours</th>' +
	N'<th>Restored in last 24 hours</th>' +
	N'<th>Restored over 24 hours</th></tr>' +
	CAST ( ( SELECT td = total_dbs,       '',
					td = restored_last_2_hours,       '',
					td = restored_last_8_hours, '',
					td = restored_last_24_hours, '',
					td = restored_older_24_hours
			  FROM #tmp_total
			  FOR XML PATH('tr'), TYPE 
	) AS NVARCHAR(MAX) ) +
	N'</table>' ;
	
print @tableHTML
    
set @subjectstring = 'Database Restore Report from '+@@SERVERNAME 
EXEC msdb.dbo.sp_send_dbmail
	@profile_name = 'default',
	@recipients ='palexander@csod.com;ayegudkin@csod.com;jferris@csod.com', 
	@body = @tableHTML,
	@body_format = 'HTML' ,
	@subject = @subjectstring;
	
end	



GO

/****** Object:  StoredProcedure [dbo].[sp_dbspaceall]    Script Date: 04/23/2015 11:14:10 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO




/*
exec sp_dbspaceall
*/
create procedure [dbo].[sp_dbspaceall]
as
begin

with fs
as
(
    select database_id, type, size * 8.0 / 1024 size
    from sys.master_files
)
select 
    name,
    (select sum(size) from fs where type = 0 and fs.database_id = db.database_id) DataFileSizeMB,
    (select sum(size) from fs where type = 1 and fs.database_id = db.database_id) LogFileSizeMB
from sys.databases db


end



GO

/****** Object:  StoredProcedure [dbo].[sp_dbspaceused]    Script Date: 04/23/2015 11:14:10 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO




/*
sp_dbspaceused 'ces_barclsysplc'
*/
create procedure [dbo].[sp_dbspaceused]
(
@db nvarchar(255) = 'tempdb'
)
as
begin

declare @sqlstring nvarchar(max) --@db nvarchar(255) = 'tempdb' ,

if exists(select name from master.sys.databases where name = @db)
begin

set @sqlstring = '
use ['+@db+']


create table #Data(
FileID int NOT NULL,
[FileGroupId] int NOT NULL,
TotalExtents int NOT NULL,
UsedExtents int NOT NULL,
[FileName] sysname NOT NULL,
[FilePath] varchar(max) NOT NULL,
[FileGroup] varchar(MAX) NULL
)

create table #Results(
db sysname NULL ,
FileType varchar(4) NOT NULL,
[FileGroup] sysname not null,
[FileName] sysname NOT NULL,
TotalMB numeric(18,2) NOT NULL,
UsedMB numeric(18,2) NOT NULL,
PctUsed numeric(18,2) NULL,
FilePATH nvarchar(MAX) NULL,
FileID int null
)

create table #Log(
db sysname NOT NULL,
LogSize numeric(18,5) NOT NULL,
LogUsed numeric(18,5) NOT NULL,
Status int NOT NULL,
[FilePath] varchar(max) NULL
)

INSERT #Data (Fileid , [FileGroupId], TotalExtents ,
UsedExtents , [FileName] , [FilePath])
EXEC (''DBCC showfilestats'')

update #Data
set #data.Filegroup = sysfilegroups.groupname
from #data, sysfilegroups
where #data.FilegroupId = sysfilegroups.groupid

INSERT INTO #Results (db ,[FileGroup], FileType , [FileName], TotalMB ,
UsedMB , PctUsed , FilePATH, FileID)
SELECT DB_NAME() db,
[FileGroup],
''Data'' FileType,
[FileName],
TotalExtents * 64./1024. TotalMB,
UsedExtents *64./1024 UsedMB,
UsedExtents*100. /TotalExtents UsedPct,
[FilePath],
FileID
FROM #Data
order BY 1,2

insert #Log (db,LogSize,LogUsed,Status )
exec(''dbcc sqlperf(logspace)'')

insert #Results(db, [FileGroup], FileType, [FileName], TotalMB,UsedMB, PctUsed, FilePath, FileID)
select DB_NAME() db,
''Log'' [FileGroup],
''Log'' FileType,
s.[name] [FileName],
s.Size/128. as LogSize ,
FILEPROPERTY(s.name,''spaceused'')/8.00 /16.00 As LogUsedSpace,
(s.Size/128. - FILEPROPERTY(s.name,''spaceused'')/8.00 /16.00) UsedPct,
s.FileName FilePath,
s.FileId FileID
from #Log l , master.dbo.sysaltfiles f , dbo.sysfiles s
where f.dbid = DB_ID()
and (s.status & 0x40) <> 0
and s.fileid=f.fileid
and l.db = DB_NAME()

SELECT r.*,
CASE WHEN s.maxsize = -1 THEN null
else CONVERT(decimal(18,2), s.maxsize /128.)
END MaxSizeMB,
CONVERT(decimal(18,2), s.growth /128.) GrowthMB
FROM #Results r
INNER JOIN dbo.sysfiles s
ON r.FileID = s.FileID
ORDER BY 1,2,3,4,5

DROP TABLE #Data
DROP TABLE #Results
DROP TABLE #Log

'
print @sqlstring

execute sp_executesql @sqlstring

end
else
begin
	select 'Database [' + @db + '] not exisit on [' + @@SERVERNAME + '] server'
end	

end




GO

/****** Object:  StoredProcedure [dbo].[sp_delete_files]    Script Date: 04/23/2015 11:14:10 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO





/*
exec sp_delete_files @folder = 'B:\SQL_Performance\TraceCollection\TraceFiles\'
	,@ext  = 'trc'
	,@minutesgoback  = -60
*/

CREATE proc [dbo].[sp_delete_files]
(
	@folder varchar(100) 
	,@ext varchar(10) 
	,@minutesgoback int = -6000
)
as
begin

	set nocount on;
	declare @run int = 1 , @reccount int = 0
	declare @sql nvarchar(4000), @filename varchar(100), @tablename varchar(100), @param_definition nvarchar(4000), @folderlogs varchar(100) 

	--set @folderlogs = @folder +'\logs\'
	set @folderlogs = @folder 
	

	------------------------------------------------

	set @sql = 'DIR ' + '"' + @folderlogs + '\*.'+@ext+'"'
	--print @sql

	if(OBJECT_ID('tempdb..#tmp_tbl')>0)
		drop table #tmp_tbl
		
	CREATE TABLE #tmp_tbl (Name varchar(400), Work int IDENTITY(1,1))

	INSERT #tmp_tbl EXECUTE master.dbo.xp_cmdshell @sql

	DELETE #tmp_tbl WHERE ISDATE(SUBSTRING(Name,1,10)) = 0 OR SUBSTRING(Name,40,1) = '.' 
	--select convert(datetime,SUBSTRING(Name,1,20)),SUBSTRING(Name,40,100),dateadd(MINUTE,@minutesgoback,GETDATE()), * 
	--From #tmp_tbl 
	--where convert(datetime,SUBSTRING(Name,1,20)) < dateadd(MINUTE,@minutesgoback,GETDATE())

	---------------------------------------------------


	declare tmp_cur cursor for 
	SELECT SUBSTRING(Name,40,100) AS Files FROM #tmp_tbl where convert(datetime,SUBSTRING(Name,1,20)) < dateadd(MINUTE,@minutesgoback,GETDATE())

	open tmp_cur
	Fetch next from tmp_cur into @filename

	while @@fetch_status = 0
	begin
	print @filename
	set @tablename = REPLACE(@filename,'.'+@ext,'')
	print 'deleteing '+@tablename


	set @filename = ltrim(RTRIM(@filename))  

	set @sql = 'del '+ @folder+ @filename
	if @run = 0
		print @sql  
	if @run = 1
		EXECUTE master.dbo.xp_cmdshell @sql
	  
	  


	  
	Fetch next from tmp_cur into @filename
	print '---'
	end

	close tmp_cur
	deallocate tmp_cur

	------------------------------------------------------
  


end



GO

/****** Object:  StoredProcedure [dbo].[sp_disksize]    Script Date: 04/23/2015 11:14:10 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO





/*
exec sp_disksize @minfreespace = 40
exec sp_disksize @minfreespace = 40 , @diskdrive = 'T:\'
exec sp_disksize @diskdrive = 'T:\'
*/
CREATE procedure [dbo].[sp_disksize]
(
	@minfreespace smallint = 100
	,@diskdrive nvarchar(10) = null
)
as
begin


declare @svrName varchar(255)
declare @sql varchar(400)
--by default it will take the current server name, we can the set the server name as well
set @svrName = @@SERVERNAME
set @sql = 'powershell.exe -c "Get-WmiObject -ComputerName ' + QUOTENAME(@svrName,'''') + ' -Class Win32_Volume -Filter ''DriveType = 3'' | select name,capacity,freespace | foreach{$_.name+''|''+$_.capacity/1048576+''%''+$_.freespace/1048576+''*''}"'
--creating a temporary table
CREATE TABLE #output
(line varchar(255))
--inserting disk name, total space and free space value in to temporary table
insert #output
EXEC xp_cmdshell @sql
--script to retrieve the values in MB from PS Script output
select @@SERVERNAME as ServerNAme
	,rtrim(ltrim(SUBSTRING(line,1,CHARINDEX('|',line) -1))) as drivename
      ,round(cast(rtrim(ltrim(SUBSTRING(line,CHARINDEX('|',line)+1,
      (CHARINDEX('%',line) -1)-CHARINDEX('|',line)) )) as Float),0) as 'capacity(MB)'
      ,round(cast(rtrim(ltrim(SUBSTRING(line,CHARINDEX('%',line)+1,
      (CHARINDEX('*',line) -1)-CHARINDEX('%',line)) )) as Float),0) as 'freespace(MB)'
      ,round(cast(rtrim(ltrim(SUBSTRING(line,CHARINDEX('|',line)+1,
      (CHARINDEX('%',line) -1)-CHARINDEX('|',line)) )) as Float)/1024,0) as 'capacity(GB)'
      ,round(cast(rtrim(ltrim(SUBSTRING(line,CHARINDEX('%',line)+1,
      (CHARINDEX('*',line) -1)-CHARINDEX('%',line)) )) as Float) /1024 ,0)as 'freespace(GB)'
      ,(round(cast(rtrim(ltrim(SUBSTRING(line,CHARINDEX('%',line)+1,(CHARINDEX('*',line) -1)-CHARINDEX('%',line)) )) as Float) /1024 ,0)
      /round(cast(rtrim(ltrim(SUBSTRING(line,CHARINDEX('|',line)+1,(CHARINDEX('%',line) -1)-CHARINDEX('|',line)) )) as Float)/1024,0))*100
       as 'freespace%'
from #output
where line like '[A-Z][:]%'
and ((round(cast(rtrim(ltrim(SUBSTRING(line,CHARINDEX('%',line)+1,(CHARINDEX('*',line) -1)-CHARINDEX('%',line)) )) as Float) /1024 ,0) /round(cast(rtrim(ltrim(SUBSTRING(line,CHARINDEX('|',line)+1,(CHARINDEX('%',line) -1)-CHARINDEX('|',line)) )) as Float)/1024,0))*100) <= @minfreespace 
and(rtrim(ltrim(SUBSTRING(line,1,CHARINDEX('|',line) -1))) = @diskdrive or @diskdrive is null)
order by drivename

drop table #output

end



GO

/****** Object:  StoredProcedure [dbo].[sp_dw_status]    Script Date: 04/23/2015 11:14:10 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO





/*
exec sp_dw_status 'ABA',0
exec sp_dw_status 'ABA',347
*/
CREATE procedure [dbo].[sp_dw_status]
(
	@clientname nvarchar(100),
	@last_run_id int = 0
)
as
begin

--set @last_run_id = 123
--set @clientname = 'socgen'

declare @timdediff int , @starttime datetime, @endtime datetime
SELECT @timdediff = DATEDIFF(hour, GETUTCDATE(),GETDATE())

if(@last_run_id = 0)
begin
	select top 1 @last_run_id = client_run_id 
	from ces_master.dbo.ssis_log (nolock) 
	where client_name = @clientname 
	order by client_run_id desc
end


select
@endtime  = DATEADD(HH,@timdediff,MAX(time)),
@starttime = DATEADD(HH,@timdediff,MIN(time))
From ces_master.dbo.ssis_log
where client_name = @clientname and client_run_id = @last_run_id

declare @seconds int , @minutes int = 0 , @hours int = 0 , @days int = 0


set @seconds = DATEDIFF(SECOND,@starttime,@endtime)
select @minutes = @seconds / 60
select @hours = @minutes / 60
select @minutes =  @minutes -@hours*60
select @days = @hours /24 
select @hours = @hours  - @days*24
select @seconds = @seconds % 60

select @clientname as ClientName, @last_run_id as LastRunID ,@starttime as StartTime , @endtime as EndTime,CONVERT(nvarchar(2),@days)+' Day(s), '+CONVERT(nvarchar(2),@hours)+' Hour(s), '+CONVERT(nvarchar(2),@minutes)+' Minutes, '+CONVERT(nvarchar(2),@seconds)+' Seconds ' as Duration




select s.client_run_id, s.client_scenario_id, s.client_task_id, t.task_name, s.client_step_id, p.step_name,
s.client_status_step_id, q.status_text,
s.client_result_step_id, r.result_name,
DATEADD(HH,@timdediff,[time]) AS PacificTime, s.comment
from ces_master.dbo.ssis_log s (nolock) 
inner join ces_master.dbo.ssis_tasks t on s.client_task_id = t.task_id
inner join ces_master.dbo.ssis_step p on s.client_step_id = p.step_id
inner join ces_master.dbo.ssis_status_step q on s.client_status_step_id = q.status_id
inner join ces_master.dbo.ssis_result_type r on s.client_result_step_id = r.result_id
where client_name = @clientname and client_run_id = @last_run_id
order by PacificTime desc, client_task_id , client_step_id , client_status_step_id

select *
,DATEADD(HH,@timdediff,(select Min(Time) from ces_master.dbo.ssis_log s (nolock) where s.client_task_id = t.task_id and client_name = @clientname and client_run_id = @last_run_id)) as starttime
,DATEADD(HH,@timdediff,(select MAX(Time) from ces_master.dbo.ssis_log s (nolock) where s.client_task_id = t.task_id and client_name = @clientname and client_run_id = @last_run_id)) as endtime
,DATEDIFF(ss
,(select Min(Time) from ces_master.dbo.ssis_log s (nolock) where s.client_task_id = t.task_id and client_name = @clientname and client_run_id = @last_run_id)
,(select MAX(Time) from ces_master.dbo.ssis_log s (nolock) where s.client_task_id = t.task_id and client_name = @clientname and client_run_id = @last_run_id)
) as duration_seconds
from ces_master.dbo.ssis_tasks t
order by duration_seconds desc

END





GO

/****** Object:  StoredProcedure [dbo].[sp_EmailLongQueries]    Script Date: 04/23/2015 11:14:11 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO





/*
exec sp_EmailLongQueries @RunningLongerThanXmin = 1 , @emaildba = 'palexander@hotmail.com;gtian@csod.com'
EXEC msdb.dbo.sp_send_dbmail @recipients = 'palexander@csod.com', @subject='test', @body='test', @body_format = 'TEXT'
*/
CREATE PROC [dbo].[sp_EmailLongQueries]
(
	@RunningLongerThanXmin int = 5,
	@emaildba varchar(1000) = null
)
AS
BEGIN

SET NOCOUNT ON

DECLARE @subject varchar(256), @body varchar(8000), @killcmd INT
if @emaildba is null
begin
	SET @emaildba = 'palexander@csod.com'
end

select @emaildba
	
SET @killcmd = 0


DECLARE @servername varchar(256), @loginid varchar(256), @ntdomain varchar(100), @ntusername varchar(100),
	@hostname varchar(255), @hostproc varchar(10), @spid varchar(10), @execcont varchar(10), @waittype varchar(256),
	@waitresource varchar(255), @waittime varchar(10), @blockedby varchar(10), @starttime datetime, @runtimesecs varchar(10),
	@runtimemin varchar(10), @status varchar(20), @dbname varchar(255), @commandtype varchar(25), @sqllen int, @sqlcmd varchar(max)

DECLARE longquery CURSOR FOR
	select 
	@@SERVERNAME as ServerName,
	sproc.loginame LoginID,
	sproc.nt_domain AS NTDomain,
	sproc.nt_username AS NTUserName,
	sproc.Hostname AS HostName,
	sproc.hostprocess,
	sproc.spid AS Session_ID,
	sproc.ecid AS Execution_Context,
	sproc.lastwaittype AS Wait_Type, 
	sproc.waitresource AS Wait_Resource,
	sproc.waittime AS Wait_Time, 
	CASE WHEN sproc.blocked = 0 THEN 0 ELSE sproc.blocked END as BlockedBy,
	sproc.last_batch Started_At,
	datediff(second,sproc.last_batch,getdate()) AS Elapsed_Seconds,
	datediff(mi,sproc.last_batch,getdate()) AS Elapsed_Mins,
	sproc.status AS [Status], 
	DB_NAME(sproc.dbid) AS DBName,
	sproc.cmd AS Command,
	len(sqltext.TEXT) SQL_Length,
	SUBSTRING(sqltext.text, (sproc.stmt_start/2)+1, 
        ((CASE sproc.stmt_end
          WHEN -1 THEN DATALENGTH(sqltext.text)
         ELSE sproc.stmt_end
         END - sproc.stmt_start)/2) + 1) AS Query_SQL
	--,sproc.*
	from master.sys.sysprocesses sproc
	OUTER APPLY master.sys.dm_exec_sql_text(sproc.sql_handle) AS sqltext
	where sproc.spid <> @@SPID
	AND sproc.spid > 50
	AND sproc.cmd <> 'AWAITING COMMAND'
	AND sproc.hostname <> @@SERVERNAME  -- Do not monitor local processes
	AND sproc.nt_domain = '{domainname}'  -- Do not monitor sql logins, only user logins
	AND datediff(mi,sproc.last_batch,getdate()) > @RunningLongerThanXmin  -- Running longer than x mins
	ORDER BY sproc.spid, sproc.ecid


OPEN longquery
FETCH NEXT FROM longquery INTO @servername, @loginid, @ntdomain, @ntusername,
		@hostname, @hostproc, @spid, @execcont, @waittype,
		@waitresource, @waittime, @blockedby, @starttime, @runtimesecs,
		@runtimemin, @status, @dbname, @commandtype, @sqllen, @sqlcmd

WHILE @@FETCH_STATUS = 0
BEGIN
	SET @killcmd = 0

	-- Auto KILL any user process running longer than x mins
	IF @runtimemin > 30
		SET @killcmd = 1

	-- Auto kill any user process over x Mins with no WHERE clause
	IF @runtimemin > 5 AND CHARINDEX('WHERE',@sqlcmd) = 0
		SET @killcmd = 1

	IF @killcmd = 1
	BEGIN
		SET @subject = 'KILLED: ' + @servername + ' SPID: ' + @spid + ' process running for ' + @runtimemin + ' Mins'
		DECLARE @sql varchar(1000)
		SET @sql = 'KILL ' + @spid + ';'
		--EXEC (@sql) --disabled by Patrick
	END
	ELSE
	BEGIN
		SET @subject = CASE WHEN @blockedby <> 0 THEN 'Blocked: ' ELSE 'Warning: ' END + @servername + ' SPID: ' + @spid + ' Runtime: ' + @runtimemin + ' Mins'
	END

	SET @body = 'Server: ' + @servername + CHAR(10) 
	SET @body = @body + 'SPID: ' + @spid + CHAR(10) 
	SET @body = @body + 'Start: ' + CONVERT(varchar(25), @starttime, 120) + ' Running for: ' + @runtimemin + ' Mins' + CHAR(10) 
	SET @body = @body + 'Username: ' + @loginid + CHAR(10) 
	SET @body = @body + 'Database: ' + @dbname + CHAR(10) 
	SET @body = @body + 'Wait: ' + RTRIM(@waittype) + ' ' + @waittime + 'ms ' + CASE WHEN @blockedby <> 0 THEN 'Blocked By SPID: ' + @blockedby ELSE '' END+ CHAR(10) 
	SET @body = @body + 'From Host: ' + RTRIM(@hostname) + ' PID: ' + @hostproc + CHAR(10) 
	SET @body = @body + CHAR(10) + 'Query: ' + LEFT(@sqlcmd,100) + CHAR(10) 
	SET @body = @body + CHAR(10) + CHAR(10) + '******* THIS IS AN UNMONITORED MAILBOX.  DO NOT REPLY TO THIS EMAIL ******* ' + CHAR(10) 

	--PRINT @subject
	--PRINT @body

	-- Send email
	EXEC msdb.dbo.sp_send_dbmail @recipients = @emaildba, @subject=@subject, @body=@body, @body_format = 'TEXT'


	FETCH NEXT FROM longquery INTO @servername, @loginid, @ntdomain, @ntusername,
		@hostname, @hostproc, @spid, @execcont, @waittype,
		@waitresource, @waittime, @blockedby, @starttime, @runtimesecs,
		@runtimemin, @status, @dbname, @commandtype, @sqllen, @sqlcmd
END
CLOSE longquery
DEALLOCATE longquery

SET NOCOUNT OFF
END




GO

/****** Object:  StoredProcedure [dbo].[sp_expensive_queries]    Script Date: 04/23/2015 11:14:11 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO





CREATE procedure [dbo].[sp_expensive_queries]
as
BEGIN


	SELECT TOP 20 
	 [Average IO] = (total_logical_reads + total_logical_writes) / qs.execution_count
	,[Total IO] = (total_logical_reads + total_logical_writes)
	,[Execution count] = qs.execution_count
	,[Individual Query] = SUBSTRING (qt.text,qs.statement_start_offset/2, 
			 (CASE WHEN qs.statement_end_offset = -1 
				THEN LEN(CONVERT(NVARCHAR(MAX), qt.text)) * 2 
			  ELSE qs.statement_end_offset END - qs.statement_start_offset)/2) 
			,[Parent Query] = qt.text
	,DatabaseName = DB_NAME(qt.dbid)
	FROM sys.dm_exec_query_stats qs
	CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) as qt
	ORDER BY [Average IO] DESC;

	SELECT TOP 20 
	 [Average CPU used] = total_worker_time / qs.execution_count
	,[Total CPU used] = total_worker_time
	,[Execution count] = qs.execution_count
	,[Individual Query] = SUBSTRING (qt.text,qs.statement_start_offset/2, 
			 (CASE WHEN qs.statement_end_offset = -1 
				THEN LEN(CONVERT(NVARCHAR(MAX), qt.text)) * 2 
			  ELSE qs.statement_end_offset END - 
	qs.statement_start_offset)/2)
	,[Parent Query] = qt.text
	,DatabaseName = DB_NAME(qt.dbid)
	FROM sys.dm_exec_query_stats qs
	CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) as qt
	ORDER BY [Average CPU used] DESC;

	SELECT TOP 20 
	[Total Logical Reads] = qs.total_logical_reads, 
	[Last Logical Reads] = qs.last_logical_reads,
	[Total Logical Writes] = qs.total_logical_writes, 
	[Last Logical Writes] = qs.last_logical_writes,
	[Execution count] = qs.execution_count,
	[Individual Query] = SUBSTRING(qt.TEXT, (qs.statement_start_offset/2)+1,
	((CASE qs.statement_end_offset
	WHEN -1 THEN DATALENGTH(qt.TEXT)
	ELSE qs.statement_end_offset
	END - qs.statement_start_offset)/2)+1),
	[Parent Query] = qt.text, 
	DatabaseName = DB_NAME(qt.dbid),
	[Total Worker Time] = qs.total_worker_time,
	[Last Worker Time] = qs.last_worker_time,
	[Total Elapsed Time Seconds] = qs.total_elapsed_time/1000000 ,
	[Last Elapsed Time Seconds] = qs.last_elapsed_time/1000000 ,
	[Last Execution Time] = qs.last_execution_time,
	[Query Plan] = qp.query_plan
	FROM sys.dm_exec_query_stats qs
	CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) qt
	CROSS APPLY sys.dm_exec_query_plan(qs.plan_handle) qp
	ORDER BY qs.total_logical_reads DESC

	SELECT TOP 20 
			[Total Reads] = SUM(total_logical_reads)
			,[Execution count] = SUM(qs.execution_count)
			,DatabaseName = DB_NAME(qt.dbid)
	FROM sys.dm_exec_query_stats qs
	CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) as qt
	GROUP BY DB_NAME(qt.dbid)
	ORDER BY [Total Reads] DESC;

END




GO

/****** Object:  StoredProcedure [dbo].[sp_headblocker]    Script Date: 04/23/2015 11:14:11 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

create procedure [dbo].[sp_headblocker]
as
begin

SELECT
   [Session ID]    = s.session_id,
   [User Process]  = CONVERT(CHAR(1), s.is_user_process),
   [Login]         = s.login_name,  
   [Database]      = ISNULL(db_name(p.dbid), N''),
   [Task State]    = ISNULL(t.task_state, N''),
   [Command]       = ISNULL(r.command, N''),
   [Application]   = ISNULL(s.program_name, N''),
   [Wait Time (ms)]     = ISNULL(w.wait_duration_ms, 0),
   [Wait Type]     = ISNULL(w.wait_type, N''),
   [Wait Resource] = ISNULL(w.resource_description, N''),
   [Blocked By]    = ISNULL(CONVERT (varchar, w.blocking_session_id), ''),
   [Head Blocker]  =
        CASE
            -- session has an active request, is blocked, but is blocking others or session is idle but has an open tran and is blocking others
            WHEN r2.session_id IS NOT NULL AND (r.blocking_session_id = 0 OR r.session_id IS NULL) THEN '1'
            -- session is either not blocking someone, or is blocking someone but is blocked by another party
            ELSE ''
        END,
   [Total CPU (ms)] = s.cpu_time,
   [Total Physical I/O (MB)]   = (s.reads + s.writes) * 8 / 1024,
   [Memory Use (KB)]  = s.memory_usage * 8192 / 1024,
   [Open Transactions] = ISNULL(r.open_transaction_count,0),
   [Login Time]    = s.login_time,
   [Last Request Start Time] = s.last_request_start_time,
   [Host Name]     = ISNULL(s.host_name, N''),
   [Net Address]   = ISNULL(c.client_net_address, N''),
   [Execution Context ID] = ISNULL(t.exec_context_id, 0),
   [Request ID] = ISNULL(r.request_id, 0),
   [Workload Group] = ISNULL(g.name, N'')
FROM sys.dm_exec_sessions s LEFT OUTER JOIN sys.dm_exec_connections c ON (s.session_id = c.session_id)
LEFT OUTER JOIN sys.dm_exec_requests r ON (s.session_id = r.session_id)
LEFT OUTER JOIN sys.dm_os_tasks t ON (r.session_id = t.session_id AND r.request_id = t.request_id)
LEFT OUTER JOIN
(
    -- In some cases (e.g. parallel queries, also waiting for a worker), one thread can be flagged as
    -- waiting for several different threads.  This will cause that thread to show up in multiple rows
    -- in our grid, which we don't want.  Use ROW_NUMBER to select the longest wait for each thread,
    -- and use it as representative of the other wait relationships this thread is involved in.
    SELECT *, ROW_NUMBER() OVER (PARTITION BY waiting_task_address ORDER BY wait_duration_ms DESC) AS row_num
    FROM sys.dm_os_waiting_tasks
) w ON (t.task_address = w.waiting_task_address) AND w.row_num = 1
LEFT OUTER JOIN sys.dm_exec_requests r2 ON (s.session_id = r2.blocking_session_id)
LEFT OUTER JOIN sys.dm_resource_governor_workload_groups g ON (g.group_id = s.group_id)--TAKE THIS dmv OUT TO WORK IN 2005
LEFT OUTER JOIN sys.sysprocesses p ON (s.session_id = p.spid)
where (CASE
            -- session has an active request, is blocked, but is blocking others or session is idle but has an open tran and is blocking others
            WHEN r2.session_id IS NOT NULL AND (r.blocking_session_id = 0 OR r.session_id IS NULL) THEN '1'
            -- session is either not blocking someone, or is blocking someone but is blocked by another party
            ELSE ''
        END)= 1
ORDER BY s.session_id; 
end
GO

/****** Object:  StoredProcedure [dbo].[sp_help_revlogin]    Script Date: 04/23/2015 11:14:11 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[sp_help_revlogin] @login_name sysname = NULL AS
DECLARE @name sysname
DECLARE @type varchar (1)
DECLARE @hasaccess int
DECLARE @denylogin int
DECLARE @is_disabled int
DECLARE @PWD_varbinary  varbinary (256)
DECLARE @PWD_string  varchar (514)
DECLARE @SID_varbinary varbinary (85)
DECLARE @SID_string varchar (514)
DECLARE @tmpstr  varchar (1024)
DECLARE @is_policy_checked varchar (3)
DECLARE @is_expiration_checked varchar (3)

DECLARE @defaultdb sysname
 
IF (@login_name IS NULL)
  DECLARE login_curs CURSOR FOR

      SELECT p.sid, p.name, p.type, p.is_disabled, p.default_database_name, l.hasaccess, l.denylogin FROM 
sys.server_principals p LEFT JOIN sys.syslogins l
      ON ( l.name = p.name ) WHERE p.type IN ( 'S', 'G', 'U' ) AND p.name <> 'sa'
ELSE
  DECLARE login_curs CURSOR FOR


      SELECT p.sid, p.name, p.type, p.is_disabled, p.default_database_name, l.hasaccess, l.denylogin FROM 
sys.server_principals p LEFT JOIN sys.syslogins l
      ON ( l.name = p.name ) WHERE p.type IN ( 'S', 'G', 'U' ) AND p.name = @login_name
OPEN login_curs

FETCH NEXT FROM login_curs INTO @SID_varbinary, @name, @type, @is_disabled, @defaultdb, @hasaccess, @denylogin
IF (@@fetch_status = -1)
BEGIN
  PRINT 'No login(s) found.'
  CLOSE login_curs
  DEALLOCATE login_curs
  RETURN -1
END
SET @tmpstr = '/* sp_help_revlogin script '
PRINT @tmpstr
SET @tmpstr = '** Generated ' + CONVERT (varchar, GETDATE()) + ' on ' + @@SERVERNAME + ' */'
PRINT @tmpstr
PRINT ''
WHILE (@@fetch_status <> -1)
BEGIN
  IF (@@fetch_status <> -2)
  BEGIN
    PRINT ''
    SET @tmpstr = '-- Login: ' + @name
    PRINT @tmpstr
    IF (@type IN ( 'G', 'U'))
    BEGIN -- NT authenticated account/group

      SET @tmpstr = 'CREATE LOGIN ' + QUOTENAME( @name ) + ' FROM WINDOWS WITH DEFAULT_DATABASE = [' + @defaultdb + ']'
    END
    ELSE BEGIN -- SQL Server authentication
        -- obtain password and sid
            SET @PWD_varbinary = CAST( LOGINPROPERTY( @name, 'PasswordHash' ) AS varbinary (256) )
        EXEC sp_hexadecimal @PWD_varbinary, @PWD_string OUT
        EXEC sp_hexadecimal @SID_varbinary,@SID_string OUT
 
        -- obtain password policy state
        SELECT @is_policy_checked = CASE is_policy_checked WHEN 1 THEN 'ON' WHEN 0 THEN 'OFF' ELSE NULL END FROM sys.sql_logins WHERE name = @name
        SELECT @is_expiration_checked = CASE is_expiration_checked WHEN 1 THEN 'ON' WHEN 0 THEN 'OFF' ELSE NULL END FROM sys.sql_logins WHERE name = @name
 
            SET @tmpstr = 'CREATE LOGIN ' + QUOTENAME( @name ) + ' WITH PASSWORD = ' + @PWD_string + ' HASHED, SID = ' + @SID_string + ', DEFAULT_DATABASE = [' + @defaultdb + ']'

        IF ( @is_policy_checked IS NOT NULL )
        BEGIN
          SET @tmpstr = @tmpstr + ', CHECK_POLICY = ' + @is_policy_checked
        END
        IF ( @is_expiration_checked IS NOT NULL )
        BEGIN
          SET @tmpstr = @tmpstr + ', CHECK_EXPIRATION = ' + @is_expiration_checked
        END
    END
    IF (@denylogin = 1)
    BEGIN -- login is denied access
      SET @tmpstr = @tmpstr + '; DENY CONNECT SQL TO ' + QUOTENAME( @name )
    END
    ELSE IF (@hasaccess = 0)
    BEGIN -- login exists but does not have access
      SET @tmpstr = @tmpstr + '; REVOKE CONNECT SQL TO ' + QUOTENAME( @name )
    END
    IF (@is_disabled = 1)
    BEGIN -- login is disabled
      SET @tmpstr = @tmpstr + '; ALTER LOGIN ' + QUOTENAME( @name ) + ' DISABLE'
    END
    PRINT @tmpstr
  END

  FETCH NEXT FROM login_curs INTO @SID_varbinary, @name, @type, @is_disabled, @defaultdb, @hasaccess, @denylogin
   END
CLOSE login_curs
DEALLOCATE login_curs
RETURN 0


GO

/****** Object:  StoredProcedure [dbo].[sp_hexadecimal]    Script Date: 04/23/2015 11:14:11 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[sp_hexadecimal]
    @binvalue varbinary(256),
    @hexvalue varchar (514) OUTPUT
AS
DECLARE @charvalue varchar (514)
DECLARE @i int
DECLARE @length int
DECLARE @hexstring char(16)
SELECT @charvalue = '0x'
SELECT @i = 1
SELECT @length = DATALENGTH (@binvalue)
SELECT @hexstring = '0123456789ABCDEF'
WHILE (@i <= @length)
BEGIN
  DECLARE @tempint int
  DECLARE @firstint int
  DECLARE @secondint int
  SELECT @tempint = CONVERT(int, SUBSTRING(@binvalue,@i,1))
  SELECT @firstint = FLOOR(@tempint/16)
  SELECT @secondint = @tempint - (@firstint*16)
  SELECT @charvalue = @charvalue +
    SUBSTRING(@hexstring, @firstint+1, 1) +
    SUBSTRING(@hexstring, @secondint+1, 1)
  SELECT @i = @i + 1
END

SELECT @hexvalue = @charvalue


GO

/****** Object:  StoredProcedure [dbo].[sp_job_info]    Script Date: 04/23/2015 11:14:11 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO





CREATE procedure [dbo].[sp_job_info]
as
begin



SELECT
   @@servername as [Server]
 , msdb.dbo.sysjobs.job_id AS [JobID]
 , msdb.dbo.sysjobs.name as [JobName]
 , msdb.dbo.sysjobs.enabled AS [Enabled]
 , msdb.dbo.sysjobs.description AS [JobDescription]
 , msdb.dbo.sysjobs.category_id AS [CategoryID]
 , msdb.dbo.syscategories.name AS [CategoryName]
 , CASE
       WHEN msdb.dbo.sysjobs.enabled = 0 THEN 'Disabled'
       WHEN msdb.dbo.sysjobs.job_id IS NULL THEN 'Unscheduled'
       
       WHEN msdb.dbo.sysschedules.freq_type = 0x1 -- OneTime
           THEN
               'Once on '
             + CONVERT(
                          CHAR(10)
                        , CAST( CAST( msdb.dbo.sysschedules.active_start_date AS VARCHAR ) AS DATETIME )
                        , 102 -- yyyy.mm.dd
                       )
       WHEN msdb.dbo.sysschedules.freq_type = 0x4 -- Daily
           THEN 'Daily'
       WHEN msdb.dbo.sysschedules.freq_type = 0x8 -- weekly
           THEN
               CASE
                   WHEN msdb.dbo.sysschedules.freq_recurrence_factor = 1
                       THEN 'Weekly on '
                   WHEN msdb.dbo.sysschedules.freq_recurrence_factor > 1
                       THEN 'Every '
                          + CAST( msdb.dbo.sysschedules.freq_recurrence_factor AS VARCHAR )
                          + ' weeks on '
               END
             + LEFT(
                         CASE WHEN msdb.dbo.sysschedules.freq_interval &  1 =  1 THEN 'Sunday, '    ELSE '' END
                       + CASE WHEN msdb.dbo.sysschedules.freq_interval &  2 =  2 THEN 'Monday, '    ELSE '' END
                       + CASE WHEN msdb.dbo.sysschedules.freq_interval &  4 =  4 THEN 'Tuesday, '   ELSE '' END
                       + CASE WHEN msdb.dbo.sysschedules.freq_interval &  8 =  8 THEN 'Wednesday, ' ELSE '' END
                       + CASE WHEN msdb.dbo.sysschedules.freq_interval & 16 = 16 THEN 'Thursday, '  ELSE '' END
                       + CASE WHEN msdb.dbo.sysschedules.freq_interval & 32 = 32 THEN 'Friday, '    ELSE '' END
                       + CASE WHEN msdb.dbo.sysschedules.freq_interval & 64 = 64 THEN 'Saturday, '  ELSE '' END
                     , LEN(
                                CASE WHEN msdb.dbo.sysschedules.freq_interval &  1 =  1 THEN 'Sunday, '    ELSE '' END
                              + CASE WHEN msdb.dbo.sysschedules.freq_interval &  2 =  2 THEN 'Monday, '    ELSE '' END
                              + CASE WHEN msdb.dbo.sysschedules.freq_interval &  4 =  4 THEN 'Tuesday, '   ELSE '' END
                              + CASE WHEN msdb.dbo.sysschedules.freq_interval &  8 =  8 THEN 'Wednesday, ' ELSE '' END
                              + CASE WHEN msdb.dbo.sysschedules.freq_interval & 16 = 16 THEN 'Thursday, '  ELSE '' END
                              + CASE WHEN msdb.dbo.sysschedules.freq_interval & 32 = 32 THEN 'Friday, '    ELSE '' END
                              + CASE WHEN msdb.dbo.sysschedules.freq_interval & 64 = 64 THEN 'Saturday, '  ELSE '' END
                           )  - 1  -- LEN() ignores trailing spaces
                   )
       WHEN msdb.dbo.sysschedules.freq_type = 0x10 -- monthly
           THEN
               CASE
                   WHEN msdb.dbo.sysschedules.freq_recurrence_factor = 1
                       THEN 'Monthly on the '
                   WHEN msdb.dbo.sysschedules.freq_recurrence_factor > 1
                       THEN 'Every '
                          + CAST( msdb.dbo.sysschedules.freq_recurrence_factor AS VARCHAR )
                          + ' months on the '
               END
             + CAST( msdb.dbo.sysschedules.freq_interval AS VARCHAR )
             + CASE
                   WHEN msdb.dbo.sysschedules.freq_interval IN ( 1, 21, 31 ) THEN 'st'
                   WHEN msdb.dbo.sysschedules.freq_interval IN ( 2, 22     ) THEN 'nd'
                   WHEN msdb.dbo.sysschedules.freq_interval IN ( 3, 23     ) THEN 'rd'
                   ELSE 'th'
               END
       WHEN msdb.dbo.sysschedules.freq_type = 0x20 -- monthly relative
           THEN
               CASE
                   WHEN msdb.dbo.sysschedules.freq_recurrence_factor = 1
                       THEN 'Monthly on the '
                   WHEN msdb.dbo.sysschedules.freq_recurrence_factor > 1
                       THEN 'Every '
                          + CAST( msdb.dbo.sysschedules.freq_recurrence_factor AS VARCHAR )
                          + ' months on the '
               END
             + CASE msdb.dbo.sysschedules.freq_relative_interval
                   WHEN 0x01 THEN 'first '
                   WHEN 0x02 THEN 'second '
                   WHEN 0x04 THEN 'third '
                   WHEN 0x08 THEN 'fourth '
                   WHEN 0x10 THEN 'last '
               END
             + CASE msdb.dbo.sysschedules.freq_interval
                   WHEN  1 THEN 'Sunday'
                   WHEN  2 THEN 'Monday'
                   WHEN  3 THEN 'Tuesday'
                   WHEN  4 THEN 'Wednesday'
                   WHEN  5 THEN 'Thursday'
                   WHEN  6 THEN 'Friday'
                   WHEN  7 THEN 'Saturday'
                   WHEN  8 THEN 'day'
                   WHEN  9 THEN 'week day'
                   WHEN 10 THEN 'weekend day'
               END
       WHEN msdb.dbo.sysschedules.freq_type = 0x40
           THEN 'Automatically starts when SQLServerAgent starts.'
       WHEN msdb.dbo.sysschedules.freq_type = 0x80
           THEN 'Starts whenever the CPUs become idle'
       ELSE ''
   END
 + CASE
       WHEN msdb.dbo.sysjobs.enabled = 0 THEN ''
       WHEN msdb.dbo.sysjobs.job_id IS NULL THEN ''
       WHEN msdb.dbo.sysschedules.freq_subday_type = 0x1 OR msdb.dbo.sysschedules.freq_type = 0x1
           THEN ' at '
			+ Case  -- Depends on time being integer to drop right-side digits
				when(msdb.dbo.sysschedules.active_start_time % 1000000)/10000 = 0 then 
						  '12'
						+ ':'  
						+Replicate('0',2 - len(convert(char(2),(msdb.dbo.sysschedules.active_start_time % 10000)/100)))
						+ convert(char(2),(msdb.dbo.sysschedules.active_start_time % 10000)/100) 
						+ ' AM'
				when (msdb.dbo.sysschedules.active_start_time % 1000000)/10000< 10 then
						convert(char(1),(msdb.dbo.sysschedules.active_start_time % 1000000)/10000) 
						+ ':'  
						+Replicate('0',2 - len(convert(char(2),(msdb.dbo.sysschedules.active_start_time % 10000)/100))) 
						+ convert(char(2),(msdb.dbo.sysschedules.active_start_time % 10000)/100) 
						+ ' AM'
				when (msdb.dbo.sysschedules.active_start_time % 1000000)/10000 < 12 then
						convert(char(2),(msdb.dbo.sysschedules.active_start_time % 1000000)/10000) 
						+ ':'  
						+Replicate('0',2 - len(convert(char(2),(msdb.dbo.sysschedules.active_start_time % 10000)/100))) 
						+ convert(char(2),(msdb.dbo.sysschedules.active_start_time % 10000)/100) 
						+ ' AM'
				when (msdb.dbo.sysschedules.active_start_time % 1000000)/10000< 22 then
						convert(char(1),((msdb.dbo.sysschedules.active_start_time % 1000000)/10000) - 12) 
						+ ':'  
						+Replicate('0',2 - len(convert(char(2),(msdb.dbo.sysschedules.active_start_time % 10000)/100))) 
						+ convert(char(2),(msdb.dbo.sysschedules.active_start_time % 10000)/100) 
						+ ' PM'
				else	convert(char(2),((msdb.dbo.sysschedules.active_start_time % 1000000)/10000) - 12)
						+ ':'  
						+Replicate('0',2 - len(convert(char(2),(msdb.dbo.sysschedules.active_start_time % 10000)/100))) 
						+ convert(char(2),(msdb.dbo.sysschedules.active_start_time % 10000)/100) 
						+ ' PM'
			end
       WHEN msdb.dbo.sysschedules.freq_subday_type IN ( 0x2, 0x4, 0x8 )
           THEN ' every '
             + CAST( msdb.dbo.sysschedules.freq_subday_interval AS VARCHAR )
             + CASE freq_subday_type
                   WHEN 0x2 THEN ' second'
                   WHEN 0x4 THEN ' minute'
                   WHEN 0x8 THEN ' hour'
               END
             + CASE
                   WHEN msdb.dbo.sysschedules.freq_subday_interval > 1 THEN 's'
				   ELSE '' -- Added default 3/21/08; John Arnott
               END
       ELSE ''
   END
 + CASE
       WHEN msdb.dbo.sysjobs.enabled = 0 THEN ''
       WHEN msdb.dbo.sysjobs.job_id IS NULL THEN ''
       WHEN msdb.dbo.sysschedules.freq_subday_type IN ( 0x2, 0x4, 0x8 )
           THEN ' between '
			+ Case  -- Depends on time being integer to drop right-side digits
				when(msdb.dbo.sysschedules.active_start_time % 1000000)/10000 = 0 then 
						  '12'
						+ ':'  
						+Replicate('0',2 - len(convert(char(2),(msdb.dbo.sysschedules.active_start_time % 10000)/100)))
						+ rtrim(convert(char(2),(msdb.dbo.sysschedules.active_start_time % 10000)/100))
						+ ' AM'
				when (msdb.dbo.sysschedules.active_start_time % 1000000)/10000< 10 then
						convert(char(1),(msdb.dbo.sysschedules.active_start_time % 1000000)/10000) 
						+ ':'  
						+Replicate('0',2 - len(convert(char(2),(msdb.dbo.sysschedules.active_start_time % 10000)/100))) 
						+ rtrim(convert(char(2),(msdb.dbo.sysschedules.active_start_time % 10000)/100))
						+ ' AM'
				when (msdb.dbo.sysschedules.active_start_time % 1000000)/10000 < 12 then
						convert(char(2),(msdb.dbo.sysschedules.active_start_time % 1000000)/10000) 
						+ ':'  
						+Replicate('0',2 - len(convert(char(2),(msdb.dbo.sysschedules.active_start_time % 10000)/100))) 
						+ rtrim(convert(char(2),(msdb.dbo.sysschedules.active_start_time % 10000)/100)) 
						+ ' AM'
				when (msdb.dbo.sysschedules.active_start_time % 1000000)/10000< 22 then
						convert(char(1),((msdb.dbo.sysschedules.active_start_time % 1000000)/10000) - 12) 
						+ ':'  
						+Replicate('0',2 - len(convert(char(2),(msdb.dbo.sysschedules.active_start_time % 10000)/100))) 
						+ rtrim(convert(char(2),(msdb.dbo.sysschedules.active_start_time % 10000)/100)) 
						+ ' PM'
				else	convert(char(2),((msdb.dbo.sysschedules.active_start_time % 1000000)/10000) - 12)
						+ ':'  
						+Replicate('0',2 - len(convert(char(2),(msdb.dbo.sysschedules.active_start_time % 10000)/100))) 
						+ rtrim(convert(char(2),(msdb.dbo.sysschedules.active_start_time % 10000)/100))
						+ ' PM'
			end
             + ' and '
			+ Case  -- Depends on time being integer to drop right-side digits
				when(msdb.dbo.sysschedules.active_end_time % 1000000)/10000 = 0 then 
						'12'
						+ ':'  
						+Replicate('0',2 - len(convert(char(2),(msdb.dbo.sysschedules.active_end_time % 10000)/100)))
						+ rtrim(convert(char(2),(msdb.dbo.sysschedules.active_end_time % 10000)/100))
						+ ' AM'
				when (msdb.dbo.sysschedules.active_end_time % 1000000)/10000< 10 then
						convert(char(1),(msdb.dbo.sysschedules.active_end_time % 1000000)/10000) 
						+ ':'  
						+Replicate('0',2 - len(convert(char(2),(msdb.dbo.sysschedules.active_end_time % 10000)/100))) 
						+ rtrim(convert(char(2),(msdb.dbo.sysschedules.active_end_time % 10000)/100))
						+ ' AM'
				when (msdb.dbo.sysschedules.active_end_time % 1000000)/10000 < 12 then
						convert(char(2),(msdb.dbo.sysschedules.active_end_time % 1000000)/10000) 
						+ ':'  
						+Replicate('0',2 - len(convert(char(2),(msdb.dbo.sysschedules.active_end_time % 10000)/100))) 
						+ rtrim(convert(char(2),(msdb.dbo.sysschedules.active_end_time % 10000)/100))
						+ ' AM'
				when (msdb.dbo.sysschedules.active_end_time % 1000000)/10000< 22 then
						convert(char(1),((msdb.dbo.sysschedules.active_end_time % 1000000)/10000) - 12)
						+ ':'  
						+Replicate('0',2 - len(convert(char(2),(msdb.dbo.sysschedules.active_end_time % 10000)/100))) 
						+ rtrim(convert(char(2),(msdb.dbo.sysschedules.active_end_time % 10000)/100)) 
						+ ' PM'
				else	convert(char(2),((msdb.dbo.sysschedules.active_end_time % 1000000)/10000) - 12)
						+ ':'  
						+Replicate('0',2 - len(convert(char(2),(msdb.dbo.sysschedules.active_end_time % 10000)/100))) 
						+ rtrim(convert(char(2),(msdb.dbo.sysschedules.active_end_time % 10000)/100)) 
						+ ' PM'
			end
       ELSE ''
   END AS Schedule

FROM         
msdb.dbo.sysjobs 
INNER JOIN msdb.dbo.sysjobschedules ON msdb.dbo.sysjobs.job_id = msdb.dbo.sysjobschedules.job_id 
INNER JOIN msdb.dbo.sysschedules ON msdb.dbo.sysjobschedules.schedule_id = msdb.dbo.sysschedules.schedule_id
INNER JOIN msdb.dbo.syscategories ON msdb.dbo.sysjobs.category_id = msdb.dbo.syscategories.category_id
order by 2

/*
SELECT
J.job_id
,s.schedule_id
,J.NAME JOB
,J.enabled
,case ss.freq_type
when 4 then 'Daily'
when 8 then 'Weekly'
else 'Other'
end freq_type
,ss.freq_interval
,DATEADD(SS,(H.RUN_TIME)%100,DATEADD(N,(H.RUN_TIME/100)%100,DATEADD(HH,H.RUN_TIME/10000,CONVERT(DATETIME,CONVERT(VARCHAR(8),H.RUN_DATE),112))))
JOB_STARTED,
DATEADD(SS,((H.RUN_DURATION)%10000)%100,DATEADD(N,((H.RUN_DURATION)%10000)/100,DATEADD(HH,(H.RUN_DURATION)/10000,DATEADD(SS,(H.RUN_TIME)%100,DATEADD(N,(H.RUN_TIME/100)%100,DATEADD(HH,H.RUN_TIME/10000,CONVERT(DATETIME,CONVERT(VARCHAR(8),H.RUN_DATE),112)))))))
JOB_COMPLETED,
CONVERT(VARCHAR(2),(H.RUN_DURATION)/10000) + ':' +
CONVERT(VARCHAR(2),((H.RUN_DURATION)%10000)/100)+ ':' +
CONVERT(VARCHAR(2),((H.RUN_DURATION)%10000)%100) RUN_DURATION,
CASE H.RUN_STATUS
WHEN 0 THEN 'FAILED'
WHEN 1 THEN 'SUCCEEDED'
WHEN 2 THEN 'RETRY'
WHEN 3 THEN 'CANCELED'
WHEN 4 THEN 'IN PROGRESS'
END RUN_STATUS
,(CASE
WHEN S.NEXT_RUN_DATE > 0 THEN DATEADD(N,(NEXT_RUN_TIME%10000)/100,DATEADD(HH,NEXT_RUN_TIME/10000,CONVERT(DATETIME,CONVERT(VARCHAR(8),NEXT_RUN_DATE),112)))
ELSE CONVERT(DATETIME,CONVERT( VARCHAR(8),'19000101'),112) END) NEXT_RUN
,S.NEXT_RUN_DATE
,S.NEXT_RUN_TIME
,@@servername as server
FROM
MSDB.dbo.SYSJOBHISTORY H,
MSDB.dbo.SYSJOBS J, 
MSDB.dbo.SYSJOBSCHEDULES S,
MSDB.dbo.SYSSCHEDULES SS,
(SELECT MAX(INSTANCE_ID) INSTANCE_ID, JOB_ID FROM MSDB.dbo.SYSJOBHISTORY GROUP BY JOB_ID) M
WHERE
H.JOB_ID = J.JOB_ID AND J.JOB_ID = S.JOB_ID AND H.JOB_ID = M.JOB_ID AND H.INSTANCE_ID = M.INSTANCE_ID
and SS.schedule_id = s.schedule_id
--and next_run_date = 20130326
--and next_run_time > 160000
--and J.NAME like 'CES Daily Maintenance - %'
order by J.NAME
*/

end




GO

/****** Object:  StoredProcedure [dbo].[sp_job_status]    Script Date: 04/23/2015 11:14:11 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO





create procedure [dbo].[sp_job_status]
(
	@isrunning bit = 0 ,
	@jobname nvarchar(255) = null
)
as
begin

	--set @jobname = 'CSOD Service Queue Collector'
	--set @isrunning = 0 -- 0:all 1:running
	
	IF EXISTS (SELECT * FROM tempdb.dbo.sysobjects WHERE   id = OBJECT_ID(N'[tempdb].[dbo].[Temp1]'))
		DROP TABLE [tempdb].[dbo].[Temp1]


	CREATE TABLE [tempdb].[dbo].[Temp1]
	(
	job_id uniqueidentifier NOT NULL,
	last_run_date nvarchar (20) NOT NULL,
	last_run_time nvarchar (20) NOT NULL,
	next_run_date nvarchar (20) NOT NULL,
	next_run_time nvarchar (20) NOT NULL,
	next_run_schedule_id INT NOT NULL,
	requested_to_run INT NOT NULL,
	request_source INT NOT NULL,
	request_source_id sysname
	COLLATE database_default NULL,
	running INT NOT NULL,
	current_step INT NOT NULL,
	current_retry_attempt INT NOT NULL,
	job_state INT NOT NULL)
	
	DECLARE @job_owner   sysname
	DECLARE @is_sysadmin   INT
	SET @is_sysadmin   = isnull (is_srvrolemember ('sysadmin'), 0)
	SET @job_owner   = suser_sname ()
	
	if @jobname is null
	begin

		INSERT INTO [tempdb].[dbo].[Temp1]
		--EXECUTE sys.xp_sqlagent_enum_jobs @is_sysadmin, @job_owner
		EXECUTE master.dbo.xp_sqlagent_enum_jobs @is_sysadmin, @job_owner
		UPDATE [tempdb].[dbo].[Temp1]
		SET last_run_time    = right ('000000' + last_run_time, 6),
		next_run_time    = right ('000000' + next_run_time, 6);
		-----
		SELECT j.name AS JobName,
		j.enabled AS Enabled,
		CASE x.running
		WHEN 1
		THEN
		'Running'
		ELSE
		CASE h.run_status
		WHEN 2 THEN 'Inactive'
		WHEN 4 THEN 'Inactive'
		ELSE 'Completed'
		END
		END
		AS CurrentStatus,
		coalesce (x.current_step, 0) AS CurrentStepNbr,
		CASE
		WHEN x.last_run_date > 0
		THEN
		convert (datetime,
		substring (x.last_run_date, 1, 4)
		+ '-'
		+ substring (x.last_run_date, 5, 2)
		+ '-'
		+ substring (x.last_run_date, 7, 2)
		+ ' '
		+ substring (x.last_run_time, 1, 2)
		+ ':'
		+ substring (x.last_run_time, 3, 2)
		+ ':'
		+ substring (x.last_run_time, 5, 2)
		+ '.000',
		121
		)
		ELSE
		NULL
		END
		AS LastRunTime,
		CASE h.run_status
		WHEN 0 THEN 'Fail'
		WHEN 1 THEN 'Success'
		WHEN 2 THEN 'Retry'
		WHEN 3 THEN 'Cancel'
		WHEN 4 THEN 'In progress'
		END
		AS LastRunOutcome,
		CASE
		WHEN h.run_duration > 0
		THEN
		(h.run_duration / 1000000) * (3600 * 24)
		+ (h.run_duration / 10000 % 100) * 3600
		+ (h.run_duration / 100 % 100) * 60
		+ (h.run_duration % 100)
		ELSE
		NULL
		END
		AS LastRunDuration
		FROM          [tempdb].[dbo].[Temp1] x
		LEFT JOIN
		msdb.dbo.sysjobs j
		ON x.job_id = j.job_id
		LEFT OUTER JOIN
		msdb.dbo.syscategories c
		ON j.category_id = c.category_id
		LEFT OUTER JOIN
		msdb.dbo.sysjobhistory h
		ON     x.job_id = h.job_id
		AND x.last_run_date = h.run_date
		AND x.last_run_time = h.run_time
		AND h.step_id = 0
		--where 
		--x.running = 1 -- to see running jobs
		--j.name = 'CSOD Service Queue Collector' --specific job
		
	end
	else
	begin

		INSERT INTO [tempdb].[dbo].[Temp1]
		--EXECUTE sys.xp_sqlagent_enum_jobs @is_sysadmin, @job_owner
		EXECUTE master.dbo.xp_sqlagent_enum_jobs @is_sysadmin, @job_owner
		UPDATE [tempdb].[dbo].[Temp1]
		SET last_run_time    = right ('000000' + last_run_time, 6),
		next_run_time    = right ('000000' + next_run_time, 6);
		-----
		SELECT j.name AS JobName,
		j.enabled AS Enabled,
		CASE x.running
		WHEN 1
		THEN
		'Running'
		ELSE
		CASE h.run_status
		WHEN 2 THEN 'Inactive'
		WHEN 4 THEN 'Inactive'
		ELSE 'Completed'
		END
		END
		AS CurrentStatus,
		coalesce (x.current_step, 0) AS CurrentStepNbr,
		CASE
		WHEN x.last_run_date > 0
		THEN
		convert (datetime,
		substring (x.last_run_date, 1, 4)
		+ '-'
		+ substring (x.last_run_date, 5, 2)
		+ '-'
		+ substring (x.last_run_date, 7, 2)
		+ ' '
		+ substring (x.last_run_time, 1, 2)
		+ ':'
		+ substring (x.last_run_time, 3, 2)
		+ ':'
		+ substring (x.last_run_time, 5, 2)
		+ '.000',
		121
		)
		ELSE
		NULL
		END
		AS LastRunTime,
		CASE h.run_status
		WHEN 0 THEN 'Fail'
		WHEN 1 THEN 'Success'
		WHEN 2 THEN 'Retry'
		WHEN 3 THEN 'Cancel'
		WHEN 4 THEN 'In progress'
		END
		AS LastRunOutcome,
		CASE
		WHEN h.run_duration > 0
		THEN
		(h.run_duration / 1000000) * (3600 * 24)
		+ (h.run_duration / 10000 % 100) * 3600
		+ (h.run_duration / 100 % 100) * 60
		+ (h.run_duration % 100)
		ELSE
		NULL
		END
		AS LastRunDuration
		FROM          [tempdb].[dbo].[Temp1] x
		LEFT JOIN
		msdb.dbo.sysjobs j
		ON x.job_id = j.job_id
		LEFT OUTER JOIN
		msdb.dbo.syscategories c
		ON j.category_id = c.category_id
		LEFT OUTER JOIN
		msdb.dbo.sysjobhistory h
		ON     x.job_id = h.job_id
		AND x.last_run_date = h.run_date
		AND x.last_run_time = h.run_time
		AND h.step_id = 0
		where 
		--x.running = 1 -- to see running jobs
		j.name = @jobname --specific job
	
	end	
end




GO

/****** Object:  StoredProcedure [dbo].[sp_kill]    Script Date: 04/23/2015 11:14:11 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO





create procedure [dbo].[sp_kill] 
(
	@dbname varchar(100) = null, -- When specified, kills all spids inside of the database
	@loginame varchar(50) = null, -- When specified, kills all spids under the login name
	@hostname varchar(50) = null -- When specified, kills all spids originating from the host machine
)
as
begin
	set nocount on
	select spid, db_name(dbid) as 'db_name', loginame, hostname into #tb1_sysprocesses from master.dbo.sysprocesses (nolock)
	declare @total_logins int, @csr_spid varchar(100) 
	set @total_logins = ( select count(distinct spid) from #tb1_sysprocesses )
	if @dbname is null
		begin
		if @loginame is null
			begin
				if @hostname is null
				begin
				if @total_logins > 0
				begin 
				declare csr_spid cursor fast_forward for select distinct spid from #tb1_sysprocesses where loginame <> 'sa' and spid <> @@spid
				open csr_spid 
				fetch next from csr_spid into @csr_spid
				while @@fetch_status = 0
				begin
				set nocount on 
				exec ('kill ' + @csr_spid)
				fetch next from csr_spid into @csr_spid
				end
				close csr_spid
				deallocate csr_spid
				end
				end
				else
				begin
				if @total_logins > 0
				begin 
				declare csr_spid cursor fast_forward for select distinct spid from #tb1_sysprocesses where hostname = @hostname and loginame <> 'sa' and spid <> @@spid
				open csr_spid 
				fetch next from csr_spid into @csr_spid
				while @@fetch_status = 0
				begin
				set nocount on 
				exec ('kill ' + @csr_spid)
				fetch next from csr_spid into @csr_spid
				end
				close csr_spid
				deallocate csr_spid
				end
				end
				--------------------------------------------------
				end 
				else
				begin
				if @total_logins > 0
				begin 
				declare csr_spid cursor fast_forward for select distinct spid from #tb1_sysprocesses where loginame = @loginame and loginame <> 'sa' and spid <> @@spid
				open csr_spid 
				fetch next from csr_spid into @csr_spid
				while @@fetch_status = 0
				begin
				set nocount on 
				exec ('kill ' + @csr_spid)
				fetch next from csr_spid into @csr_spid
				end
				close csr_spid
				deallocate csr_spid
				end

				end
				-----------------------
				end
				else
				begin
				if @total_logins > 0
				begin 
				declare csr_spid cursor fast_forward for select distinct spid from #tb1_sysprocesses where db_name = @dbname and loginame <> 'sa' and spid <> @@spid
				open csr_spid 
				fetch next from csr_spid into @csr_spid
				while @@fetch_status = 0
				begin
				set nocount on 
				exec ('kill ' + @csr_spid)
				fetch next from csr_spid into @csr_spid
				end
			close csr_spid
			deallocate csr_spid
			end

		end
	drop table #tb1_sysprocesses
end




GO

/****** Object:  StoredProcedure [dbo].[sp_kill_user]    Script Date: 04/23/2015 11:14:11 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



/*
exec sp_kill_user 'db_user'
*/
CREATE proc [dbo].[sp_kill_user]
(
	@username nvarchar(1000) = 'db_user'
)
as
begin

    SET NOCOUNT ON
 
    DECLARE @spid INT,
        @cnt INT,
        @sql VARCHAR(255)
 
    SELECT @spid = MIN(spid), @cnt = COUNT(*)
        FROM master..sysprocesses
        WHERE loginame = @username
        AND spid != @@SPID
 
    PRINT 'Starting to KILL '+RTRIM(@cnt)+' processes.'
    
    WHILE @spid IS NOT NULL
    BEGIN
        PRINT 'About to KILL '+RTRIM(@spid)  
        SET @sql = 'KILL '+RTRIM(@spid)
        EXEC(@sql)  
        SELECT @spid = MIN(spid), @cnt = COUNT(*)
            FROM master..sysprocesses
            WHERE loginame = @username
            AND spid != @@SPID  
        PRINT RTRIM(@cnt)+' processes remain.'
    END
END



GO

/****** Object:  StoredProcedure [dbo].[sp_ListFiles]    Script Date: 04/23/2015 11:14:11 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO




/*
EXECUTE sp_ListFiles 'H:\IISLogs\logs','log'
*/
CREATE PROCEDURE [dbo].[sp_ListFiles]
(
	@folder varchar(100) = 'H:\IISLogs\logs' , 
	@extention varchar(10) = 'log'
)
as
begin

declare @sql nvarchar(4000)

if @extention is null
begin
set @sql = 'DIR ' + '"' + @folder + '\*.*"'
end
else
begin
set @sql = 'DIR ' + '"' + @folder + '\*.'+@extention+'"'
end

print @sql

if(OBJECT_ID('tempdb..#tmp_tbl')>0)
	drop table #tmp_tbl
	
CREATE TABLE #tmp_tbl (Name varchar(400), Work int IDENTITY(1,1))

INSERT #tmp_tbl EXECUTE master.dbo.xp_cmdshell @sql

--select * From #tmp_tbl
DELETE #tmp_tbl WHERE ISDATE(SUBSTRING(Name,1,10)) = 0 OR SUBSTRING(Name,40,1) = '.' OR Name LIKE '%.lnk'
--select * From #tmp_tbl

SELECT SUBSTRING(Name,40,100) AS Files
FROM #tmp_tbl
ORDER BY 1


end



GO

/****** Object:  StoredProcedure [dbo].[sp_long_running_queries]    Script Date: 04/23/2015 11:14:11 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO





/*
exec sp_long_running_queries @longduration = 15 , @sendalertemail = 1 , @showsessions = 0 , @killsessions = 0
exec sp_long_running_queries @longduration = 15 , @sendalertemail = 0 , @showsessions = 1 , @killsessions = 0
exec sp_long_running_queries @longduration = 15 , @sendalertemail = 0 , @showsessions = 1 , @killsessions = 1

exec sp_long_running_queries @longduration = 120 , @sendalertemail = 1 , @showsessions = 1 , @killsessions = 1
exec sp_long_running_queries @longduration = 120 , @sendalertemail = 1 , @showsessions = 1 , @killsessions = 1, @dbname = 'VSphere_UpdateManager'

*/
CREATE procedure [dbo].[sp_long_running_queries]
(
	@longduration int = 15 -- minutes
	, @sendalertemail int = 0
	, @showsessions int = 0
	, @killsessions int = 0
	, @dbname nvarchar(100) = null
)
as
BEGIN

	CREATE TABLE #_tmp_whoisactive
	( [dd hh:mm:ss.mss] varchar(8000) NULL,[session_id] smallint NOT NULL,[sql_text] xml NULL,[login_name] nvarchar(128) NOT NULL,[wait_info] nvarchar(4000) NULL,[CPU] varchar(30) NULL,[tempdb_allocations] varchar(30) NULL,[tempdb_current] varchar(30) NULL,[
blocking_session_id] smallint NULL,[reads] varchar(30) NULL,[writes] varchar(30) NULL,[physical_reads] varchar(30) NULL,[used_memory] varchar(30) NULL,[status] varchar(30) NOT NULL,[open_tran_count] varchar(30) NULL,[percent_complete] varchar(30) NULL,[ho
st_name] nvarchar(128) NULL,[database_name] nvarchar(128) NULL,[program_name] nvarchar(128) NULL,[start_time] datetime NOT NULL,[login_time] datetime NULL,[request_id] int NULL,[collection_time] datetime NOT NULL)

	exec sp_WhoIsActive @destination_table = '#_tmp_whoisactive'

	--delete from #_tmp_whoisactive where login_name in (select account_name from [AuditExceptionAccounts])

	--select datediff(mi,start_time,collection_time) , * from #_tmp_whoisactive where datediff(mi,start_time,collection_time) > @longduration
	if @showsessions = 1 
	begin
		select * from #_tmp_whoisactive where datediff(mi,start_time,collection_time) > @longduration
	end
	
	if @sendalertemail = 1 and exists (	select * from #_tmp_whoisactive where datediff(mi,start_time,collection_time) > @longduration)
	begin

		DECLARE @tableHTML  NVARCHAR(MAX) , @subjectstring nvarchar(200);

		SET @tableHTML =
			N'<H1>Long Runing Queries on '+@@SERVERNAME+' executing over '+convert(nvarchar(10),@longduration)+' minutes</H1>' +
			N'<table border="1">' +
			N'<tr><th>Time Elapsed</th><th>Session</th>' +
			N'<th>Login Name</th><th>Database</th><th>Executing Host</th>' +
			N'<th>Status</th></tr>' +
			CAST ( ( SELECT td = [dd hh:mm:ss.mss],       '',
							td = session_id, '',
							td = login_name, '',
							td = database_name, '',
							td = host_name(), '',
							td = Status
					  FROM #_tmp_whoisactive
					  where datediff(mi,start_time,collection_time) > @longduration
					  FOR XML PATH('tr'), TYPE 
			) AS NVARCHAR(MAX) ) +
			N'</table>' ;
			
			--print @tableHTML
		    
		set @subjectstring = 'Long Running Queries over '+convert(nvarchar(10),@longduration)+' min on SQL Server '+@@SERVERNAME 
		EXEC msdb.dbo.sp_send_dbmail
			@profile_name = 'default',
			@recipients = 'patrickalexander@hotmail.com',
			@body = @tableHTML,
			@body_format = 'HTML' ,
			@subject = @subjectstring;
	    
	end
	
	--kill sessions
	if @killsessions = 1 
	begin

		declare @mid int , @sql nvarchar(1000)
		declare tmp_cur cursor for 
		select [session_id] from #_tmp_whoisactive where (datediff(mi,start_time,collection_time) > @longduration) and ([database_name] = @dbname or @dbname is null)

		open tmp_cur
		Fetch next from tmp_cur into @mid

		while @@fetch_status = 0
		begin
		print @mid
		set @sql = 'kill '+ CONVERT(nvarchar(10), @mid)
		print @sql
		exec sp_executesql @sql
		Fetch next from tmp_cur into @mid
		print '---'
		end

		close tmp_cur
		deallocate tmp_cur
	end

	drop table #_tmp_whoisactive

END






GO

/****** Object:  StoredProcedure [dbo].[sp_maintenance_re_index]    Script Date: 04/23/2015 11:14:11 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO




/*
maintenance_re_index 10
*/
Create Procedure [dbo].[sp_maintenance_re_index]
(
	@MaxFragmentation int = 10 ,
	@TrivialPageCount int = 30 ,
	@RebuildThreshold int = 1000
)
as
BEGIN

SET NOCOUNT ON; 
SET QUOTED_IDENTIFIER ON;

DECLARE @objectid int; 
DECLARE @indexid int; 
DECLARE @partitioncount bigint; 
DECLARE @schemaname nvarchar(130); 
DECLARE @objectname nvarchar(130); 
DECLARE @indexname nvarchar(130); 
DECLARE @partitionnum bigint; 
DECLARE @partitions bigint; 
DECLARE @frag float; 
DECLARE @command nvarchar(4000); 
DECLARE @HasBlobColumn int; 

--DECLARE @MaxFragmentation int; 
--DECLARE @TrivialPageCount int;
--DECLARE @RebuildThreshold int;

---- Tuning constants 
--SET @MaxFragmentation = 10 --Change this value to adjust the threshold for fragmentation
--SET @RebuildThreshold = 30 --Change this value to adjust the break point for defrag/rebuild
--SET @TrivialPageCount = 1000 --Change this value to adjust the size threshold

-- Conditionally select tables and indexes from the sys.dm_db_index_physical_stats function 
-- and convert object and index IDs to names. 
if(OBJECT_ID('tempdb..#work_to_do')>1)
	DROP TABLE #work_to_do; 

SELECT distinct
object_id AS objectid, 
index_id AS indexid, 
partition_number AS partitionnum, 
avg_fragmentation_in_percent AS frag 
INTO #work_to_do 
FROM sys.dm_db_index_physical_stats (DB_ID(), NULL, NULL, NULL, 'LIMITED') 
WHERE avg_fragmentation_in_percent > @MaxFragmentation
AND index_id > 0 -- cannot defrag a heap 
AND page_count > @TrivialPageCount -- ignore trivial sized indexes 

-- Declare the cursor for the list of partitions to be processed. 
DECLARE partitions CURSOR FOR 
SELECT distinct WTD.* 
FROM #work_to_do WTD
INNER JOIN sys.indexes I ON I.object_id = WTD.objectid
WHERE I.is_disabled = 0 AND I.is_hypothetical = 0; 

-- Open the cursor. 

OPEN partitions; 

-- Loop through the partitions. 

WHILE (1=1) 
	BEGIN; 
		FETCH NEXT FROM partitions INTO @objectid, @indexid, @partitionnum, @frag; 
		IF @@FETCH_STATUS < 0 BREAK; 
			SET @HasBlobColumn = 0 -- reinitialize 
			SELECT @objectname = QUOTENAME(o.name), @schemaname = QUOTENAME(s.name) 
			FROM sys.objects AS o 
			JOIN sys.schemas AS s ON s.schema_id = o.schema_id  WHERE o.object_id = @objectid; 
			
			SELECT @indexname = QUOTENAME(name) 
			FROM sys.indexes 
			WHERE object_id = @objectid AND index_id = @indexid; 

			SELECT @partitioncount = count (*) 
			FROM sys.partitions 
			WHERE object_id = @objectid AND index_id = @indexid; 

			-- Check for BLOB columns 
			IF @indexid = 1 -- only check here for clustered indexes ANY blob column on the table counts 
				SELECT @HasBlobColumn = CASE WHEN max(so.object_ID) IS NULL THEN 0 ELSE 1 END 
				FROM sys.objects SO 
				inner join sys.columns SC ON SO.Object_id = SC.object_id 
				inner join sys.types ST ON SC.system_type_id = ST.system_type_id AND ST.name IN ('text', 'ntext', 'image', 'varchar', 'nvarchar', 'varbinary', 'xml') AND SC.max_length = -1 
				WHERE SO.Object_ID = @objectID 
			ELSE -- nonclustered. Only need to check if indexed column is a BLOB 
				SELECT @HasBlobColumn = CASE WHEN max(so.object_ID) IS NULL THEN 0 ELSE 1 END 
				FROM sys.objects SO 
				INNER JOIN sys.index_columns SIC ON SO.Object_ID = SIC.object_id 
				INNER JOIN sys.Indexes SI ON SO.Object_ID = SI.Object_ID AND SIC.index_id = SI.index_id 
				INNER JOIN sys.columns SC ON SO.Object_id = SC.object_id AND SIC.Column_id = SC.column_id 
				INNER JOIN sys.types ST ON SC.system_type_id = ST.system_type_id AND ST.name IN ('text', 'ntext', 'image', 'varchar', 'nvarchar', 'varbinary', 'xml') AND SC.max_length = -1 
				WHERE SO.Object_ID = @objectID 
			
				SET @command = N'ALTER INDEX ' + @indexname + N' ON ' + @schemaname + N'.' + @objectname; 
				IF @frag > @RebuildThreshold
				BEGIN
					SET @command = @command + N' REBUILD'
					IF @HasBlobColumn = 1
						SET @command = @command + N' WITH( SORT_IN_TEMPDB = ON) ' 
					ELSE 
						SET @command = @command + N' WITH( ONLINE = ON, SORT_IN_TEMPDB = ON) ' 
				END
				ELSE
					SET @command = @command + N' REORGANIZE'
					IF @partitioncount > 1 
						SET @command = @command + N' PARTITION=' + CAST(@partitionnum AS nvarchar(10)); 
						PRINT N'Executing: ' + @command +' Has Blob = ' + convert(nvarchar(2),@HasBlobColumn); 
						
						--PRINT  @command 
						--print 'print '''+@command +''''
						--print 'Go'
						EXEC (@command) 
		END; 
		-- Close and deallocate the cursor. 
		CLOSE partitions; 
		DEALLOCATE partitions; 
END




GO

/****** Object:  StoredProcedure [dbo].[sp_middletier_heartbeat_alert]    Script Date: 04/23/2015 11:14:11 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO




/*
exec sp_middletier_heartbeat_alert -5, 'palexander@csod.com'
*/
CREATE procedure [dbo].[sp_middletier_heartbeat_alert]
(
	@delay int = -60 --seconds
	,@recipients_in varchar(1000) = 'palexander@csod.com'
)
as
begin

--alert on heartbeat is delayed for current service
select e.Name, c.Name as 'Cluster', datediff(s, e.heartbeat, getutcdate()) as SecondsLapsed , e.Serving, e.Load , e.Version, e.heartbeat as LastHeartbeat, getutcdate() as collectiontime
into #tmp_hearbeat
from ces_master..middle_tier_endpoint e (nolock)
join ces_master..middle_tier_cluster c (nolock) on c.id = e.clusterid
where heartbeat < dateadd(second, -600, getutcdate())
and e.version = (
select max(version)
from ceS_master..middle_tier_endpoint e (nolock)
join ces_master..middle_tier_cluster c1 (nolock) on c1.id = e.clusterid
where c1.id = c.id
)
and c.GUID != '5C2EEDBF-A8D2-46BF-BC14-0028C0514308' -- eclude Page Rendering Service

--select * from #tmp_hearbeat

if (select COUNT(*) from #tmp_hearbeat) > 0
begin

DECLARE @tableHTML  NVARCHAR(MAX) ='...' , @subjectstring nvarchar(200)='...'


SET @tableHTML =
	N'<H1>Alert : Heartbeat delayed on Server '+@@SERVERNAME+' more than ('+convert(varchar,@delay)+') seconds</H1>' +
	N'<table border="1">' +
	N'<tr><th>Name</th>' +
	N'<th>Cluster</th><th>SecondsLapsed</th><th>Serving</th><th>Load</th><th>Version</th><th>LastHeartbeat(UTC)</th><th>CollectionTime(UTC)</th></tr>' +
	CAST ( ( SELECT td = Name,       '',
					td = Cluster,       '',
					td = SecondsLapsed,       '',
					td = Serving,       '',
					td = Load,       '',
					td = Version,       '',
					td = LastHeartbeat,       '',
					td = collectiontime
			  FROM #tmp_hearbeat
			  FOR XML PATH('tr'), TYPE 
	) AS NVARCHAR(MAX) ) +
	N'</table>' ;
	
	print @tableHTML
    
set @subjectstring = 'Alert : Heartbeat delayed on Server '+@@SERVERNAME 
print @subjectstring 


		EXEC msdb.dbo.sp_send_dbmail
			@profile_name = 'default',
			@recipients = @recipients_in, 
			@body = @tableHTML,
			@body_format = 'HTML' ,
			@subject = @subjectstring;
			
end

drop table #tmp_hearbeat

end





GO

/****** Object:  StoredProcedure [dbo].[sp_missing_indexes]    Script Date: 04/23/2015 11:14:11 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO





create procedure [dbo].[sp_missing_indexes]
as
begin

	SELECT 
	statement AS [database.scheme.table],
	column_id , column_name, column_usage, 
	migs.user_seeks, migs.user_scans, 
	migs.last_user_seek, migs.avg_total_user_cost,
	migs.avg_user_impact
	FROM sys.dm_db_missing_index_details AS mid
	CROSS APPLY sys.dm_db_missing_index_columns (mid.index_handle)
	INNER JOIN sys.dm_db_missing_index_groups AS mig 
	ON mig.index_handle = mid.index_handle
	INNER JOIN sys.dm_db_missing_index_group_stats  AS migs 
	ON mig.index_group_handle=migs.group_handle
	ORDER BY migs.avg_user_impact desc, mig.index_group_handle, mig.index_handle, column_id

end




GO

/****** Object:  StoredProcedure [dbo].[sp_missing_indexes2]    Script Date: 04/23/2015 11:14:11 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO





create procedure [dbo].[sp_missing_indexes2]
as
begin


	WITH XMLNAMESPACES  
	   (DEFAULT 'http://schemas.microsoft.com/sqlserver/2004/07/showplan') 
	    
	SELECT query_plan, 
		   n.value('(@StatementText)[1]', 'VARCHAR(4000)') AS sql_text, 
		   n.value('(//MissingIndexGroup/@Impact)[1]', 'FLOAT') AS impact, 
		   DB_ID(REPLACE(REPLACE(n.value('(//MissingIndex/@Database)[1]', 'VARCHAR(128)'),'[',''),']','')) AS database_id, 
		   OBJECT_ID(n.value('(//MissingIndex/@Database)[1]', 'VARCHAR(128)') + '.' + 
			   n.value('(//MissingIndex/@Schema)[1]', 'VARCHAR(128)') + '.' + 
			   n.value('(//MissingIndex/@Table)[1]', 'VARCHAR(128)')) AS OBJECT_ID, 
		   n.value('(//MissingIndex/@Database)[1]', 'VARCHAR(128)') + '.' + 
			   n.value('(//MissingIndex/@Schema)[1]', 'VARCHAR(128)') + '.' + 
			   n.value('(//MissingIndex/@Table)[1]', 'VARCHAR(128)')  
		   AS statement, 
		   (   SELECT DISTINCT c.value('(@Name)[1]', 'VARCHAR(128)') + ', ' 
			   FROM n.nodes('//ColumnGroup') AS t(cg) 
			   CROSS APPLY cg.nodes('Column') AS r(c) 
			   WHERE cg.value('(@Usage)[1]', 'VARCHAR(128)') = 'EQUALITY' 
			   FOR  XML PATH('') 
		   ) AS equality_columns, 
			(  SELECT DISTINCT c.value('(@Name)[1]', 'VARCHAR(128)') + ', ' 
			   FROM n.nodes('//ColumnGroup') AS t(cg) 
			   CROSS APPLY cg.nodes('Column') AS r(c) 
			   WHERE cg.value('(@Usage)[1]', 'VARCHAR(128)') = 'INEQUALITY' 
			   FOR  XML PATH('') 
		   ) AS inequality_columns, 
		   (   SELECT DISTINCT c.value('(@Name)[1]', 'VARCHAR(128)') + ', ' 
			   FROM n.nodes('//ColumnGroup') AS t(cg) 
			   CROSS APPLY cg.nodes('Column') AS r(c) 
			   WHERE cg.value('(@Usage)[1]', 'VARCHAR(128)') = 'INCLUDE' 
			   FOR  XML PATH('') 
		   ) AS include_columns 
	INTO #MissingIndexInfo 
	FROM  
	( 
	   SELECT query_plan 
	   FROM (    
			   SELECT DISTINCT plan_handle 
			   FROM sys.dm_exec_query_stats WITH(NOLOCK)  
			 ) AS qs 
		   OUTER APPLY sys.dm_exec_query_plan(qs.plan_handle) tp     
	   WHERE tp.query_plan.exist('//MissingIndex')=1 
	) AS tab (query_plan) 
	CROSS APPLY query_plan.nodes('//StmtSimple') AS q(n) 
	WHERE n.exist('QueryPlan/MissingIndexes') = 1 

	-- Trim trailing comma from lists 
	UPDATE #MissingIndexInfo 
	SET equality_columns = LEFT(equality_columns,LEN(equality_columns)-1), 
	   inequality_columns = LEFT(inequality_columns,LEN(inequality_columns)-1), 
	   include_columns = LEFT(include_columns,LEN(include_columns)-1) 
	    
	SELECT * 
	FROM #MissingIndexInfo 
	order by impact desc

	DROP TABLE #MissingIndexInfo

end




GO

/****** Object:  StoredProcedure [dbo].[sp_missing_indexes3]    Script Date: 04/23/2015 11:14:11 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO





create procedure [dbo].[sp_missing_indexes3]
as
begin

SELECT
  migs.avg_total_user_cost * (migs.avg_user_impact / 100.0) * (migs.user_seeks + migs.user_scans) AS improvement_measure,
  'CREATE INDEX [missing_index_' + CONVERT (varchar, mig.index_group_handle) + '_' + CONVERT (varchar, mid.index_handle)
  + '_' + LEFT (PARSENAME(mid.statement, 1), 32) + ']'
  + ' ON ' + mid.statement
  + ' (' + ISNULL (mid.equality_columns,'')
    + CASE WHEN mid.equality_columns IS NOT NULL AND mid.inequality_columns IS NOT NULL THEN ',' ELSE '' END
    + ISNULL (mid.inequality_columns, '')
  + ')'
  + ISNULL (' INCLUDE (' + mid.included_columns + ')', '') AS create_index_statement,
  migs.*, mid.database_id, mid.[object_id]
FROM sys.dm_db_missing_index_groups mig
INNER JOIN sys.dm_db_missing_index_group_stats migs ON migs.group_handle = mig.index_group_handle
INNER JOIN sys.dm_db_missing_index_details mid ON mig.index_handle = mid.index_handle
WHERE migs.avg_total_user_cost * (migs.avg_user_impact / 100.0) * (migs.user_seeks + migs.user_scans) > 10
ORDER BY migs.avg_total_user_cost * migs.avg_user_impact * (migs.user_seeks + migs.user_scans) DESC

end





GO

/****** Object:  StoredProcedure [dbo].[sp_orphan_users]    Script Date: 04/23/2015 11:14:11 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO




CREATE PROC [dbo].[sp_orphan_users]
as
BEGIN

	--DROP TABLE #Results
	CREATE TABLE #Results
	(
		[Database Name] sysname COLLATE Latin1_General_CI_AS, 
		[Orphaned User] sysname COLLATE Latin1_General_CI_AS
	)

	SET NOCOUNT ON	

	DECLARE @DBName sysname, @Qry nvarchar(4000)

	SET @Qry = ''
	SET @DBName = ''

	WHILE @DBName IS NOT NULL
	BEGIN
		SET @DBName = 
				(
					SELECT MIN(name) 
					FROM master..sysdatabases 
					WHERE 	name NOT IN 
						(
						 'master', 'model', 'tempdb', 'msdb', 
						 'distribution', 'pubs', 'northwind'
						)
						AND DATABASEPROPERTY(name, 'IsOffline') = 0 
						AND DATABASEPROPERTY(name, 'IsSuspect') = 0 
						AND name > @DBName
				)
		
		IF @DBName IS NULL BREAK

		SET @Qry = '	SELECT ''' + @DBName + ''' AS [Database Name], 
				CAST(name AS sysname) COLLATE Latin1_General_CI_AS  AS [Orphaned User]
				FROM ' + QUOTENAME(@DBName) + '..sysusers su
				WHERE su.islogin = 1
				AND su.name <> ''guest''
				AND NOT EXISTS
				(
					SELECT 1
					FROM master..syslogins sl
					WHERE su.sid = sl.sid
				)'

		INSERT INTO #Results EXEC (@Qry)
	END

	SELECT * 
	FROM #Results 
	ORDER BY [Database Name], [Orphaned User]

END



GO

/****** Object:  StoredProcedure [dbo].[sp_pagelatch]    Script Date: 04/23/2015 11:14:11 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO




CREATE procedure [dbo].[sp_pagelatch]
as
begin


Select session_id,
wait_type,
wait_duration_ms,
blocking_session_id,
resource_description,
ResourceType = Case
When Cast(Right(resource_description, Len(resource_description) - Charindex(':', resource_description, 3)) As Int) - 1 % 8088 = 0 Then 'Is PFS Page'
           When Cast(Right(resource_description, Len(resource_description) - Charindex(':', resource_description, 3)) As Int) - 2 % 511232 = 0 Then 'Is GAM Page'
           When Cast(Right(resource_description, Len(resource_description) - Charindex(':', resource_description, 3)) As Int) - 3 % 511232 = 0 Then 'Is SGAM Page'
           Else 'Is Not PFS, GAM, or SGAM page'
           End,
CollectionDate = Getdate()
From sys.dm_os_waiting_tasks
Where wait_type Like 'PAGE%LATCH_%' 
And resource_description Like '2:%'


end



GO

/****** Object:  StoredProcedure [dbo].[sp_pagelatch_alert]    Script Date: 04/23/2015 11:14:11 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO





CREATE procedure [dbo].[sp_pagelatch_alert]
(
	@alerttreshhold int = 30
)
as
begin

if(OBJECT_ID('tempdb..#tmp')>1)
	drop table #tmp
	
create table #tmp
(
lineid int identity(1,1),
session_id int,
wait_type varchar(100),
wait_duration_ms  varchar(100),
blocking_session_id varchar(100),
resource_description varchar(max),
ResourceType  varchar(100)
)

insert into #tmp (session_id ,wait_type ,wait_duration_ms  ,blocking_session_id ,resource_description ,ResourceType)
Select session_id,
wait_type,
wait_duration_ms,
blocking_session_id,
resource_description,
     ResourceType = Case
When Cast(Right(resource_description, Len(resource_description) - Charindex(':', resource_description, 3)) As Int) - 1 % 8088 = 0 Then 'Is PFS Page'
           When Cast(Right(resource_description, Len(resource_description) - Charindex(':', resource_description, 3)) As Int) - 2 % 511232 = 0 Then 'Is GAM Page'
           When Cast(Right(resource_description, Len(resource_description) - Charindex(':', resource_description, 3)) As Int) - 3 % 511232 = 0 Then 'Is SGAM Page'
           Else 'Is Not PFS, GAM, or SGAM page'
           End
From sys.dm_os_waiting_tasks
Where wait_type Like 'PAGE%LATCH_%' 
And resource_description Like '2:1:103%'

if (select COUNT(*) from #tmp) >= @alerttreshhold
begin

		DECLARE @tableHTML  NVARCHAR(MAX) , @subjectstring nvarchar(200);

		SET @tableHTML =
			N'<H1>PAGELATCH Issue on '+@@SERVERNAME+' </H1>' +
			N'<table border="1">' +
			N'<tr><th>Line #</th><th>Session ID</th><th>Wait Type</th>' +
			N'<th>Wait Duration</th><th>Blocking Session</th><th>Resource Type</th>' +
			N'<th>Resrouce Description</th></tr>' +
			CAST ( ( SELECT td = lineid,       '',
							td = session_id,       '',
							td = wait_type, '',
							td = wait_duration_ms, '',
							td = blocking_session_id, '',
							td = ResourceType, '',
							td = resource_description
					  FROM #tmp
					  FOR XML PATH('tr'), TYPE 
			) AS NVARCHAR(MAX) ) +
			N'</table>' ;
			
			print @tableHTML
		    
		set @subjectstring = 'PAGELATCH Issue on SQL Server '+@@SERVERNAME 
		EXEC msdb.dbo.sp_send_dbmail
			@profile_name = 'default',
			@recipients ='palexander@acheck.com;', 
			@body = @tableHTML,
			@body_format = 'HTML' ,
			@subject = @subjectstring;

end


end








GO

/****** Object:  StoredProcedure [dbo].[sp_recompile_stuck_procs]    Script Date: 04/23/2015 11:14:11 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO




/*
exec sp_who3
exec sp_recompile_stuck_procs 2
*/
CREATE PROCEDURE [dbo].[sp_recompile_stuck_procs]
(
@maxcount int = 10
)
AS
BEGIN
	SET NOCOUNT ON;


declare @datestr nvarchar(100), @sql nvarchar(4000), @tblname nvarchar(100)
--declare @maxcount int = 0
select @datestr = CONVERT(nvarchar(10),getdate(), 112)+'_'+CONVERT(nvarchar(10),datepart(hour,getdate()))+'_'+CONVERT(nvarchar(10),datepart(minute,getdate()))+'_'+CONVERT(nvarchar(10),datepart(SECOND,getdate()))
--select @datestr 
set @tblname = '__drop_who3_collection_1_minute_'+@datestr

set @sql = 'IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N''[dbo].['+@tblname+']'') AND type in (N''U''))
create table '+@tblname+'
(SPID bigint,Status varchar(100),Login varchar(100),Host varchar(100),BlkBy bigint, TempDBWait varchar(100),DBName varchar(100),CommandType varchar(100),
SQLStatement varchar(max),ObjectName varchar(100),ElapsedMS bigint,CPUTime bigint,IOReads bigint,IOWrites bigint,LastWaitType varchar(100),
StartTime datetime,Protocol varchar(100),ConnectionWrites bigint,ConnectionReads bigint,ClientAddress  varchar(100),Authentication  varchar(100), Collectiontime datetime)
'
--print @sql
exec sp_executesql @sql	

set @sql = 'insert into '+@tblname+'
exec sp_who3 '
--print @sql
exec sp_executesql @sql	

--set @sql = 'select dbname, objectname,login, host, count(*) as cc into '+@tblname+'_loop from '+@tblname+' where objectname is not null group by  dbname, objectname,login, host having count(*) > '+CONVERT(varchar, @maxcount)
set @sql = 'select dbname, objectname,login, host, count(*) as cc into '+@tblname+'_loop from '+@tblname+' where objectname is not null and host not like ''%PRD-MSQ%'' group by  dbname, objectname,login, host having count(*) > '+CONVERT(varchar, @maxcount)
--print @sql
exec sp_executesql @sql	

--set @sql = 'select * from '+@tblname
----print @sql
--exec sp_executesql @sql	

--set @sql = 'select * from '+@tblname+'_loop'
----print @sql
--exec sp_executesql @sql	


---------------------------------------------------------
--declare @tblname nvarchar(100) = '__drop_who3_collection_1_minute_20120917_13_37_16' , @sql nvarchar(1000)
declare @tbl table (db nvarchar(100) , sp nvarchar(100),login nvarchar(100), host nvarchar(100), cc int)
declare @db nvarchar(100) , @sp nvarchar(100),@login nvarchar(100), @host nvarchar(100)

set @sql = 'select dbname, objectname,login, host, cc From '+@tblname+'_loop'

insert into @tbl
exec sp_executesql @sql

declare tmp_cur cursor for 
select db, sp ,login,host From @tbl

open tmp_cur
Fetch next from tmp_cur into @db, @sp,@login,@host

while @@fetch_status = 0
begin
	--print  @db
	--print @sp
	set @sql = 'use [' +@db +']
	exec sp_recompile '+replace(@sp, 'dbo.','')

	print @sql
	exec sp_executesql @sql


Fetch next from tmp_cur into  @db, @sp,@login,@host
print '---'
end

close tmp_cur
deallocate tmp_cur

-----------------------------------
if (select COUNT(*) from @tbl) > 0
begin

DECLARE @tableHTML  NVARCHAR(MAX) ='...' , @subjectstring nvarchar(200)='...'

SET @tableHTML =
	N'<H1>Proc Re-compile on '+@@SERVERNAME+' </H1>' +
	N'<table border="1">' +
	N'<tr><th>Database</th>' +
	N'<th>Proc</th><th>Login</th><th>Host</th><th>Counts</th></tr>' +
	CAST ( ( SELECT td = db,       '',
					td = sp,       '',
					td = login,       '',
					td = host,       '',
					td = cc
			  FROM @tbl
			  FOR XML PATH('tr'), TYPE 
	) AS NVARCHAR(MAX) ) +
	N'</table>' ;
	
	print @tableHTML
    
set @subjectstring = 'Alert : Proc Re-compile on SQL Server '+@@SERVERNAME 
print @subjectstring 

		EXEC msdb.dbo.sp_send_dbmail
			@profile_name = 'default',
			@recipients ='palexander@csod.com;DEFCON5@csod.com', 
			@body = @tableHTML,
			@body_format = 'HTML' ,
			@subject = @subjectstring;
			
end

---------------------------------------

set @sql = 'drop table '+@tblname+'_loop'
--print @sql
exec sp_executesql @sql	



set @sql = 'drop table '+@tblname
--print @sql
exec sp_executesql @sql	



END




GO

/****** Object:  StoredProcedure [dbo].[sp_security_report]    Script Date: 04/23/2015 11:14:12 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO




/*
exec sp_security_report
*/
create procedure [dbo].[sp_security_report]
as
begin

SET nocount ON 

-- Get all roles 
CREATE TABLE #temp_srvrole 
(ServerRole VARCHAR(128), Description VARCHAR(128)) 
INSERT INTO #temp_srvrole 
EXEC sp_helpsrvrole 

-- sp_help syslogins 
CREATE TABLE #temp_memberrole 
(ServerRole VARCHAR(128), 
MemberName VARCHAR(265), 
MemberSID VARCHAR(300)) 

DECLARE @ServerRole VARCHAR(128) 

DECLARE srv_role CURSOR FAST_FORWARD FOR 
SELECT ServerRole FROM #temp_srvrole 
OPEN srv_role 
FETCH NEXT FROM srv_role INTO @ServerRole 

WHILE @@FETCH_STATUS = 0 
BEGIN 
INSERT INTO #temp_memberrole 
EXEC sp_helpsrvrolemember @ServerRole 
FETCH NEXT FROM srv_role INTO @ServerRole 
END 

CLOSE srv_role 
DEALLOCATE srv_role 

SELECT ServerRole, MemberName FROM #temp_memberrole 

-- IF BUILTIN\Administrators is exist and sysadmin 
IF EXISTS(SELECT *FROM #temp_memberrole 
WHERE MemberName = 'BUILTIN\Administrators' 
AND ServerRole = 'sysadmin' ) 
BEGIN 
CREATE TABLE #temp_localadmin (output VARCHAR(8000)) 
INSERT INTO #temp_localadmin 
EXEC xp_cmdshell 'net localgroup administrators' 

SELECT output AS local_administrator 
FROM #temp_localadmin 
WHERE output LIKE '%\%' 
DROP TABLE #temp_localadmin 
END 

DROP TABLE #temp_srvrole 
DROP TABLE #temp_memberrole 

-- Get individual Logins 
SELECT name, 'Individual NT Login' LoginType 
FROM syslogins 
WHERE isntgroup = 0 AND isntname = 1 
UNION 
SELECT name, 'Individual SQL Login' LoginType 
FROM syslogins 
WHERE isntgroup = 0 AND isntname = 0 
UNION ALL 
-- Get Group logins 
SELECT name,'NT Group Login' LoginType 
FROM syslogins 
WHERE isntgroup = 1 


-- get group list 
-- EXEC xp_cmdshell 'net group "AnalyticsDev" /domain' 
CREATE TABLE #temp_groupadmin 
(output VARCHAR(8000)) 
CREATE TABLE #temp_groupadmin2 
(groupName VARCHAR(256), groupMember VARCHAR(1000)) 
DECLARE @grpname VARCHAR(128) 
DECLARE @sqlcmd VARCHAR(1000) 

DECLARE grp_role CURSOR FAST_FORWARD FOR 
SELECT REPLACE(name,'US\','') 
FROM syslogins 
WHERE isntgroup = 1 AND name LIKE 'US\%' 

OPEN grp_role 
FETCH NEXT FROM grp_role INTO @grpname 

WHILE @@FETCH_STATUS = 0 
BEGIN 

SET @sqlcmd = 'net group "' + @grpname + '" /domain' 
TRUNCATE TABLE #temp_groupadmin 

PRINT @sqlcmd 
INSERT INTO #temp_groupadmin 
EXEC xp_cmdshell @sqlcmd 

SET ROWCOUNT 8 
DELETE FROM #temp_groupadmin 

SET ROWCOUNT 0 

INSERT INTO #temp_groupadmin2 
SELECT @grpname, output FROM #temp_groupadmin 
WHERE output NOT LIKE ('%The command completed successfully%') 

FETCH NEXT FROM grp_role INTO @grpname 
END 


CLOSE grp_role 
DEALLOCATE grp_role 

SELECT * FROM #temp_groupadmin2 

DROP TABLE #temp_groupadmin 
DROP TABLE #temp_groupadmin2 



PRINT 'EXEC sp_validatelogins ' 
PRINT '----------------------------------------------' 
EXEC sp_validatelogins 
PRINT '' 


-- Get all the Database Rols for that specIFic members 
CREATE TABLE #temp_rolemember 
(DbRole VARCHAR(128),MemberName VARCHAR(128),MemberSID VARCHAR(1000)) 
CREATE TABLE #temp_rolemember_final 
(DbName VARCHAR(100), DbRole VARCHAR(128),MemberName VARCHAR(128)) 

DECLARE @dbname VARCHAR(128) 
DECLARE @sqlcmd2 VARCHAR(1000) 

DECLARE grp_role CURSOR FOR 
SELECT name FROM sysdatabases 
WHERE name NOT IN ('tempdb') 
AND DATABASEPROPERTYEX(name, 'Status') = 'ONLINE' 


OPEN grp_role 
FETCH NEXT FROM grp_role INTO @dbname 

WHILE @@FETCH_STATUS = 0 
BEGIN 

TRUNCATE TABLE #temp_rolemember 
SET @sqlcmd2 = 'EXEC [' + @dbname + ']..sp_helprolemember' 

PRINT @sqlcmd2 
INSERT INTO #temp_rolemember 
EXECUTE(@sqlcmd2) 

INSERT INTO #temp_rolemember_final 
SELECT @dbname AS DbName, DbRole, MemberName 
FROM #temp_rolemember 

FETCH NEXT FROM grp_role INTO @dbname 
END 


CLOSE grp_role 
DEALLOCATE grp_role 

SELECT * FROM #temp_rolemember_final 

DROP TABLE #temp_rolemember 
DROP TABLE #temp_rolemember_final

end




GO

/****** Object:  StoredProcedure [dbo].[sp_server_failover_alert]    Script Date: 04/23/2015 11:14:12 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO




/*
exec sp_server_failover_alert
*/
CREATE procedure [dbo].[sp_server_failover_alert]
as
begin

--SELECT SERVERPROPERTY('ComputerNamePhysicalNetBIOS') AS [CurrentNodeName] 

----Find SQL Server Cluster Nodes
--SELECT * FROM fn_virtualservernodes() 
--SELECT * FROM sys.dm_os_cluster_nodes 

----Find SQL Server Cluster Shared Drives
--SELECT * FROM fn_servershareddrives() 
--SELECT * FROM sys.dm_io_cluster_shared_drives

if (SELECT SERVERPROPERTY('ComputerNamePhysicalNetBIOS') AS [CurrentNodeName] ) != 'RIV-SQL-02A'
begin


	DECLARE @tableHTML  NVARCHAR(4000) , @subjectstring nvarchar(200), @currentnode nvarchar(100)
	SELECT @currentnode = convert(nvarchar,SERVERPROPERTY('ComputerNamePhysicalNetBIOS'))
	set @tableHTML = '<H1>SQL Server running on second node.</H1> Need immediate Attention.</br>The current node: '+@currentnode
	print @tableHTML

	set @subjectstring = 'SQL Server Failover Notice '+@@SERVERNAME 
	EXEC msdb.dbo.sp_send_dbmail
		--@profile_name = 'default',
		@recipients = 'patrickalexander@hotmail.com;ACheckDB@acheckamerica.com;kcinty@acheckamerica.com;qkong@acheckamerica.com',
		--@recipients ='patrickalexander@hotmail.com;', 
		@body = @tableHTML,
		@body_format = 'HTML' ,
		@subject = @subjectstring;	
end

end

GO

/****** Object:  StoredProcedure [dbo].[sp_slow_running_qureies]    Script Date: 04/23/2015 11:14:12 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO





create procedure [dbo].[sp_slow_running_qureies]
as
begin

	SELECT DISTINCT TOP 100
	t.TEXT QueryName,
	s.execution_count AS ExecutionCount,
	s.max_elapsed_time AS MaxElapsedTime,
	ISNULL(s.total_elapsed_time / 1000 / NULLIF(s.execution_count, 0), 0) AS AvgElapsedTime,
	s.creation_time AS LogCreatedOn,
	ISNULL(s.execution_count / 1000 / NULLIF(DATEDIFF(s, s.creation_time, GETDATE()), 0), 0) AS FrequencyPerSec
	FROM sys.dm_exec_query_stats s
	CROSS APPLY sys.dm_exec_sql_text( s.sql_handle ) t
	WHERE s.execution_count > 1
	ORDER BY AvgElapsedTime desc , s.max_elapsed_time DESC, ExecutionCount DESC;

end



GO

/****** Object:  StoredProcedure [dbo].[sp_tempdb_contention]    Script Date: 04/23/2015 11:14:12 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO





Create procedure [dbo].[sp_tempdb_contention]
as
begin

SELECT	session_id,
wait_type,
wait_duration_ms,
blocking_session_id,
resource_description,
ResourceType = CASE
                WHEN Cast(RIGHT(resource_description, Len(resource_description) - Charindex(':', resource_description, LEN(resource_description)-CHARINDEX(':', REVERSE(resource_description), 1))) AS NVARCHAR) - 1 % 8088 = 0 THEN 'Is PFS Page'
                WHEN Cast(RIGHT(resource_description, Len(resource_description) - Charindex(':', resource_description, LEN(resource_description)-CHARINDEX(':', REVERSE(resource_description), 1))) AS NVARCHAR) - 2 % 511232 = 0 THEN 'Is GAM Page'
                WHEN Cast(RIGHT(resource_description, Len(resource_description) - Charindex(':', resource_description, LEN(resource_description)-CHARINDEX(':', REVERSE(resource_description), 1))) AS NVARCHAR) - 3 % 511232 = 0 THEN 'Is SGAM Page'
                ELSE 'Is Not PFS, GAM, or SGAM page'
              END
FROM	sys.dm_os_waiting_tasks
WHERE	wait_type LIKE 'PAGE%LATCH_%'
AND resource_description LIKE '2:%'

end




GO

/****** Object:  StoredProcedure [dbo].[sp_tempdb_sessions]    Script Date: 04/23/2015 11:14:12 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO





CREATE procedure [dbo].[sp_tempdb_sessions]
as
begin

SELECT
  su.session_id AS [SESSION ID]
  ,DB_NAME(su.database_id) AS [DATABASE Name]
  ,HOST_NAME AS [System Name]
  ,program_name AS [Program Name]
  ,es.login_name AS [USER Name]
  ,es.status
  ,es.cpu_time AS [CPU TIME (in milisec)]
  ,total_scheduled_time AS [Total Scheduled TIME (in milisec)]
  ,es.total_elapsed_time AS    [Elapsed TIME (in milisec)]
  ,(es.memory_usage * 8)      AS [Memory USAGE (in KB)]
  ,(su.user_objects_alloc_page_count * 8) AS [SPACE Allocated FOR USER Objects (in KB)]
  ,(su.user_objects_dealloc_page_count * 8) AS [SPACE Deallocated FOR USER Objects (in KB)]
  ,(su.internal_objects_alloc_page_count * 8) AS [SPACE Allocated FOR Internal Objects (in KB)]
  ,(su.internal_objects_dealloc_page_count * 8) AS [SPACE Deallocated FOR Internal Objects (in KB)]
  ,CASE es.is_user_process
             WHEN 1      THEN 'user session'
             WHEN 0      THEN 'system session'
  END         AS [SESSION Type], es.row_count AS [ROW COUNT]
  ,SQLStatement       = SUBSTRING   
        (    
            qt.text,    
            er.statement_start_offset/2,    
            (CASE WHEN er.statement_end_offset = -1    
                THEN LEN(CONVERT(nvarchar(MAX), qt.text)) * 2    
                ELSE er.statement_end_offset    
                END - er.statement_start_offset)/2    
        )    
  ,ObjectName         = OBJECT_SCHEMA_NAME(qt.objectid,dbid) + '.' + OBJECT_NAME(qt.objectid, qt.dbid)  					
  
FROM sys.dm_db_session_space_usage su
INNER join sys.dm_exec_sessions es ON su.session_id = es.session_id
INNER JOiN sys.dm_exec_requests er on er.session_id = su.session_id
OUTER APPLY sys.dm_exec_sql_text(er.sql_handle) as qt    


order by [SPACE Allocated FOR USER Objects (in KB)] desc

end




GO

/****** Object:  StoredProcedure [dbo].[sp_tempdb_sessions_alert]    Script Date: 04/23/2015 11:14:12 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO





CREATE Procedure [dbo].[sp_tempdb_sessions_alert]
as
begin

DECLARE @tableHTML  NVARCHAR(MAX) , @subjectstring nvarchar(200), @cc int = 0;

select @cc = COUNT(*)
FROM sys.dm_db_session_space_usage su
INNER join sys.dm_exec_sessions es ON su.session_id = es.session_id
INNER JOiN sys.dm_exec_requests er on er.session_id = su.session_id
OUTER APPLY sys.dm_exec_sql_text(er.sql_handle) as qt  
where  
es.status = 'sleeping'
and es.login_name not like '%PRDIU%' 
and es.login_name not like '%PRDSU%' 
and es.login_name not like '%PRODTCS%' 
and es.login_name not like '%CLUSTER%' 
and es.login_name not like '%SQLServerAgent%'
and es.login_name not like '%IUSR%'
and es.login_name not like '%SUSR%'
and es.login_name not in ('sa','NT AUTHORITY\SYSTEM')

if( @cc > 0)
begin

SET @tableHTML =
	N'<H1>Open Sessions on TempDB on SQL Server '+@@SERVERNAME+' </H1>' +
	N'<table border="1">' +
	N'<tr><th>Session ID</th><th>Host Name</th><th>Login Name</th><th>CPU Time (in milisec)</th><th>Total Elapsed Time(in milisec)</th><th>SQL Statement</th><th>Object</th></tr>' +
	CAST ( (SELECT td = es.session_id,'',
					td = es.HOST_NAME, '',
					td = es.login_name,'',
					td = es.cpu_time, '',
					td = es.total_elapsed_time,'',
    td = SUBSTRING   
        (    
            qt.text,    
            er.statement_start_offset/2,    
            (CASE WHEN er.statement_end_offset = -1    
                THEN LEN(CONVERT(nvarchar(MAX), qt.text)) * 2    
                ELSE er.statement_end_offset    
                END - er.statement_start_offset)/2    
        ),  '',  
    td = OBJECT_SCHEMA_NAME(qt.objectid,dbid) + '.' + OBJECT_NAME(qt.objectid, qt.dbid)  					
FROM sys.dm_db_session_space_usage su
INNER join sys.dm_exec_sessions es ON su.session_id = es.session_id
INNER JOiN sys.dm_exec_requests er on er.session_id = su.session_id
OUTER APPLY sys.dm_exec_sql_text(er.sql_handle) as qt  
where  
es.status = 'sleeping'
and es.login_name not like '%PRDIU%' 
and es.login_name not like '%PRDSU%' 
and es.login_name not like '%PRODTCS%' 
and es.login_name not like '%CLUSTER%' 
and es.login_name not like '%SQLServerAgent%'
and es.login_name not like '%IUSR%'
and es.login_name not like '%SUSR%'
and es.login_name not in ('sa','NT AUTHORITY\SYSTEM')

			  FOR XML PATH('tr'), TYPE 
	) AS NVARCHAR(MAX) ) +
	N'</table>' ;
	
print @tableHTML

set @subjectstring = 'Open Sessions on TempDB on SQL Server '+@@SERVERNAME 
EXEC msdb.dbo.sp_send_dbmail
	@profile_name = 'default',
	@recipients ='palexander@csod.com;jferris@csod.com;DEFCON4@csod.com', 
	@body = @tableHTML,
	@body_format = 'HTML' ,
	@subject = @subjectstring;

end			
else
begin
	print 'nothing to report'
	/*
	select *
	FROM sys.dm_db_session_space_usage su
	INNER join sys.dm_exec_sessions es ON su.session_id = es.session_id
	INNER JOiN sys.dm_exec_requests er on er.session_id = su.session_id
	OUTER APPLY sys.dm_exec_sql_text(er.sql_handle) as qt  
	where  
	es.status = 'sleeping'
	and es.login_name not in ('sa','NT AUTHORITY\SYSTEM')
	*/
end
--exec sp_tempdb_sessions

end




GO

/****** Object:  StoredProcedure [dbo].[sp_wait_alert]    Script Date: 04/23/2015 11:14:12 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO




/*
exec sp_wait_alert 1000
*/
CREATE proc [dbo].[sp_wait_alert]
(
	@waittime_ms int = 1000 --milliseconds
)
as
begin

select top 10 
spid, waittime as waittime_ms, db_name(dbid) as dbname, cpu, physical_io, login_time, last_batch, hostname, program_name, cmd, nt_domain, nt_username, getdate() as collectiontime
into #tmp
from master.sys.sysprocesses (nolock)
where spid > 50 and loginame not in ('sa') and waittime > @waittime_ms
order by waittime desc, physical_io desc, cpu desc


if (select COUNT(*) from #tmp) > 0
begin
	DECLARE @tableHTML  NVARCHAR(MAX) , @subjectstring nvarchar(200);
	select * from #tmp

	SET @tableHTML =
		N'<H1>Waittimes on '+@@SERVERNAME+' </H1>' +
		N'<table border="1">' +
		N'<tr><th>Session</th>' +
		N'<th>Waittime(ms)</th>' +
		N'<th>DB</th>' +
		N'<th>CPU</th>' +
		N'<th>IO</th>' +
		N'<th>Login Time</th>' +
		N'<th>Last Batch Time</th>' +
		N'<th>Hostname</th>' +
		N'<th>Programname</th>' +
		N'<th>Command</th>' +
		N'<th>Domain</th>' +
		N'<th>Username</th>' +
		N'<th>CollectionTime</th></tr>' +
		CAST ( ( SELECT td = spid,       '',
						td = waittime_ms, '',
						td = dbname, '',
						td = cpu, '',
						td = physical_io, '',
						td = login_time, '',
						td = last_batch, '',
						td = hostname, '',
						td = program_name, '',
						td = cmd, '',
						td = nt_domain, '',
						td = nt_username, '',
						td = collectiontime
				  FROM #tmp
				  FOR XML PATH('tr'), TYPE 
		) AS NVARCHAR(MAX) ) +
		N'</table>' ;
		
		print @tableHTML	

		set @subjectstring = 'Waittimes on SQL Server '+@@SERVERNAME 
		EXEC msdb.dbo.sp_send_dbmail
			@profile_name = 'default',
			--@recipients ='palexander@csod.com;jferris@csod.com;DEFCON5@csod.com', 
			@recipients ='palexander@csod.com;DEFCON5@csod.com', 
			@body = @tableHTML,
			@body_format = 'HTML' ,
			@subject = @subjectstring;


end

drop table #tmp
/*
select top 10 *
from master.sys.sysprocesses (nolock)
where spid > 50 and loginame not in ('sa')
order by waittime desc, physical_io desc, cpu desc

select top 10 
spid, waittime as waittime_ms, db_name(dbid) as dbname, cpu, physical_io, login_time, last_batch, hostname, program_name, cmd, nt_domain, nt_username, getdate() as collectiontime
from master.sys.sysprocesses (nolock)
where spid > 50 and loginame not in ('sa') and waittime > 500
order by waittime desc, physical_io desc, cpu desc

*/

end



GO

/****** Object:  StoredProcedure [dbo].[sp_who3]    Script Date: 04/23/2015 11:14:12 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO




CREATE PROCEDURE [dbo].[sp_who3]
(    
    @SessionID int = NULL   
)    
AS
BEGIN   
  
SELECT
    SPID                = er.session_id    
    ,Status             = ses.status    
    ,[Login]            = ses.login_name    
    ,Host               = ses.host_name    
    ,BlkBy              = er.blocking_session_id
    ,TempDBWait			= wait.resource_description
    ,DBName             = DB_Name(er.database_id)    
    ,CommandType        = er.command    
    ,SQLStatement       = SUBSTRING   
        (    
            qt.text,    
            er.statement_start_offset/2,    
            (CASE WHEN er.statement_end_offset = -1    
                THEN LEN(CONVERT(nvarchar(MAX), qt.text)) * 2    
                ELSE er.statement_end_offset    
                END - er.statement_start_offset)/2    
        )    
    ,ObjectName         = OBJECT_SCHEMA_NAME(qt.objectid,dbid) + '.' + OBJECT_NAME(qt.objectid, qt.dbid)    
    ,ElapsedMS          = er.total_elapsed_time    
    ,CPUTime            = er.cpu_time    
    ,IOReads            = er.logical_reads + er.reads    
    ,IOWrites           = er.writes    
    ,LastWaitType       = er.last_wait_type    
    ,StartTime          = er.start_time    
    ,Protocol           = con.net_transport    
    ,ConnectionWrites   = con.num_writes    
    ,ConnectionReads    = con.num_reads    
    ,ClientAddress      = con.client_net_address    
    ,Authentication     = con.auth_scheme
    ,CollectionTime		= GETDATE()   
FROM sys.dm_exec_requests er    
LEFT JOIN sys.dm_exec_sessions ses    
ON ses.session_id = er.session_id    
LEFT JOIN sys.dm_exec_connections con    
ON con.session_id = ses.session_id
LEFT JOIN sys.dm_os_waiting_tasks wait
ON er.session_id = wait.session_id
AND wait.wait_type like 'PAGE%LATCH_%' AND wait.resource_description like '2:%'
OUTER APPLY sys.dm_exec_sql_text(er.sql_handle) as qt    
WHERE er.session_id > 50    
    AND (@SessionID IS NULL OR er.session_id = @SessionID)
    AND er.session_id <> @@SPID   
ORDER BY   
    er.blocking_session_id DESC   
    ,er.session_id    
END



GO

/****** Object:  StoredProcedure [dbo].[sp_WhoIsActive]    Script Date: 04/23/2015 11:14:12 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO





/*********************************************************************************************
Who Is Active? v11.11 (2012-03-22)
(C) 2007-2012, Adam Machanic

Feedback: mailto:amachanic@gmail.com
Updates: http://sqlblog.com/blogs/adam_machanic/archive/tags/who+is+active/default.aspx
"Beta" Builds: http://sqlblog.com/files/folders/beta/tags/who+is+active/default.aspx

Donate! Support this project: http://tinyurl.com/WhoIsActiveDonate

License: 
	Who is Active? is free to download and use for personal, educational, and internal 
	corporate purposes, provided that this header is preserved. Redistribution or sale 
	of Who is Active?, in whole or in part, is prohibited without the author's express 
	written consent.
*********************************************************************************************/
CREATE PROC [dbo].[sp_WhoIsActive]
(
--~
	--Filters--Both inclusive and exclusive
	--Set either filter to '' to disable
	--Valid filter types are: session, program, database, login, and host
	--Session is a session ID, and either 0 or '' can be used to indicate "all" sessions
	--All other filter types support % or _ as wildcards
	@filter sysname = '',
	@filter_type VARCHAR(10) = 'session',
	@not_filter sysname = '',
	@not_filter_type VARCHAR(10) = 'session',

	--Retrieve data about the calling session?
	@show_own_spid BIT = 0,

	--Retrieve data about system sessions?
	@show_system_spids BIT = 0,

	--Controls how sleeping SPIDs are handled, based on the idea of levels of interest
	--0 does not pull any sleeping SPIDs
	--1 pulls only those sleeping SPIDs that also have an open transaction
	--2 pulls all sleeping SPIDs
	@show_sleeping_spids TINYINT = 1,

	--If 1, gets the full stored procedure or running batch, when available
	--If 0, gets only the actual statement that is currently running in the batch or procedure
	@get_full_inner_text BIT = 0,

	--Get associated query plans for running tasks, if available
	--If @get_plans = 1, gets the plan based on the request's statement offset
	--If @get_plans = 2, gets the entire plan based on the request's plan_handle
	@get_plans TINYINT = 0,

	--Get the associated outer ad hoc query or stored procedure call, if available
	@get_outer_command BIT = 0,

	--Enables pulling transaction log write info and transaction duration
	@get_transaction_info BIT = 0,

	--Get information on active tasks, based on three interest levels
	--Level 0 does not pull any task-related information
	--Level 1 is a lightweight mode that pulls the top non-CXPACKET wait, giving preference to blockers
	--Level 2 pulls all available task-based metrics, including: 
	--number of active tasks, current wait stats, physical I/O, context switches, and blocker information
	@get_task_info TINYINT = 1,

	--Gets associated locks for each request, aggregated in an XML format
	@get_locks BIT = 0,

	--Get average time for past runs of an active query
	--(based on the combination of plan handle, sql handle, and offset)
	@get_avg_time BIT = 0,

	--Get additional non-performance-related information about the session or request
	--text_size, language, date_format, date_first, quoted_identifier, arithabort, ansi_null_dflt_on, 
	--ansi_defaults, ansi_warnings, ansi_padding, ansi_nulls, concat_null_yields_null, 
	--transaction_isolation_level, lock_timeout, deadlock_priority, row_count, command_type
	--
	--If a SQL Agent job is running, an subnode called agent_info will be populated with some or all of
	--the following: job_id, job_name, step_id, step_name, msdb_query_error (in the event of an error)
	--
	--If @get_task_info is set to 2 and a lock wait is detected, a subnode called block_info will be
	--populated with some or all of the following: lock_type, database_name, object_id, file_id, hobt_id, 
	--applock_hash, metadata_resource, metadata_class_id, object_name, schema_name
	@get_additional_info BIT = 0,

	--Walk the blocking chain and count the number of 
	--total SPIDs blocked all the way down by a given session
	--Also enables task_info Level 1, if @get_task_info is set to 0
	@find_block_leaders BIT = 0,

	--Pull deltas on various metrics
	--Interval in seconds to wait before doing the second data pull
	@delta_interval TINYINT = 0,

	--List of desired output columns, in desired order
	--Note that the final output will be the intersection of all enabled features and all 
	--columns in the list. Therefore, only columns associated with enabled features will 
	--actually appear in the output. Likewise, removing columns from this list may effectively
	--disable features, even if they are turned on
	--
	--Each element in this list must be one of the valid output column names. Names must be
	--delimited by square brackets. White space, formatting, and additional characters are
	--allowed, as long as the list contains exact matches of delimited valid column names.
	@output_column_list VARCHAR(8000) = '[dd%][session_id][sql_text][sql_command][login_name][wait_info][tasks][tran_log%][cpu%][temp%][block%][reads%][writes%][context%][physical%][query_plan][locks][%]',

	--Column(s) by which to sort output, optionally with sort directions. 
		--Valid column choices:
		--session_id, physical_io, reads, physical_reads, writes, tempdb_allocations,
		--tempdb_current, CPU, context_switches, used_memory, physical_io_delta, 
		--reads_delta, physical_reads_delta, writes_delta, tempdb_allocations_delta, 
		--tempdb_current_delta, CPU_delta, context_switches_delta, used_memory_delta, 
		--tasks, tran_start_time, open_tran_count, blocking_session_id, blocked_session_count,
		--percent_complete, host_name, login_name, database_name, start_time, login_time
		--
		--Note that column names in the list must be bracket-delimited. Commas and/or white
		--space are not required. 
	@sort_order VARCHAR(500) = '[start_time] ASC',

	--Formats some of the output columns in a more "human readable" form
	--0 disables outfput format
	--1 formats the output for variable-width fonts
	--2 formats the output for fixed-width fonts
	@format_output TINYINT = 1,

	--If set to a non-blank value, the script will attempt to insert into the specified 
	--destination table. Please note that the script will not verify that the table exists, 
	--or that it has the correct schema, before doing the insert.
	--Table can be specified in one, two, or three-part format
	@destination_table VARCHAR(4000) = '',

	--If set to 1, no data collection will happen and no result set will be returned; instead,
	--a CREATE TABLE statement will be returned via the @schema parameter, which will match 
	--the schema of the result set that would be returned by using the same collection of the
	--rest of the parameters. The CREATE TABLE statement will have a placeholder token of 
	--<table_name> in place of an actual table name.
	@return_schema BIT = 0,
	@schema VARCHAR(MAX) = NULL OUTPUT,

	--Help! What do I do?
	@help BIT = 0
--~
)
/*
OUTPUT COLUMNS
--------------
Formatted/Non:	[session_id] [smallint] NOT NULL
	Session ID (a.k.a. SPID)

Formatted:		[dd hh:mm:ss.mss] [varchar](15) NULL
Non-Formatted:	<not returned>
	For an active request, time the query has been running
	For a sleeping session, time since the last batch completed

Formatted:		[dd hh:mm:ss.mss (avg)] [varchar](15) NULL
Non-Formatted:	[avg_elapsed_time] [int] NULL
	(Requires @get_avg_time option)
	How much time has the active portion of the query taken in the past, on average?

Formatted:		[physical_io] [varchar](30) NULL
Non-Formatted:	[physical_io] [bigint] NULL
	Shows the number of physical I/Os, for active requests

Formatted:		[reads] [varchar](30) NULL
Non-Formatted:	[reads] [bigint] NULL
	For an active request, number of reads done for the current query
	For a sleeping session, total number of reads done over the lifetime of the session

Formatted:		[physical_reads] [varchar](30) NULL
Non-Formatted:	[physical_reads] [bigint] NULL
	For an active request, number of physical reads done for the current query
	For a sleeping session, total number of physical reads done over the lifetime of the session

Formatted:		[writes] [varchar](30) NULL
Non-Formatted:	[writes] [bigint] NULL
	For an active request, number of writes done for the current query
	For a sleeping session, total number of writes done over the lifetime of the session

Formatted:		[tempdb_allocations] [varchar](30) NULL
Non-Formatted:	[tempdb_allocations] [bigint] NULL
	For an active request, number of TempDB writes done for the current query
	For a sleeping session, total number of TempDB writes done over the lifetime of the session

Formatted:		[tempdb_current] [varchar](30) NULL
Non-Formatted:	[tempdb_current] [bigint] NULL
	For an active request, number of TempDB pages currently allocated for the query
	For a sleeping session, number of TempDB pages currently allocated for the session

Formatted:		[CPU] [varchar](30) NULL
Non-Formatted:	[CPU] [int] NULL
	For an active request, total CPU time consumed by the current query
	For a sleeping session, total CPU time consumed over the lifetime of the session

Formatted:		[context_switches] [varchar](30) NULL
Non-Formatted:	[context_switches] [bigint] NULL
	Shows the number of context switches, for active requests

Formatted:		[used_memory] [varchar](30) NOT NULL
Non-Formatted:	[used_memory] [bigint] NOT NULL
	For an active request, total memory consumption for the current query
	For a sleeping session, total current memory consumption

Formatted:		[physical_io_delta] [varchar](30) NULL
Non-Formatted:	[physical_io_delta] [bigint] NULL
	(Requires @delta_interval option)
	Difference between the number of physical I/Os reported on the first and second collections. 
	If the request started after the first collection, the value will be NULL

Formatted:		[reads_delta] [varchar](30) NULL
Non-Formatted:	[reads_delta] [bigint] NULL
	(Requires @delta_interval option)
	Difference between the number of reads reported on the first and second collections. 
	If the request started after the first collection, the value will be NULL

Formatted:		[physical_reads_delta] [varchar](30) NULL
Non-Formatted:	[physical_reads_delta] [bigint] NULL
	(Requires @delta_interval option)
	Difference between the number of physical reads reported on the first and second collections. 
	If the request started after the first collection, the value will be NULL

Formatted:		[writes_delta] [varchar](30) NULL
Non-Formatted:	[writes_delta] [bigint] NULL
	(Requires @delta_interval option)
	Difference between the number of writes reported on the first and second collections. 
	If the request started after the first collection, the value will be NULL

Formatted:		[tempdb_allocations_delta] [varchar](30) NULL
Non-Formatted:	[tempdb_allocations_delta] [bigint] NULL
	(Requires @delta_interval option)
	Difference between the number of TempDB writes reported on the first and second collections. 
	If the request started after the first collection, the value will be NULL

Formatted:		[tempdb_current_delta] [varchar](30) NULL
Non-Formatted:	[tempdb_current_delta] [bigint] NULL
	(Requires @delta_interval option)
	Difference between the number of allocated TempDB pages reported on the first and second 
	collections. If the request started after the first collection, the value will be NULL

Formatted:		[CPU_delta] [varchar](30) NULL
Non-Formatted:	[CPU_delta] [int] NULL
	(Requires @delta_interval option)
	Difference between the CPU time reported on the first and second collections. 
	If the request started after the first collection, the value will be NULL

Formatted:		[context_switches_delta] [varchar](30) NULL
Non-Formatted:	[context_switches_delta] [bigint] NULL
	(Requires @delta_interval option)
	Difference between the context switches count reported on the first and second collections
	If the request started after the first collection, the value will be NULL

Formatted:		[used_memory_delta] [varchar](30) NULL
Non-Formatted:	[used_memory_delta] [bigint] NULL
	Difference between the memory usage reported on the first and second collections
	If the request started after the first collection, the value will be NULL

Formatted:		[tasks] [varchar](30) NULL
Non-Formatted:	[tasks] [smallint] NULL
	Number of worker tasks currently allocated, for active requests

Formatted/Non:	[status] [varchar](30) NOT NULL
	Activity status for the session (running, sleeping, etc)

Formatted/Non:	[wait_info] [nvarchar](4000) NULL
	Aggregates wait information, in the following format:
		(Ax: Bms/Cms/Dms)E
	A is the number of waiting tasks currently waiting on resource type E. B/C/D are wait
	times, in milliseconds. If only one thread is waiting, its wait time will be shown as B.
	If two tasks are waiting, each of their wait times will be shown (B/C). If three or more 
	tasks are waiting, the minimum, average, and maximum wait times will be shown (B/C/D).
	If wait type E is a page latch wait and the page is of a "special" type (e.g. PFS, GAM, SGAM), 
	the page type will be identified.
	If wait type E is CXPACKET, the nodeId from the query plan will be identified

Formatted/Non:	[locks] [xml] NULL
	(Requires @get_locks option)
	Aggregates lock information, in XML format.
	The lock XML includes the lock mode, locked object, and aggregates the number of requests. 
	Attempts are made to identify locked objects by name

Formatted/Non:	[tran_start_time] [datetime] NULL
	(Requires @get_transaction_info option)
	Date and time that the first transaction opened by a session caused a transaction log 
	write to occur.

Formatted/Non:	[tran_log_writes] [nvarchar](4000) NULL
	(Requires @get_transaction_info option)
	Aggregates transaction log write information, in the following format:
	A:wB (C kB)
	A is a database that has been touched by an active transaction
	B is the number of log writes that have been made in the database as a result of the transaction
	C is the number of log kilobytes consumed by the log records

Formatted:		[open_tran_count] [varchar](30) NULL
Non-Formatted:	[open_tran_count] [smallint] NULL
	Shows the number of open transactions the session has open

Formatted:		[sql_command] [xml] NULL
Non-Formatted:	[sql_command] [nvarchar](max) NULL
	(Requires @get_outer_command option)
	Shows the "outer" SQL command, i.e. the text of the batch or RPC sent to the server, 
	if available

Formatted:		[sql_text] [xml] NULL
Non-Formatted:	[sql_text] [nvarchar](max) NULL
	Shows the SQL text for active requests or the last statement executed
	for sleeping sessions, if available in either case.
	If @get_full_inner_text option is set, shows the full text of the batch.
	Otherwise, shows only the active statement within the batch.
	If the query text is locked, a special timeout message will be sent, in the following format:
		<timeout_exceeded />
	If an error occurs, an error message will be sent, in the following format:
		<error message="message" />

Formatted/Non:	[query_plan] [xml] NULL
	(Requires @get_plans option)
	Shows the query plan for the request, if available.
	If the plan is locked, a special timeout message will be sent, in the following format:
		<timeout_exceeded />
	If an error occurs, an error message will be sent, in the following format:
		<error message="message" />

Formatted/Non:	[blocking_session_id] [smallint] NULL
	When applicable, shows the blocking SPID

Formatted:		[blocked_session_count] [varchar](30) NULL
Non-Formatted:	[blocked_session_count] [smallint] NULL
	(Requires @find_block_leaders option)
	The total number of SPIDs blocked by this session,
	all the way down the blocking chain.

Formatted:		[percent_complete] [varchar](30) NULL
Non-Formatted:	[percent_complete] [real] NULL
	When applicable, shows the percent complete (e.g. for backups, restores, and some rollbacks)

Formatted/Non:	[host_name] [sysname] NOT NULL
	Shows the host name for the connection

Formatted/Non:	[login_name] [sysname] NOT NULL
	Shows the login name for the connection

Formatted/Non:	[database_name] [sysname] NULL
	Shows the connected database

Formatted/Non:	[program_name] [sysname] NULL
	Shows the reported program/application name

Formatted/Non:	[additional_info] [xml] NULL
	(Requires @get_additional_info option)
	Returns additional non-performance-related session/request information
	If the script finds a SQL Agent job running, the name of the job and job step will be reported
	If @get_task_info = 2 and the script finds a lock wait, the locked object will be reported

Formatted/Non:	[start_time] [datetime] NOT NULL
	For active requests, shows the time the request started
	For sleeping sessions, shows the time the last batch completed

Formatted/Non:	[login_time] [datetime] NOT NULL
	Shows the time that the session connected

Formatted/Non:	[request_id] [int] NULL
	For active requests, shows the request_id
	Should be 0 unless MARS is being used

Formatted/Non:	[collection_time] [datetime] NOT NULL
	Time that this script's final SELECT ran
*/
AS
BEGIN;
	SET NOCOUNT ON; 
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
	SET QUOTED_IDENTIFIER ON;
	SET ANSI_PADDING ON;
	SET CONCAT_NULL_YIELDS_NULL ON;
	SET ANSI_WARNINGS ON;
	SET NUMERIC_ROUNDABORT OFF;
	SET ARITHABORT ON;

	IF
		@filter IS NULL
		OR @filter_type IS NULL
		OR @not_filter IS NULL
		OR @not_filter_type IS NULL
		OR @show_own_spid IS NULL
		OR @show_system_spids IS NULL
		OR @show_sleeping_spids IS NULL
		OR @get_full_inner_text IS NULL
		OR @get_plans IS NULL
		OR @get_outer_command IS NULL
		OR @get_transaction_info IS NULL
		OR @get_task_info IS NULL
		OR @get_locks IS NULL
		OR @get_avg_time IS NULL
		OR @get_additional_info IS NULL
		OR @find_block_leaders IS NULL
		OR @delta_interval IS NULL
		OR @format_output IS NULL
		OR @output_column_list IS NULL
		OR @sort_order IS NULL
		OR @return_schema IS NULL
		OR @destination_table IS NULL
		OR @help IS NULL
	BEGIN;
		RAISERROR('Input parameters cannot be NULL', 16, 1);
		RETURN;
	END;
	
	IF @filter_type NOT IN ('session', 'program', 'database', 'login', 'host')
	BEGIN;
		RAISERROR('Valid filter types are: session, program, database, login, host', 16, 1);
		RETURN;
	END;
	
	IF @filter_type = 'session' AND @filter LIKE '%[^0123456789]%'
	BEGIN;
		RAISERROR('Session filters must be valid integers', 16, 1);
		RETURN;
	END;
	
	IF @not_filter_type NOT IN ('session', 'program', 'database', 'login', 'host')
	BEGIN;
		RAISERROR('Valid filter types are: session, program, database, login, host', 16, 1);
		RETURN;
	END;
	
	IF @not_filter_type = 'session' AND @not_filter LIKE '%[^0123456789]%'
	BEGIN;
		RAISERROR('Session filters must be valid integers', 16, 1);
		RETURN;
	END;
	
	IF @show_sleeping_spids NOT IN (0, 1, 2)
	BEGIN;
		RAISERROR('Valid values for @show_sleeping_spids are: 0, 1, or 2', 16, 1);
		RETURN;
	END;
	
	IF @get_plans NOT IN (0, 1, 2)
	BEGIN;
		RAISERROR('Valid values for @get_plans are: 0, 1, or 2', 16, 1);
		RETURN;
	END;

	IF @get_task_info NOT IN (0, 1, 2)
	BEGIN;
		RAISERROR('Valid values for @get_task_info are: 0, 1, or 2', 16, 1);
		RETURN;
	END;

	IF @format_output NOT IN (0, 1, 2)
	BEGIN;
		RAISERROR('Valid values for @format_output are: 0, 1, or 2', 16, 1);
		RETURN;
	END;
	
	IF @help = 1
	BEGIN;
		DECLARE 
			@header VARCHAR(MAX),
			@params VARCHAR(MAX),
			@outputs VARCHAR(MAX);

		SELECT 
			@header =
				REPLACE
				(
					REPLACE
					(
						CONVERT
						(
							VARCHAR(MAX),
							SUBSTRING
							(
								t.text, 
								CHARINDEX('/' + REPLICATE('*', 93), t.text) + 94,
								CHARINDEX(REPLICATE('*', 93) + '/', t.text) - (CHARINDEX('/' + REPLICATE('*', 93), t.text) + 94)
							)
						),
						CHAR(13)+CHAR(10),
						CHAR(13)
					),
					'	',
					''
				),
			@params =
				CHAR(13) +
					REPLACE
					(
						REPLACE
						(
							CONVERT
							(
								VARCHAR(MAX),
								SUBSTRING
								(
									t.text, 
									CHARINDEX('--~', t.text) + 5, 
									CHARINDEX('--~', t.text, CHARINDEX('--~', t.text) + 5) - (CHARINDEX('--~', t.text) + 5)
								)
							),
							CHAR(13)+CHAR(10),
							CHAR(13)
						),
						'	',
						''
					),
				@outputs = 
					CHAR(13) +
						REPLACE
						(
							REPLACE
							(
								REPLACE
								(
									CONVERT
									(
										VARCHAR(MAX),
										SUBSTRING
										(
											t.text, 
											CHARINDEX('OUTPUT COLUMNS'+CHAR(13)+CHAR(10)+'--------------', t.text) + 32,
											CHARINDEX('*/', t.text, CHARINDEX('OUTPUT COLUMNS'+CHAR(13)+CHAR(10)+'--------------', t.text) + 32) - (CHARINDEX('OUTPUT COLUMNS'+CHAR(13)+CHAR(10)+'--------------', t.text) + 32)
										)
									),
									CHAR(9),
									CHAR(255)
								),
								CHAR(13)+CHAR(10),
								CHAR(13)
							),
							'	',
							''
						) +
						CHAR(13)
		FROM sys.dm_exec_requests AS r
		CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) AS t
		WHERE
			r.session_id = @@SPID;

		WITH
		a0 AS
		(SELECT 1 AS n UNION ALL SELECT 1),
		a1 AS
		(SELECT 1 AS n FROM a0 AS a, a0 AS b),
		a2 AS
		(SELECT 1 AS n FROM a1 AS a, a1 AS b),
		a3 AS
		(SELECT 1 AS n FROM a2 AS a, a2 AS b),
		a4 AS
		(SELECT 1 AS n FROM a3 AS a, a3 AS b),
		numbers AS
		(
			SELECT TOP(LEN(@header) - 1)
				ROW_NUMBER() OVER
				(
					ORDER BY (SELECT NULL)
				) AS number
			FROM a4
			ORDER BY
				number
		)
		SELECT
			RTRIM(LTRIM(
				SUBSTRING
				(
					@header,
					number + 1,
					CHARINDEX(CHAR(13), @header, number + 1) - number - 1
				)
			)) AS [------header---------------------------------------------------------------------------------------------------------------]
		FROM numbers
		WHERE
			SUBSTRING(@header, number, 1) = CHAR(13);

		WITH
		a0 AS
		(SELECT 1 AS n UNION ALL SELECT 1),
		a1 AS
		(SELECT 1 AS n FROM a0 AS a, a0 AS b),
		a2 AS
		(SELECT 1 AS n FROM a1 AS a, a1 AS b),
		a3 AS
		(SELECT 1 AS n FROM a2 AS a, a2 AS b),
		a4 AS
		(SELECT 1 AS n FROM a3 AS a, a3 AS b),
		numbers AS
		(
			SELECT TOP(LEN(@params) - 1)
				ROW_NUMBER() OVER
				(
					ORDER BY (SELECT NULL)
				) AS number
			FROM a4
			ORDER BY
				number
		),
		tokens AS
		(
			SELECT 
				RTRIM(LTRIM(
					SUBSTRING
					(
						@params,
						number + 1,
						CHARINDEX(CHAR(13), @params, number + 1) - number - 1
					)
				)) AS token,
				number,
				CASE
					WHEN SUBSTRING(@params, number + 1, 1) = CHAR(13) THEN number
					ELSE COALESCE(NULLIF(CHARINDEX(',' + CHAR(13) + CHAR(13), @params, number), 0), LEN(@params)) 
				END AS param_group,
				ROW_NUMBER() OVER
				(
					PARTITION BY
						CHARINDEX(',' + CHAR(13) + CHAR(13), @params, number),
						SUBSTRING(@params, number+1, 1)
					ORDER BY 
						number
				) AS group_order
			FROM numbers
			WHERE
				SUBSTRING(@params, number, 1) = CHAR(13)
		),
		parsed_tokens AS
		(
			SELECT
				MIN
				(
					CASE
						WHEN token LIKE '@%' THEN token
						ELSE NULL
					END
				) AS parameter,
				MIN
				(
					CASE
						WHEN token LIKE '--%' THEN RIGHT(token, LEN(token) - 2)
						ELSE NULL
					END
				) AS description,
				param_group,
				group_order
			FROM tokens
			WHERE
				NOT 
				(
					token = '' 
					AND group_order > 1
				)
			GROUP BY
				param_group,
				group_order
		)
		SELECT
			CASE
				WHEN description IS NULL AND parameter IS NULL THEN '-------------------------------------------------------------------------'
				WHEN param_group = MAX(param_group) OVER() THEN parameter
				ELSE COALESCE(LEFT(parameter, LEN(parameter) - 1), '')
			END AS [------parameter----------------------------------------------------------],
			CASE
				WHEN description IS NULL AND parameter IS NULL THEN '----------------------------------------------------------------------------------------------------------------------'
				ELSE COALESCE(description, '')
			END AS [------description-----------------------------------------------------------------------------------------------------]
		FROM parsed_tokens
		ORDER BY
			param_group, 
			group_order;
		
		WITH
		a0 AS
		(SELECT 1 AS n UNION ALL SELECT 1),
		a1 AS
		(SELECT 1 AS n FROM a0 AS a, a0 AS b),
		a2 AS
		(SELECT 1 AS n FROM a1 AS a, a1 AS b),
		a3 AS
		(SELECT 1 AS n FROM a2 AS a, a2 AS b),
		a4 AS
		(SELECT 1 AS n FROM a3 AS a, a3 AS b),
		numbers AS
		(
			SELECT TOP(LEN(@outputs) - 1)
				ROW_NUMBER() OVER
				(
					ORDER BY (SELECT NULL)
				) AS number
			FROM a4
			ORDER BY
				number
		),
		tokens AS
		(
			SELECT 
				RTRIM(LTRIM(
					SUBSTRING
					(
						@outputs,
						number + 1,
						CASE
							WHEN 
								COALESCE(NULLIF(CHARINDEX(CHAR(13) + 'Formatted', @outputs, number + 1), 0), LEN(@outputs)) < 
								COALESCE(NULLIF(CHARINDEX(CHAR(13) + CHAR(255) COLLATE Latin1_General_Bin2, @outputs, number + 1), 0), LEN(@outputs))
								THEN COALESCE(NULLIF(CHARINDEX(CHAR(13) + 'Formatted', @outputs, number + 1), 0), LEN(@outputs)) - number - 1
							ELSE
								COALESCE(NULLIF(CHARINDEX(CHAR(13) + CHAR(255) COLLATE Latin1_General_Bin2, @outputs, number + 1), 0), LEN(@outputs)) - number - 1
						END
					)
				)) AS token,
				number,
				COALESCE(NULLIF(CHARINDEX(CHAR(13) + 'Formatted', @outputs, number + 1), 0), LEN(@outputs)) AS output_group,
				ROW_NUMBER() OVER
				(
					PARTITION BY 
						COALESCE(NULLIF(CHARINDEX(CHAR(13) + 'Formatted', @outputs, number + 1), 0), LEN(@outputs))
					ORDER BY
						number
				) AS output_group_order
			FROM numbers
			WHERE
				SUBSTRING(@outputs, number, 10) = CHAR(13) + 'Formatted'
				OR SUBSTRING(@outputs, number, 2) = CHAR(13) + CHAR(255) COLLATE Latin1_General_Bin2
		),
		output_tokens AS
		(
			SELECT 
				*,
				CASE output_group_order
					WHEN 2 THEN MAX(CASE output_group_order WHEN 1 THEN token ELSE NULL END) OVER (PARTITION BY output_group)
					ELSE ''
				END COLLATE Latin1_General_Bin2 AS column_info
			FROM tokens
		)
		SELECT
			CASE output_group_order
				WHEN 1 THEN '-----------------------------------'
				WHEN 2 THEN 
					CASE
						WHEN CHARINDEX('Formatted/Non:', column_info) = 1 THEN
							SUBSTRING(column_info, CHARINDEX(CHAR(255) COLLATE Latin1_General_Bin2, column_info)+1, CHARINDEX(']', column_info, CHARINDEX(CHAR(255) COLLATE Latin1_General_Bin2, column_info)+2) - CHARINDEX(CHAR(255) COLLATE Latin1_General_Bin2, column_info))
						ELSE
							SUBSTRING(column_info, CHARINDEX(CHAR(255) COLLATE Latin1_General_Bin2, column_info)+2, CHARINDEX(']', column_info, CHARINDEX(CHAR(255) COLLATE Latin1_General_Bin2, column_info)+2) - CHARINDEX(CHAR(255) COLLATE Latin1_General_Bin2, column_info)-1)
					END
				ELSE ''
			END AS formatted_column_name,
			CASE output_group_order
				WHEN 1 THEN '-----------------------------------'
				WHEN 2 THEN 
					CASE
						WHEN CHARINDEX('Formatted/Non:', column_info) = 1 THEN
							SUBSTRING(column_info, CHARINDEX(']', column_info)+2, LEN(column_info))
						ELSE
							SUBSTRING(column_info, CHARINDEX(']', column_info)+2, CHARINDEX('Non-Formatted:', column_info, CHARINDEX(']', column_info)+2) - CHARINDEX(']', column_info)-3)
					END
				ELSE ''
			END AS formatted_column_type,
			CASE output_group_order
				WHEN 1 THEN '---------------------------------------'
				WHEN 2 THEN 
					CASE
						WHEN CHARINDEX('Formatted/Non:', column_info) = 1 THEN ''
						ELSE
							CASE
								WHEN SUBSTRING(column_info, CHARINDEX(CHAR(255) COLLATE Latin1_General_Bin2, column_info, CHARINDEX('Non-Formatted:', column_info))+1, 1) = '<' THEN
									SUBSTRING(column_info, CHARINDEX(CHAR(255) COLLATE Latin1_General_Bin2, column_info, CHARINDEX('Non-Formatted:', column_info))+1, CHARINDEX('>', column_info, CHARINDEX(CHAR(255) COLLATE Latin1_General_Bin2, column_info, CHARINDEX('Non-Formatted:', column_info))+1) - CHARINDEX(CHAR(255) COLLATE Latin1_General_Bin2, column_info, CHARINDEX('Non-Formatted:', column_info)))
								ELSE
									SUBSTRING(column_info, CHARINDEX(CHAR(255) COLLATE Latin1_General_Bin2, column_info, CHARINDEX('Non-Formatted:', column_info))+1, CHARINDEX(']', column_info, CHARINDEX(CHAR(255) COLLATE Latin1_General_Bin2, column_info, CHARINDEX('Non-Formatted:', column_info))+1) - CHARINDEX(CHAR(255) COLLATE Latin1_General_Bin2, column_info, CHARINDEX('Non-Formatted:', column_info)))
							END
					END
				ELSE ''
			END AS unformatted_column_name,
			CASE output_group_order
				WHEN 1 THEN '---------------------------------------'
				WHEN 2 THEN 
					CASE
						WHEN CHARINDEX('Formatted/Non:', column_info) = 1 THEN ''
						ELSE
							CASE
								WHEN SUBSTRING(column_info, CHARINDEX(CHAR(255) COLLATE Latin1_General_Bin2, column_info, CHARINDEX('Non-Formatted:', column_info))+1, 1) = '<' THEN ''
								ELSE
									SUBSTRING(column_info, CHARINDEX(']', column_info, CHARINDEX('Non-Formatted:', column_info))+2, CHARINDEX('Non-Formatted:', column_info, CHARINDEX(']', column_info)+2) - CHARINDEX(']', column_info)-3)
							END
					END
				ELSE ''
			END AS unformatted_column_type,
			CASE output_group_order
				WHEN 1 THEN '----------------------------------------------------------------------------------------------------------------------'
				ELSE REPLACE(token, CHAR(255) COLLATE Latin1_General_Bin2, '')
			END AS [------description-----------------------------------------------------------------------------------------------------]
		FROM output_tokens
		WHERE
			NOT 
			(
				output_group_order = 1 
				AND output_group = LEN(@outputs)
			)
		ORDER BY
			output_group,
			CASE output_group_order
				WHEN 1 THEN 99
				ELSE output_group_order
			END;

		RETURN;
	END;

	WITH
	a0 AS
	(SELECT 1 AS n UNION ALL SELECT 1),
	a1 AS
	(SELECT 1 AS n FROM a0 AS a, a0 AS b),
	a2 AS
	(SELECT 1 AS n FROM a1 AS a, a1 AS b),
	a3 AS
	(SELECT 1 AS n FROM a2 AS a, a2 AS b),
	a4 AS
	(SELECT 1 AS n FROM a3 AS a, a3 AS b),
	numbers AS
	(
		SELECT TOP(LEN(@output_column_list))
			ROW_NUMBER() OVER
			(
				ORDER BY (SELECT NULL)
			) AS number
		FROM a4
		ORDER BY
			number
	),
	tokens AS
	(
		SELECT 
			'|[' +
				SUBSTRING
				(
					@output_column_list,
					number + 1,
					CHARINDEX(']', @output_column_list, number) - number - 1
				) + '|]' AS token,
			number
		FROM numbers
		WHERE
			SUBSTRING(@output_column_list, number, 1) = '['
	),
	ordered_columns AS
	(
		SELECT
			x.column_name,
			ROW_NUMBER() OVER
			(
				PARTITION BY
					x.column_name
				ORDER BY
					tokens.number,
					x.default_order
			) AS r,
			ROW_NUMBER() OVER
			(
				ORDER BY
					tokens.number,
					x.default_order
			) AS s
		FROM tokens
		JOIN
		(
			SELECT '[session_id]' AS column_name, 1 AS default_order
			UNION ALL
			SELECT '[dd hh:mm:ss.mss]', 2
			WHERE
				@format_output IN (1, 2)
			UNION ALL
			SELECT '[dd hh:mm:ss.mss (avg)]', 3
			WHERE
				@format_output IN (1, 2)
				AND @get_avg_time = 1
			UNION ALL
			SELECT '[avg_elapsed_time]', 4
			WHERE
				@format_output = 0
				AND @get_avg_time = 1
			UNION ALL
			SELECT '[physical_io]', 5
			WHERE
				@get_task_info = 2
			UNION ALL
			SELECT '[reads]', 6
			UNION ALL
			SELECT '[physical_reads]', 7
			UNION ALL
			SELECT '[writes]', 8
			UNION ALL
			SELECT '[tempdb_allocations]', 9
			UNION ALL
			SELECT '[tempdb_current]', 10
			UNION ALL
			SELECT '[CPU]', 11
			UNION ALL
			SELECT '[context_switches]', 12
			WHERE
				@get_task_info = 2
			UNION ALL
			SELECT '[used_memory]', 13
			UNION ALL
			SELECT '[physical_io_delta]', 14
			WHERE
				@delta_interval > 0	
				AND @get_task_info = 2
			UNION ALL
			SELECT '[reads_delta]', 15
			WHERE
				@delta_interval > 0
			UNION ALL
			SELECT '[physical_reads_delta]', 16
			WHERE
				@delta_interval > 0
			UNION ALL
			SELECT '[writes_delta]', 17
			WHERE
				@delta_interval > 0
			UNION ALL
			SELECT '[tempdb_allocations_delta]', 18
			WHERE
				@delta_interval > 0
			UNION ALL
			SELECT '[tempdb_current_delta]', 19
			WHERE
				@delta_interval > 0
			UNION ALL
			SELECT '[CPU_delta]', 20
			WHERE
				@delta_interval > 0
			UNION ALL
			SELECT '[context_switches_delta]', 21
			WHERE
				@delta_interval > 0
				AND @get_task_info = 2
			UNION ALL
			SELECT '[used_memory_delta]', 22
			WHERE
				@delta_interval > 0
			UNION ALL
			SELECT '[tasks]', 23
			WHERE
				@get_task_info = 2
			UNION ALL
			SELECT '[status]', 24
			UNION ALL
			SELECT '[wait_info]', 25
			WHERE
				@get_task_info > 0
				OR @find_block_leaders = 1
			UNION ALL
			SELECT '[locks]', 26
			WHERE
				@get_locks = 1
			UNION ALL
			SELECT '[tran_start_time]', 27
			WHERE
				@get_transaction_info = 1
			UNION ALL
			SELECT '[tran_log_writes]', 28
			WHERE
				@get_transaction_info = 1
			UNION ALL
			SELECT '[open_tran_count]', 29
			UNION ALL
			SELECT '[sql_command]', 30
			WHERE
				@get_outer_command = 1
			UNION ALL
			SELECT '[sql_text]', 31
			UNION ALL
			SELECT '[query_plan]', 32
			WHERE
				@get_plans >= 1
			UNION ALL
			SELECT '[blocking_session_id]', 33
			WHERE
				@get_task_info > 0
				OR @find_block_leaders = 1
			UNION ALL
			SELECT '[blocked_session_count]', 34
			WHERE
				@find_block_leaders = 1
			UNION ALL
			SELECT '[percent_complete]', 35
			UNION ALL
			SELECT '[host_name]', 36
			UNION ALL
			SELECT '[login_name]', 37
			UNION ALL
			SELECT '[database_name]', 38
			UNION ALL
			SELECT '[program_name]', 39
			UNION ALL
			SELECT '[additional_info]', 40
			WHERE
				@get_additional_info = 1
			UNION ALL
			SELECT '[start_time]', 41
			UNION ALL
			SELECT '[login_time]', 42
			UNION ALL
			SELECT '[request_id]', 43
			UNION ALL
			SELECT '[collection_time]', 44
		) AS x ON 
			x.column_name LIKE token ESCAPE '|'
	)
	SELECT
		@output_column_list =
			STUFF
			(
				(
					SELECT
						',' + column_name as [text()]
					FROM ordered_columns
					WHERE
						r = 1
					ORDER BY
						s
					FOR XML
						PATH('')
				),
				1,
				1,
				''
			);
	
	IF COALESCE(RTRIM(@output_column_list), '') = ''
	BEGIN;
		RAISERROR('No valid column matches found in @output_column_list or no columns remain due to selected options.', 16, 1);
		RETURN;
	END;
	
	IF @destination_table <> ''
	BEGIN;
		SET @destination_table = 
			--database
			COALESCE(QUOTENAME(PARSENAME(@destination_table, 3)) + '.', '') +
			--schema
			COALESCE(QUOTENAME(PARSENAME(@destination_table, 2)) + '.', '') +
			--table
			COALESCE(QUOTENAME(PARSENAME(@destination_table, 1)), '');
			
		IF COALESCE(RTRIM(@destination_table), '') = ''
		BEGIN;
			RAISERROR('Destination table not properly formatted.', 16, 1);
			RETURN;
		END;
	END;

	WITH
	a0 AS
	(SELECT 1 AS n UNION ALL SELECT 1),
	a1 AS
	(SELECT 1 AS n FROM a0 AS a, a0 AS b),
	a2 AS
	(SELECT 1 AS n FROM a1 AS a, a1 AS b),
	a3 AS
	(SELECT 1 AS n FROM a2 AS a, a2 AS b),
	a4 AS
	(SELECT 1 AS n FROM a3 AS a, a3 AS b),
	numbers AS
	(
		SELECT TOP(LEN(@sort_order))
			ROW_NUMBER() OVER
			(
				ORDER BY (SELECT NULL)
			) AS number
		FROM a4
		ORDER BY
			number
	),
	tokens AS
	(
		SELECT 
			'|[' +
				SUBSTRING
				(
					@sort_order,
					number + 1,
					CHARINDEX(']', @sort_order, number) - number - 1
				) + '|]' AS token,
			SUBSTRING
			(
				@sort_order,
				CHARINDEX(']', @sort_order, number) + 1,
				COALESCE(NULLIF(CHARINDEX('[', @sort_order, CHARINDEX(']', @sort_order, number)), 0), LEN(@sort_order)) - CHARINDEX(']', @sort_order, number)
			) AS next_chunk,
			number
		FROM numbers
		WHERE
			SUBSTRING(@sort_order, number, 1) = '['
	),
	ordered_columns AS
	(
		SELECT
			x.column_name +
				CASE
					WHEN tokens.next_chunk LIKE '%asc%' THEN ' ASC'
					WHEN tokens.next_chunk LIKE '%desc%' THEN ' DESC'
					ELSE ''
				END AS column_name,
			ROW_NUMBER() OVER
			(
				PARTITION BY
					x.column_name
				ORDER BY
					tokens.number
			) AS r,
			tokens.number
		FROM tokens
		JOIN
		(
			SELECT '[session_id]' AS column_name
			UNION ALL
			SELECT '[physical_io]'
			UNION ALL
			SELECT '[reads]'
			UNION ALL
			SELECT '[physical_reads]'
			UNION ALL
			SELECT '[writes]'
			UNION ALL
			SELECT '[tempdb_allocations]'
			UNION ALL
			SELECT '[tempdb_current]'
			UNION ALL
			SELECT '[CPU]'
			UNION ALL
			SELECT '[context_switches]'
			UNION ALL
			SELECT '[used_memory]'
			UNION ALL
			SELECT '[physical_io_delta]'
			UNION ALL
			SELECT '[reads_delta]'
			UNION ALL
			SELECT '[physical_reads_delta]'
			UNION ALL
			SELECT '[writes_delta]'
			UNION ALL
			SELECT '[tempdb_allocations_delta]'
			UNION ALL
			SELECT '[tempdb_current_delta]'
			UNION ALL
			SELECT '[CPU_delta]'
			UNION ALL
			SELECT '[context_switches_delta]'
			UNION ALL
			SELECT '[used_memory_delta]'
			UNION ALL
			SELECT '[tasks]'
			UNION ALL
			SELECT '[tran_start_time]'
			UNION ALL
			SELECT '[open_tran_count]'
			UNION ALL
			SELECT '[blocking_session_id]'
			UNION ALL
			SELECT '[blocked_session_count]'
			UNION ALL
			SELECT '[percent_complete]'
			UNION ALL
			SELECT '[host_name]'
			UNION ALL
			SELECT '[login_name]'
			UNION ALL
			SELECT '[database_name]'
			UNION ALL
			SELECT '[start_time]'
			UNION ALL
			SELECT '[login_time]'
		) AS x ON 
			x.column_name LIKE token ESCAPE '|'
	)
	SELECT
		@sort_order = COALESCE(z.sort_order, '')
	FROM
	(
		SELECT
			STUFF
			(
				(
					SELECT
						',' + column_name as [text()]
					FROM ordered_columns
					WHERE
						r = 1
					ORDER BY
						number
					FOR XML
						PATH('')
				),
				1,
				1,
				''
			) AS sort_order
	) AS z;

	CREATE TABLE #sessions
	(
		recursion SMALLINT NOT NULL,
		session_id SMALLINT NOT NULL,
		request_id INT NOT NULL,
		session_number INT NOT NULL,
		elapsed_time INT NOT NULL,
		avg_elapsed_time INT NULL,
		physical_io BIGINT NULL,
		reads BIGINT NULL,
		physical_reads BIGINT NULL,
		writes BIGINT NULL,
		tempdb_allocations BIGINT NULL,
		tempdb_current BIGINT NULL,
		CPU INT NULL,
		thread_CPU_snapshot BIGINT NULL,
		context_switches BIGINT NULL,
		used_memory BIGINT NOT NULL, 
		tasks SMALLINT NULL,
		status VARCHAR(30) NOT NULL,
		wait_info NVARCHAR(4000) NULL,
		locks XML NULL,
		transaction_id BIGINT NULL,
		tran_start_time DATETIME NULL,
		tran_log_writes NVARCHAR(4000) NULL,
		open_tran_count SMALLINT NULL,
		sql_command XML NULL,
		sql_handle VARBINARY(64) NULL,
		statement_start_offset INT NULL,
		statement_end_offset INT NULL,
		sql_text XML NULL,
		plan_handle VARBINARY(64) NULL,
		query_plan XML NULL,
		blocking_session_id SMALLINT NULL,
		blocked_session_count SMALLINT NULL,
		percent_complete REAL NULL,
		host_name sysname NULL,
		login_name sysname NOT NULL,
		database_name sysname NULL,
		program_name sysname NULL,
		additional_info XML NULL,
		start_time DATETIME NOT NULL,
		login_time DATETIME NULL,
		last_request_start_time DATETIME NULL,
		PRIMARY KEY CLUSTERED (session_id, request_id, recursion) WITH (IGNORE_DUP_KEY = ON),
		UNIQUE NONCLUSTERED (transaction_id, session_id, request_id, recursion) WITH (IGNORE_DUP_KEY = ON)
	);

	IF @return_schema = 0
	BEGIN;
		--Disable unnecessary autostats on the table
		CREATE STATISTICS s_session_id ON #sessions (session_id)
		WITH SAMPLE 0 ROWS, NORECOMPUTE;
		CREATE STATISTICS s_request_id ON #sessions (request_id)
		WITH SAMPLE 0 ROWS, NORECOMPUTE;
		CREATE STATISTICS s_transaction_id ON #sessions (transaction_id)
		WITH SAMPLE 0 ROWS, NORECOMPUTE;
		CREATE STATISTICS s_session_number ON #sessions (session_number)
		WITH SAMPLE 0 ROWS, NORECOMPUTE;
		CREATE STATISTICS s_status ON #sessions (status)
		WITH SAMPLE 0 ROWS, NORECOMPUTE;
		CREATE STATISTICS s_start_time ON #sessions (start_time)
		WITH SAMPLE 0 ROWS, NORECOMPUTE;
		CREATE STATISTICS s_last_request_start_time ON #sessions (last_request_start_time)
		WITH SAMPLE 0 ROWS, NORECOMPUTE;
		CREATE STATISTICS s_recursion ON #sessions (recursion)
		WITH SAMPLE 0 ROWS, NORECOMPUTE;

		DECLARE @recursion SMALLINT;
		SET @recursion = 
			CASE @delta_interval
				WHEN 0 THEN 1
				ELSE -1
			END;

		DECLARE @first_collection_ms_ticks BIGINT;
		DECLARE @last_collection_start DATETIME;

		--Used for the delta pull
		REDO:;
		
		IF 
			@get_locks = 1 
			AND @recursion = 1
			AND @output_column_list LIKE '%|[locks|]%' ESCAPE '|'
		BEGIN;
			SELECT
				y.resource_type,
				y.database_name,
				y.object_id,
				y.file_id,
				y.page_type,
				y.hobt_id,
				y.allocation_unit_id,
				y.index_id,
				y.schema_id,
				y.principal_id,
				y.request_mode,
				y.request_status,
				y.session_id,
				y.resource_description,
				y.request_count,
				s.request_id,
				s.start_time,
				CONVERT(sysname, NULL) AS object_name,
				CONVERT(sysname, NULL) AS index_name,
				CONVERT(sysname, NULL) AS schema_name,
				CONVERT(sysname, NULL) AS principal_name,
				CONVERT(NVARCHAR(2048), NULL) AS query_error
			INTO #locks
			FROM
			(
				SELECT
					sp.spid AS session_id,
					CASE sp.status
						WHEN 'sleeping' THEN CONVERT(INT, 0)
						ELSE sp.request_id
					END AS request_id,
					CASE sp.status
						WHEN 'sleeping' THEN sp.last_batch
						ELSE COALESCE(req.start_time, sp.last_batch)
					END AS start_time,
					sp.dbid
				FROM sys.sysprocesses AS sp
				OUTER APPLY
				(
					SELECT TOP(1)
						CASE
							WHEN 
							(
								sp.hostprocess > ''
								OR r.total_elapsed_time < 0
							) THEN
								r.start_time
							ELSE
								DATEADD
								(
									ms, 
									1000 * (DATEPART(ms, DATEADD(second, -(r.total_elapsed_time / 1000), GETDATE())) / 500) - DATEPART(ms, DATEADD(second, -(r.total_elapsed_time / 1000), GETDATE())), 
									DATEADD(second, -(r.total_elapsed_time / 1000), GETDATE())
								)
						END AS start_time
					FROM sys.dm_exec_requests AS r
					WHERE
						r.session_id = sp.spid
						AND r.request_id = sp.request_id
				) AS req
				WHERE
					--Process inclusive filter
					1 =
						CASE
							WHEN @filter <> '' THEN
								CASE @filter_type
									WHEN 'session' THEN
										CASE
											WHEN
												CONVERT(SMALLINT, @filter) = 0
												OR sp.spid = CONVERT(SMALLINT, @filter)
													THEN 1
											ELSE 0
										END
									WHEN 'program' THEN
										CASE
											WHEN sp.program_name LIKE @filter THEN 1
											ELSE 0
										END
									WHEN 'login' THEN
										CASE
											WHEN sp.loginame LIKE @filter THEN 1
											ELSE 0
										END
									WHEN 'host' THEN
										CASE
											WHEN sp.hostname LIKE @filter THEN 1
											ELSE 0
										END
									WHEN 'database' THEN
										CASE
											WHEN DB_NAME(sp.dbid) LIKE @filter THEN 1
											ELSE 0
										END
									ELSE 0
								END
							ELSE 1
						END
					--Process exclusive filter
					AND 0 =
						CASE
							WHEN @not_filter <> '' THEN
								CASE @not_filter_type
									WHEN 'session' THEN
										CASE
											WHEN sp.spid = CONVERT(SMALLINT, @not_filter) THEN 1
											ELSE 0
										END
									WHEN 'program' THEN
										CASE
											WHEN sp.program_name LIKE @not_filter THEN 1
											ELSE 0
										END
									WHEN 'login' THEN
										CASE
											WHEN sp.loginame LIKE @not_filter THEN 1
											ELSE 0
										END
									WHEN 'host' THEN
										CASE
											WHEN sp.hostname LIKE @not_filter THEN 1
											ELSE 0
										END
									WHEN 'database' THEN
										CASE
											WHEN DB_NAME(sp.dbid) LIKE @not_filter THEN 1
											ELSE 0
										END
									ELSE 0
								END
							ELSE 0
						END
					AND 
					(
						@show_own_spid = 1
						OR sp.spid <> @@SPID
					)
					AND 
					(
						@show_system_spids = 1
						OR sp.hostprocess > ''
					)
					AND sp.ecid = 0
			) AS s
			INNER HASH JOIN
			(
				SELECT
					x.resource_type,
					x.database_name,
					x.object_id,
					x.file_id,
					CASE
						WHEN x.page_no = 1 OR x.page_no % 8088 = 0 THEN 'PFS'
						WHEN x.page_no = 2 OR x.page_no % 511232 = 0 THEN 'GAM'
						WHEN x.page_no = 3 OR x.page_no % 511233 = 0 THEN 'SGAM'
						WHEN x.page_no = 6 OR x.page_no % 511238 = 0 THEN 'DCM'
						WHEN x.page_no = 7 OR x.page_no % 511239 = 0 THEN 'BCM'
						WHEN x.page_no IS NOT NULL THEN '*'
						ELSE NULL
					END AS page_type,
					x.hobt_id,
					x.allocation_unit_id,
					x.index_id,
					x.schema_id,
					x.principal_id,
					x.request_mode,
					x.request_status,
					x.session_id,
					x.request_id,
					CASE
						WHEN COALESCE(x.object_id, x.file_id, x.hobt_id, x.allocation_unit_id, x.index_id, x.schema_id, x.principal_id) IS NULL THEN NULLIF(resource_description, '')
						ELSE NULL
					END AS resource_description,
					COUNT(*) AS request_count
				FROM
				(
					SELECT
						tl.resource_type +
							CASE
								WHEN tl.resource_subtype = '' THEN ''
								ELSE '.' + tl.resource_subtype
							END AS resource_type,
						COALESCE(DB_NAME(tl.resource_database_id), N'(null)') AS database_name,
						CONVERT
						(
							INT,
							CASE
								WHEN tl.resource_type = 'OBJECT' THEN tl.resource_associated_entity_id
								WHEN tl.resource_description LIKE '%object_id = %' THEN
									(
										SUBSTRING
										(
											tl.resource_description, 
											(CHARINDEX('object_id = ', tl.resource_description) + 12), 
											COALESCE
											(
												NULLIF
												(
													CHARINDEX(',', tl.resource_description, CHARINDEX('object_id = ', tl.resource_description) + 12),
													0
												), 
												DATALENGTH(tl.resource_description)+1
											) - (CHARINDEX('object_id = ', tl.resource_description) + 12)
										)
									)
								ELSE NULL
							END
						) AS object_id,
						CONVERT
						(
							INT,
							CASE 
								WHEN tl.resource_type = 'FILE' THEN CONVERT(INT, tl.resource_description)
								WHEN tl.resource_type IN ('PAGE', 'EXTENT', 'RID') THEN LEFT(tl.resource_description, CHARINDEX(':', tl.resource_description)-1)
								ELSE NULL
							END
						) AS file_id,
						CONVERT
						(
							INT,
							CASE
								WHEN tl.resource_type IN ('PAGE', 'EXTENT', 'RID') THEN 
									SUBSTRING
									(
										tl.resource_description, 
										CHARINDEX(':', tl.resource_description) + 1, 
										COALESCE
										(
											NULLIF
											(
												CHARINDEX(':', tl.resource_description, CHARINDEX(':', tl.resource_description) + 1), 
												0
											), 
											DATALENGTH(tl.resource_description)+1
										) - (CHARINDEX(':', tl.resource_description) + 1)
									)
								ELSE NULL
							END
						) AS page_no,
						CASE
							WHEN tl.resource_type IN ('PAGE', 'KEY', 'RID', 'HOBT') THEN tl.resource_associated_entity_id
							ELSE NULL
						END AS hobt_id,
						CASE
							WHEN tl.resource_type = 'ALLOCATION_UNIT' THEN tl.resource_associated_entity_id
							ELSE NULL
						END AS allocation_unit_id,
						CONVERT
						(
							INT,
							CASE
								WHEN
									/*TODO: Deal with server principals*/ 
									tl.resource_subtype <> 'SERVER_PRINCIPAL' 
									AND tl.resource_description LIKE '%index_id or stats_id = %' THEN
									(
										SUBSTRING
										(
											tl.resource_description, 
											(CHARINDEX('index_id or stats_id = ', tl.resource_description) + 23), 
											COALESCE
											(
												NULLIF
												(
													CHARINDEX(',', tl.resource_description, CHARINDEX('index_id or stats_id = ', tl.resource_description) + 23), 
													0
												), 
												DATALENGTH(tl.resource_description)+1
											) - (CHARINDEX('index_id or stats_id = ', tl.resource_description) + 23)
										)
									)
								ELSE NULL
							END 
						) AS index_id,
						CONVERT
						(
							INT,
							CASE
								WHEN tl.resource_description LIKE '%schema_id = %' THEN
									(
										SUBSTRING
										(
											tl.resource_description, 
											(CHARINDEX('schema_id = ', tl.resource_description) + 12), 
											COALESCE
											(
												NULLIF
												(
													CHARINDEX(',', tl.resource_description, CHARINDEX('schema_id = ', tl.resource_description) + 12), 
													0
												), 
												DATALENGTH(tl.resource_description)+1
											) - (CHARINDEX('schema_id = ', tl.resource_description) + 12)
										)
									)
								ELSE NULL
							END 
						) AS schema_id,
						CONVERT
						(
							INT,
							CASE
								WHEN tl.resource_description LIKE '%principal_id = %' THEN
									(
										SUBSTRING
										(
											tl.resource_description, 
											(CHARINDEX('principal_id = ', tl.resource_description) + 15), 
											COALESCE
											(
												NULLIF
												(
													CHARINDEX(',', tl.resource_description, CHARINDEX('principal_id = ', tl.resource_description) + 15), 
													0
												), 
												DATALENGTH(tl.resource_description)+1
											) - (CHARINDEX('principal_id = ', tl.resource_description) + 15)
										)
									)
								ELSE NULL
							END
						) AS principal_id,
						tl.request_mode,
						tl.request_status,
						tl.request_session_id AS session_id,
						tl.request_request_id AS request_id,

						/*TODO: Applocks, other resource_descriptions*/
						RTRIM(tl.resource_description) AS resource_description,
						tl.resource_associated_entity_id
						/*********************************************/
					FROM 
					(
						SELECT 
							request_session_id,
							CONVERT(VARCHAR(120), resource_type) COLLATE Latin1_General_Bin2 AS resource_type,
							CONVERT(VARCHAR(120), resource_subtype) COLLATE Latin1_General_Bin2 AS resource_subtype,
							resource_database_id,
							CONVERT(VARCHAR(512), resource_description) COLLATE Latin1_General_Bin2 AS resource_description,
							resource_associated_entity_id,
							CONVERT(VARCHAR(120), request_mode) COLLATE Latin1_General_Bin2 AS request_mode,
							CONVERT(VARCHAR(120), request_status) COLLATE Latin1_General_Bin2 AS request_status,
							request_request_id
						FROM sys.dm_tran_locks
					) AS tl
				) AS x
				GROUP BY
					x.resource_type,
					x.database_name,
					x.object_id,
					x.file_id,
					CASE
						WHEN x.page_no = 1 OR x.page_no % 8088 = 0 THEN 'PFS'
						WHEN x.page_no = 2 OR x.page_no % 511232 = 0 THEN 'GAM'
						WHEN x.page_no = 3 OR x.page_no % 511233 = 0 THEN 'SGAM'
						WHEN x.page_no = 6 OR x.page_no % 511238 = 0 THEN 'DCM'
						WHEN x.page_no = 7 OR x.page_no % 511239 = 0 THEN 'BCM'
						WHEN x.page_no IS NOT NULL THEN '*'
						ELSE NULL
					END,
					x.hobt_id,
					x.allocation_unit_id,
					x.index_id,
					x.schema_id,
					x.principal_id,
					x.request_mode,
					x.request_status,
					x.session_id,
					x.request_id,
					CASE
						WHEN COALESCE(x.object_id, x.file_id, x.hobt_id, x.allocation_unit_id, x.index_id, x.schema_id, x.principal_id) IS NULL THEN NULLIF(resource_description, '')
						ELSE NULL
					END
			) AS y ON
				y.session_id = s.session_id
				AND y.request_id = s.request_id
			OPTION (HASH GROUP);

			--Disable unnecessary autostats on the table
			CREATE STATISTICS s_database_name ON #locks (database_name)
			WITH SAMPLE 0 ROWS, NORECOMPUTE;
			CREATE STATISTICS s_object_id ON #locks (object_id)
			WITH SAMPLE 0 ROWS, NORECOMPUTE;
			CREATE STATISTICS s_hobt_id ON #locks (hobt_id)
			WITH SAMPLE 0 ROWS, NORECOMPUTE;
			CREATE STATISTICS s_allocation_unit_id ON #locks (allocation_unit_id)
			WITH SAMPLE 0 ROWS, NORECOMPUTE;
			CREATE STATISTICS s_index_id ON #locks (index_id)
			WITH SAMPLE 0 ROWS, NORECOMPUTE;
			CREATE STATISTICS s_schema_id ON #locks (schema_id)
			WITH SAMPLE 0 ROWS, NORECOMPUTE;
			CREATE STATISTICS s_principal_id ON #locks (principal_id)
			WITH SAMPLE 0 ROWS, NORECOMPUTE;
			CREATE STATISTICS s_request_id ON #locks (request_id)
			WITH SAMPLE 0 ROWS, NORECOMPUTE;
			CREATE STATISTICS s_start_time ON #locks (start_time)
			WITH SAMPLE 0 ROWS, NORECOMPUTE;
			CREATE STATISTICS s_resource_type ON #locks (resource_type)
			WITH SAMPLE 0 ROWS, NORECOMPUTE;
			CREATE STATISTICS s_object_name ON #locks (object_name)
			WITH SAMPLE 0 ROWS, NORECOMPUTE;
			CREATE STATISTICS s_schema_name ON #locks (schema_name)
			WITH SAMPLE 0 ROWS, NORECOMPUTE;
			CREATE STATISTICS s_page_type ON #locks (page_type)
			WITH SAMPLE 0 ROWS, NORECOMPUTE;
			CREATE STATISTICS s_request_mode ON #locks (request_mode)
			WITH SAMPLE 0 ROWS, NORECOMPUTE;
			CREATE STATISTICS s_request_status ON #locks (request_status)
			WITH SAMPLE 0 ROWS, NORECOMPUTE;
			CREATE STATISTICS s_resource_description ON #locks (resource_description)
			WITH SAMPLE 0 ROWS, NORECOMPUTE;
			CREATE STATISTICS s_index_name ON #locks (index_name)
			WITH SAMPLE 0 ROWS, NORECOMPUTE;
			CREATE STATISTICS s_principal_name ON #locks (principal_name)
			WITH SAMPLE 0 ROWS, NORECOMPUTE;
		END;
		
		DECLARE 
			@sql VARCHAR(MAX), 
			@sql_n NVARCHAR(MAX);

		SET @sql = 
			CONVERT(VARCHAR(MAX), '') +
			'DECLARE @blocker BIT;
			SET @blocker = 0;
			DECLARE @i INT;
			SET @i = 2147483647;

			DECLARE @sessions TABLE
			(
				session_id SMALLINT NOT NULL,
				request_id INT NOT NULL,
				login_time DATETIME,
				last_request_end_time DATETIME,
				status VARCHAR(30),
				statement_start_offset INT,
				statement_end_offset INT,
				sql_handle BINARY(20),
				host_name NVARCHAR(128),
				login_name NVARCHAR(128),
				program_name NVARCHAR(128),
				database_id SMALLINT,
				memory_usage INT,
				open_tran_count SMALLINT, 
				' +
				CASE
					WHEN 
					(
						@get_task_info <> 0 
						OR @find_block_leaders = 1 
					) THEN
						'wait_type NVARCHAR(32),
						wait_resource NVARCHAR(256),
						wait_time BIGINT, 
						'
					ELSE 
						''
				END +
				'blocked SMALLINT,
				is_user_process BIT,
				cmd VARCHAR(32),
				PRIMARY KEY CLUSTERED (session_id, request_id) WITH (IGNORE_DUP_KEY = ON)
			);

			DECLARE @blockers TABLE
			(
				session_id INT NOT NULL PRIMARY KEY
			);

			BLOCKERS:;

			INSERT @sessions
			(
				session_id,
				request_id,
				login_time,
				last_request_end_time,
				status,
				statement_start_offset,
				statement_end_offset,
				sql_handle,
				host_name,
				login_name,
				program_name,
				database_id,
				memory_usage,
				open_tran_count, 
				' +
				CASE
					WHEN 
					(
						@get_task_info <> 0
						OR @find_block_leaders = 1 
					) THEN
						'wait_type,
						wait_resource,
						wait_time, 
						'
					ELSE
						''
				END +
				'blocked,
				is_user_process,
				cmd 
			)
			SELECT TOP(@i)
				spy.session_id,
				spy.request_id,
				spy.login_time,
				spy.last_request_end_time,
				spy.status,
				spy.statement_start_offset,
				spy.statement_end_offset,
				spy.sql_handle,
				spy.host_name,
				spy.login_name,
				spy.program_name,
				spy.database_id,
				spy.memory_usage,
				spy.open_tran_count,
				' +
				CASE
					WHEN 
					(
						@get_task_info <> 0  
						OR @find_block_leaders = 1 
					) THEN
						'spy.wait_type,
						CASE
							WHEN
								spy.wait_type LIKE N''PAGE%LATCH_%''
								OR spy.wait_type = N''CXPACKET''
								OR spy.wait_type LIKE N''LATCH[_]%''
								OR spy.wait_type = N''OLEDB'' THEN
									spy.wait_resource
							ELSE
								NULL
						END AS wait_resource,
						spy.wait_time, 
						'
					ELSE
						''
				END +
				'spy.blocked,
				spy.is_user_process,
				spy.cmd
			FROM
			(
				SELECT TOP(@i)
					spx.*, 
					' +
					CASE
						WHEN 
						(
							@get_task_info <> 0 
							OR @find_block_leaders = 1 
						) THEN
							'ROW_NUMBER() OVER
							(
								PARTITION BY
									spx.session_id,
									spx.request_id
								ORDER BY
									CASE
										WHEN spx.wait_type LIKE N''LCK[_]%'' THEN 
											1
										ELSE
											99
									END,
									spx.wait_time DESC,
									spx.blocked DESC
							) AS r 
							'
						ELSE 
							'1 AS r 
							'
					END +
				'FROM
				(
					SELECT TOP(@i)
						sp0.session_id,
						sp0.request_id,
						sp0.login_time,
						sp0.last_request_end_time,
						LOWER(sp0.status) AS status,
						CASE
							WHEN sp0.cmd = ''CREATE INDEX'' THEN
								0
							ELSE
								sp0.stmt_start
						END AS statement_start_offset,
						CASE
							WHEN sp0.cmd = N''CREATE INDEX'' THEN
								-1
							ELSE
								COALESCE(NULLIF(sp0.stmt_end, 0), -1)
						END AS statement_end_offset,
						sp0.sql_handle,
						sp0.host_name,
						sp0.login_name,
						sp0.program_name,
						sp0.database_id,
						sp0.memory_usage,
						sp0.open_tran_count, 
						' +
						CASE
							WHEN 
							(
								@get_task_info <> 0 
								OR @find_block_leaders = 1 
							) THEN
								'CASE
									WHEN sp0.wait_time > 0 AND sp0.wait_type <> N''CXPACKET'' THEN
										sp0.wait_type
									ELSE
										NULL
								END AS wait_type,
								CASE
									WHEN sp0.wait_time > 0 AND sp0.wait_type <> N''CXPACKET'' THEN 
										sp0.wait_resource
									ELSE
										NULL
								END AS wait_resource,
								CASE
									WHEN sp0.wait_type <> N''CXPACKET'' THEN
										sp0.wait_time
									ELSE
										0
								END AS wait_time, 
								'
							ELSE
								''
						END +
						'sp0.blocked,
						sp0.is_user_process,
						sp0.cmd
					FROM
					(
						SELECT TOP(@i)
							sp1.session_id,
							sp1.request_id,
							sp1.login_time,
							sp1.last_request_end_time,
							sp1.status,
							sp1.cmd,
							sp1.stmt_start,
							sp1.stmt_end,
							MAX(NULLIF(sp1.sql_handle, 0x00)) OVER (PARTITION BY sp1.session_id, sp1.request_id) AS sql_handle,
							sp1.host_name,
							MAX(sp1.login_name) OVER (PARTITION BY sp1.session_id, sp1.request_id) AS login_name,
							sp1.program_name,
							sp1.database_id,
							MAX(sp1.memory_usage)  OVER (PARTITION BY sp1.session_id, sp1.request_id) AS memory_usage,
							MAX(sp1.open_tran_count)  OVER (PARTITION BY sp1.session_id, sp1.request_id) AS open_tran_count,
							sp1.wait_type,
							sp1.wait_resource,
							sp1.wait_time,
							sp1.blocked,
							sp1.hostprocess,
							sp1.is_user_process
						FROM
						(
							SELECT TOP(@i)
								sp2.spid AS session_id,
								CASE sp2.status
									WHEN ''sleeping'' THEN
										CONVERT(INT, 0)
									ELSE
										sp2.request_id
								END AS request_id,
								MAX(sp2.login_time) AS login_time,
								MAX(sp2.last_batch) AS last_request_end_time,
								MAX(CONVERT(VARCHAR(30), RTRIM(sp2.status)) COLLATE Latin1_General_Bin2) AS status,
								MAX(CONVERT(VARCHAR(32), RTRIM(sp2.cmd)) COLLATE Latin1_General_Bin2) AS cmd,
								MAX(sp2.stmt_start) AS stmt_start,
								MAX(sp2.stmt_end) AS stmt_end,
								MAX(sp2.sql_handle) AS sql_handle,
								MAX(CONVERT(sysname, RTRIM(sp2.hostname)) COLLATE SQL_Latin1_General_CP1_CI_AS) AS host_name,
								MAX(CONVERT(sysname, RTRIM(sp2.loginame)) COLLATE SQL_Latin1_General_CP1_CI_AS) AS login_name,
								MAX
								(
									CASE
										WHEN blk.queue_id IS NOT NULL THEN
											N''Service Broker
												database_id: '' + CONVERT(NVARCHAR, blk.database_id) +
												N'' queue_id: '' + CONVERT(NVARCHAR, blk.queue_id)
										ELSE
											CONVERT
											(
												sysname,
												RTRIM(sp2.program_name)
											)
									END COLLATE SQL_Latin1_General_CP1_CI_AS
								) AS program_name,
								MAX(sp2.dbid) AS database_id,
								MAX(sp2.memusage) AS memory_usage,
								MAX(sp2.open_tran) AS open_tran_count,
								RTRIM(sp2.lastwaittype) AS wait_type,
								RTRIM(sp2.waitresource) AS wait_resource,
								MAX(sp2.waittime) AS wait_time,
								COALESCE(NULLIF(sp2.blocked, sp2.spid), 0) AS blocked,
								MAX
								(
									CASE
										WHEN blk.session_id = sp2.spid THEN
											''blocker''
										ELSE
											RTRIM(sp2.hostprocess)
									END
								) AS hostprocess,
								CONVERT
								(
									BIT,
									MAX
									(
										CASE
											WHEN sp2.hostprocess > '''' THEN
												1
											ELSE
												0
										END
									)
								) AS is_user_process
							FROM
							(
								SELECT TOP(@i)
									session_id,
									CONVERT(INT, NULL) AS queue_id,
									CONVERT(INT, NULL) AS database_id
								FROM @blockers

								UNION ALL

								SELECT TOP(@i)
									CONVERT(SMALLINT, 0),
									CONVERT(INT, NULL) AS queue_id,
									CONVERT(INT, NULL) AS database_id
								WHERE
									@blocker = 0

								UNION ALL

								SELECT TOP(@i)
									CONVERT(SMALLINT, spid),
									queue_id,
									database_id
								FROM sys.dm_broker_activated_tasks
								WHERE
									@blocker = 0
							) AS blk
							INNER JOIN sys.sysprocesses AS sp2 ON
								sp2.spid = blk.session_id
								OR
								(
									blk.session_id = 0
									AND @blocker = 0
								)
							' +
							CASE 
								WHEN 
								(
									@get_task_info = 0 
									AND @find_block_leaders = 0
								) THEN
									'WHERE
										sp2.ecid = 0 
									' 
								ELSE
									''
							END +
							'GROUP BY
								sp2.spid,
								CASE sp2.status
									WHEN ''sleeping'' THEN
										CONVERT(INT, 0)
									ELSE
										sp2.request_id
								END,
								RTRIM(sp2.lastwaittype),
								RTRIM(sp2.waitresource),
								COALESCE(NULLIF(sp2.blocked, sp2.spid), 0)
						) AS sp1
					) AS sp0
					WHERE
						@blocker = 1
						OR
						(1=1 
						' +
							--inclusive filter
							CASE
								WHEN @filter <> '' THEN
									CASE @filter_type
										WHEN 'session' THEN
											CASE
												WHEN CONVERT(SMALLINT, @filter) <> 0 THEN
													'AND sp0.session_id = CONVERT(SMALLINT, @filter) 
													'
												ELSE
													''
											END
										WHEN 'program' THEN
											'AND sp0.program_name LIKE @filter 
											'
										WHEN 'login' THEN
											'AND sp0.login_name LIKE @filter 
											'
										WHEN 'host' THEN
											'AND sp0.host_name LIKE @filter 
											'
										WHEN 'database' THEN
											'AND DB_NAME(sp0.database_id) LIKE @filter 
											'
										ELSE
											''
									END
								ELSE
									''
							END +
							--exclusive filter
							CASE
								WHEN @not_filter <> '' THEN
									CASE @not_filter_type
										WHEN 'session' THEN
											CASE
												WHEN CONVERT(SMALLINT, @not_filter) <> 0 THEN
													'AND sp0.session_id <> CONVERT(SMALLINT, @not_filter) 
													'
												ELSE
													''
											END
										WHEN 'program' THEN
											'AND sp0.program_name NOT LIKE @not_filter 
											'
										WHEN 'login' THEN
											'AND sp0.login_name NOT LIKE @not_filter 
											'
										WHEN 'host' THEN
											'AND sp0.host_name NOT LIKE @not_filter 
											'
										WHEN 'database' THEN
											'AND DB_NAME(sp0.database_id) NOT LIKE @not_filter 
											'
										ELSE
											''
									END
								ELSE
									''
							END +
							CASE @show_own_spid
								WHEN 1 THEN
									''
								ELSE
									'AND sp0.session_id <> @@spid 
									'
							END +
							CASE 
								WHEN @show_system_spids = 0 THEN
									'AND sp0.hostprocess > '''' 
									' 
								ELSE
									''
							END +
							CASE @show_sleeping_spids
								WHEN 0 THEN
									'AND sp0.status <> ''sleeping'' 
									'
								WHEN 1 THEN
									'AND
									(
										sp0.status <> ''sleeping''
										OR sp0.open_tran_count > 0
									)
									'
								ELSE
									''
							END +
						')
				) AS spx
			) AS spy
			WHERE
				spy.r = 1; 
			' + 
			CASE @recursion
				WHEN 1 THEN 
					'IF @@ROWCOUNT > 0
					BEGIN;
						INSERT @blockers
						(
							session_id
						)
						SELECT TOP(@i)
							blocked
						FROM @sessions
						WHERE
							NULLIF(blocked, 0) IS NOT NULL

						EXCEPT

						SELECT TOP(@i)
							session_id
						FROM @sessions; 
						' +

						CASE
							WHEN
							(
								@get_task_info > 0
								OR @find_block_leaders = 1
							) THEN
								'IF @@ROWCOUNT > 0
								BEGIN;
									SET @blocker = 1;
									GOTO BLOCKERS;
								END; 
								'
							ELSE 
								''
						END +
					'END; 
					'
				ELSE 
					''
			END +
			'SELECT TOP(@i)
				@recursion AS recursion,
				x.session_id,
				x.request_id,
				DENSE_RANK() OVER
				(
					ORDER BY
						x.session_id
				) AS session_number,
				' +
				CASE
					WHEN @output_column_list LIKE '%|[dd hh:mm:ss.mss|]%' ESCAPE '|' THEN 
						'x.elapsed_time '
					ELSE 
						'0 '
				END + 
					'AS elapsed_time, 
					' +
				CASE
					WHEN
						(
							@output_column_list LIKE '%|[dd hh:mm:ss.mss (avg)|]%' ESCAPE '|' OR 
							@output_column_list LIKE '%|[avg_elapsed_time|]%' ESCAPE '|'
						)
						AND @recursion = 1
							THEN 
								'x.avg_elapsed_time / 1000 '
					ELSE 
						'NULL '
				END + 
					'AS avg_elapsed_time, 
					' +
				CASE
					WHEN 
						@output_column_list LIKE '%|[physical_io|]%' ESCAPE '|'
						OR @output_column_list LIKE '%|[physical_io_delta|]%' ESCAPE '|'
							THEN 
								'x.physical_io '
					ELSE 
						'NULL '
				END + 
					'AS physical_io, 
					' +
				CASE
					WHEN 
						@output_column_list LIKE '%|[reads|]%' ESCAPE '|'
						OR @output_column_list LIKE '%|[reads_delta|]%' ESCAPE '|'
							THEN 
								'x.reads '
					ELSE 
						'0 '
				END + 
					'AS reads, 
					' +
				CASE
					WHEN 
						@output_column_list LIKE '%|[physical_reads|]%' ESCAPE '|'
						OR @output_column_list LIKE '%|[physical_reads_delta|]%' ESCAPE '|'
							THEN 
								'x.physical_reads '
					ELSE 
						'0 '
				END + 
					'AS physical_reads, 
					' +
				CASE
					WHEN 
						@output_column_list LIKE '%|[writes|]%' ESCAPE '|'
						OR @output_column_list LIKE '%|[writes_delta|]%' ESCAPE '|'
							THEN 
								'x.writes '
					ELSE 
						'0 '
				END + 
					'AS writes, 
					' +
				CASE
					WHEN 
						@output_column_list LIKE '%|[tempdb_allocations|]%' ESCAPE '|'
						OR @output_column_list LIKE '%|[tempdb_allocations_delta|]%' ESCAPE '|'
							THEN 
								'x.tempdb_allocations '
					ELSE 
						'0 '
				END + 
					'AS tempdb_allocations, 
					' +
				CASE
					WHEN 
						@output_column_list LIKE '%|[tempdb_current|]%' ESCAPE '|'
						OR @output_column_list LIKE '%|[tempdb_current_delta|]%' ESCAPE '|'
							THEN 
								'x.tempdb_current '
					ELSE 
						'0 '
				END + 
					'AS tempdb_current, 
					' +
				CASE
					WHEN 
						@output_column_list LIKE '%|[CPU|]%' ESCAPE '|'
						OR @output_column_list LIKE '%|[CPU_delta|]%' ESCAPE '|'
							THEN
								'x.CPU '
					ELSE
						'0 '
				END + 
					'AS CPU, 
					' +
				CASE
					WHEN 
						@output_column_list LIKE '%|[CPU_delta|]%' ESCAPE '|'
						AND @get_task_info = 2
							THEN 
								'x.thread_CPU_snapshot '
					ELSE 
						'0 '
				END + 
					'AS thread_CPU_snapshot, 
					' +
				CASE
					WHEN 
						@output_column_list LIKE '%|[context_switches|]%' ESCAPE '|'
						OR @output_column_list LIKE '%|[context_switches_delta|]%' ESCAPE '|'
							THEN 
								'x.context_switches '
					ELSE 
						'NULL '
				END + 
					'AS context_switches, 
					' +
				CASE
					WHEN 
						@output_column_list LIKE '%|[used_memory|]%' ESCAPE '|'
						OR @output_column_list LIKE '%|[used_memory_delta|]%' ESCAPE '|'
							THEN 
								'x.used_memory '
					ELSE 
						'0 '
				END + 
					'AS used_memory, 
					' +
				CASE
					WHEN 
						@output_column_list LIKE '%|[tasks|]%' ESCAPE '|'
						AND @recursion = 1
							THEN 
								'x.tasks '
					ELSE 
						'NULL '
				END + 
					'AS tasks, 
					' +
				CASE
					WHEN 
						(
							@output_column_list LIKE '%|[status|]%' ESCAPE '|' 
							OR @output_column_list LIKE '%|[sql_command|]%' ESCAPE '|'
						)
						AND @recursion = 1
							THEN 
								'x.status '
					ELSE 
						''''' '
				END + 
					'AS status, 
					' +
				CASE
					WHEN 
						@output_column_list LIKE '%|[wait_info|]%' ESCAPE '|' 
						AND @recursion = 1
							THEN 
								CASE @get_task_info
									WHEN 2 THEN
										'COALESCE(x.task_wait_info, x.sys_wait_info) '
									ELSE
										'x.sys_wait_info '
								END
					ELSE 
						'NULL '
				END + 
					'AS wait_info, 
					' +
				CASE
					WHEN 
						(
							@output_column_list LIKE '%|[tran_start_time|]%' ESCAPE '|' 
							OR @output_column_list LIKE '%|[tran_log_writes|]%' ESCAPE '|' 
						)
						AND @recursion = 1
							THEN 
								'x.transaction_id '
					ELSE 
						'NULL '
				END + 
					'AS transaction_id, 
					' +
				CASE
					WHEN 
						@output_column_list LIKE '%|[open_tran_count|]%' ESCAPE '|' 
						AND @recursion = 1
							THEN 
								'x.open_tran_count '
					ELSE 
						'NULL '
				END + 
					'AS open_tran_count, 
					' +
				CASE
					WHEN 
						@output_column_list LIKE '%|[sql_text|]%' ESCAPE '|' 
						AND @recursion = 1
							THEN 
								'x.sql_handle '
					ELSE 
						'NULL '
				END + 
					'AS sql_handle, 
					' +
				CASE
					WHEN 
						(
							@output_column_list LIKE '%|[sql_text|]%' ESCAPE '|' 
							OR @output_column_list LIKE '%|[query_plan|]%' ESCAPE '|' 
						)
						AND @recursion = 1
							THEN 
								'x.statement_start_offset '
					ELSE 
						'NULL '
				END + 
					'AS statement_start_offset, 
					' +
				CASE
					WHEN 
						(
							@output_column_list LIKE '%|[sql_text|]%' ESCAPE '|' 
							OR @output_column_list LIKE '%|[query_plan|]%' ESCAPE '|' 
						)
						AND @recursion = 1
							THEN 
								'x.statement_end_offset '
					ELSE 
						'NULL '
				END + 
					'AS statement_end_offset, 
					' +
				'NULL AS sql_text, 
					' +
				CASE
					WHEN 
						@output_column_list LIKE '%|[query_plan|]%' ESCAPE '|' 
						AND @recursion = 1
							THEN 
								'x.plan_handle '
					ELSE 
						'NULL '
				END + 
					'AS plan_handle, 
					' +
				CASE
					WHEN 
						@output_column_list LIKE '%|[blocking_session_id|]%' ESCAPE '|' 
						AND @recursion = 1
							THEN 
								'NULLIF(x.blocking_session_id, 0) '
					ELSE 
						'NULL '
				END + 
					'AS blocking_session_id, 
					' +
				CASE
					WHEN 
						@output_column_list LIKE '%|[percent_complete|]%' ESCAPE '|'
						AND @recursion = 1
							THEN 
								'x.percent_complete '
					ELSE 
						'NULL '
				END + 
					'AS percent_complete, 
					' +
				CASE
					WHEN 
						@output_column_list LIKE '%|[host_name|]%' ESCAPE '|' 
						AND @recursion = 1
							THEN 
								'x.host_name '
					ELSE 
						''''' '
				END + 
					'AS host_name, 
					' +
				CASE
					WHEN 
						@output_column_list LIKE '%|[login_name|]%' ESCAPE '|' 
						AND @recursion = 1
							THEN 
								'x.login_name '
					ELSE 
						''''' '
				END + 
					'AS login_name, 
					' +
				CASE
					WHEN 
						@output_column_list LIKE '%|[database_name|]%' ESCAPE '|' 
						AND @recursion = 1
							THEN 
								'DB_NAME(x.database_id) '
					ELSE 
						'NULL '
				END + 
					'AS database_name, 
					' +
				CASE
					WHEN 
						@output_column_list LIKE '%|[program_name|]%' ESCAPE '|' 
						AND @recursion = 1
							THEN 
								'x.program_name '
					ELSE 
						''''' '
				END + 
					'AS program_name, 
					' +
				CASE
					WHEN
						@output_column_list LIKE '%|[additional_info|]%' ESCAPE '|'
						AND @recursion = 1
							THEN
								'(
									SELECT TOP(@i)
										x.text_size,
										x.language,
										x.date_format,
										x.date_first,
										CASE x.quoted_identifier
											WHEN 0 THEN ''OFF''
											WHEN 1 THEN ''ON''
										END AS quoted_identifier,
										CASE x.arithabort
											WHEN 0 THEN ''OFF''
											WHEN 1 THEN ''ON''
										END AS arithabort,
										CASE x.ansi_null_dflt_on
											WHEN 0 THEN ''OFF''
											WHEN 1 THEN ''ON''
										END AS ansi_null_dflt_on,
										CASE x.ansi_defaults
											WHEN 0 THEN ''OFF''
											WHEN 1 THEN ''ON''
										END AS ansi_defaults,
										CASE x.ansi_warnings
											WHEN 0 THEN ''OFF''
											WHEN 1 THEN ''ON''
										END AS ansi_warnings,
										CASE x.ansi_padding
											WHEN 0 THEN ''OFF''
											WHEN 1 THEN ''ON''
										END AS ansi_padding,
										CASE ansi_nulls
											WHEN 0 THEN ''OFF''
											WHEN 1 THEN ''ON''
										END AS ansi_nulls,
										CASE x.concat_null_yields_null
											WHEN 0 THEN ''OFF''
											WHEN 1 THEN ''ON''
										END AS concat_null_yields_null,
										CASE x.transaction_isolation_level
											WHEN 0 THEN ''Unspecified''
											WHEN 1 THEN ''ReadUncomitted''
											WHEN 2 THEN ''ReadCommitted''
											WHEN 3 THEN ''Repeatable''
											WHEN 4 THEN ''Serializable''
											WHEN 5 THEN ''Snapshot''
										END AS transaction_isolation_level,
										x.lock_timeout,
										x.deadlock_priority,
										x.row_count,
										x.command_type, 
										' +
										CASE
											WHEN @output_column_list LIKE '%|[program_name|]%' ESCAPE '|' THEN
												'(
													SELECT TOP(1)
														CONVERT(uniqueidentifier, CONVERT(XML, '''').value(''xs:hexBinary( substring(sql:column("agent_info.job_id_string"), 0) )'', ''binary(16)'')) AS job_id,
														agent_info.step_id,
														(
															SELECT TOP(1)
																NULL
															FOR XML
																PATH(''job_name''),
																TYPE
														),
														(
															SELECT TOP(1)
																NULL
															FOR XML
																PATH(''step_name''),
																TYPE
														)
													FROM
													(
														SELECT TOP(1)
															SUBSTRING(x.program_name, CHARINDEX(''0x'', x.program_name) + 2, 32) AS job_id_string,
															SUBSTRING(x.program_name, CHARINDEX('': Step '', x.program_name) + 7, CHARINDEX('')'', x.program_name, CHARINDEX('': Step '', x.program_name)) - (CHARINDEX('': Step '', x.program_name) + 7)) AS step_id
														WHERE
															x.program_name LIKE N''SQLAgent - TSQL JobStep (Job 0x%''
													) AS agent_info
													FOR XML
														PATH(''agent_job_info''),
														TYPE
												),
												'
											ELSE ''
										END +
										CASE
											WHEN @get_task_info = 2 THEN
												'CONVERT(XML, x.block_info) AS block_info, 
												'
											ELSE
												''
										END +
										'x.host_process_id 
									FOR XML
										PATH(''additional_info''),
										TYPE
								) '
					ELSE
						'NULL '
				END + 
					'AS additional_info, 
				x.start_time, 
					' +
				CASE
					WHEN
						@output_column_list LIKE '%|[login_time|]%' ESCAPE '|'
						AND @recursion = 1
							THEN
								'x.login_time '
					ELSE 
						'NULL '
				END + 
					'AS login_time, 
				x.last_request_start_time
			FROM
			(
				SELECT TOP(@i)
					y.*,
					CASE
						WHEN DATEDIFF(day, y.start_time, GETDATE()) > 24 THEN
							DATEDIFF(second, GETDATE(), y.start_time)
						ELSE DATEDIFF(ms, y.start_time, GETDATE())
					END AS elapsed_time,
					COALESCE(tempdb_info.tempdb_allocations, 0) AS tempdb_allocations,
					COALESCE
					(
						CASE
							WHEN tempdb_info.tempdb_current < 0 THEN 0
							ELSE tempdb_info.tempdb_current
						END,
						0
					) AS tempdb_current, 
					' +
					CASE
						WHEN 
							(
								@get_task_info <> 0
								OR @find_block_leaders = 1
							) THEN
								'N''('' + CONVERT(NVARCHAR, y.wait_duration_ms) + N''ms)'' +
									y.wait_type +
										CASE
											WHEN y.wait_type LIKE N''PAGE%LATCH_%'' THEN
												N'':'' +
												COALESCE(DB_NAME(CONVERT(INT, LEFT(y.resource_description, CHARINDEX(N'':'', y.resource_description) - 1))), N''(null)'') +
												N'':'' +
												SUBSTRING(y.resource_description, CHARINDEX(N'':'', y.resource_description) + 1, LEN(y.resource_description) - CHARINDEX(N'':'', REVERSE(y.resource_description)) - CHARINDEX(N'':'', y.resource_description)) +
												N''('' +
													CASE
														WHEN
															CONVERT(INT, RIGHT(y.resource_description, CHARINDEX(N'':'', REVERSE(y.resource_description)) - 1)) = 1 OR
															CONVERT(INT, RIGHT(y.resource_description, CHARINDEX(N'':'', REVERSE(y.resource_description)) - 1)) % 8088 = 0
																THEN 
																	N''PFS''
														WHEN
															CONVERT(INT, RIGHT(y.resource_description, CHARINDEX(N'':'', REVERSE(y.resource_description)) - 1)) = 2 OR
															CONVERT(INT, RIGHT(y.resource_description, CHARINDEX(N'':'', REVERSE(y.resource_description)) - 1)) % 511232 = 0
																THEN 
																	N''GAM''
														WHEN
															CONVERT(INT, RIGHT(y.resource_description, CHARINDEX(N'':'', REVERSE(y.resource_description)) - 1)) = 3 OR
															CONVERT(INT, RIGHT(y.resource_description, CHARINDEX(N'':'', REVERSE(y.resource_description)) - 1)) % 511233 = 0
																THEN
																	N''SGAM''
														WHEN
															CONVERT(INT, RIGHT(y.resource_description, CHARINDEX(N'':'', REVERSE(y.resource_description)) - 1)) = 6 OR
															CONVERT(INT, RIGHT(y.resource_description, CHARINDEX(N'':'', REVERSE(y.resource_description)) - 1)) % 511238 = 0 
																THEN 
																	N''DCM''
														WHEN
															CONVERT(INT, RIGHT(y.resource_description, CHARINDEX(N'':'', REVERSE(y.resource_description)) - 1)) = 7 OR
															CONVERT(INT, RIGHT(y.resource_description, CHARINDEX(N'':'', REVERSE(y.resource_description)) - 1)) % 511239 = 0 
																THEN 
																	N''BCM''
														ELSE 
															N''*''
													END +
												N'')''
											WHEN y.wait_type = N''CXPACKET'' THEN
												N'':'' + SUBSTRING(y.resource_description, CHARINDEX(N''nodeId'', y.resource_description) + 7, 4)
											WHEN y.wait_type LIKE N''LATCH[_]%'' THEN
												N'' ['' + LEFT(y.resource_description, COALESCE(NULLIF(CHARINDEX(N'' '', y.resource_description), 0), LEN(y.resource_description) + 1) - 1) + N'']''
											WHEN
												y.wait_type = N''OLEDB''
												AND y.resource_description LIKE N''%(SPID=%)'' THEN
													N''['' + LEFT(y.resource_description, CHARINDEX(N''(SPID='', y.resource_description) - 2) +
														N'':'' + SUBSTRING(y.resource_description, CHARINDEX(N''(SPID='', y.resource_description) + 6, CHARINDEX(N'')'', y.resource_description, (CHARINDEX(N''(SPID='', y.resource_description) + 6)) - (CHARINDEX(N''(SPID='', y.resource_description) + 6)) + '']''
											ELSE
												N''''
										END COLLATE Latin1_General_Bin2 AS sys_wait_info, 
										'
							ELSE
								''
						END +
						CASE
							WHEN @get_task_info = 2 THEN
								'tasks.physical_io,
								tasks.context_switches,
								tasks.tasks,
								tasks.block_info,
								tasks.wait_info AS task_wait_info,
								tasks.thread_CPU_snapshot,
								'
							ELSE
								'' 
					END +
					CASE 
						WHEN NOT (@get_avg_time = 1 AND @recursion = 1) THEN
							'CONVERT(INT, NULL) '
						ELSE 
							'qs.total_elapsed_time / qs.execution_count '
					END + 
						'AS avg_elapsed_time 
				FROM
				(
					SELECT TOP(@i)
						sp.session_id,
						sp.request_id,
						COALESCE(r.logical_reads, s.logical_reads) AS reads,
						COALESCE(r.reads, s.reads) AS physical_reads,
						COALESCE(r.writes, s.writes) AS writes,
						COALESCE(r.CPU_time, s.CPU_time) AS CPU,
						sp.memory_usage + COALESCE(r.granted_query_memory, 0) AS used_memory,
						LOWER(sp.status) AS status,
						COALESCE(r.sql_handle, sp.sql_handle) AS sql_handle,
						COALESCE(r.statement_start_offset, sp.statement_start_offset) AS statement_start_offset,
						COALESCE(r.statement_end_offset, sp.statement_end_offset) AS statement_end_offset,
						' +
						CASE
							WHEN 
							(
								@get_task_info <> 0
								OR @find_block_leaders = 1 
							) THEN
								'sp.wait_type COLLATE Latin1_General_Bin2 AS wait_type,
								sp.wait_resource COLLATE Latin1_General_Bin2 AS resource_description,
								sp.wait_time AS wait_duration_ms, 
								'
							ELSE
								''
						END +
						'NULLIF(sp.blocked, 0) AS blocking_session_id,
						r.plan_handle,
						NULLIF(r.percent_complete, 0) AS percent_complete,
						sp.host_name,
						sp.login_name,
						sp.program_name,
						s.host_process_id,
						COALESCE(r.text_size, s.text_size) AS text_size,
						COALESCE(r.language, s.language) AS language,
						COALESCE(r.date_format, s.date_format) AS date_format,
						COALESCE(r.date_first, s.date_first) AS date_first,
						COALESCE(r.quoted_identifier, s.quoted_identifier) AS quoted_identifier,
						COALESCE(r.arithabort, s.arithabort) AS arithabort,
						COALESCE(r.ansi_null_dflt_on, s.ansi_null_dflt_on) AS ansi_null_dflt_on,
						COALESCE(r.ansi_defaults, s.ansi_defaults) AS ansi_defaults,
						COALESCE(r.ansi_warnings, s.ansi_warnings) AS ansi_warnings,
						COALESCE(r.ansi_padding, s.ansi_padding) AS ansi_padding,
						COALESCE(r.ansi_nulls, s.ansi_nulls) AS ansi_nulls,
						COALESCE(r.concat_null_yields_null, s.concat_null_yields_null) AS concat_null_yields_null,
						COALESCE(r.transaction_isolation_level, s.transaction_isolation_level) AS transaction_isolation_level,
						COALESCE(r.lock_timeout, s.lock_timeout) AS lock_timeout,
						COALESCE(r.deadlock_priority, s.deadlock_priority) AS deadlock_priority,
						COALESCE(r.row_count, s.row_count) AS row_count,
						COALESCE(r.command, sp.cmd) AS command_type,
						COALESCE
						(
							CASE
								WHEN
								(
									s.is_user_process = 0
									AND r.total_elapsed_time >= 0
								) THEN
									DATEADD
									(
										ms,
										1000 * (DATEPART(ms, DATEADD(second, -(r.total_elapsed_time / 1000), GETDATE())) / 500) - DATEPART(ms, DATEADD(second, -(r.total_elapsed_time / 1000), GETDATE())),
										DATEADD(second, -(r.total_elapsed_time / 1000), GETDATE())
									)
							END,
							NULLIF(COALESCE(r.start_time, sp.last_request_end_time), CONVERT(DATETIME, ''19000101'', 112)),
							(
								SELECT TOP(1)
									DATEADD(second, -(ms_ticks / 1000), GETDATE())
								FROM sys.dm_os_sys_info
							)
						) AS start_time,
						sp.login_time,
						CASE
							WHEN s.is_user_process = 1 THEN
								s.last_request_start_time
							ELSE
								COALESCE
								(
									DATEADD
									(
										ms,
										1000 * (DATEPART(ms, DATEADD(second, -(r.total_elapsed_time / 1000), GETDATE())) / 500) - DATEPART(ms, DATEADD(second, -(r.total_elapsed_time / 1000), GETDATE())),
										DATEADD(second, -(r.total_elapsed_time / 1000), GETDATE())
									),
									s.last_request_start_time
								)
						END AS last_request_start_time,
						r.transaction_id,
						sp.database_id,
						sp.open_tran_count
					FROM @sessions AS sp
					LEFT OUTER LOOP JOIN sys.dm_exec_sessions AS s ON
						s.session_id = sp.session_id
						AND s.login_time = sp.login_time
					LEFT OUTER LOOP JOIN sys.dm_exec_requests AS r ON
						sp.status <> ''sleeping''
						AND r.session_id = sp.session_id
						AND r.request_id = sp.request_id
						AND
						(
							(
								s.is_user_process = 0
								AND sp.is_user_process = 0
							)
							OR
							(
								r.start_time = s.last_request_start_time
								AND s.last_request_end_time = sp.last_request_end_time
							)
						)
				) AS y
				' + 
				CASE 
					WHEN @get_task_info = 2 THEN
						CONVERT(VARCHAR(MAX), '') +
						'LEFT OUTER HASH JOIN
						(
							SELECT TOP(@i)
								task_nodes.task_node.value(''(session_id/text())[1]'', ''SMALLINT'') AS session_id,
								task_nodes.task_node.value(''(request_id/text())[1]'', ''INT'') AS request_id,
								task_nodes.task_node.value(''(physical_io/text())[1]'', ''BIGINT'') AS physical_io,
								task_nodes.task_node.value(''(context_switches/text())[1]'', ''BIGINT'') AS context_switches,
								task_nodes.task_node.value(''(tasks/text())[1]'', ''INT'') AS tasks,
								task_nodes.task_node.value(''(block_info/text())[1]'', ''NVARCHAR(4000)'') AS block_info,
								task_nodes.task_node.value(''(waits/text())[1]'', ''NVARCHAR(4000)'') AS wait_info,
								task_nodes.task_node.value(''(thread_CPU_snapshot/text())[1]'', ''BIGINT'') AS thread_CPU_snapshot
							FROM
							(
								SELECT TOP(@i)
									CONVERT
									(
										XML,
										REPLACE
										(
											CONVERT(NVARCHAR(MAX), tasks_raw.task_xml_raw) COLLATE Latin1_General_Bin2,
											N''</waits></tasks><tasks><waits>'',
											N'', ''
										)
									) AS task_xml
								FROM
								(
									SELECT TOP(@i)
										CASE waits.r
											WHEN 1 THEN
												waits.session_id
											ELSE
												NULL
										END AS [session_id],
										CASE waits.r
											WHEN 1 THEN
												waits.request_id
											ELSE
												NULL
										END AS [request_id],											
										CASE waits.r
											WHEN 1 THEN
												waits.physical_io
											ELSE
												NULL
										END AS [physical_io],
										CASE waits.r
											WHEN 1 THEN
												waits.context_switches
											ELSE
												NULL
										END AS [context_switches],
										CASE waits.r
											WHEN 1 THEN
												waits.thread_CPU_snapshot
											ELSE
												NULL
										END AS [thread_CPU_snapshot],
										CASE waits.r
											WHEN 1 THEN
												waits.tasks
											ELSE
												NULL
										END AS [tasks],
										CASE waits.r
											WHEN 1 THEN
												waits.block_info
											ELSE
												NULL
										END AS [block_info],
										REPLACE
										(
											REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
											REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
											REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
												CONVERT
												(
													NVARCHAR(MAX),
													N''('' +
														CONVERT(NVARCHAR, num_waits) + N''x: '' +
														CASE num_waits
															WHEN 1 THEN
																CONVERT(NVARCHAR, min_wait_time) + N''ms''
															WHEN 2 THEN
																CASE
																	WHEN min_wait_time <> max_wait_time THEN
																		CONVERT(NVARCHAR, min_wait_time) + N''/'' + CONVERT(NVARCHAR, max_wait_time) + N''ms''
																	ELSE
																		CONVERT(NVARCHAR, max_wait_time) + N''ms''
																END
															ELSE
																CASE
																	WHEN min_wait_time <> max_wait_time THEN
																		CONVERT(NVARCHAR, min_wait_time) + N''/'' + CONVERT(NVARCHAR, avg_wait_time) + N''/'' + CONVERT(NVARCHAR, max_wait_time) + N''ms''
																	ELSE 
																		CONVERT(NVARCHAR, max_wait_time) + N''ms''
																END
														END +
													N'')'' + wait_type COLLATE Latin1_General_Bin2
												),
												NCHAR(31),N''?''),NCHAR(30),N''?''),NCHAR(29),N''?''),NCHAR(28),N''?''),NCHAR(27),N''?''),NCHAR(26),N''?''),NCHAR(25),N''?''),NCHAR(24),N''?''),NCHAR(23),N''?''),NCHAR(22),N''?''),
												NCHAR(21),N''?''),NCHAR(20),N''?''),NCHAR(19),N''?''),NCHAR(18),N''?''),NCHAR(17),N''?''),NCHAR(16),N''?''),NCHAR(15),N''?''),NCHAR(14),N''?''),NCHAR(12),N''?''),
												NCHAR(11),N''?''),NCHAR(8),N''?''),NCHAR(7),N''?''),NCHAR(6),N''?''),NCHAR(5),N''?''),NCHAR(4),N''?''),NCHAR(3),N''?''),NCHAR(2),N''?''),NCHAR(1),N''?''),
											NCHAR(0),
											N''''
										) AS [waits]
									FROM
									(
										SELECT TOP(@i)
											w1.*,
											ROW_NUMBER() OVER
											(
												PARTITION BY
													w1.session_id,
													w1.request_id
												ORDER BY
													w1.block_info DESC,
													w1.num_waits DESC,
													w1.wait_type
											) AS r
										FROM
										(
											SELECT TOP(@i)
												task_info.session_id,
												task_info.request_id,
												task_info.physical_io,
												task_info.context_switches,
												task_info.thread_CPU_snapshot,
												task_info.num_tasks AS tasks,
												CASE
													WHEN task_info.runnable_time IS NOT NULL THEN
														''RUNNABLE''
													ELSE
														wt2.wait_type
												END AS wait_type,
												NULLIF(COUNT(COALESCE(task_info.runnable_time, wt2.waiting_task_address)), 0) AS num_waits,
												MIN(COALESCE(task_info.runnable_time, wt2.wait_duration_ms)) AS min_wait_time,
												AVG(COALESCE(task_info.runnable_time, wt2.wait_duration_ms)) AS avg_wait_time,
												MAX(COALESCE(task_info.runnable_time, wt2.wait_duration_ms)) AS max_wait_time,
												MAX(wt2.block_info) AS block_info
											FROM
											(
												SELECT TOP(@i)
													t.session_id,
													t.request_id,
													SUM(CONVERT(BIGINT, t.pending_io_count)) OVER (PARTITION BY t.session_id, t.request_id) AS physical_io,
													SUM(CONVERT(BIGINT, t.context_switches_count)) OVER (PARTITION BY t.session_id, t.request_id) AS context_switches, 
													' +
													CASE
														WHEN @output_column_list LIKE '%|[CPU_delta|]%' ESCAPE '|'
															THEN
																'SUM(tr.usermode_time + tr.kernel_time) OVER (PARTITION BY t.session_id, t.request_id) '
														ELSE
															'CONVERT(BIGINT, NULL) '
													END + 
														' AS thread_CPU_snapshot, 
													COUNT(*) OVER (PARTITION BY t.session_id, t.request_id) AS num_tasks,
													t.task_address,
													t.task_state,
													CASE
														WHEN
															t.task_state = ''RUNNABLE''
															AND w.runnable_time > 0 THEN
																w.runnable_time
														ELSE
															NULL
													END AS runnable_time
												FROM sys.dm_os_tasks AS t
												CROSS APPLY
												(
													SELECT TOP(1)
														sp2.session_id
													FROM @sessions AS sp2
													WHERE
														sp2.session_id = t.session_id
														AND sp2.request_id = t.request_id
														AND sp2.status <> ''sleeping''
												) AS sp20
												LEFT OUTER HASH JOIN
												(
													SELECT TOP(@i)
														(
															SELECT TOP(@i)
																ms_ticks
															FROM sys.dm_os_sys_info
														) -
															w0.wait_resumed_ms_ticks AS runnable_time,
														w0.worker_address,
														w0.thread_address,
														w0.task_bound_ms_ticks
													FROM sys.dm_os_workers AS w0
													WHERE
														w0.state = ''RUNNABLE''
														OR @first_collection_ms_ticks >= w0.task_bound_ms_ticks
												) AS w ON
													w.worker_address = t.worker_address 
												' +
												CASE
													WHEN @output_column_list LIKE '%|[CPU_delta|]%' ESCAPE '|'
														THEN
															'LEFT OUTER HASH JOIN sys.dm_os_threads AS tr ON
																tr.thread_address = w.thread_address
																AND @first_collection_ms_ticks >= w.task_bound_ms_ticks
															'
													ELSE
														''
												END +
											') AS task_info
											LEFT OUTER HASH JOIN
											(
												SELECT TOP(@i)
													wt1.wait_type,
													wt1.waiting_task_address,
													MAX(wt1.wait_duration_ms) AS wait_duration_ms,
													MAX(wt1.block_info) AS block_info
												FROM
												(
													SELECT DISTINCT TOP(@i)
														wt.wait_type +
															CASE
																WHEN wt.wait_type LIKE N''PAGE%LATCH_%'' THEN
																	'':'' +
																	COALESCE(DB_NAME(CONVERT(INT, LEFT(wt.resource_description, CHARINDEX(N'':'', wt.resource_description) - 1))), N''(null)'') +
																	N'':'' +
																	SUBSTRING(wt.resource_description, CHARINDEX(N'':'', wt.resource_description) + 1, LEN(wt.resource_description) - CHARINDEX(N'':'', REVERSE(wt.resource_description)) - CHARINDEX(N'':'', wt.resource_description)) +
																	N''('' +
																		CASE
																			WHEN
																				CONVERT(INT, RIGHT(wt.resource_description, CHARINDEX(N'':'', REVERSE(wt.resource_description)) - 1)) = 1 OR
																				CONVERT(INT, RIGHT(wt.resource_description, CHARINDEX(N'':'', REVERSE(wt.resource_description)) - 1)) % 8088 = 0
																					THEN 
																						N''PFS''
																			WHEN
																				CONVERT(INT, RIGHT(wt.resource_description, CHARINDEX(N'':'', REVERSE(wt.resource_description)) - 1)) = 2 OR
																				CONVERT(INT, RIGHT(wt.resource_description, CHARINDEX(N'':'', REVERSE(wt.resource_description)) - 1)) % 511232 = 0 
																					THEN 
																						N''GAM''
																			WHEN
																				CONVERT(INT, RIGHT(wt.resource_description, CHARINDEX(N'':'', REVERSE(wt.resource_description)) - 1)) = 3 OR
																				CONVERT(INT, RIGHT(wt.resource_description, CHARINDEX(N'':'', REVERSE(wt.resource_description)) - 1)) % 511233 = 0 
																					THEN 
																						N''SGAM''
																			WHEN
																				CONVERT(INT, RIGHT(wt.resource_description, CHARINDEX(N'':'', REVERSE(wt.resource_description)) - 1)) = 6 OR
																				CONVERT(INT, RIGHT(wt.resource_description, CHARINDEX(N'':'', REVERSE(wt.resource_description)) - 1)) % 511238 = 0 
																					THEN 
																						N''DCM''
																			WHEN
																				CONVERT(INT, RIGHT(wt.resource_description, CHARINDEX(N'':'', REVERSE(wt.resource_description)) - 1)) = 7 OR
																				CONVERT(INT, RIGHT(wt.resource_description, CHARINDEX(N'':'', REVERSE(wt.resource_description)) - 1)) % 511239 = 0
																					THEN 
																						N''BCM''
																			ELSE
																				N''*''
																		END +
																	N'')''
																WHEN wt.wait_type = N''CXPACKET'' THEN
																	N'':'' + SUBSTRING(wt.resource_description, CHARINDEX(N''nodeId'', wt.resource_description) + 7, 4)
																WHEN wt.wait_type LIKE N''LATCH[_]%'' THEN
																	N'' ['' + LEFT(wt.resource_description, COALESCE(NULLIF(CHARINDEX(N'' '', wt.resource_description), 0), LEN(wt.resource_description) + 1) - 1) + N'']''
																ELSE 
																	N''''
															END COLLATE Latin1_General_Bin2 AS wait_type,
														CASE
															WHEN
															(
																wt.blocking_session_id IS NOT NULL
																AND wt.wait_type LIKE N''LCK[_]%''
															) THEN
																(
																	SELECT TOP(@i)
																		x.lock_type,
																		REPLACE
																		(
																			REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
																			REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
																			REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
																				DB_NAME
																				(
																					CONVERT
																					(
																						INT,
																						SUBSTRING(wt.resource_description, NULLIF(CHARINDEX(N''dbid='', wt.resource_description), 0) + 5, COALESCE(NULLIF(CHARINDEX(N'' '', wt.resource_description, CHARINDEX(N''dbid='', wt.resource_description) + 5), 0), LEN(wt.resource_description) + 1) - CHARINDEX(N''dbid='', wt.resource_description) - 5)
																					)
																				),
																				NCHAR(31),N''?''),NCHAR(30),N''?''),NCHAR(29),N''?''),NCHAR(28),N''?''),NCHAR(27),N''?''),NCHAR(26),N''?''),NCHAR(25),N''?''),NCHAR(24),N''?''),NCHAR(23),N''?''),NCHAR(22),N''?''),
																				NCHAR(21),N''?''),NCHAR(20),N''?''),NCHAR(19),N''?''),NCHAR(18),N''?''),NCHAR(17),N''?''),NCHAR(16),N''?''),NCHAR(15),N''?''),NCHAR(14),N''?''),NCHAR(12),N''?''),
																				NCHAR(11),N''?''),NCHAR(8),N''?''),NCHAR(7),N''?''),NCHAR(6),N''?''),NCHAR(5),N''?''),NCHAR(4),N''?''),NCHAR(3),N''?''),NCHAR(2),N''?''),NCHAR(1),N''?''),
																			NCHAR(0),
																			N''''
																		) AS database_name,
																		CASE x.lock_type
																			WHEN N''objectlock'' THEN
																				SUBSTRING(wt.resource_description, NULLIF(CHARINDEX(N''objid='', wt.resource_description), 0) + 6, COALESCE(NULLIF(CHARINDEX(N'' '', wt.resource_description, CHARINDEX(N''objid='', wt.resource_description) + 6), 0), LEN(wt.resource_description) + 1) - CHARINDEX(N''objid='', wt.resource_description) - 6)
																			ELSE
																				NULL
																		END AS object_id,
																		CASE x.lock_type
																			WHEN N''filelock'' THEN
																				SUBSTRING(wt.resource_description, NULLIF(CHARINDEX(N''fileid='', wt.resource_description), 0) + 7, COALESCE(NULLIF(CHARINDEX(N'' '', wt.resource_description, CHARINDEX(N''fileid='', wt.resource_description) + 7), 0), LEN(wt.resource_description) + 1) - CHARINDEX(N''fileid='', wt.resource_description) - 7)
																			ELSE
																				NULL
																		END AS file_id,
																		CASE
																			WHEN x.lock_type in (N''pagelock'', N''extentlock'', N''ridlock'') THEN
																				SUBSTRING(wt.resource_description, NULLIF(CHARINDEX(N''associatedObjectId='', wt.resource_description), 0) + 19, COALESCE(NULLIF(CHARINDEX(N'' '', wt.resource_description, CHARINDEX(N''associatedObjectId='', wt.resource_description) + 19), 0), LEN(wt.resource_description) + 1) - CHARINDEX(N''associatedObjectId='', wt.resource_description) - 19)
																			WHEN x.lock_type in (N''keylock'', N''hobtlock'', N''allocunitlock'') THEN
																				SUBSTRING(wt.resource_description, NULLIF(CHARINDEX(N''hobtid='', wt.resource_description), 0) + 7, COALESCE(NULLIF(CHARINDEX(N'' '', wt.resource_description, CHARINDEX(N''hobtid='', wt.resource_description) + 7), 0), LEN(wt.resource_description) + 1) - CHARINDEX(N''hobtid='', wt.resource_description) - 7)
																			ELSE
																				NULL
																		END AS hobt_id,
																		CASE x.lock_type
																			WHEN N''applicationlock'' THEN
																				SUBSTRING(wt.resource_description, NULLIF(CHARINDEX(N''hash='', wt.resource_description), 0) + 5, COALESCE(NULLIF(CHARINDEX(N'' '', wt.resource_description, CHARINDEX(N''hash='', wt.resource_description) + 5), 0), LEN(wt.resource_description) + 1) - CHARINDEX(N''hash='', wt.resource_description) - 5)
																			ELSE
																				NULL
																		END AS applock_hash,
																		CASE x.lock_type
																			WHEN N''metadatalock'' THEN
																				SUBSTRING(wt.resource_description, NULLIF(CHARINDEX(N''subresource='', wt.resource_description), 0) + 12, COALESCE(NULLIF(CHARINDEX(N'' '', wt.resource_description, CHARINDEX(N''subresource='', wt.resource_description) + 12), 0), LEN(wt.resource_description) + 1) - CHARINDEX(N''subresource='', wt.resource_description) - 12)
																			ELSE
																				NULL
																		END AS metadata_resource,
																		CASE x.lock_type
																			WHEN N''metadatalock'' THEN
																				SUBSTRING(wt.resource_description, NULLIF(CHARINDEX(N''classid='', wt.resource_description), 0) + 8, COALESCE(NULLIF(CHARINDEX(N'' dbid='', wt.resource_description) - CHARINDEX(N''classid='', wt.resource_description), 0), LEN(wt.resource_description) + 1) - 8)
																			ELSE
																				NULL
																		END AS metadata_class_id
																	FROM
																	(
																		SELECT TOP(1)
																			LEFT(wt.resource_description, CHARINDEX(N'' '', wt.resource_description) - 1) COLLATE Latin1_General_Bin2 AS lock_type
																	) AS x
																	FOR XML
																		PATH('''')
																)
															ELSE NULL
														END AS block_info,
														wt.wait_duration_ms,
														wt.waiting_task_address
													FROM
													(
														SELECT TOP(@i)
															wt0.wait_type COLLATE Latin1_General_Bin2 AS wait_type,
															wt0.resource_description COLLATE Latin1_General_Bin2 AS resource_description,
															wt0.wait_duration_ms,
															wt0.waiting_task_address,
															CASE
																WHEN wt0.blocking_session_id = p.blocked THEN
																	wt0.blocking_session_id
																ELSE
																	NULL
															END AS blocking_session_id
														FROM sys.dm_os_waiting_tasks AS wt0
														CROSS APPLY
														(
															SELECT TOP(1)
																s0.blocked
															FROM @sessions AS s0
															WHERE
																s0.session_id = wt0.session_id
																AND COALESCE(s0.wait_type, N'''') <> N''OLEDB''
																AND wt0.wait_type <> N''OLEDB''
														) AS p
													) AS wt
												) AS wt1
												GROUP BY
													wt1.wait_type,
													wt1.waiting_task_address
											) AS wt2 ON
												wt2.waiting_task_address = task_info.task_address
												AND wt2.wait_duration_ms > 0
												AND task_info.runnable_time IS NULL
											GROUP BY
												task_info.session_id,
												task_info.request_id,
												task_info.physical_io,
												task_info.context_switches,
												task_info.thread_CPU_snapshot,
												task_info.num_tasks,
												CASE
													WHEN task_info.runnable_time IS NOT NULL THEN
														''RUNNABLE''
													ELSE
														wt2.wait_type
												END
										) AS w1
									) AS waits
									ORDER BY
										waits.session_id,
										waits.request_id,
										waits.r
									FOR XML
										PATH(N''tasks''),
										TYPE
								) AS tasks_raw (task_xml_raw)
							) AS tasks_final
							CROSS APPLY tasks_final.task_xml.nodes(N''/tasks'') AS task_nodes (task_node)
							WHERE
								task_nodes.task_node.exist(N''session_id'') = 1
						) AS tasks ON
							tasks.session_id = y.session_id
							AND tasks.request_id = y.request_id 
						'
					ELSE
						''
				END +
				'LEFT OUTER HASH JOIN
				(
					SELECT TOP(@i)
						t_info.session_id,
						COALESCE(t_info.request_id, -1) AS request_id,
						SUM(t_info.tempdb_allocations) AS tempdb_allocations,
						SUM(t_info.tempdb_current) AS tempdb_current
					FROM
					(
						SELECT TOP(@i)
							tsu.session_id,
							tsu.request_id,
							tsu.user_objects_alloc_page_count +
								tsu.internal_objects_alloc_page_count AS tempdb_allocations,
							tsu.user_objects_alloc_page_count +
								tsu.internal_objects_alloc_page_count -
								tsu.user_objects_dealloc_page_count -
								tsu.internal_objects_dealloc_page_count AS tempdb_current
						FROM sys.dm_db_task_space_usage AS tsu
						CROSS APPLY
						(
							SELECT TOP(1)
								s0.session_id
							FROM @sessions AS s0
							WHERE
								s0.session_id = tsu.session_id
						) AS p

						UNION ALL

						SELECT TOP(@i)
							ssu.session_id,
							NULL AS request_id,
							ssu.user_objects_alloc_page_count +
								ssu.internal_objects_alloc_page_count AS tempdb_allocations,
							ssu.user_objects_alloc_page_count +
								ssu.internal_objects_alloc_page_count -
								ssu.user_objects_dealloc_page_count -
								ssu.internal_objects_dealloc_page_count AS tempdb_current
						FROM sys.dm_db_session_space_usage AS ssu
						CROSS APPLY
						(
							SELECT TOP(1)
								s0.session_id
							FROM @sessions AS s0
							WHERE
								s0.session_id = ssu.session_id
						) AS p
					) AS t_info
					GROUP BY
						t_info.session_id,
						COALESCE(t_info.request_id, -1)
				) AS tempdb_info ON
					tempdb_info.session_id = y.session_id
					AND tempdb_info.request_id =
						CASE
							WHEN y.status = N''sleeping'' THEN
								-1
							ELSE
								y.request_id
						END
				' +
				CASE 
					WHEN 
						NOT 
						(
							@get_avg_time = 1 
							AND @recursion = 1
						) THEN 
							''
					ELSE
						'LEFT OUTER HASH JOIN
						(
							SELECT TOP(@i)
								*
							FROM sys.dm_exec_query_stats
						) AS qs ON
							qs.sql_handle = y.sql_handle
							AND qs.plan_handle = y.plan_handle
							AND qs.statement_start_offset = y.statement_start_offset
							AND qs.statement_end_offset = y.statement_end_offset
						'
				END + 
			') AS x
			OPTION (KEEPFIXED PLAN, OPTIMIZE FOR (@i = 1)); ';

		SET @sql_n = CONVERT(NVARCHAR(MAX), @sql);

		SET @last_collection_start = GETDATE();

		IF @recursion = -1
		BEGIN;
			SELECT
				@first_collection_ms_ticks = ms_ticks
			FROM sys.dm_os_sys_info;
		END;

		INSERT #sessions
		(
			recursion,
			session_id,
			request_id,
			session_number,
			elapsed_time,
			avg_elapsed_time,
			physical_io,
			reads,
			physical_reads,
			writes,
			tempdb_allocations,
			tempdb_current,
			CPU,
			thread_CPU_snapshot,
			context_switches,
			used_memory,
			tasks,
			status,
			wait_info,
			transaction_id,
			open_tran_count,
			sql_handle,
			statement_start_offset,
			statement_end_offset,		
			sql_text,
			plan_handle,
			blocking_session_id,
			percent_complete,
			host_name,
			login_name,
			database_name,
			program_name,
			additional_info,
			start_time,
			login_time,
			last_request_start_time
		)
		EXEC sp_executesql 
			@sql_n,
			N'@recursion SMALLINT, @filter sysname, @not_filter sysname, @first_collection_ms_ticks BIGINT',
			@recursion, @filter, @not_filter, @first_collection_ms_ticks;

		--Collect transaction information?
		IF
			@recursion = 1
			AND
			(
				@output_column_list LIKE '%|[tran_start_time|]%' ESCAPE '|'
				OR @output_column_list LIKE '%|[tran_log_writes|]%' ESCAPE '|' 
			)
		BEGIN;	
			DECLARE @i INT;
			SET @i = 2147483647;

			UPDATE s
			SET
				tran_start_time =
					CONVERT
					(
						DATETIME,
						LEFT
						(
							x.trans_info,
							NULLIF(CHARINDEX(NCHAR(254) COLLATE Latin1_General_Bin2, x.trans_info) - 1, -1)
						),
						121
					),
				tran_log_writes =
					RIGHT
					(
						x.trans_info,
						LEN(x.trans_info) - CHARINDEX(NCHAR(254) COLLATE Latin1_General_Bin2, x.trans_info)
					)
			FROM
			(
				SELECT TOP(@i)
					trans_nodes.trans_node.value('(session_id/text())[1]', 'SMALLINT') AS session_id,
					COALESCE(trans_nodes.trans_node.value('(request_id/text())[1]', 'INT'), 0) AS request_id,
					trans_nodes.trans_node.value('(trans_info/text())[1]', 'NVARCHAR(4000)') AS trans_info				
				FROM
				(
					SELECT TOP(@i)
						CONVERT
						(
							XML,
							REPLACE
							(
								CONVERT(NVARCHAR(MAX), trans_raw.trans_xml_raw) COLLATE Latin1_General_Bin2, 
								N'</trans_info></trans><trans><trans_info>', N''
							)
						)
					FROM
					(
						SELECT TOP(@i)
							CASE u_trans.r
								WHEN 1 THEN u_trans.session_id
								ELSE NULL
							END AS [session_id],
							CASE u_trans.r
								WHEN 1 THEN u_trans.request_id
								ELSE NULL
							END AS [request_id],
							CONVERT
							(
								NVARCHAR(MAX),
								CASE
									WHEN u_trans.database_id IS NOT NULL THEN
										CASE u_trans.r
											WHEN 1 THEN COALESCE(CONVERT(NVARCHAR, u_trans.transaction_start_time, 121) + NCHAR(254), N'')
											ELSE N''
										END + 
											REPLACE
											(
												REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
												REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
												REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
													CONVERT(VARCHAR(128), COALESCE(DB_NAME(u_trans.database_id), N'(null)')),
													NCHAR(31),N'?'),NCHAR(30),N'?'),NCHAR(29),N'?'),NCHAR(28),N'?'),NCHAR(27),N'?'),NCHAR(26),N'?'),NCHAR(25),N'?'),NCHAR(24),N'?'),NCHAR(23),N'?'),NCHAR(22),N'?'),
													NCHAR(21),N'?'),NCHAR(20),N'?'),NCHAR(19),N'?'),NCHAR(18),N'?'),NCHAR(17),N'?'),NCHAR(16),N'?'),NCHAR(15),N'?'),NCHAR(14),N'?'),NCHAR(12),N'?'),
													NCHAR(11),N'?'),NCHAR(8),N'?'),NCHAR(7),N'?'),NCHAR(6),N'?'),NCHAR(5),N'?'),NCHAR(4),N'?'),NCHAR(3),N'?'),NCHAR(2),N'?'),NCHAR(1),N'?'),
												NCHAR(0),
												N'?'
											) +
											N': ' +
										CONVERT(NVARCHAR, u_trans.log_record_count) + N' (' + CONVERT(NVARCHAR, u_trans.log_kb_used) + N' kB)' +
										N','
									ELSE
										N'N/A,'
								END COLLATE Latin1_General_Bin2
							) AS [trans_info]
						FROM
						(
							SELECT TOP(@i)
								trans.*,
								ROW_NUMBER() OVER
								(
									PARTITION BY
										trans.session_id,
										trans.request_id
									ORDER BY
										trans.transaction_start_time DESC
								) AS r
							FROM
							(
								SELECT TOP(@i)
									session_tran_map.session_id,
									session_tran_map.request_id,
									s_tran.database_id,
									COALESCE(SUM(s_tran.database_transaction_log_record_count), 0) AS log_record_count,
									COALESCE(SUM(s_tran.database_transaction_log_bytes_used), 0) / 1024 AS log_kb_used,
									MIN(s_tran.database_transaction_begin_time) AS transaction_start_time
								FROM
								(
									SELECT TOP(@i)
										*
									FROM sys.dm_tran_active_transactions
									WHERE
										transaction_begin_time <= @last_collection_start
								) AS a_tran
								INNER HASH JOIN
								(
									SELECT TOP(@i)
										*
									FROM sys.dm_tran_database_transactions
									WHERE
										database_id < 32767
								) AS s_tran ON
									s_tran.transaction_id = a_tran.transaction_id
								LEFT OUTER HASH JOIN
								(
									SELECT TOP(@i)
										*
									FROM sys.dm_tran_session_transactions
								) AS tst ON
									s_tran.transaction_id = tst.transaction_id
								CROSS APPLY
								(
									SELECT TOP(1)
										s3.session_id,
										s3.request_id
									FROM
									(
										SELECT TOP(1)
											s1.session_id,
											s1.request_id
										FROM #sessions AS s1
										WHERE
											s1.transaction_id = s_tran.transaction_id
											AND s1.recursion = 1
											
										UNION ALL
									
										SELECT TOP(1)
											s2.session_id,
											s2.request_id
										FROM #sessions AS s2
										WHERE
											s2.session_id = tst.session_id
											AND s2.recursion = 1
									) AS s3
									ORDER BY
										s3.request_id
								) AS session_tran_map
								GROUP BY
									session_tran_map.session_id,
									session_tran_map.request_id,
									s_tran.database_id
							) AS trans
						) AS u_trans
						FOR XML
							PATH('trans'),
							TYPE
					) AS trans_raw (trans_xml_raw)
				) AS trans_final (trans_xml)
				CROSS APPLY trans_final.trans_xml.nodes('/trans') AS trans_nodes (trans_node)
			) AS x
			INNER HASH JOIN #sessions AS s ON
				s.session_id = x.session_id
				AND s.request_id = x.request_id
			OPTION (OPTIMIZE FOR (@i = 1));
		END;

		--Variables for text and plan collection
		DECLARE	
			@session_id SMALLINT,
			@request_id INT,
			@sql_handle VARBINARY(64),
			@plan_handle VARBINARY(64),
			@statement_start_offset INT,
			@statement_end_offset INT,
			@start_time DATETIME,
			@database_name sysname;

		IF 
			@recursion = 1
			AND @output_column_list LIKE '%|[sql_text|]%' ESCAPE '|'
		BEGIN;
			DECLARE sql_cursor
			CURSOR LOCAL FAST_FORWARD
			FOR 
				SELECT 
					session_id,
					request_id,
					sql_handle,
					statement_start_offset,
					statement_end_offset
				FROM #sessions
				WHERE
					recursion = 1
					AND sql_handle IS NOT NULL
			OPTION (KEEPFIXED PLAN);

			OPEN sql_cursor;

			FETCH NEXT FROM sql_cursor
			INTO 
				@session_id,
				@request_id,
				@sql_handle,
				@statement_start_offset,
				@statement_end_offset;

			--Wait up to 5 ms for the SQL text, then give up
			SET LOCK_TIMEOUT 5;

			WHILE @@FETCH_STATUS = 0
			BEGIN;
				BEGIN TRY;
					UPDATE s
					SET
						s.sql_text =
						(
							SELECT
								REPLACE
								(
									REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
									REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
									REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
										N'--' + NCHAR(13) + NCHAR(10) +
										CASE 
											WHEN @get_full_inner_text = 1 THEN est.text
											WHEN LEN(est.text) < (@statement_end_offset / 2) + 1 THEN est.text
											WHEN SUBSTRING(est.text, (@statement_start_offset/2), 2) LIKE N'[a-zA-Z0-9][a-zA-Z0-9]' THEN est.text
											ELSE
												CASE
													WHEN @statement_start_offset > 0 THEN
														SUBSTRING
														(
															est.text,
															((@statement_start_offset/2) + 1),
															(
																CASE
																	WHEN @statement_end_offset = -1 THEN 2147483647
																	ELSE ((@statement_end_offset - @statement_start_offset)/2) + 1
																END
															)
														)
													ELSE RTRIM(LTRIM(est.text))
												END
										END +
										NCHAR(13) + NCHAR(10) + N'--' COLLATE Latin1_General_Bin2,
										NCHAR(31),N'?'),NCHAR(30),N'?'),NCHAR(29),N'?'),NCHAR(28),N'?'),NCHAR(27),N'?'),NCHAR(26),N'?'),NCHAR(25),N'?'),NCHAR(24),N'?'),NCHAR(23),N'?'),NCHAR(22),N'?'),
										NCHAR(21),N'?'),NCHAR(20),N'?'),NCHAR(19),N'?'),NCHAR(18),N'?'),NCHAR(17),N'?'),NCHAR(16),N'?'),NCHAR(15),N'?'),NCHAR(14),N'?'),NCHAR(12),N'?'),
										NCHAR(11),N'?'),NCHAR(8),N'?'),NCHAR(7),N'?'),NCHAR(6),N'?'),NCHAR(5),N'?'),NCHAR(4),N'?'),NCHAR(3),N'?'),NCHAR(2),N'?'),NCHAR(1),N'?'),
									NCHAR(0),
									N''
								) AS [processing-instruction(query)]
							FOR XML
								PATH(''),
								TYPE
						),
						s.statement_start_offset = 
							CASE 
								WHEN LEN(est.text) < (@statement_end_offset / 2) + 1 THEN 0
								WHEN SUBSTRING(CONVERT(VARCHAR(MAX), est.text), (@statement_start_offset/2), 2) LIKE '[a-zA-Z0-9][a-zA-Z0-9]' THEN 0
								ELSE @statement_start_offset
							END,
						s.statement_end_offset = 
							CASE 
								WHEN LEN(est.text) < (@statement_end_offset / 2) + 1 THEN -1
								WHEN SUBSTRING(CONVERT(VARCHAR(MAX), est.text), (@statement_start_offset/2), 2) LIKE '[a-zA-Z0-9][a-zA-Z0-9]' THEN -1
								ELSE @statement_end_offset
							END
					FROM 
						#sessions AS s,
						(
							SELECT TOP(1)
								text
							FROM
							(
								SELECT 
									text, 
									0 AS row_num
								FROM sys.dm_exec_sql_text(@sql_handle)
								
								UNION ALL
								
								SELECT 
									NULL,
									1 AS row_num
							) AS est0
							ORDER BY
								row_num
						) AS est
					WHERE 
						s.session_id = @session_id
						AND s.request_id = @request_id
						AND s.recursion = 1
					OPTION (KEEPFIXED PLAN);
				END TRY
				BEGIN CATCH;
					UPDATE s
					SET
						s.sql_text = 
							CASE ERROR_NUMBER() 
								WHEN 1222 THEN '<timeout_exceeded />'
								ELSE '<error message="' + ERROR_MESSAGE() + '" />'
							END
					FROM #sessions AS s
					WHERE 
						s.session_id = @session_id
						AND s.request_id = @request_id
						AND s.recursion = 1
					OPTION (KEEPFIXED PLAN);
				END CATCH;

				FETCH NEXT FROM sql_cursor
				INTO
					@session_id,
					@request_id,
					@sql_handle,
					@statement_start_offset,
					@statement_end_offset;
			END;

			--Return this to the default
			SET LOCK_TIMEOUT -1;

			CLOSE sql_cursor;
			DEALLOCATE sql_cursor;
		END;

		IF 
			@get_outer_command = 1 
			AND @recursion = 1
			AND @output_column_list LIKE '%|[sql_command|]%' ESCAPE '|'
		BEGIN;
			DECLARE @buffer_results TABLE
			(
				EventType VARCHAR(30),
				Parameters INT,
				EventInfo NVARCHAR(4000),
				start_time DATETIME,
				session_number INT IDENTITY(1,1) NOT NULL PRIMARY KEY
			);

			DECLARE buffer_cursor
			CURSOR LOCAL FAST_FORWARD
			FOR 
				SELECT 
					session_id,
					MAX(start_time) AS start_time
				FROM #sessions
				WHERE
					recursion = 1
				GROUP BY
					session_id
				ORDER BY
					session_id
				OPTION (KEEPFIXED PLAN);

			OPEN buffer_cursor;

			FETCH NEXT FROM buffer_cursor
			INTO 
				@session_id,
				@start_time;

			WHILE @@FETCH_STATUS = 0
			BEGIN;
				BEGIN TRY;
					--In SQL Server 2008, DBCC INPUTBUFFER will throw 
					--an exception if the session no longer exists
					INSERT @buffer_results
					(
						EventType,
						Parameters,
						EventInfo
					)
					EXEC sp_executesql
						N'DBCC INPUTBUFFER(@session_id) WITH NO_INFOMSGS;',
						N'@session_id SMALLINT',
						@session_id;

					UPDATE br
					SET
						br.start_time = @start_time
					FROM @buffer_results AS br
					WHERE
						br.session_number = 
						(
							SELECT MAX(br2.session_number)
							FROM @buffer_results br2
						);
				END TRY
				BEGIN CATCH
				END CATCH;

				FETCH NEXT FROM buffer_cursor
				INTO 
					@session_id,
					@start_time;
			END;

			UPDATE s
			SET
				sql_command = 
				(
					SELECT 
						REPLACE
						(
							REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
							REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
							REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
								CONVERT
								(
									NVARCHAR(MAX),
									N'--' + NCHAR(13) + NCHAR(10) + br.EventInfo + NCHAR(13) + NCHAR(10) + N'--' COLLATE Latin1_General_Bin2
								),
								NCHAR(31),N'?'),NCHAR(30),N'?'),NCHAR(29),N'?'),NCHAR(28),N'?'),NCHAR(27),N'?'),NCHAR(26),N'?'),NCHAR(25),N'?'),NCHAR(24),N'?'),NCHAR(23),N'?'),NCHAR(22),N'?'),
								NCHAR(21),N'?'),NCHAR(20),N'?'),NCHAR(19),N'?'),NCHAR(18),N'?'),NCHAR(17),N'?'),NCHAR(16),N'?'),NCHAR(15),N'?'),NCHAR(14),N'?'),NCHAR(12),N'?'),
								NCHAR(11),N'?'),NCHAR(8),N'?'),NCHAR(7),N'?'),NCHAR(6),N'?'),NCHAR(5),N'?'),NCHAR(4),N'?'),NCHAR(3),N'?'),NCHAR(2),N'?'),NCHAR(1),N'?'),
							NCHAR(0),
							N''
						) AS [processing-instruction(query)]
					FROM @buffer_results AS br
					WHERE 
						br.session_number = s.session_number
						AND br.start_time = s.start_time
						AND 
						(
							(
								s.start_time = s.last_request_start_time
								AND EXISTS
								(
									SELECT *
									FROM sys.dm_exec_requests r2
									WHERE
										r2.session_id = s.session_id
										AND r2.request_id = s.request_id
										AND r2.start_time = s.start_time
								)
							)
							OR 
							(
								s.request_id = 0
								AND EXISTS
								(
									SELECT *
									FROM sys.dm_exec_sessions s2
									WHERE
										s2.session_id = s.session_id
										AND s2.last_request_start_time = s.last_request_start_time
								)
							)
						)
					FOR XML
						PATH(''),
						TYPE
				)
			FROM #sessions AS s
			WHERE
				recursion = 1
			OPTION (KEEPFIXED PLAN);

			CLOSE buffer_cursor;
			DEALLOCATE buffer_cursor;
		END;

		IF 
			@get_plans >= 1 
			AND @recursion = 1
			AND @output_column_list LIKE '%|[query_plan|]%' ESCAPE '|'
		BEGIN;
			DECLARE plan_cursor
			CURSOR LOCAL FAST_FORWARD
			FOR 
				SELECT
					session_id,
					request_id,
					plan_handle,
					statement_start_offset,
					statement_end_offset
				FROM #sessions
				WHERE
					recursion = 1
					AND plan_handle IS NOT NULL
			OPTION (KEEPFIXED PLAN);

			OPEN plan_cursor;

			FETCH NEXT FROM plan_cursor
			INTO 
				@session_id,
				@request_id,
				@plan_handle,
				@statement_start_offset,
				@statement_end_offset;

			--Wait up to 5 ms for a query plan, then give up
			SET LOCK_TIMEOUT 5;

			WHILE @@FETCH_STATUS = 0
			BEGIN;
				BEGIN TRY;
					UPDATE s
					SET
						s.query_plan =
						(
							SELECT
								CONVERT(xml, query_plan)
							FROM sys.dm_exec_text_query_plan
							(
								@plan_handle, 
								CASE @get_plans
									WHEN 1 THEN
										@statement_start_offset
									ELSE
										0
								END, 
								CASE @get_plans
									WHEN 1 THEN
										@statement_end_offset
									ELSE
										-1
								END
							)
						)
					FROM #sessions AS s
					WHERE 
						s.session_id = @session_id
						AND s.request_id = @request_id
						AND s.recursion = 1
					OPTION (KEEPFIXED PLAN);
				END TRY
				BEGIN CATCH;
					IF ERROR_NUMBER() = 6335
					BEGIN;
						UPDATE s
						SET
							s.query_plan =
							(
								SELECT
									N'--' + NCHAR(13) + NCHAR(10) + 
									N'-- Could not render showplan due to XML data type limitations. ' + NCHAR(13) + NCHAR(10) + 
									N'-- To see the graphical plan save the XML below as a .SQLPLAN file and re-open in SSMS.' + NCHAR(13) + NCHAR(10) +
									N'--' + NCHAR(13) + NCHAR(10) +
										REPLACE(qp.query_plan, N'<RelOp', NCHAR(13)+NCHAR(10)+N'<RelOp') + 
										NCHAR(13) + NCHAR(10) + N'--' COLLATE Latin1_General_Bin2 AS [processing-instruction(query_plan)]
								FROM sys.dm_exec_text_query_plan
								(
									@plan_handle, 
									CASE @get_plans
										WHEN 1 THEN
											@statement_start_offset
										ELSE
											0
									END, 
									CASE @get_plans
										WHEN 1 THEN
											@statement_end_offset
										ELSE
											-1
									END
								) AS qp
								FOR XML
									PATH(''),
									TYPE
							)
						FROM #sessions AS s
						WHERE 
							s.session_id = @session_id
							AND s.request_id = @request_id
							AND s.recursion = 1
						OPTION (KEEPFIXED PLAN);
					END;
					ELSE
					BEGIN;
						UPDATE s
						SET
							s.query_plan = 
								CASE ERROR_NUMBER() 
									WHEN 1222 THEN '<timeout_exceeded />'
									ELSE '<error message="' + ERROR_MESSAGE() + '" />'
								END
						FROM #sessions AS s
						WHERE 
							s.session_id = @session_id
							AND s.request_id = @request_id
							AND s.recursion = 1
						OPTION (KEEPFIXED PLAN);
					END;
				END CATCH;

				FETCH NEXT FROM plan_cursor
				INTO
					@session_id,
					@request_id,
					@plan_handle,
					@statement_start_offset,
					@statement_end_offset;
			END;

			--Return this to the default
			SET LOCK_TIMEOUT -1;

			CLOSE plan_cursor;
			DEALLOCATE plan_cursor;
		END;

		IF 
			@get_locks = 1 
			AND @recursion = 1
			AND @output_column_list LIKE '%|[locks|]%' ESCAPE '|'
		BEGIN;
			DECLARE locks_cursor
			CURSOR LOCAL FAST_FORWARD
			FOR 
				SELECT DISTINCT
					database_name
				FROM #locks
				WHERE
					EXISTS
					(
						SELECT *
						FROM #sessions AS s
						WHERE
							s.session_id = #locks.session_id
							AND recursion = 1
					)
					AND database_name <> '(null)'
				OPTION (KEEPFIXED PLAN);

			OPEN locks_cursor;

			FETCH NEXT FROM locks_cursor
			INTO 
				@database_name;

			WHILE @@FETCH_STATUS = 0
			BEGIN;
				BEGIN TRY;
					SET @sql_n = CONVERT(NVARCHAR(MAX), '') +
						'UPDATE l ' +
						'SET ' +
							'object_name = ' +
								'REPLACE ' +
								'( ' +
									'REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE( ' +
									'REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE( ' +
									'REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE( ' +
										'o.name COLLATE Latin1_General_Bin2, ' +
										'NCHAR(31),N''?''),NCHAR(30),N''?''),NCHAR(29),N''?''),NCHAR(28),N''?''),NCHAR(27),N''?''),NCHAR(26),N''?''),NCHAR(25),N''?''),NCHAR(24),N''?''),NCHAR(23),N''?''),NCHAR(22),N''?''), ' +
										'NCHAR(21),N''?''),NCHAR(20),N''?''),NCHAR(19),N''?''),NCHAR(18),N''?''),NCHAR(17),N''?''),NCHAR(16),N''?''),NCHAR(15),N''?''),NCHAR(14),N''?''),NCHAR(12),N''?''), ' +
										'NCHAR(11),N''?''),NCHAR(8),N''?''),NCHAR(7),N''?''),NCHAR(6),N''?''),NCHAR(5),N''?''),NCHAR(4),N''?''),NCHAR(3),N''?''),NCHAR(2),N''?''),NCHAR(1),N''?''), ' +
									'NCHAR(0), ' +
									N''''' ' +
								'), ' +
							'index_name = ' +
								'REPLACE ' +
								'( ' +
									'REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE( ' +
									'REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE( ' +
									'REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE( ' +
										'i.name COLLATE Latin1_General_Bin2, ' +
										'NCHAR(31),N''?''),NCHAR(30),N''?''),NCHAR(29),N''?''),NCHAR(28),N''?''),NCHAR(27),N''?''),NCHAR(26),N''?''),NCHAR(25),N''?''),NCHAR(24),N''?''),NCHAR(23),N''?''),NCHAR(22),N''?''), ' +
										'NCHAR(21),N''?''),NCHAR(20),N''?''),NCHAR(19),N''?''),NCHAR(18),N''?''),NCHAR(17),N''?''),NCHAR(16),N''?''),NCHAR(15),N''?''),NCHAR(14),N''?''),NCHAR(12),N''?''), ' +
										'NCHAR(11),N''?''),NCHAR(8),N''?''),NCHAR(7),N''?''),NCHAR(6),N''?''),NCHAR(5),N''?''),NCHAR(4),N''?''),NCHAR(3),N''?''),NCHAR(2),N''?''),NCHAR(1),N''?''), ' +
									'NCHAR(0), ' +
									N''''' ' +
								'), ' +
							'schema_name = ' +
								'REPLACE ' +
								'( ' +
									'REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE( ' +
									'REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE( ' +
									'REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE( ' +
										's.name COLLATE Latin1_General_Bin2, ' +
										'NCHAR(31),N''?''),NCHAR(30),N''?''),NCHAR(29),N''?''),NCHAR(28),N''?''),NCHAR(27),N''?''),NCHAR(26),N''?''),NCHAR(25),N''?''),NCHAR(24),N''?''),NCHAR(23),N''?''),NCHAR(22),N''?''), ' +
										'NCHAR(21),N''?''),NCHAR(20),N''?''),NCHAR(19),N''?''),NCHAR(18),N''?''),NCHAR(17),N''?''),NCHAR(16),N''?''),NCHAR(15),N''?''),NCHAR(14),N''?''),NCHAR(12),N''?''), ' +
										'NCHAR(11),N''?''),NCHAR(8),N''?''),NCHAR(7),N''?''),NCHAR(6),N''?''),NCHAR(5),N''?''),NCHAR(4),N''?''),NCHAR(3),N''?''),NCHAR(2),N''?''),NCHAR(1),N''?''), ' +
									'NCHAR(0), ' +
									N''''' ' +
								'), ' +
							'principal_name = ' + 
								'REPLACE ' +
								'( ' +
									'REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE( ' +
									'REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE( ' +
									'REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE( ' +
										'dp.name COLLATE Latin1_General_Bin2, ' +
										'NCHAR(31),N''?''),NCHAR(30),N''?''),NCHAR(29),N''?''),NCHAR(28),N''?''),NCHAR(27),N''?''),NCHAR(26),N''?''),NCHAR(25),N''?''),NCHAR(24),N''?''),NCHAR(23),N''?''),NCHAR(22),N''?''), ' +
										'NCHAR(21),N''?''),NCHAR(20),N''?''),NCHAR(19),N''?''),NCHAR(18),N''?''),NCHAR(17),N''?''),NCHAR(16),N''?''),NCHAR(15),N''?''),NCHAR(14),N''?''),NCHAR(12),N''?''), ' +
										'NCHAR(11),N''?''),NCHAR(8),N''?''),NCHAR(7),N''?''),NCHAR(6),N''?''),NCHAR(5),N''?''),NCHAR(4),N''?''),NCHAR(3),N''?''),NCHAR(2),N''?''),NCHAR(1),N''?''), ' +
									'NCHAR(0), ' +
									N''''' ' +
								') ' +
						'FROM #locks AS l ' +
						'LEFT OUTER JOIN ' + QUOTENAME(@database_name) + '.sys.allocation_units AS au ON ' +
							'au.allocation_unit_id = l.allocation_unit_id ' +
						'LEFT OUTER JOIN ' + QUOTENAME(@database_name) + '.sys.partitions AS p ON ' +
							'p.hobt_id = ' +
								'COALESCE ' +
								'( ' +
									'l.hobt_id, ' +
									'CASE ' +
										'WHEN au.type IN (1, 3) THEN au.container_id ' +
										'ELSE NULL ' +
									'END ' +
								') ' +
						'LEFT OUTER JOIN ' + QUOTENAME(@database_name) + '.sys.partitions AS p1 ON ' +
							'l.hobt_id IS NULL ' +
							'AND au.type = 2 ' +
							'AND p1.partition_id = au.container_id ' +
						'LEFT OUTER JOIN ' + QUOTENAME(@database_name) + '.sys.objects AS o ON ' +
							'o.object_id = COALESCE(l.object_id, p.object_id, p1.object_id) ' +
						'LEFT OUTER JOIN ' + QUOTENAME(@database_name) + '.sys.indexes AS i ON ' +
							'i.object_id = COALESCE(l.object_id, p.object_id, p1.object_id) ' +
							'AND i.index_id = COALESCE(l.index_id, p.index_id, p1.index_id) ' +
						'LEFT OUTER JOIN ' + QUOTENAME(@database_name) + '.sys.schemas AS s ON ' +
							's.schema_id = COALESCE(l.schema_id, o.schema_id) ' +
						'LEFT OUTER JOIN ' + QUOTENAME(@database_name) + '.sys.database_principals AS dp ON ' +
							'dp.principal_id = l.principal_id ' +
						'WHERE ' +
							'l.database_name = @database_name ' +
						'OPTION (KEEPFIXED PLAN); ';
					
					EXEC sp_executesql
						@sql_n,
						N'@database_name sysname',
						@database_name;
				END TRY
				BEGIN CATCH;
					UPDATE #locks
					SET
						query_error = 
							REPLACE
							(
								REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
								REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
								REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
									CONVERT
									(
										NVARCHAR(MAX), 
										ERROR_MESSAGE() COLLATE Latin1_General_Bin2
									),
									NCHAR(31),N'?'),NCHAR(30),N'?'),NCHAR(29),N'?'),NCHAR(28),N'?'),NCHAR(27),N'?'),NCHAR(26),N'?'),NCHAR(25),N'?'),NCHAR(24),N'?'),NCHAR(23),N'?'),NCHAR(22),N'?'),
									NCHAR(21),N'?'),NCHAR(20),N'?'),NCHAR(19),N'?'),NCHAR(18),N'?'),NCHAR(17),N'?'),NCHAR(16),N'?'),NCHAR(15),N'?'),NCHAR(14),N'?'),NCHAR(12),N'?'),
									NCHAR(11),N'?'),NCHAR(8),N'?'),NCHAR(7),N'?'),NCHAR(6),N'?'),NCHAR(5),N'?'),NCHAR(4),N'?'),NCHAR(3),N'?'),NCHAR(2),N'?'),NCHAR(1),N'?'),
								NCHAR(0),
								N''
							)
					WHERE 
						database_name = @database_name
					OPTION (KEEPFIXED PLAN);
				END CATCH;

				FETCH NEXT FROM locks_cursor
				INTO
					@database_name;
			END;

			CLOSE locks_cursor;
			DEALLOCATE locks_cursor;

			CREATE CLUSTERED INDEX IX_SRD ON #locks (session_id, request_id, database_name);

			UPDATE s
			SET 
				s.locks =
				(
					SELECT 
						REPLACE
						(
							REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
							REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
							REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
								CONVERT
								(
									NVARCHAR(MAX), 
									l1.database_name COLLATE Latin1_General_Bin2
								),
								NCHAR(31),N'?'),NCHAR(30),N'?'),NCHAR(29),N'?'),NCHAR(28),N'?'),NCHAR(27),N'?'),NCHAR(26),N'?'),NCHAR(25),N'?'),NCHAR(24),N'?'),NCHAR(23),N'?'),NCHAR(22),N'?'),
								NCHAR(21),N'?'),NCHAR(20),N'?'),NCHAR(19),N'?'),NCHAR(18),N'?'),NCHAR(17),N'?'),NCHAR(16),N'?'),NCHAR(15),N'?'),NCHAR(14),N'?'),NCHAR(12),N'?'),
								NCHAR(11),N'?'),NCHAR(8),N'?'),NCHAR(7),N'?'),NCHAR(6),N'?'),NCHAR(5),N'?'),NCHAR(4),N'?'),NCHAR(3),N'?'),NCHAR(2),N'?'),NCHAR(1),N'?'),
							NCHAR(0),
							N''
						) AS [Database/@name],
						MIN(l1.query_error) AS [Database/@query_error],
						(
							SELECT 
								l2.request_mode AS [Lock/@request_mode],
								l2.request_status AS [Lock/@request_status],
								COUNT(*) AS [Lock/@request_count]
							FROM #locks AS l2
							WHERE 
								l1.session_id = l2.session_id
								AND l1.request_id = l2.request_id
								AND l2.database_name = l1.database_name
								AND l2.resource_type = 'DATABASE'
							GROUP BY
								l2.request_mode,
								l2.request_status
							FOR XML
								PATH(''),
								TYPE
						) AS [Database/Locks],
						(
							SELECT
								COALESCE(l3.object_name, '(null)') AS [Object/@name],
								l3.schema_name AS [Object/@schema_name],
								(
									SELECT
										l4.resource_type AS [Lock/@resource_type],
										l4.page_type AS [Lock/@page_type],
										l4.index_name AS [Lock/@index_name],
										CASE 
											WHEN l4.object_name IS NULL THEN l4.schema_name
											ELSE NULL
										END AS [Lock/@schema_name],
										l4.principal_name AS [Lock/@principal_name],
										l4.resource_description AS [Lock/@resource_description],
										l4.request_mode AS [Lock/@request_mode],
										l4.request_status AS [Lock/@request_status],
										SUM(l4.request_count) AS [Lock/@request_count]
									FROM #locks AS l4
									WHERE 
										l4.session_id = l3.session_id
										AND l4.request_id = l3.request_id
										AND l3.database_name = l4.database_name
										AND COALESCE(l3.object_name, '(null)') = COALESCE(l4.object_name, '(null)')
										AND COALESCE(l3.schema_name, '') = COALESCE(l4.schema_name, '')
										AND l4.resource_type <> 'DATABASE'
									GROUP BY
										l4.resource_type,
										l4.page_type,
										l4.index_name,
										CASE 
											WHEN l4.object_name IS NULL THEN l4.schema_name
											ELSE NULL
										END,
										l4.principal_name,
										l4.resource_description,
										l4.request_mode,
										l4.request_status
									FOR XML
										PATH(''),
										TYPE
								) AS [Object/Locks]
							FROM #locks AS l3
							WHERE 
								l3.session_id = l1.session_id
								AND l3.request_id = l1.request_id
								AND l3.database_name = l1.database_name
								AND l3.resource_type <> 'DATABASE'
							GROUP BY 
								l3.session_id,
								l3.request_id,
								l3.database_name,
								COALESCE(l3.object_name, '(null)'),
								l3.schema_name
							FOR XML
								PATH(''),
								TYPE
						) AS [Database/Objects]
					FROM #locks AS l1
					WHERE
						l1.session_id = s.session_id
						AND l1.request_id = s.request_id
						AND l1.start_time IN (s.start_time, s.last_request_start_time)
						AND s.recursion = 1
					GROUP BY 
						l1.session_id,
						l1.request_id,
						l1.database_name
					FOR XML
						PATH(''),
						TYPE
				)
			FROM #sessions s
			OPTION (KEEPFIXED PLAN);
		END;

		IF 
			@find_block_leaders = 1
			AND @recursion = 1
			AND @output_column_list LIKE '%|[blocked_session_count|]%' ESCAPE '|'
		BEGIN;
			WITH
			blockers AS
			(
				SELECT
					session_id,
					session_id AS top_level_session_id
				FROM #sessions
				WHERE
					recursion = 1

				UNION ALL

				SELECT
					s.session_id,
					b.top_level_session_id
				FROM blockers AS b
				JOIN #sessions AS s ON
					s.blocking_session_id = b.session_id
					AND s.recursion = 1
			)
			UPDATE s
			SET
				s.blocked_session_count = x.blocked_session_count
			FROM #sessions AS s
			JOIN
			(
				SELECT
					b.top_level_session_id AS session_id,
					COUNT(*) - 1 AS blocked_session_count
				FROM blockers AS b
				GROUP BY
					b.top_level_session_id
			) x ON
				s.session_id = x.session_id
			WHERE
				s.recursion = 1;
		END;

		IF
			@get_task_info = 2
			AND @output_column_list LIKE '%|[additional_info|]%' ESCAPE '|'
			AND @recursion = 1
		BEGIN;
			CREATE TABLE #blocked_requests
			(
				session_id SMALLINT NOT NULL,
				request_id INT NOT NULL,
				database_name sysname NOT NULL,
				object_id INT,
				hobt_id BIGINT,
				schema_id INT,
				schema_name sysname NULL,
				object_name sysname NULL,
				query_error NVARCHAR(2048),
				PRIMARY KEY (database_name, session_id, request_id)
			);

			CREATE STATISTICS s_database_name ON #blocked_requests (database_name)
			WITH SAMPLE 0 ROWS, NORECOMPUTE;
			CREATE STATISTICS s_schema_name ON #blocked_requests (schema_name)
			WITH SAMPLE 0 ROWS, NORECOMPUTE;
			CREATE STATISTICS s_object_name ON #blocked_requests (object_name)
			WITH SAMPLE 0 ROWS, NORECOMPUTE;
			CREATE STATISTICS s_query_error ON #blocked_requests (query_error)
			WITH SAMPLE 0 ROWS, NORECOMPUTE;
		
			INSERT #blocked_requests
			(
				session_id,
				request_id,
				database_name,
				object_id,
				hobt_id,
				schema_id
			)
			SELECT
				session_id,
				request_id,
				database_name,
				object_id,
				hobt_id,
				CONVERT(INT, SUBSTRING(schema_node, CHARINDEX(' = ', schema_node) + 3, LEN(schema_node))) AS schema_id
			FROM
			(
				SELECT
					session_id,
					request_id,
					agent_nodes.agent_node.value('(database_name/text())[1]', 'sysname') AS database_name,
					agent_nodes.agent_node.value('(object_id/text())[1]', 'int') AS object_id,
					agent_nodes.agent_node.value('(hobt_id/text())[1]', 'bigint') AS hobt_id,
					agent_nodes.agent_node.value('(metadata_resource/text()[.="SCHEMA"]/../../metadata_class_id/text())[1]', 'varchar(100)') AS schema_node
				FROM #sessions AS s
				CROSS APPLY s.additional_info.nodes('//block_info') AS agent_nodes (agent_node)
				WHERE
					s.recursion = 1
			) AS t
			WHERE
				t.database_name IS NOT NULL
				AND
				(
					t.object_id IS NOT NULL
					OR t.hobt_id IS NOT NULL
					OR t.schema_node IS NOT NULL
				);
			
			DECLARE blocks_cursor
			CURSOR LOCAL FAST_FORWARD
			FOR
				SELECT DISTINCT
					database_name
				FROM #blocked_requests;
				
			OPEN blocks_cursor;
			
			FETCH NEXT FROM blocks_cursor
			INTO 
				@database_name;
			
			WHILE @@FETCH_STATUS = 0
			BEGIN;
				BEGIN TRY;
					SET @sql_n = 
						CONVERT(NVARCHAR(MAX), '') +
						'UPDATE b ' +
						'SET ' +
							'b.schema_name = ' +
								'REPLACE ' +
								'( ' +
									'REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE( ' +
									'REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE( ' +
									'REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE( ' +
										's.name COLLATE Latin1_General_Bin2, ' +
										'NCHAR(31),N''?''),NCHAR(30),N''?''),NCHAR(29),N''?''),NCHAR(28),N''?''),NCHAR(27),N''?''),NCHAR(26),N''?''),NCHAR(25),N''?''),NCHAR(24),N''?''),NCHAR(23),N''?''),NCHAR(22),N''?''), ' +
										'NCHAR(21),N''?''),NCHAR(20),N''?''),NCHAR(19),N''?''),NCHAR(18),N''?''),NCHAR(17),N''?''),NCHAR(16),N''?''),NCHAR(15),N''?''),NCHAR(14),N''?''),NCHAR(12),N''?''), ' +
										'NCHAR(11),N''?''),NCHAR(8),N''?''),NCHAR(7),N''?''),NCHAR(6),N''?''),NCHAR(5),N''?''),NCHAR(4),N''?''),NCHAR(3),N''?''),NCHAR(2),N''?''),NCHAR(1),N''?''), ' +
									'NCHAR(0), ' +
									N''''' ' +
								'), ' +
							'b.object_name = ' +
								'REPLACE ' +
								'( ' +
									'REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE( ' +
									'REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE( ' +
									'REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE( ' +
										'o.name COLLATE Latin1_General_Bin2, ' +
										'NCHAR(31),N''?''),NCHAR(30),N''?''),NCHAR(29),N''?''),NCHAR(28),N''?''),NCHAR(27),N''?''),NCHAR(26),N''?''),NCHAR(25),N''?''),NCHAR(24),N''?''),NCHAR(23),N''?''),NCHAR(22),N''?''), ' +
										'NCHAR(21),N''?''),NCHAR(20),N''?''),NCHAR(19),N''?''),NCHAR(18),N''?''),NCHAR(17),N''?''),NCHAR(16),N''?''),NCHAR(15),N''?''),NCHAR(14),N''?''),NCHAR(12),N''?''), ' +
										'NCHAR(11),N''?''),NCHAR(8),N''?''),NCHAR(7),N''?''),NCHAR(6),N''?''),NCHAR(5),N''?''),NCHAR(4),N''?''),NCHAR(3),N''?''),NCHAR(2),N''?''),NCHAR(1),N''?''), ' +
									'NCHAR(0), ' +
									N''''' ' +
								') ' +
						'FROM #blocked_requests AS b ' +
						'LEFT OUTER JOIN ' + QUOTENAME(@database_name) + '.sys.partitions AS p ON ' +
							'p.hobt_id = b.hobt_id ' +
						'LEFT OUTER JOIN ' + QUOTENAME(@database_name) + '.sys.objects AS o ON ' +
							'o.object_id = COALESCE(p.object_id, b.object_id) ' +
						'LEFT OUTER JOIN ' + QUOTENAME(@database_name) + '.sys.schemas AS s ON ' +
							's.schema_id = COALESCE(o.schema_id, b.schema_id) ' +
						'WHERE ' +
							'b.database_name = @database_name; ';
					
					EXEC sp_executesql
						@sql_n,
						N'@database_name sysname',
						@database_name;
				END TRY
				BEGIN CATCH;
					UPDATE #blocked_requests
					SET
						query_error = 
							REPLACE
							(
								REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
								REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
								REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
									CONVERT
									(
										NVARCHAR(MAX), 
										ERROR_MESSAGE() COLLATE Latin1_General_Bin2
									),
									NCHAR(31),N'?'),NCHAR(30),N'?'),NCHAR(29),N'?'),NCHAR(28),N'?'),NCHAR(27),N'?'),NCHAR(26),N'?'),NCHAR(25),N'?'),NCHAR(24),N'?'),NCHAR(23),N'?'),NCHAR(22),N'?'),
									NCHAR(21),N'?'),NCHAR(20),N'?'),NCHAR(19),N'?'),NCHAR(18),N'?'),NCHAR(17),N'?'),NCHAR(16),N'?'),NCHAR(15),N'?'),NCHAR(14),N'?'),NCHAR(12),N'?'),
									NCHAR(11),N'?'),NCHAR(8),N'?'),NCHAR(7),N'?'),NCHAR(6),N'?'),NCHAR(5),N'?'),NCHAR(4),N'?'),NCHAR(3),N'?'),NCHAR(2),N'?'),NCHAR(1),N'?'),
								NCHAR(0),
								N''
							)
					WHERE
						database_name = @database_name;
				END CATCH;

				FETCH NEXT FROM blocks_cursor
				INTO
					@database_name;
			END;
			
			CLOSE blocks_cursor;
			DEALLOCATE blocks_cursor;
			
			UPDATE s
			SET
				additional_info.modify
				('
					insert <schema_name>{sql:column("b.schema_name")}</schema_name>
					as last
					into (/additional_info/block_info)[1]
				')
			FROM #sessions AS s
			INNER JOIN #blocked_requests AS b ON
				b.session_id = s.session_id
				AND b.request_id = s.request_id
				AND s.recursion = 1
			WHERE
				b.schema_name IS NOT NULL;

			UPDATE s
			SET
				additional_info.modify
				('
					insert <object_name>{sql:column("b.object_name")}</object_name>
					as last
					into (/additional_info/block_info)[1]
				')
			FROM #sessions AS s
			INNER JOIN #blocked_requests AS b ON
				b.session_id = s.session_id
				AND b.request_id = s.request_id
				AND s.recursion = 1
			WHERE
				b.object_name IS NOT NULL;

			UPDATE s
			SET
				additional_info.modify
				('
					insert <query_error>{sql:column("b.query_error")}</query_error>
					as last
					into (/additional_info/block_info)[1]
				')
			FROM #sessions AS s
			INNER JOIN #blocked_requests AS b ON
				b.session_id = s.session_id
				AND b.request_id = s.request_id
				AND s.recursion = 1
			WHERE
				b.query_error IS NOT NULL;
		END;

		IF
			@output_column_list LIKE '%|[program_name|]%' ESCAPE '|'
			AND @output_column_list LIKE '%|[additional_info|]%' ESCAPE '|'
			AND @recursion = 1
		BEGIN;
			DECLARE @job_id UNIQUEIDENTIFIER;
			DECLARE @step_id INT;

			DECLARE agent_cursor
			CURSOR LOCAL FAST_FORWARD
			FOR 
				SELECT
					s.session_id,
					agent_nodes.agent_node.value('(job_id/text())[1]', 'uniqueidentifier') AS job_id,
					agent_nodes.agent_node.value('(step_id/text())[1]', 'int') AS step_id
				FROM #sessions AS s
				CROSS APPLY s.additional_info.nodes('//agent_job_info') AS agent_nodes (agent_node)
				WHERE
					s.recursion = 1
			OPTION (KEEPFIXED PLAN);
			
			OPEN agent_cursor;

			FETCH NEXT FROM agent_cursor
			INTO 
				@session_id,
				@job_id,
				@step_id;

			WHILE @@FETCH_STATUS = 0
			BEGIN;
				BEGIN TRY;
					DECLARE @job_name sysname;
					SET @job_name = NULL;
					DECLARE @step_name sysname;
					SET @step_name = NULL;
					
					SELECT
						@job_name = 
							REPLACE
							(
								REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
								REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
								REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
									j.name,
									NCHAR(31),N'?'),NCHAR(30),N'?'),NCHAR(29),N'?'),NCHAR(28),N'?'),NCHAR(27),N'?'),NCHAR(26),N'?'),NCHAR(25),N'?'),NCHAR(24),N'?'),NCHAR(23),N'?'),NCHAR(22),N'?'),
									NCHAR(21),N'?'),NCHAR(20),N'?'),NCHAR(19),N'?'),NCHAR(18),N'?'),NCHAR(17),N'?'),NCHAR(16),N'?'),NCHAR(15),N'?'),NCHAR(14),N'?'),NCHAR(12),N'?'),
									NCHAR(11),N'?'),NCHAR(8),N'?'),NCHAR(7),N'?'),NCHAR(6),N'?'),NCHAR(5),N'?'),NCHAR(4),N'?'),NCHAR(3),N'?'),NCHAR(2),N'?'),NCHAR(1),N'?'),
								NCHAR(0),
								N'?'
							),
						@step_name = 
							REPLACE
							(
								REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
								REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
								REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
									s.step_name,
									NCHAR(31),N'?'),NCHAR(30),N'?'),NCHAR(29),N'?'),NCHAR(28),N'?'),NCHAR(27),N'?'),NCHAR(26),N'?'),NCHAR(25),N'?'),NCHAR(24),N'?'),NCHAR(23),N'?'),NCHAR(22),N'?'),
									NCHAR(21),N'?'),NCHAR(20),N'?'),NCHAR(19),N'?'),NCHAR(18),N'?'),NCHAR(17),N'?'),NCHAR(16),N'?'),NCHAR(15),N'?'),NCHAR(14),N'?'),NCHAR(12),N'?'),
									NCHAR(11),N'?'),NCHAR(8),N'?'),NCHAR(7),N'?'),NCHAR(6),N'?'),NCHAR(5),N'?'),NCHAR(4),N'?'),NCHAR(3),N'?'),NCHAR(2),N'?'),NCHAR(1),N'?'),
								NCHAR(0),
								N'?'
							)
					FROM msdb.dbo.sysjobs AS j
					INNER JOIN msdb..sysjobsteps AS s ON
						j.job_id = s.job_id
					WHERE
						j.job_id = @job_id
						AND s.step_id = @step_id;

					IF @job_name IS NOT NULL
					BEGIN;
						UPDATE s
						SET
							additional_info.modify
							('
								insert text{sql:variable("@job_name")}
								into (/additional_info/agent_job_info/job_name)[1]
							')
						FROM #sessions AS s
						WHERE 
							s.session_id = @session_id
						OPTION (KEEPFIXED PLAN);
						
						UPDATE s
						SET
							additional_info.modify
							('
								insert text{sql:variable("@step_name")}
								into (/additional_info/agent_job_info/step_name)[1]
							')
						FROM #sessions AS s
						WHERE 
							s.session_id = @session_id
						OPTION (KEEPFIXED PLAN);
					END;
				END TRY
				BEGIN CATCH;
					DECLARE @msdb_error_message NVARCHAR(256);
					SET @msdb_error_message = ERROR_MESSAGE();
				
					UPDATE s
					SET
						additional_info.modify
						('
							insert <msdb_query_error>{sql:variable("@msdb_error_message")}</msdb_query_error>
							as last
							into (/additional_info/agent_job_info)[1]
						')
					FROM #sessions AS s
					WHERE 
						s.session_id = @session_id
						AND s.recursion = 1
					OPTION (KEEPFIXED PLAN);
				END CATCH;

				FETCH NEXT FROM agent_cursor
				INTO 
					@session_id,
					@job_id,
					@step_id;
			END;

			CLOSE agent_cursor;
			DEALLOCATE agent_cursor;
		END; 
		
		IF 
			@delta_interval > 0 
			AND @recursion <> 1
		BEGIN;
			SET @recursion = 1;

			DECLARE @delay_time CHAR(12);
			SET @delay_time = CONVERT(VARCHAR, DATEADD(second, @delta_interval, 0), 114);
			WAITFOR DELAY @delay_time;

			GOTO REDO;
		END;
	END;

	SET @sql = 
		--Outer column list
		CONVERT
		(
			VARCHAR(MAX),
			CASE
				WHEN 
					@destination_table <> '' 
					AND @return_schema = 0 
						THEN 'INSERT ' + @destination_table + ' '
				ELSE ''
			END +
			'SELECT ' +
				@output_column_list + ' ' +
			CASE @return_schema
				WHEN 1 THEN 'INTO #session_schema '
				ELSE ''
			END
		--End outer column list
		) + 
		--Inner column list
		CONVERT
		(
			VARCHAR(MAX),
			'FROM ' +
			'( ' +
				'SELECT ' +
					'session_id, ' +
					--[dd hh:mm:ss.mss]
					CASE
						WHEN @format_output IN (1, 2) THEN
							'CASE ' +
								'WHEN elapsed_time < 0 THEN ' +
									'RIGHT ' +
									'( ' +
										'REPLICATE(''0'', max_elapsed_length) + CONVERT(VARCHAR, (-1 * elapsed_time) / 86400), ' +
										'max_elapsed_length ' +
									') + ' +
										'RIGHT ' +
										'( ' +
											'CONVERT(VARCHAR, DATEADD(second, (-1 * elapsed_time), 0), 120), ' +
											'9 ' +
										') + ' +
										'''.000'' ' +
								'ELSE ' +
									'RIGHT ' +
									'( ' +
										'REPLICATE(''0'', max_elapsed_length) + CONVERT(VARCHAR, elapsed_time / 86400000), ' +
										'max_elapsed_length ' +
									') + ' +
										'RIGHT ' +
										'( ' +
											'CONVERT(VARCHAR, DATEADD(second, elapsed_time / 1000, 0), 120), ' +
											'9 ' +
										') + ' +
										'''.'' + ' + 
										'RIGHT(''000'' + CONVERT(VARCHAR, elapsed_time % 1000), 3) ' +
							'END AS [dd hh:mm:ss.mss], '
						ELSE
							''
					END +
					--[dd hh:mm:ss.mss (avg)] / avg_elapsed_time
					CASE 
						WHEN  @format_output IN (1, 2) THEN 
							'RIGHT ' +
							'( ' +
								'''00'' + CONVERT(VARCHAR, avg_elapsed_time / 86400000), ' +
								'2 ' +
							') + ' +
								'RIGHT ' +
								'( ' +
									'CONVERT(VARCHAR, DATEADD(second, avg_elapsed_time / 1000, 0), 120), ' +
									'9 ' +
								') + ' +
								'''.'' + ' +
								'RIGHT(''000'' + CONVERT(VARCHAR, avg_elapsed_time % 1000), 3) AS [dd hh:mm:ss.mss (avg)], '
						ELSE
							'avg_elapsed_time, '
					END +
					--physical_io
					CASE @format_output
						WHEN 1 THEN 'CONVERT(VARCHAR, SPACE(MAX(LEN(CONVERT(VARCHAR, physical_io))) OVER() - LEN(CONVERT(VARCHAR, physical_io))) + LEFT(CONVERT(CHAR(22), CONVERT(MONEY, physical_io), 1), 19)) AS '
						WHEN 2 THEN 'CONVERT(VARCHAR, LEFT(CONVERT(CHAR(22), CONVERT(MONEY, physical_io), 1), 19)) AS '
						ELSE ''
					END + 'physical_io, ' +
					--reads
					CASE @format_output
						WHEN 1 THEN 'CONVERT(VARCHAR, SPACE(MAX(LEN(CONVERT(VARCHAR, reads))) OVER() - LEN(CONVERT(VARCHAR, reads))) + LEFT(CONVERT(CHAR(22), CONVERT(MONEY, reads), 1), 19)) AS '
						WHEN 2 THEN 'CONVERT(VARCHAR, LEFT(CONVERT(CHAR(22), CONVERT(MONEY, reads), 1), 19)) AS '
						ELSE ''
					END + 'reads, ' +
					--physical_reads
					CASE @format_output
						WHEN 1 THEN 'CONVERT(VARCHAR, SPACE(MAX(LEN(CONVERT(VARCHAR, physical_reads))) OVER() - LEN(CONVERT(VARCHAR, physical_reads))) + LEFT(CONVERT(CHAR(22), CONVERT(MONEY, physical_reads), 1), 19)) AS '
						WHEN 2 THEN 'CONVERT(VARCHAR, LEFT(CONVERT(CHAR(22), CONVERT(MONEY, physical_reads), 1), 19)) AS '
						ELSE ''
					END + 'physical_reads, ' +
					--writes
					CASE @format_output
						WHEN 1 THEN 'CONVERT(VARCHAR, SPACE(MAX(LEN(CONVERT(VARCHAR, writes))) OVER() - LEN(CONVERT(VARCHAR, writes))) + LEFT(CONVERT(CHAR(22), CONVERT(MONEY, writes), 1), 19)) AS '
						WHEN 2 THEN 'CONVERT(VARCHAR, LEFT(CONVERT(CHAR(22), CONVERT(MONEY, writes), 1), 19)) AS '
						ELSE ''
					END + 'writes, ' +
					--tempdb_allocations
					CASE @format_output
						WHEN 1 THEN 'CONVERT(VARCHAR, SPACE(MAX(LEN(CONVERT(VARCHAR, tempdb_allocations))) OVER() - LEN(CONVERT(VARCHAR, tempdb_allocations))) + LEFT(CONVERT(CHAR(22), CONVERT(MONEY, tempdb_allocations), 1), 19)) AS '
						WHEN 2 THEN 'CONVERT(VARCHAR, LEFT(CONVERT(CHAR(22), CONVERT(MONEY, tempdb_allocations), 1), 19)) AS '
						ELSE ''
					END + 'tempdb_allocations, ' +
					--tempdb_current
					CASE @format_output
						WHEN 1 THEN 'CONVERT(VARCHAR, SPACE(MAX(LEN(CONVERT(VARCHAR, tempdb_current))) OVER() - LEN(CONVERT(VARCHAR, tempdb_current))) + LEFT(CONVERT(CHAR(22), CONVERT(MONEY, tempdb_current), 1), 19)) AS '
						WHEN 2 THEN 'CONVERT(VARCHAR, LEFT(CONVERT(CHAR(22), CONVERT(MONEY, tempdb_current), 1), 19)) AS '
						ELSE ''
					END + 'tempdb_current, ' +
					--CPU
					CASE @format_output
						WHEN 1 THEN 'CONVERT(VARCHAR, SPACE(MAX(LEN(CONVERT(VARCHAR, CPU))) OVER() - LEN(CONVERT(VARCHAR, CPU))) + LEFT(CONVERT(CHAR(22), CONVERT(MONEY, CPU), 1), 19)) AS '
						WHEN 2 THEN 'CONVERT(VARCHAR, LEFT(CONVERT(CHAR(22), CONVERT(MONEY, CPU), 1), 19)) AS '
						ELSE ''
					END + 'CPU, ' +
					--context_switches
					CASE @format_output
						WHEN 1 THEN 'CONVERT(VARCHAR, SPACE(MAX(LEN(CONVERT(VARCHAR, context_switches))) OVER() - LEN(CONVERT(VARCHAR, context_switches))) + LEFT(CONVERT(CHAR(22), CONVERT(MONEY, context_switches), 1), 19)) AS '
						WHEN 2 THEN 'CONVERT(VARCHAR, LEFT(CONVERT(CHAR(22), CONVERT(MONEY, context_switches), 1), 19)) AS '
						ELSE ''
					END + 'context_switches, ' +
					--used_memory
					CASE @format_output
						WHEN 1 THEN 'CONVERT(VARCHAR, SPACE(MAX(LEN(CONVERT(VARCHAR, used_memory))) OVER() - LEN(CONVERT(VARCHAR, used_memory))) + LEFT(CONVERT(CHAR(22), CONVERT(MONEY, used_memory), 1), 19)) AS '
						WHEN 2 THEN 'CONVERT(VARCHAR, LEFT(CONVERT(CHAR(22), CONVERT(MONEY, used_memory), 1), 19)) AS '
						ELSE ''
					END + 'used_memory, ' +
					CASE
						WHEN @output_column_list LIKE '%|_delta|]%' ESCAPE '|' THEN
							--physical_io_delta			
							'CASE ' +
								'WHEN ' +
									'first_request_start_time = last_request_start_time ' + 
									'AND num_events = 2 ' +
									'AND physical_io_delta >= 0 ' +
										'THEN ' +
										CASE @format_output
											WHEN 1 THEN 'CONVERT(VARCHAR, SPACE(MAX(LEN(CONVERT(VARCHAR, physical_io_delta))) OVER() - LEN(CONVERT(VARCHAR, physical_io_delta))) + LEFT(CONVERT(CHAR(22), CONVERT(MONEY, physical_io_delta), 1), 19)) ' 
											WHEN 2 THEN 'CONVERT(VARCHAR, LEFT(CONVERT(CHAR(22), CONVERT(MONEY, physical_io_delta), 1), 19)) '
											ELSE 'physical_io_delta '
										END +
								'ELSE NULL ' +
							'END AS physical_io_delta, ' +
							--reads_delta
							'CASE ' +
								'WHEN ' +
									'first_request_start_time = last_request_start_time ' + 
									'AND num_events = 2 ' +
									'AND reads_delta >= 0 ' +
										'THEN ' +
										CASE @format_output
											WHEN 1 THEN 'CONVERT(VARCHAR, SPACE(MAX(LEN(CONVERT(VARCHAR, reads_delta))) OVER() - LEN(CONVERT(VARCHAR, reads_delta))) + LEFT(CONVERT(CHAR(22), CONVERT(MONEY, reads_delta), 1), 19)) '
											WHEN 2 THEN 'CONVERT(VARCHAR, LEFT(CONVERT(CHAR(22), CONVERT(MONEY, reads_delta), 1), 19)) '
											ELSE 'reads_delta '
										END +
								'ELSE NULL ' +
							'END AS reads_delta, ' +
							--physical_reads_delta
							'CASE ' +
								'WHEN ' +
									'first_request_start_time = last_request_start_time ' + 
									'AND num_events = 2 ' +
									'AND physical_reads_delta >= 0 ' +
										'THEN ' +
										CASE @format_output
											WHEN 1 THEN 'CONVERT(VARCHAR, SPACE(MAX(LEN(CONVERT(VARCHAR, physical_reads_delta))) OVER() - LEN(CONVERT(VARCHAR, physical_reads_delta))) + LEFT(CONVERT(CHAR(22), CONVERT(MONEY, physical_reads_delta), 1), 19)) '
											WHEN 2 THEN 'CONVERT(VARCHAR, LEFT(CONVERT(CHAR(22), CONVERT(MONEY, physical_reads_delta), 1), 19)) '
											ELSE 'physical_reads_delta '
										END + 
								'ELSE NULL ' +
							'END AS physical_reads_delta, ' +
							--writes_delta
							'CASE ' +
								'WHEN ' +
									'first_request_start_time = last_request_start_time ' + 
									'AND num_events = 2 ' +
									'AND writes_delta >= 0 ' +
										'THEN ' +
										CASE @format_output
											WHEN 1 THEN 'CONVERT(VARCHAR, SPACE(MAX(LEN(CONVERT(VARCHAR, writes_delta))) OVER() - LEN(CONVERT(VARCHAR, writes_delta))) + LEFT(CONVERT(CHAR(22), CONVERT(MONEY, writes_delta), 1), 19)) '
											WHEN 2 THEN 'CONVERT(VARCHAR, LEFT(CONVERT(CHAR(22), CONVERT(MONEY, writes_delta), 1), 19)) '
											ELSE 'writes_delta '
										END + 
								'ELSE NULL ' +
							'END AS writes_delta, ' +
							--tempdb_allocations_delta
							'CASE ' +
								'WHEN ' +
									'first_request_start_time = last_request_start_time ' + 
									'AND num_events = 2 ' +
									'AND tempdb_allocations_delta >= 0 ' +
										'THEN ' +
										CASE @format_output
											WHEN 1 THEN 'CONVERT(VARCHAR, SPACE(MAX(LEN(CONVERT(VARCHAR, tempdb_allocations_delta))) OVER() - LEN(CONVERT(VARCHAR, tempdb_allocations_delta))) + LEFT(CONVERT(CHAR(22), CONVERT(MONEY, tempdb_allocations_delta), 1), 19)) '
											WHEN 2 THEN 'CONVERT(VARCHAR, LEFT(CONVERT(CHAR(22), CONVERT(MONEY, tempdb_allocations_delta), 1), 19)) '
											ELSE 'tempdb_allocations_delta '
										END + 
								'ELSE NULL ' +
							'END AS tempdb_allocations_delta, ' +
							--tempdb_current_delta
							--this is the only one that can (legitimately) go negative 
							'CASE ' +
								'WHEN ' +
									'first_request_start_time = last_request_start_time ' + 
									'AND num_events = 2 ' +
										'THEN ' +
										CASE @format_output
											WHEN 1 THEN 'CONVERT(VARCHAR, SPACE(MAX(LEN(CONVERT(VARCHAR, tempdb_current_delta))) OVER() - LEN(CONVERT(VARCHAR, tempdb_current_delta))) + LEFT(CONVERT(CHAR(22), CONVERT(MONEY, tempdb_current_delta), 1), 19)) '
											WHEN 2 THEN 'CONVERT(VARCHAR, LEFT(CONVERT(CHAR(22), CONVERT(MONEY, tempdb_current_delta), 1), 19)) '
											ELSE 'tempdb_current_delta '
										END + 
								'ELSE NULL ' +
							'END AS tempdb_current_delta, ' +
							--CPU_delta
							'CASE ' +
								'WHEN ' +
									'first_request_start_time = last_request_start_time ' + 
									'AND num_events = 2 ' +
										'THEN ' +
											'CASE ' +
												'WHEN ' +
													'thread_CPU_delta > CPU_delta ' +
													'AND thread_CPU_delta > 0 ' +
														'THEN ' +
															CASE @format_output
																WHEN 1 THEN 'CONVERT(VARCHAR, SPACE(MAX(LEN(CONVERT(VARCHAR, thread_CPU_delta + CPU_delta))) OVER() - LEN(CONVERT(VARCHAR, thread_CPU_delta))) + LEFT(CONVERT(CHAR(22), CONVERT(MONEY, thread_CPU_delta), 1), 19)) '
																WHEN 2 THEN 'CONVERT(VARCHAR, LEFT(CONVERT(CHAR(22), CONVERT(MONEY, thread_CPU_delta), 1), 19)) '
																ELSE 'thread_CPU_delta '
															END + 
												'WHEN CPU_delta >= 0 THEN ' +
													CASE @format_output
														WHEN 1 THEN 'CONVERT(VARCHAR, SPACE(MAX(LEN(CONVERT(VARCHAR, thread_CPU_delta + CPU_delta))) OVER() - LEN(CONVERT(VARCHAR, CPU_delta))) + LEFT(CONVERT(CHAR(22), CONVERT(MONEY, CPU_delta), 1), 19)) '
														WHEN 2 THEN 'CONVERT(VARCHAR, LEFT(CONVERT(CHAR(22), CONVERT(MONEY, CPU_delta), 1), 19)) '
														ELSE 'CPU_delta '
													END + 
												'ELSE NULL ' +
											'END ' +
								'ELSE ' +
									'NULL ' +
							'END AS CPU_delta, ' +
							--context_switches_delta
							'CASE ' +
								'WHEN ' +
									'first_request_start_time = last_request_start_time ' + 
									'AND num_events = 2 ' +
									'AND context_switches_delta >= 0 ' +
										'THEN ' +
										CASE @format_output
											WHEN 1 THEN 'CONVERT(VARCHAR, SPACE(MAX(LEN(CONVERT(VARCHAR, context_switches_delta))) OVER() - LEN(CONVERT(VARCHAR, context_switches_delta))) + LEFT(CONVERT(CHAR(22), CONVERT(MONEY, context_switches_delta), 1), 19)) '
											WHEN 2 THEN 'CONVERT(VARCHAR, LEFT(CONVERT(CHAR(22), CONVERT(MONEY, context_switches_delta), 1), 19)) '
											ELSE 'context_switches_delta '
										END + 
								'ELSE NULL ' +
							'END AS context_switches_delta, ' +
							--used_memory_delta
							'CASE ' +
								'WHEN ' +
									'first_request_start_time = last_request_start_time ' + 
									'AND num_events = 2 ' +
									'AND used_memory_delta >= 0 ' +
										'THEN ' +
										CASE @format_output
											WHEN 1 THEN 'CONVERT(VARCHAR, SPACE(MAX(LEN(CONVERT(VARCHAR, used_memory_delta))) OVER() - LEN(CONVERT(VARCHAR, used_memory_delta))) + LEFT(CONVERT(CHAR(22), CONVERT(MONEY, used_memory_delta), 1), 19)) '
											WHEN 2 THEN 'CONVERT(VARCHAR, LEFT(CONVERT(CHAR(22), CONVERT(MONEY, used_memory_delta), 1), 19)) '
											ELSE 'used_memory_delta '
										END + 
								'ELSE NULL ' +
							'END AS used_memory_delta, '
						ELSE ''
					END +
					--tasks
					CASE @format_output
						WHEN 1 THEN 'CONVERT(VARCHAR, SPACE(MAX(LEN(CONVERT(VARCHAR, tasks))) OVER() - LEN(CONVERT(VARCHAR, tasks))) + LEFT(CONVERT(CHAR(22), CONVERT(MONEY, tasks), 1), 19)) AS '
						WHEN 2 THEN 'CONVERT(VARCHAR, LEFT(CONVERT(CHAR(22), CONVERT(MONEY, tasks), 1), 19)) '
						ELSE ''
					END + 'tasks, ' +
					'status, ' +
					'wait_info, ' +
					'locks, ' +
					'tran_start_time, ' +
					'LEFT(tran_log_writes, LEN(tran_log_writes) - 1) AS tran_log_writes, ' +
					--open_tran_count
					CASE @format_output
						WHEN 1 THEN 'CONVERT(VARCHAR, SPACE(MAX(LEN(CONVERT(VARCHAR, open_tran_count))) OVER() - LEN(CONVERT(VARCHAR, open_tran_count))) + LEFT(CONVERT(CHAR(22), CONVERT(MONEY, open_tran_count), 1), 19)) AS '
						WHEN 2 THEN 'CONVERT(VARCHAR, LEFT(CONVERT(CHAR(22), CONVERT(MONEY, open_tran_count), 1), 19)) AS '
						ELSE ''
					END + 'open_tran_count, ' +
					--sql_command
					CASE @format_output 
						WHEN 0 THEN 'REPLACE(REPLACE(CONVERT(NVARCHAR(MAX), sql_command), ''<?query --''+CHAR(13)+CHAR(10), ''''), CHAR(13)+CHAR(10)+''--?>'', '''') AS '
						ELSE ''
					END + 'sql_command, ' +
					--sql_text
					CASE @format_output 
						WHEN 0 THEN 'REPLACE(REPLACE(CONVERT(NVARCHAR(MAX), sql_text), ''<?query --''+CHAR(13)+CHAR(10), ''''), CHAR(13)+CHAR(10)+''--?>'', '''') AS '
						ELSE ''
					END + 'sql_text, ' +
					'query_plan, ' +
					'blocking_session_id, ' +
					--blocked_session_count
					CASE @format_output
						WHEN 1 THEN 'CONVERT(VARCHAR, SPACE(MAX(LEN(CONVERT(VARCHAR, blocked_session_count))) OVER() - LEN(CONVERT(VARCHAR, blocked_session_count))) + LEFT(CONVERT(CHAR(22), CONVERT(MONEY, blocked_session_count), 1), 19)) AS '
						WHEN 2 THEN 'CONVERT(VARCHAR, LEFT(CONVERT(CHAR(22), CONVERT(MONEY, blocked_session_count), 1), 19)) AS '
						ELSE ''
					END + 'blocked_session_count, ' +
					--percent_complete
					CASE @format_output
						WHEN 1 THEN 'CONVERT(VARCHAR, SPACE(MAX(LEN(CONVERT(VARCHAR, CONVERT(MONEY, percent_complete), 2))) OVER() - LEN(CONVERT(VARCHAR, CONVERT(MONEY, percent_complete), 2))) + CONVERT(CHAR(22), CONVERT(MONEY, percent_complete), 2)) AS '
						WHEN 2 THEN 'CONVERT(VARCHAR, CONVERT(CHAR(22), CONVERT(MONEY, blocked_session_count), 1)) AS '
						ELSE ''
					END + 'percent_complete, ' +
					'host_name, ' +
					'login_name, ' +
					'database_name, ' +
					'program_name, ' +
					'additional_info, ' +
					'start_time, ' +
					'login_time, ' +
					'CASE ' +
						'WHEN status = N''sleeping'' THEN NULL ' +
						'ELSE request_id ' +
					'END AS request_id, ' +
					'GETDATE() AS collection_time '
		--End inner column list
		) +
		--Derived table and INSERT specification
		CONVERT
		(
			VARCHAR(MAX),
				'FROM ' +
				'( ' +
					'SELECT TOP(2147483647) ' +
						'*, ' +
						'CASE ' +
							'MAX ' +
							'( ' +
								'LEN ' +
								'( ' +
									'CONVERT ' +
									'( ' +
										'VARCHAR, ' +
										'CASE ' +
											'WHEN elapsed_time < 0 THEN ' +
												'(-1 * elapsed_time) / 86400 ' +
											'ELSE ' +
												'elapsed_time / 86400000 ' +
										'END ' +
									') ' +
								') ' +
							') OVER () ' +
								'WHEN 1 THEN 2 ' +
								'ELSE ' +
									'MAX ' +
									'( ' +
										'LEN ' +
										'( ' +
											'CONVERT ' +
											'( ' +
												'VARCHAR, ' +
												'CASE ' +
													'WHEN elapsed_time < 0 THEN ' +
														'(-1 * elapsed_time) / 86400 ' +
													'ELSE ' +
														'elapsed_time / 86400000 ' +
												'END ' +
											') ' +
										') ' +
									') OVER () ' +
						'END AS max_elapsed_length, ' +
						CASE
							WHEN @output_column_list LIKE '%|_delta|]%' ESCAPE '|' THEN
								'MAX(physical_io * recursion) OVER (PARTITION BY session_id, request_id) + ' +
									'MIN(physical_io * recursion) OVER (PARTITION BY session_id, request_id) AS physical_io_delta, ' +
								'MAX(reads * recursion) OVER (PARTITION BY session_id, request_id) + ' +
									'MIN(reads * recursion) OVER (PARTITION BY session_id, request_id) AS reads_delta, ' +
								'MAX(physical_reads * recursion) OVER (PARTITION BY session_id, request_id) + ' +
									'MIN(physical_reads * recursion) OVER (PARTITION BY session_id, request_id) AS physical_reads_delta, ' +
								'MAX(writes * recursion) OVER (PARTITION BY session_id, request_id) + ' +
									'MIN(writes * recursion) OVER (PARTITION BY session_id, request_id) AS writes_delta, ' +
								'MAX(tempdb_allocations * recursion) OVER (PARTITION BY session_id, request_id) + ' +
									'MIN(tempdb_allocations * recursion) OVER (PARTITION BY session_id, request_id) AS tempdb_allocations_delta, ' +
								'MAX(tempdb_current * recursion) OVER (PARTITION BY session_id, request_id) + ' +
									'MIN(tempdb_current * recursion) OVER (PARTITION BY session_id, request_id) AS tempdb_current_delta, ' +
								'MAX(CPU * recursion) OVER (PARTITION BY session_id, request_id) + ' +
									'MIN(CPU * recursion) OVER (PARTITION BY session_id, request_id) AS CPU_delta, ' +
								'MAX(thread_CPU_snapshot * recursion) OVER (PARTITION BY session_id, request_id) + ' +
									'MIN(thread_CPU_snapshot * recursion) OVER (PARTITION BY session_id, request_id) AS thread_CPU_delta, ' +
								'MAX(context_switches * recursion) OVER (PARTITION BY session_id, request_id) + ' +
									'MIN(context_switches * recursion) OVER (PARTITION BY session_id, request_id) AS context_switches_delta, ' +
								'MAX(used_memory * recursion) OVER (PARTITION BY session_id, request_id) + ' +
									'MIN(used_memory * recursion) OVER (PARTITION BY session_id, request_id) AS used_memory_delta, ' +
								'MIN(last_request_start_time) OVER (PARTITION BY session_id, request_id) AS first_request_start_time, '
							ELSE ''
						END +
						'COUNT(*) OVER (PARTITION BY session_id, request_id) AS num_events ' +
					'FROM #sessions AS s1 ' +
					CASE 
						WHEN @sort_order = '' THEN ''
						ELSE
							'ORDER BY ' +
								@sort_order
					END +
				') AS s ' +
				'WHERE ' +
					's.recursion = 1 ' +
			') x ' +
			'OPTION (KEEPFIXED PLAN); ' +
			'' +
			CASE @return_schema
				WHEN 1 THEN
					'SET @schema = ' +
						'''CREATE TABLE <table_name> ( '' + ' +
							'STUFF ' +
							'( ' +
								'( ' +
									'SELECT ' +
										''','' + ' +
										'QUOTENAME(COLUMN_NAME) + '' '' + ' +
										'DATA_TYPE + ' + 
										'CASE ' +
											'WHEN DATA_TYPE LIKE ''%char'' THEN ''('' + COALESCE(NULLIF(CONVERT(VARCHAR, CHARACTER_MAXIMUM_LENGTH), ''-1''), ''max'') + '') '' ' +
											'ELSE '' '' ' +
										'END + ' +
										'CASE IS_NULLABLE ' +
											'WHEN ''NO'' THEN ''NOT '' ' +
											'ELSE '''' ' +
										'END + ''NULL'' AS [text()] ' +
									'FROM tempdb.INFORMATION_SCHEMA.COLUMNS ' +
									'WHERE ' +
										'TABLE_NAME = (SELECT name FROM tempdb.sys.objects WHERE object_id = OBJECT_ID(''tempdb..#session_schema'')) ' +
										'ORDER BY ' +
											'ORDINAL_POSITION ' +
									'FOR XML ' +
										'PATH('''') ' +
								'), + ' +
								'1, ' +
								'1, ' +
								''''' ' +
							') + ' +
						''')''; ' 
				ELSE ''
			END
		--End derived table and INSERT specification
		);

	SET @sql_n = CONVERT(NVARCHAR(MAX), @sql);

	EXEC sp_executesql
		@sql_n,
		N'@schema VARCHAR(MAX) OUTPUT',
		@schema OUTPUT;
END;




GO

/****** Object:  StoredProcedure [dbo].[sp_Worst_TSQL]    Script Date: 04/23/2015 11:14:12 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO




CREATE PROC [dbo].[sp_Worst_TSQL]
/*
Written by: Gregory A. Larsen
Copyright © 2008 Gregory A. Larsen. All rights reserved.
Name: usp_Worst_TSQL
Description: This stored procedure displays the top worst performing queries based on CPU, Execution Count,
             I/O and Elapsed_Time as identified using DMV information. This can be display the worst
             performing queries from an instance, or database perspective.   The number of records shown,
             the database, and the sort order are identified by passing pararmeters.
Parameters: There are three different parameters that can be passed to this procedures: @DBNAME, @COUNT
             and @ORDERBY. The @DBNAME is used to constraint the output to a specific database. If
             when calling this SP this parameter is set to a specific database name then only statements
             that are associated with that database will be displayed. If the @DBNAME parameter is not set
             then this SP will return rows associated with any database. The @COUNT parameter allows you
             to control the number of rows returned by this SP. If this parameter is used then only the
             TOP x rows, where x is equal to @COUNT will be returned, based on the @ORDERBY parameter.
             The @ORDERBY parameter identifies the sort order of the rows returned in descending order.
             This @ORDERBY parameters supports the following type: CPU, AE, TE, EC or AIO, TIO, ALR, TLR, ALW, TLW, APR, and TPR
             where "ACPU" represents Average CPU Usage
                   "TCPU" represents Total CPU usage
                   "AE"   represents Average Elapsed Time
                   "TE"   represents Total Elapsed Time
                   "EC"   represents Execution Count
                   "AIO" represents Average IOs
                   "TIO" represents Total IOs
                   "ALR" represents Average Logical Reads
                   "TLR" represents Total Logical Reads
                   "ALW" represents Average Logical Writes
                   "TLW" represents Total Logical Writes
                   "APR" represents Average Physical Reads
                   "TPR" represents Total Physical Read
Typical execution calls

   Top 6 statements in the AdventureWorks database base on Average CPU Usage:
      EXEC usp_Worst_TSQL @DBNAME='AdventureWorks',@COUNT=6,@ORDERBY='ACPU';

   Top 100 statements order by Average IO
      EXEC usp_Worst_TSQL @COUNT=100,@ORDERBY='ALR';
   Show top 100 statements by Average IO
      EXEC usp_Worst_TSQL;
*/
(@DBNAME VARCHAR(128) = ''
 ,@COUNT INT = 999999999
 ,@ORDERBY VARCHAR(4) = 'AIO')
AS
-- Check for valid @ORDERBY parameter
IF ((SELECT CASE WHEN
          @ORDERBY in ('ACPU','TCPU','AE','TE','EC','AIO','TIO','ALR','TLR','ALW','TWL','APR','TPR')
             THEN 1 ELSE 0 END) = 0)
BEGIN
   -- abort if invalid @ORDERBY parameter entered
   RAISERROR('@ORDERBY parameter not APCU, TCPU, AE, TE, EC, AIO, TIO, ALR, TLR, ALW, TLW, APR or TPR',11,1)
   RETURN
 END
 SELECT TOP (@COUNT)
         COALESCE(DB_NAME(st.dbid),
                  DB_NAME(CAST(pa.value AS INT))+'*',
                 'Resource') AS [Database Name]
         -- find the offset of the actual statement being executed
         ,SUBSTRING(text,
                   CASE WHEN statement_start_offset = 0
                          OR statement_start_offset IS NULL
                           THEN 1
                           ELSE statement_start_offset/2 + 1 END,
                   CASE WHEN statement_end_offset = 0
                          OR statement_end_offset = -1
                          OR statement_end_offset IS NULL
                           THEN LEN(text)
                           ELSE statement_end_offset/2 END -
                     CASE WHEN statement_start_offset = 0
                            OR statement_start_offset IS NULL
                             THEN 1
                             ELSE statement_start_offset/2 END + 1
                  ) AS [Statement]
         ,OBJECT_SCHEMA_NAME(st.objectid,dbid) [Schema Name]
         ,OBJECT_NAME(st.objectid,dbid) [Object Name]
         ,objtype [Cached Plan objtype]
         ,execution_count [Execution Count]
         ,(total_logical_reads + total_logical_writes + total_physical_reads )/execution_count [Average IOs]
         ,total_logical_reads + total_logical_writes + total_physical_reads [Total IOs]
         ,total_logical_reads/execution_count [Avg Logical Reads]
         ,total_logical_reads [Total Logical Reads]
         ,total_logical_writes/execution_count [Avg Logical Writes]
         ,total_logical_writes [Total Logical Writes]
         ,total_physical_reads/execution_count [Avg Physical Reads]
         ,total_physical_reads [Total Physical Reads]
         ,total_worker_time / execution_count [Avg CPU]
         ,total_worker_time [Total CPU]
         ,total_elapsed_time / execution_count [Avg Elapsed Time]
         ,total_elapsed_time [Total Elasped Time]
         ,last_execution_time [Last Execution Time]
    FROM sys.dm_exec_query_stats qs
    JOIN sys.dm_exec_cached_plans cp ON qs.plan_handle = cp.plan_handle
    CROSS APPLY sys.dm_exec_sql_text(qs.plan_handle) st
    OUTER APPLY sys.dm_exec_plan_attributes(qs.plan_handle) pa
    WHERE attribute = 'dbid' AND
     CASE when @DBNAME = '' THEN ''
                               ELSE COALESCE(DB_NAME(st.dbid),
                                          DB_NAME(CAST(pa.value AS INT)) + '*',
                                          'Resource') END
                                    IN (RTRIM(@DBNAME),RTRIM(@DBNAME) + '*') 

    ORDER BY CASE
                WHEN @ORDERBY = 'ACPU' THEN total_worker_time / execution_count
                WHEN @ORDERBY = 'TCPU' THEN total_worker_time
                WHEN @ORDERBY = 'AE'   THEN total_elapsed_time / execution_count
                WHEN @ORDERBY = 'TE'   THEN total_elapsed_time
                WHEN @ORDERBY = 'EC'   THEN execution_count
                WHEN @ORDERBY = 'AIO' THEN (total_logical_reads + total_logical_writes + total_physical_reads) / execution_count
                WHEN @ORDERBY = 'TIO' THEN total_logical_reads + total_logical_writes + total_physical_reads
                WHEN @ORDERBY = 'ALR' THEN total_logical_reads / execution_count
                WHEN @ORDERBY = 'TLR' THEN total_logical_reads
                WHEN @ORDERBY = 'ALW' THEN total_logical_writes / execution_count
                WHEN @ORDERBY = 'TLW' THEN total_logical_writes
                WHEN @ORDERBY = 'APR' THEN total_physical_reads / execution_count
                WHEN @ORDERBY = 'TPR' THEN total_physical_reads
           END DESC



GO


