SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/* Calculates saldo of 1 account AT THE END of date @dt */
/* OBSOLETE: Use acc_get_balance  */
CREATE PROCEDURE [dbo].[GET_ACC_SALDO]
  @account TACCOUNT,
  @iso TISO,
  @dt smalldatetime,
  @shadow_level	smallint = -1,
  @saldo money OUTPUT,
  @saldo_equ money OUTPUT,
  @act_pas tinyint OUTPUT,
  @descrip_geo varchar(100) OUTPUT,
  @descrip_lat varchar(100) OUTPUT
AS

SET NOCOUNT ON
SET @saldo = 0
SET @saldo_equ = 0

DECLARE
  @open_dt smalldatetime

IF @shadow_level >= 0 
BEGIN
  IF @dt < dbo.bank_open_date()
    SET @shadow_level = -1
END

DECLARE @acc_id int

SELECT @acc_id = ACC_ID, @act_pas = ACT_PAS, @descrip_geo = DESCRIP, @descrip_lat = DESCRIP_LAT
FROM dbo.ACCOUNTS(NOLOCK)
WHERE ACCOUNT = @account AND ISO = @iso
IF @@ROWCOUNT = 0 RETURN (1)

SELECT @saldo = BALANCE, @saldo_equ = BALANCE_EQU
FROM dbo.acc_get_balance2 (@acc_id, @dt, 0, @shadow_level)

SET @saldo = ISNULL(@saldo,$0)
SET @saldo_equ = ISNULL(@saldo_equ,$0)

RETURN (0)
GO
