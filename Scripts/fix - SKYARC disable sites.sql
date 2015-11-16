-------------------------------
--for dc sites
-------------------------------
SELECT * 
FROM dc.SiteTheatreApi api
INNER JOIN dc.site si ON si.MediaSiteId = api.MediaSiteId
WHERE si.ElectronicDeliveryAddress NOT IN ('11.255.117.2','11.255.121.2')

UPDATE api
SET ActiveFlag = 0
FROM dc.SiteTheatreApi api
INNER JOIN dc.site si ON si.MediaSiteId = api.MediaSiteId
WHERE si.ElectronicDeliveryAddress NOT IN ('11.255.117.2','11.255.121.2')

SELECT * 
FROM dc.SiteTheatreApi api
INNER JOIN dc.site si ON si.MediaSiteId = api.MediaSiteId
WHERE si.ElectronicDeliveryAddress IN ('11.255.117.2','11.255.121.2')

SELECT * 
FROM dc.SiteTheatreApi api
WHERE api.ActiveFlag = 1


-------------------------------
--for dc sites
-------------------------------
SELECT * FROM dbo.StatusType

SELECT * 
FROM dbo.tblMediaSites
WHERE FTPAddress NOT IN ('11.255.117.2','11.255.121.2')

UPDATE dbo.tblMediaSites
SET StatusTypeId = 2
WHERE FTPAddress NOT IN ('11.255.117.2','11.255.121.2')
AND StatusTypeId = 1

SELECT * 
FROM dbo.tblMediaSites
WHERE FTPAddress IN ('11.255.117.2','11.255.121.2')

SELECT StatusTypeId,* 
FROM dbo.tblMediaSites
WHERE StatusTypeId !=2

