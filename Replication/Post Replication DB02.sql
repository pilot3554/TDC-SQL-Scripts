--run on LAXDC-G-DB02

USE [KMS_001]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO
--recreate index for Active sites
CREATE UNIQUE CLUSTERED INDEX [ix_tblKeyDeliveryFormat_01] ON [dbo].[tblKeyDeliveryFormat] ([CompanyCode], [Active])
GO
CREATE NONCLUSTERED INDEX [ix_tblKeyDeliveryFormat_02] ON [dbo].[tblKeyDeliveryFormat] ([Category], [Active], [CompanyCode])
GO
--recreate index for tblAuditorium
IF  NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[tblAuditorium]') AND name = N'PK_tblAuditorium')
CREATE CLUSTERED INDEX [PK_tblAuditorium] ON [dbo].[tblAuditorium]
(
    [CompanyCode] ASC,
    [AddressCode] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO

-- recreate index for the theatre table
CREATE UNIQUE CLUSTERED INDEX [ix_tblTheatres_01] ON [dbo].[tblTheatres] ([CompanyCode])

--recreate index for the equipment table

--those are in QA only as of 01/23/2012:

CREATE NONCLUSTERED INDEX [ix_tblEquipment_01] ON [dbo].[tblEquipment] ([CompanyCode] ASC, [AddressCode] ASC)
INCLUDE ( [LineID] ) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ix_tblEquipment_02] ON [dbo].[tblEquipment] ([ItemNumber] ASC, [SerialNumber] ASC)
ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ix_tblEquipment_03] ON [dbo].[tblEquipment] ([SerialNumber] ASC, [ItemNumber] ASC)
ON [PRIMARY]
GO


--Recreate the indexed view
GO

create view dbo.viewTheatreSearch
with
    schemabinding

as

select  AddressID
       ,SearchTextCol = isnull(t.CompanyCode,'')    + ', ' + 
                        isnull(t.Name,'')           + ', ' + 
                        isnull(t.Address1,'')       + ', ' + 
                        isnull(t.City,'')           + ', ' + 
                        isnull(t.[State],'')        + ', ' + 
                        isnull(t.Zip,'')            + ', ' + 
                        isnull(t.Country,'')        + ', ' +
                        isnull(N.Countrycode3,'')   + ', ' +
                        isnull(n.CountryNameText,'')
from    dbo.tblTheatres t
join    dbo.tblKeyDeliveryFormat f 
on      f.CompanyCode = t.CompanyCode
join    dbo.CountryNameText n 
on      t.Country = n.Countrycode
where   f.Active = 1
        and n.ActiveFlag = 1
GO

--indexes
CREATE UNIQUE CLUSTERED INDEX [idx_ViewTheatreSearch_01] ON [dbo].[viewTheatreSearch] ([AddressID]) ON [PRIMARY]
GO
-- Full Text Information

CREATE FULLTEXT INDEX ON [dbo].[viewTheatreSearch] KEY INDEX [idx_ViewTheatreSearch_01] ON [KMS_001_Catalog] WITH CHANGE_TRACKING AUTO
GO
ALTER FULLTEXT INDEX ON [dbo].[viewTheatreSearch] ADD ([SearchTextCol] LANGUAGE 1033)
GO

--Explicit permissions
GRANT SELECT ON  [dbo].[tblTheatres] TO [FMUser]
GO

--TBLprojector
--ALTER TABLE [dbo].[tblProjector] ADD CONSTRAINT [PK_tblProjector] PRIMARY KEY CLUSTERED  ([LineID])
--GO
--CREATE NONCLUSTERED INDEX [ix_tblProjector_01] ON [dbo].[tblProjector] ([CompanyCode], [AddressCode])
--GO


USE [KMS_001]
GO

CREATE NONCLUSTERED INDEX [ix_tblCertificates_01] ON [dbo].[tblCertificates]
(
    [CertificateID],
    [DnQualifier]
)
GO
CREATE NONCLUSTERED INDEX [ix_tblCertificates_02] ON [dbo].[tblCertificates] 
(
    [AlertEquipmentID]) INCLUDE ([DnQualifier], [Thumbprint]
)
GO
