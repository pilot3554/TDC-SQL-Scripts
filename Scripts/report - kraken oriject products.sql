
SELECT a.ProjectType, b.ProjectSubtype, c.ProductName, e.TaskTemplateName, *
FROM dbo.ProjectType a 
INNER JOIN ProjectSubtype b ON a.ProjectTypeID = b.ProjectTypeID
INNER JOIN Product c ON b.ProjectSubtypeID = c.ProjectSubtypeID
INNER JOIN ProductTaskTemplate d ON c.ProductID = d.ProductID
INNER JOIN TaskTemplate e ON d.TaskTemplateID = e.TaskTemplateID
WHERE a.ActiveFlag = 1 AND b.ActiveFlag = 1  AND c.DeleteFlag = 0 AND d.DeleteFlag = 0 
ORDER BY a.ProjectType, b.ProjectSubtype, c.ProductName, e.TaskTemplateName

