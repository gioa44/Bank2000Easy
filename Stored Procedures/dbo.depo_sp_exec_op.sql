SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[depo_sp_exec_op]
	@doc_rec_id int OUTPUT,
	@accrue_doc_rec_id int OUTPUT,
	@op_id int,
	@user_id int
AS

SET NOCOUNT ON;

DECLARE 
	@r int

DECLARE @internal_transaction bit
SET @internal_transaction = 0
IF @@TRANCOUNT = 0
BEGIN
	BEGIN TRAN
	SET @internal_transaction = 1
END

DECLARE
	@rec_id int

DECLARE
	@depo_id int,
	@op_date smalldatetime,
	@op_amount money,
	@op_iso char(3),
	@op_type smallint,
	@op_state bit,
	@op_data xml,
	@op_acc_data xml,
	@recalculate_schedule bit

DECLARE
	@new_start_date smalldatetime,
	@new_end_date smalldatetime,
	@min_amount_check_date smalldatetime,
	@acc_client_no int,
	@change_intrate bit


SELECT @depo_id = DEPO_ID, @op_date = OP_DATE, @op_type = OP_TYPE, @op_state = OP_STATE, @op_amount = AMOUNT, @op_iso = ISO, @op_data = OP_DATA, @doc_rec_id = DOC_REC_ID, @accrue_doc_rec_id = ACCRUE_DOC_REC_ID
FROM dbo.DEPO_OP
WHERE OP_ID = @op_id
IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR('<ERR>OPERATION NOT FOUND</ERR>', 16, 1); RETURN (1); END

IF @op_state = 1
  BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ÏÐÄÒÀÝÉÀ ÖÊÅÄ ÛÄÓÒÖËÄÁÖËÉÀ, ÂÀÍÀÀáËÄÈ ÌÏÍÀÝÄÌÄÁÉ!</ERR>', 16, 1); RETURN (1); END
  
DECLARE
	@doc_rec_state tinyint,
	@doc_type smallint,
	@accrue_before_exec bit,
	@realize_before_exec bit,
	@op_exec_doc_rec_state tinyint,
	@op_exec_doc_rec_state_cash tinyint

SELECT @accrue_before_exec = ACCRUE_BEFORE_EXEC, @realize_before_exec = REALIZE_BEFORE_EXEC, @op_exec_doc_rec_state = EXEC_DOC_REC_STATE, @op_exec_doc_rec_state_cash = EXEC_DOC_REC_STATE_CASH
FROM dbo.DEPO_OP_TYPES (NOLOCK)
WHERE [TYPE_ID] = @op_type
IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR('<ERR>OPERATION TYPE SETTINGS NOT FOUND</ERR>', 16, 1); RETURN (1); END


IF @doc_rec_id IS NOT NULL
BEGIN
	SELECT @doc_type = DOC_TYPE, @doc_rec_state = REC_STATE
	FROM dbo.OPS_0000 (NOLOCK)
	WHERE REC_ID = @doc_rec_id
	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR('<ERR>ERROR READING DOC DATA</ERR>', 16, 1); RETURN (1); END

	IF @doc_rec_state IS NOT NULL
	BEGIN
		IF @doc_type = 120 --Cash Order
			SET @op_exec_doc_rec_state = @op_exec_doc_rec_state_cash

		IF @doc_rec_state < @op_exec_doc_rec_state
		BEGIN
			IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK;
			RAISERROR ('<ERR>ÏÐÄÒÀÝÉÀÓÈÀÍ ÃÀÊÀÅÛÉÒÄÁÖËÉ ÓÀÁÖÈÄÁÉÓ ÀÅÔÏÒÉÆÀÝÉÉÓ ÃÀÁÀËÉ ÃÏÍÄ, ÓÀàÉÒÏÀ ÓÀÁÖÈÄÁÉÓ ÀÅÔÏÒÉÆÀÝÉÀ!</ERR>', 16, 1)
			RETURN (1)
		END
	END
END

DECLARE
	@dept_no int,
	@client_no int,
	@iso char(3),
	@amount money,
	@depo_type tinyint,
	@start_date smalldatetime,
	@end_date smalldatetime,
	@days_in_year smallint,
	@perc_flags int,
	@realize_type tinyint,
	@realize_count smallint,
	@realize_count_type tinyint,
	@accrue_type tinyint,
	@recalculate_type tinyint,
	@formula varchar(255),
	@spend_const_amount money,
	@spend_amount money,
	@depo_account_state tinyint,
	@prod_id int


DECLARE
	@depo_realize_amount money,
	@interest_realize_amount money,
	@interest_realize_adv_amount money

DECLARE
	@depo_acc_id int,
	@accrual_acc_id int,
	@loss_acc_id int,
	@depo_realize_acc_id int,
	@interest_realize_acc_id int,
	@interest_realize_adv_acc_id int

DECLARE
	@acc_rec_state tinyint,
	@depo_bal_acc TBAL_ACC

DECLARE
	@interest_realize_adv bit,
	@accumulative bit,
	@accumulate_schema_intrate tinyint,
	@date_type int

DECLARE
	@intrate money,
	@real_intrate money

DECLARE
	@acc_min_amount money,
	@acc_min_amount2 money,

	@change_formula bit,
	@new_formula varchar(255)
	
DECLARE -- common variables
	@prolongable bit,
	@prolongation_count int,
	@renewable bit,
	@renew_capitalized bit,
	@renew_count int,
	@renew_max int,
	@renew_last_prod_id int,
	@last_renew_date smalldatetime

SELECT @dept_no = DEPT_NO, @client_no = CLIENT_NO, @depo_type = DEPO_TYPE, @iso = ISO, @amount = AMOUNT, @start_date = [START_DATE], @end_date = END_DATE, @days_in_year = DAYS_IN_YEAR, @perc_flags = PERC_FLAGS,
	@realize_type = REALIZE_TYPE, @realize_count = REALIZE_COUNT, @realize_count_type = REALIZE_COUNT_TYPE,	@accrue_type = ACCRUE_TYPE,	@recalculate_type = RECALCULATE_TYPE, @date_type = DATE_TYPE,
	@formula = FORMULA, @interest_realize_adv = INTEREST_REALIZE_ADV,
	@spend_amount = SPEND_AMOUNT, @spend_const_amount = SPEND_CONST_AMOUNT,
	@depo_realize_amount = DEPO_REALIZE_SCHEMA_AMOUNT,	@interest_realize_amount = NULL, @interest_realize_adv_amount = INTEREST_REALIZE_ADV_AMOUNT,
	@depo_acc_id = DEPO_ACC_ID,	@accrual_acc_id = ACCRUAL_ACC_ID, @loss_acc_id = LOSS_ACC_ID, @depo_realize_acc_id = DEPO_REALIZE_ACC_ID,
	@interest_realize_acc_id = INTEREST_REALIZE_ACC_ID,	@interest_realize_adv_acc_id = INTEREST_REALIZE_ADV_ACC_ID,
	@depo_account_state = DEPO_ACCOUNT_STATE, @accumulative = ACCUMULATIVE, @accumulate_schema_intrate = ACCUMULATE_SCHEMA_INTRATE, @prod_id = PROD_ID
FROM dbo.DEPO_DEPOSITS (NOLOCK)
WHERE DEPO_ID = @depo_id
IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR('<ERR>DEPOSIT NOT FOUND</ERR>', 16, 1); RETURN (1); END

SET @acc_rec_state = CASE @depo_account_state
	WHEN 1 THEN 1
	WHEN 2 THEN 4
	WHEN 3 THEN 16
END

DECLARE
	@tax_rate money

SET @tax_rate = (SELECT CONVERT(money, VALS) FROM dbo.INI_STR (NOLOCK) WHERE IDS = 'DEPOSIT_TAX_RATE')
IF @@ERROR <> 0 OR (@tax_rate IS NULL) BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR('<ERR>ERROR READING SETTINGS (DEPOSIT_TAX_RATE)</ERR>', 16, 1); RETURN (1); END

IF @tax_rate = $0.00
BEGIN
	DECLARE
		@tax_rate_attribute varchar(1000)

	SELECT @tax_rate_attribute = ATTRIB_VALUE
	FROM dbo.CLIENT_ATTRIBUTES (NOLOCK)
	WHERE CLIENT_NO = @client_no AND ATTRIB_CODE = '$TAXABLE'

	IF @@ERROR <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR('<ERR>ERROR READING SETTINGS (DEPOSIT_TAX_RATE)</ERR>', 16, 1); RETURN (1); END

	IF ISNULL(@tax_rate_attribute, '') = '1'
		SET @tax_rate = $7.5
END

IF EXISTS(SELECT * FROM dbo.DOC_DETAILS_PERC (NOLOCK) WHERE ACC_ID = @depo_acc_id AND ACCR_DATE > @op_date)
BEGIN
	IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK;
	RAISERROR('<ERR>ÛÄÝÃÏÌÀ ÏÐÄÒÀÝÉÉÓ ÛÄÒÖËÄÁÉÓ ÃÒÏÓ, ÀÍÂÀÒÉÛÆÄ ÌÏáÃÀ ÃÀÒÉÝáÅÀ ÏÐÄÒÀÝÉÉÓ ÛÄÌÃÄÂÉ ÈÀÒÉÙÄÁÉÈ</ERR>', 16, 1);
	RETURN (1)
END

DECLARE
	@archive_deposit bit,
	@accrue_deposit bit

SELECT @archive_deposit = ISNULL(ARCHIVE_DEPOSIT, convert(bit, 0)), @accrue_deposit = ISNULL(ACCRUE_DEPOSIT, convert(bit, 0))
FROM dbo.DEPO_VW_OP_DATA_COMMON
WHERE OP_ID = @op_id
IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR('<ERR>OPERATION DATA NOT FOUND</ERR>', 16, 1); RETURN (1); END

IF @archive_deposit = 1
BEGIN
	INSERT INTO dbo.DEPO_DEPOSITS_HISTORY
	SELECT @op_id, *
	FROM dbo.DEPO_DEPOSITS
	WHERE DEPO_ID = @depo_id
	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR('<ERR>ERROR ARCHIVE DEPOSIT!</ERR>', 16, 1); RETURN (1); END
END

IF @op_type = dbo.depo_fn_const_op_convert()
BEGIN
	DECLARE
		@calc_amount_1 money,
		@total_calc_amount_1 money,
		@last_calc_date_1 smalldatetime,
		@min_processing_date_1 smalldatetime,
		@min_processing_total_calc_amount_1 money

	SELECT @calc_amount_1 = CALC_AMOUNT, @total_calc_amount_1 = TOTAL_CALC_AMOUNT, @last_calc_date_1 = LAST_CALC_DATE, @min_processing_date_1 = MIN_PROCESSING_DATE, @min_processing_total_calc_amount_1 = MIN_PROCESSING_TOTAL_CALC_AMOUNT
	FROM dbo.ACCOUNTS_CRED_PERC
	WHERE ACC_ID = @depo_acc_id
	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR GET ACCOUNT CRED PERC DATA</ERR>', 16, 1); RETURN (1); END
END

IF (@op_type = dbo.depo_fn_const_op_withdraw()) AND (@accumulative = 1) AND (@accumulate_schema_intrate <> 2)
	SET @accrue_before_exec = 0
	
IF @accrue_deposit = 1 AND @accrue_before_exec = 0
	SET @accrue_before_exec = 1

IF (@accrue_doc_rec_id IS NULL) AND (@accrue_before_exec = 1)
BEGIN
	EXEC @r = dbo.PROCESS_ACCRUAL
		@perc_type = 0,
		@acc_id = @depo_acc_id,
		@user_id = @user_id,
		@dept_no = @dept_no,
		@doc_date = @op_date,
		@calc_date = @op_date,
		@force_calc = 1,
		@force_realization = 0,
		@simulate = 0,
		@recalc_option  = 0,
		@depo_depo_id = @depo_id,
		@depo_op_type = @op_type,
		@depo_op_id = @op_id,
		@rec_id  = @accrue_doc_rec_id OUTPUT
	IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR PROCESS ACRRUAL</ERR>', 16, 1); RETURN (1); END

	IF @accrue_doc_rec_id IS NOT NULL
	BEGIN
		UPDATE dbo.OPS_0000 WITH(ROWLOCK, UPDLOCK)
		SET [UID] = [UID] + 1, FLAGS = 1
		WHERE REC_ID = @accrue_doc_rec_id
		IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR PROCESS ACRRUAL DOC FLAGS CHANGE</ERR>', 16, 1); RETURN (1); END
	END	
END

IF @op_type IN (dbo.depo_fn_const_op_intrate_change(), dbo.depo_fn_const_op_prolongation(), dbo.depo_fn_const_op_prolongation_intrate_change())
BEGIN
	IF @accrue_doc_rec_id IS NOT NULL
	BEGIN
		UPDATE dbo.OPS_0000 WITH(ROWLOCK, UPDLOCK)
		SET [UID] = [UID] + 1, FLAGS = 1
		WHERE REC_ID = @accrue_doc_rec_id
		IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR PROCESS ACRRUAL DOC FLAGS CHANGE</ERR>', 16, 1); RETURN (1); END
	END	
END

