
--server: LAXDC-W-ALEXANP\SQL2008R2
use TDCDBCollector

select * From test
select * From servers
select top 10 * From dbo.jobhistory


select *
From dbo.jobhistory
where SERVER = 'laxdc-s-db02N'
and job_name like '%maint%'



select COUNT(*) 
From dbo.jobhistory
where SERVER = 'laxdc-s-db02N'
and job_name like '%maint%'


select job_name, COUNT(*) as exec_count ,MAX(run_duration) as max_run_duration, MIN(run_duration) as min_run_duration , AVG(run_duration) as avg_run_duraiton
From dbo.jobhistory
--where SERVER = 'laxdc-s-db02N'
--where job_name like '%maint%'
group by job_name
order by MAX(run_duration) desc

--last run date and duration
with jj (server_name, job_name,  last_run_date)
as
(
select server as server_name, job_name, MAX(run_date) as last_run_date
From dbo.jobhistory
group by server,job_name
)
select jj.server_name, jj.job_name, jj.last_run_date, max(jh.run_duration) as last_run_duration
from jj inner join dbo.jobhistory jh on jj.server_name = jh.server and jj.job_name = jh.job_name and jj.last_run_date = jh.run_date
--where SERVER = 'laxdc-s-db02N'
where jj.job_name like '%back%'
group by jj.server_name, jj.job_name, jj.last_run_date
order by last_run_duration
go

