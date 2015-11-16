--run on DB01-PROD

use [AlertCRM]
GO

exec sp_replicationdboption @dbname = N'AlertCRM', @optname = N'publish', @value = N'true'
GO


----------------------------------------------------------------
--Alert Theatre and Equipment
----------------------------------------------------------------

-- Adding the transactional publication
use [AlertCRM]
exec sp_addpublication @publication = N'Alert Theatre and Equipment', @description = N'Transactional publication of database ''AlertCRM'' from Publisher ''LV1-S-MSSQL-101''.', @sync_method = N'concurrent', @retention = 0, @allow_push = N'true', @allow_pull = N'true', @allow_anonymous = N'false', @enabled_for_internet = N'false', @snapshot_in_defaultfolder = N'true', @compress_snapshot = N'false', @ftp_port = 21, @allow_subscription_copy = N'false', @add_to_active_directory = N'false', @repl_freq = N'continuous', @status = N'active', @independent_agent = N'true', @immediate_sync = N'false', @allow_sync_tran = N'false', @allow_queued_tran = N'false', @allow_dts = N'false', @replicate_ddl = 1, @allow_initialize_from_backup = N'false', @enabled_for_p2p = N'false', @enabled_for_het_sub = N'false'
GO

exec sp_addpublication_snapshot @publication = N'Alert Theatre and Equipment', @frequency_type = 1, @frequency_interval = 0, @frequency_relative_interval = 0, @frequency_recurrence_factor = 0, @frequency_subday = 0, @frequency_subday_interval = 0, @active_start_time_of_day = 0, @active_end_time_of_day = 235959, @active_start_date = 0, @active_end_date = 0, @job_login = null, @job_password = null, @publisher_security_mode = 1
GO

use [AlertCRM]
exec sp_addarticle @publication = N'Alert Theatre and Equipment', @article = N'Address', @source_owner = N'dbo', @source_object = N'Address', @type = N'logbased', @description = null, @creation_script = null, @pre_creation_cmd = N'drop', @schema_option = 0x000000000803509F, @identityrangemanagementoption = N'manual', @destination_table = N'tblTheatres', @destination_owner = N'dbo', @vertical_partition = N'true', @ins_cmd = N'CALL sp_MSins_dboAddress', @del_cmd = N'CALL sp_MSdel_dboAddress', @upd_cmd = N'SCALL sp_MSupd_dboAddress', @filter_clause = N'addresscode=''primary'' AND companyCode IS NOT NULL AND Timezone IS NOT NULL and companycode<2000000'

-- Adding the article's partition column(s)
exec sp_articlecolumn @publication = N'Alert Theatre and Equipment', @article = N'Address', @column = N'AddressID', @operation = N'add', @force_invalidate_snapshot = 1, @force_reinit_subscription = 1
exec sp_articlecolumn @publication = N'Alert Theatre and Equipment', @article = N'Address', @column = N'CompanyCode', @operation = N'add', @force_invalidate_snapshot = 1, @force_reinit_subscription = 1
exec sp_articlecolumn @publication = N'Alert Theatre and Equipment', @article = N'Address', @column = N'Name', @operation = N'add', @force_invalidate_snapshot = 1, @force_reinit_subscription = 1
exec sp_articlecolumn @publication = N'Alert Theatre and Equipment', @article = N'Address', @column = N'Address1', @operation = N'add', @force_invalidate_snapshot = 1, @force_reinit_subscription = 1
exec sp_articlecolumn @publication = N'Alert Theatre and Equipment', @article = N'Address', @column = N'City', @operation = N'add', @force_invalidate_snapshot = 1, @force_reinit_subscription = 1
exec sp_articlecolumn @publication = N'Alert Theatre and Equipment', @article = N'Address', @column = N'State', @operation = N'add', @force_invalidate_snapshot = 1, @force_reinit_subscription = 1
exec sp_articlecolumn @publication = N'Alert Theatre and Equipment', @article = N'Address', @column = N'Zip', @operation = N'add', @force_invalidate_snapshot = 1, @force_reinit_subscription = 1
exec sp_articlecolumn @publication = N'Alert Theatre and Equipment', @article = N'Address', @column = N'Country', @operation = N'add', @force_invalidate_snapshot = 1, @force_reinit_subscription = 1
exec sp_articlecolumn @publication = N'Alert Theatre and Equipment', @article = N'Address', @column = N'TimeZone', @operation = N'add', @force_invalidate_snapshot = 1, @force_reinit_subscription = 1

