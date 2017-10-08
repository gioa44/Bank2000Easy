SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[GET_ACC_SHADOW]
  @acc_id int,
  @dt smalldatetime,
  @saldo money OUTPUT,
  @act_pas tinyint OUTPUT,
  @shadow_dbo money OUTPUT,
  @shadow_cro money OUTPUT,
  @descrip_geo varchar(100) OUTPUT,
  @descrip_lat varchar(100) OUTPUT,
  @last_op_date smalldatetime OUTPUT,
  @shadow_level	smallint = -1AS

SET NOCOUNT ON

DECLARE @open_dt smalldatetime

IF @shadow_level >= 0 
BEGIN
  SET @open_dt = dbo.bank_open_date()
  IF @dt < @open_dt
    SET @shadow_level = -1
END

SELECT @act_pas = NULL, @descrip_geo = NULL, @descrip_lat = NULL, @saldo = NULL, @shadow_dbo = 0, @shadow_cro = 0

SELECT @act_pas = ACT_PAS, @descrip_geo = DESCRIP, @descrip_lat = DESCRIP_LAT
FROM dbo.ACCOUNTS(NOLOCK)
WHERE ACC_ID = @acc_id
IF @@ROWCOUNT = 0 RETURN (1)SELECT TOP 1 @saldo = SALDO, @last_op_date = DTFROM dbo.SALDOS(NOLOCK)
WHERE ACC_ID = @acc_id AND DT <= @dt
ORDER BY DT DESC

SET @saldo = ISNULL(@saldo, $0.0000)

IF @shadow_level >= 0
BEGIN
  DECLARE
    @rec_state 	smallint

  IF @shadow_level <= 0
    SET @rec_state = 0
  ELSE
  IF @shadow_level = 1
    SET @rec_state = 10
  ELSE
  IF @shadow_level >= 2
    SET @rec_state = 20

  SELECT  @shadow_dbo = SUM(CASE @acc_id WHEN D.DEBIT_ID THEN D.AMOUNT ELSE 0 END),
          @shadow_cro = SUM(CASE @acc_id WHEN D.CREDIT_ID THEN D.AMOUNT ELSE 0 END)
  FROM dbo.OPS_HELPER_0000 S(NOLOCK) 
    INNER JOIN dbo.OPS_0000 D(NOLOCK) ON D.REC_ID = S.REC_ID
  WHERE S.ACC_ID = @acc_id AND S.DT <= @dt AND D.REC_STATE >= @rec_state
END
RETURN (0)
GO
