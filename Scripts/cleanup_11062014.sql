
select  
CompositionUUID,(case when b.cpl like '%keyid%' then 'yes' else 'no' end) as aa,a.RequiresKey--, b.cpl,*
into #tmp
from dbo.Compositions a (nolock)
inner join kms_001.dbo.tblCPL b (nolock) on a.CompositionUUID = b.cplUUID
where --b.cpl like '%keyid%' and 
a.RequiresKey = 0
 
select * from #tmp order by CompositionUUID
 
select b.aa, * 
from Compositions a 
inner join #tmp b on a.CompositionUUID = b. CompositionUUID
where b.aa ='yes' --and a.active = 1 --
and a.requireskey = 0
order by a.CompositionUUID
 
update a 
set requireskey = 1, modifieddate = getdate()
from Compositions a 
inner join #tmp b on a.CompositionUUID = b. CompositionUUID
where b.aa ='yes' --and a.active = 1 
and a.requireskey = 0
 
 
 
select  *
from dbo.Compositions
where CompositionUUID is null
and RequiresKey = 1
--and active = 1
 
update a 
set RequiresKey = 0 , ModifiedDate = getdate()
from dbo.Compositions a 
where CompositionUUID is null 
and RequiresKey = 1
--and active = 1

 
 