-- Adding the article filter
exec sp_articlefilter @publication = N'Alert Theatre and Equipment', @article = N'Address', @filter_name = N'FLTR_Address_1__63', @filter_clause = N'addresscode=''primary'' AND companyCode IS NOT NULL AND Timezone IS NOT NULL and companycode<2000000', @force_invalidate_snapshot = 1, @force_reinit_subscription = 1

-- Adding the article synchronization object
exec sp_articleview @publication = N'Alert Theatre and Equipment', @article = N'Address', @view_name = N'SYNC_Address_1__63', @filter_clause = N'addresscode=''primary'' AND companyCode IS NOT NULL AND Timezone IS NOT NULL and companycode<2000000', @force_invalidate_snapshot = 1, @force_reinit_subscription = 1
GO

use [AlertCRM]
exec sp_addarticle @publication = N'Alert Theatre and Equipment', @article = N'Company', @source_owner = N'dbo', @source_object = N'Company', @type = N'logbased', @description = N'', @creation_script = N'', @pre_creation_cmd = N'drop', @schema_option = 0x000000000803509F, @identityrangemanagementoption = N'none', @destination_table = N'tblKeyDeliveryFormat', @destination_owner = N'dbo', @status = 24, @vertical_partition = N'true', @ins_cmd = N'CALL [sp_MSins_dboCompany]', @del_cmd = N'CALL [sp_MSdel_dboCompany]', @upd_cmd = N'SCALL [sp_MSupd_dboCompany]'

-- Adding the article's partition column(s)
exec sp_articlecolumn @publication = N'Alert Theatre and Equipment', @article = N'Company', @column = N'CompanyID', @operation = N'add', @force_invalidate_snapshot = 1, @force_reinit_subscription = 1
exec sp_articlecolumn @publication = N'Alert Theatre and Equipment', @article = N'Company', @column = N'CompanyCode', @operation = N'add', @force_invalidate_snapshot = 1, @force_reinit_subscription = 1
exec sp_articlecolumn @publication = N'Alert Theatre and Equipment', @article = N'Company', @column = N'Active', @operation = N'add', @force_invalidate_snapshot = 1, @force_reinit_subscription = 1
exec sp_articlecolumn @publication = N'Alert Theatre and Equipment', @article = N'Company', @column = N'UserText5', @operation = N'add', @force_invalidate_snapshot = 1, @force_reinit_subscription = 1
exec sp_articlecolumn @publication = N'Alert Theatre and Equipment', @article = N'Company', @column = N'UserText19', @operation = N'add', @force_invalidate_snapshot = 1, @force_reinit_subscription = 1
exec sp_articlecolumn @publication = N'Alert Theatre and Equipment', @article = N'Company', @column = N'Category', @operation = N'add', @force_invalidate_snapshot = 1, @force_reinit_subscription = 1


-- Adding the article synchronization object
exec sp_articleview @publication = N'Alert Theatre and Equipment', @article = N'Company', @view_name = N'SYNC_Company_1__67', @filter_clause = N'', @force_invalidate_snapshot = 1, @force_reinit_subscription = 1
GO
use [AlertCRM]
exec sp_addarticle @publication = N'Alert Theatre and Equipment', @article = N'CompanyEquipment', @source_owner = N'dbo', @source_object = N'CompanyEquipment', @type = N'logbased', @description = N'', @creation_script = N'', @pre_creation_cmd = N'drop', @schema_option = 0x000000000803509F, @identityrangemanagementoption = N'Manual', @destination_table = N'tblEquipment', @destination_owner = N'dbo', @status = 24, @vertical_partition = N'true', @ins_cmd = N'CALL [sp_MSins_dboCompanyEquipment]', @del_cmd = N'CALL [sp_MSdel_dboCompanyEquipment]', @upd_cmd = N'SCALL [sp_MSupd_dboCompanyEquipment]', @filter_clause = N'ItemNumber in (select itemNumber from [alertCRM].[dbo].[ItemMaster] where userText6 in (''Screen Server'',''Mastering Station''))'