IF @op_type = dbo.depo_fn_const_op_active()
BEGIN
	IF EXISTS(SELECT * FROM dbo.ACCOUNTS_CRED_PERC (NOLOCK) WHERE ACC_ID = @depo_acc_id) 
	BEGIN
		IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK;
		RAISERROR('<ERR>ÀÍÀÁÒÉÓ ÀÍÂÀÒÉÛÆÄ ÃÀÊÀÅÛÉÒÄÁÖËÉÀ ÊÒÄÃÉÔÖË ÍÀÛÈÆÄ ÃÀÒÉÝáÅÉÓ ÓØÄÌÀ!</ERR>', 16, 1) 
		RETURN (1)
	END

	IF @interest_realize_adv = 1
	BEGIN
		DECLARE
			@interest_realize_adv_tax_amount money,
			@interest_realize_adv_tax_amount_equ money

		SELECT @interest_realize_adv_tax_amount = INTEREST_REALIZE_ADV_TAX_AMOUNT,
			@interest_realize_adv_tax_amount_equ = INTEREST_REALIZE_ADV_TAX_AMOUNT_EQU
		FROM dbo.DEPO_VW_OP_ACC_DATA_ACTIVE (NOLOCK)
		WHERE OP_ID = @op_id
		IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR OP ACC DATA NOT FOUND</ERR>', 16, 1); RETURN (1); END
			
		
		INSERT INTO dbo.ACCOUNTS_CRED_PERC
			(ACC_ID, [START_DATE], END_DATE, MOVE_COUNT, MOVE_COUNT_TYPE, CALC_TYPE, FORMULA,
			CLIENT_ACCOUNT, PERC_CLIENT_ACCOUNT, PERC_BANK_ACCOUNT, DAYS_IN_YEAR, PERC_FLAGS, PERC_TYPE, TAX_RATE,
			DEPO_ID, RECALCULATE_TYPE, DEPO_REALIZE_ACC_ID, INTEREST_REALIZE_ACC_ID,
			DEPO_REALIZE_AMOUNT, INTEREST_REALIZE_AMOUNT, ADVANCE_ACC_ID, ADVANCE_AMOUNT,
			TOTAL_TAX_PAYED_AMOUNT, TOTAL_TAX_PAYED_AMOUNT_EQU)
		VALUES
			(@depo_acc_id, @start_date, @end_date, @realize_count, @realize_count_type, @accrue_type, @formula,
			@interest_realize_adv_acc_id, @accrual_acc_id, @loss_acc_id, @days_in_year, @perc_flags, @realize_type, @tax_rate,
			@depo_id, @recalculate_type, @depo_realize_acc_id, @interest_realize_acc_id,
			@depo_realize_amount, @interest_realize_amount, @interest_realize_acc_id, @interest_realize_adv_amount,
			@interest_realize_adv_tax_amount, @interest_realize_adv_tax_amount_equ)
	END
	ELSE
	BEGIN
		INSERT INTO dbo.ACCOUNTS_CRED_PERC
			(ACC_ID, [START_DATE], END_DATE, MOVE_COUNT, MOVE_COUNT_TYPE, CALC_TYPE, FORMULA,
			CLIENT_ACCOUNT, PERC_CLIENT_ACCOUNT, PERC_BANK_ACCOUNT, DAYS_IN_YEAR, PERC_FLAGS, PERC_TYPE, TAX_RATE,
			DEPO_ID, RECALCULATE_TYPE, DEPO_REALIZE_ACC_ID, INTEREST_REALIZE_ACC_ID,
			DEPO_REALIZE_AMOUNT, INTEREST_REALIZE_AMOUNT, ADVANCE_ACC_ID, ADVANCE_AMOUNT)
		VALUES
			(@depo_acc_id, @start_date, @end_date, @realize_count, @realize_count_type, @accrue_type, @formula,
			@interest_realize_acc_id, @accrual_acc_id, @loss_acc_id, @days_in_year, @perc_flags, @realize_type, @tax_rate,
			@depo_id, @recalculate_type, @depo_realize_acc_id, @interest_realize_acc_id,
			@depo_realize_amount, @interest_realize_amount, @interest_realize_adv_acc_id, @interest_realize_adv_amount)
	END

	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR('<ERR>ERROR INSERT ACCOUNT SCHEMA!</ERR>', 16, 1); RETURN (1); END
END
ELSE
IF @op_type = dbo.depo_fn_const_op_accumulate()
BEGIN
	DECLARE
		@depo_amount money

	SELECT @real_intrate = REAL_INTRATE, @intrate = INTRATE, @depo_amount = DEPO_AMOUNT, @change_formula = CHANGE_FORMULA
	FROM dbo.DEPO_VW_OP_DATA_ACCUMULATE
	WHERE OP_ID = @op_id
	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR('<ERR>ERROR OP DATA NOT FOUND!</ERR>', 16, 1); RETURN (1); END

	DECLARE
		@new_real_intrate TRATE

	IF @change_formula = 1
	BEGIN
		SET @formula = dbo.depo_fn_get_formula_accrue(@depo_id, @op_amount, @depo_amount, @real_intrate, @intrate)
		SET @new_real_intrate = dbo.depo_fn_get_formula_accrue_value(@op_amount, @depo_amount, @real_intrate, @intrate)

		INSERT INTO dbo.ACC_CHANGES (ACC_ID, [USER_ID], DESCRIP)
		VALUES (@depo_acc_id, @user_id, 'ÀÍÂÀÒÉÛÉÓ ÛÄÝÅËÀ : UID ÊÒÄÃ.ÃÀÒÉÝáÅÀ (ÀÍÀÁÒÆÄ ÈÀÍáÉÓ ÃÀÌÀÔÄÁÀ)')
		IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR UPDATE ACCOUNT CHANGES</ERR>', 16, 1); RETURN (1); END

		SET @rec_id = SCOPE_IDENTITY()
		
		INSERT INTO dbo.ACCOUNTS_ARC
		SELECT @rec_id, *
		FROM dbo.ACCOUNTS
		WHERE ACC_ID = @depo_acc_id
		IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR UPDATE ACCOUNT ARC</ERR>', 16, 1); RETURN (1); END

		UPDATE dbo.ACCOUNTS WITH (ROWLOCK, UPDLOCK)
		SET [UID] = [UID] + 1
		WHERE ACC_ID = @depo_acc_id
		IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR UPDATE ACCOUNT DATA</ERR>', 16, 1); RETURN (1); END

		INSERT INTO dbo.ACCOUNTS_CRED_PERC_ARC
		SELECT @rec_id, *
		FROM dbo.ACCOUNTS_CRED_PERC
		WHERE ACC_ID = @depo_acc_id
		IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR UPDATE ACCOUNT CRED PERC ARC</ERR>', 16, 1); RETURN (1); END

		UPDATE dbo.ACCOUNTS_CRED_PERC WITH (ROWLOCK, UPDLOCK)
		SET FORMULA = @formula
		WHERE ACC_ID = @depo_acc_id
		IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR UPDATE ACCOUNT CRED PERC ARC</ERR>', 16, 1); RETURN (1); END

		EXEC @r = dbo.ON_USER_AFTER_EDIT_ACC @depo_acc_id, @user_id
		IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR PROC: ON_USER_AFTER_EDIT_ACC</ERR>', 16, 1); RETURN (1); END

		SET @op_acc_data =
			(SELECT
				@rec_id AS ACC_ARC_REC_ID
		FOR XML RAW, TYPE)	

		UPDATE dbo.DEPO_OP WITH (ROWLOCK, UPDLOCK)
		SET OP_ACC_DATA = @op_acc_data
		WHERE OP_ID = @op_id
		IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR UPDATE OP DATA</ERR>', 16, 1); RETURN (1); END
	END
	ELSE
		SET @new_real_intrate = @real_intrate

	UPDATE dbo.DEPO_DEPOSITS WITH (ROWLOCK, UPDLOCK)
	SET AMOUNT = AMOUNT + @op_amount, REAL_INTRATE = @new_real_intrate
	WHERE DEPO_ID = @depo_id
	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR('<ERR>ERROR UPDATING DEPOSIT DATA</ERR>', 16, 1); RETURN (1); END
END
ELSE
IF @op_type = dbo.depo_fn_const_op_realize_interest()
BEGIN
	UPDATE dbo.DEPO_DEPOSITS WITH (ROWLOCK, UPDLOCK)
	SET AMOUNT = AMOUNT + @op_amount
	WHERE DEPO_ID = @depo_id
	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR('<ERR>ERROR UPDATING DEPOSIT DATA</ERR>', 16, 1); RETURN (1); END
END
ELSE
IF @op_type = dbo.depo_fn_const_op_withdraw()
BEGIN
	DECLARE 
		@change_spend_const_amount bit

	SELECT @change_spend_const_amount = CHANGE_SPEND_CONST_AMOUNT, @change_formula = CHANGE_FORMULA
	FROM dbo.DEPO_VW_OP_DATA_WITHDRAW
	WHERE OP_ID = @op_id
	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR('<ERR>ERROR OP DATA NOT FOUND!</ERR>', 16, 1); RETURN (1); END

	UPDATE dbo.DEPO_DEPOSITS WITH (ROWLOCK, UPDLOCK)
	SET AMOUNT = AMOUNT - @op_amount
	WHERE DEPO_ID = @depo_id
	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR('<ERR>ERROR UPDATING DEPOSIT DATA</ERR>', 16, 1); RETURN (1); END

	IF @change_spend_const_amount = 1
	BEGIN
		UPDATE dbo.DEPO_DEPOSITS WITH (ROWLOCK, UPDLOCK)
		SET SPEND_CONST_AMOUNT = @amount - @op_amount
		WHERE DEPO_ID = @depo_id
		IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR('<ERR>ERROR UPDATING DEPOSIT DATA</ERR>', 16, 1); RETURN (1); END				
	END

	IF @change_formula = 1
	BEGIN
		SET @formula = dbo.depo_fn_get_formula(@depo_id, default)
		
		UPDATE dbo.DEPO_DEPOSITS WITH (ROWLOCK, UPDLOCK)
		SET FORMULA = @formula
		WHERE DEPO_ID = @depo_id
		IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR('<ERR>ERROR UPDATING DEPOSIT DATA</ERR>', 16, 1); RETURN (1); END				

		INSERT INTO dbo.ACC_CHANGES (ACC_ID, [USER_ID], DESCRIP)
		VALUES (@depo_acc_id, @user_id, 'ÀÍÂÀÒÉÛÉÓ ÛÄÝÅËÀ : UID ÊÒÄÃ.ÃÀÒÉÝáÅÀ (ÀÍÀÁÒÉÃÀÍ ÈÀÍáÉÓ ÂÀÔÀÍÀ)')
		IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR UPDATE ACCOUNT CHANGES</ERR>', 16, 1); RETURN (1); END

		SET @rec_id = SCOPE_IDENTITY()
		
		INSERT INTO dbo.ACCOUNTS_ARC
		SELECT @rec_id, *
		FROM dbo.ACCOUNTS
		WHERE ACC_ID = @depo_acc_id
		IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR UPDATE ACCOUNT ARC</ERR>', 16, 1); RETURN (1); END

		UPDATE dbo.ACCOUNTS WITH (ROWLOCK, UPDLOCK)
		SET [UID] = [UID] + 1
		WHERE ACC_ID = @depo_acc_id
		IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR UPDATE ACCOUNT DATA</ERR>', 16, 1); RETURN (1); END

		INSERT INTO dbo.ACCOUNTS_CRED_PERC_ARC
		SELECT @rec_id, *
		FROM dbo.ACCOUNTS_CRED_PERC
		WHERE ACC_ID = @depo_acc_id
		IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR UPDATE ACCOUNT CRED PERC ARC</ERR>', 16, 1); RETURN (1); END

		UPDATE dbo.ACCOUNTS_CRED_PERC WITH (ROWLOCK, UPDLOCK)
		SET FORMULA = @formula
		WHERE ACC_ID = @depo_acc_id
		IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR UPDATE ACCOUNT CRED PERC ARC</ERR>', 16, 1); RETURN (1); END

	END

END
ELSE
IF @op_type = dbo.depo_fn_const_op_withdraw_interest_tax()
BEGIN
	UPDATE dbo.DEPO_DEPOSITS WITH (ROWLOCK, UPDLOCK)
	SET AMOUNT = AMOUNT - @op_amount
	WHERE DEPO_ID = @depo_id
	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR('<ERR>ERROR UPDATING DEPOSIT DATA</ERR>', 16, 1); RETURN (1); END
END
ELSE
IF @op_type = dbo.depo_fn_const_op_withdraw_schedule()
BEGIN
	DECLARE 
		@depo_withdraw_amount_schedule money

	SELECT @depo_withdraw_amount_schedule = DEPO_AMOUNT
	FROM dbo.DEPO_VW_OP_DATA_WITHDRAW_SCHEDULE
	WHERE OP_ID = @op_id
	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR('<ERR>ERROR OP DATA NOT FOUND!</ERR>', 16, 1); RETURN (1); END

	UPDATE dbo.DEPO_DEPOSITS WITH (ROWLOCK, UPDLOCK)
	SET AMOUNT = AMOUNT - @depo_withdraw_amount_schedule
	WHERE DEPO_ID = @depo_id
	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR('<ERR>ERROR UPDATING DEPOSIT DATA</ERR>', 16, 1); RETURN (1); END
END
ELSE
IF @op_type = dbo.depo_fn_const_op_bonus()
BEGIN
	EXEC @r = dbo.PROCESS_ACCRUAL
		@perc_type = 0,
		@acc_id = @depo_acc_id,
		@user_id = @user_id,
		@dept_no = @dept_no,
		@doc_date = @op_date,
		@calc_date = @op_date,
		@force_calc = 1,
		@force_realization = 0,
		@simulate = 0,
		@recalc_option  = 0,
		@accrue_amount = @op_amount,
		@depo_depo_id = @depo_id,
		@depo_op_type = @op_type,
		@depo_op_id = @op_id,
		@rec_id  = @accrue_doc_rec_id OUTPUT
	IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR PROCESS ACRRUAL</ERR>', 16, 1); RETURN (1); END
	
	IF @accrue_doc_rec_id IS NOT NULL
	BEGIN
		UPDATE dbo.OPS_0000 WITH(ROWLOCK, UPDLOCK)
		SET [UID] = [UID] + 1, FLAGS = 1
		WHERE REC_ID = @accrue_doc_rec_id
		IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR PROCESS ACRRUAL DOC FLAGS CHANGE</ERR>', 16, 1); RETURN (1); END
	END	
