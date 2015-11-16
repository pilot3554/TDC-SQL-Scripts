select		*
from		dbo.FLMProcessQueue (nolock)
where	(	ProcessName		=	'Import AlertFLMData' 			or
( ProcessName		=	'Move IncomingFLMLog'  and FLMDataSourceID = 1 )	)	and
ProcessFlag		=	0			and
ErrorFlag		=	0			and
DeleteFlag		=	0			and
ProcessQueued	 is not null	and
ProcessEndTime is null									


SELECT *
FROM dbo.FLMProcessQueue
WHERE FLMProcessQueueID = 202969

UPDATE FLMProcessQueue
SET ErrorFlag = 1 
WHERE FLMProcessQueueID = 202969
