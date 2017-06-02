
use aces
DECLARE @SiteID NVARCHAR(1000) = 'aces_bpi_csp'
DECLARE @loadRevisionTable NVARCHAR(1000) = CONCAT(@SiteID, '_load_fcst_r')
DECLARE @loadFcstTable NVARCHAR(1000) = CONCAT(@SiteID, '_load_fcst')
DECLARE @myDate NVARCHAR(30) = CONVERT(varchar(8), GETDATE(), 112) 

EXEC 
('
if object_ID (''tempdb..#UnionAll'')is NOT NULL drop table #UnionAll
select date, time, load_fcst, revision
	into #UnionAll
	from  ' +@loadRevisionTable +' 
	where date = ' +@myDate +' 

if object_ID (''tempdb..#MaxDateTime'')is NOT NULL drop table #MaxDateTime
select	date, time, max(revision) as maxRevisionTime
	into #MaxDateTime
	from #UnionAll
	where revision <  DATEADD(day, -1, convert(date, GETDATE()))
	group by date, time
	having max(revision) < DATEADD(day, -1, convert(date, GETDATE()))

if object_ID (''tempdb..#MightMissHours'')is NOT NULL drop table #MightMissHours
select mdt.date, mdt.time, u.load_fcst, mdt.maxRevisionTime
	into #MightMissHours
	from #MaxDateTime mdt
	join #UnionAll u
	on mdt.date = u.date and mdt.time = u.time and mdt.maxRevisionTime = u.revision
	order by 1, 2
if object_ID (''tempdb..#CurrentFcst'')is NOT NULL drop table #CurrentFcst
select date, time, load_fcst 
	into #CurrentFcst
	from ' +@loadFcstTable+ ' where date = ' +@myDate +' 
select a.date, a.time, a.load_fcst, m.load_fcst AS "yesterday_load_fcst" ,  a.load_fcst-m.load_fcst AS "Difference", m.maxRevisionTime
from #CurrentFcst a
left join #MightMissHours m
on a.date = m.date and a.time = m.time
order by 1, 2
')


