SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[ON_BEFORE_DELETE_DOC_LOAN_ACCRUAL]
  @rec_id int,					-- ÓÀÁÖÈÉÓ ÛÉÃÀ #
  @user_id int,					-- ÅÉÍ ÛËÉÓ ÓÀÁÖÈÓ
  
-- ÓáÅÀ ÐÀÒÀÌÄÔÒÄÁÉ

  @check_saldo bit = 1,		-- ÛÄÀÌÏßÌÏÓ ÈÖ ÀÒÀ ÌÉÍ. ÍÀÛÈÉ
  @info bit = 0,			-- ÒÄÀËÖÒÀÃ ÂÀÔÀÒÃÄÓ ÈÖ ÌáÏËÏÃ ÉÍÌ×ÏÒÌÀÝÉÀ
  @lat bit = 0				-- ÂÀÌÏÉÔÀÍÏÓ ÈÖ ÀÒÀ ÉÍÂËÉÓÖÒÀÃ ÛÄÝÃÏÌÄÁÉ
AS

SET NOCOUNT ON

DECLARE 
	@parent_rec_id int,
	@loan_id int,
	@amount money,
	@accr_date smalldatetime,
	@doc_type smallint,
	@type_id int,
	@op_code TOPCODE,
	@prev_calc_date smalldatetime

SELECT @loan_id = convert(int, ACCOUNT_EXTRA), @accr_date = DOC_DATE_IN_DOC, @doc_type = DOC_TYPE, @amount = AMOUNT, @op_code = OP_CODE, @prev_calc_date = CONVERT(smalldatetime, FOREIGN_ID), @type_id = BNK_CLI_ID, @parent_rec_id = PARENT_REC_ID
FROM dbo.OPS_0000
WHERE REC_ID = @rec_id

IF ISNULL(@parent_rec_id, 0) > 0
	SET @rec_id = @parent_rec_id
	 
IF ISNULL(@type_id, 0) = 0
	RETURN (0)


IF EXISTS(SELECT * FROM dbo.OPS_0000 WHERE ACCOUNT_EXTRA = @loan_id AND (DOC_DATE > @accr_date OR (DOC_DATE = @accr_date AND REC_ID > @rec_id AND ISNULL(PARENT_REC_ID, 0) <> @rec_id)))
BEGIN
	RAISERROR('<ERR>ÀÌ ÃÀÒÉÝáÅÉÓ ÓÀÁÖÈÉÓ ßÀÛËÀ ÀÒ ÛÄÉÞËÄÁÀ, ÒÀÃÂÀÍ ÀÌ ÏÐÄÒÀÝÉÉÓ ÛÄÌÃÄÂ ÓÄÓáÆÄ ÌÏáÃÀ ÓáÅÀ ÏÐÄÒÀÝÉÀ</ERR>', 16, 1)
	RETURN 1
END


DECLARE
	@sign money

SET @sign = SIGN(@type_id)
SET @type_id = ABS(@type_id)

