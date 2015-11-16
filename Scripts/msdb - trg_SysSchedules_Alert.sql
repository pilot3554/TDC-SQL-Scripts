USE msdb 
GO 
IF  EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[trg_SysSchedules_Alert]'))
DROP TRIGGER [dbo].[trg_SysSchedules_Alert]
GO
CREATE TRIGGER trg_SysSchedules_Alert
ON sysschedules  
FOR UPDATE AS 
SET NOCOUNT ON 

DECLARE @UserName VARCHAR(50) 
DECLARE @HostName VARCHAR(50)
DECLARE @schedulename VARCHAR(100)
DECLARE @scheduleid INT
DECLARE @JobName VARCHAR(100)
DECLARE @JobID UNIQUEIDENTIFIER
DECLARE @DeletedJobName VARCHAR(100)
DECLARE @New_Enabled INT 
DECLARE @Old_Enabled INT
DECLARE @Bodytext VARCHAR(200)
DECLARE @SubjectText VARCHAR(200)
DECLARE @Servername VARCHAR(50)
DECLARE @operators VARCHAR(100)
DECLARE @EventType NVARCHAR(MAX)
DECLARE @SchemaName NVARCHAR(MAX)
DECLARE @DatabaseName NVARCHAR(300)
DECLARE @CommandText NVARCHAR(MAX)
DECLARE @ObjectName NVARCHAR(MAX)
DECLARE @ObjectType NVARCHAR(MAX)
DECLARE @tableHTML NVARCHAR(MAX) 
DECLARE @StartTime NVARCHAR(MAX) 
DECLARE @_recipients NVARCHAR(1000)

SELECT @UserName = SYSTEM_USER, @HostName = HOST_NAME() 
SELECT @New_Enabled = Enabled FROM Inserted 
SELECT @Old_Enabled = Enabled FROM Deleted 
SELECT @scheduleid = Schedule_id FROM Deleted
SELECT @Servername = @@servername
SELECT @schedulename = name FROM Inserted
SELECT @operators = 'Prod DBA'
SET @jobname = ''
SELECT @jobname = @jobname + name+', ' FROM dbo.sysjobs WHERE job_id IN (SELECT job_id FROM dbo.sysjobschedules WHERE schedule_id = @scheduleid)

-- check if the enabled flag has been updated.
IF @New_Enabled <> @Old_Enabled 
BEGIN 

	SELECT 
	@EventType = 'MSDB Job Modification'
	,@DatabaseName = 'MSDB'
	,@SchemaName = 'dbo'
	,@ObjectName = 'sysjobs'
	,@ObjectType = 'JOB'
	,@CommandText = ''
	,@StartTime = GETDATE()

	IF @New_Enabled = 1 
	BEGIN 
		SET @bodytext = 'User: '+@username+' from '+@hostname+' ENABLED Job Schedule ['+@schedulename+'] on Job ['+@jobname+'] at '+CONVERT(VARCHAR(20),GETDATE(),100) 
		SET @subjecttext = 'SQL Job Schedule on '+@Servername+' : ['+@jobname+'] : ['+@schedulename+'] has been ENABLED at '+CONVERT(VARCHAR(20),GETDATE(),100) 
		SET @tableHTML ='User: '+@username+'<br>From '+@hostname+'<br><b><font size="3" color="red">ENABLED</font> Job Schedule ['+@schedulename+'] on Job ['+@jobname+']</b><br>at '+CONVERT(VARCHAR(20),GETDATE(),100)+' (PST)'
	END 

	IF @New_Enabled = 0 
	BEGIN 
		SET @bodytext = 'User: '+@username+' from '+@hostname+' DISABLED Job Schedule ['+@schedulename+'] on Job ['+@jobname+'] at '+CONVERT(VARCHAR(20),GETDATE(),100) 
		SET @subjecttext = 'SQL Job Schedule on '+@Servername+' : ['+@jobname+'] : ['+@schedulename+'] has been DISABLED at '+CONVERT(VARCHAR(20),GETDATE(),100) 
		SET @tableHTML ='User: '+@username+'<br>From '+@hostname+'<br><b><font size="3" color="red">DISABLED</font> Job Schedule ['+@schedulename+'] on Job ['+@jobname+']</b><br>at '+CONVERT(VARCHAR(20),GETDATE(),100)+' (PST)'
	END 


	IF  EXISTS (SELECT NAME FROM msdb.dbo.sysoperators WHERE NAME = @operators )
	BEGIN
		SET @_recipients = (SELECT email_address FROM msdb.dbo.sysoperators WHERE NAME = @operators )
		EXEC msdb.dbo.sp_send_dbmail @recipients = @_recipients, @subject = @subjecttext, @body = @tableHTML, @body_format = 'HTML', @exclude_query_output = 1
	END

	IF OBJECT_ID('master.dbo.auditlog') > 0
	BEGIN
		INSERT INTO master.[dbo].[AuditLog]
				   ([AuditServerName]
				   ,[AuditDatabaseName]
				   ,[AuditEvent]
				   ,[AuditSchemaName]
				   ,[AuditObjectName]
				   ,[AuditObjectType]
				   ,[AuditDesc]
				   ,[AuditDatetime]
				   ,[AuditLoginName])
			 VALUES
				   (@@SERVERNAME
				   ,@DatabaseName
				   ,@EventType
				   ,@SchemaName
				   ,@ObjectName
				   ,@ObjectType
				   ,@bodytext
				   ,@StartTime
				   ,ORIGINAL_LOGIN())	
	END
			   
END
GO
