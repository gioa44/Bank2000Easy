SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[SYS_ADD_DATE_CONSTRAINTS] (@dt smalldatetime) AS

DECLARE @sql nvarchar(4000)

DECLARE 
	@max_s nvarchar(10),
	@s nvarchar(4),
	@year int

SET @year = YEAR(@dt - 1)
SET @s = dbo.sys_get_arc_table_suffix(@year)
SET @max_s = dbo.sys_get_date_str (@dt)
SET @max_s = '''' + @max_s + ''''

SET @sql = N'

ALTER TABLE dbo.' + dbo.sys_get_arc_table_name('OPS',@year) + N' WITH CHECK ADD CONSTRAINT CK_' + dbo.sys_get_arc_table_name('OPS',@year) + N'
CHECK (DOC_DATE >= ''' + @s + '0101'' AND DOC_DATE < ' + @max_s + N')

ALTER TABLE dbo.' + dbo.sys_get_arc_table_name('OPS',0) + N' WITH CHECK ADD CONSTRAINT CK_' + dbo.sys_get_arc_table_name('OPS',0) + N'
CHECK (DOC_DATE >= ' + @max_s + N')

ALTER TABLE dbo.' + dbo.sys_get_arc_table_name('OPS_HELPER',@year) + N' WITH CHECK ADD CONSTRAINT CK_' + dbo.sys_get_arc_table_name('OPS_HELPER',@year) + N'
CHECK (DT >= ''' + @s + '0101'' AND DT < ' + @max_s + N')

ALTER TABLE dbo.' + dbo.sys_get_arc_table_name('OPS_HELPER',0) + N' WITH CHECK ADD CONSTRAINT CK_' + dbo.sys_get_arc_table_name('OPS_HELPER',0) + N'
CHECK (DT >= ' + @max_s + N')

ALTER TABLE dbo.' + dbo.sys_get_arc_table_name('SALDOS',@year) + N' WITH CHECK ADD CONSTRAINT CK_' + dbo.sys_get_arc_table_name('SALDOS',@year) + N'
CHECK (DT >= ''' + @s + '0101'' AND DT < ' + @max_s + N')

ALTER TABLE dbo.' + dbo.sys_get_arc_table_name('BAL',@year) + N' WITH CHECK ADD CONSTRAINT CK_' + dbo.sys_get_arc_table_name('BAL',@year) + N'
CHECK (DT >= ''' + @s + '0101'' AND DT < ' + @max_s + N')

ALTER TABLE dbo.' + dbo.sys_get_arc_table_name('VAL_RATES',@year) + N' WITH CHECK ADD CONSTRAINT CK_' + dbo.sys_get_arc_table_name('VAL_RATES',@year) + N'
CHECK (DT >= ''' + @s + '0101'' AND DT < ' + @max_s + N')

ALTER TABLE dbo.' + dbo.sys_get_arc_table_name('VAL_RATES',0) + N' WITH CHECK ADD CONSTRAINT CK_' + dbo.sys_get_arc_table_name('VAL_RATES',0) + N'
CHECK (DT >= ' + @max_s + N')'

EXEC sp_executesql @sql
GO
