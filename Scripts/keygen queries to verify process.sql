--what we see at monitor
select 
(
select count(*) 
from kms_001.dbo.KDMDistributionWorkQueue with (nolock)
where kdmdistributionstatusid = 1
)
+
(
select count(*)
from Booking_001.dbo.KeyOrders with (nolock)
where keydeliverydate <= getdate() 
and isnull(kdmdeliverystatusid,1) = 1 
and cancelflag = 0
and orderstatus = 'Processed'
) as KeyPackageQueueCount


--should always be zero
select count(*) , kdmdistributionstatusid
from kms_001.dbo.KDMDistributionWorkQueue
group by kdmdistributionstatusid
having kdmdistributionstatusid = 1


select *
from Booking_001.dbo.KeyOrders (nolock)
where keydeliverydate <= getdate() 
and isnull(kdmdeliverystatusid,1) = 1 
and cancelflag = 0
and orderstatus = 'Processed'


select top 1000 *
from Booking_001.dbo.KeyOrders a (nolock)
inner join Booking_001.dbo.Engagements b (nolock) on a.EngagementID = b.EngagementID 
where keydeliverydate <= getdate() 
and isnull(kdmdeliverystatusid,1) = 1
and cancelflag = 0
and orderstatus = 'Processed'
and customeraccount not in (select theatreid from kms_001.dbo.KDMDistributionWorkQueue where kdmdistributionstatusid = 1)
order by ordercreateddate, keyorderid

--error
select top 1000 *
from booking_001..keyorders a 
inner join Booking_001.dbo.Engagements b (nolock) on a.EngagementID = b.EngagementID 
where isnull(a.kdmdeliverystatusid,0) != 3 and 
b.customeraccount = 1014281
and dateadd(d,-14,getdate()) > playdateend
order by a.lastupdateddate desc

select *
from kms_001.dbo.KDMDistributionWorkQueue
where kdmdistributionstatusid is null



select *
from kms_001.dbo.KdmDeliveryStatus

select *
from kms_001.dbo.KdmDistributionStatus

-- if stuck then need to do this, why stuck ??
--update a 
--set kdmdeliverystatusid = null
--from Booking_001.dbo.KeyOrders a
--where keyorderid in (10554472,10554473)

select *
from Booking_001.dbo.KeyOrders a
where keyorderid in (10554472,10554473)

-- if stuck then need to do this, why stuck ??
set rowcount 100
update a 
set kdmdeliverystatusid = null
--select *
from Booking_001.dbo.KeyOrders  a(nolock)
where keydeliverydate <= getdate() 
and isnull(kdmdeliverystatusid,1) = 1 
and cancelflag = 0
and orderstatus = 'Processed'
set rowcount 0

select *
from 
    KMS_001.dbo.tblStudioKeyOrderPackageDetail skopd1
    inner join KMS_001.dbo.tblStudioKeyOrderPackageDetail skopd2 on (skopd1.StudioKeyOrderTheatreID = skopd2.StudioKeyOrderTheatreID)
    inner join Booking_001.dbo.KeyOrders ko2 on (skopd2.BookingKeyOrderID = ko2.KeyOrderID)
where 
    skopd1.BookingKeyOrderID = 10554472 and
    ko2.OrderStatus = 'Queued' and 
    skopd1.DeleteFlag = 0 and 
    Skopd2.DeleteFlag = 0


select * From KMS_001.dbo.tblStudioKeyOrderPackageDetail where BookingKeyOrderID = 10554472
select * From Booking_001.dbo.KeyOrders where KeyOrderID = 10554472



--in KMS

select top 10 * 
from dbo.tblStudioKeyOrder 
where studiokeyorderid =  395651


select top 100 * 
from dbo.tblStudioKeyOrderTheatre a 
inner join dbo.tblStudioKeyOrderPackageDetail b on a.studiokeyordertheatreid = b.studiokeyordertheatreid
where a.studiokeyorderid =  395651
and theatreid = 1014281
