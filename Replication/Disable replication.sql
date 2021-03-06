-- on LAXDC-G-DB01 
-- replicated server LAXDC-G-DB02

-- Dropping the transactional subscriptions
use [AlertCRM]
exec sp_dropsubscription @publication = N'Alert Theatre and Equipment', @subscriber = N'LAXDC-G-DB02', @destination_db = N'KMS_001', @article = N'all'
GO

-- Dropping the transactional articles
use [AlertCRM]
exec sp_dropsubscription @publication = N'Alert Theatre and Equipment', @article = N'Address', @subscriber = N'all', @destination_db = N'all'
GO
use [AlertCRM]
exec sp_droparticle @publication = N'Alert Theatre and Equipment', @article = N'Address', @force_invalidate_snapshot = 1
GO
use [AlertCRM]
exec sp_dropsubscription @publication = N'Alert Theatre and Equipment', @article = N'Company', @subscriber = N'all', @destination_db = N'all'
GO
use [AlertCRM]
exec sp_droparticle @publication = N'Alert Theatre and Equipment', @article = N'Company', @force_invalidate_snapshot = 1
GO
use [AlertCRM]
exec sp_dropsubscription @publication = N'Alert Theatre and Equipment', @article = N'CompanyEquipment', @subscriber = N'all', @destination_db = N'all'
GO
use [AlertCRM]
exec sp_droparticle @publication = N'Alert Theatre and Equipment', @article = N'CompanyEquipment', @force_invalidate_snapshot = 1
GO
use [AlertCRM]
exec sp_dropsubscription @publication = N'Alert Theatre and Equipment', @article = N'ItemMaster', @subscriber = N'all', @destination_db = N'all'
GO
use [AlertCRM]
exec sp_droparticle @publication = N'Alert Theatre and Equipment', @article = N'ItemMaster', @force_invalidate_snapshot = 1
GO

-- Dropping the transactional publication
use [AlertCRM]
exec sp_droppublication @publication = N'Alert Theatre and Equipment'
GO


-- Dropping the transactional subscriptions
use [AlertCRM]
exec sp_dropsubscription @publication = N'Auditoriums', @subscriber = N'LAXDC-G-DB02', @destination_db = N'KMS_001', @article = N'all'
GO

-- Dropping the transactional articles
use [AlertCRM]
exec sp_dropsubscription @publication = N'Auditoriums', @article = N'address', @subscriber = N'all', @destination_db = N'all'
GO
use [AlertCRM]
exec sp_droparticle @publication = N'Auditoriums', @article = N'address', @force_invalidate_snapshot = 1
GO

-- Dropping the transactional publication
use [AlertCRM]
exec sp_droppublication @publication = N'Auditoriums'
GO

use [AlertCRM]
EXEC sp_removedbreplication 
GO



-- Dropping the transactional subscriptions
use [TDC_DB01]
exec sp_dropsubscription @publication = N'Certificates', @subscriber = N'LAXDC-G-DB02', @destination_db = N'KMS_001', @article = N'all'
GO

-- Dropping the transactional articles
use [TDC_DB01]
exec sp_dropsubscription @publication = N'Certificates', @article = N'tblCertificates', @subscriber = N'all', @destination_db = N'all'
GO
use [TDC_DB01]
exec sp_droparticle @publication = N'Certificates', @article = N'tblCertificates', @force_invalidate_snapshot = 1
GO

-- Dropping the transactional publication
use [TDC_DB01]
exec sp_droppublication @publication = N'Certificates'
GO

use [TDC_DB01]
EXEC sp_removedbreplication 
GO
