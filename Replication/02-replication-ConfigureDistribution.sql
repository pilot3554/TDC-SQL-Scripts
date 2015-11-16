--run on DB01-PROD

select @@SERVERNAME
/****** Scripting replication configuration. Script Date: 6/18/2015 12:01:34 PM ******/
/****** Please Note: For security reasons, all password parameters were scripted with either NULL or an empty string. ******/
EXEC master.dbo.sp_serveroption @server=N'lv1-s-mssql-101', @optname=N'dist', @optvalue=N'true'
GO

EXEC sp_dropdistributor @no_checks = 1, @ignore_distributor = 1
GO

/****** Installing the server as a Distributor. Script Date: 6/18/2015 12:01:34 PM ******/
use master
exec sp_adddistributor @distributor = N'lv1-s-mssql-101', @password = N'We''reinthe$$$'
GO
exec sp_adddistributiondb @database = N'distribution', @data_folder = N'G:\DBFiles', @log_folder = N'L:\DBFiles', @log_file_size = 2, @min_distretention = 0, @max_distretention = 72, @history_retention = 48, @security_mode = 1
GO

use [distribution] 
if (not exists (select * from sysobjects where name = 'UIProperties' and type = 'U ')) 
	create table UIProperties(id int) 
if (exists (select * from ::fn_listextendedproperty('SnapshotFolder', 'user', 'dbo', 'table', 'UIProperties', null, null))) 
	EXEC sp_updateextendedproperty N'SnapshotFolder', N'F:\Program Files\Microsoft SQL Server\MSSQL10_50.MSSQLSERVER\MSSQL\ReplData', 'user', dbo, 'table', 'UIProperties' 
else 
	EXEC sp_addextendedproperty N'SnapshotFolder', N'F:\Program Files\Microsoft SQL Server\MSSQL10_50.MSSQLSERVER\MSSQL\ReplData', 'user', dbo, 'table', 'UIProperties'
GO

exec sp_adddistpublisher @publisher = N'lv1-s-mssql-101', @distribution_db = N'distribution', @security_mode = 1, @working_directory = N'F:\Program Files\Microsoft SQL Server\MSSQL10_50.MSSQLSERVER\MSSQL\ReplData', @trusted = N'false', @thirdparty_flag = 0, @publisher_type = N'MSSQLSERVER'
GO
