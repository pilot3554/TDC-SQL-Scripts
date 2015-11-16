SET NOCOUNT ON
DECLARE @Now DATETIME
DECLARE @Cmd nvarchar(40)
DECLARE @SpId int
DECLARE @Xminutes INT = 120
SET @Now = GetDate()

IF OBJECT_ID('tempdb..#who2')>1
	DROP TABLE #Who2

CREATE TABLE #Who2(
    [SPID] int, 
    [Status] SysName NULL,
    [Login] SysName NULL, 
    [HostName] SysName NULL,
    [BlkBy] SysName NULL,
    [DBName] SysName NULL,
    [Command] SysName NULL,
    [CPUTime] int NULL,
    [DiskIO] int NULL,
    [LastBatch] SysName NULL,
    [ProgramName] SysName NULL,
    [SPID2] int NULL,
    [RequestId] int NULL)     

INSERT #Who2 exec sp_Who2

DELETE FROM #Who2 WHERE Login = 'sa' OR HostName='.'
DELETE FROM #Who2 WHERE ProgramName NOT IN ('Microsoft SQL Server Management Studio','Microsoft SQL Server Management Studio - Query')


ALTER TABLE #Who2 ADD LastDate DATETIME


IF Month(@Now)=1 And Day(@Now)=1
BEGIN
    UPDATE #Who2
        SET LastDate=
            CASE WHEN LastBatch Like '12%'
                THEN Cast( Substring(LastBatch,1,5)+ '/'+ 
                            Cast(Year(@now)-1 As varchar(4)) +' '+ 
                            Substring(LastBatch,7,8) as DateTime)
            ELSE
                           Cast( Substring(LastBatch,1,5)+ '/'+ 
                           Cast(Year(@now) As varchar(4))+' ' + 
                          Substring(LastBatch,7,8) as DateTime)
            END    
END    
ELSE
BEGIN
    UPDATE #Who2
        SET LastDate=Cast( Substring(LastBatch,1,5)+ '/'+ 
                Cast(Year(@now) As varchar(4))+' ' + 
                Substring(LastBatch,7,8) as DateTime)
END

SELECT * FROM #Who2 Where Abs(DateDiff(mi,LastDate,@Now)) > @Xminutes

/*
DECLARE Hit_List CURSOR FOR 
SELECT SPID FROM #Who2 Where Abs(DateDiff(mi,LastDate,@Now)) > @Xminutes
OPEN Hit_List
FETCH NEXT FROM Hit_List into @SpId
WHILE @@FETCH_STATUS=0
BEGIN
    SET @Cmd='KILL '+Cast(@SpId as nvarchar(11))
    EXEC(@Cmd)
    FETCH NEXT FROM Hit_List into @SpId
END
CLOSE Hit_List
DEALLOCATE Hit_List
DROP TABLE #Who2
*/