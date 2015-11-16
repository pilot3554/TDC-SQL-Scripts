-- List all SSRS subscriptions 
USE [ReportServer];  -- You may change the database name. 
GO 
 
SELECT USR.UserName AS SubscriptionOwner 
      ,SUB.ModifiedDate 
      ,SUB.[Description] 
      ,SUB.EventType 
      ,SUB.DeliveryExtension 
      ,SUB.LastStatus 
      ,SUB.LastRunTime 
      ,SCH.NextRunTime 
      ,SCH.Name AS ScheduleName       
      ,CAT.[Path] AS ReportPath 
      ,CAT.[Description] AS ReportDescription 
FROM dbo.Subscriptions AS SUB 
     INNER JOIN dbo.Users AS USR 
         ON SUB.OwnerID = USR.UserID 
     INNER JOIN dbo.[Catalog] AS CAT 
         ON SUB.Report_OID = CAT.ItemID 
     INNER JOIN dbo.ReportSchedule AS RS 
         ON SUB.Report_OID = RS.ReportID 
            AND SUB.SubscriptionID = RS.SubscriptionID 
     INNER JOIN dbo.Schedule AS SCH 
         ON RS.ScheduleID = SCH.ScheduleID 
ORDER BY USR.UserName 
        ,CAT.[Path];
        
SELECT Reportname = c.Name 
  ,FileLocation = c.Path
  ,SubscriptionDesc=su.Description 
  ,Subscriptiontype=su.EventType 
  ,su.LastStatus 
  ,su.LastRunTime 
  ,Schedulename=sch.Name 
  ,ScheduleType = sch.EventType 
  ,ScheduleFrequency = 
   CASE sch.RecurrenceType 
   WHEN 1 THEN 'Once' 
   WHEN 2 THEN 'Hourly' 
   WHEN 4 THEN 'Daily/Weekly' 
   WHEN 5 THEN 'Monthly' 
   END 
  ,su.Parameters 
  FROM Reportserver.dbo.Subscriptions su 
  JOIN Reportserver.dbo.Catalog c 
    ON su.Report_OID = c.ItemID 
  JOIN Reportserver.dbo.ReportSchedule rsc 
    ON rsc.ReportID = c.ItemID 
   AND rsc.SubscriptionID = su.SubscriptionID 
  JOIN Reportserver.dbo.Schedule Sch 
    ON rsc.ScheduleID = sch.ScheduleID 
ORDER BY LastRunTime DESC