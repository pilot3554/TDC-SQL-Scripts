-- Dropping the transactional subscriptions
use [Kalmus]
exec sp_dropsubscription @publication = N'Kalums-to-Booking_001', @subscriber = N'LV1-D-MSSQL-102', @destination_db = N'Booking_001', @article = N'all'
GO

-- Dropping the transactional articles
use [Kalmus]
exec sp_dropsubscription @publication = N'Kalums-to-Booking_001', @article = N'Circuit', @subscriber = N'all', @destination_db = N'all'
GO
use [Kalmus]
exec sp_droparticle @publication = N'Kalums-to-Booking_001', @article = N'Circuit', @force_invalidate_snapshot = 1
GO
use [Kalmus]
exec sp_dropsubscription @publication = N'Kalums-to-Booking_001', @article = N'Theatre', @subscriber = N'all', @destination_db = N'all'
GO
use [Kalmus]
exec sp_droparticle @publication = N'Kalums-to-Booking_001', @article = N'Theatre', @force_invalidate_snapshot = 1
GO
use [Kalmus]
exec sp_dropsubscription @publication = N'Kalums-to-Booking_001', @article = N'TheatreSetupSummary', @subscriber = N'all', @destination_db = N'all'
GO
use [Kalmus]
exec sp_droparticle @publication = N'Kalums-to-Booking_001', @article = N'TheatreSetupSummary', @force_invalidate_snapshot = 1
GO

-- Dropping the transactional publication
use [Kalmus]
exec sp_droppublication @publication = N'Kalums-to-Booking_001'
GO

