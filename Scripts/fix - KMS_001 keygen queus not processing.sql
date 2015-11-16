LAXDC-S-DB02
USE KMS_001

--any keys in the queus?
SELECT TOP 10000 *
FROM [KMS_001].[dbo].[KdmServerJobEntry] ks (nolock)
join [dbo].[tblKeyGenJobEntries] kje (nolock) on kje.jobEntryID=ks.JobEntryId
join [dbo].[tblEquipment] e (nolock) on e.LineID=kje.equipmentID
join [dbo].[tblTheatres] t (nolock) on t.CompanyCode=e.CompanyCode
where kje.jobEntryID=66637742

--IF anything here THEN maybe need TO RESTART the SERVICE


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

--Keygen Package Queue from keymon
select COUNT(*) as 'number of KDM pending' from [KMS_001].[dbo].[tblKeyGenJobEntries] (nolock) where jobStatusID in (1,9) and dateAdded > GETDATE()-7

