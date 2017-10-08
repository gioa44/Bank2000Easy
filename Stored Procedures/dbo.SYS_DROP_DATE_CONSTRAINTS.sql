SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[SYS_DROP_DATE_CONSTRAINTS] (@year int) AS

DECLARE @sql nvarchar(4000)

SET @sql = N'
ALTER TABLE dbo.' + dbo.sys_get_arc_table_name('OPS',@year) + N' DROP CONSTRAINT CK_' + dbo.sys_get_arc_table_name('OPS',@year) + N'
ALTER TABLE dbo.' + dbo.sys_get_arc_table_name('OPS',0) + N' DROP CONSTRAINT CK_' + dbo.sys_get_arc_table_name('OPS',0) + N'
ALTER TABLE dbo.' + dbo.sys_get_arc_table_name('OPS_HELPER',@year) + N' DROP CONSTRAINT CK_' + dbo.sys_get_arc_table_name('OPS_HELPER',@year) + N'
ALTER TABLE dbo.' + dbo.sys_get_arc_table_name('OPS_HELPER',0) + N' DROP CONSTRAINT CK_' + dbo.sys_get_arc_table_name('OPS_HELPER',0) + N'
ALTER TABLE dbo.' + dbo.sys_get_arc_table_name('SALDOS',@year) + N' DROP CONSTRAINT CK_' + dbo.sys_get_arc_table_name('SALDOS',@year) + N'
ALTER TABLE dbo.' + dbo.sys_get_arc_table_name('BAL',@year) + N' DROP CONSTRAINT CK_' + dbo.sys_get_arc_table_name('BAL',@year) + N'
ALTER TABLE dbo.' + dbo.sys_get_arc_table_name('VAL_RATES',@year) + N' DROP CONSTRAINT CK_' + dbo.sys_get_arc_table_name('VAL_RATES',@year) + N'
ALTER TABLE dbo.' + dbo.sys_get_arc_table_name('VAL_RATES',0) + N' DROP CONSTRAINT CK_' + dbo.sys_get_arc_table_name('VAL_RATES',0)

EXEC sp_executesql @sql
GO
