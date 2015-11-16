--db02.kms_001
use kms_001
go
INSERT INTO [dbo].[tblStudioUsers]
           ([userID]
           ,[rightsOwnerID]
           ,[Country])
select '00000000-0000-0000-0000-000000000001',RightsOwnerID,null 
from [KMS_001].[dbo].[tblRightsOwner] 
where RightsOwnerID not in 
(
select RightsOwnerID
FROM [KMS_001].[dbo].[tblStudioUsers] su 
where userID='00000000-0000-0000-0000-000000000001'
)

--send email
if exists (select '00000000-0000-0000-0000-000000000001',RightsOwnerID,null 
from [KMS_001].[dbo].[tblRightsOwner] 
where RightsOwnerID not in 
(
select RightsOwnerID
FROM [KMS_001].[dbo].[tblStudioUsers] su 
where userID='00000000-0000-0000-0000-000000000001'
)
)
begin

DECLARE @tableHTML  NVARCHAR(MAX) ;

SET @tableHTML =
    N'<H1>tblStudioUsers missing records</H1>' +
    N'<table border="1">' +
    N'<tr><th>Work Order ID</th><th>Product ID</th>' +
    N'<th>Name</th><th>Order Qty</th><th>Due Date</th>' +
    N'<th>Expected Revenue</th></tr>' +
    CAST ( ( SELECT td = '00000000-0000-0000-0000-000000000001' ,       '',
                    td = RightsOwnerID
					from [KMS_001].[dbo].[tblRightsOwner] 
					where RightsOwnerID not in 
					(
					select RightsOwnerID
					FROM [KMS_001].[dbo].[tblStudioUsers] su 
					where userID='00000000-0000-0000-0000-000000000001'
					)
              FOR XML PATH('tr'), TYPE 
    ) AS NVARCHAR(MAX) ) +
    N'</table>' ;
print @tableHTML 

EXEC msdb.dbo.sp_send_dbmail
    @recipients = 'patrick.alexander@technicolor.com',
    @subject = 'tblStudioUsers missing records',
    @body = @tableHTML,
    @body_format = 'HTML' ;

end    