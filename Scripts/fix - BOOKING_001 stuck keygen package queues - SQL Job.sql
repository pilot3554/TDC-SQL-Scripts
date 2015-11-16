set nocount on;
DECLARE @tableHTML  NVARCHAR(MAX)

declare
	 @kOrderL LongTable
	,@StudioKeyOrderTheatreTable StudioKeyOrderTheatreTable 
		
insert into @kOrderL (value)
select  
    ko.keyorderid
from
    kms_001.dbo.tblTheatres t
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
    left outer join kms_001.dbo.tblStudioKeyOrderPackageDetail skopd on
        (
            ko.KeyOrderID = skopd.BookingKeyOrderID and
            skopd.DeleteFlag = 0
        )
    left outer join kms_001.dbo.tblStudioKeyOrderTheatre skot on
        (
            skopd.StudioKeyOrderTheatreID = skot.StudioKeyOrderTheatreId and
            skot.DeleteFlag = 0
        )
    left outer join kms_001.dbo.tblStudioKeyOrder sko on
        (
            sko.StudioKeyOrderId = skot.StudioKeyOrderId AND
            sko.DeleteFlag = 0
        )
where
             skot.StudioKeyOrderId is null
             and ko.KdmDeliveryStatusId =  1
             --and ko.keydeliverydate > getdate()	   
             and ko.PlayDateEnd > getdate()	   

--select * From @kOrderL  

if exists(select * from @kOrderL)
begin
print 'something to do'

	SET @tableHTML =
		N'<H1>Stuck Keygen Packages</H1>' +
		N'<table border="1">' +
		N'<tr><th>KeyorderID</th></tr>' +
		CAST ( ( SELECT td = value ,       ''
						FROM @kOrderL
				  FOR XML PATH('tr'), TYPE 
		) AS NVARCHAR(MAX) ) +
		N'</table>' ;
	--print @tableHTML 

	EXEC msdb.dbo.sp_send_dbmail
		@recipients = 'patrick.alexander@bydeluxe.com;Sylvain.Delporte@bydeluxe.com;Rick.Litiatco@bydeluxe.com',
		@subject = 'Stuck Keygen Packages',
		@body = @tableHTML,
		@body_format = 'HTML' ;  


	exec dbo.usp_InsertKeyOrdersIntoStudioPortal @keyOrderList = @kOrderL, @CreatedBy = 'DNS', @StudioKeyOrderTheatreTable = @StudioKeyOrderTheatreTable

	--reset the job
	UPDATE [Booking_001].[dbo].[KeyOrders]
	  SET KdmDeliveryStatusId = null
	  WHERE KeyOrderID in 
			(select value from @kOrderL)

		
end
else
begin
print 'Gone fishing ....'
end

	   
