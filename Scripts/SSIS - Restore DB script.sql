USE TDCAdminDB
GO
UPDATE [DatabaseRestoreSetting] SET ActiveFlag = 0, restoreonly =  0
GO
SELECT * FROM [dbo].[DatabaseRestoreSetting] WHERE Environment = 'dev' AND SourceDatabase IN ('kalmus', 'KalmusMastering')
GO
UPDATE [DatabaseRestoreSetting]
SET PointInTimeRestore = '2015-04-04 08:30:00', ActiveFlag = 1
WHERE Environment = 'DEV' AND SourceDatabase IN ('kalmus', 'KalmusMastering') --AND TargetServer = 'BRBK632LW12'
GO
SELECT * FROM [dbo].[DatabaseRestoreSetting] WHERE Environment = 'dev' AND SourceDatabase IN ('kalmus', 'KalmusMastering')
GO

EXEC msdb..sp_start_job @job_name = 'Restore DEV environment'
GO

SELECT * FROM test ORDER BY 1 DESC
SELECT * FROM DatabaseRestoreProgress ORDER BY CreatedDate desc
SELECT * FROM [dbo].[DatabaseBackupSet]
SELECT * FROM [dbo].[DatabaseRestoreHistory] ORDER BY CreatedDate desc
SELECT * FROM [dbo].[DatabaseRestoreSetting] WHERE Environment = 'DEV'
