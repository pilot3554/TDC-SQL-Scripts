DECLARE @filename VARCHAR(500) , @filecontent VARCHAR(max)
DECLARE @sql VARCHAR(4000)

DECLARE db_cursor CURSOR FOR  
SELECT --top 10
--[DnQualifier]
certificateid
,[Certificate]
FROM [TDC_DB01].[dbo].[tblCertificates]
where validto>getdate() and WaimeaStatusID=1 and CertificateAuthority=0
and addedon>getdate()-900

OPEN db_cursor  
FETCH NEXT FROM db_cursor INTO @filename  , @filecontent

WHILE @@FETCH_STATUS = 0  
BEGIN  
       print @filename
       set @filename = @filename --+'.txt'
       set @sql = 'echo ' +  @filecontent + ' > B:\temp\'+@filename
       --print @sql
       exec xp_CmdShell @sql ,no_output

       FETCH NEXT FROM db_cursor INTO @filename  , @filecontent  
END  

CLOSE db_cursor  
DEALLOCATE db_cursor

-------------------------------------------

