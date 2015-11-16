SELECT  L.request_session_id AS SPID, 
    DB_NAME(L.resource_database_id) AS DatabaseName,
    O.Name AS LockedObjectName, 
    P.object_id AS LockedObjectId, 
    L.resource_type AS LockedResource, 
    L.request_mode AS LockType,
    ST.text AS SqlStatementText,        
    ES.login_name AS LoginName,
    ES.host_name AS HostName,
    TST.is_user_transaction as IsUserTransaction,
    AT.name as TransactionName,
    CN.auth_scheme as AuthenticationMethod
FROM    sys.dm_tran_locks L
    JOIN sys.partitions P ON P.hobt_id = L.resource_associated_entity_id
    JOIN sys.objects O ON O.object_id = P.object_id
    JOIN sys.dm_exec_sessions ES ON ES.session_id = L.request_session_id
    JOIN sys.dm_tran_session_transactions TST ON ES.session_id = TST.session_id
    JOIN sys.dm_tran_active_transactions AT ON TST.transaction_id = AT.transaction_id
    JOIN sys.dm_exec_connections CN ON CN.session_id = ES.session_id
    CROSS APPLY sys.dm_exec_sql_text(CN.most_recent_sql_handle) AS ST
WHERE   resource_database_id = db_id()
ORDER BY L.request_session_id

select XEventData.XEvent.value('(data/value)[1]', 'varchar(max)') as DeadlockGraph
FROM
(select CAST(target_data as xml) as TargetData
from sys.dm_xe_session_targets st
join sys.dm_xe_sessions s on s.address = st.event_session_address
where name = 'system_health') AS Data
CROSS APPLY TargetData.nodes ('//RingBufferTarget/event') AS XEventData (XEvent)
where XEventData.XEvent.value('@name', 'varchar(4000)') = 'xml_deadlock_report'


;WITH SystemHealth
AS (
	SELECT 
		CAST ( target_data AS xml ) AS SessionXML
	FROM 
		sys.dm_xe_session_targets st
	INNER JOIN 
		sys.dm_xe_sessions s 
	ON 
		s.[address] = st.event_session_address
	WHERE 
		name = 'system_health'
)
SELECT 
	Deadlock.value ( '@timestamp', 'datetime' ) AS DeadlockDateTime
,	CAST ( Deadlock.value ( '(data/value)[1]', 'Nvarchar(max)' ) AS XML ) AS DeadlockGraph
FROM 
	SystemHealth s
    CROSS APPLY SessionXML.nodes ( '//RingBufferTarget/event' ) AS t (Deadlock) WHERE 
	Deadlock.value ( '@name', 'nvarchar(128)' ) = N'xml_deadlock_report'
ORDER BY
	Deadlock.value ( '@timestamp', 'datetime' );

