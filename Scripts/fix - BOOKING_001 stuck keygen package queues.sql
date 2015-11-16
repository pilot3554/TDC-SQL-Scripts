--LAXDC-S-DB02.Booking_001

UPDATE [Booking_001].[dbo].[KeyOrders]
  SET KdmDeliveryStatusId = NULL
--SELECT * FROM [Booking_001].[dbo].[KeyOrders]  
  WHERE KeyOrderID in 
        (SELECT  tblKeyPackageXref.keyOrderID
  FROM [Booking_001].[dbo].[KeyOrders]
  JOIN Booking_001.dbo.tblKeyPackageXref ON dbo.KeyOrders.KeyOrderID = dbo.tblKeyPackageXref.keyOrderID
  WHERE KdmDeliveryStatusId = 1
  AND PlayDateEnd > DATEADD(HOUR,-1,GETDATE()))

--this is waht KEYMON is showing !
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
