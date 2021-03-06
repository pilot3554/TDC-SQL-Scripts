use [KalmusFLM]
exec sp_replicationdboption @dbname = N'KalmusFLM', @optname = N'publish', @value = N'true'
GO
-- Adding the transactional publication
use [KalmusFLM]
exec sp_addpublication @publication = N'KalmusFLM Publication', @description = N'Transactional publication of database ''KalmusFLM'' from Publisher ''LV1-D-MSSQL-102''.', @sync_method = N'concurrent', @retention = 0, @allow_push = N'true', @allow_pull = N'true', @allow_anonymous = N'true', @enabled_for_internet = N'false', @snapshot_in_defaultfolder = N'true', @compress_snapshot = N'false', @ftp_port = 21, @allow_subscription_copy = N'false', @add_to_active_directory = N'false', @repl_freq = N'continuous', @status = N'active', @independent_agent = N'true', @immediate_sync = N'true', @allow_sync_tran = N'false', @allow_queued_tran = N'false', @allow_dts = N'false', @replicate_ddl = 1, @allow_initialize_from_backup = N'false', @enabled_for_p2p = N'false', @enabled_for_het_sub = N'false'
GO

exec sp_addpublication_snapshot @publication = N'KalmusFLM Publication', @frequency_type = 1, @frequency_interval = 1, @frequency_relative_interval = 1, @frequency_recurrence_factor = 0, @frequency_subday = 8, @frequency_subday_interval = 1, @active_start_time_of_day = 0, @active_end_time_of_day = 235959, @active_start_date = 0, @active_end_date = 0, @job_login = null, @job_password = null, @publisher_security_mode = 1
GO

use [KalmusFLM]
exec sp_addarticle @publication = N'KalmusFLM Publication', @article = N'SourceFLM', @source_owner = N'dbo', @source_object = N'SourceFLM', @type = N'logbased', @description = null, @creation_script = null, @pre_creation_cmd = N'drop', @schema_option = 0x00000000080350DF, @identityrangemanagementoption = N'manual', @destination_table = N'SourceFLM', @destination_owner = N'dbo', @vertical_partition = N'false', @ins_cmd = N'CALL sp_MSins_dboSourceFLM', @del_cmd = N'CALL sp_MSdel_dboSourceFLM', @upd_cmd = N'SCALL sp_MSupd_dboSourceFLM', @filter_clause = N'[FLMDataSourceID] = 12'
GO
-- Adding the article filter
exec sp_articlefilter @publication = N'KalmusFLM Publication', @article = N'SourceFLM', @filter_name = N'FLTR_SourceFLM_1__54', @filter_clause = N'[FLMDataSourceID] = 12', @force_invalidate_snapshot = 1, @force_reinit_subscription = 1
GO
-- Adding the article synchronization object
exec sp_articleview @publication = N'KalmusFLM Publication', @article = N'SourceFLM', @view_name = N'SYNC_SourceFLM_1__54', @filter_clause = N'[FLMDataSourceID] = 12', @force_invalidate_snapshot = 1, @force_reinit_subscription = 1
GO

use [KalmusFLM]
exec sp_addarticle @publication = N'KalmusFLM Publication', @article = N'SourceFLMDevice', @source_owner = N'dbo', @source_object = N'SourceFLMDevice', @type = N'logbased', @description = null, @creation_script = null, @pre_creation_cmd = N'drop', @schema_option = 0x00000000080350DF, @identityrangemanagementoption = N'manual', @destination_table = N'SourceFLMDevice', @destination_owner = N'dbo', @vertical_partition = N'false', @ins_cmd = N'CALL sp_MSins_dboSourceFLMDevice', @del_cmd = N'CALL sp_MSdel_dboSourceFLMDevice', @upd_cmd = N'SCALL sp_MSupd_dboSourceFLMDevice', @filter_clause = N'[FLMDataSourceID] = 12'

-- Adding the article filter
exec sp_articlefilter @publication = N'KalmusFLM Publication', @article = N'SourceFLMDevice', @filter_name = N'FLTR_SourceFLMDevice_1__54', @filter_clause = N'[FLMDataSourceID] = 12', @force_invalidate_snapshot = 1, @force_reinit_subscription = 1

-- Adding the article synchronization object
exec sp_articleview @publication = N'KalmusFLM Publication', @article = N'SourceFLMDevice', @view_name = N'SYNC_SourceFLMDevice_1__54', @filter_clause = N'[FLMDataSourceID] = 12', @force_invalidate_snapshot = 1, @force_reinit_subscription = 1
GO



