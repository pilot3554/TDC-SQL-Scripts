-- select top 10 * from dbo.tblKeyGenJobs

select top 10 *
from dbo.KdmDeliveryHistory order by 1 desc

select top 10 *
from dbo.KdmDeliverySetting

select top 10 *
from dbo.tblTheatres

select top 10 c.country, *
from KdmDeliveryHistory a with (nolock)
inner join KdmDeliverySetting b with (nolock) on a.kdmdeliverysettingid = b.kdmdeliverysettingid
inner join tblTheatres c with (nolock) on a.tcn = c.companycode
where b.kdmdeliverytypeid = 1
and year(a.deliverystarted)=2014


select c.country,count(*) as cc
from KdmDeliveryHistory a with (nolock)
inner join KdmDeliverySetting b with (nolock) on a.kdmdeliverysettingid = b.kdmdeliverysettingid
inner join tblTheatres c with (nolock) on a.tcn = c.companycode
where b.kdmdeliverytypeid = 1
and year(a.deliverystarted)=2014
group by c.country