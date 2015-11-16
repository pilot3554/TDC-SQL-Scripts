use master
go

ALTER DATABASE [ReplifyMon_Restored] SET  SINGLE_USER WITH ROLLBACK IMMEDIATE
GO
drop database [ReplifyMon_Restored]
go

EXECUTE master..sqlbackup 
'-SQL "RESTORE DATABASE [ReplifyMon_Restored] 
FROM DISK = ''\\laxdc-s-utl01\Backups\LAXDC-S-DB03\Data\Full\FULL_(local)_ReplifyMon_20150103_050136.sqb'' 
WITH RECOVERY, 
MOVE ''ReplifyMon'' TO ''G:\DBFiles\ReplifyMon_Restored.mdf'', 
MOVE ''ReplifyMon_log'' TO ''L:\DBFiles\ReplifyMon_Restored_log.ldf'', ORPHAN_CHECK"'




--ALERT
exec sp_kill @dbname = 'ALERT'
--Full restore 
EXECUTE master..sqlbackup '-SQL "RESTORE DATABASE [ALERT] FROM DISK = ''B:\SQLBackup\Full_Prod\FULL_(local)_Alert_20150725_080226.sqb'' WITH NORECOVERY, REPLACE"'
--Diff restore
EXECUTE master..sqlbackup '-SQL "RESTORE DATABASE [ALERT] FROM DISK = ''B:\SQLBackup\Diff_Prod\DIFF_(local)_Alert_20150725_142301.sqb'' WITH RECOVERY, ORPHAN_CHECK"'
GO