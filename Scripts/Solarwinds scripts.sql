/*
select    v.LastSync,v.volumetype, n.NodeID, v.Caption, n.IP_Address, n.Caption, n.Circuit, n.SiteFullName, n.TCD_id

from 
                                [OrionNPM].[dbo].[Volumes] v (nolock)
join        [OrionNPM].[dbo].[Nodes] n (nolock) on n.nodeID=v.NodeID

where 
n.Circuit like '%tdc%' and 
                                (v.LastSync<GETDATE()-1
                                or v.volumetype = 'unknown'
                                )
                                and n.Status=1
*/

SELECT DISTINCT Volumes.VolumeID AS NetObjectID, Volumes.FullName AS Name ,Volumes.VolumePercentUsed , Volumes.LastSync, Nodes.Circuit, Nodes.caption, *
FROM Nodes 
INNER JOIN Volumes ON (Nodes.NodeID = Volumes.NodeID) 
WHERE 
Circuit like '%tdc%'
and (Volumes.VolumeType = 'Fixed Disk')
AND Volumes.FullName not like '%C:\%'
--AND (Nodes.Circuit = 'TDC_Infrastructure') 
AND (Volumes.VolumePercentUsed > 80) 
AND Volumes.FullName like '%DB0%'
order by Volumes.VolumePercentUsed desc



--Query from volumes and nodes tables with icons and links
SELECT  v.Caption , VolumeResponding, v.LastSync , n.LastSync , VolumeType, n.caption  , Circuit
FROM Volumes v
inner join nodes n on v.nodeid=n.nodeid
where n.status <> '9' and
volumeresponding = 'N' and
VolumeType in ('Fixed Disk', 'Network Disk')
and Circuit like '%tdc%'
--and Circuit like '%TDC_NonProd%'
--and n.LastSync < dateadd(hh,-1, getdate())
--and n.caption like '%db0%'
--sort by age
order by n.caption, v.lastsync desc
