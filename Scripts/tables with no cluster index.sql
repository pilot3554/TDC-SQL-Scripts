/*
Finding Tables with Nonclustered Primary Keys and no Clustered Index
http://www.brentozar.com/archive/2015/07/finding-tables-with-nonclustered-primary-keys-and-no-clustered-index/
*/
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

SELECT  QUOTENAME(SCHEMA_NAME([t].[schema_id])) + '.' + QUOTENAME([t].[name]) AS [Table] ,
        QUOTENAME(OBJECT_NAME([kc].[object_id])) AS [IndexName] ,
        ( SUM([a].[total_pages]) * 8 / 1024.0 ) AS [IndexSizeMB]
FROM    [sys].[tables] [t]
INNER JOIN [sys].[indexes] [i]
ON      [t].[object_id] = [i].[object_id]
INNER JOIN [sys].[partitions] [p]
ON      [i].[object_id] = [p].[object_id]
        AND [i].[index_id] = [p].[index_id]
INNER JOIN [sys].[allocation_units] [a]
ON      [p].[partition_id] = [a].[container_id]
INNER JOIN [sys].[key_constraints] AS [kc]
ON      [t].[object_id] = [kc].[parent_object_id]
WHERE   (
          [i].[name] IS NOT NULL
          AND OBJECTPROPERTY([kc].[object_id], 'CnstIsNonclustKey') = 1 --Unique Constraint or Primary Key can qualify
          AND OBJECTPROPERTY([t].[object_id], 'TableHasClustIndex') = 0 --Make sure there's no Clustered Index, this is a valid design choice
          AND OBJECTPROPERTY([t].[object_id], 'TableHasPrimaryKey') = 1 --Make sure it has a Primary Key and it's not just a Unique Constraint
          AND OBJECTPROPERTY([t].[object_id], 'IsUserTable') = 1 --Make sure it's a user table because whatever, why not? We've come this far
        )
GROUP BY [t].[schema_id] ,
        [t].[name] ,
        OBJECT_NAME([kc].[object_id])
ORDER BY SUM([a].[total_pages]) * 8 / 1024.0 DESC;