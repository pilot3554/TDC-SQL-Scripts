
SELECT * FROM [Kalmus].[dbo].[AppUser]
WHERE AppUserAccount LIKE '%fl%'

INSERT INTO [Kalmus].[dbo].[AppUser]
           ([AppUserHexID]
           ,[AppUserAccount]
           ,[AppUserEmail]
)
     VALUES
           ('39DDC9CB-50F8-4C18-896C-A840B520AE17'
           ,'FLM Deluxe'
           ,'james.bayhylle@bydeluxe.com'
)
GO

1254
SELECT *
FROM [Kalmus].[dbo].[AppUserCountryAccess]

INSERT INTO [AppUserCountryAccess]
(AppUserID,CountryCode,ActiveFlag)
SELECT DISTINCT 1264, CountryCode, 1
FROM [Kalmus].[dbo].[AppUserCountryAccess]


DELETE FROM [AppUser] WHERE AppUserID = 1253
DELETE FROM [AppUserCountryAccess] WHERE AppUserID = 1114