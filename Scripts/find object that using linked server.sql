--find out objects using linked server
DECLARE @VName varchar(256)
Declare Findlinked cursor
LOCAL STATIC FORWARD_ONLY READ_ONLY
     FOR
Select name
	From sys.servers
	Where is_linked = 1
		
Open Findlinked;
Fetch next from Findlinked into @VName;

while @@FETCH_STATUS = 0
Begin
	SELECT OBJECT_NAME(object_id) 
		FROM sys.sql_modules 
		WHERE Definition LIKE '%'+@VName +'%' 
		AND OBJECTPROPERTY(object_id, 'IsProcedure') = 1 ;
		
	Fetch next from Findlinked into @VName;
End

Close Findlinked
Deallocate Findlinked


--exclusing jobs
Declare @VName varchar(256)
Declare Findlinked cursor
LOCAL STATIC FORWARD_ONLY READ_ONLY
     FOR
Select name AS name
	From sys.servers
	Where is_linked = 1
		
Open Findlinked;
Fetch next from Findlinked into @VName;

while @@FETCH_STATUS = 0
Begin
	SELECT OBJECT_NAME(object_id) 
		FROM sys.sql_modules 
		WHERE Definition LIKE '%'+@VName +'%' 
		AND OBJECTPROPERTY(object_id, 'IsProcedure') = 1 ;
		
	Fetch next from Findlinked into @VName;
END
Close Findlinked

Open Findlinked;
Fetch next from Findlinked into @VName;

while @@FETCH_STATUS = 0
Begin
	SELECT j.name AS JobName,js.command 
		FROM msdb.dbo.sysjobsteps js
			INNER JOIN msdb.dbo.sysjobs j
				ON j.job_id = js.job_id
		WHERE js.command LIKE '%'+@VName +'%'
	Fetch next from Findlinked into @VName;
END

Close Findlinked
Deallocate Findlinked