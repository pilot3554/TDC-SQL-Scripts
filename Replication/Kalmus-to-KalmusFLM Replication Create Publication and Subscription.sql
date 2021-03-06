/*
--make sure any server level triggers are disabled
DISABLE trigger trg_UserChangesTrack  On All Server
enable trigger trg_UserChangesTrack  On All SERVER
*/

-- Enabling the replication database
use master
exec sp_replicationdboption @dbname = N'Kalmus', @optname = N'publish', @value = N'true'
GO

-- Adding the transactional publication
use [Kalmus]
exec sp_addpublication @publication = N'Kalmus-to-KalmusFLM', @description = N'Transactional publication of database ''Kalmus'' from Publisher ''LV1-D-MSSQL-101''.', @sync_method = N'concurrent', @retention = 0, @allow_push = N'true', @allow_pull = N'true', @allow_anonymous = N'true', @enabled_for_internet = N'false', @snapshot_in_defaultfolder = N'true', @compress_snapshot = N'false', @ftp_port = 21, @allow_subscription_copy = N'false', @add_to_active_directory = N'false', @repl_freq = N'continuous', @status = N'active', @independent_agent = N'true', @immediate_sync = N'true', @allow_sync_tran = N'false', @allow_queued_tran = N'false', @allow_dts = N'false', @replicate_ddl = 1, @allow_initialize_from_backup = N'false', @enabled_for_p2p = N'false', @enabled_for_het_sub = N'false'
GO

exec sp_addpublication_snapshot @publication = N'Kalmus-to-KalmusFLM', @frequency_type = 1, @frequency_interval = 1, @frequency_relative_interval = 1, @frequency_recurrence_factor = 0, @frequency_subday = 8, @frequency_subday_interval = 1, @active_start_time_of_day = 0, @active_end_time_of_day = 235959, @active_start_date = 0, @active_end_date = 0, @job_login = null, @job_password = null, @publisher_security_mode = 1
Go

exec sp_addarticle @publication = N'Kalmus-to-KalmusFLM', @article = N'AppUser', @source_owner = N'dbo', @source_object = N'AppUser', @type = N'logbased', @description = N'', @creation_script = null, @pre_creation_cmd = N'drop', @schema_option = 0x00000140080350DF, @identityrangemanagementoption = N'manual', @destination_table = N'AppUser', @destination_owner = N'dbo', @vertical_partition = N'false', @ins_cmd = N'CALL sp_MSins_dboAppUser', @del_cmd = N'CALL sp_MSdel_dboAppUser', @upd_cmd = N'SCALL sp_MSupd_dboAppUser'
GO

exec sp_addarticle @publication = N'Kalmus-to-KalmusFLM', @article = N'AppUserCountryAccess', @source_owner = N'dbo', @source_object = N'AppUserCountryAccess', @type = N'logbased', @description = null, @creation_script = null, @pre_creation_cmd = N'drop', @schema_option = 0x00000140080350DF, @identityrangemanagementoption = N'manual', @destination_table = N'AppUserCountryAccess', @destination_owner = N'dbo', @vertical_partition = N'false', @ins_cmd = N'CALL sp_MSins_dboAppUserCountryAccess', @del_cmd = N'CALL sp_MSdel_dboAppUserCountryAccess', @upd_cmd = N'SCALL sp_MSupd_dboAppUserCountryAccess'
GO

exec sp_addarticle @publication = N'Kalmus-to-KalmusFLM', @article = N'Auditorium', @source_owner = N'dbo', @source_object = N'Auditorium', @type = N'logbased', @description = null, @creation_script = null, @pre_creation_cmd = N'drop', @schema_option = 0x00000140080350DF, @identityrangemanagementoption = N'manual', @destination_table = N'Auditorium', @destination_owner = N'dbo', @vertical_partition = N'false', @ins_cmd = N'CALL sp_MSins_dboAuditorium', @del_cmd = N'CALL sp_MSdel_dboAuditorium', @upd_cmd = N'SCALL sp_MSupd_dboAuditorium'
GO

