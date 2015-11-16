SELECT COUNT(*) 
FROM [dbo].[KeyOrders] a (NOLOCK)
INNER JOIN kms_001.[dbo].[tblKeyGenJobs] b (NOLOCK) ON a.KeyWorkOrderID = b.jobid
INNER JOIN [dbo].[tblKeyPackageXref] c (NOLOCK) ON a.KeyOrderID = c.keyOrderID
INNER JOIN kms_001.[dbo].[tblKeyGenJobEntries] d (NOLOCK) ON d.jobID = b.jobID
WHERE c.packageID = 532707


SELECT TOP 10 b.dateCompleted, DATENAME(weekday,b.dateCompleted), a.*
FROM [dbo].[KeyOrders] a (NOLOCK)
INNER JOIN kms_001.[dbo].[tblKeyGenJobs] b (NOLOCK) ON a.KeyWorkOrderID = b.jobid
INNER JOIN [dbo].[tblKeyPackageXref] c (NOLOCK) ON a.KeyOrderID = c.keyOrderID
INNER JOIN kms_001.[dbo].[tblKeyGenJobEntries] d (NOLOCK) ON d.jobID = b.jobID
WHERE c.packageID = 532707

SELECT COUNT(*) , CONVERT(VARCHAR,b.dateCompleted,101)
FROM [dbo].[KeyOrders] a (NOLOCK)
INNER JOIN kms_001.[dbo].[tblKeyGenJobs] b (NOLOCK) ON a.KeyWorkOrderID = b.jobid
INNER JOIN [dbo].[tblKeyPackageXref] c (NOLOCK) ON a.KeyOrderID = c.keyOrderID
INNER JOIN kms_001.[dbo].[tblKeyGenJobEntries] d (NOLOCK) ON d.jobID = b.jobID
WHERE c.packageID = 532707
GROUP BY CONVERT(VARCHAR,b.dateCompleted,101)


SELECT COUNT(*) , c.packageID
FROM [dbo].[KeyOrders] a (NOLOCK)
INNER JOIN kms_001.[dbo].[tblKeyGenJobs] b (NOLOCK) ON a.KeyWorkOrderID = b.jobid
INNER JOIN [dbo].[tblKeyPackageXref] c (NOLOCK) ON a.KeyOrderID = c.keyOrderID
INNER JOIN kms_001.[dbo].[tblKeyGenJobEntries] d (NOLOCK) ON d.jobID = b.jobID
--WHERE c.packageID = 532707
WHERE  b.dateCompleted > '09/01/2015'
GROUP BY c.packageID
ORDER BY COUNT(*) DESC


SELECT COUNT(*) , CONVERT(VARCHAR,b.dateStarted,101),  DATENAME(weekday,b.dateStarted)
FROM [dbo].[KeyOrders] a (NOLOCK)
INNER JOIN kms_001.[dbo].[tblKeyGenJobs] b (NOLOCK) ON a.KeyWorkOrderID = b.jobid
INNER JOIN [dbo].[tblKeyPackageXref] c (NOLOCK) ON a.KeyOrderID = c.keyOrderID
INNER JOIN kms_001.[dbo].[tblKeyGenJobEntries] d (NOLOCK) ON d.jobID = b.jobID
--WHERE c.packageID = 532707
WHERE  b.dateCompleted > '01/01/2015'
GROUP BY CONVERT(VARCHAR,b.dateStarted,101), DATENAME(weekday,b.dateStarted)
ORDER BY CONVERT(VARCHAR,b.dateStarted,101)