-- [sp_job_info]
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

-------------------------------------------------------


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
--where msdb.dbo.sysjobs.name like '%DCT%'
order by 2