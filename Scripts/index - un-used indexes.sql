-- GET UNUSED INDEXES THAT APPEAR IN THE INDEX USAGE STATS TABLE
--query that identifies unused indexes based on this criteria and outputs them in a pretty nice format
DECLARE @MinimumPageCount int
SET @MinimumPageCount = 500

SELECT	Databases.name AS [Database], 
	object_name(Indexes.object_id) AS [Table],					
	Indexes.name AS [Index],		
	PhysicalStats.page_count as [Page_Count],
	CONVERT(decimal(18,2), PhysicalStats.page_count * 8 / 1024.0) AS [Total Size (MB)],
	CONVERT(decimal(18,2), PhysicalStats.avg_fragmentation_in_percent) AS [Frag %],
	ParititionStats.row_count AS [Row Count],
	CONVERT(decimal(18,2), (PhysicalStats.page_count * 8.0 * 1024) 
		/ ParititionStats.row_count) AS [Index Size/Row (Bytes)]
FROM sys.dm_db_index_usage_stats UsageStats
	INNER JOIN sys.indexes Indexes
		ON Indexes.index_id = UsageStats.index_id
			AND Indexes.object_id = UsageStats.object_id
	INNER JOIN SYS.databases Databases
		ON Databases.database_id = UsageStats.database_id		
	INNER JOIN sys.dm_db_index_physical_stats (DB_ID(),NULL,NULL,NULL,NULL) 
			AS PhysicalStats
		ON PhysicalStats.index_id = UsageStats.Index_id	
			and PhysicalStats.object_id = UsageStats.object_id
	INNER JOIN SYS.dm_db_partition_stats ParititionStats
		ON ParititionStats.index_id = UsageStats.index_id
			and ParititionStats.object_id = UsageStats.object_id		
WHERE UsageStats.user_scans = 0
	AND UsageStats.user_seeks = 0
	-- ignore indexes with less than a certain number of pages of memory
	AND PhysicalStats.page_count > @MinimumPageCount
	-- Exclude primary keys, which should not be removed
	AND Indexes.type_desc != 'CLUSTERED'		
ORDER BY [Page_Count] DESC


-- GET UNUSED INDEXES THAT DO **NOT** APPEAR IN THE INDEX USAGE STATS TABLE
DECLARE @dbid INT
SELECT @dbid = DB_ID(DB_NAME())

SELECT	Databases.Name AS [Database],
	Objects.NAME AS [Table],
	Indexes.NAME AS [Index],
	Indexes.INDEX_ID,
	PhysicalStats.page_count as [Page Count],
	CONVERT(decimal(18,2), PhysicalStats.page_count * 8 / 1024.0) AS [Total Index Size (MB)],
	CONVERT(decimal(18,2), PhysicalStats.avg_fragmentation_in_percent) AS [Fragmentation (%)]
FROM SYS.INDEXES Indexes
	INNER JOIN SYS.OBJECTS Objects ON Indexes.OBJECT_ID = Objects.OBJECT_ID
	LEFT JOIN sys.dm_db_index_physical_stats(@dbid, null, null, null, null) PhysicalStats
		ON PhysicalStats.object_id = Indexes.object_id 
                     AND PhysicalStats.index_id = indexes.index_id
	INNER JOIN sys.databases Databases
		ON Databases.database_id = PhysicalStats.database_id
WHERE Objects.type = 'U' -- Is User Table
	AND Indexes.is_primary_key = 0
	AND Indexes.INDEX_ID NOT IN (
			SELECT UsageStats.INDEX_ID
			FROM SYS.DM_DB_INDEX_USAGE_STATS UsageStats
			WHERE UsageStats.OBJECT_ID = Indexes.OBJECT_ID
				AND   Indexes.INDEX_ID = UsageStats.INDEX_ID
				AND   DATABASE_ID = @dbid)
ORDER BY PhysicalStats.page_count DESC,
	Objects.NAME,
        Indexes.INDEX_ID,
        Indexes.NAME ASC