-- Adding the article's partition column(s)
exec sp_articlecolumn @publication = N'Alert Theatre and Equipment', @article = N'CompanyEquipment', @column = N'LineID', @operation = N'add', @force_invalidate_snapshot = 1, @force_reinit_subscription = 1
exec sp_articlecolumn @publication = N'Alert Theatre and Equipment', @article = N'CompanyEquipment', @column = N'CompanyCode', @operation = N'add', @force_invalidate_snapshot = 1, @force_reinit_subscription = 1
exec sp_articlecolumn @publication = N'Alert Theatre and Equipment', @article = N'CompanyEquipment', @column = N'AddressCode', @operation = N'add', @force_invalidate_snapshot = 1, @force_reinit_subscription = 1
exec sp_articlecolumn @publication = N'Alert Theatre and Equipment', @article = N'CompanyEquipment', @column = N'ItemNumber', @operation = N'add', @force_invalidate_snapshot = 1, @force_reinit_subscription = 1
exec sp_articlecolumn @publication = N'Alert Theatre and Equipment', @article = N'CompanyEquipment', @column = N'SerialNumber', @operation = N'add', @force_invalidate_snapshot = 1, @force_reinit_subscription = 1
exec sp_articlecolumn @publication = N'Alert Theatre and Equipment', @article = N'CompanyEquipment', @column = N'UserText17', @operation = N'add', @force_invalidate_snapshot = 1, @force_reinit_subscription = 1
--added in qa
exec sp_articlecolumn @publication = N'Alert Theatre and Equipment', @article = N'CompanyEquipment', @column = N'UserText3', @operation = N'add', @force_invalidate_snapshot = 1, @force_reinit_subscription = 1
--added in qa 01/2012
exec sp_articlecolumn @publication = N'Alert Theatre and Equipment', @article = N'CompanyEquipment', @column = N'ItemVersion', @operation = N'add', @force_invalidate_snapshot = 1, @force_reinit_subscription = 1
exec sp_articlecolumn @publication = N'Alert Theatre and Equipment', @article = N'CompanyEquipment', @column = N'InstallDate', @operation = N'add', @force_invalidate_snapshot = 1, @force_reinit_subscription = 1
exec sp_articlecolumn @publication = N'Alert Theatre and Equipment', @article = N'CompanyEquipment', @column = N'UserText7', @operation = N'add', @force_invalidate_snapshot = 1, @force_reinit_subscription = 1
exec sp_articlecolumn @publication = N'Alert Theatre and Equipment', @article = N'CompanyEquipment', @column = N'UserText20', @operation = N'add', @force_invalidate_snapshot = 1, @force_reinit_subscription = 1

-- Adding the article filter
exec sp_articlefilter @publication = N'Alert Theatre and Equipment', @article = N'CompanyEquipment', @filter_name = N'FLTR_CompanyEquipment_1__131', @filter_clause = N'ItemNumber in (select itemNumber from [alertCRM].[dbo].[ItemMaster] where userText6 in (''Screen Server'',''Mastering Station''))', @force_invalidate_snapshot = 1, @force_reinit_subscription = 1

-- Adding the article synchronization object
exec sp_articleview @publication = N'Alert Theatre and Equipment', @article = N'CompanyEquipment', @view_name = N'SYNC_CompanyEquipment_1__67', @filter_clause = N'ItemNumber in (select itemNumber from [alertCRM].[dbo].[ItemMaster] where userText6 in (''Screen Server'',''Mastering Station''))', @force_invalidate_snapshot = 1, @force_reinit_subscription = 1
GO


