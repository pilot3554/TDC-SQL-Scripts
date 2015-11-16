select @@servername as [ServerName],t.object_id, db_name() as [DatabaseName], s.name as [SchemaName], t.name as [TableName], c.name as [ColumnName], p.name as [DataType]
,(case when p.name in ('nvarchar') and c.max_length = -1 then 'Max' else convert(varchar,(case when p.name in ('nvarchar','sysname') then c.max_length/2 else c.max_length end)) end) as [DataLenght]
, (CASE WHEN x.value is null THEN 'This is the ' + p.name + ' ' + (case when isnull((select i.is_primary_key 
	from sys.index_columns ic 
	left outer join sys.indexes i on i.index_id = ic.index_id and ic.object_id = i.object_id
	where ic.object_id = c.object_id and ic.column_id = c.column_id and i.is_primary_key = 1
	),0) = 0 then 'column' else 'primary key' end) + ' for ' + c.Name ELSE x.value END) as  [ColumnDescription]
, c.is_nullable as [AllowNulls]
, isnull(d.definition,'') as [DefaultValue]
, c.is_identity as [isIdentity]
, isnull((select i.is_primary_key 
	from sys.index_columns ic 
	left outer join sys.indexes i on i.index_id = ic.index_id and ic.object_id = i.object_id
	where ic.object_id = c.object_id and ic.column_id = c.column_id and i.is_primary_key = 1
	),0) as [isPrimaryKey]
, (case when isnull(f.parent_column_id, 0) = 0 then 0 else 1 end) as [isForeignKey]
, isnull((select name from sys.tables t2 where t2.object_id = f.referenced_object_id),'') as [ForeignKeyReferenceTable]
, isnull((select name from sys.columns c2 where c2.object_id = f.referenced_object_id and c2.column_id = f.referenced_column_id),'') as [ForeignKeyReferenceColumn]
from sys.tables t
inner join sys.schemas s on t.schema_id = s.schema_id
inner join sys.columns c on t.object_id = c.object_id
inner join sys.types p on c.user_type_id = p.user_type_id and c.system_type_id = p.system_type_id
left outer join sys.foreign_key_columns f on f.parent_object_id = c.object_id and f.parent_column_id = c.column_id
left outer join sys.extended_properties x on x.major_id = c.object_id and x.minor_id = c.column_id and x.class = 1
left outer join sys.default_constraints d on d.object_id = c.default_object_id
where t.object_id not in (select major_id From sys.extended_properties where name = 'microsoft_database_tools_support' and value = '1') 
--and t.object_id = 62623266--181575685
order by s.name, t.name, c.column_id


select * 
FRom sys.tables 
where name = 'AWBuildVersion'

select * 
From sys.columns
where object_id = 181575685

select * 
From sys.indexes
where object_id = 181575685

select *, (select name from sys.tables t2 where t2.object_id = fk.referenced_object_id)
From sys.foreign_key_columns fk
where fk.parent_object_id = 62623266

select *
from sys.indexes
where object_id = 62623266

select i.is_primary_key, *
from sys.index_columns ic 
left outer join sys.indexes i on i.index_id = ic.index_id and ic.object_id = i.object_id
where ic.object_id = 62623266 and ic.column_id = 3 and i.is_primary_key = 1

select *
from sys.default_constraints
where object_id in (78623323,94623380)
