SELECT TOP 10 * FROM AlertCRM.dbo.Address WHERE addresscode='primary' AND companyCode IS NOT NULL AND Timezone IS NOT NULL and companycode<2000000 AND AddressID = '0D373DE3-6CFB-4F8E-943B-38E780AFA03C'
SELECT TOP 10 * FROM [LAXDC-D-DB02].KMS_001.dbo.tblTheatres WHERE AddressID = '0D373DE3-6CFB-4F8E-943B-38E780AFA03C'
SELECT TOP 10 * FROM [LAXDC-D-DB02].KMS_001.dbo.tblAuditorium WHERE AddressID = '0D373DE3-6CFB-4F8E-943B-38E780AFA03C'

UPDATE AlertCRM.dbo.Address SET [State]='ZZ' WHERE AddressID = '0D373DE3-6CFB-4F8E-943B-38E780AFA03C'
UPDATE AlertCRM.dbo.Address SET UserText2='ZZ' WHERE AddressID = '0D373DE3-6CFB-4F8E-943B-38E780AFA03C'

UPDATE AlertCRM.dbo.Address SET [State]='' WHERE AddressID = '0D373DE3-6CFB-4F8E-943B-38E780AFA03C'
UPDATE AlertCRM.dbo.Address SET UserText2='' WHERE AddressID = '0D373DE3-6CFB-4F8E-943B-38E780AFA03C'
----------------------------------------------------------------------------------------------------------------

SELECT TOP 10 * FROM AlertCRM.dbo.Company WHERE CompanyID = 'D1802A92-64D7-49B8-97F8-B6F4CCFBD1EB'
SELECT TOP 10 * FROM [LAXDC-D-DB02].KMS_001.dbo.tblKeyDeliveryFormat WHERE CompanyID = 'D1802A92-64D7-49B8-97F8-B6F4CCFBD1EB'

UPDATE AlertCRM.dbo.Company SET UserText19 = 'zz' WHERE CompanyID = 'D1802A92-64D7-49B8-97F8-B6F4CCFBD1EB'
UPDATE AlertCRM.dbo.Company SET UserText19 = '' WHERE CompanyID = 'D1802A92-64D7-49B8-97F8-B6F4CCFBD1EB'

----------------------------------------------------------------------------------------------------------------

SELECT TOP 10 * FROM AlertCRM.dbo.CompanyEquipment WHERE ItemNumber in (select itemNumber from [alertCRM].[dbo].[ItemMaster] where userText6 in ('Screen Server','Mastering Station')) AND lineid = '8E36F1BC-12AB-4B2A-A9B0-00004C03ABF4'
SELECT TOP 10 * FROM [LAXDC-D-DB02].KMS_001.dbo.tblEquipment WHERE lineid = '8E36F1BC-12AB-4B2A-A9B0-00004C03ABF4'

UPDATE AlertCRM.dbo.CompanyEquipment SET UserText3 = 'ZZ'  WHERE lineid = '8E36F1BC-12AB-4B2A-A9B0-00004C03ABF4'
UPDATE AlertCRM.dbo.CompanyEquipment SET UserText3 = ''  WHERE lineid = '8E36F1BC-12AB-4B2A-A9B0-00004C03ABF4'

----------------------------------------------------------------------------------------------------------------

SELECT TOP 10 * FROM AlertCRM.dbo.ItemMaster WHERE ItemNumber in (select itemNumber from alertCRM.dbo.ItemMaster where userText6 in ('Screen Server','Mastering Station')) AND ItemNumber = 'ARR-QCP'
SELECT TOP 10 * FROM [LAXDC-D-DB02].KMS_001.dbo.tblMakeModelXref WHERE ItemNumber = 'ARR-QCP'

UPDATE AlertCRM.dbo.ItemMaster SET UserText7 = 'ARRI-QCP2' WHERE ItemNumber = 'ARR-QCP'
UPDATE AlertCRM.dbo.ItemMaster SET UserText7 = 'ARRI-QCP' WHERE ItemNumber = 'ARR-QCP'

----------------------------------------------------------------------------------------------------------------

SELECT TOP 10 * FROM [TDC_DB01].dbo.tblCertificates WHERE Thumbprint = '3D61DA5558BA57A52016CD4EBCFF02BA945AAE8E'
SELECT TOP 10 * FROM [LAXDC-D-DB02].KMS_001.dbo.tblCertificates WHERE Thumbprint = '3D61DA5558BA57A52016CD4EBCFF02BA945AAE8E'

UPDATE [TDC_DB01].dbo.tblCertificates SET AlertEquipmentID = '8E36F1BC-12AB-4B2A-A9B0-00004C03ABF4' WHERE Thumbprint = '3D61DA5558BA57A52016CD4EBCFF02BA945AAE8E'
UPDATE [TDC_DB01].dbo.tblCertificates SET AlertEquipmentID = NULL WHERE Thumbprint = '3D61DA5558BA57A52016CD4EBCFF02BA945AAE8E'
