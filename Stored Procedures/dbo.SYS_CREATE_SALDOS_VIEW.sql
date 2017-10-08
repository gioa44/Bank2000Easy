SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[SYS_CREATE_SALDOS_VIEW]
AS

DECLARE 
	@sql nvarchar(2000),
	@view_name sysname,
	@year int,
	@y int

SET @view_name = 'SALDOS'
SET @sql = N'IF OBJECT_ID(''' + @view_name + N''')<>0 DROP VIEW dbo.' + @view_name
EXEC sp_executesql @sql

SET @sql = N'CREATE VIEW dbo.' + @view_name + ' AS' + CHAR(13) + CHAR(13)

--IF @is_full <> 0
--	SET @sql = @sql + 'SELECT * FROM dbo.SALDOS_0000' + CHAR(13) + '  UNION ALL' + CHAR(13)

SET @year = YEAR(dbo.bank_first_date ())
IF @year < 2000
	SET @year = 2000

DECLARE @dt smalldatetime

SET @dt = dbo.bank_open_date() - 1

SET @y = @year
WHILE @y <= YEAR(@dt)
BEGIN
  SET @sql = @sql + N'SELECT * FROM dbo.SALDOS_' + CONVERT(nvarchar(4), @y) + ' (NOLOCK)' + CHAR(13)
  IF @y <> YEAR(@dt)
    SET @sql = @sql + N'  UNION ALL' + CHAR(13)
  SET @y = @y + 1
END

EXEC sp_executesql @sql
GO
