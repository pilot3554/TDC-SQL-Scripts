exec master.dbo.sp_addlinkedserver @server = N'laxdc-s-db02', @srvproduct=N'SQLOLEDB', @provider=N'SQLNCLI', @datasrc=N'DCBWALEXANDP'
exec master.dbo.sp_addlinkedsrvlogin @rmtsrvname=N'laxdc-s-db02',@useself=N'False',@locallogin=null,@rmtuser=N'rptuser',@rmtpassword='ActiveX1'
GO
EXEC master.dbo.sp_serveroption @server=N'laxdc-s-db02', @optname=N'collation compatible', @optvalue=N'false'
GO
EXEC master.dbo.sp_serveroption @server=N'laxdc-s-db02', @optname=N'data access', @optvalue=N'true'
GO
EXEC master.dbo.sp_serveroption @server=N'laxdc-s-db02', @optname=N'dist', @optvalue=N'false'
GO
EXEC master.dbo.sp_serveroption @server=N'laxdc-s-db02', @optname=N'pub', @optvalue=N'false'
GO
EXEC master.dbo.sp_serveroption @server=N'laxdc-s-db02', @optname=N'rpc', @optvalue=N'true'
GO
EXEC master.dbo.sp_serveroption @server=N'laxdc-s-db02', @optname=N'rpc out', @optvalue=N'true'
GO
EXEC master.dbo.sp_serveroption @server=N'laxdc-s-db02', @optname=N'sub', @optvalue=N'false'
GO
EXEC master.dbo.sp_serveroption @server=N'laxdc-s-db02', @optname=N'connect timeout', @optvalue=N'0'
GO
EXEC master.dbo.sp_serveroption @server=N'laxdc-s-db02', @optname=N'collation name', @optvalue=null
GO
EXEC master.dbo.sp_serveroption @server=N'laxdc-s-db02', @optname=N'lazy schema validation', @optvalue=N'false'
GO
EXEC master.dbo.sp_serveroption @server=N'laxdc-s-db02', @optname=N'query timeout', @optvalue=N'0'
GO
EXEC master.dbo.sp_serveroption @server=N'laxdc-s-db02', @optname=N'use remote collation', @optvalue=N'true'
GO
EXEC master.dbo.sp_serveroption @server=N'laxdc-s-db02', @optname=N'remote proc transaction promotion', @optvalue=N'false'
GO