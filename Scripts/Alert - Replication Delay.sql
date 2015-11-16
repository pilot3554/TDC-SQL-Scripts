DECLARE @tableHTML  NVARCHAR(MAX)

if(OBJECT_ID('tempdb..#tmp')>1)
drop table #tmp

;WITH LastRestores AS
(
SELECT
    DatabaseName = [d].[name] ,
    [d].[create_date] ,
    [d].[compatibility_level] ,
    [d].[collation_name] ,
    r.*,
    RowNum = ROW_NUMBER() OVER (PARTITION BY d.Name ORDER BY r.[restore_date] DESC)
FROM master.sys.databases d
LEFT OUTER JOIN msdb.dbo.[restorehistory] r ON r.[destination_database_name] = d.Name
)
SELECT rtrim(ltrim(DatabaseName)) as DatabaseName ,convert(varchar,restore_date) as [LastRestoreDate] 
into #tmp
FROM [LastRestores]
WHERE [RowNum] = 1
and restore_date is not null
and restore_date < dateadd(mi, -30,GETDATE())
and DatabaseName in ('alert','alertcrm','AlertViewState','CineCaster','CrushFTP','DeploymentDB','Kalmus','KalmusMastering','TDC_DB01','KalmusFLM','_Test_log_Shipping')

SET @tableHTML =
	N'<H1>Delayed Log Shipping over 30 minutes</H1>' +
	N'<table border="1">' +
	N'<tr><th>DB</th><th>Last Restore</th></tr>' +
	CAST ( ( SELECT td = DatabaseName ,       '',
	                td = [LastRestoreDate] ,       ''
					FROM #tmp
			  FOR XML PATH('tr'), TYPE 
	) AS NVARCHAR(MAX) ) +
	N'</table>' ;
print @tableHTML
	
if exists(select * From #tmp)
begin


exec msdb.dbo.sp_send_dbmail
@recipients = 'patrick.alexander@technicolor.com;Sylvain.Delporte@technicolor.com'
,@subject = 'DB Log Shipping Delayed'
,@body = @tableHTML
,@body_format = 'HTML' 


end

