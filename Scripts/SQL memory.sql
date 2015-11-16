--Total Server Memory (KB) 
--Specifies the amount of memory the server has committed using the memory manager.
SELECT object_name ,counter_name, cntr_value, cntr_type
FROM sys.dm_os_performance_counters
WHERE counter_name = 'Total Server Memory (KB)'

--Target Server Memory (KB) 
--Indicates the ideal amount of memory the server can consume.
SELECT object_name ,counter_name, cntr_value, cntr_type
FROM sys.dm_os_performance_counters
WHERE counter_name = 'Target Server Memory (KB)'

--Results need to be close
--When the Total Server Memory and Target Server Memory values are close, there’s no memory pressure on the server 
--In other words, the Total Server Memory/ Target Server Memory ratio should be close to 1
--If the Total Server Memory value is significantly lower than the Target Server Memory value during normal 
--SQL Server operation, it can mean that there’s memory pressure on the server so SQL Server cannot get 
--as much memory as needed, or that the Maximum server memory option is set too low


SELECT [total_physical_memory_kb] / 1024 AS [Total_Physical_Memory_In_MB]
    ,[available_page_file_kb] / 1024 AS [Available_Physical_Memory_In_MB]
    ,[total_page_file_kb] / 1024 AS [Total_Page_File_In_MB]
    ,[available_page_file_kb] / 1024 AS [Available_Page_File_MB]
    ,[kernel_paged_pool_kb] / 1024 AS [Kernel_Paged_Pool_MB]
    ,[kernel_nonpaged_pool_kb] / 1024 AS [Kernel_Nonpaged_Pool_MB]
    ,[system_memory_state_desc] AS [System_Memory_State_Desc]
FROM [master].[sys].[dm_os_sys_memory]

DBCC MEMORYSTATUS