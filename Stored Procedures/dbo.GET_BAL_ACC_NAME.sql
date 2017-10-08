SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[GET_BAL_ACC_NAME]
  @big_bal_acc 	TBAL_ACC,
  @alternate bit = 1,
  @is_lat bit = 0,
  @bal_acc_name varchar(100) OUTPUTAS

SET NOCOUNT ON

IF @alternate = 0
BEGIN
  SELECT @bal_acc_name = CASE WHEN @is_lat = 0 THEN DESCRIP ELSE DESCRIP_LAT END
  FROM   dbo.PLANLIST (NOLOCK)
  WHERE  BAL_ACC = @big_bal_acc
END
ELSE
BEGIN
  SELECT @bal_acc_name = CASE WHEN @is_lat = 0 THEN DESCRIP ELSE DESCRIP_LAT END
  FROM   dbo.PLANLIST_ALT (NOLOCK)
  WHERE  BAL_ACC = @big_bal_acc
END

RETURN (0)
GO