END
ELSE
IF @op_type = dbo.depo_fn_const_op_revision()
BEGIN
	DECLARE		
		@new_intrate money,
		@new_spend_amount_intrate money

	SELECT @new_intrate = NEW_INTRATE, @new_spend_amount_intrate = NEW_SPEND_AMOUNT_INTRATE
	FROM dbo.DEPO_VW_OP_DATA_REVISION
	WHERE OP_ID = @op_id
	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR('<ERR>ERROR OP DATA NOT FOUND!</ERR>', 16, 1); RETURN (1); END


	INSERT INTO dbo.ACC_CHANGES (ACC_ID, [USER_ID], DESCRIP)
	VALUES (@depo_acc_id, @user_id, 'ÀÍÂÀÒÉÛÉÓ ÛÄÝÅËÀ : UID ÊÒÄÃ.ÃÀÒÉÝáÅÀ (ÀÍÀÁÒÉÓ ÒÄÅÉÆÉÀ)')
	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR UPDATE ACCOUNT CHANGES</ERR>', 16, 1); RETURN (1); END

	SET @rec_id = SCOPE_IDENTITY()
	
	INSERT INTO dbo.ACCOUNTS_ARC
	SELECT @rec_id, *
	FROM dbo.ACCOUNTS
	WHERE ACC_ID = @depo_acc_id
	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR UPDATE ACCOUNT ARC</ERR>', 16, 1); RETURN (1); END

	UPDATE dbo.ACCOUNTS WITH (ROWLOCK, UPDLOCK)
	SET [UID] = [UID] + 1
	WHERE ACC_ID = @depo_acc_id
	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR UPDATE ACCOUNT DATA</ERR>', 16, 1); RETURN (1); END

	SET @op_acc_data = (SELECT * FROM ACCOUNTS_CRED_PERC WHERE ACC_ID = @depo_acc_id FOR XML RAW, TYPE)
	UPDATE dbo.DEPO_OP WITH (ROWLOCK, UPDLOCK)
	SET OP_ACC_DATA = @op_acc_data
	WHERE OP_ID = @op_id
	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR UPDATE OP DATA</ERR>', 16, 1); RETURN (1); END

	INSERT INTO dbo.ACCOUNTS_CRED_PERC_ARC
	SELECT @rec_id, *
	FROM dbo.ACCOUNTS_CRED_PERC
	WHERE ACC_ID = @depo_acc_id
	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR UPDATE ACCOUNT CRED PERC ARC</ERR>', 16, 1); RETURN (1); END

	UPDATE dbo.DEPO_DEPOSITS  WITH (ROWLOCK, UPDLOCK)
	SET INTRATE = @new_intrate,
		REAL_INTRATE = @new_intrate,
		FORMULA = @formula
	WHERE DEPO_ID = @depo_id
	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR('<ERR>ERROR UPDATING DEPOSIT DATA</ERR>', 16, 1); RETURN (1); END
	
	SET @new_formula = dbo.depo_fn_get_formula(@depo_id, default)
	
	UPDATE dbo.DEPO_DEPOSITS  WITH (ROWLOCK, UPDLOCK)
	SET FORMULA = @new_formula
	WHERE DEPO_ID = @depo_id
	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR('<ERR>ERROR UPDATING DEPOSIT DATA</ERR>', 16, 1); RETURN (1); END
	
	UPDATE dbo.ACCOUNTS_CRED_PERC WITH (ROWLOCK, UPDLOCK)
	SET FORMULA = @new_formula
	WHERE ACC_ID = @depo_acc_id
	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR UPDATE ACCOUNT CRED PERC</ERR>', 16, 1); RETURN (1); END
END
ELSE
IF @op_type = dbo.depo_fn_const_op_intrate_change()
BEGIN

	SELECT @change_intrate = CHANGE_INTRATE, @new_intrate = NEW_INTRATE, @recalculate_schedule = RECALCULATE_SCHEDULE
	FROM dbo.DEPO_VW_OP_DATA_CHANGE_INTRATE
	WHERE OP_ID = @op_id
	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR('<ERR>ERROR OP DATA NOT FOUND!</ERR>', 16, 1); RETURN (1); END

	INSERT INTO dbo.ACC_CHANGES (ACC_ID, [USER_ID], DESCRIP)
	VALUES (@depo_acc_id, @user_id, 'ÀÍÂÀÒÉÛÉÓ ÛÄÝÅËÀ : UID ÊÒÄÃ.ÃÀÒÉÝáÅÀ (ÀÍÀÁÀÒÆÄ ÐÒÏÝÄÍÔÉÓ ÛÄÝÅËÀ)')
	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR UPDATE ACCOUNT CHANGES</ERR>', 16, 1); RETURN (1); END

	SET @rec_id = SCOPE_IDENTITY()
	
	INSERT INTO dbo.ACCOUNTS_ARC
	SELECT @rec_id, *
	FROM dbo.ACCOUNTS
	WHERE ACC_ID = @depo_acc_id
	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR UPDATE ACCOUNT ARC</ERR>', 16, 1); RETURN (1); END

	UPDATE dbo.ACCOUNTS WITH (ROWLOCK, UPDLOCK)
	SET [UID] = [UID] + 1
	WHERE ACC_ID = @depo_acc_id
	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR UPDATE ACCOUNT DATA</ERR>', 16, 1); RETURN (1); END

	SET @op_acc_data = (SELECT * FROM ACCOUNTS_CRED_PERC WHERE ACC_ID = @depo_acc_id FOR XML RAW, TYPE)
	UPDATE dbo.DEPO_OP WITH (ROWLOCK, UPDLOCK)
	SET OP_ACC_DATA = @op_acc_data
	WHERE OP_ID = @op_id
	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR UPDATE OP DATA</ERR>', 16, 1); RETURN (1); END

	INSERT INTO dbo.ACCOUNTS_CRED_PERC_ARC
	SELECT @rec_id, *
	FROM dbo.ACCOUNTS_CRED_PERC
	WHERE ACC_ID = @depo_acc_id
	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR UPDATE ACCOUNT CRED PERC ARC</ERR>', 16, 1); RETURN (1); END

	IF @change_intrate=1 
	BEGIN
		UPDATE dbo.DEPO_DEPOSITS  WITH (ROWLOCK, UPDLOCK)
		SET REAL_INTRATE = @new_intrate,
			INTRATE = @new_intrate
		WHERE DEPO_ID = @depo_id
		IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR('<ERR>ERROR UPDATING DEPOSIT DATA</ERR>', 16, 1); RETURN (1); END
	END
	ELSE
	BEGIN
		UPDATE dbo.DEPO_DEPOSITS  WITH (ROWLOCK, UPDLOCK)
		SET REAL_INTRATE = @new_intrate
		WHERE DEPO_ID = @depo_id
		IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR('<ERR>ERROR UPDATING DEPOSIT DATA</ERR>', 16, 1); RETURN (1); END
	END
	
	SET @new_formula = dbo.depo_fn_get_formula(@depo_id, default)
		
	UPDATE dbo.ACCOUNTS_CRED_PERC WITH (ROWLOCK, UPDLOCK)
	SET FORMULA = @new_formula
	WHERE ACC_ID = @depo_acc_id
	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR UPDATE ACCOUNT CRED PERC</ERR>', 16, 1); RETURN (1); END
	
	UPDATE dbo.DEPO_DEPOSITS  WITH (ROWLOCK, UPDLOCK)
	SET FORMULA = @new_formula
	WHERE DEPO_ID = @depo_id
	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR('<ERR>ERROR UPDATING DEPOSIT DATA</ERR>', 16, 1); RETURN (1); END

	IF @recalculate_schedule = 1
	BEGIN		
		EXEC @r = dbo.depo_sp_recalculate_depo_schedule
			@op_id = @op_id,
			@depo_id = @depo_id,
			@op_date = @op_date,
			@new_intrate = @new_intrate
		IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR('<ERR>ERROR RECALCULATE NEW SCHEDULE</ERR>', 16, 1); RETURN (1); END
	END
END
ELSE
IF @op_type = dbo.depo_fn_const_op_taxrate_change()
BEGIN
	SELECT @new_intrate = NEW_TAXRATE
	FROM dbo.DEPO_VW_OP_DATA_CHANGE_TAXRATE
	WHERE OP_ID = @op_id
	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR('<ERR>ERROR OP DATA NOT FOUND!</ERR>', 16, 1); RETURN (1); END

	INSERT INTO dbo.ACC_CHANGES (ACC_ID, [USER_ID], DESCRIP)
	VALUES (@depo_acc_id, @user_id, 'ÀÍÂÀÒÉÛÉÓ ÛÄÝÅËÀ : UID ÊÒÄÃ.ÃÀÒÉÝáÅÀ (ÃÀÓÀÁÄÂÒÉ ÓÀÐÒÏÝÄÍÔÏ ÂÀÍÀÊÅÄÈÉÓ ÛÄÝÅËÀ)')
	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR UPDATE ACCOUNT CHANGES</ERR>', 16, 1); RETURN (1); END

	SET @rec_id = SCOPE_IDENTITY()
	
	INSERT INTO dbo.ACCOUNTS_ARC
	SELECT @rec_id, *
	FROM dbo.ACCOUNTS
	WHERE ACC_ID = @depo_acc_id
	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR UPDATE ACCOUNT ARC</ERR>', 16, 1); RETURN (1); END

	UPDATE dbo.ACCOUNTS WITH (ROWLOCK, UPDLOCK)
	SET [UID] = [UID] + 1
	WHERE ACC_ID = @depo_acc_id
	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR UPDATE ACCOUNT DATA</ERR>', 16, 1); RETURN (1); END

	INSERT INTO dbo.ACCOUNTS_CRED_PERC_ARC
	SELECT @rec_id, *
	FROM dbo.ACCOUNTS_CRED_PERC
	WHERE ACC_ID = @depo_acc_id
	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR UPDATE ACCOUNT CRED PERC ARC</ERR>', 16, 1); RETURN (1); END

	UPDATE dbo.ACCOUNTS_CRED_PERC WITH (ROWLOCK, UPDLOCK)
	SET TAX_RATE = @new_intrate
	WHERE ACC_ID = @depo_acc_id
	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR UPDATE ACCOUNT CRED PERC</ERR>', 16, 1); RETURN (1); END
END
ELSE
IF @op_type = dbo.depo_fn_const_op_intrate_advance()
BEGIN
	SELECT @new_formula = NEW_FORMULA
	FROM dbo.DEPO_VW_OP_DATA_CHANGE_INTRATE_ADVANCE
	WHERE OP_ID = @op_id
	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR('<ERR>ERROR OP DATA NOT FOUND!</ERR>', 16, 1); RETURN (1); END

	INSERT INTO dbo.ACC_CHANGES (ACC_ID, [USER_ID], DESCRIP)
	VALUES (@depo_acc_id, @user_id, 'ÀÍÂÀÒÉÛÉÓ ÛÄÝÅËÀ : UID ÊÒÄÃ.ÃÀÒÉÝáÅÀ (×ÏÒÌÖËÉÓ ÛÄÝÅËÀ ÀËÔÄÒÍÀÔÉÖËÉÈ)')
	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR UPDATE ACCOUNT CHANGES</ERR>', 16, 1); RETURN (1); END

	SET @rec_id = SCOPE_IDENTITY()
	
	INSERT INTO dbo.ACCOUNTS_ARC
	SELECT @rec_id, *
	FROM dbo.ACCOUNTS
	WHERE ACC_ID = @depo_acc_id
	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR UPDATE ACCOUNT ARC</ERR>', 16, 1); RETURN (1); END

	UPDATE dbo.ACCOUNTS WITH (ROWLOCK, UPDLOCK)
	SET [UID] = [UID] + 1
	WHERE ACC_ID = @depo_acc_id
	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR UPDATE ACCOUNT DATA</ERR>', 16, 1); RETURN (1); END

	SET @op_acc_data = (SELECT * FROM ACCOUNTS_CRED_PERC WHERE ACC_ID = @depo_acc_id FOR XML RAW, TYPE)
	UPDATE dbo.DEPO_OP WITH (ROWLOCK, UPDLOCK)
	SET OP_ACC_DATA = @op_acc_data
	WHERE OP_ID = @op_id
	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR UPDATE OP DATA</ERR>', 16, 1); RETURN (1); END

	INSERT INTO dbo.ACCOUNTS_CRED_PERC_ARC
	SELECT @rec_id, *
	FROM dbo.ACCOUNTS_CRED_PERC
	WHERE ACC_ID = @depo_acc_id
	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR UPDATE ACCOUNT CRED PERC ARC</ERR>', 16, 1); RETURN (1); END

	UPDATE dbo.ACCOUNTS_CRED_PERC WITH (ROWLOCK, UPDLOCK)
	SET FORMULA = @new_formula
	WHERE ACC_ID = @depo_acc_id
	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR UPDATE ACCOUNT CRED PERC</ERR>', 16, 1); RETURN (1); END
	
	UPDATE dbo.DEPO_DEPOSITS  WITH (ROWLOCK, UPDLOCK)
	SET FORMULA = @new_formula
	WHERE DEPO_ID = @depo_id
	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR('<ERR>ERROR UPDATING DEPOSIT DATA</ERR>', 16, 1); RETURN (1); END
END
ELSE
IF @op_type = dbo.depo_fn_const_op_function_advance()
BEGIN
	SELECT @new_formula = NEW_FORMULA
	FROM dbo.DEPO_VW_OP_DATA_CHANGE_FUNCTION_ADVANCE
	WHERE OP_ID = @op_id
	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR('<ERR>ERROR OP DATA NOT FOUND!</ERR>', 16, 1); RETURN (1); END

	INSERT INTO dbo.ACC_CHANGES (ACC_ID, [USER_ID], DESCRIP)
	VALUES (@depo_acc_id, @user_id, 'ÀÍÂÀÒÉÛÉÓ ÛÄÝÅËÀ : UID ÊÒÄÃ.ÃÀÒÉÝáÅÀ (×ÏÒÌÖËÉÓ ÛÄÝÅËÀ ÀËÔÄÒÍÀÔÉÖËÉÈ)')
	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR UPDATE ACCOUNT CHANGES</ERR>', 16, 1); RETURN (1); END

	SET @rec_id = SCOPE_IDENTITY()
	
	INSERT INTO dbo.ACCOUNTS_ARC
	SELECT @rec_id, *
	FROM dbo.ACCOUNTS
	WHERE ACC_ID = @depo_acc_id
	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR UPDATE ACCOUNT ARC</ERR>', 16, 1); RETURN (1); END

	UPDATE dbo.ACCOUNTS WITH (ROWLOCK, UPDLOCK)
	SET [UID] = [UID] + 1
	WHERE ACC_ID = @depo_acc_id
	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR UPDATE ACCOUNT DATA</ERR>', 16, 1); RETURN (1); END

	SET @op_acc_data = (SELECT * FROM ACCOUNTS_CRED_PERC WHERE ACC_ID = @depo_acc_id FOR XML RAW, TYPE)
	UPDATE dbo.DEPO_OP WITH (ROWLOCK, UPDLOCK)
	SET OP_ACC_DATA = @op_acc_data
	WHERE OP_ID = @op_id
	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR UPDATE OP DATA</ERR>', 16, 1); RETURN (1); END

	INSERT INTO dbo.ACCOUNTS_CRED_PERC_ARC
	SELECT @rec_id, *
	FROM dbo.ACCOUNTS_CRED_PERC
	WHERE ACC_ID = @depo_acc_id
	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR UPDATE ACCOUNT CRED PERC ARC</ERR>', 16, 1); RETURN (1); END

	UPDATE dbo.ACCOUNTS_CRED_PERC WITH (ROWLOCK, UPDLOCK)
	SET FORMULA = @new_formula
	WHERE ACC_ID = @depo_acc_id
	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR UPDATE ACCOUNT CRED PERC</ERR>', 16, 1); RETURN (1); END
	
	UPDATE dbo.DEPO_DEPOSITS  WITH (ROWLOCK, UPDLOCK)
	SET FORMULA = @new_formula
	WHERE DEPO_ID = @depo_id
	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR('<ERR>ERROR UPDATING DEPOSIT DATA</ERR>', 16, 1); RETURN (1); END
