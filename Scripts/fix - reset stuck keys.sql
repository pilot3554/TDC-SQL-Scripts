use booking_001
go

DECLARE @tableHTML  NVARCHAR(MAX)


if exists(
SELECT TOP 100 b.*
  FROM [Booking_001].[dbo].[KeyOrders] a 
  JOIN Booking_001.dbo.tblKeyPackageXref b ON a.KeyOrderID = b.keyOrderID
  WHERE a.KdmDeliveryStatusId = 1
  AND a.PlayDateEnd > dateadd(hh,1,GETDATE())
)
begin


	SET @tableHTML =
		N'<H1>Stuck Keygen Packages</H1>' +
		N'<table border="1">' +
		N'<tr><th>packageID</th><th>keyOrderID</th></tr>' +
		CAST ( ( SELECT td = b.packageID ,       '',
						td = b.keyOrderID
						FROM [Booking_001].[dbo].[KeyOrders] a 
						JOIN Booking_001.dbo.tblKeyPackageXref b ON a.KeyOrderID = b.keyOrderID
						WHERE a.KdmDeliveryStatusId = 1
						AND a.PlayDateEnd > dateadd(hh,1,GETDATE())
				  FOR XML PATH('tr'), TYPE 
		) AS NVARCHAR(MAX) ) +
		N'</table>' ;
	--print @tableHTML 

	EXEC msdb.dbo.sp_send_dbmail
		@recipients = 'patrick.alexander@technicolor.com;Sylvain.Delporte@technicolor.com;Rick.Litiatco@technicolor.com',
		@subject = 'Stuck Keygen Packages',
		@body = @tableHTML,
		@body_format = 'HTML' ;  
    
	declare
		 @kOrderL LongTable
		,@StudioKeyOrderTheatreTable StudioKeyOrderTheatreTable 
			insert into @kOrderL (value)
			SELECT keyorderid FROM Booking_001.dbo.KeyOrders WHERE keyorderid in
			(SELECT  tblKeyPackageXref.keyOrderID
	  FROM [Booking_001].[dbo].[KeyOrders]
	  JOIN Booking_001.dbo.tblKeyPackageXref ON dbo.KeyOrders.KeyOrderID = dbo.tblKeyPackageXref.keyOrderID
	  WHERE KdmDeliveryStatusId = 1
	  AND PlayDateEnd > dateadd(hh,1,GETDATE()))

	--select * From @kOrderL 
	exec dbo.usp_InsertKeyOrdersIntoStudioPortal @keyOrderList = @kOrderL, @CreatedBy = 'DNS', @StudioKeyOrderTheatreTable = @StudioKeyOrderTheatreTable

	--reset the job
	UPDATE [Booking_001].[dbo].[KeyOrders]
	  SET KdmDeliveryStatusId = null
	  WHERE KeyOrderID in 
			(SELECT  tblKeyPackageXref.keyOrderID
	  FROM [Booking_001].[dbo].[KeyOrders]
	  JOIN Booking_001.dbo.tblKeyPackageXref ON dbo.KeyOrders.KeyOrderID = dbo.tblKeyPackageXref.keyOrderID
	  WHERE KdmDeliveryStatusId = 1
	  AND PlayDateEnd > dateadd(hh,1,GETDATE()))

END    


/*

use booking_001
go

SELECT TOP 100 b.*
  FROM [Booking_001].[dbo].[KeyOrders] a 
  JOIN Booking_001.dbo.tblKeyPackageXref b ON a.KeyOrderID = b.keyOrderID
  WHERE a.KdmDeliveryStatusId = 1
  AND a.PlayDateEnd > GETDATE()

Go

use kms_001
GO
-- see what keyorder doesn't have a studiokeyorder in a specific package
       select  distinct
            p.PackageID,
            p.PriorityID ^ 1 as PriorityID, --Booking treats 0 as High Priority / KMS treats 1 as High Priority
            ko.KeyOrderReasonID,
            ko.OrderStatus,
            ISNULL(sko.SendKdmsToDefaultContact, 0) SendKdmsToDefaultContact,
            skr.LocalizedKDMEmails EnableLocalizedEmails,
            skot.StudioKeyOrderId,
            t.CompanyCode TheatreId,
            t.Name,
            t.City,
            t.State,
            t.Zip,
            t.Country
        from
            dbo.tblTheatres t
            inner join Booking_001.dbo.Engagements e on (t.CompanyCode = e.CustomerAccount)
            inner join Booking_001.dbo.KeyOrders ko on (e.EngagementID = ko.EngagementID)
            left outer join Booking_001.dbo.tblKeyPackageXref px on (ko.KeyOrderID = px.KeyOrderID)
            left outer join Booking_001.dbo.tblKeyPackages p on (px.PackageID = p.PackageID)
            inner loop join Booking_001.dbo.StudioKeyRules skr  on
                (
                    e.StudioAccountNum = skr.StudioID and
                    skr.KeyRuleTypeID is NULL
                )  -- forcing a loop join to prevent hash or merge join, which causes over reading/locking
            inner join Booking_001.dbo.CountryCodes cc with (nolock)  on
                (
                    t.Country = cc.CountryCode and
                    skr.isIntlRule <> cc.IsDomestic
                )
            left outer join dbo.tblStudioKeyOrderPackageDetail skopd on
                (
                    ko.KeyOrderID = skopd.BookingKeyOrderID and
                    skopd.DeleteFlag = 0
                )
            left outer join dbo.tblStudioKeyOrderTheatre skot on
                (
                    skopd.StudioKeyOrderTheatreID = skot.StudioKeyOrderTheatreId and
                    skot.DeleteFlag = 0
                )
            left outer join dbo.tblStudioKeyOrder sko on
                (
                    sko.StudioKeyOrderId = skot.StudioKeyOrderId AND
                    sko.DeleteFlag = 0
                )
        where
                     p.PackageID in 
                     (
                     SELECT TOP 100 b.packageid
						  FROM [Booking_001].[dbo].[KeyOrders] a 
						  JOIN Booking_001.dbo.tblKeyPackageXref b ON a.KeyOrderID = b.keyOrderID
						  WHERE a.KdmDeliveryStatusId = 1
						  AND a.PlayDateEnd > GETDATE()
                     )
                     and ko.KdmDeliveryStatusId =  1
go

*/