exec sp_addarticle @publication = N'Kalmus-to-KalmusFLM', @article = N'Certificate', @source_owner = N'dbo', @source_object = N'Certificate', @type = N'logbased', @description = null, @creation_script = null, @pre_creation_cmd = N'drop', @schema_option = 0x00000140080350DF, @identityrangemanagementoption = N'manual', @destination_table = N'Certificate', @destination_owner = N'dbo', @vertical_partition = N'false', @ins_cmd = N'CALL sp_MSins_dboCertificate', @del_cmd = N'CALL sp_MSdel_dboCertificate', @upd_cmd = N'SCALL sp_MSupd_dboCertificate'
GO

exec sp_addarticle @publication = N'Kalmus-to-KalmusFLM', @article = N'Circuit', @source_owner = N'dbo', @source_object = N'Circuit', @type = N'logbased', @description = null, @creation_script = null, @pre_creation_cmd = N'drop', @schema_option = 0x00000140080350DF, @identityrangemanagementoption = N'manual', @destination_table = N'Circuit', @destination_owner = N'dbo', @vertical_partition = N'false', @ins_cmd = N'CALL sp_MSins_dboCircuit', @del_cmd = N'CALL sp_MSdel_dboCircuit', @upd_cmd = N'SCALL sp_MSupd_dboCircuit'
GO

exec sp_addarticle @publication = N'Kalmus-to-KalmusFLM', @article = N'CountryCode', @source_owner = N'dbo', @source_object = N'CountryCode', @type = N'logbased', @description = null, @creation_script = null, @pre_creation_cmd = N'drop', @schema_option = 0x00000140080350DF, @identityrangemanagementoption = N'manual', @destination_table = N'CountryCode', @destination_owner = N'dbo', @vertical_partition = N'false', @ins_cmd = N'CALL sp_MSins_dboCountryCode', @del_cmd = N'CALL sp_MSdel_dboCountryCode', @upd_cmd = N'SCALL sp_MSupd_dboCountryCode'
GO

exec sp_addarticle @publication = N'Kalmus-to-KalmusFLM', @article = N'Customer', @source_owner = N'dbo', @source_object = N'Customer', @type = N'logbased', @description = null, @creation_script = null, @pre_creation_cmd = N'drop', @schema_option = 0x00000140080350DF, @identityrangemanagementoption = N'manual', @destination_table = N'Customer', @destination_owner = N'dbo', @vertical_partition = N'false', @ins_cmd = N'CALL sp_MSins_dboCustomer', @del_cmd = N'CALL sp_MSdel_dboCustomer', @upd_cmd = N'SCALL sp_MSupd_dboCustomer'
GO

exec sp_addarticle @publication = N'Kalmus-to-KalmusFLM', @article = N'CustomerTheatreMapping', @source_owner = N'dbo', @source_object = N'CustomerTheatreMapping', @type = N'logbased', @description = null, @creation_script = null, @pre_creation_cmd = N'drop', @schema_option = 0x00000140080350DF, @identityrangemanagementoption = N'manual', @destination_table = N'CustomerTheatreMapping', @destination_owner = N'dbo', @vertical_partition = N'false', @ins_cmd = N'CALL sp_MSins_dboCustomerTheatreMapping', @del_cmd = N'CALL sp_MSdel_dboCustomerTheatreMapping', @upd_cmd = N'SCALL sp_MSupd_dboCustomerTheatreMapping'
GO

