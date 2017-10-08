SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[CLOSE_JAN_01]
AS

SET NOCOUNT ON;

DECLARE
  @sql nvarchar(4000),
  @date smalldatetime,
  @r int

SET @date = dbo.bank_open_date ()

DECLARE @msg nvarchar(255)
SET @msg =  'CLOSING JAN 01 ' + CONVERT(varchar(4),YEAR(@date))
PRINT @msg

IF DAY(@date + 1) <> 2 OR MONTH(@date + 1) <> 1
BEGIN
  SET @msg = CONVERT(varchar(20), @date, 103)
  RAISERROR ('<ERR>Cannot close year. %s is not JAN 01</ERR>', 16, 1, @msg)
  RETURN(-1009)
END

DECLARE @year int
SET @year = YEAR(@date)

SET @sql = N'
INSERT INTO dbo.' + dbo.sys_get_arc_table_name('VAL_RATES',@year) + N'
SELECT R.ISO, @date, R.ITEMS, R.AMOUNT
FROM dbo.VAL_RATES R
WHERE R.DT = (SELECT MAX(R2.DT) FROM dbo.VAL_RATES R2 WHERE R2.ISO = R.ISO AND R2.DT <= @date) 
	AND NOT EXISTS(SELECT * FROM dbo.' + dbo.sys_get_arc_table_name('VAL_RATES',@year) + N' R3 WHERE R3.ISO = R.ISO)'

EXEC sp_executesql @sql, N'@date smalldatetime', @date

SET @sql = N'
INSERT INTO dbo.' + dbo.sys_get_arc_table_name('SALDOS',@year) + N'
SELECT R.ACC_ID, @date, $0.00, $0.00, R.SALDO
FROM dbo.SALDOS R
WHERE R.DT = (SELECT MAX(R2.DT) FROM dbo.SALDOS R2 WHERE R2.ACC_ID = R.ACC_ID AND R2.DT <= @date) 
	AND R.SALDO <> $0.00 AND NOT EXISTS(SELECT * FROM dbo.' + dbo.sys_get_arc_table_name('SALDOS',@year) + N' R3 WHERE R3.ACC_ID = R.ACC_ID)'

EXEC sp_executesql @sql, N'@date smalldatetime', @date
GO
