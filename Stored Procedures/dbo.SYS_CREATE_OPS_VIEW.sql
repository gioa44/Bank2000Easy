SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[SYS_CREATE_OPS_VIEW] (@is_onlyarc bit, @is_onlydocs bit)
AS

DECLARE 
	@view_name nvarchar(20),
	@sql nvarchar(2000),
	@year int,
	@y int

IF @is_onlyarc = 1
	SET @view_name = 'OPS_ARC'
ELSE
IF @is_onlydocs = 1
	SET @view_name = 'OPS'
ELSE
	SET @view_name = 'OPS_FULL'

SET @sql = N'IF OBJECT_ID(''' + @view_name + ''')<>0 DROP VIEW dbo.' + @view_name
EXEC sp_executesql @sql

SET @sql = N'CREATE VIEW dbo.' + @view_name + ' AS' + CHAR(13) + CHAR(13)

IF @is_onlydocs = 1
  SET @sql = @sql + N'SELECT * FROM dbo.OPS_0000'
ELSE
BEGIN
  IF @is_onlyarc = 0
    SET @sql = @sql +  N'SELECT * FROM dbo.OPS_0000' + CHAR(13) + '  UNION ALL' + CHAR(13)

	SET @year = YEAR(dbo.bank_first_date ())
	IF @year < 2000
	  SET @year = 2000

	DECLARE @dt smalldatetime

	SET @dt = dbo.bank_open_date() - 1

	SET @y = @year
	WHILE @y <= YEAR(@dt)
	BEGIN
	  SET @sql = @sql + N'SELECT * FROM dbo.OPS_' + CONVERT(nvarchar(4), @y) + ' (NOLOCK)' + CHAR(13)
	  IF @y <> YEAR(@dt)
		SET @sql = @sql + N'  UNION ALL' + CHAR(13)
	  SET @y = @y + 1
	END
END

EXEC sp_executesql @sql
GO
