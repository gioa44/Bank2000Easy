SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[get_bal_acc_info_n]
	@big_bal_acc TBAL_ACC,
	@chart_no	integer = 0,	@rec_state	tinyint OUTPUT,
	@act_pas	tinyint OUTPUT,
	@class_type	tinyint OUTPUT,
	@val_type	tinyint OUTPUT
AS
SET NOCOUNT ON;

IF @chart_no = 0
BEGIN
  SELECT @rec_state = REC_STATE, @act_pas = ACT_PAS, @class_type = CLASS_TYPE, @val_type = VAL_TYPE
  FROM dbo.PLANLIST_ALT (NOLOCK)
  WHERE BAL_ACC = @big_bal_acc
END
ELSEIF @chart_no = 1
BEGIN
  SELECT @rec_state = REC_STATE, @act_pas = ACT_PAS, @class_type = CLASS_TYPE, @val_type = VAL_TYPE
  FROM dbo.PLANLIST (NOLOCK)
  WHERE BAL_ACC = @big_bal_acc
END
ELSEIF @chart_no = 2
BEGIN
  SELECT @rec_state = REC_STATE, @act_pas = ACT_PAS, @class_type = CLASS_TYPE, @val_type = VAL_TYPE
  FROM dbo.PLANLIST2 (NOLOCK)
  WHERE BAL_ACC = @big_bal_acc
END
ELSEIF @chart_no = 3
BEGIN
  SELECT @rec_state = REC_STATE, @act_pas = ACT_PAS, @class_type = CLASS_TYPE, @val_type = VAL_TYPE
  FROM dbo.PLANLIST3 (NOLOCK)
  WHERE BAL_ACC = @big_bal_acc
END

IF @act_pas IS NULL
	RETURN (1)
RETURN (0)
GO
