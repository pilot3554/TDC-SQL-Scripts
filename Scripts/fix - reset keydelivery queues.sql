USE KMS_001
GO

-- retry recent delivery errors

update ko
set KdmDeliveryStatusId = null
--select *
from  Booking_001.dbo.KeyOrders ko (nolock)
inner join Booking_001.dbo.Engagements e (nolock) on e.EngagementID = ko.EngagementID 
inner join KdmDeliverySetting b on e.customeraccount = convert(varchar,b.tcn)
where keydeliverydate <= getdate() 
and isnull(kdmdeliverystatusid,1) = 4 
and cancelflag = 0
and orderstatus = 'Processed'
and ko.LastUpdatedDate > '10/30/2014'
and customeraccount not in (select theatreid from kms_001.dbo.KDMDistributionWorkQueue (nolock) where kdmdistributionstatusid = 1)
and ko.PlayDateEnd>=getdate() --if kdm is expired, no point
and b.KdmDeliveryTypeid = 1 and b.priority = 1 and b.deleteflag = 0 and b.isactive = 1


select *
from  Booking_001.dbo.KeyOrders ko (nolock)
inner join Booking_001.dbo.Engagements e (nolock) on e.EngagementID = ko.EngagementID 
inner join KdmDeliverySetting b on e.customeraccount = convert(varchar,b.tcn)
where keydeliverydate <= getdate() 
and isnull(kdmdeliverystatusid,1) = 4 
and cancelflag = 0
and orderstatus = 'Processed'
and ko.LastUpdatedDate > '10/30/2014'
and customeraccount not in (select theatreid from kms_001.dbo.KDMDistributionWorkQueue (nolock) where kdmdistributionstatusid = 1)
and ko.PlayDateEnd>=getdate() --if kdm is expired, no point
and b.KdmDeliveryTypeid = 1 and b.priority = 1 and b.deleteflag = 0 and b.isactive = 1




select top 10 *
From Booking_001.dbo.Engagements a 
inner join KdmDeliverySetting b on a.customeraccount = convert(varchar,b.tcn)
where b.KdmDeliveryTypeid = 1 and b.priority = 1 and b.deleteflag = 0 and b.isactive = 1

select top 10 *
From dbo.KdmDeliveryType


select * 
FRom KdmDeliverySetting 
where tcn in (1011838,1017396,1040251) and deleteflag =0

select top 100 *
from dbo.KdmDeliveryHistory
where tcn in (1040251) and KdmDeliveryStatusid = 4
order by deliverystarted desc

select *
from dbo.KdmDeliveryStatus