exec sp_addarticle @publication = N'Kalmus-to-KalmusFLM', @article = N'DataProviderTheatreAuditorium', @source_owner = N'dbo', @source_object = N'DataProviderTheatreAuditorium', @type = N'logbased', @description = null, @creation_script = null, @pre_creation_cmd = N'drop', @schema_option = 0x00000140080350DF, @identityrangemanagementoption = N'manual', @destination_table = N'DataProviderTheatreAuditorium', @destination_owner = N'dbo', @vertical_partition = N'false', @ins_cmd = N'CALL sp_MSins_dboDataProviderTheatreAuditorium', @del_cmd = N'CALL sp_MSdel_dboDataProviderTheatreAuditorium', @upd_cmd = N'SCALL sp_MSupd_dboDataProviderTheatreAuditorium'
GO

exec sp_addarticle @publication = N'Kalmus-to-KalmusFLM', @article = N'Device', @source_owner = N'dbo', @source_object = N'Device', @type = N'logbased', @description = null, @creation_script = null, @pre_creation_cmd = N'drop', @schema_option = 0x00000140080350DF, @identityrangemanagementoption = N'manual', @destination_table = N'Device', @destination_owner = N'dbo', @vertical_partition = N'false', @ins_cmd = N'CALL sp_MSins_dboDevice', @del_cmd = N'CALL sp_MSdel_dboDevice', @upd_cmd = N'SCALL sp_MSupd_dboDevice'
GO

exec sp_addarticle @publication = N'Kalmus-to-KalmusFLM', @article = N'DeviceType', @source_owner = N'dbo', @source_object = N'DeviceType', @type = N'logbased', @description = null, @creation_script = null, @pre_creation_cmd = N'drop', @schema_option = 0x00000140080350DF, @identityrangemanagementoption = N'manual', @destination_table = N'DeviceType', @destination_owner = N'dbo', @vertical_partition = N'false', @ins_cmd = N'CALL sp_MSins_dboDeviceType', @del_cmd = N'CALL sp_MSdel_dboDeviceType', @upd_cmd = N'SCALL sp_MSupd_dboDeviceType'
GO

exec sp_addarticle @publication = N'Kalmus-to-KalmusFLM', @article = N'Studio', @source_owner = N'dbo', @source_object = N'Studio', @type = N'logbased', @description = N'', @creation_script = null, @pre_creation_cmd = N'drop', @schema_option = 0x00000140080350DF, @identityrangemanagementoption = N'manual', @destination_table = N'Studio', @destination_owner = N'dbo', @vertical_partition = N'false', @ins_cmd = N'CALL sp_MSins_dboStudio', @del_cmd = N'CALL sp_MSdel_dboStudio', @upd_cmd = N'SCALL sp_MSupd_dboStudio'
GO

exec sp_addarticle @publication = N'Kalmus-to-KalmusFLM', @article = N'Theatre', @source_owner = N'dbo', @source_object = N'Theatre', @type = N'logbased', @description = null, @creation_script = null, @pre_creation_cmd = N'drop', @schema_option = 0x00000140080350DF, @identityrangemanagementoption = N'manual', @destination_table = N'Theatre', @destination_owner = N'dbo', @vertical_partition = N'false', @ins_cmd = N'CALL sp_MSins_dboTheatre', @del_cmd = N'CALL sp_MSdel_dboTheatre', @upd_cmd = N'SCALL sp_MSupd_dboTheatre'
GO


-----------------Initiate Snapshot agent -----------------
-----------------Run the Job to create the snapshot - LV1-D-MSSQL-101-Kalmus-Kalmus-to-KalmusFLM-x

-----------------BEGIN: Script to be run at Publisher 'LV1-D-MSSQL-101'-----------------
use [Kalmus]
exec sp_addsubscription @publication = N'Kalmus-to-KalmusFLM', @subscriber = N'lv1-d-mssql-102', @destination_db = N'KalmusFLM', @subscription_type = N'Push', @sync_type = N'automatic', @article = N'all', @update_mode = N'read only', @subscriber_type = 0
exec sp_addpushsubscription_agent @publication = N'Kalmus-to-KalmusFLM', @subscriber = N'lv1-d-mssql-102', @subscriber_db = N'KalmusFLM', @job_login = null, @job_password = null, @subscriber_security_mode = 1, @frequency_type = 64, @frequency_interval = 0, @frequency_relative_interval = 0, @frequency_recurrence_factor = 0, @frequency_subday = 0, @frequency_subday_interval = 0, @active_start_time_of_day = 0, @active_end_time_of_day = 235959, @active_start_date = 20150923, @active_end_date = 99991231, @enabled_for_syncmgr = N'False', @dts_package_location = N'Distributor'
GO
-----------------END: Script to be run at Publisher 'LV1-D-MSSQL-101'-----------------