-----------------Initiate Snapshot agent -----------------
-----------------Run the Job to create the snapshot - LV1-D-MSSQL-102-KalmusFLM-KalmusFLM Publication-xx


-----------------BEGIN: Script to be run at Publisher 'LV1-D-MSSQL-102'-----------------
use [KalmusFLM]
exec sp_addsubscription @publication = N'KalmusFLM Publication', @subscriber = N'lv1-d-mssql-101', @destination_db = N'Kalmus', @subscription_type = N'Push', @sync_type = N'automatic', @article = N'all', @update_mode = N'read only', @subscriber_type = 0
exec sp_addpushsubscription_agent @publication = N'KalmusFLM Publication', @subscriber = N'lv1-d-mssql-101', @subscriber_db = N'Kalmus', @job_login = null, @job_password = null, @subscriber_security_mode = 1, @frequency_type = 64, @frequency_interval = 0, @frequency_relative_interval = 0, @frequency_recurrence_factor = 0, @frequency_subday = 0, @frequency_subday_interval = 0, @active_start_time_of_day = 0, @active_end_time_of_day = 235959, @active_start_date = 20151005, @active_end_date = 99991231, @enabled_for_syncmgr = N'False', @dts_package_location = N'Distributor'
GO
-----------------END: Script to be run at Publisher 'LV1-D-MSSQL-102'-----------------

-----------------BEGIN: Script to be run at Publisher 'LV1-D-MSSQL-102'-----------------
use [KalmusFLM]
exec sp_addsubscription @publication = N'KalmusFLM Publication', @subscriber = N'lv1-d-mssql-101', @destination_db = N'AlertCRM', @subscription_type = N'Push', @sync_type = N'automatic', @article = N'all', @update_mode = N'read only', @subscriber_type = 0
exec sp_addpushsubscription_agent @publication = N'KalmusFLM Publication', @subscriber = N'lv1-d-mssql-101', @subscriber_db = N'AlertCRM', @job_login = null, @job_password = null, @subscriber_security_mode = 1, @frequency_type = 64, @frequency_interval = 0, @frequency_relative_interval = 0, @frequency_recurrence_factor = 0, @frequency_subday = 0, @frequency_subday_interval = 0, @active_start_time_of_day = 0, @active_end_time_of_day = 235959, @active_start_date = 20151006, @active_end_date = 99991231, @enabled_for_syncmgr = N'False', @dts_package_location = N'Distributor'
GO
-----------------END: Script to be run at Publisher 'LV1-D-MSSQL-102'-----------------

-----------------BEGIN: Script to be run at Publisher 'LV1-D-MSSQL-102'-----------------
use [KalmusFLM]
exec sp_addsubscription @publication = N'KalmusFLM Publication', @subscriber = N'lv1-d-mssql-102', @destination_db = N'KMS_001', @subscription_type = N'Push', @sync_type = N'automatic', @article = N'all', @update_mode = N'read only', @subscriber_type = 0
exec sp_addpushsubscription_agent @publication = N'KalmusFLM Publication', @subscriber = N'lv1-d-mssql-102', @subscriber_db = N'KMS_001', @job_login = null, @job_password = null, @subscriber_security_mode = 1, @frequency_type = 64, @frequency_interval = 0, @frequency_relative_interval = 0, @frequency_recurrence_factor = 0, @frequency_subday = 0, @frequency_subday_interval = 0, @active_start_time_of_day = 0, @active_end_time_of_day = 235959, @active_start_date = 20151006, @active_end_date = 99991231, @enabled_for_syncmgr = N'False', @dts_package_location = N'Distributor'
GO
-----------------END: Script to be run at Publisher 'LV1-D-MSSQL-102'-----------------

-----------------BEGIN: Script to be run at Publisher 'LV1-D-MSSQL-102'-----------------
use [KalmusFLM]
exec sp_addsubscription @publication = N'KalmusFLM Publication', @subscriber = N'lv1-d-mssql-101', @destination_db = N'TDC_DB01', @subscription_type = N'Push', @sync_type = N'automatic', @article = N'all', @update_mode = N'read only', @subscriber_type = 0
exec sp_addpushsubscription_agent @publication = N'KalmusFLM Publication', @subscriber = N'lv1-d-mssql-101', @subscriber_db = N'TDC_DB01', @job_login = null, @job_password = null, @subscriber_security_mode = 1, @frequency_type = 64, @frequency_interval = 0, @frequency_relative_interval = 0, @frequency_recurrence_factor = 0, @frequency_subday = 0, @frequency_subday_interval = 0, @active_start_time_of_day = 0, @active_end_time_of_day = 235959, @active_start_date = 20151028, @active_end_date = 99991231, @enabled_for_syncmgr = N'False', @dts_package_location = N'Distributor'
GO
-----------------END: Script to be run at Publisher 'LV1-D-MSSQL-102'-----------------



