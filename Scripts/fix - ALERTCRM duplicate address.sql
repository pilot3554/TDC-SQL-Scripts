USE AlertCRM

UPDATE dbo.Address
SET ModifyDate = GETDATE(), ModifiedByUser ='alexanp1', AddressCode = '00'
WHERE AddressID = '6D8512E9-34A4-4737-A330-B57CAF80511D'


SELECT * 
FROM dbo.Address
WHERE CompanyCode = '1006105'
