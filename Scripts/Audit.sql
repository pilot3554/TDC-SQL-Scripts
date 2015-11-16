USE [master]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF  EXISTS (SELECT * FROM master.sys.server_triggers WHERE parent_class_desc = 'SERVER' AND name = N'trg_UserChangesTrack')
DROP TRIGGER [trg_UserChangesTrack] ON ALL SERVER
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[AuditLog]') AND type in (N'U'))
DROP TABLE [dbo].[AuditLog]
GO



CREATE TABLE [dbo].[AuditLog](
	[LineID] [int] IDENTITY(1,1) NOT NULL,
	[AuditLoginName] [nvarchar](50) NULL,
	[AuditDatetime] [datetimeoffset](7) NULL,
	[AuditServerName] [nvarchar](50) NULL,
	[AuditDatabaseName] [nvarchar](50) NULL,
	[AuditEvent] [nvarchar](1000) NULL,
	[AuditSchemaName] [nvarchar](50) NULL,
	[AuditObjectName] [nvarchar](50) NULL,
	[AuditObjectType] [nvarchar](50) NULL,
	[AuditDesc] [nvarchar](max) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO


Use Master 
Go

/*
disable trigger trg_UserChangesTrack  On All Server
enable trigger trg_UserChangesTrack  On All Server
*/
ALTER TRIGGER [trg_UserChangesTrack] 
On All Server 
FOR DDL_EVENTS
As

set nocount on;

DECLARE @EventType NVARCHAR(MAX)
DECLARE @SchemaName NVARCHAR(MAX)
DECLARE @DatabaseName NVARCHAR(300)
DECLARE @CommandText NVARCHAR(MAX)
DECLARE @ObjectName NVARCHAR(MAX)
DECLARE @ObjectType NVARCHAR(MAX)
DECLARE @tableHTML NVARCHAR(Max) 
DECLARE @StartTime NVARCHAR(Max) 
DECLARE @_subject NVARCHAR(100)
DECLARE @_recipients NVARCHAR(1000)

Begin 
	SELECT 
		@EventType = IsNull(EVENTDATA().value('(/EVENT_INSTANCE/EventType)[1]','nvarchar(max)'), '') 
		,@DatabaseName = IsNull(EVENTDATA().value('(/EVENT_INSTANCE/DatabaseName)[1]','nvarchar(300)'), '') 
		,@SchemaName = IsNull(EVENTDATA().value('(/EVENT_INSTANCE/SchemaName)[1]','nvarchar(max)'), '') 
		,@ObjectName = IsNull(EVENTDATA().value('(/EVENT_INSTANCE/ObjectName)[1]','nvarchar(max)'), '')
		,@ObjectType = IsNull(EVENTDATA().value('(/EVENT_INSTANCE/ObjectType)[1]','nvarchar(max)'), '')
		,@CommandText = IsNull(EVENTDATA().value('(/EVENT_INSTANCE/TSQLCommand/CommandText)[1]','nvarchar(max)'), '')
		,@StartTime = IsNull(EVENTDATA().value('(/EVENT_INSTANCE/PostTime)[1]','nvarchar(max)'), '')

	SET @tableHTML =
		N'<table border="1">' +
		N'<tr><th>User</th><td>' + ORIGINAL_LOGIN() + '</td></tr>' +
		N'<tr><th>Event Type</th><td>' + @EventType + '</td></tr>' +
		N'<tr><th>Start Time</th><td>' + @StartTime + '</td></tr>' +
		N'<tr><th>Database Name</th><td>' + @DatabaseName + '</td></tr>' +
		N'<tr><th>Schema Name</th><td>' + @SchemaName + '</td></tr>' +
		N'<tr><th>Object Name</th><td>' + @ObjectName + '</td></tr>' +
		N'<tr><th>Object Type</th><td>' + @ObjectType + '</td></tr>' +
		N'<tr><th>SQL Statement</th><td>' + @CommandText + '</td></tr>' +
		N'</table>' ;


	INSERT INTO [dbo].[AuditLog]
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
			   ,@CommandText
			   ,@StartTime
			   ,ORIGINAL_LOGIN())	

	if(ORIGINAL_LOGIN() != 'TDCINEMA\_sqlserver' and @ObjectType not in ('INDEX','STATISTICS'))
	Begin
		set @_subject = @@servername+' Server Audit'
		
		IF  EXISTS (SELECT name FROM msdb.dbo.sysoperators WHERE name = N'DBA')
			begin
				set @_recipients = (select email_address from msdb.dbo.sysoperators WHERE name = N'DBA')
				Exec msdb.dbo.sp_send_dbmail @recipients = @_recipients, @subject = @_subject, @body = @tableHTML, @body_format = 'HTML', @exclude_query_output = 1
			end
	End

End 


GO


SET ANSI_NULLS OFF
GO

SET QUOTED_IDENTIFIER OFF
GO