END
ELSE
IF @op_type = dbo.depo_fn_const_op_prolongation()
BEGIN
	SELECT @new_end_date = NEW_END_DATE
	FROM dbo.DEPO_VW_OP_DATA_PROLONGATION
	WHERE OP_ID = @op_id
	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR('<ERR>ERROR OP DATA NOT FOUND!</ERR>', 16, 1); RETURN (1); END

	UPDATE dbo.DEPO_DEPOSITS  WITH (ROWLOCK, UPDLOCK)
	SET END_DATE = @new_end_date,
		PROLONGATION_COUNT = ISNULL(PROLONGATION_COUNT, 0) + 1
	WHERE DEPO_ID = @depo_id
	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR('<ERR>ERROR UPDATING DEPOSIT DATA</ERR>', 16, 1); RETURN (1); END

	SELECT @acc_client_no = CLIENT_NO
	FROM dbo.ACCOUNTS (NOLOCK)
	WHERE ACC_ID = @depo_acc_id
	IF (@acc_client_no IS NOT NULL) AND (@acc_client_no = @client_no)
	BEGIN
		INSERT INTO dbo.ACC_CHANGES (ACC_ID, [USER_ID], DESCRIP)
		VALUES (@depo_acc_id, @user_id, 'ÀÍÂÀÒÉÛÉÓ ÛÄÝÅËÀ : UID PERIOD (ÀÍÀÁÒÉÓ ÐÒÏËÏÍÂÀÝÉÀ)')
		IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR UPDATE ACCOUNT CHANGES</ERR>', 16, 1); RETURN (1); END

		SET @rec_id = SCOPE_IDENTITY()
		
		INSERT INTO dbo.ACCOUNTS_ARC
		SELECT @rec_id, *
		FROM dbo.ACCOUNTS
		WHERE ACC_ID = @depo_acc_id
		IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR INSERT ACCOUNT ARC</ERR>', 16, 1); RETURN (1); END

		UPDATE dbo.ACCOUNTS WITH (ROWLOCK, UPDLOCK)
		SET [UID] = [UID] + 1,
			PERIOD = @new_end_date
		WHERE ACC_ID = @depo_acc_id
		IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR UPDATE ACCOUNT DATA</ERR>', 16, 1); RETURN (1); END
		
		INSERT INTO dbo.ACCOUNTS_CRED_PERC_ARC
		SELECT @rec_id, *
		FROM dbo.ACCOUNTS_CRED_PERC
		WHERE ACC_ID = @depo_acc_id
		IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR INSERT ACCOUNT CRED PERC ARC</ERR>', 16, 1); RETURN (1); END

		UPDATE dbo.ACCOUNTS_CRED_PERC WITH (ROWLOCK, UPDLOCK)
		SET END_DATE = @new_end_date
		WHERE ACC_ID = @depo_acc_id
		IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR UPDATE ACCOUNT CRED PERC</ERR>', 16, 1); RETURN (1); END
	END

	SELECT @acc_client_no = CLIENT_NO
	FROM dbo.ACCOUNTS (NOLOCK)
	WHERE ACC_ID = @accrual_acc_id
	IF (@acc_client_no IS NOT NULL) AND (@acc_client_no = @client_no)
	BEGIN
		INSERT INTO dbo.ACC_CHANGES (ACC_ID, [USER_ID], DESCRIP)
		VALUES (@accrual_acc_id, @user_id, 'ÀÍÂÀÒÉÛÉÓ ÛÄÝÅËÀ : UID PERIOD (ÀÍÀÁÒÉÓ ÐÒÏËÏÍÂÀÝÉÀ)')
		IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR UPDATE ACCOUNT CHANGES</ERR>', 16, 1); RETURN (1); END

		SET @rec_id = SCOPE_IDENTITY()
		
		INSERT INTO dbo.ACCOUNTS_ARC
		SELECT @rec_id, *
		FROM dbo.ACCOUNTS
		WHERE ACC_ID = @accrual_acc_id
		IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR INSERT ACCOUNT ARC</ERR>', 16, 1); RETURN (1); END

		UPDATE dbo.ACCOUNTS WITH (ROWLOCK, UPDLOCK)
		SET [UID] = [UID] + 1,
			PERIOD = @new_end_date
		WHERE ACC_ID = @accrual_acc_id
		IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR UPDATE ACCOUNT DATA</ERR>', 16, 1); RETURN (1); END
	END

	SELECT @acc_client_no = CLIENT_NO
	FROM dbo.ACCOUNTS (NOLOCK)
	WHERE ACC_ID = @loss_acc_id
	IF (@acc_client_no IS NOT NULL) AND (@acc_client_no = @client_no)
	BEGIN
		INSERT INTO dbo.ACC_CHANGES (ACC_ID, [USER_ID], DESCRIP)
		VALUES (@loss_acc_id, @user_id, 'ÀÍÂÀÒÉÛÉÓ ÛÄÝÅËÀ : UID PERIOD (ÀÍÀÁÒÉÓ ÐÒÏËÏÍÂÀÝÉÀ)')
		IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR UPDATE ACCOUNT CHANGES</ERR>', 16, 1); RETURN (1); END

		SET @rec_id = SCOPE_IDENTITY()
		
		INSERT INTO dbo.ACCOUNTS_ARC
		SELECT @rec_id, *
		FROM dbo.ACCOUNTS
		WHERE ACC_ID = @loss_acc_id
		IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR INSERT ACCOUNT ARC</ERR>', 16, 1); RETURN (1); END

		UPDATE dbo.ACCOUNTS WITH (ROWLOCK, UPDLOCK)
		SET [UID] = [UID] + 1,
		PERIOD = @new_end_date
		WHERE ACC_ID = @loss_acc_id
		IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR UPDATE ACCOUNT DATA</ERR>', 16, 1); RETURN (1); END
	END

	IF @interest_realize_adv_acc_id IS NULL	
		SET @acc_client_no = NULL
	ELSE
	BEGIN
		SELECT @acc_client_no = CLIENT_NO
		FROM dbo.ACCOUNTS (NOLOCK)
		WHERE ACC_ID = @interest_realize_adv_acc_id
	END

	IF (@acc_client_no IS NOT NULL) AND (@acc_client_no = @client_no)
	BEGIN
		INSERT INTO dbo.ACC_CHANGES (ACC_ID, [USER_ID], DESCRIP)
		VALUES (@interest_realize_adv_acc_id, @user_id, 'ÀÍÂÀÒÉÛÉÓ ÛÄÝÅËÀ : UID PERIOD (ÀÍÀÁÒÉÓ ÐÒÏËÏÍÂÀÝÉÀ)')
		IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR UPDATE ACCOUNT CHANGES</ERR>', 16, 1); RETURN (1); END

		SET @rec_id = SCOPE_IDENTITY()
		
		INSERT INTO dbo.ACCOUNTS_ARC
		SELECT @rec_id, *
		FROM dbo.ACCOUNTS
		WHERE ACC_ID = @interest_realize_adv_acc_id
		IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR INSERT ACCOUNT ARC</ERR>', 16, 1); RETURN (1); END

		UPDATE dbo.ACCOUNTS WITH (ROWLOCK, UPDLOCK)
		SET [UID] = [UID] + 1,
		PERIOD = @new_end_date
		WHERE ACC_ID = @interest_realize_adv_acc_id
		IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR UPDATE ACCOUNT DATA</ERR>', 16, 1); RETURN (1); END
	END
END
ELSE
IF @op_type = dbo.depo_fn_const_op_prolongation_intrate_change()
BEGIN
	SELECT @new_end_date = NEW_END_DATE, @change_intrate = CHANGE_INTRATE, @new_intrate = NEW_INTRATE, @recalculate_schedule = RECALCULATE_SCHEDULE
	FROM dbo.DEPO_VW_OP_DATA_PROLONGATION_INTRATE_CHANGE
	WHERE OP_ID = @op_id
	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR('<ERR>ERROR OP DATA NOT FOUND!</ERR>', 16, 1); RETURN (1); END

	UPDATE dbo.DEPO_DEPOSITS  WITH (ROWLOCK, UPDLOCK)
	SET END_DATE = @new_end_date,
		INTRATE = @new_intrate,
		REAL_INTRATE = @new_intrate,
		PROLONGATION_COUNT = ISNULL(PROLONGATION_COUNT, 0) + 1
	WHERE DEPO_ID = @depo_id
	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR('<ERR>ERROR UPDATING DEPOSIT DATA</ERR>', 16, 1); RETURN (1); END

	SELECT @acc_client_no = CLIENT_NO
	FROM dbo.ACCOUNTS (NOLOCK)
	WHERE ACC_ID=@depo_acc_id
	IF (@acc_client_no IS NOT NULL) AND (@acc_client_no = @client_no)
	BEGIN
		INSERT INTO dbo.ACC_CHANGES (ACC_ID, [USER_ID], DESCRIP)
		VALUES (@depo_acc_id, @user_id, 'ÀÍÂÀÒÉÛÉÓ ÛÄÝÅËÀ : UID PERIOD (ÀÍÀÁÒÉÓ ÐÒÏËÏÍÂÀÝÉÀ)')
		IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR UPDATE ACCOUNT CHANGES</ERR>', 16, 1); RETURN (1); END

		SET @rec_id = SCOPE_IDENTITY()
		
		INSERT INTO dbo.ACCOUNTS_ARC
		SELECT @rec_id, *
		FROM dbo.ACCOUNTS
		WHERE ACC_ID = @depo_acc_id
		IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR INSERT ACCOUNT ARC</ERR>', 16, 1); RETURN (1); END

		UPDATE dbo.ACCOUNTS WITH (ROWLOCK, UPDLOCK)
		SET [UID] = [UID] + 1,
			PERIOD = @new_end_date
		WHERE ACC_ID = @depo_acc_id
		IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR UPDATE ACCOUNT DATA</ERR>', 16, 1); RETURN (1); END
		
		SET @op_acc_data = (SELECT * FROM dbo.ACCOUNTS_CRED_PERC (NOLOCK) WHERE ACC_ID = @depo_acc_id FOR XML RAW, TYPE)
		UPDATE dbo.DEPO_OP WITH (ROWLOCK, UPDLOCK)
		SET OP_ACC_DATA = @op_acc_data
		WHERE OP_ID = @op_id
		IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR UPDATE OP DATA</ERR>', 16, 1); RETURN (1); END

		INSERT INTO dbo.ACCOUNTS_CRED_PERC_ARC
		SELECT @rec_id, *
		FROM dbo.ACCOUNTS_CRED_PERC
		WHERE ACC_ID = @depo_acc_id
		IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR UPDATE ACCOUNT CRED PERC ARC</ERR>', 16, 1); RETURN (1); END

		SET @new_formula = dbo.depo_fn_get_formula(@depo_id, default)

		UPDATE dbo.DEPO_DEPOSITS  WITH (ROWLOCK, UPDLOCK)
		SET FORMULA = @new_formula
		WHERE DEPO_ID = @depo_id
		IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR('<ERR>ERROR UPDATING DEPOSIT DATA</ERR>', 16, 1); RETURN (1); END
			
		UPDATE dbo.ACCOUNTS_CRED_PERC WITH (ROWLOCK, UPDLOCK)
		SET END_DATE = @new_end_date,
			PERC_TYPE = 1, -- ÁÀÍÊÉ ÒÄÓÐÖÁËÉÊÀ
			MOVE_COUNT = 1, -- ÁÀÍÊÉ ÒÄÓÐÖÁËÉÊÀ
			MOVE_COUNT_TYPE = 2, -- ÁÀÍÊÉ ÒÄÓÐÖÁËÉÊÀ
			FORMULA = @new_formula
		WHERE ACC_ID = @depo_acc_id
		IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR UPDATE ACCOUNT CRED PERC</ERR>', 16, 1); RETURN (1); END
	END

	SELECT @acc_client_no = CLIENT_NO
	FROM dbo.ACCOUNTS (NOLOCK)
	WHERE ACC_ID=@accrual_acc_id
	IF (@acc_client_no IS NOT NULL) AND (@acc_client_no = @client_no)
	BEGIN
		INSERT INTO dbo.ACC_CHANGES (ACC_ID, [USER_ID], DESCRIP)
		VALUES (@accrual_acc_id, @user_id, 'ÀÍÂÀÒÉÛÉÓ ÛÄÝÅËÀ : UID PERIOD (ÀÍÀÁÒÉÓ ÐÒÏËÏÍÂÀÝÉÀ)')
		IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR UPDATE ACCOUNT CHANGES</ERR>', 16, 1); RETURN (1); END

		SET @rec_id = SCOPE_IDENTITY()
		
		INSERT INTO dbo.ACCOUNTS_ARC
		SELECT @rec_id, *
		FROM dbo.ACCOUNTS (NOLOCK)
		WHERE ACC_ID = @accrual_acc_id
		IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR INSERT ACCOUNT ARC</ERR>', 16, 1); RETURN (1); END

		UPDATE dbo.ACCOUNTS WITH (ROWLOCK, UPDLOCK)
		SET [UID] = [UID] + 1,
			PERIOD = @new_end_date
		WHERE ACC_ID = @accrual_acc_id
		IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR UPDATE ACCOUNT DATA</ERR>', 16, 1); RETURN (1); END
	END

	SELECT @acc_client_no = CLIENT_NO
	FROM ACCOUNTS
	WHERE ACC_ID=@loss_acc_id
	IF (@acc_client_no IS NOT NULL) AND (@acc_client_no = @client_no) 
	BEGIN
		INSERT INTO dbo.ACC_CHANGES (ACC_ID, [USER_ID], DESCRIP)
		VALUES (@loss_acc_id, @user_id, 'ÀÍÂÀÒÉÛÉÓ ÛÄÝÅËÀ : UID PERIOD (ÀÍÀÁÒÉÓ ÐÒÏËÏÍÂÀÝÉÀ)')
		IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR UPDATE ACCOUNT CHANGES</ERR>', 16, 1); RETURN (1); END

		SET @rec_id = SCOPE_IDENTITY()
		
		INSERT INTO dbo.ACCOUNTS_ARC
		SELECT @rec_id, *
		FROM dbo.ACCOUNTS (NOLOCK)
		WHERE ACC_ID = @loss_acc_id
		IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR INSERT ACCOUNT ARC</ERR>', 16, 1); RETURN (1); END

		UPDATE dbo.ACCOUNTS WITH (ROWLOCK, UPDLOCK)
		SET [UID] = [UID] + 1,
			PERIOD = @new_end_date
		WHERE ACC_ID = @loss_acc_id
		IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR UPDATE ACCOUNT DATA</ERR>', 16, 1); RETURN (1); END
	END

	IF @interest_realize_adv_acc_id IS NULL	
		SET @acc_client_no=NULL
	ELSE
	BEGIN
		SELECT @acc_client_no = CLIENT_NO
		FROM dbo.ACCOUNTS (NOLOCK)
		WHERE ACC_ID = @interest_realize_adv_acc_id
	END

	IF (@acc_client_no IS NOT NULL) AND (@acc_client_no = @client_no)
	BEGIN
		INSERT INTO dbo.ACC_CHANGES (ACC_ID, [USER_ID], DESCRIP)
		VALUES (@interest_realize_adv_acc_id, @user_id, 'ÀÍÂÀÒÉÛÉÓ ÛÄÝÅËÀ : UID PERIOD (ÀÍÀÁÒÉÓ ÐÒÏËÏÍÂÀÝÉÀ)')
		IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR UPDATE ACCOUNT CHANGES</ERR>', 16, 1); RETURN (1); END

		SET @rec_id = SCOPE_IDENTITY()
		
		INSERT INTO dbo.ACCOUNTS_ARC
		SELECT @rec_id, *
		FROM dbo.ACCOUNTS (NOLOCK)
		WHERE ACC_ID = @interest_realize_adv_acc_id
		IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR INSERT ACCOUNT ARC</ERR>', 16, 1); RETURN (1); END

		UPDATE dbo.ACCOUNTS WITH (ROWLOCK, UPDLOCK)
		SET [UID] = [UID] + 1,
			PERIOD = @new_end_date
		WHERE ACC_ID = @interest_realize_adv_acc_id
		IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR UPDATE ACCOUNT DATA</ERR>', 16, 1); RETURN (1); END
	END

	IF @recalculate_schedule = 1
	BEGIN		
		EXEC @r = dbo.depo_sp_recalculate_depo_schedule
			@op_id = @op_id,
			@depo_id = @depo_id,
			@op_date = @op_date,
			@new_intrate = @new_intrate
		IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR('<ERR>ERROR RECALCULATE NEW SCHEDULE</ERR>', 16, 1); RETURN (1); END
	END
	
