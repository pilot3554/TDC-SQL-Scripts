USE master;
GO
/*
exec sp_expire_user_sessions 
exec sp_expire_user_sessions @showonly = 1
exec sp_expire_user_sessions @showonly = 1, @Xminutes = 0
*/
ALTER PROCEDURE sp_expire_user_sessions
    (
      @Xminutes INT = 120 ,
      @showonly BIT = 0
    )
AS
    BEGIN

        SET NOCOUNT ON;
        DECLARE @Now DATETIME;
        DECLARE @Cmd NVARCHAR(40);
        DECLARE @SpId INT;
        SET @Now = GETDATE();

        IF OBJECT_ID('tempdb..#who2') > 1
            DROP TABLE #Who2;

        CREATE TABLE #Who2
            (
              [SPID] INT ,
              [Status] sysname NULL ,
              [Login] sysname NULL ,
              [HostName] sysname NULL ,
              [BlkBy] sysname NULL ,
              [DBName] sysname NULL ,
              [Command] sysname NULL ,
              [CPUTime] INT NULL ,
              [DiskIO] INT NULL ,
              [LastBatch] sysname NULL ,
              [ProgramName] sysname NULL ,
              [SPID2] INT NULL ,
              [RequestId] INT NULL
            );     

        INSERT  #Who2
                EXEC sp_who2;

        DELETE  FROM #Who2
        WHERE   Login = 'sa'
                OR HostName = '.';
        
        DELETE  FROM #Who2
        WHERE   SPID = @@SPID;
        
        DELETE  FROM #Who2
        WHERE   ProgramName NOT IN ( 'Microsoft SQL Server Management Studio',
                                     'Microsoft SQL Server Management Studio - Query' );


        ALTER TABLE #Who2 ADD LastDate DATETIME;


        IF MONTH(@Now) = 1
            AND DAY(@Now) = 1
            BEGIN
                UPDATE  #Who2
                SET     LastDate = CASE WHEN LastBatch LIKE '12%'
                                        THEN CAST(SUBSTRING(LastBatch, 1, 5)
                                             + '/'
                                             + CAST(YEAR(@Now) - 1 AS VARCHAR(4))
                                             + ' ' + SUBSTRING(LastBatch, 7, 8) AS DATETIME)
                                        ELSE CAST(SUBSTRING(LastBatch, 1, 5)
                                             + '/'
                                             + CAST(YEAR(@Now) AS VARCHAR(4))
                                             + ' ' + SUBSTRING(LastBatch, 7, 8) AS DATETIME)
                                   END;    
            END;    
        ELSE
            BEGIN
                UPDATE  #Who2
                SET     LastDate = CAST(SUBSTRING(LastBatch, 1, 5) + '/'
                        + CAST(YEAR(@Now) AS VARCHAR(4)) + ' '
                        + SUBSTRING(LastBatch, 7, 8) AS DATETIME);
            END;

        IF @showonly = 0
            BEGIN
                DECLARE Hit_List CURSOR
                FOR
                    SELECT  SPID
                    FROM    #Who2
                    WHERE   ABS(DATEDIFF(mi, LastDate, @Now)) > @Xminutes;
                OPEN Hit_List;
                FETCH NEXT FROM Hit_List INTO @SpId;
                WHILE @@FETCH_STATUS = 0
                    BEGIN
                        SET @Cmd = 'KILL ' + CAST(@SpId AS NVARCHAR(11));
                        EXEC(@Cmd);
                        FETCH NEXT FROM Hit_List INTO @SpId;
                    END;
                CLOSE Hit_List;
                DEALLOCATE Hit_List;
                DROP TABLE #Who2;
            END;
        ELSE
            BEGIN
                SELECT  *
                FROM    #Who2
                WHERE   ABS(DATEDIFF(mi, LastDate, @Now)) > @Xminutes;
            END;
            

    END;
GO
