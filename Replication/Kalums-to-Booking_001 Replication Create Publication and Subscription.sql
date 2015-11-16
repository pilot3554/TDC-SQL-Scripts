-- Enabling the replication database
use master
exec sp_replicationdboption @dbname = N'Kalmus', @optname = N'publish', @value = N'true'
GO

-- Adding the transactional publication
use [Kalmus]
exec sp_addpublication @publication = N'Kalums-to-Booking_001', @description = N'Transactional publication of database ''Kalmus'' from Publisher ''LV1-D-MSSQL-101''.', @sync_method = N'concurrent', @retention = 0, @allow_push = N'true', @allow_pull = N'true', @allow_anonymous = N'true', @enabled_for_internet = N'false', @snapshot_in_defaultfolder = N'true', @compress_snapshot = N'false', @ftp_port = 21, @allow_subscription_copy = N'false', @add_to_active_directory = N'false', @repl_freq = N'continuous', @status = N'active', @independent_agent = N'true', @immediate_sync = N'true', @allow_sync_tran = N'false', @allow_queued_tran = N'false', @allow_dts = N'false', @replicate_ddl = 1, @allow_initialize_from_backup = N'false', @enabled_for_p2p = N'false', @enabled_for_het_sub = N'false'
GO
exec sp_addpublication_snapshot @publication = N'Kalums-to-Booking_001', @frequency_type = 1, @frequency_interval = 1, @frequency_relative_interval = 1, @frequency_recurrence_factor = 0, @frequency_subday = 8, @frequency_subday_interval = 1, @active_start_time_of_day = 0, @active_end_time_of_day = 235959, @active_start_date = 0, @active_end_date = 0, @job_login = null, @job_password = null, @publisher_security_mode = 1
GO

USE [Kalmus]
exec sp_addarticle @publication = N'Kalums-to-Booking_001', @article = N'Circuit', @source_owner = N'dbo', @source_object = N'Circuit', @type = N'logbased', @description = null, @creation_script = null, @pre_creation_cmd = N'drop', @schema_option = 0x00000000090350DF, @identityrangemanagementoption = N'manual', @destination_table = N'Circuit', @destination_owner = N'dbo', @vertical_partition = N'false', @ins_cmd = N'CALL sp_MSins_dboCircuit', @del_cmd = N'CALL sp_MSdel_dboCircuit', @upd_cmd = N'SCALL sp_MSupd_dboCircuit'
GO

USE [Kalmus]
exec sp_addarticle @publication = N'Kalums-to-Booking_001', @article = N'Theatre', @source_owner = N'dbo', @source_object = N'Theatre', @type = N'logbased', @description = null, @creation_script = null, @pre_creation_cmd = N'drop', @schema_option = 0x00000000090350DF, @identityrangemanagementoption = N'manual', @destination_table = N'Theatre', @destination_owner = N'dbo', @vertical_partition = N'false', @ins_cmd = N'CALL sp_MSins_dboTheatre', @del_cmd = N'CALL sp_MSdel_dboTheatre', @upd_cmd = N'SCALL sp_MSupd_dboTheatre'
GO

use [Kalmus]
exec sp_addarticle @publication = N'Kalums-to-Booking_001', @article = N'TheatreSetupSummary', @source_owner = N'dbo', @source_object = N'TheatreSetupSummary', @type = N'logbased', @description = null, @creation_script = null, @pre_creation_cmd = N'drop', @schema_option = 0x00000000090350DF, @identityrangemanagementoption = N'manual', @destination_table = N'TheatreSetupSummary', @destination_owner = N'dbo', @vertical_partition = N'false', @ins_cmd = N'CALL sp_MSins_dboTheatreSetupSummary', @del_cmd = N'CALL sp_MSdel_dboTheatreSetupSummary', @upd_cmd = N'SCALL sp_MSupd_dboTheatreSetupSummary'
GO

-----------------Initiate Snapshot agent -----------------
-----------------Run the Job to create the snapshot - LV1-D-MSSQL-101-Kalmus-Kalums-to-Booking_001-x


-----------------BEGIN: Script to be run at Publisher 'LV1-D-MSSQL-101'-----------------
use [Kalmus]
exec sp_addsubscription @publication = N'Kalums-to-Booking_001', @subscriber = N'lv1-d-mssql-102', @destination_db = N'Booking_001', @subscription_type = N'Push', @sync_type = N'automatic', @article = N'all', @update_mode = N'read only', @subscriber_type = 0
exec sp_addpushsubscription_agent @publication = N'Kalums-to-Booking_001', @subscriber = N'lv1-d-mssql-102', @subscriber_db = N'Booking_001', @job_login = null, @job_password = null, @subscriber_security_mode = 1, @frequency_type = 64, @frequency_interval = 0, @frequency_relative_interval = 0, @frequency_recurrence_factor = 0, @frequency_subday = 0, @frequency_subday_interval = 0, @active_start_time_of_day = 0, @active_end_time_of_day = 235959, @active_start_date = 20150922, @active_end_date = 99991231, @enabled_for_syncmgr = N'False', @dts_package_location = N'Distributor'
GO
-----------------END: Script to be run at Publisher 'LV1-D-MSSQL-101'-----------------

/*
Testing 

SELECT count(*) FROM Kalmus.dbo.Theatre
SELECT count(*) FROM Kalmus.dbo.TheatreSetupSummary
SELECT count(*) FROM Kalmus.dbo.Circuit

SELECT count(*) FROM [LAXDC-D-DB02].Booking_001.dbo.Theatre
SELECT count(*) FROM [LAXDC-D-DB02].Booking_001.dbo.TheatreSetupSummary
SELECT count(*) FROM [LAXDC-D-DB02].Booking_001.dbo.Circuit


SELECT TOP 10 * FROM Kalmus.dbo.Theatre WHERE TheatreID = 100000
SELECT TOP 10 * FROM Kalmus.dbo.TheatreSetupSummary WHERE TheatreID = 100004
SELECT TOP 10 * FROM Kalmus.dbo.Circuit WHERE CircuitID = 1000

SELECT TOP 10 * FROM [LAXDC-D-DB02].Booking_001.dbo.Theatre WHERE TheatreID = 100000
SELECT TOP 10 * FROM [LAXDC-D-DB02].Booking_001.dbo.TheatreSetupSummary WHERE TheatreID = 100004
SELECT TOP 10 * FROM [LAXDC-D-DB02].Booking_001.dbo.Circuit WHERE CircuitID = 1000

UPDATE Kalmus.dbo.Theatre SET TheatreName = TheatreName+'.'  WHERE TheatreID = 100000
UPDATE Kalmus.dbo.TheatreSetupSummary SET CircuitName = CircuitName+'.' WHERE TheatreID = 100004
UPDATE Kalmus.dbo.Circuit SET CircuitName = CircuitName+'.' WHERE CircuitID = 1000

UPDATE Kalmus.dbo.Theatre SET TheatreName = REPLACE(TheatreName,'.','') WHERE TheatreID = 100000
UPDATE Kalmus.dbo.TheatreSetupSummary SET CircuitName = REPLACE(CircuitName,'.','') WHERE TheatreID = 100004
UPDATE Kalmus.dbo.Circuit SET CircuitName = REPLACE(CircuitName,'.','') WHERE CircuitID = 1000

*/