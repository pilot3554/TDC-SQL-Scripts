--slow
SELECT COUNT(*) FROM tblPlaylistAssets (NOLOCK)

--fast
SELECT CONVERT(bigint, rows)
FROM sysindexes
WHERE id = OBJECT_ID('tblPlaylistAssets')
AND indid < 2
	
--SSMS method
SELECT CAST(p.rows AS float)
FROM sys.tables AS tbl
INNER JOIN sys.indexes AS idx ON idx.object_id = tbl.object_id and idx.index_id < 2
INNER JOIN sys.partitions AS p ON p.object_id=CAST(tbl.object_id AS int) AND p.index_id=idx.index_id
WHERE ((tbl.name=N'tblPlaylistAssets'
AND SCHEMA_NAME(tbl.schema_id)='dbo'))
 	
--another reliable method
SELECT SUM (row_count)
FROM sys.dm_db_partition_stats
WHERE object_id=OBJECT_ID('tblPlaylistAssets')   
AND (index_id=0 or index_id=1);