END
ELSE
IF @op_type = dbo.depo_fn_const_op_mark2default()
BEGIN
	DECLARE
		@deposit_default bit
		
	SELECT @deposit_default = DEPOSIT_DEFAULT
	FROM dbo.DEPO_VW_OP_DATA_MARK2DEFAULT
	WHERE OP_ID = @op_id
	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR('<ERR>ERROR OP DATA NOT FOUND!</ERR>', 16, 1); RETURN (1); END
		
	UPDATE dbo.DEPO_DEPOSITS WITH (ROWLOCK, UPDLOCK)
	SET DEPOSIT_DEFAULT = @deposit_default  
	WHERE DEPO_ID = @depo_id
	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR('<ERR>ERROR UPDATING DEPOSIT DATA</ERR>', 16, 1); RETURN (1); END
END
ELSE
IF @op_type = dbo.depo_fn_const_op_mark2default_change_intrate_schema()
BEGIN
	DECLARE 
		@mark_default_new_intrate money,
		@new_intrate_schema int,
		@intitial_amount money,
		@real_formula varchar(255),
--		@date_type int, agcerilia globalur cvladad da vkitxulobt DEPO_DEPOSITS cxrilidan
		@depo_period int,
		@avg_intrate money,
		@date1 smalldatetime,
		@date2 smalldatetime,
--		@pfDontIncludeEndDate int,
		@pfDontIncludeStartDate int

	SET @pfDontIncludeStartDate = 1
	
	SELECT @new_intrate = NEW_INTRATE, @new_intrate_schema = NEW_INTRATE_SCHEMA, 
			@intitial_amount = INTITIAL_AMOUNT
	FROM dbo.DEPO_VW_OP_DATA_MARK2DEFAULT_CHANGE_INTRATE_SCHEMA
	WHERE OP_ID = @op_id
	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR('ERROR OP DATA NOT FOUND!', 16, 1); RETURN (1); END
		
	UPDATE dbo.DEPO_DEPOSITS WITH(UPDLOCK)
	SET INTRATE = @new_intrate,
		INTRATE_SCHEMA = @new_intrate_schema
	WHERE DEPO_ID = @depo_id
	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('ERROR CHANGE INTRATE DATA', 16, 1); RETURN (1); END

	SET @formula = dbo.depo_fn_get_formula(@depo_id, default)
	SET @real_formula = NULL

	DECLARE cc CURSOR LOCAL FAST_FORWARD--ანაბარზე გაკეთებული  შენატანების cursor
	FOR
		SELECT OP_DATE, SUM(AMOUNT)
		FROM dbo.DEPO_OP (NOLOCK)
		WHERE DEPO_ID = @depo_id AND OP_TYPE = dbo.depo_fn_const_op_accumulate()
		GROUP BY OP_DATE
	
	SET @date1 = @start_date --ვიწყებთ სარგებლის გადაანგარიშებას სულ თავიდან
	SET @avg_intrate = @new_intrate

	IF @perc_flags & @pfDontIncludeStartDate <> 0 -- თუ @date1 არის ანაბრის გახსნის თარიღი და პირველი დღე არ ითვლება მაშინ ვიწყებთ დარიცხვებს შემდეგი დღიდან
		SET @date1 = @date1 + 1

	OPEN cc
	FETCH NEXT FROM cc INTO @date2, @amount

	WHILE @@FETCH_STATUS = 0
	BEGIN
		
		EXEC dbo.depo_sp_get_deposit_accumulate_intrate
			@depo_id = @depo_id,
			@op_date = @date2,
			@date_type = @date_type,
			@end_date = @end_date,
			@iso = @iso,
			@intrate_schema = @new_intrate_schema,
			@period = @depo_period OUTPUT,
			@intrate = @intrate OUTPUT,
			@return_row = 0

		SET @real_formula = dbo.depo_fn_get_formula_accrue(@depo_id, @amount, @intitial_amount, @avg_intrate, @intrate)
		SET @avg_intrate = dbo.depo_fn_get_formula_accrue_value(@amount, @intitial_amount, @avg_intrate, @intrate)
		SET @intitial_amount = @intitial_amount + @amount
		SET @date1 = @date2 + 1

		FETCH NEXT FROM cc INTO @date2, @amount
	END

	CLOSE cc
	DEALLOCATE cc	

	UPDATE dbo.DEPO_DEPOSITS WITH(UPDLOCK)
	SET REAL_INTRATE = @avg_intrate,
		FORMULA = @formula	
	WHERE DEPO_ID = @depo_id
	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('ERROR CHANGE DEPOSIT DATA', 16, 1); RETURN (1); END
		
	INSERT INTO dbo.ACC_CHANGES (ACC_ID, [USER_ID], DESCRIP)
	VALUES (@depo_acc_id, @user_id, 'ÀÍÂÀÒÉÛÉÓ ÛÄÝÅËÀ : UID ÊÒÄÃ.ÃÀÒÉÝáÅÀ (ÀÍÀÁÒÆÄ პÐÉÒÏÁÉÓ ÃÀÒÙÅÄÅÉÓ ÂÀÌÏ ÓÀÐÒÏÝÄÍÔÏ ÂÀÍÀÊÅÄÈÉÓ ÓØÄÌÉÓ ÛÄÝÅËÀ)')
	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('ERROR UPDATE ACCOUNT CHANGES', 16, 1); RETURN (1); END

	SET @rec_id = SCOPE_IDENTITY()

	INSERT INTO dbo.ACCOUNTS_ARC
	SELECT @rec_id, *
	FROM dbo.ACCOUNTS
	WHERE ACC_ID = @depo_acc_id
	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('ERROR UPDATE ACCOUNT ARC', 16, 1); RETURN (1); END

	UPDATE dbo.ACCOUNTS WITH (UPDLOCK)
	SET [UID] = [UID] + 1
	WHERE ACC_ID = @depo_acc_id
	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('ERROR UPDATE ACCOUNT DATA', 16, 1); RETURN (1); END

	INSERT INTO dbo.ACCOUNTS_CRED_PERC_ARC
	SELECT @rec_id, *
	FROM dbo.ACCOUNTS_CRED_PERC
	WHERE ACC_ID = @depo_acc_id
	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('ERROR UPDATE ACCOUNT CRED PERC ARC', 16, 1); RETURN (1); END

	UPDATE dbo.ACCOUNTS_CRED_PERC WITH(UPDLOCK)
	SET FORMULA = ISNULL(@real_formula, @formula)
	WHERE ACC_ID = @depo_acc_id
	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('ERROR CHANGE ACCOUNTS_CRED_PERC FORMULA', 16, 1); RETURN (1); END

END
ELSE
IF @op_type = dbo.depo_fn_const_op_change_depo_realize_account()
BEGIN
	DECLARE
		@new_depo_realize_acc_id int,
		@change_interest_realize_acc bit

	SELECT @new_depo_realize_acc_id = NEW_DEPO_REALIZE_ACC_ID, @change_interest_realize_acc = CHANGE_INTEREST_REALIZE_ACC
	FROM dbo.DEPO_VW_OP_DATA_CHANGE_DEPO_REALIZE_ACCOUNT
	WHERE OP_ID  = @op_id
	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR('<ERR>ERROR OP DATA NOT FOUND!</ERR>', 16, 1); RETURN (1); END

	UPDATE dbo.DEPO_DEPOSITS WITH (ROWLOCK, UPDLOCK)
	SET DEPO_REALIZE_ACC_ID = @new_depo_realize_acc_id
	WHERE DEPO_ID = @depo_id
	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR('<ERR>ERROR UPDATING DEPOSIT REALIZE ACCOUNT</ERR>', 16, 1); RETURN (1); END

	IF @change_interest_realize_acc = 1
	BEGIN
		INSERT INTO dbo.ACC_CHANGES (ACC_ID, [USER_ID], DESCRIP)
		VALUES (@depo_acc_id, @user_id, 'ÀÍÂÀÒÉÛÉÓ ÛÄÝÅËÀ : UID ÃÀÒÉÝáÅÀ ÊÒÄÃÉÔÖË ÍÀÛÈÆÄ')
		IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR UPDATE ACCOUNT CHANGES</ERR>', 16, 1); RETURN (1); END

		SET @rec_id = SCOPE_IDENTITY()
		
		INSERT INTO dbo.ACCOUNTS_ARC
		SELECT @rec_id, *
		FROM dbo.ACCOUNTS
		WHERE ACC_ID = @depo_acc_id
		IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR UPDATE ACCOUNT ARC</ERR>', 16, 1); RETURN (1); END

		UPDATE dbo.ACCOUNTS WITH (ROWLOCK, UPDLOCK)
		SET [UID] = [UID] + 1
		WHERE ACC_ID = @depo_acc_id
		IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR UPDATE ACCOUNT DATA</ERR>', 16, 1); RETURN (1); END

		INSERT INTO dbo.ACCOUNTS_CRED_PERC_ARC
		SELECT @rec_id, *
		FROM dbo.ACCOUNTS_CRED_PERC
		WHERE ACC_ID = @depo_acc_id
		IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR UPDATE ACCOUNT CRED PERC ARC</ERR>', 16, 1); RETURN (1); END

		UPDATE dbo.ACCOUNTS_CRED_PERC WITH (ROWLOCK, UPDLOCK)
		SET CLIENT_ACCOUNT = @new_depo_realize_acc_id,
			INTEREST_REALIZE_ACC_ID = @new_depo_realize_acc_id
		WHERE ACC_ID = @depo_acc_id
		IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR UPDATE ACCOUNT CRED PERC ARC</ERR>', 16, 1); RETURN (1); END

		UPDATE dbo.DEPO_DEPOSITS WITH (ROWLOCK, UPDLOCK)
		SET INTEREST_REALIZE_ACC_ID = @new_depo_realize_acc_id
		WHERE DEPO_ID = @depo_id
		IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR('<ERR>ERROR UPDATING INTEREST REALIZE ACCOUNT</ERR>', 16, 1); RETURN (1); END
	END