use [AlertCRM]
exec sp_addarticle @publication = N'Alert Theatre and Equipment', @article = N'ItemMaster', @source_owner = N'dbo', @source_object = N'ItemMaster', @type = N'logbased', @description = N'', @creation_script = N'', @pre_creation_cmd = N'drop', @schema_option = 0x000000000803509F, @identityrangemanagementoption = N'none', @destination_table = N'tblMakeModelXref', @destination_owner = N'dbo', @status = 24, @vertical_partition = N'true', @ins_cmd = N'CALL [sp_MSins_dboItemMaster]', @del_cmd = N'CALL [sp_MSdel_dboItemMaster]', @upd_cmd = N'SCALL [sp_MSupd_dboItemMaster]', @filter_clause = N'ItemNumber in (select itemNumber from alertCRM.dbo.ItemMaster where userText6 in (''Screen Server'',''Mastering Station''))'

-- Adding the article's partition column(s)
exec sp_articlecolumn @publication = N'Alert Theatre and Equipment', @article = N'ItemMaster', @column = N'ItemNumber', @operation = N'add', @force_invalidate_snapshot = 1, @force_reinit_subscription = 1
exec sp_articlecolumn @publication = N'Alert Theatre and Equipment', @article = N'ItemMaster', @column = N'Manufacturer', @operation = N'add', @force_invalidate_snapshot = 1, @force_reinit_subscription = 1
exec sp_articlecolumn @publication = N'Alert Theatre and Equipment', @article = N'ItemMaster', @column = N'UserText6', @operation = N'add', @force_invalidate_snapshot = 1, @force_reinit_subscription = 1
exec sp_articlecolumn @publication = N'Alert Theatre and Equipment', @article = N'ItemMaster', @column = N'UserText7', @operation = N'add', @force_invalidate_snapshot = 1, @force_reinit_subscription = 1

-- Adding the article filter
exec sp_articlefilter @publication = N'Alert Theatre and Equipment', @article = N'ItemMaster', @filter_name = N'FLTR_CompanyEquipment_1__67', @filter_clause = N'ItemNumber in (select itemNumber from alertCRM.dbo.ItemMaster where userText6 in (''Screen Server'',''Mastering Station''))', @force_invalidate_snapshot = 1, @force_reinit_subscription = 1

-- Adding the article synchronization object
exec sp_articleview @publication = N'Alert Theatre and Equipment', @article = N'ItemMaster', @view_name = N'SYNC_ItemMaster_1__67', @filter_clause = N'ItemNumber in (select itemNumber from alertCRM.dbo.ItemMaster where userText6 in (''Screen Server'',''Mastering Station''))', @force_invalidate_snapshot = 1, @force_reinit_subscription = 1
GO


----------------------------------------------------------------
--Auditoriums
----------------------------------------------------------------

use [AlertCRM]
exec sp_addpublication @publication = N'Auditoriums', @description = N'Transactional publication of database ''AlertCRM''', @sync_method = N'concurrent', @retention = 0, @allow_push = N'true', @allow_pull = N'true', @allow_anonymous = N'true', @enabled_for_internet = N'false', @snapshot_in_defaultfolder = N'true', @compress_snapshot = N'false', @ftp_port = 21, @ftp_login = N'anonymous', @allow_subscription_copy = N'false', @add_to_active_directory = N'false', @repl_freq = N'continuous', @status = N'active', @independent_agent = N'true', @immediate_sync = N'true', @allow_sync_tran = N'false', @autogen_sync_procs = N'false', @allow_queued_tran = N'false', @allow_dts = N'false', @replicate_ddl = 0, @allow_initialize_from_backup = N'false', @enabled_for_p2p = N'false', @enabled_for_het_sub = N'false'
GO

exec sp_addpublication_snapshot @publication = N'Auditoriums', @frequency_type = 1, @frequency_interval = 0, @frequency_relative_interval = 0, @frequency_recurrence_factor = 0, @frequency_subday = 0, @frequency_subday_interval = 0, @active_start_time_of_day = 0, @active_end_time_of_day = 235959, @active_start_date = 0, @active_end_date = 0, @job_login = null, @job_password = null, @publisher_security_mode = 1
GO



