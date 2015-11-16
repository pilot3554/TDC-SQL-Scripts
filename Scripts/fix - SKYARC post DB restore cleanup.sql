USE [SkyArc_3_02]
GO
--------------------------
-- laxdc-t-db03
--------------------------

UPDATE api
   SET api.ActiveFlag = 0
FROM dc.SiteTheatreApi api 
join dc.Site si
on si.MediaSiteId = api.MediaSiteId
WHERE si.TDC_ID <> 999999
AND api.ActiveFlag != 0

update  [dc].[Site]
set    PlaylistDeliveryTypeId = 1
where PlaylistDeliveryTypeId = 2
and TDC_ID<>'999999'

UPDATE a
SET ElectronicDeliveryAddress = NULL
--SELECT *
FROM [dc].[Site] a
WHERE TDC_ID<>'999999'




--------------------------
-- laxdc-g-db03
--------------------------

USE [SkyArc_3_02]
GO
--this is only for laxdc-t-db03


--test sites
SELECT *
FROM dc.SiteTheatreApi api 
join dc.Site si
on si.MediaSiteId = api.MediaSiteId
WHERE si.TDC_ID IN (1006768,1006211)

SELECT * FROM [dc].[Site]
where PlaylistDeliveryTypeId = 2
and TDC_ID IN (1006768,1006211)

SELECT *
FROM [dc].[Site] a
WHERE TDC_ID IN (1006768,1006211)


--------------------------

UPDATE api
   SET api.ActiveFlag = 0
FROM dc.SiteTheatreApi api 
join dc.Site si
on si.MediaSiteId = api.MediaSiteId
WHERE si.TDC_ID NOT IN (1006768,1006211)
AND api.ActiveFlag != 0

update  [dc].[Site]
set    PlaylistDeliveryTypeId = 1
where PlaylistDeliveryTypeId = 2
and TDC_ID NOT IN (1006768,1006211)

UPDATE a
SET ElectronicDeliveryAddress = NULL
FROM [dc].[Site] a
WHERE TDC_ID<>'999999'


