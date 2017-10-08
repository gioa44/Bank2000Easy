SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[get_bal_acc_name_n]
	@big_bal_acc TBAL_ACC,
	@chart_no	integer = 0,
	@is_lat bit = 0,
	@bal_acc_name varchar(100) OUTPUTAS
SET NOCOUNT ON;

IF @chart_no = 0
BEGIN
  SELECT @bal_acc_name = CASE WHEN @is_lat = 0 THEN DESCRIP ELSE DESCRIP_LAT END
  FROM dbo.PLANLIST_ALT (NOLOCK)
  WHERE BAL_ACC = @big_bal_acc
END
ELSEIF @chart_no = 1
BEGIN
  SELECT @bal_acc_name = CASE WHEN @is_lat = 0 THEN DESCRIP ELSE DESCRIP_LAT END
  FROM dbo.PLANLIST (NOLOCK)
  WHERE BAL_ACC = @big_bal_acc
END
ELSEIF @chart_no = 2
BEGIN
  SELECT @bal_acc_name = CASE WHEN @is_lat = 0 THEN DESCRIP ELSE DESCRIP_LAT END
  FROM dbo.PLANLIST2 (NOLOCK)
  WHERE BAL_ACC = @big_bal_acc
END
ELSEIF @chart_no = 3
BEGIN
  SELECT @bal_acc_name = CASE WHEN @is_lat = 0 THEN DESCRIP ELSE DESCRIP_LAT END
  FROM dbo.PLANLIST3 (NOLOCK)
  WHERE BAL_ACC = @big_bal_acc
END

RETURN (0)
GO
