SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[SYS_CREATE_BAL_VIEW] (@type tinyint) -- @type in (0,1,2,3)
AS

DECLARE 
	@sql nvarchar(2000),
	@year int,
	@y int,
	@view_name sysname,
	@field_list varchar(512)

IF @type = 0
BEGIN
	SET @view_name = 'BALANCES_WIDE'
	SET @field_list = '*'
END
ELSE
IF @type = 1
BEGIN
	SET @view_name = 'BALANCES'
	SET @field_list = 'DT, BRANCH_ID, DEPT_NO, BAL_ACC, ISO, DBO, CRO, DBS, CRS'
END
ELSE
IF @type = 2
BEGIN
	SET @view_name = 'BALANCES_EQU'
	SET @field_list = 'DT, BRANCH_ID, DEPT_NO, BAL_ACC, ISO, DBO_EQU AS DBO, CRO_EQU AS CRO, DBS_EQU AS DBS, CRS_EQU AS CRS'
END

SET @sql = N'IF OBJECT_ID(''' + @view_name + ''')<>0 DROP VIEW dbo.' + @view_name
EXEC sp_executesql @sql

SET @sql = N'CREATE VIEW dbo.' + @view_name + ' AS' + char(13)

SET @year = YEAR(dbo.bank_first_date ())
IF @year < 2000
  SET @year = 2000

DECLARE @dt smalldatetime

SET @dt = dbo.bank_open_date() - 1

SET @y = @year
WHILE @y <= YEAR(@dt)
BEGIN
  SET @sql = @sql + N'SELECT ' + @field_list + ' FROM dbo.BAL_' + CONVERT(nvarchar(4), @y) + ' (NOLOCK)' + CHAR(13)
  IF @y <> YEAR(@dt)
    SET @sql = @sql + N'  UNION ALL' + CHAR(13)
  SET @y = @y + 1
END

EXEC sp_executesql @sql
GO