END
IF @op_type = dbo.depo_fn_const_op_change_interest_realize_account()
BEGIN
	DECLARE
		@new_interest_realize_acc_id int

	SELECT @new_interest_realize_acc_id = NEW_INTEREST_REALIZE_ACC_ID
	FROM dbo.DEPO_VW_OP_DATA_CHANGE_INTEREST_REALIZE_ACCOUNT
	WHERE OP_ID  = @op_id
	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR('<ERR>ERROR OP DATA NOT FOUND!</ERR>', 16, 1); RETURN (1); END

	INSERT INTO dbo.ACC_CHANGES (ACC_ID, [USER_ID], DESCRIP)
	VALUES (@depo_acc_id, @user_id, 'ÀÍÂÀÒÉÛÉÓ ÛÄÝÅËÀ : UID ÃÀÒÉÝáÅÀ ÊÒÄÃÉÔÖË ÍÀÛÈÆÄ')
	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR UPDATE ACCOUNT CHANGES</ERR>', 16, 1); RETURN (1); END

	SET @rec_id = SCOPE_IDENTITY()
	
	INSERT INTO dbo.ACCOUNTS_ARC
	SELECT @rec_id, *
	FROM dbo.ACCOUNTS
	WHERE ACC_ID = @depo_acc_id
	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR UPDATE ACCOUNT ARC</ERR>', 16, 1); RETURN (1); END

	UPDATE dbo.ACCOUNTS WITH (ROWLOCK, UPDLOCK)
	SET [UID] = [UID] + 1
	WHERE ACC_ID = @depo_acc_id
	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR UPDATE ACCOUNT DATA</ERR>', 16, 1); RETURN (1); END

	INSERT INTO dbo.ACCOUNTS_CRED_PERC_ARC
	SELECT @rec_id, *
	FROM dbo.ACCOUNTS_CRED_PERC
	WHERE ACC_ID = @depo_acc_id
	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR UPDATE ACCOUNT CRED PERC ARC</ERR>', 16, 1); RETURN (1); END

	UPDATE dbo.ACCOUNTS_CRED_PERC WITH (ROWLOCK, UPDLOCK)
	SET CLIENT_ACCOUNT = @new_interest_realize_acc_id,
		INTEREST_REALIZE_ACC_ID = @new_interest_realize_acc_id
	WHERE ACC_ID = @depo_acc_id
	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR UPDATE ACCOUNT CRED PERC ARC</ERR>', 16, 1); RETURN (1); END

	UPDATE dbo.DEPO_DEPOSITS WITH (ROWLOCK, UPDLOCK)
	SET INTEREST_REALIZE_ACC_ID = @new_interest_realize_acc_id
	WHERE DEPO_ID = @depo_id
	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR('<ERR>ERROR UPDATING DEPOSIT REALIZE ACCOUNT</ERR>', 16, 1); RETURN (1); END
END
ELSE
IF @op_type = dbo.depo_fn_const_op_shareable_change()
BEGIN
	DECLARE
		@new_shareable bit,
		@new_shared_control_client_no int,
		@new_shared_control bit

	SELECT @new_shareable = SHAREABLE, @new_shared_control_client_no = SHARED_CONTROL_CLIENT_NO, 
		@new_shared_control = SHARED_CONTROL
	FROM dbo.DEPO_VW_OP_DATA_CHANGE_SHAREABLE
	WHERE OP_ID  = @op_id
	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR('<ERR>ERROR OP DATA NOT FOUND!</ERR>', 16, 1); RETURN (1); END

	UPDATE dbo.DEPO_DEPOSITS WITH(ROWLOCK, UPDLOCK)
	SET SHAREABLE = @new_shareable, 
		SHARED_CONTROL_CLIENT_NO = @new_shared_control_client_no, 
		SHARED_CONTROL = @new_shared_control
	WHERE DEPO_ID = @depo_id
	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR('<ERR>ERROR UPDATE DEPOSITS!</ERR>', 16, 1); RETURN (1); END

END
IF @op_type = dbo.depo_fn_const_op_renew()
BEGIN
	DECLARE		
		@renew_start_date smalldatetime,
		@renew_period int,
		@renew_end_date smalldatetime,
		@renew_agreement_amount money,
		@renew_intrate money,		
		@generate_new_schedule bit,
		
		@acc_change_descrip varchar(300)

	SELECT  @renew_start_date = [START_DATE], @renew_period = PERIOD, @renew_end_date = END_DATE, @renew_agreement_amount = AGREEMENT_AMOUNT,
		@renew_intrate = INTRATE, @renew_count = RENEW_COUNT, @generate_new_schedule = GENERATE_NEW_SCHEDULE
	FROM dbo.DEPO_VW_OP_DATA_RENEW
	WHERE OP_ID  = @op_id
	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR('<ERR>ERROR OP DATA NOT FOUND!</ERR>', 16, 1); RETURN (1); END

	SET @acc_change_descrip = 'ÀÍÂÀÒÉÛÉÓ ÛÄÝÅËÀ : UID'

	IF @end_date IS NOT NULL
	BEGIN
		SET @acc_change_descrip = @acc_change_descrip + ' PERIOD'
		IF ISNULL(@spend_amount, $0.00) <> $0.00
			SET @acc_change_descrip = @acc_change_descrip + ' MIN_AMOUNT_CHECK_DATE'
	END
	SET @acc_change_descrip = @acc_change_descrip + ' (ÀÍÀÁÒÉÓ ÂÀÍÀáËÄÁÀ)'

	INSERT INTO dbo.ACC_CHANGES (ACC_ID, [USER_ID], DESCRIP)
	VALUES (@depo_acc_id, @user_id, @acc_change_descrip)
	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR UPDATE ACCOUNT CHANGES</ERR>', 16, 1); RETURN (1); END

	SET @rec_id = SCOPE_IDENTITY()
	
	INSERT INTO dbo.ACCOUNTS_ARC
	SELECT @rec_id, *
	FROM dbo.ACCOUNTS
	WHERE ACC_ID = @depo_acc_id
	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR UPDATE ACCOUNT ARC</ERR>', 16, 1); RETURN (1); END

	UPDATE dbo.ACCOUNTS WITH (ROWLOCK, UPDLOCK)
	SET [UID] = [UID] + 1,
		PERIOD = CASE WHEN @end_date IS NOT NULL THEN @renew_end_date ELSE PERIOD END,
		MIN_AMOUNT_CHECK_DATE = CASE WHEN ISNULL(@spend_amount, $0.00) <> $0.00 THEN @renew_end_date ELSE MIN_AMOUNT_CHECK_DATE END
	WHERE ACC_ID = @depo_acc_id
	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR UPDATE ACCOUNT DATA</ERR>', 16, 1); RETURN (1); END

	SET @op_acc_data = (SELECT * FROM ACCOUNTS_CRED_PERC WHERE ACC_ID = @depo_acc_id FOR XML RAW, TYPE)
	UPDATE dbo.DEPO_OP WITH (ROWLOCK, UPDLOCK)
	SET OP_ACC_DATA = @op_acc_data
	WHERE OP_ID = @op_id
	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR UPDATE OP DATA</ERR>', 16, 1); RETURN (1); END

	INSERT INTO dbo.ACCOUNTS_CRED_PERC_ARC
	SELECT @rec_id, *
	FROM dbo.ACCOUNTS_CRED_PERC
	WHERE ACC_ID = @depo_acc_id
	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR UPDATE ACCOUNT CRED PERC ARC</ERR>', 16, 1); RETURN (1); END

	UPDATE dbo.DEPO_DEPOSITS  WITH (ROWLOCK, UPDLOCK)
	SET END_DATE = @renew_end_date,
		AGREEMENT_AMOUNT = @renew_agreement_amount,
		AMOUNT = @renew_agreement_amount,
		INTRATE = @renew_intrate,
		REAL_INTRATE = @renew_intrate,
		SPEND_CONST_AMOUNT = CASE WHEN SPEND_CONST_AMOUNT IS NULL THEN NULL ELSE @renew_agreement_amount END,
		RENEW_COUNT = @renew_count,
		LAST_RENEW_DATE = @renew_start_date
	WHERE DEPO_ID = @depo_id
	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR('<ERR>ERROR UPDATING DEPOSIT DATA</ERR>', 16, 1); RETURN (1); END
	
	SET @formula = dbo.depo_fn_get_formula(@depo_id, @op_id)
	
	UPDATE dbo.DEPO_DEPOSITS  WITH (ROWLOCK, UPDLOCK)
	SET FORMULA = @formula
	WHERE DEPO_ID = @depo_id
	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR('<ERR>ERROR UPDATING DEPOSIT DATA</ERR>', 16, 1); RETURN (1); END	
	
	UPDATE dbo.ACCOUNTS_CRED_PERC WITH (ROWLOCK, UPDLOCK)
	SET [START_DATE] = @renew_start_date,
		END_DATE = @renew_end_date,
		FORMULA = @formula,
		CALC_AMOUNT = NULL,
		TOTAL_CALC_AMOUNT = NULL,
		TOTAL_PAYED_AMOUNT = NULL,
		LAST_CALC_DATE = NULL,
		LAST_MOVE_DATE = NULL,
		DEPO_REALIZE_AMOUNT = NULL,
		INTEREST_REALIZE_AMOUNT = NULL,
		ADVANCE_AMOUNT = NULL,
		MIN_PROCESSING_DATE = NULL,
		MIN_PROCESSING_TOTAL_CALC_AMOUNT = NULL,
		TOTAL_TAX_PAYED_AMOUNT = NULL,
		TOTAL_TAX_PAYED_AMOUNT_EQU = NULL
	WHERE ACC_ID = @depo_acc_id
	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR UPDATE ACCOUNT CRED PERC ARC</ERR>', 16, 1); RETURN (1); END

	IF @generate_new_schedule = 1
	BEGIN
		DECLARE @depo_schedule_new TABLE(	SCHEDULE_DATE smalldatetime NOT NULL,
											PAYMENT money NOT NULL,	PRINCIPAL money NOT NULL,
											INTEREST money NOT NULL,
											INTEREST_TAX money NOT NULL,
											TAX money NOT NULL,
											BALANCE money NULL )

		INSERT INTO dbo.DEPO_SCHEDULE_ARC
		SELECT @op_id, * 
		FROM dbo.DEPO_SCHEDULE (NOLOCK)
		WHERE DEPO_ID = @depo_id
		IF @@ERROR <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR UPDATE DEPO SCHEDULE ARC</ERR>', 16, 1); RETURN (1); END

		DELETE FROM dbo.DEPO_SCHEDULE
		WHERE DEPO_ID = @depo_id
		IF @@ERROR <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR DELETE DEPO SCHEDULE</ERR>', 16, 1); RETURN (1); END
											
		INSERT INTO @depo_schedule_new
		EXEC @r = dbo.depo_sp_get_depo_reailze_schedule
			@depo_amount = @renew_agreement_amount,
			@start_date = @renew_start_date,
			@end_date = @renew_end_date,
			@date = @renew_start_date,
			@intrate = @renew_intrate,
			@prod_id = @prod_id,
			@tax_rate = @tax_rate,
			@result_type = 1
		IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR UPDATE NEW DEPO SCHEDULE</ERR>', 16, 1); RETURN (1); END

		INSERT INTO dbo.DEPO_SCHEDULE
		SELECT @depo_id, *
		FROM @depo_schedule_new
		IF @@ERROR <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR UPDATE DEPO SCHEDULE</ERR>', 16, 1); RETURN (1); END

	END
