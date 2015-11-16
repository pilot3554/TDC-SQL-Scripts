use kalmusmastering
go

select top 10 *
from dbo.WorkOrder
where --workordername = 'Last Five Years' and 
workorderid = 2024894

select top 100 
a.WorkOrderAuditLogID,a.WorkOrderID,a.ColName,a.AppUserID,a.DeleteFlag,a.CreatedDate,
b.appuseraccount--, (select workorderstatus from dbo.WorkOrderStatus c where c.workorderstatusid = a.OldVal )
,(case when a.colname = 'WorkOrderStatusID' then (select workorderstatus from dbo.WorkOrderStatus c where c.workorderstatusid = a.OldVal) else a.oldval end) as oldval
,(case when a.colname = 'WorkOrderStatusID' then (select workorderstatus from dbo.WorkOrderStatus c where c.workorderstatusid = a.newVal) else a.newval end) as newval
from dbo.WorkOrderAuditLog a 
inner join kalmus.dbo.AppUser b on a.appuserid = b.appuserid
where workorderid = 2024894
order by 1 desc


select * 
from dbo.DistributionProject
where projectid = 104544

select *
from dbo.ProjectAuditLog
where projectid = 104544

select * 
from dbo.DistributionProjectAuditLog
where DistributionProjectid=10648

exec usp_GetProjectHistory @projectid = 104544
