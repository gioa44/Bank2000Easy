SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[ON_BEFORE_DELETE_DOC_UP] 
  @rec_id int,					-- საბუთის შიდა №
  @user_id int,					-- ვინ შლის საბუთს
  
-- სხვა პარამეტრები

  @check_saldo bit = 1,		-- შეამოწმოს თუ არა მინ. ნაშთი
  @dont_check_up bit = 0,	-- შეამოწმოს თუ არა კომ. გადასახადები
  @info bit = 0,			-- რეალურად გატარდეს, თუ მხოლოდ ინფორმაციაა
  @lat bit = 0				-- გამოიტანოს თუ არა შეცდომები ინგლისურად
AS

SET NOCOUNT ON

DECLARE
	@foreign_id int

SELECT @foreign_id = FOREIGN_ID
FROM dbo.OPS_0000
WHERE REC_ID = @rec_id

IF @dont_check_up = 0 AND @foreign_id > 0	-- Utility Payment
BEGIN
	IF @lat = 0 
		RAISERROR ('<ERR>ÀÒ ÛÄÉÞËÄÁÀ ÀÌ ÓÀÁÖÈÉÓ ßÀÛËÀ. (ÊÏÌÖÍÀËÖÒÉ ÂÀÃÀÓÀáÀÃÄÁÉ)</ERR>',16,1)
	ELSE RAISERROR ('<ERR>Cannot delete this document (Utility payments)</ERR>',16,1)
	RETURN 1
END

IF @foreign_id = 0
BEGIN
	DELETE FROM dbo.PENDING_PAYMENTS
	WHERE DOC_REC_ID = @rec_id
	IF @@ERROR <> 0 RETURN 1
END
GO