END
ELSE
IF @op_type = dbo.depo_fn_const_op_convert()
BEGIN
	DECLARE
		@accrue_amount money,
		@accrue_amount_equ money
	DECLARE
		@depo_acc_exists bit,
		@conv_op_id int

	SET @depo_acc_exists = 1
	
	SELECT @intrate = INTRATE, @depo_realize_acc_id = DEPO_REALIZE_ACC_ID, @interest_realize_acc_id = INTEREST_REALIZE_ACC_ID
	FROM dbo.DEPO_VW_OP_DATA_CONVERT
	WHERE OP_ID = @op_id
	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR('<ERR>OPERATION DATA NOT FOUND</ERR>', 16, 1); RETURN (1); END

	SELECT @accrue_amount = ROUND(ISNULL(TOTAL_CALC_AMOUNT, $0.00), 2)
	FROM dbo.ACCOUNTS_CRED_PERC
	WHERE ACC_ID = @depo_acc_id
	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR ACCOUNT CRED PERC NOT FOUND</ERR>', 16, 1); RETURN (1); END

	/*EXEC @r = dbo.GET_CROSS_AMOUNT
		@iso1 = @iso,
		@iso2 = @op_iso,
		@amount = @accrue_amount,
		@dt = @op_date,
		@new_amount = @accrue_amount_equ OUTPUT*/
		
	EXEC dbo.depo_sp_get_convert_amount
		@client_no = @client_no,
		@iso1 = @iso,
		@iso2 = @op_iso,
		@amount = @accrue_amount,
		@new_amount = @accrue_amount_equ OUTPUT
		
	IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ÛÄÝÃÏÌÀ ÃÀÒÉÝáÖËÉ ÓÀÒÂÄÁËÉÓ ÊÏÍÅÄÒÔÉÒÄÁÉÓÀÓ!</ERR>', 16, 1); RETURN (1); END

	INSERT INTO dbo.ACC_CHANGES (ACC_ID, [USER_ID], DESCRIP)
	VALUES (@depo_acc_id, @user_id, 'ÀÍÂÀÒÉÛÉÓ ÛÄÝÅËÀ : UID REC_STATE ÊÒÄÃ.ÃÀÒÉÝáÅÀ (ÀÍÀÁÒÉÓ ÊÏÍÅÄÒÔÀÝÉÀ ÓáÅÀ ÅÀËÖÔÀÛÉ)')
	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR UPDATE ACCOUNT CHANGES</ERR>', 16, 1); RETURN (1); END

	SET @rec_id = SCOPE_IDENTITY()
	
	INSERT INTO dbo.ACCOUNTS_ARC
	SELECT @rec_id, *
	FROM dbo.ACCOUNTS
	WHERE ACC_ID = @depo_acc_id
	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR UPDATE ACCOUNT ARC</ERR>', 16, 1); RETURN (1); END

	UPDATE dbo.ACCOUNTS WITH (ROWLOCK, UPDLOCK)
	SET [UID] = [UID] + 1, REC_STATE = 2 --ÃÀáÖÒÖËÉ
	WHERE ACC_ID = @depo_acc_id
	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR UPDATE ACCOUNT DATA</ERR>', 16, 1); RETURN (1); END

	INSERT INTO dbo.ACCOUNTS_CRED_PERC_ARC
	SELECT @rec_id, *
	FROM dbo.ACCOUNTS_CRED_PERC
	WHERE ACC_ID = @depo_acc_id
	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR UPDATE ACCOUNT CRED PERC ARC</ERR>', 16, 1); RETURN (1); END

	EXEC @r = dbo.ON_USER_AFTER_EDIT_ACC @depo_acc_id, @user_id
	IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR PROC: ON_USER_AFTER_EDIT_ACC</ERR>', 16, 1); RETURN (1); END

	SET @real_intrate = @intrate

	DECLARE
		@depo_account TACCOUNT,
		@depo_acc_id_1 int,
		@loss_acc_id_1 int,
		@accrual_acc_id_1 int,
		@formula_2 varchar(255),
		@calc_amount_2 money,
		@total_calc_amount_2 money,
		@last_calc_date_2 smalldatetime,
		@min_processing_date_2 smalldatetime,
		@min_processing_total_calc_amount_2 money

	SET @depo_acc_id_1 = @depo_acc_id
	SET @loss_acc_id_1 = @loss_acc_id
	SET @accrual_acc_id_1 = @accrual_acc_id
 
	SET @depo_account = dbo.acc_get_account(@depo_acc_id)
	
	SET @depo_acc_id = NULL
	SET @loss_acc_id = NULL
	SET @accrual_acc_id = NULL

	SELECT TOP 1 @conv_op_id = OP_ID, @depo_acc_id = DEPO_ACC_ID, @loss_acc_id = LOSS_ACC_ID, @accrual_acc_id = ACCRUAL_ACC_ID 
	FROM dbo.DEPO_DEPOSITS_HISTORY
	WHERE DEPO_ID = @depo_id AND ISO = @op_iso
	ORDER BY OP_ID DESC

	UPDATE dbo.DEPO_DEPOSITS WITH (ROWLOCK, UPDLOCK)
	SET	ISO = @op_iso,
		AGREEMENT_AMOUNT = @op_amount,
		AMOUNT = @op_amount,
		INTRATE = @intrate,
		REAL_INTRATE = @real_intrate
	WHERE DEPO_ID = @depo_id
	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR('<ERR>ERROR UPDATING DEPOSIT DATA</ERR>', 16, 1); RETURN (1); END

	SET @formula = dbo.depo_fn_get_formula(@depo_id, default)
	IF @@ERROR <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR GENERATE FORMULA</ERR>', 16, 1); RETURN (1); END
	
	IF @depo_acc_id IS NULL
	BEGIN
		SET @depo_acc_exists = 0

		EXEC @r = dbo.depo_sp_add_account_deposit
			@depo_id = @depo_id,
			@user_id = @user_id,
			@op_date = @op_date,
			@depo_account = @depo_account,
			@acc_id = @depo_acc_id OUTPUT,
			@bal_acc = @depo_bal_acc OUTPUT
		IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR('<ERR>ÛÄÝÃÏÌÀ ÃÄÐÏÆÉÔÉÓ ÀÍÂÀÒÉÛÉÓ ÂÀáÓÍÉÓÀÓ</ERR>', 16, 1); RETURN (1); END

		EXEC @r = dbo.depo_sp_add_account_loss
			@depo_id = @depo_id,
			@user_id = @user_id,
			@op_date = @op_date,
			@depo_bal_acc = @depo_bal_acc,
			@acc_id = @loss_acc_id OUTPUT
		IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR('<ERR>ÛÄÝÃÏÌÀ ÃÄÐÏÆÉÔÉÓ ÀÍÂÀÒÉÛÉÓ ÂÀáÓÍÉÓÀÓ</ERR>', 16, 1); RETURN (1); END

		EXEC @r = dbo.depo_sp_add_account_accrual
			@depo_id = @depo_id,
			@user_id = @user_id,
			@op_date = @op_date,
			@depo_bal_acc = @depo_bal_acc,
			@acc_id = @accrual_acc_id OUTPUT
		IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR('<ERR>ÛÄÝÃÏÌÀ ÃÄÐÏÆÉÔÉÓ ÀÍÂÀÒÉÛÉÓ ÂÀáÓÍÉÓÀÓ</ERR>', 16, 1); RETURN (1); END
	END
	
	IF @interest_realize_acc_id = 0
	BEGIN
		SET @interest_realize_acc_id = @depo_acc_id 
		SET @op_data.modify('replace value of (//@INTEREST_REALIZE_ACC_ID)[1] with sql:variable("@interest_realize_acc_id")')	  

		UPDATE dbo.DEPO_OP WITH (ROWLOCK, UPDLOCK)
		SET OP_DATA = @op_data
		WHERE OP_ID = @op_id
		IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR UPDATE OP DATA</ERR>', 16, 1); RETURN (1); END
	 END

	UPDATE dbo.DEPO_DEPOSITS WITH (ROWLOCK, UPDLOCK)
	SET	FORMULA = @formula,
		DEPO_ACC_ID = @depo_acc_id,
		LOSS_ACC_ID = @loss_acc_id,
		ACCRUAL_ACC_ID = @accrual_acc_id,
		DEPO_REALIZE_ACC_ID = @depo_realize_acc_id,
		INTEREST_REALIZE_ACC_ID = @interest_realize_acc_id,
		INTEREST_REALIZE_ADV = 0,
		INTEREST_REALIZE_ADV_ACC_ID = NULL
	WHERE DEPO_ID = @depo_id
	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR('<ERR>ERROR UPDATING DEPOSIT DATA</ERR>', 16, 1); RETURN (1); END

	IF (@depo_acc_exists = 0) AND EXISTS(SELECT * FROM dbo.ACCOUNTS_CRED_PERC (NOLOCK) WHERE ACC_ID = @depo_acc_id) 
	BEGIN
		IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK;
		RAISERROR('<ERR>ÀÍÀÁÒÉÓ ÀÍÂÀÒÉÛÆÄ ÃÀÊÀÅÛÉÒÄÁÖËÉÀ ÊÒÄÃÉÔÖË ÍÀÛÈÆÄ ÃÀÒÉÝáÅÉÓ ÓØÄÌÀ!</ERR>', 16, 1) 
		RETURN (1)
	END

	IF @depo_acc_exists = 0
	BEGIN 
		INSERT INTO dbo.ACCOUNTS_CRED_PERC
			(ACC_ID, [START_DATE], END_DATE, MOVE_COUNT, MOVE_COUNT_TYPE, CALC_TYPE, FORMULA,
			CLIENT_ACCOUNT, PERC_CLIENT_ACCOUNT, PERC_BANK_ACCOUNT, DAYS_IN_YEAR, PERC_FLAGS, PERC_TYPE, TAX_RATE,
			DEPO_ID, RECALCULATE_TYPE, DEPO_REALIZE_ACC_ID, INTEREST_REALIZE_ACC_ID,
			DEPO_REALIZE_AMOUNT, INTEREST_REALIZE_AMOUNT, ADVANCE_ACC_ID, ADVANCE_AMOUNT)
		VALUES
			(@depo_acc_id, @op_date, @end_date, @realize_count, @realize_count_type, @accrue_type, @formula,
			@interest_realize_acc_id, @accrual_acc_id, @loss_acc_id, @days_in_year, @perc_flags, @realize_type, @tax_rate,
			@depo_id, @recalculate_type, @depo_realize_acc_id, @interest_realize_acc_id,
			NULL, NULL, NULL, NULL)
		IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR('<ERR>ERROR INSERT ACCOUNT SCHEMA!</ERR>', 16, 1); RETURN (1); END
	END
	ELSE
	BEGIN
		INSERT INTO dbo.ACC_CHANGES (ACC_ID, [USER_ID], DESCRIP)
		VALUES (@depo_acc_id, @user_id, 'ÀÍÂÀÒÉÛÉÓ ÛÄÝÅËÀ : UID REC_STATE ÊÒÄÃ.ÃÀÒÉÝáÅÀ (ÀÍÀÁÒÉÓ ÊÏÍÅÄÒÔÀÝÉÀ ÓáÅÀ ÅÀËÖÔÀÛÉ)')
		IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR UPDATE ACCOUNT CHANGES</ERR>', 16, 1); RETURN (1); END

		SET @rec_id = SCOPE_IDENTITY()

		--SET @op_acc_data.modify('replace value of (//@ARC_REC_ID2)[1] with sql:variable("@rec_id")')
		
		INSERT INTO dbo.ACCOUNTS_ARC
		SELECT @rec_id, *
		FROM dbo.ACCOUNTS
		WHERE ACC_ID = @depo_acc_id
		IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR UPDATE ACCOUNT ARC</ERR>', 16, 1); RETURN (1); END

		UPDATE dbo.ACCOUNTS WITH (ROWLOCK, UPDLOCK)
		SET [UID] = [UID] + 1, REC_STATE = @acc_rec_state
		WHERE ACC_ID = @depo_acc_id
		IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR UPDATE ACCOUNT DATA</ERR>', 16, 1); RETURN (1); END

		INSERT INTO dbo.ACCOUNTS_CRED_PERC_ARC
		SELECT @rec_id, *
		FROM dbo.ACCOUNTS_CRED_PERC
		WHERE ACC_ID = @depo_acc_id
		IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR UPDATE ACCOUNT CRED PERC ARC</ERR>', 16, 1); RETURN (1); END

		SELECT @formula_2 = FORMULA, @calc_amount_2 = CALC_AMOUNT, @total_calc_amount_2 = TOTAL_CALC_AMOUNT, @last_calc_date_2 = LAST_CALC_DATE,
			@min_processing_date_2 = MIN_PROCESSING_DATE, @min_processing_total_calc_amount_2 = MIN_PROCESSING_TOTAL_CALC_AMOUNT
		FROM dbo.ACCOUNTS_CRED_PERC
		WHERE ACC_ID = @depo_acc_id
		IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR GET ACCOUNT CRED PERC DATA</ERR>', 16, 1); RETURN (1); END

		UPDATE dbo.ACCOUNTS_CRED_PERC
		SET FORMULA = @formula
		WHERE ACC_ID = @depo_acc_id
		IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR UPDATE CRED PERC DATA</ERR>',16,1); RETURN (1); END


		EXEC @r = dbo.ON_USER_AFTER_EDIT_ACC @depo_acc_id, @user_id
		IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR PROC: ON_USER_AFTER_EDIT_ACC</ERR>', 16, 1); RETURN (1); END
	END

	SET @op_acc_data =
		(SELECT
			@iso AS ISO,
			@amount AS AMOUNT,
			@depo_acc_id_1 AS DEPO_ACC_ID,
			@loss_acc_id_1 AS LOSS_ACC_ID,
			@accrual_acc_id_1 AS ACCRUAL_ACC_ID,
			@accrue_amount AS ACCRUE_AMOUNT,
			@accrue_amount_equ AS ACCRUE_AMOUNT_EQU,
			@calc_amount_1 AS CALC_AMOUNT_1,
			@total_calc_amount_1 AS TOTAL_CALC_AMOUNT_1,
			@min_processing_date_1 AS MIN_PROCESSING_DATE_1,
			@min_processing_total_calc_amount_1 AS MIN_PROCESSING_TOTAL_CALC_AMOUNT_1,
			@formula_2 AS FORMULA_2,
			@calc_amount_2 AS CALC_AMOUNT_2,
			@total_calc_amount_2 AS TOTAL_CALC_AMOUNT_2,
			@last_calc_date_2 AS LAST_CALC_DATE_2,
			@min_processing_date_2 AS MIN_PROCESSING_DATE_2,
			@min_processing_total_calc_amount_2 AS MIN_PROCESSING_TOTAL_CALC_AMOUNT_2
	FOR XML RAW, TYPE)	

	UPDATE dbo.DEPO_OP WITH (ROWLOCK, UPDLOCK)
	SET OP_ACC_DATA = @op_acc_data
	WHERE OP_ID = @op_id
	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR UPDATE OP DATA</ERR>', 16, 1); RETURN (1); END
END
ELSE
IF @op_type = dbo.depo_fn_const_op_change_officer()
BEGIN
	DECLARE @new_responsible_user_id int

	SELECT @new_responsible_user_id = NEW_RESPONSIBLE_USER_ID
	FROM dbo.DEPO_VW_OP_DATA_CHANGE_OFFICER
	WHERE OP_ID = @op_id
	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>OP DATA NOT FOUND</ERR>', 16, 1); RETURN (1); END  

	UPDATE dbo.DEPO_DEPOSITS
	SET RESPONSIBLE_USER_ID = @new_responsible_user_id
	WHERE DEPO_ID = @depo_id
	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR UPDATING DEPOSIT DATA</ERR>', 16, 1); RETURN (1); END
END
ELSE
IF @op_type = dbo.depo_fn_const_op_block_amount()
BEGIN
	DECLARE
		@depo_blocked_by_product varchar(20),
		@depo_block_reason varchar(255), 
		@depo_acc_block_id int

	SELECT @depo_blocked_by_product = BLOCKED_BY_PRODUCT, @depo_block_reason = BLOCK_REASON
	FROM dbo.DEPO_VW_OP_DATA_BLOCK_AMOUNT
	WHERE OP_ID = @op_id
	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>DEPO ACTIVE DATA NOT FOUND</ERR>', 16, 1); RETURN (1); END

	EXEC @r = dbo.acc_block_amount
		@acc_id = @depo_acc_id,
		@iso = @iso,
		@amount = @op_amount,
		@fee = $0.00,
		@user_id = @user_id,
		@product_id = @depo_blocked_by_product,
		@auto_unblock_date = NULL,
		@user_data = @depo_id,
		@block_id = @depo_acc_block_id OUTPUT
	IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ÛÄÝÃÏÌÀ ÀÍÀÁÀÒÆÄ ÈÀÍáÉÓ ÁËÏÊÉÒÄÁÉÓÀÓ!</ERR>', 16, 1); RETURN (1); END	

	SET @op_data.modify('replace value of (//@BLOCK_ID)[1] with sql:variable("@depo_acc_block_id")')

	UPDATE dbo.DEPO_OP WITH (ROWLOCK, UPDLOCK)
	SET OP_DATA = @op_data
	WHERE OP_ID = @op_id
	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR UPDATE OP DATA</ERR>', 16, 1); RETURN (1); END
END
ELSE
IF @op_type = dbo.depo_fn_const_op_clear_block_amount()
BEGIN
	DECLARE
		@depo_acc_clear_block_id int

	SELECT @depo_acc_clear_block_id = BLOCK_ID
	FROM dbo.DEPO_VW_OP_DATA_CLEAR_BLOCK_AMOUNT
	WHERE OP_ID = @op_id
	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>OP DATA NOT FOUND</ERR>', 16, 1); RETURN (1); END

	EXEC @r = dbo.acc_unblock_amount_by_id
		@acc_id = @depo_acc_id,
		@block_id = @depo_acc_clear_block_id,
		@user_id = @user_id,
		@doc_rec_id = NULL
	IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ÛÄÝÃÏÌÀ ÀÍÀÁÀÒÆÄ ÈÀÍáÉÓ ÁËÏÊÉÒÄÁÉÓÀÓ!</ERR>', 16, 1); RETURN (1); END	
