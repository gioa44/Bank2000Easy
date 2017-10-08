SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[SYS_CREATE_VAL_RATES_TABLE] (@year int, @is_first bit)
AS

DECLARE 
  @sql nvarchar(2000),
  @s nvarchar(4),
  @s1 nvarchar(4)

SET @s = dbo.sys_get_arc_table_suffix(@year)
SET @s1 = dbo.sys_get_arc_table_suffix(@year+1)

SET @sql = N'IF OBJECT_ID(''' + dbo.sys_get_arc_table_name ('VAL_RATES',@year) + ''')<>0 DROP TABLE dbo.' + dbo.sys_get_arc_table_name ('VAL_RATES',@year)
EXEC sp_executesql @sql

SET @sql = N'CREATE TABLE dbo.' + dbo.sys_get_arc_table_name ('VAL_RATES',@year) + '(
	ISO TISO NOT NULL,
	DT smalldatetime NOT NULL,
	ITEMS int NOT NULL,
	AMOUNT money NOT NULL)'

IF @year <> 0
  SET @sql = @sql + ' ON [ARCHIVE]'

EXEC sp_executesql @sql

SET @sql = N'ALTER TABLE dbo.' + dbo.sys_get_arc_table_name ('VAL_RATES',@year) + N' ADD CONSTRAINT PK_' + dbo.sys_get_arc_table_name ('VAL_RATES',@year) + N' PRIMARY KEY CLUSTERED (ISO,DT)'

EXEC sp_executesql @sql

SET @sql = N'ALTER TABLE dbo.' + dbo.sys_get_arc_table_name ('VAL_RATES',@year) + N' WITH CHECK ADD CONSTRAINT CK_' + dbo.sys_get_arc_table_name ('VAL_RATES',@year) + N' '

DECLARE 
  @max_date smalldatetime,
  @dt smalldatetime,
  @max_s nvarchar(10)

SET @dt = dbo.bank_open_date()
IF YEAR(@dt) = @year OR @year = 0
  SET @max_s = dbo.sys_get_date_str(@dt)
ELSE 
  SET @max_s = @s1 + '0101'

SET @max_s = '''' + @max_s + ''''

IF @year = 0
  SET @sql = @sql + N'CHECK (DT >= ' + @max_s + N')'
ELSE
IF @is_first = 1
  SET @sql = @sql + N'CHECK (DT < ' + @max_s + N')'
ELSE
  SET @sql = @sql + N'CHECK (DT >= ''' + @s + '0101'' AND DT < ' + @max_s + N')'

EXEC sp_executesql @sql
GO
