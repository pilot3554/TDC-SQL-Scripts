declare
    @FlightDate DATE ='2015-08-07 00:00:00'
   ,@MediaSiteId INT = NULL
   ,@SVAssetID VARCHAR(100) = NULL

    set nocount on 

    declare @SVAssetIDWildCard varchar(100)
    declare @UsbDriveDeliveryMode smallint = 1
       ,@ElectronicDeliveryMode smallint = 2

    if isnull(@SVAssetID, '') <> ''
        set @SVAssetIDWildCard = '%' + @SVAssetID + '%'


	--	Get Asset Status Summary 
	DROP TABLE #CompositionAssetStatusBySite


    create table #CompositionAssetStatusBySite
        (MediaSiteId int not null
        ,CompositionAssetStatusId smallint
        ,CompositionAssetId int )

    create nonclustered index [ix_#CompositionAssetStatusBySite_01] on #CompositionAssetStatusBySite (MediaSiteId,CompositionAssetStatusId)


    IF @MediaSiteId IS NULL
        begin

            DROP TABLE #CurAndFutureFlightDateAssetMap
			CREATE table #CurAndFutureFlightDateAssetMap
                (MediaSiteId int not null
                ,FlightTypeId smallint null
                ,FlightDate date
                ,CompositionAssetStatus varchar(50) )  
            create index ix_#CurAndFutureFlightDateAssetMap_01 on #CurAndFutureFlightDateAssetMap (MediaSiteId,FlightDate)

			DROP TABLE #SiteMissingContent
            create table #SiteMissingContent
                (MediaSiteId int not null
                                 primary key
                ,TDC_ID int null
                ,SiteName varchar(256) null
                ,Address varchar(50) null
                ,City varchar(50) null
                ,State varchar(50) null
                ,Zip varchar(50) null
                ,ExhibitorName varchar(50) null
                ,ElectronicDeliveryAddress varchar(250) null
                ,ApiVersion varchar(50) null
                ,LastAttemptedConnectionDate datetime null
                ,LastSuccessfulConnectionDate datetime null
                ,ConnectionErrorCount smallint null
                ,ConnectionErrorMessage varchar(1000) null
                ,AssetsMissingOnDisk int null
                ,AssetsMissingOnTMS int null
                ,AssetsSizeMismatch int null
                ,AssetsHashError int null
                ,AssetsHashComplete int null
                ,DeliveryStatus varchar(1000) null
                ,CompositionAssetStatus varchar(255) null
                ,FutureFlightDate date null
                ,FutureCompositionAssetStatus varchar(255) null
                ,TempSwitchedToUsb bit null )                      -- 2013/08/21 added temporary switch to Usb flag   



            -- get site for the selected FlightDate

            insert  into #CurAndFutureFlightDateAssetMap
                    ( MediaSiteId
                    ,FlightTypeId
                    ,FlightDate )
                    select  pl1.MediaSiteId
                           ,1 as FlightTypeId
                           ,@FlightDate as CurrentWeekFlightDate
                    from    dc.Playlist pl1 ( nolock )
                    join    dc.Site s ( nolock )
                    on      pl1.MediaSiteId = s.MediaSiteId
                    where   pl1.FlightDate = @FlightDate
                            and ( s.PlaylistDeliveryTypeId = @ElectronicDeliveryMode
                                  or isnull(s.ElectronicDeliveryAddress, '') <> ''
                                  and s.PlaylistDeliveryTypeId = @UsbDriveDeliveryMode )
                    group by pl1.MediaSiteId
                    union all
                    select  plc.MediaSiteId
                           ,2 as FlightTypeId
                           ,min(plc.FlightDate) as FutureFlightDate
                    from    dc.Playlist plc ( nolock )
                    join    dc.Site s ( nolock )
                    on      plc.MediaSiteId = s.MediaSiteId
                    join    dc.Playlist plf ( nolock )
                    on      plc.MediaSiteId = plf.MediaSiteId
                    where   plf.FlightDate = @FlightDate
                            and plc.FlightDate > @FlightDate
                            and ( s.PlaylistDeliveryTypeId = @ElectronicDeliveryMode
                                  or isnull(s.ElectronicDeliveryAddress, '') <> ''
                                  and s.PlaylistDeliveryTypeId = @UsbDriveDeliveryMode )
                    group by plc.MediaSiteId


    


            insert  into #CompositionAssetStatusBySite
                    ( MediaSiteId
                    ,CompositionAssetStatusId
                    ,CompositionAssetId )
                    select distinct
                            s.MediaSiteId
                           ,sca.CompositionAssetStatusId
                           ,sca.CompositionAssetId
                    from    #CurAndFutureFlightDateAssetMap s
                    join    dc.Playlist p ( nolock )
                    on      s.MediaSiteId = p.MediaSiteId
                    join    dc.PlaylistAsset pa ( nolock )
                    on      p.PlaylistId = pa.PlaylistId
                    join    dc.MediaAsset ma ( nolock )
                    on      pa.MediaAssetId = ma.MediaAssetId
                    join    dc.MediaAssetComposition mac ( nolock )
                    on      ma.MediaAssetId = mac.MediaAssetId
                    join    dc.Composition c ( nolock )
                    on      mac.CompositionId = c.CompositionId
                            and mac.AspectTypeId = c.AspectTypeId
                    join    dc.CompositionAssetMap cam ( nolock )
                    on      c.CompositionId = cam.CompositionId
                    join    dc.CompositionAsset ca ( nolock )
                    on      cam.CompositionAssetId = ca.CompositionAssetId
                    join    dc.SiteCompositionAsset sca ( nolock )
                    on      s.MediaSiteId = sca.MediaSiteId
                            and ca.CompositionAssetId = sca.CompositionAssetId
                    where   p.FlightDate = @FlightDate
                            and s.FlightTypeId = 1

END

--SELECT * FROM dc.CompositionAsset
--SELECT * FROM dc.CompositionAssetStatus

SELECT a.*, b.TDC_ID, REPLACE(c.Path,'Assets\',''), *
FROM #CompositionAssetStatusBySite a 
INNER JOIN dc.Site b ON a.MediaSiteId = b.MediaSiteId
INNER JOIN dc.CompositionAsset c ON c.CompositionAssetId = a.CompositionAssetId
WHERE a.CompositionAssetStatusId = 1 
AND b.TDC_ID = 1005037 

SELECT b.TDC_ID, COUNT(*)
FROM #CompositionAssetStatusBySite a 
INNER JOIN dc.Site b ON a.MediaSiteId = b.MediaSiteId
INNER JOIN dc.CompositionAsset c ON c.CompositionAssetId = a.CompositionAssetId
WHERE --b.TDC_ID = 1011300 AND 
a.CompositionAssetStatusId = 1
GROUP BY b.TDC_ID
--HAVING count(*) >1


SELECT DISTINCT REPLACE(c.Path,'Assets\','')
FROM #CompositionAssetStatusBySite a 
INNER JOIN dc.Site b ON a.MediaSiteId = b.MediaSiteId
INNER JOIN dc.CompositionAsset c ON c.CompositionAssetId = a.CompositionAssetId
WHERE --b.TDC_ID = 1017810 AND 
a.CompositionAssetStatusId = 1


