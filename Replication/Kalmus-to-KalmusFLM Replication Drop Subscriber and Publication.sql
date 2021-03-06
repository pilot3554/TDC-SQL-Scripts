-- Dropping the transactional subscriptions
use [Kalmus]
exec sp_dropsubscription @publication = N'Kalmus-to-KalmusFLM', @subscriber = N'LV1-D-MSSQL-102', @destination_db = N'KalmusFLM', @article = N'all'
GO

-- Dropping the transactional articles
use [Kalmus]
exec sp_dropsubscription @publication = N'Kalmus-to-KalmusFLM', @article = N'AppUser', @subscriber = N'all', @destination_db = N'all'
GO
use [Kalmus]
exec sp_droparticle @publication = N'Kalmus-to-KalmusFLM', @article = N'AppUser', @force_invalidate_snapshot = 1
GO
use [Kalmus]
exec sp_dropsubscription @publication = N'Kalmus-to-KalmusFLM', @article = N'AppUserCountryAccess', @subscriber = N'all', @destination_db = N'all'
GO
use [Kalmus]
exec sp_droparticle @publication = N'Kalmus-to-KalmusFLM', @article = N'AppUserCountryAccess', @force_invalidate_snapshot = 1
GO
use [Kalmus]
exec sp_dropsubscription @publication = N'Kalmus-to-KalmusFLM', @article = N'Auditorium', @subscriber = N'all', @destination_db = N'all'
GO
use [Kalmus]
exec sp_droparticle @publication = N'Kalmus-to-KalmusFLM', @article = N'Auditorium', @force_invalidate_snapshot = 1
GO
use [Kalmus]
exec sp_dropsubscription @publication = N'Kalmus-to-KalmusFLM', @article = N'Certificate', @subscriber = N'all', @destination_db = N'all'
GO
use [Kalmus]
exec sp_droparticle @publication = N'Kalmus-to-KalmusFLM', @article = N'Certificate', @force_invalidate_snapshot = 1
GO
use [Kalmus]
exec sp_dropsubscription @publication = N'Kalmus-to-KalmusFLM', @article = N'Circuit', @subscriber = N'all', @destination_db = N'all'
GO
use [Kalmus]
exec sp_droparticle @publication = N'Kalmus-to-KalmusFLM', @article = N'Circuit', @force_invalidate_snapshot = 1
GO
use [Kalmus]
exec sp_dropsubscription @publication = N'Kalmus-to-KalmusFLM', @article = N'CountryCode', @subscriber = N'all', @destination_db = N'all'
GO
use [Kalmus]
exec sp_droparticle @publication = N'Kalmus-to-KalmusFLM', @article = N'CountryCode', @force_invalidate_snapshot = 1
GO
use [Kalmus]
exec sp_dropsubscription @publication = N'Kalmus-to-KalmusFLM', @article = N'Customer', @subscriber = N'all', @destination_db = N'all'
GO
use [Kalmus]
exec sp_droparticle @publication = N'Kalmus-to-KalmusFLM', @article = N'Customer', @force_invalidate_snapshot = 1
GO
use [Kalmus]
exec sp_dropsubscription @publication = N'Kalmus-to-KalmusFLM', @article = N'CustomerTheatreMapping', @subscriber = N'all', @destination_db = N'all'
GO
use [Kalmus]
exec sp_droparticle @publication = N'Kalmus-to-KalmusFLM', @article = N'CustomerTheatreMapping', @force_invalidate_snapshot = 1
GO
use [Kalmus]
exec sp_dropsubscription @publication = N'Kalmus-to-KalmusFLM', @article = N'DataProviderTheatreAuditorium', @subscriber = N'all', @destination_db = N'all'
GO
use [Kalmus]
exec sp_droparticle @publication = N'Kalmus-to-KalmusFLM', @article = N'DataProviderTheatreAuditorium', @force_invalidate_snapshot = 1
GO
use [Kalmus]
exec sp_dropsubscription @publication = N'Kalmus-to-KalmusFLM', @article = N'Device', @subscriber = N'all', @destination_db = N'all'
GO
use [Kalmus]
exec sp_droparticle @publication = N'Kalmus-to-KalmusFLM', @article = N'Device', @force_invalidate_snapshot = 1
GO
use [Kalmus]
exec sp_dropsubscription @publication = N'Kalmus-to-KalmusFLM', @article = N'DeviceType', @subscriber = N'all', @destination_db = N'all'
GO
use [Kalmus]
exec sp_droparticle @publication = N'Kalmus-to-KalmusFLM', @article = N'DeviceType', @force_invalidate_snapshot = 1
GO
use [Kalmus]
exec sp_dropsubscription @publication = N'Kalmus-to-KalmusFLM', @article = N'Studio', @subscriber = N'all', @destination_db = N'all'
GO
use [Kalmus]
exec sp_droparticle @publication = N'Kalmus-to-KalmusFLM', @article = N'Studio', @force_invalidate_snapshot = 1
GO
use [Kalmus]
exec sp_dropsubscription @publication = N'Kalmus-to-KalmusFLM', @article = N'Theatre', @subscriber = N'all', @destination_db = N'all'
GO
use [Kalmus]
exec sp_droparticle @publication = N'Kalmus-to-KalmusFLM', @article = N'Theatre', @force_invalidate_snapshot = 1
GO

-- Dropping the transactional publication
use [Kalmus]
exec sp_droppublication @publication = N'Kalmus-to-KalmusFLM'
GO

