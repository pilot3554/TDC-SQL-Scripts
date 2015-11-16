--laxdc-s-db01
-- the custom filed translation is on sharepoint site
--http://standard.technicolor.com/km/svcstts/tts/tdc/dns/Shared%20Documents/Alert%20System/Alert%20Field%20Mapping.XLS

USE AlertCRM

DECLARE @oldcompanycode INT, @newcompanycode INT , @Lineid UNIQUEIDENTIFIER
SET @oldcompanycode = 1013833    
SET @newcompanycode = 1011979  
SET @Lineid = '5c895220-5a41-4ac6-9a77-005d7609b977'

/*
SELECT *
INTO _CompanyEquipment_drop_after_04152015
FROM dbo.CompanyEquipment
*/

SELECT * 
FROM dbo.CompanyEquipment
WHERE lineid = @Lineid
AND CompanyCode = @oldcompanycode

SELECT *
FROM dbo.Address
WHERE CompanyCode = @oldcompanycode
AND AddressCode = 'primary'

SELECT *
FROM dbo.Address
WHERE CompanyCode = @newcompanycode
AND AddressCode = 'primary'



UPDATE dbo.CompanyEquipment
SET 
CompanyCode = @newcompanycode 
,AddressID = (SELECT AddressID FROM dbo.Address WHERE CompanyCode = @newcompanycode AND AddressCode = 'PRIMARY')
,AddressCode = 'PRIMARY'
,CompanyID = (SELECT CompanyID FROM dbo.Address WHERE CompanyCode = @newcompanycode AND AddressCode = 'PRIMARY')
--,UserText1 = 'Exhibitor'  --OWNER
,UserText12 = '14.C.100-89' --LOCATION
,ModifiedByUser = 'alexanp1_bulk'
,ModifyDate = GETDATE()
WHERE 
CompanyCode = @oldcompanycode
AND lineid IN (
'5c895220-5a41-4ac6-9a77-005d7609b977',
'24135423-0f6f-48f3-9058-028db5a15081',
'1dd36cce-dbae-464e-8a2e-05a409680812',
'aa11789e-0946-4c14-8942-094d302d93b3',
'ece26c7b-0e19-45c9-9fa0-09a27a47bb69',
'7b917db2-e859-45e6-b253-0a76668f7f85',
'b55e4fba-2c40-4310-b17a-1277810bc395',
'a1f818af-d44e-474b-a143-1770403526ab',
'cb2aa0c6-4dc5-4da6-9b94-1c0e16ae07ea',
'd8637656-8d6c-4dee-8e9a-1c48be306943',
'c43cbb1d-14b7-4264-8823-1cbcabad7540',
'57bffae2-c2dc-44a6-8d9f-1d2b26e0ce81',
'e937df76-c224-43d7-99f7-1fc606dc0544',
'20796937-be6d-43f2-9664-23e10aaf3544',
'afe0582b-f80b-4415-940b-241bab9687c4',
'f7041988-f144-4759-9284-25bcc5dc12f0',
'c4556d19-8784-432a-981a-273336cfeed3',
'fb7ec97e-3fd7-4e1f-9fd6-2a032d09556e',
'b33c3d87-7503-4546-93b9-2e110e7226c6',
'ba2dd75c-4c35-4487-8bda-34eef0fe7837',
'bce1dc60-fed9-4495-a73f-3620abab3d03',
'96cee72f-1db4-47c6-a768-37547fd40385',
'6ab7eb27-00fb-4cb1-a7bf-40d632e753c9',
'a611fd94-ea6b-482e-90c8-468962cb3e39',
'511e22ee-f83f-483a-950e-479288e5b75a',
'49cbc87f-b896-408e-8ae2-4b883a24450e',
'b08e385b-c0dc-4630-8b13-50cddf28c5ef',
'3c707601-989c-4f33-9ca8-535ac8080815',
'ad80b206-b71c-4bde-a86e-5363d0df089b',
'05dd76ec-5056-476f-b5e1-54ab0798e382',
'567ff821-8bb5-41b8-9bfb-559e02507077',
'76311fcc-15ed-4cd9-b3a0-5657ce6eba40',
'bc484ebd-e863-4237-a76d-58283f123bd1',
'0900825b-118c-440e-b310-5869a5823f44',
'c0004f54-5f38-4322-93d7-6807b76576ac',
'08a3ceea-00e5-49b6-bad0-6980a9c8411e',
'fc0df448-e54e-4fb7-bafc-6d2f72f8ec91',
'25ae97f3-589a-41ea-a165-79e4c6b57537',
'c16ead72-e67e-4e4a-8926-88ab8e43a8df',
'6f6a7ea7-e8eb-4c5d-8936-9181885c75a5',
'f7ff8c85-f4c8-4be5-bb87-92f600656fbb',
'ebf2f585-04d9-43f0-bf10-95ed03454301',
'493520d8-a4c4-45ef-8f72-9699d5ff720c',
'06433506-9638-48c7-9680-995a1970e3c9',
'edef4d51-53f3-4b7c-be35-9dadc70187d2',
'014f0e7d-0047-45b4-92fa-a5aa7e21ea25',
'6091cc6b-7a15-48e6-8945-a6f7ce606196',
'30bd18ce-2bc5-4a62-9b05-a74b02b19f6f',
'851cabe1-8aff-457a-b5fa-a98e0a91187f',
'011345a1-09c4-4e09-a7a1-abd9d2750fcb',
'9eae4128-de8f-42a8-8b6a-adf154aedf2e',
'cc1e6987-0723-4fa5-a917-b420183470e6',
'34fb3ec1-5c93-439d-bcf4-b872ca54f2bd',
'b0b4f6a1-f1d3-4bde-9818-b8b52465dd1d',
'937ff3b9-f155-4750-babf-b8d8e80ef78f',
'8c3a4c79-21e4-4756-9f71-bbc6419ecca9',
'cb895e7c-7f81-430c-aa15-bd7e68e80dc4',
'9835f717-2328-4ae2-8830-be82de3c683a',
'82ee1fbd-ecaa-4f06-9b7f-c1acf1440470',
'4570422f-9c5e-4679-8d96-c35f01122654',
'af629f0f-e81f-4ac2-8889-c5d68af339f9',
'498c3ff0-6917-46d1-a238-c8de6f0b975d',
'84612d69-1406-4465-aebd-c8e43d77a0f5',
'ca4cdc6a-f557-4840-baf3-cc18d028a5b8',
'ef238f72-1910-450f-a9a5-cc4849dc846a',
'0c7278d6-239f-4740-99a3-ce47fa60f7dd',
'3a6adf18-5825-4147-9fe7-ce728408fcde',
'0e438c45-05e0-4292-a7c0-cf73df38a4ba',
'f060edbf-32e0-4975-84ba-d1aba70e7a4c',
'2cbd2ff7-79aa-417d-b65f-d43f4274035f',
'40b2ec52-5837-4983-a828-d7355fb494e3',
'1f44943d-8b30-48a5-b1f7-e769a1dd57d2',
'08500701-e7c5-4df2-b0ae-e8983fdef253',
'58e808fc-5df7-42d1-bcbe-e91256450c7c',
'f54637c4-bb98-4b26-9c57-ea5efe2b74e7',
'1fb7aa80-c876-4c73-a04c-eb63b2e37cca',
'792cdb4b-9681-4f2d-8fe7-ec4a43e89f77',
'e1aef0f3-3a16-41a1-b927-efd8b5aacc18',
'dce9af29-9f88-4494-b6b4-f4514ffd3209',
'87d39dcd-e64d-488a-9ae0-f4fc733206e0',
'4e5941f9-4346-4882-a931-f51af5875fd4',
'd0840ff8-8d83-416d-a2ec-f6732ddf24c0',
'd46f1b2f-cbfa-46cd-9746-fc3215a5fe4a'
)


