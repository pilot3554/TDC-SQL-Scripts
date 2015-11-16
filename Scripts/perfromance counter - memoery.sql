--sp_who3
--sp_whoisactive

SELECT [cntr_value]
FROM sys.dm_os_performance_counters
WHERE
	[object_name] LIKE '%Buffer Manager%'
	AND [counter_name] = 'Page life expectancy'
	
	SELECT [cntr_value]
FROM sys.dm_os_performance_counters
WHERE
	[object_name] LIKE '%Buffer Manager%'
	AND [counter_name] = 'Buffer cache hit ratio'
	
SELECT [cntr_value]
FROM sys.dm_os_performance_counters
WHERE
	[object_name] LIKE '%Memory Manager%'
	AND [counter_name] = 'Memory Grants Pending'	
	
SELECT ROUND(100.0 * (
	SELECT CAST([cntr_value] AS FLOAT)
	FROM sys.dm_os_performance_counters
        WHERE		
		[object_name] LIKE '%Memory Manager%'
		AND [counter_name] = 'Total Server Memory (KB)'
	) / (
		SELECT CAST([cntr_value] AS FLOAT)
	FROM sys.dm_os_performance_counters
	WHERE
		[object_name] LIKE '%Memory Manager%'
		AND [counter_name] = 'Target Server Memory (KB)')
	, 2)AS [Ratio]	