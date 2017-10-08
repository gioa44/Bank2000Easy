SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS OFF
GO

CREATE PROCEDURE [dbo].[SYS_DELETE_NEW_YEAR]
AS

SET NOCOUNT ON;

DECLARE
  @sql nvarchar(4000),
  @date smalldatetime,
  @r int

SET @date = dbo.bank_open_date ()

DECLARE @msg nvarchar(255)
SET @msg =  'DELETING YEAR: ' + CONVERT(varchar(4),YEAR(@date))
PRINT @msg

IF DAY(@date) <> 1 OR MONTH(@date) <> 1
BEGIN
  SET @msg = CONVERT(varchar(20), @date, 103)
  RAISERROR ('<ERR>Cannot delete year. %s is not JAN 01</ERR>', 16, 1, @msg)
  RETURN(-1009)
END

DECLARE @year int
SET @year = YEAR(@date)

SET @sql = N'DROP TABLE dbo.' + dbo.sys_get_arc_table_name('SALDOS',@year)
EXEC sp_executesql @sql
SET @sql = N'DROP TABLE dbo.' + dbo.sys_get_arc_table_name('OPS_HELPER',@year)
EXEC sp_executesql @sql
SET @sql = N'DROP TABLE dbo.' + dbo.sys_get_arc_table_name('OPS',@year)
EXEC sp_executesql @sql
SET @sql = N'DROP TABLE dbo.' + dbo.sys_get_arc_table_name('BAL',@year)
EXEC sp_executesql @sql
SET @sql = N'DROP TABLE dbo.' + dbo.sys_get_arc_table_name('VAL_RATES',@year)
EXEC sp_executesql @sql


EXEC dbo.SYS_CREATE_OPS_VIEW 1, 0
EXEC dbo.SYS_CREATE_OPS_VIEW 0, 1
EXEC dbo.SYS_CREATE_OPS_VIEW 0, 0

EXEC dbo.SYS_CREATE_BAL_VIEW 0
EXEC dbo.SYS_CREATE_BAL_VIEW 1
EXEC dbo.SYS_CREATE_BAL_VIEW 2

EXEC dbo.SYS_CREATE_SALDOS_VIEW 

EXEC dbo.SYS_CREATE_OPS_HELPER_VIEW 1, 0
EXEC dbo.SYS_CREATE_OPS_HELPER_VIEW 0, 1
EXEC dbo.SYS_CREATE_OPS_HELPER_VIEW 0, 0

EXEC dbo.SYS_CREATE_VAL_RATES_VIEW

SET @year = @year - 1

SET @sql = N'
ALTER TABLE dbo.' + dbo.sys_get_arc_table_name('OPS',@year) + N' DROP CONSTRAINT CK_' + dbo.sys_get_arc_table_name('OPS',@year) + N'
ALTER TABLE dbo.' + dbo.sys_get_arc_table_name('OPS_HELPER',@year) + N' DROP CONSTRAINT CK_' + dbo.sys_get_arc_table_name('OPS_HELPER',@year) + N'
ALTER TABLE dbo.' + dbo.sys_get_arc_table_name('SALDOS',@year) + N' DROP CONSTRAINT CK_' + dbo.sys_get_arc_table_name('SALDOS',@year) + N'
ALTER TABLE dbo.' + dbo.sys_get_arc_table_name('BAL',@year) + N' DROP CONSTRAINT CK_' + dbo.sys_get_arc_table_name('BAL',@year) + N'
ALTER TABLE dbo.' + dbo.sys_get_arc_table_name('VAL_RATES',@year) + N' DROP CONSTRAINT CK_' + dbo.sys_get_arc_table_name('VAL_RATES',@year)

EXEC sp_executesql @sql
GO
