select * 
from master..user_migration 
where name like 'patrick%'

SELECT *
FROM [USER] a 
WHERE a.IsEnabled = 1

SELECT 
a.userid
,a.domain
,a.Username
,a.Email
,b.*,a.*
,'update [user] set domain = ''CORP'', username = '''+b.bydeluxeldap+''' , email = '''+b.bydeluxe+''' where userid = '+CONVERT(VARCHAR,a.UserID)
FROM [USER] a 
INNER JOIN master..user_migration  b ON a.Username = b.technicolorldap
--WHERE a.Username = 'alexanp1'
--WHERE a.IsEnabled = 1
ORDER BY a.userid

SELECT 
a.UserId
,a.UserName
,a.LoweredUserName
,REPLACE(a.Username,'@am','')
,b.*
,'update [aspnet_Users] set UserName = '''+b.bydeluxeldap+'@CORP'', LoweredUserName = '''+LOWER(b.bydeluxeldap)+'@corp''  where userid = '''+CONVERT(VARCHAR(100),a.UserID)+''''
FROM aspnet_Users a
INNER JOIN master..user_migration  b ON REPLACE(a.Username,'@am','') = b.technicolorldap
WHERE REPLACE(a.Username,'@am','') = 'alexanp1'


SELECT 
a.UserId
,a.Email
,a.LoweredEmail
,b.*
,'update [aspnet_Membership] set Email = '''+b.bydeluxe+''', LoweredEmail = '''+LOWER(b.bydeluxe)+'''  where userid = '''+CONVERT(VARCHAR(100),a.UserID)+''''
FROM dbo.aspnet_Membership a
INNER JOIN master..user_migration  b ON a.LoweredEmail = b.technicolor
WHERE a.LoweredEmail = 'patrick.alexander@technicolor.com'