/*
Testing 

SELECT count(*) FROM Kalmus.dbo.AppUser
SELECT count(*) FROM [LAXDC-D-DB02].KalmusFLM.dbo.AppUser

SELECT count(*) FROM Kalmus.dbo.AppUserCountryAccess
SELECT count(*) FROM [LAXDC-D-DB02].KalmusFLM.dbo.AppUserCountryAccess

SELECT count(*) FROM Kalmus.dbo.Auditorium
SELECT count(*) FROM [LAXDC-D-DB02].KalmusFLM.dbo.Auditorium

SELECT count(*) FROM Kalmus.dbo.Certificate
SELECT count(*) FROM [LAXDC-D-DB02].KalmusFLM.dbo.Certificate

SELECT count(*) FROM Kalmus.dbo.Circuit
SELECT count(*) FROM [LAXDC-D-DB02].KalmusFLM.dbo.Circuit

SELECT count(*) FROM Kalmus.dbo.CountryCode
SELECT count(*) FROM [LAXDC-D-DB02].KalmusFLM.dbo.CountryCode

SELECT count(*) FROM Kalmus.dbo.Customer
SELECT count(*) FROM [LAXDC-D-DB02].KalmusFLM.dbo.Customer

SELECT count(*) FROM Kalmus.dbo.CustomerTheatreMapping
SELECT count(*) FROM [LAXDC-D-DB02].KalmusFLM.dbo.CustomerTheatreMapping

SELECT count(*) FROM Kalmus.dbo.DataProviderTheatreAuditorium
SELECT count(*) FROM [LAXDC-D-DB02].KalmusFLM.dbo.DataProviderTheatreAuditorium

SELECT count(*) FROM Kalmus.dbo.Device
SELECT count(*) FROM [LAXDC-D-DB02].KalmusFLM.dbo.Device

SELECT count(*) FROM Kalmus.dbo.DeviceType
SELECT count(*) FROM [LAXDC-D-DB02].KalmusFLM.dbo.DeviceType

SELECT count(*) FROM Kalmus.dbo.Studio
SELECT count(*) FROM [LAXDC-D-DB02].KalmusFLM.dbo.Studio

SELECT count(*) FROM Kalmus.dbo.Theatre
SELECT count(*) FROM [LAXDC-D-DB02].KalmusFLM.dbo.Theatre




SELECT TOP 10 * FROM Kalmus.dbo.Theatre WHERE TheatreID = 100000
SELECT TOP 10 * FROM Kalmus.dbo.Circuit WHERE CircuitID = 1000

SELECT TOP 10 * FROM [LAXDC-D-DB02].KalmusFLM.dbo.Theatre WHERE TheatreID = 100000
SELECT TOP 10 * FROM [LAXDC-D-DB02].KalmusFLM.dbo.Circuit WHERE CircuitID = 1000

UPDATE Kalmus.dbo.Theatre SET TheatreName = TheatreName+'.'  WHERE TheatreID = 100000
UPDATE Kalmus.dbo.Circuit SET CircuitName = CircuitName+'.' WHERE CircuitID = 1000

UPDATE Kalmus.dbo.Theatre SET TheatreName = REPLACE(TheatreName,'.','') WHERE TheatreID = 100000
UPDATE Kalmus.dbo.Circuit SET CircuitName = REPLACE(CircuitName,'.','') WHERE CircuitID = 1000

*/