UPDATE dbo.LOAN_ACCOUNT_BALANCE
SET
	INTEREST_DATE = CASE @type_id WHEN 1030 THEN @prev_calc_date ELSE INTEREST_DATE END,
	INTEREST_BALANCE = CASE @type_id WHEN 1030 THEN ISNULL(INTEREST_BALANCE, $0.00) + (@sign * -@amount) ELSE INTEREST_BALANCE END,
	
	OVERDUE_INTEREST_DATE = CASE @type_id WHEN 1160 THEN @prev_calc_date ELSE OVERDUE_INTEREST_DATE END,
	OVERDUE_INTEREST_BALANCE = CASE @type_id WHEN 1160 THEN ISNULL(OVERDUE_INTEREST_BALANCE, $0.00) + (@sign * -@amount) ELSE OVERDUE_INTEREST_BALANCE END,

	OVERDUE_INTEREST30_DATE = CASE @type_id WHEN 2060 THEN @prev_calc_date ELSE OVERDUE_INTEREST30_DATE END,
	OVERDUE_INTEREST30_BALANCE = CASE @type_id WHEN 2060 THEN ISNULL(OVERDUE_INTEREST30_BALANCE, $0.00) + (@sign * -@amount) ELSE OVERDUE_INTEREST30_BALANCE END,
	
	PENALTY_DATE = CASE @type_id WHEN 2000 THEN @prev_calc_date ELSE PENALTY_DATE END,
	PENALTY_BALANCE = CASE @type_id WHEN 2000 THEN ISNULL(PENALTY_BALANCE, $0.00) + (@sign * -@amount) ELSE PENALTY_BALANCE END,


	RISK_CATEGORY_DATE = CASE WHEN @type_id IN (8000, 8010, 8020, 8030, 8040, 8050)  THEN @prev_calc_date ELSE RISK_CATEGORY_DATE END,
	RISK_CATEGORY_BALANCE = CASE WHEN @type_id IN (8000, 8010, 8020, 8030, 8040, 8050) THEN CASE WHEN @type_id = 8000 THEN ISNULL(RISK_CATEGORY_BALANCE, $0.00) + (@sign * -@amount) ELSE NULL END ELSE RISK_CATEGORY_BALANCE END,
	RISK_CATEGORY_1_BALANCE = CASE WHEN @type_id IN (8000, 8010, 8020, 8030, 8040, 8050) THEN CASE WHEN @type_id = 8010 THEN ISNULL(RISK_CATEGORY_1_BALANCE, $0.00) + (@sign * -@amount) ELSE CASE WHEN @type_id = 8000 THEN NULL ELSE RISK_CATEGORY_1_BALANCE END END ELSE RISK_CATEGORY_1_BALANCE END,
	RISK_CATEGORY_2_BALANCE = CASE WHEN @type_id IN (8000, 8010, 8020, 8030, 8040, 8050) THEN CASE WHEN @type_id = 8020 THEN ISNULL(RISK_CATEGORY_2_BALANCE, $0.00) + (@sign * -@amount) ELSE CASE WHEN @type_id = 8000 THEN NULL ELSE RISK_CATEGORY_2_BALANCE END  END ELSE RISK_CATEGORY_2_BALANCE END,
	RISK_CATEGORY_3_BALANCE = CASE WHEN @type_id IN (8000, 8010, 8020, 8030, 8040, 8050) THEN CASE WHEN @type_id = 8030 THEN ISNULL(RISK_CATEGORY_3_BALANCE, $0.00) + (@sign * -@amount) ELSE CASE WHEN @type_id = 8000 THEN NULL ELSE RISK_CATEGORY_3_BALANCE END  END ELSE RISK_CATEGORY_3_BALANCE END,
	RISK_CATEGORY_4_BALANCE = CASE WHEN @type_id IN (8000, 8010, 8020, 8030, 8040, 8050) THEN CASE WHEN @type_id = 8040 THEN ISNULL(RISK_CATEGORY_4_BALANCE, $0.00) + (@sign * -@amount) ELSE CASE WHEN @type_id = 8000 THEN NULL ELSE RISK_CATEGORY_4_BALANCE END  END ELSE RISK_CATEGORY_4_BALANCE END,
	RISK_CATEGORY_5_BALANCE = CASE WHEN @type_id IN (8000, 8010, 8020, 8030, 8040, 8050) THEN CASE WHEN @type_id = 8050 THEN ISNULL(RISK_CATEGORY_5_BALANCE, $0.00) + (@sign * -@amount) ELSE CASE WHEN @type_id = 8000 THEN NULL ELSE RISK_CATEGORY_5_BALANCE END  END ELSE RISK_CATEGORY_5_BALANCE END
WHERE LOAN_ID = @loan_id
IF @@ERROR<>0 OR @@ROWCOUNT <> 1 BEGIN RAISERROR('ÛÄÝÃÏÌÀ ÓÀÓÄÓáÏ ÍÀÛÈÉÓ ÝÅËÉËÄÁÉÓÀÓ!!!', 16, 1) RETURN (1) END
  
RETURN 0

GO