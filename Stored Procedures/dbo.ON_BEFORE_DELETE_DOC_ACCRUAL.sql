SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[ON_BEFORE_DELETE_DOC_ACCRUAL]
  @rec_id int,					-- საბუთის შიდა №
  @user_id int,					-- ვინ შლის საბუთს
  
-- სხვა პარამეტრები

  @check_saldo bit = 1,		-- შეამოწმოს თუ არა მინ. ნაშთი
  @info bit = 0,			-- რეალურად გატარდეს, თუ მხოლოდ ინფორმაციაა
  @lat bit = 0				-- გამოიტანოს თუ არა შეცდომები ინგლისურად
AS

SET NOCOUNT ON

DECLARE 
	@is_debit bit,
	@acc_id int,
	@amount2 money,
	@amount2_equ money,
	@amount4 money,
	@accr_date smalldatetime,
	@doc_type smallint,
	@op_code TOPCODE,
	@prev_calc_date smalldatetime

SELECT @amount2 = AMOUNT, @amount2_equ = AMOUNT_EQU, @accr_date = DOC_DATE_IN_DOC, @doc_type = DOC_TYPE, @op_code = OP_CODE
FROM dbo.OPS_0000
WHERE REC_ID = @rec_id

SELECT @acc_id = ACC_ID, @amount4 = AMOUNT4, @prev_calc_date = PREV_DATE
FROM dbo.DOC_DETAILS_PERC
WHERE DOC_REC_ID = @rec_id

IF EXISTS(SELECT * FROM dbo.DOC_DETAILS_PERC WHERE ACC_ID = @acc_id AND ACCR_DATE > @accr_date)
BEGIN
	RAISERROR('<ERR>ÀÌ ÃÀÒÉÝáÅÉÓ ÓÀÁÖÈÉÓ ßÀÛËÀ ÀÒ ÛÄÉÞËÄÁÀ, ÒÀÃÂÀÍ ÀÌ ÀÍÂÀÒÉÛÆÄ ÌÏáÃÀ ÃÀÒÉÝáÅÀ ÛÄÌÃÄÂÉ ÈÀÒÉÙÄÁÉÈ</ERR>', 16, 1)
	RETURN 1
END

IF @amount4 IS NULL
	SET @amount4 = $0.00
	
IF @amount4 < $0.00
BEGIN
	SET @amount2 = -@amount2
	SET @amount2_equ = -@amount2_equ
END	

DELETE FROM dbo.DOC_DETAILS_PERC
WHERE DOC_REC_ID = @rec_id

SET @is_debit = CASE WHEN @doc_type = 30 THEN 0 ELSE 1 END

IF @op_code = '*%AC*'	-- Accrual
BEGIN
	IF @is_debit = 1
		UPDATE dbo.ACCOUNTS_DEB_PERC
		SET LAST_CALC_DATE = @prev_calc_date, CALC_AMOUNT = ISNULL(CALC_AMOUNT, $0.0000) - @amount4, TOTAL_CALC_AMOUNT = ISNULL(TOTAL_CALC_AMOUNT, $0.0000) - @amount2
		WHERE ACC_ID = @acc_id
	ELSE
		UPDATE dbo.ACCOUNTS_CRED_PERC
		SET LAST_CALC_DATE = @prev_calc_date, CALC_AMOUNT = ISNULL(CALC_AMOUNT, $0.0000) - @amount4, TOTAL_CALC_AMOUNT = ISNULL(TOTAL_CALC_AMOUNT, $0.0000) - @amount2
		WHERE ACC_ID = @acc_id
END
ELSE
IF @op_code = '*%RL*'	-- Realization
BEGIN
	IF @is_debit = 1
		UPDATE dbo.ACCOUNTS_DEB_PERC
		SET LAST_MOVE_DATE = @prev_calc_date, TOTAL_PAYED_AMOUNT = ISNULL(TOTAL_PAYED_AMOUNT, $0.0000) - @amount2, CALC_AMOUNT = ISNULL(CALC_AMOUNT, $0.0000) + @amount4
		WHERE ACC_ID = @acc_id
	ELSE
		UPDATE dbo.ACCOUNTS_CRED_PERC
		SET LAST_MOVE_DATE = @prev_calc_date, TOTAL_PAYED_AMOUNT = ISNULL(TOTAL_PAYED_AMOUNT, $0.0000) - @amount2, CALC_AMOUNT = ISNULL(CALC_AMOUNT, $0.0000) + @amount4 
		WHERE ACC_ID = @acc_id
END
ELSE
IF @op_code = '*%TX*'	-- Realization Tax
BEGIN
	IF @is_debit = 0
		UPDATE dbo.ACCOUNTS_CRED_PERC
		SET TOTAL_TAX_PAYED_AMOUNT = ISNULL(TOTAL_TAX_PAYED_AMOUNT, $0.0000) - @amount2,
			TOTAL_TAX_PAYED_AMOUNT_EQU = ISNULL(TOTAL_TAX_PAYED_AMOUNT_EQU, $0.0000) - @amount2_equ
		WHERE ACC_ID = @acc_id
END

RETURN @@ERROR
GO
