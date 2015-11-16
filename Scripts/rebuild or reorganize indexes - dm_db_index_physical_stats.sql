use skyarc_3_02

/*
avg_fragmentation_in_percent value	-->	Corrective statement
> 5% and < = 30%					-->	ALTER INDEX REORGANIZE
> 30%								-->	ALTER INDEX REBUILD WITH (ONLINE = ON)*
*/


SELECT a.index_id, name, avg_fragmentation_in_percent
FROM sys.dm_db_index_physical_stats (DB_ID(N'skyarc_3_02'), OBJECT_ID(N'dbo.tblPlaylistAssets'), NULL, NULL, NULL) AS a
    JOIN sys.indexes AS b ON a.object_id = b.object_id AND a.index_id = b.index_id;

SELECT a.index_id, name, avg_fragmentation_in_percent
FROM sys.dm_db_index_physical_stats (DB_ID(N'skyarc_3_02'), NULL, NULL, NULL, NULL) AS a
    JOIN sys.indexes AS b ON a.object_id = b.object_id AND a.index_id = b.index_id;

DBCC showcontig(tblPlaylistAssets)

