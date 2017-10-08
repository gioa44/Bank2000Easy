SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[GET_BAL_ACC_INFO]
	@big_bal_acc 	TBAL_ACC,
        @alternate 	bit,
	@rec_state	tinyint OUTPUT,
	@act_pas	tinyint OUTPUT,
	@class_type	tinyint OUTPUT,
	@val_type	tinyint OUTPUT
AS


SET NOCOUNT ON

IF @alternate = 0
BEGIN
  SELECT @rec_state  = REC_STATE,
	 @act_pas    = ACT_PAS,
	 @class_type = CLASS_TYPE,
	 @val_type   = VAL_TYPE
  FROM   PLANLIST (NOLOCK)
  WHERE  BAL_ACC = @big_bal_acc
END
ELSE

BEGIN
  SELECT @rec_state  = REC_STATE,
	 @act_pas    = ACT_PAS,
	 @class_type = CLASS_TYPE,
	 @val_type   = VAL_TYPE
  FROM   PLANLIST_ALT (NOLOCK)
  WHERE  BAL_ACC = @big_bal_acc
END

IF (@act_pas IS NULL ) RETURN (1)
RETURN (0)


GO
