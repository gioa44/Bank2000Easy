SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[ON_BEFORE_DELETE_DOC_LOAN_OPS]
  @rec_id int,					-- ÓÀÁÖÈÉÓ ÛÉÃÀ #
  @user_id int,					-- ÅÉÍ ÛËÉÓ ÓÀÁÖÈÓ
  
-- ÓáÅÀ ÐÀÒÀÌÄÔÒÄÁÉ

  @check_saldo bit = 1,		-- ÛÄÀÌÏßÌÏÓ ÈÖ ÀÒÀ ÌÉÍ. ÍÀÛÈÉ
  @info bit = 0,			-- ÒÄÀËÖÒÀÃ ÂÀÔÀÒÃÄÓ ÈÖ ÌáÏËÏÃ ÉÍÌ×ÏÒÌÀÝÉÀ
  @lat bit = 0				-- ÂÀÌÏÉÔÀÍÏÓ ÈÖ ÀÒÀ ÉÍÂËÉÓÖÒÀÃ ÛÄÝÃÏÌÄÁÉ
AS

SET NOCOUNT ON

DECLARE 
	@loan_id int,
	@amount money,
	@accr_date smalldatetime,
	@doc_type smallint,
	@type_id int,
	@op_code TOPCODE,
	@prev_calc_date smalldatetime

SELECT @loan_id = convert(int, ACCOUNT_EXTRA), @accr_date = DOC_DATE_IN_DOC, @doc_type = DOC_TYPE, @amount = AMOUNT, @op_code = OP_CODE, @prev_calc_date = CONVERT(smalldatetime, FOREIGN_ID), @type_id = BNK_CLI_ID
FROM dbo.OPS_0000
WHERE REC_ID = @rec_id


UPDATE dbo.LOAN_ACCOUNT_BALANCE
SET
	ACC_0301_DATE = CASE ABS(@type_id) WHEN 10 THEN @prev_calc_date ELSE ACC_0301_DATE END,
	ACC_0301_BALANCE = CASE ABS(@type_id) WHEN 10 THEN ISNULL(ACC_0301_BALANCE, $0.00) + (SIGN(@type_id) * -@amount) ELSE ACC_0301_BALANCE END,

	PRINCIPAL_BALANCE = CASE ABS(@type_id)
		WHEN 30 THEN ISNULL(PRINCIPAL_BALANCE, $0.00) + (SIGN(@type_id) * -@amount)
		WHEN 40 THEN ISNULL(PRINCIPAL_BALANCE, $0.00) + (SIGN(@type_id) * @amount)
		WHEN 50 THEN ISNULL(PRINCIPAL_BALANCE, $0.00) + (SIGN(@type_id) * @amount)
		ELSE PRINCIPAL_BALANCE END,
	OVERDUE_PRINCIPAL_BALANCE = CASE ABS(@type_id)
		WHEN 40 THEN ISNULL(OVERDUE_PRINCIPAL_BALANCE, $0.00) + (SIGN(@type_id) * -@amount)
		WHEN 51 THEN ISNULL(OVERDUE_PRINCIPAL_BALANCE, $0.00) + (SIGN(@type_id) * @amount)	
		ELSE OVERDUE_PRINCIPAL_BALANCE END,

	--WRITEOFF_PRINCIPAL_BALANCE = CASE WHEN ABS(@type_id) IN (50, 51) THEN ISNULL(WRITEOFF_BALANCE, $0.00) + (SIGN(@type_id) * -@amount) ELSE WRITEOFF_BALANCE END,


	INTEREST_DATE = CASE ABS(@type_id) WHEN 1030 THEN @prev_calc_date ELSE INTEREST_DATE END,
	INTEREST_BALANCE = CASE ABS(@type_id) WHEN 1030 THEN ISNULL(INTEREST_BALANCE, $0.00) + (SIGN(@type_id) * -@amount) ELSE INTEREST_BALANCE END,
	
	OVERDUE_INTEREST_DATE = CASE ABS(@type_id) WHEN 1160 THEN @prev_calc_date ELSE OVERDUE_INTEREST_DATE END,
	OVERDUE_INTEREST_BALANCE = CASE ABS(@type_id) WHEN 1160 THEN ISNULL(OVERDUE_INTEREST_BALANCE, $0.00) + (SIGN(@type_id) * -@amount) ELSE OVERDUE_INTEREST_BALANCE END,

	OVERDUE_INTEREST30_DATE = CASE ABS(@type_id) WHEN 2060 THEN @prev_calc_date ELSE OVERDUE_INTEREST30_DATE END,
	OVERDUE_INTEREST30_BALANCE = CASE ABS(@type_id) WHEN 2060 THEN ISNULL(OVERDUE_INTEREST30_BALANCE, $0.00) + (SIGN(@type_id) * -@amount) ELSE OVERDUE_INTEREST30_BALANCE END,
	
	PENALTY_DATE = CASE ABS(@type_id) WHEN 2000 THEN @prev_calc_date ELSE PENALTY_DATE END,
	PENALTY_BALANCE = CASE ABS(@type_id) WHEN 2000 THEN ISNULL(PENALTY_BALANCE, $0.00) + (SIGN(@type_id) * -@amount) ELSE PENALTY_BALANCE END,

	--WRITEOFF_DATE  = CASE ABS(@type_id) WHEN 70 THEN @prev_calc_date ELSE WRITEOFF_DATE END,
	--WRITEOFF_BALANCE = CASE ABS(@type_id) WHEN 70 THEN ISNULL(WRITEOFF_BALANCE, $0.00) + (SIGN(@type_id) * -@amount) ELSE WRITEOFF_BALANCE END,


	ADMIN_FEE_DATE = CASE ABS(@type_id) WHEN 1000 THEN @prev_calc_date ELSE ADMIN_FEE_DATE END,
	ADMIN_FEE_BALANCE = CASE ABS(@type_id) WHEN 1000 THEN ISNULL(ADMIN_FEE_BALANCE, $0.00) + (SIGN(@type_id) * -@amount) ELSE ADMIN_FEE_BALANCE END
WHERE LOAN_ID = @loan_id
IF @@ERROR<>0 OR @@ROWCOUNT <> 1 BEGIN RAISERROR('ÛÄÝÃÏÌÀ ÓÀÓÄÓáÏ ÍÀÛÈÉÓ ÝÅËÉËÄÁÉÓÀÓ!!!', 16, 1) RETURN (1) END
  
RETURN 0

GO
