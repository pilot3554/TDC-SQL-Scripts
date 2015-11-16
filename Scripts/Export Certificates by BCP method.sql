DECLARE @filename VARCHAR(500) , @filecontent VARCHAR(max) , @FileNameout varchar(1000)
DECLARE @sql VARCHAR(max)
declare @bcpCommand varchar(1000)

DECLARE db_cursor CURSOR FOR  
SELECT 
[MasterKdmId]
,[MasterKdm]
FROM [KMS_001].[dbo].[tblMasterKDM]
where addeddate>'07/01/2015'

OPEN db_cursor  
FETCH NEXT FROM db_cursor INTO @filename  , @filecontent

WHILE @@FETCH_STATUS = 0  
BEGIN  

print @filename
print len(@filecontent)

set @FileNameout = 'B:\temp\'+@filename
SET @bcpCommand = 'bcp "SELECT [MasterKdm] FROM [KMS_001].[dbo].[tblMasterKDM] where [MasterKdmId] = '''+@filename+'''" queryout "' + @FileNameout + '" -T -c'
EXEC master..xp_cmdshell @bcpCommand, no_output
print @bcpCommand 
print '------------------------------'

FETCH NEXT FROM db_cursor INTO @filename  , @filecontent  
END  

CLOSE db_cursor  
DEALLOCATE db_cursor