SELECT count(*) FROM KalmusFLM.dbo.SourceFLM  WHERE FLMDataSourceID = 12
SELECT count(*) FROM [LAXDC-D-DB01].Kalmus.dbo.SourceFLM 
SELECT count(*) FROM [LAXDC-D-DB01].AlertCRM.dbo.SourceFLM 
SELECT count(*) FROM [LAXDC-D-DB02].KMS_001.dbo.SourceFLM 

SELECT count(*) FROM KalmusFLM.dbo.SourceFLMDevice WHERE FLMDataSourceID = 12
SELECT count(*) FROM [LAXDC-D-DB01].Kalmus.dbo.SourceFLMDevice 
SELECT count(*) FROM [LAXDC-D-DB01].AlertCRM.dbo.SourceFLMDevice 
SELECT count(*) FROM [LAXDC-D-DB02].KMS_001.dbo.SourceFLMDevice 

SELECT TOP 10 * FROM KalmusFLM.dbo.SourceFLM WHERE sourceflmid = 801914

update KalmusFLM.dbo.SourceFLM set masterflmid = 1 WHERE sourceflmid = 801914 
SELECT TOP 10 * FROM KalmusFLM.dbo.SourceFLM WHERE FLMDataSourceID = 12 AND sourceflmid = 801914
SELECT TOP 10 * FROM [LAXDC-D-DB01].Kalmus.dbo.SourceFLM WHERE sourceflmid = 801914

update KalmusFLM.dbo.SourceFLM set masterflmid = Null WHERE sourceflmid = 801914
SELECT TOP 10 * FROM KalmusFLM.dbo.SourceFLM WHERE sourceflmid = 801914
SELECT TOP 10 * FROM [LAXDC-D-DB01].Kalmus.dbo.SourceFLM WHERE sourceflmid = 801914


SELECT TOP 10 * FROM KalmusFLM.dbo.SourceFLMDevice WHERE FLMDataSourceID = 12 AND SourceFLMDeviceID = 713731

update KalmusFLM.dbo.SourceFLMDevice set Exhibitor = Exhibitor+'.' WHERE SourceFLMDeviceID = 713731
SELECT TOP 10 * FROM KalmusFLM.dbo.SourceFLMDevice WHERE SourceFLMDeviceID = 713731
SELECT TOP 10 * FROM [LAXDC-D-DB01].Kalmus.dbo.SourceFLMDevice WHERE SourceFLMDeviceID = 713731

update KalmusFLM.dbo.SourceFLMDevice set Exhibitor = replace(Exhibitor,'.','') WHERE SourceFLMDeviceID = 713731
SELECT TOP 10 * FROM KalmusFLM.dbo.SourceFLMDevice WHERE SourceFLMDeviceID = 713731
SELECT TOP 10 * FROM [LAXDC-D-DB01].Kalmus.dbo.SourceFLMDevice WHERE SourceFLMDeviceID = 713731


-- Dropping the transactional subscriptions
use [KalmusFLM]
exec sp_dropsubscription @publication = N'KalmusFLM Publication', @subscriber = N'LV1-D-MSSQL-101', @destination_db = N'Kalmus', @article = N'all'
GO
exec sp_dropsubscription @publication = N'KalmusFLM Publication', @subscriber = N'LV1-D-MSSQL-101', @destination_db = N'AlertCRM', @article = N'all'
GO
exec sp_dropsubscription @publication = N'KalmusFLM Publication', @subscriber = N'LV1-D-MSSQL-101', @destination_db = N'KMS_001', @article = N'all'
GO

-- Dropping the transactional articles
use [KalmusFLM]
exec sp_dropsubscription @publication = N'KalmusFLM Publication', @article = N'SourceFLM', @subscriber = N'all', @destination_db = N'all'
GO
exec sp_droparticle @publication = N'KalmusFLM Publication', @article = N'SourceFLM', @force_invalidate_snapshot = 1
GO

USE [KalmusFLM]
exec sp_dropsubscription @publication = N'KalmusFLM Publication', @article = N'SourceFLMDevice', @subscriber = N'all', @destination_db = N'all'
GO
exec sp_droparticle @publication = N'KalmusFLM Publication', @article = N'SourceFLMDevice', @force_invalidate_snapshot = 1
GO

-- Dropping the transactional publication
use [KalmusFLM]
exec sp_droppublication @publication = N'KalmusFLM Publication'
GO