END
ELSE
IF @op_type = dbo.depo_fn_const_op_break_renew()
BEGIN
	SELECT @prolongable = PROLONGABLE, @renewable = RENEWABLE
	FROM dbo.DEPO_VW_OP_DATA_BREAK_RENEW
	WHERE OP_ID = @op_id
	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>OP DATA NOT FOUND</ERR>', 16, 1); RETURN (1); END  

	UPDATE dbo.DEPO_DEPOSITS WITH (ROWLOCK, UPDLOCK)
	SET PROLONGABLE = @prolongable, RENEWABLE = @renewable
	WHERE DEPO_ID = @depo_id
	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR UPDATING DEPOSIT DATA</ERR>', 16, 1); RETURN (1); END
END
ELSE
IF @op_type = dbo.depo_fn_const_op_resume_renew()
BEGIN
	SELECT @prolongable = PROLONGABLE, @renewable = RENEWABLE
	FROM dbo.DEPO_VW_OP_DATA_RESUME_RENEW
	WHERE OP_ID = @op_id
	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>OP DATA NOT FOUND</ERR>', 16, 1); RETURN (1); END  

	UPDATE dbo.DEPO_DEPOSITS WITH (ROWLOCK, UPDLOCK)
	SET PROLONGABLE = @prolongable, RENEWABLE = @renewable
	WHERE DEPO_ID = @depo_id
	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR UPDATING DEPOSIT DATA</ERR>', 16, 1); RETURN (1); END
END
IF @op_type = dbo.depo_fn_const_op_allow_renew()
BEGIN
	SELECT @renewable = RENEWABLE, @renew_capitalized = RENEW_CAPITALIZED, @renew_max = RENEW_MAX,
		@renew_count = RENEW_COUNT, @renew_last_prod_id = RENEW_LAST_PROD_ID, @last_renew_date = LAST_RENEW_DATE
	FROM dbo.DEPO_VW_OP_DATA_ALLOW_RENEW
	WHERE OP_ID = @op_id
	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>OP DATA NOT FOUND</ERR>', 16, 1); RETURN (1); END  

	UPDATE dbo.DEPO_DEPOSITS WITH (ROWLOCK, UPDLOCK)
	SET RENEWABLE=@renewable,
		RENEW_CAPITALIZED = @renew_capitalized,
		RENEW_MAX = @renew_max,
		RENEW_COUNT = @renew_count,
		RENEW_LAST_PROD_ID = @renew_last_prod_id,
		LAST_RENEW_DATE = @last_renew_date
	WHERE DEPO_ID = @depo_id
	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR UPDATING DEPOSIT DATA</ERR>', 16, 1); RETURN (1); END
END
ELSE
IF @op_type = dbo.depo_fn_const_op_allow_prolongation()
BEGIN
	SELECT  @prolongable = PROLONGABLE,
			@prolongation_count = PROLONGATION_COUNT
	FROM dbo.DEPO_VW_OP_DATA_ALLOW_PROLONGATION
	WHERE OP_ID = @op_id
	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>OP DATA NOT FOUND</ERR>', 16, 1); RETURN (1); END  

	UPDATE dbo.DEPO_DEPOSITS WITH (ROWLOCK, UPDLOCK)
	SET PROLONGABLE = @prolongable,
		PROLONGATION_COUNT = @prolongation_count
	WHERE DEPO_ID = @depo_id
	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR UPDATING DEPOSIT DATA</ERR>', 16, 1); RETURN (1); END
END
ELSE
IF @op_type IN (dbo.depo_fn_const_op_annulment(), dbo.depo_fn_const_op_annulment_amount(), dbo.depo_fn_const_op_close_default())
BEGIN
	SELECT @acc_min_amount = ACC_MIN_AMOUNT
	FROM dbo.DEPO_VW_OP_DATA_ACTIVE
	WHERE DEPO_ID = @depo_id
	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>DEPO ACTIVE DATA NOT FOUND</ERR>', 16, 1); RETURN (1); END

	SELECT @acc_min_amount2 = MIN_AMOUNT 
	FROM dbo.ACCOUNTS (NOLOCK)
	WHERE ACC_ID = @depo_acc_id
	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>DEPO ACCOUNT DATA NOT FOUND</ERR>', 16, 1); RETURN (1); END

		
	IF (ISNULL(@acc_min_amount, $0.00) <> $0.00) AND (ISNULL(@acc_min_amount, $0.00) = ISNULL(@acc_min_amount2, $0.00))
	BEGIN
		INSERT INTO dbo.ACC_CHANGES (ACC_ID,[USER_ID],DESCRIP) 
		VALUES (@depo_acc_id, @user_id, 'ÀÍÂÀÒÉÛÉÓ ÛÄÝÅËÀ : UID MIN_AMOUNT MIN_AMOUNT_NEW MIN_AMOUNT_CHECK_DATE')
		IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR INSERT ACCOUNT CHANGE LOG</ERR>', 16, 1); RETURN (1); END

		SET @rec_id = SCOPE_IDENTITY()

		SET @op_data.modify('replace value of (//@ACC_ARC_REC_ID)[1] with sql:variable("@rec_id")')

		UPDATE dbo.DEPO_OP WITH (ROWLOCK, UPDLOCK)
		SET OP_DATA = @op_data
		WHERE OP_ID = @op_id
		IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR UPDATE OP DATA</ERR>', 16, 1); RETURN (1); END

		INSERT INTO dbo.ACCOUNTS_ARC
		SELECT @rec_id, *
		FROM dbo.ACCOUNTS
		WHERE ACC_ID = @depo_acc_id
		IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR UPDATE ACCOUNT ARC</ERR>', 16, 1); RETURN (1); END

		UPDATE dbo.ACCOUNTS WITH (ROWLOCK, UPDLOCK)
		SET [UID] = [UID] + 1,
			MIN_AMOUNT = $0.00,
			MIN_AMOUNT_NEW = $0.00,
			MIN_AMOUNT_CHECK_DATE = NULL
		WHERE ACC_ID = @depo_acc_id
		IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR UPDATE ACCOUNT DATA</ERR>', 16, 1); RETURN (1); END

		INSERT INTO dbo.ACCOUNTS_CRED_PERC_ARC
		SELECT @rec_id, *
		FROM dbo.ACCOUNTS_CRED_PERC
		WHERE ACC_ID = @depo_acc_id
		IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR UPDATE ACCOUNT CRED PERC ARC</ERR>', 16, 1); RETURN (1); END

		EXEC @r = dbo.ON_USER_AFTER_EDIT_ACC @depo_acc_id, @user_id
		IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR PROC: ON_USER_AFTER_EDIT_ACC</ERR>', 16, 1); RETURN (1); END
	END

	UPDATE dbo.DEPO_DEPOSITS WITH (ROWLOCK, UPDLOCK)
	SET [STATE] = 
			CASE @op_type
				WHEN dbo.depo_fn_const_op_annulment() THEN 240
				WHEN dbo.depo_fn_const_op_annulment_amount() THEN 241
				WHEN dbo.depo_fn_const_op_close_default() THEN 248
				ELSE NULL
			END,
		ANNULMENT_DATE = CASE WHEN @op_type = dbo.depo_fn_const_op_close_default() THEN NULL ELSE @op_date END
	WHERE DEPO_ID = @depo_id
	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR UPDATING DEPOSIT DATA</ERR>', 16, 1); RETURN (1); END
END
ELSE
IF @op_type IN (dbo.depo_fn_const_op_close(), dbo.depo_fn_const_op_annulment_positive())
BEGIN

	SELECT @acc_min_amount = ACC_MIN_AMOUNT
	FROM dbo.DEPO_VW_OP_DATA_ACTIVE
	WHERE DEPO_ID = @depo_id
	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>DEPO ACTIVE DATA NOT FOUND</ERR>', 16, 1); RETURN (1); END

	SELECT @acc_min_amount2 = MIN_AMOUNT 
	FROM dbo.ACCOUNTS (NOLOCK)
	WHERE ACC_ID = @depo_acc_id
	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>DEPO ACTIVE DATA NOT FOUND</ERR>', 16, 1); RETURN (1); END

		
	IF (ISNULL(@acc_min_amount, $0.00) <> $0.00) AND (ISNULL(@acc_min_amount, $0.00) = ISNULL(@acc_min_amount2, $0.00))
	BEGIN
		INSERT INTO dbo.ACC_CHANGES (ACC_ID,[USER_ID],DESCRIP) 
		VALUES (@depo_acc_id, @user_id, 'ÀÍÂÀÒÉÛÉÓ ÛÄÝÅËÀ : UID MIN_AMOUNT MIN_AMOUNT_NEW MIN_AMOUNT_CHECK_DATE')
		IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR INSERT ACCOUNT CHANGE LOG</ERR>', 16, 1); RETURN (1); END

		SET @rec_id = SCOPE_IDENTITY()

		SET @op_data.modify('replace value of (//@ACC_ARC_REC_ID)[1] with sql:variable("@rec_id")')

		UPDATE dbo.DEPO_OP WITH (ROWLOCK, UPDLOCK)
		SET OP_DATA = @op_data
		WHERE OP_ID = @op_id
		IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR UPDATE OP DATA</ERR>', 16, 1); RETURN (1); END

		INSERT INTO dbo.ACCOUNTS_ARC
		SELECT @rec_id, *
		FROM dbo.ACCOUNTS
		WHERE ACC_ID = @depo_acc_id
		IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR UPDATE ACCOUNT ARC</ERR>', 16, 1); RETURN (1); END

		UPDATE dbo.ACCOUNTS WITH (ROWLOCK, UPDLOCK)
		SET [UID] = [UID] + 1,
			MIN_AMOUNT = $0.00,
			MIN_AMOUNT_NEW = $0.00,
			MIN_AMOUNT_CHECK_DATE = NULL
		WHERE ACC_ID = @depo_acc_id
		IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR UPDATE ACCOUNT DATA</ERR>', 16, 1); RETURN (1); END

		INSERT INTO dbo.ACCOUNTS_CRED_PERC_ARC
		SELECT @rec_id, *
		FROM dbo.ACCOUNTS_CRED_PERC
		WHERE ACC_ID = @depo_acc_id
		IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR UPDATE ACCOUNT CRED PERC ARC</ERR>', 16, 1); RETURN (1); END

		EXEC @r = dbo.ON_USER_AFTER_EDIT_ACC @depo_acc_id, @user_id
		IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR PROC: ON_USER_AFTER_EDIT_ACC</ERR>', 16, 1); RETURN (1); END
	END

	EXEC @r = dbo.PROCESS_ACCRUAL
		@perc_type = 0,
		@acc_id = @depo_acc_id,
		@user_id = @user_id,
		@dept_no = @dept_no,
		@doc_date = @op_date,
		@calc_date = @op_date,
		@force_realization = 1,
		@simulate = 0,
		@recalc_option  = 0,
		@depo_depo_id = @depo_id,
		@depo_op_type = @op_type,
		@depo_op_id = @op_id,
		@rec_id  = @accrue_doc_rec_id OUTPUT,
		@depo_op_doc_rec_id  = @doc_rec_id OUTPUT
	IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR PROCESS ACRRUAL</ERR>', 16, 1); RETURN (1); END

	UPDATE dbo.DEPO_DEPOSITS WITH (ROWLOCK, UPDLOCK)
	SET [STATE] =
			CASE @op_type
				WHEN dbo.depo_fn_const_op_annulment_positive() THEN 245
				WHEN dbo.depo_fn_const_op_close() THEN 250
				ELSE NULL
			END,
		ANNULMENT_DATE = 
			CASE @op_type
				WHEN dbo.depo_fn_const_op_annulment_positive() THEN @op_date
				WHEN dbo.depo_fn_const_op_close() THEN NULL
				ELSE NULL
			END
	WHERE DEPO_ID = @depo_id
	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR UPDATING DEPOSIT DATA</ERR>', 16, 1); RETURN (1); END
END

EXEC @r = dbo.depo_sp_exec_op_accounting @doc_rec_id = @doc_rec_id OUTPUT, @accrue_doc_rec_id = @accrue_doc_rec_id OUTPUT, @user_id = @user_id, @op_id = @op_id
IF @@ERROR <> 0 OR @r <> 0 BEGIN SET @doc_rec_id = NULL; SET @accrue_doc_rec_id = NULL; IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR('<ERR>ERROR EXECUTE ACCOUNTING</ERR>', 16, 1); RETURN (1); END

UPDATE dbo.DEPO_OP WITH (ROWLOCK, UPDLOCK)
SET OP_STATE = 1, AUTH_OWNER = @user_id,
	DOC_REC_ID = CASE WHEN (@doc_rec_id IS NOT NULL) AND ISNULL(@doc_rec_id, 0) <> ISNULL(DOC_REC_ID, 0) THEN @doc_rec_id ELSE DOC_REC_ID END,
	ACCRUE_DOC_REC_ID = CASE WHEN (@accrue_doc_rec_id IS NOT NULL) AND ISNULL(@accrue_doc_rec_id, 0) <> ISNULL(ACCRUE_DOC_REC_ID, 0) THEN @accrue_doc_rec_id ELSE ACCRUE_DOC_REC_ID END
WHERE OP_ID = @op_id
IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR('<ERR>ERROR INSERT ACCOUNT SCHEMA!</ERR>', 16, 1); RETURN (1); END

UPDATE dbo.DEPO_DEPOSITS WITH (ROWLOCK, UPDLOCK)
SET ROW_VERSION = ROW_VERSION + 1 
WHERE DEPO_ID = @depo_id
IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR('<ERR>ERROR UPDATING DEPOSIT DATA</ERR>', 16, 1); RETURN (1); END

INSERT INTO dbo.DEPO_DEPOSIT_CHANGES(DEPO_ID, [USER_ID], DESCRIP)
SELECT @depo_id, @user_id, 'ÏÐÄÒÀÝÉÉÓ ÛÄÓÒÖËÄÁÀ: '  + DESCRIP
FROM dbo.DEPO_OP_TYPES (NOLOCK)
WHERE [TYPE_ID] = @op_type
IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR OPERATION LOGGING</ERR>', 16, 1); RETURN (1); END

IF @internal_transaction=1 AND @@TRANCOUNT>0 
	COMMIT TRAN

RETURN (0)
GO
