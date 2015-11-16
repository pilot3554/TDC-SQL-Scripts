--{"KeyID_Prime":"081326090.1022231.4", "CPL": "GRAVITY_FTR_S_FR-FR_INT_51-FR-DBOX_2K_WR_20131025_TEU_VF", "VendorID": "1022231", "Screen_information": "4",

declare @ContentTitleText varchar(255) =  'DolphinTale2_FTR_F_LAS-XX_INT_51_2K_WR_20140826_TDC_IOP',
@Begin datetime = '2014-10-29 13:00:00',
@End datetime = '2014-10-30 22:59:00',
@KdmEmails varchar(500) = 'patrick.alexander@technicolor.com',
@ccFlag char(1) = '1',


@PageSize int = 1500,
@PageIndex int = 0,
@StartIndex int,
@EndIndex int
    
    set @StartIndex = case when @PageSize is null then null
                           else @PageIndex * @PageSize + 1
                      end ;
    set @EndIndex = case when @StartIndex is null then null
                         else @StartIndex + @PageSize - 1
                    end ;


select
A.a,
A.b
from
(
select --top 1500 
RowNum = row_number() over ( order by x.tdcid asc, convert(int, a.AddressCode) asc),
RrowNum = row_number() over ( order by x.tdcid desc, convert(int, a.AddressCode) desc ),
'{"KeyID_Prime":"' + replace(convert(varchar(12),getdate(),114),':','') + '.' + x.tdcId + '.' + convert(varchar(3), convert(int, a.AddressCode)) +'", "CPL": "' + @ContentTitleText + '", "VendorID": "' + x.tdcId + '", "Screen_information": "' +  convert(varchar,convert(int, a.AddressCode)) + '",' a, 
'"LicenseBeginDate": "' + convert(varchar,@Begin,120) + '", "LicenseEndDate": "' + convert(varchar,@End,120) + '", "KDM_Emails": "' + @KdmEmails + '", "BookerName": "Tester","CC": ' + @ccFlag + '},' b

from    dbo.studioTheatreXrefInfo x (nolock) 
join	KMS_001.dbo.tblTheatres t (nolock) on t.CompanyCode = x.TdcId
join	dbo.CountryCodes c (nolock) on c.CountryCode = t.Country     
join    KMS_001.dbo.tblAuditorium a (nolock) 
on      a.CompanyCode = x.TdcId
join	KMS_001.dbo.tblEquipment e (nolock)  on e.CompanyCode = t.CompanyCode
        and e.AddressCode = a.AddressCode
join	KMS_001.dbo.tblCertificates r (nolock)   on r.AlertEquipmentID = e.LineID
        and r.WaimeaStatusID = 1    
where      
        x.StudioId = '2000005' and
        x.DeleteFlag = 0 and
        x.TdcId = x.StudioTheatreId and
        c.IsDomestic = 0 and
        a.AddressCode not in ( 'Primary', '00' ) and
        --convert(int, a.AddressCode) = 2 and
        c.CountryCode3 = 'FRA'
 ) A
 where
	A.RowNum between isnull(@StartIndex, A.RowNum)
               and     isnull(@EndIndex, ( A.RowNum + A.RrowNum - 1 ))
 --order by x.tdcid



--select top 1500
-- RowNum = row_number() over ( order by x.tdcid asc, convert(int, a.AddressCode) asc),
-- RrowNum = row_number() over ( order by x.tdcid desc, convert(int, a.AddressCode) desc ),

--'{"KeyID_Prime":"' + replace(convert(varchar(12),getdate(),114),':','') + '.' + x.tdcId + '.' + convert(varchar(3), convert(int, a.AddressCode)) +'", "CPL": "' + @ContentTitleText + '", "VendorID": "' + x.tdcId + '", "Screen_information": "' +  convert(varchar,convert(int, a.AddressCode)) + '",', 
--'"LicenseBeginDate": "' + convert(varchar,@Begin,120) + '", "LicenseEndDate": "' + convert(varchar,@End,120) + '", "KDM_Emails": "' + @KdmEmails + '", "BookerName": "Tester","CC": ' + @ccFlag + '},' 

--from    dbo.studioTheatreXrefInfo x (nolock) 
--join	KMS_001.dbo.tblTheatres t (nolock) on t.CompanyCode = x.TdcId
--join	dbo.CountryCodes c (nolock) on c.CountryCode = t.Country     
--join    KMS_001.dbo.tblAuditorium a (nolock) 
--on      a.CompanyCode = x.TdcId
--join	KMS_001.dbo.tblEquipment e (nolock)  on e.CompanyCode = t.CompanyCode
--        and e.AddressCode = a.AddressCode
--join	KMS_001.dbo.tblCertificates r (nolock)   on r.AlertEquipmentID = e.LineID
--        and r.WaimeaStatusID = 1    
--where      
--        x.StudioId = '2000005' and
--        x.DeleteFlag = 0 and
--        x.TdcId = x.StudioTheatreId and
--        c.IsDomestic = 0 and
--        a.AddressCode not in ( 'Primary', '00' ) and
--        --convert(int, a.AddressCode) = 2 and
--        c.CountryCode3 = 'FRA'
-- order by x.tdcid desc