-- Adding the transactional articles
use [AlertCRM]
exec sp_addarticle @publication = N'Auditoriums', @article = N'address', @source_owner = N'dbo', @source_object = N'Address', @type = N'logbased', @description = N'', @creation_script = N'', @pre_creation_cmd = N'drop', @schema_option = 0x000000000803508F, @identityrangemanagementoption = N'none', @destination_table = N'tblAuditorium', @destination_owner = N'dbo', @status = 24, @vertical_partition = N'true', @ins_cmd = N'CALL [dbo].[sp_MSins_dbotblAuditorium]', @del_cmd = N'CALL [dbo].[sp_MSdel_dbotblAuditorium]', @upd_cmd = N'SCALL [dbo].[sp_MSupd_dbotblAuditorium]', @filter_clause = N'[CompanyCode] <2000000'

-- Adding the article's partition column(s)
exec sp_articlecolumn @publication = N'Auditoriums', @article = N'address', @column = N'AddressID', @operation = N'add', @force_invalidate_snapshot = 1, @force_reinit_subscription = 1
exec sp_articlecolumn @publication = N'Auditoriums', @article = N'address', @column = N'CompanyCode', @operation = N'add', @force_invalidate_snapshot = 1, @force_reinit_subscription = 1
exec sp_articlecolumn @publication = N'Auditoriums', @article = N'address', @column = N'AddressCode', @operation = N'add', @force_invalidate_snapshot = 1, @force_reinit_subscription = 1
exec sp_articlecolumn @publication = N'Auditoriums', @article = N'address', @column = N'UserText2', @operation = N'add', @force_invalidate_snapshot = 1, @force_reinit_subscription = 1
exec sp_articlecolumn @publication = N'Auditoriums', @article = N'address', @column = N'UserText3', @operation = N'add', @force_invalidate_snapshot = 1, @force_reinit_subscription = 1
--exec sp_articlecolumn @publication = N'Auditoriums', @article = N'address', @column = N'UserText4', @operation = N'add', @force_invalidate_snapshot = 1, @force_reinit_subscription = 1
exec sp_articlecolumn @publication = N'Auditoriums', @article = N'address', @column = N'UserText5', @operation = N'add', @force_invalidate_snapshot = 1, @force_reinit_subscription = 1
exec sp_articlecolumn @publication = N'Auditoriums', @article = N'address', @column = N'UserText7', @operation = N'add', @force_invalidate_snapshot = 1, @force_reinit_subscription = 1
exec sp_articlecolumn @publication = N'Auditoriums', @article = N'address', @column = N'UserText9', @operation = N'add', @force_invalidate_snapshot = 1, @force_reinit_subscription = 1

-- Adding the article filter
exec sp_articlefilter @publication = N'Auditoriums', @article = N'address', @filter_name = N'FLTR_address_1__54', @filter_clause = N'[CompanyCode] <2000000', @force_invalidate_snapshot = 1, @force_reinit_subscription = 1

-- Adding the article synchronization object
exec sp_articleview @publication = N'Auditoriums', @article = N'address', @view_name = N'SYNC_tblAuditorium_1__67', @filter_clause = N'[CompanyCode] <2000000', @force_invalidate_snapshot = 1, @force_reinit_subscription = 1
GO


use [TDC_DB01]
exec sp_replicationdboption @dbname = N'TDC_DB01', @optname = N'publish', @value = N'true'
GO

