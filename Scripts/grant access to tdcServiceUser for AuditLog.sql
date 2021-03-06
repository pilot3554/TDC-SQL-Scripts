USE [master]
GO
CREATE USER [tdcServiceUser] FOR LOGIN [tdcServiceUser]
GO

USE [msdb]
GO
CREATE USER [tdcServiceUser] FOR LOGIN [tdcServiceUser]
GO

USE [master]
GO
EXEC sp_addrolemember N'db_datareader', N'tdcServiceUser'
GO
USE [master]
GO
EXEC sp_droprolemember N'db_datawriter', N'tdcServiceUser'
GO
use [master]
GO
GRANT INSERT ON [dbo].[AuditLog] TO [tdcServiceUser]
GO
use [master]
GO
GRANT SELECT ON [dbo].[AuditLog] TO [tdcServiceUser]
GO
use [master]
GO
GRANT INSERT ON [dbo].[AuditLog] TO public
GO
use [master]
GO
GRANT SELECT ON [dbo].[AuditLog] TO public
GO


USE [msdb]
GO
EXEC sp_addrolemember N'db_datareader', N'tdcServiceUser'
GO
grant select on [dbo].[sysoperators] to public
GO

/*
disable trigger trg_UserChangesTrack  On All Server
enable trigger trg_UserChangesTrack  On All Server
*/