----------------------------------------------------------------
--Certificates
----------------------------------------------------------------
-- Adding the transactional publication
use [TDC_DB01]
exec sp_addpublication @publication = N'Certificates', @description = N'Transactional publication of database ''TDC_DB01''', @sync_method = N'concurrent', @retention = 0, @allow_push = N'true', @allow_pull = N'true', @allow_anonymous = N'true', @enabled_for_internet = N'false', @snapshot_in_defaultfolder = N'true', @compress_snapshot = N'false', @ftp_port = 21, @ftp_login = N'anonymous', @allow_subscription_copy = N'false', @add_to_active_directory = N'false', @repl_freq = N'continuous', @status = N'active', @independent_agent = N'true', @immediate_sync = N'true', @allow_sync_tran = N'false', @autogen_sync_procs = N'false', @allow_queued_tran = N'false', @allow_dts = N'false', @replicate_ddl = 0, @allow_initialize_from_backup = N'false', @enabled_for_p2p = N'false', @enabled_for_het_sub = N'false'
GO
exec sp_addpublication_snapshot @publication = N'Certificates', @frequency_type = 1, @frequency_interval = 0, @frequency_relative_interval = 0, @frequency_recurrence_factor = 0, @frequency_subday = 0, @frequency_subday_interval = 0, @active_start_time_of_day = 0, @active_end_time_of_day = 235959, @active_start_date = 0, @active_end_date = 0, @job_login = null, @job_password = null, @publisher_security_mode = 1
GO

-- Adding the transactional articles
use [TDC_DB01]
exec sp_addarticle @publication = N'Certificates', @article = N'tblCertificates', @source_owner = N'dbo', @source_object = N'tblCertificates', @type = N'logbased', @description = N'', @creation_script = N'', @pre_creation_cmd = N'drop', @schema_option = 0x000000000803509F, @identityrangemanagementoption = N'MANUAL', @destination_table = N'tblCertificates', @destination_owner = N'dbo', @status = 24, @vertical_partition = N'true', @ins_cmd = N'CALL [sp_MSins_dbotblCertificates]', @del_cmd = N'CALL [sp_MSdel_dbotblCertificates]', @upd_cmd = N'SCALL [sp_MSupd_dbotblCertificates]'

-- Adding the article's partition column(s)
exec sp_articlecolumn @publication = N'Certificates', @article = N'tblCertificates', @column = N'Thumbprint', @operation = N'add', @force_invalidate_snapshot = 1, @force_reinit_subscription = 1
exec sp_articlecolumn @publication = N'Certificates', @article = N'tblCertificates', @column = N'DnQualifier', @operation = N'add', @force_invalidate_snapshot = 1, @force_reinit_subscription = 1
exec sp_articlecolumn @publication = N'Certificates', @article = N'tblCertificates', @column = N'WaimeaStatusID', @operation = N'add', @force_invalidate_snapshot = 1, @force_reinit_subscription = 1
exec sp_articlecolumn @publication = N'Certificates', @article = N'tblCertificates', @column = N'AlertEquipmentID', @operation = N'add', @force_invalidate_snapshot = 1, @force_reinit_subscription = 1
exec sp_articlecolumn @publication = N'Certificates', @article = N'tblCertificates', @column = N'SignatureAlgorithmID', @operation = N'add', @force_invalidate_snapshot = 1, @force_reinit_subscription = 1
exec sp_articlecolumn @publication = N'Certificates', @article = N'tblCertificates', @column = N'Certificate', @operation = N'add', @force_invalidate_snapshot = 1, @force_reinit_subscription = 1 --2013/06/25
exec sp_articlecolumn @publication = N'Certificates', @article = N'tblCertificates', @column = N'CertificateID', @operation = N'add', @force_invalidate_snapshot = 1, @force_reinit_subscription = 1 --2013/10/30
exec sp_articlecolumn @publication = N'Certificates', @article = N'tblCertificates', @column = N'CertificateRoleID', @operation = N'add', @force_invalidate_snapshot = 1, @force_reinit_subscription = 1 --2015/07/10
exec sp_articlecolumn @publication = N'Certificates', @article = N'tblCertificates', @column = N'CertificateAuthority', @operation = N'add', @force_invalidate_snapshot = 1, @force_reinit_subscription = 1 --2013/11/14
-- Adding the article synchronization object
exec sp_articleview @publication = N'Certificates', @article = N'tblCertificates', @view_name = N'SYNC_tblCertificates_1__67', @filter_clause = N'', @force_invalidate_snapshot = 1, @force_reinit_subscription = 1
GO
