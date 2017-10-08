SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[PROCESS_ACCRUAL_DEPO_OLD]
	@perc_type tinyint,
	@acc_id int,
	@user_id int,
	@dept_no int,
	@doc_date smalldatetime,
	@calc_date smalldatetime,
	@force_calc bit = 0,
	@force_realization bit = 0,
	@simulate bit = 0,
	@recalc_option tinyint = 0,	-- 0x00 - Calc as usual
								-- 0x01 - Recalc from beginning
								-- 0x02 - Recalc from last realiz. date
	@formula varchar(512) = NULL,
	@accrue_amount money = NULL,
	@restart_calc bit = 0,
	@show_result bit = 1,
	@restore_acc_id int = NULL,
	@depo_depo_id int = NULL,
	@depo_op_type smallint = NULL,
	@depo_op_id int = NULL,
	@interest_amount money = NULL OUTPUT,
	@rec_id int = NULL OUTPUT,
	@depo_op_doc_rec_id int = NULL OUTPUT
	
AS

SET NOCOUNT ON

-- Constants
DECLARE
	@pfDontIncludeStartDate int,
	@pfDontIncludeEndDate int,
	@pfLeaveTrail int,
	@pmtByMonth30 int,
	@pctNone int


SET @pfDontIncludeStartDate = 1
SET @pfDontIncludeEndDate = 2
SET @pfLeaveTrail = 4

SET @pmtByMonth30 = 3
SET @pctNone = 99

IF @force_realization <> 0
	SET @force_calc = 1

DECLARE
	@start_date smalldatetime,
	@end_date smalldatetime,
	@end_date_original smalldatetime,
	@perc_flags int,
	@calc_type int,
	@move_type int,
	@move_num int,
	@move_num_type int,
	@last_calc_date smalldatetime,
	@last_move_date smalldatetime,
	@prev_last_calc_date smalldatetime,
	@prev_last_move_date smalldatetime,
	@total_calc_amount money,
	@total_payed_amount money

DECLARE
	@account TACCOUNT,
	@iso TISO,
	@branch_id int,
    @realiz_acc_id int,
    @prof_loss_acc_id int,
    @perc_calc_acc_id int,
	@prev_calc_amount money,
	@days_in_year int,
	@tax_rate money,
	@is_incasso bit,
	@client_no int,
	@is_juridical bit,
	@is_resident bit
	
SELECT @branch_id = BRANCH_ID, @account = ACCOUNT, @iso = ISO, @is_incasso = IS_INCASSO, @client_no = CLIENT_NO
FROM dbo.ACCOUNTS (NOLOCK)
WHERE ACC_ID = @acc_id

IF @client_no IS NULL
BEGIN
	SET @is_juridical = NULL
	SET @is_resident = NULL 
END
ELSE
	SELECT @is_juridical = IS_JURIDICAL, @is_resident = IS_RESIDENT
	FROM dbo.CLIENTS (NOLOCK)
	WHERE CLIENT_NO = @client_no


IF @perc_type = 1	-- ÃÄÁÄÔÖÒÉ ÃÀÒÉÝáÅÀ
	SELECT @start_date = START_DATE, @end_date = END_DATE, @perc_flags = PERC_FLAGS, 
		@prev_last_calc_date = LAST_CALC_DATE, @prev_last_move_date = LAST_MOVE_DATE,
		@last_calc_date = ISNULL(LAST_CALC_DATE, LAST_MOVE_DATE), @last_move_date = LAST_MOVE_DATE,
		@calc_type = CALC_TYPE, @move_type = PERC_TYPE, @move_num = MOVE_COUNT, @move_num_type = MOVE_COUNT_TYPE,
		@realiz_acc_id = CLIENT_ACCOUNT, 
		@prof_loss_acc_id = PERC_BANK_ACCOUNT,
		@perc_calc_acc_id = PERC_CLIENT_ACCOUNT,
		@prev_calc_amount = ISNULL(CALC_AMOUNT, $0.00), 
		@formula = ISNULL(@formula, FORMULA), @days_in_year = DAYS_IN_YEAR, @tax_rate = $0.0000,
		@total_calc_amount = ISNULL(TOTAL_CALC_AMOUNT, $0.00), @total_payed_amount = ISNULL(TOTAL_PAYED_AMOUNT, $0.00)
	FROM dbo.ACCOUNTS_DEB_PERC P
	WHERE ACC_ID = @acc_id
ELSE
IF @perc_type = 0	-- ÊÒÄÃÉÔÖËÉ ÃÀÒÉÝáÅÀ
	SELECT @start_date = START_DATE, @end_date = END_DATE, @perc_flags = PERC_FLAGS, 
		@prev_last_calc_date = LAST_CALC_DATE, @prev_last_move_date = LAST_MOVE_DATE,
		@last_calc_date = ISNULL(LAST_CALC_DATE, LAST_MOVE_DATE), @last_move_date = LAST_MOVE_DATE,
		@calc_type = CALC_TYPE, @move_type = PERC_TYPE, @move_num = MOVE_COUNT, @move_num_type = MOVE_COUNT_TYPE,
		@realiz_acc_id = CLIENT_ACCOUNT, 
		@prof_loss_acc_id = PERC_BANK_ACCOUNT,
		@perc_calc_acc_id = PERC_CLIENT_ACCOUNT,
		@prev_calc_amount = ISNULL(CALC_AMOUNT, $0.00), 
		@formula = ISNULL(@formula, FORMULA), @days_in_year = DAYS_IN_YEAR, @tax_rate = TAX_RATE,
		@total_calc_amount = ISNULL(TOTAL_CALC_AMOUNT, $0.00), @total_payed_amount = ISNULL(TOTAL_PAYED_AMOUNT, $0.00)
	FROM dbo.ACCOUNTS_CRED_PERC P
	WHERE ACC_ID = @acc_id

IF ISNULL(@formula, '') = ''
	RETURN 0

IF @end_date IS NULL 
	SET @end_date = '20500101'

SET @end_date_original = @end_date

EXEC dbo.ON_USER_BEFORE_PROCESS_ACCRUAL 
	@perc_type = @perc_type,
	@acc_id = @acc_id,
	@user_id = @user_id,
	@dept_no = @dept_no,
	@doc_date = @doc_date,
	@calc_date = @calc_date,
	@force_calc = @force_calc,
	@force_realization = @force_realization,
	@simulate = @simulate,
	@recalc_option = @recalc_option OUTPUT,
	@formula = @formula OUTPUT 

IF @recalc_option = 0x01 -- Recalc from the beginning
BEGIN
	SET @last_calc_date = NULL 
	SET @last_move_date = NULL
--	IF @recalc_start_date IS NOT NULL
--		SET @start_date = @recalc_start_date
END
ELSE
IF @recalc_option = 0x02 -- Recalc from last realiz. date
BEGIN
	SET @last_calc_date = @last_move_date 
END

DECLARE 
	@need_move bit,
	@need_calc bit

SET @need_move = @force_realization
IF @need_move = 0
	SET @need_move = dbo.accruals_perc_need_move (@calc_date, @start_date, @end_date, @move_type, @move_num, @move_num_type, @perc_flags)

SET @need_calc = @need_move | @force_calc
IF @need_calc = 0
	SET @need_calc = dbo.accruals_perc_need_calc (@calc_date, @start_date, @end_date, @calc_type, @perc_flags)

IF @need_calc = 0
	RETURN (0)

DECLARE @need_trail bit

IF @realiz_acc_id IS NULL OR @realiz_acc_id = @acc_id
BEGIN
	SET @realiz_acc_id = @acc_id
	SET @perc_flags = @perc_flags & (~@pfLeaveTrail)
	SET @need_trail = 0
END
ELSE 
	SET @need_trail = (@perc_flags & @pfLeaveTrail)

IF @last_calc_date IS NULL OR @last_calc_date < @start_date
BEGIN
	IF @perc_flags & @pfDontIncludeStartDate <> 0
		SET @start_date = @start_date + 1
END
ELSE
	SET @start_date = @last_calc_date + 1

IF (@perc_flags & @pfDontIncludeEndDate <> 0) AND (@end_date = @calc_date)
	SET @end_date = @calc_date - 1
ELSE
IF @end_date > @calc_date 
	SET @end_date = @calc_date

IF @start_date > @calc_date
	RETURN

DECLARE
    @cur_accrual money,
	@month_eq_30 bit,
	@r int

SET @cur_accrual = $0.0000

IF @move_num_type = @pmtByMonth30
	SET @month_eq_30 = 1
ELSE
	SET @month_eq_30 = 0

IF @need_calc <> 0
BEGIN
	EXEC dbo.calc_accrual_amount @acc_id, @start_date, @end_date, @formula, 1, @cur_accrual OUTPUT, @month_eq_30, @need_move, @days_in_year, @tax_rate, @recalc_option

	IF @recalc_option = 0x1 -- beginning
		SET @cur_accrual = ROUND(@cur_accrual - @total_calc_amount, 2)
	ELSE
	IF @recalc_option = 0x2 -- last realization
		SET @cur_accrual = ROUND(@cur_accrual - @prev_calc_amount, 2)
	ELSE
	BEGIN
		IF @last_calc_date IS NULL
			SET @cur_accrual = @cur_accrual - @prev_calc_amount
	END
END

DECLARE 
	@tax_acc TACCOUNT,
	@tax_acc_id int,
	@tax_branch_id int

SET @tax_acc_id = 0

IF @perc_type = 0
BEGIN
	IF @iso = 'GEL'
	BEGIN
		IF @client_no IS NULL
			EXEC dbo.GET_SETTING_ACC 'DEPOSIT_TAX_ACC', @tax_acc OUTPUT
		ELSE
		IF @is_juridical = 0 AND @is_resident = 1
			EXEC dbo.GET_SETTING_ACC 'DEPO_TAX_ACC_RP', @tax_acc OUTPUT
		ELSE
		IF @is_juridical = 0 AND @is_resident = 0
			EXEC dbo.GET_SETTING_ACC 'DEPO_TAX_ACC_NRP', @tax_acc OUTPUT
		ELSE
		IF @is_juridical = 1 AND @is_resident = 1
			EXEC dbo.GET_SETTING_ACC 'DEPO_TAX_ACC_RJ', @tax_acc OUTPUT
		ELSE
		IF @is_juridical = 1 AND @is_resident = 0
			EXEC dbo.GET_SETTING_ACC 'DEPO_TAX_ACC_NRJ', @tax_acc OUTPUT
	END
	ELSE
	BEGIN
		IF @client_no IS NULL
			EXEC dbo.GET_SETTING_ACC 'DEPOSIT_TAX_ACC_V', @tax_acc OUTPUT
		ELSE
		IF @is_juridical = 0 AND @is_resident = 1
			EXEC dbo.GET_SETTING_ACC 'DEPO_TAX_ACC_RP_V', @tax_acc OUTPUT
		ELSE
		IF @is_juridical = 0 AND @is_resident = 0
			EXEC dbo.GET_SETTING_ACC 'DEPO_TAX_ACC_NRP_V', @tax_acc OUTPUT
		ELSE
		IF @is_juridical = 1 AND @is_resident = 1
			EXEC dbo.GET_SETTING_ACC 'DEPO_TAX_ACC_RJ_V', @tax_acc OUTPUT
		ELSE
		IF @is_juridical = 1 AND @is_resident = 0
			EXEC dbo.GET_SETTING_ACC 'DEPO_TAX_ACC_NRJ_V', @tax_acc OUTPUT
	END
	
	EXEC dbo.GET_SETTING_INT 'HEAD_BRANCH_DEPT_NO ', @tax_branch_id OUTPUT
 
	SET @tax_acc_id = dbo.acc_get_acc_id (@tax_branch_id, @tax_acc, @iso)
	IF @tax_acc_id IS NULL 
	BEGIN
		RAISERROR ('ÌÉÙÄÁÖËÉ ÐÒÏÝÄÍÔÉÓ ÃÀÁÄÂÅÒÉÓ ÀÍÂÀÒÉÛÉ ÀÒ ÌÏÉÞÄÁÍÀ', 16, 1)
		RETURN 1
	END
END
ELSE
IF @perc_type = 1	-- ÃÄÁÄÔÖÒÉ ÃÀÒÉÝáÅÀ
BEGIN
	IF @realiz_acc_id <> @acc_id
		SELECT @is_incasso = IS_INCASSO
		FROM dbo.ACCOUNTS (NOLOCK)
		WHERE ACC_ID = @realiz_acc_id
	IF @is_incasso <> 0
		SET @need_move = 0
END



DECLARE @internal_transaction bit
SET @internal_transaction = 0
IF @simulate = 0 AND @@TRANCOUNT = 0
BEGIN
	BEGIN TRAN
	SET @internal_transaction = 1
END

CREATE TABLE #accruals (DEBIT_ID int, CREDIT_ID int, AMOUNT money, OP_CODE varchar(5) collate database_default, DESCRIP varchar(150) collate database_default, [SIGN] smallint)

IF @cur_accrual <> $0.0000 AND @calc_type <> @pctNone
BEGIN
	-- დარიცხვის საბუთის დამატება
	EXEC @r = dbo._INTERNAL_ADD_DOC_PERC 
		@perc_type = @perc_type, 
		@debit_id = @perc_calc_acc_id, 
		@credit_id = @prof_loss_acc_id, 
		@amount = @cur_accrual, 
		@op_code = '*%AC*', 
		@descrip = 'ÐÒÏÝÄÍÔÉÓ ÃÀÒÉÝáÅÀ'
	IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 1 END
END

IF @need_move <> 0
BEGIN
	DECLARE 
		@credit_id int,
		@calc_amount money

	IF @calc_type <> @pctNone
		SET @credit_id = @perc_calc_acc_id
	ELSE
		SET @credit_id = @prof_loss_acc_id

	SET @calc_amount = @prev_calc_amount + @cur_accrual

	IF @calc_amount <= 0
		SET @tax_rate = $0.00


	EXEC @r = dbo._INTERNAL_ADD_DOC_PERC 
		@perc_type = @perc_type, 
		@debit_id = @realiz_acc_id,
		@credit_id = @credit_id,
		@amount = @calc_amount, 
		@op_code = '*%RL*', 
		@descrip = 'ÃÀÒÉÝáÖËÉ ÐÒÏÝÄÍÔÉÓ ÒÄÀËÉÆÀÝÉÀ',
		@tax_rate = @tax_rate,
		@tax_acc_id = @tax_acc_id,
		@main_acc_id = @acc_id,
		@need_trail = @need_trail 
	IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 1 END
END

IF @simulate = 0
BEGIN
	DECLARE 
		@debit_id int,
		@amount money,
		@op_code TOPCODE,
		@descrip varchar(150),
		@doc_type smallint,
		@parent_rec_id int,
		@foreign_id int,
		@amount2 money,
		@sign smallint

	SET @doc_type = CASE @perc_type WHEN 0 THEN 30 WHEN 1 THEN 32 WHEN 3 THEN 30 END
	
	SET @parent_rec_id = 0
	IF (SELECT COUNT(*) FROM #accruals WHERE ROUND(AMOUNT, 2) > $0.0000) > 1
		SET @parent_rec_id = -1

	DECLARE cc CURSOR
	FOR
	SELECT * FROM #accruals

	OPEN cc
	FETCH NEXT FROM cc INTO @debit_id, @credit_id, @amount, @op_code, @descrip, @sign

	WHILE @@FETCH_STATUS = 0
	BEGIN
		IF @op_code = '*%AC*'
			SET @amount2 = ROUND(@prev_calc_amount + @amount, 2) - ROUND(@prev_calc_amount, 2)
		ELSE
			SET @amount2 = ROUND(@amount, 2)

		IF @amount2 > 0
		BEGIN
			SET @descrip = @descrip + ' - ' + CONVERT(varchar(34), @account) + '/' + @iso
			IF @op_code = '*%RL*'	-- Realization
				SET @foreign_id = CONVERT(int, @prev_last_move_date)
			ELSE
				SET @foreign_id = CONVERT(int, @prev_last_calc_date)

			EXEC @r = dbo.ADD_DOC4
				@rec_id = @rec_id OUTPUT,			
				@user_id = @user_id,
				@owner = @user_id,
				@doc_type = @doc_type,
				@doc_date = @doc_date,
				@doc_date_in_doc = @calc_date,
				@debit_id = @debit_id,
				@credit_id = @credit_id,
				@iso = @iso,
				@amount = @amount2,
				@rec_state = 20,
				@descrip = @descrip,
				@op_code = @op_code,
				@parent_rec_id = @parent_rec_id,
				@account_extra = @acc_id,
				@dept_no = @dept_no,
				@foreign_id = @foreign_id,

				@check_saldo = 0,		-- შეამოწმოს თუ არა მინ. ნაშთი
				@add_tariff = 0,		-- დაამატოს თუ არა ტარიფის საბუთი
				@info = 0				-- რეალურად გატარდეს, თუ მხოლოდ ინფორმაციაა

			IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 31 END

			SET @amount = @amount * @sign
			IF @perc_type = 1
				SET @amount = - @amount 

			UPDATE dbo.OPS_0000
			SET CASH_AMOUNT = @amount
			WHERE REC_ID = @rec_id

			IF @@ERROR<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 31 END

			DECLARE @prev_date smalldatetime

			IF @op_code = '*%RL*'	-- Realization
				SET @prev_date = @prev_last_move_date
			ELSE
				SET @prev_date = @prev_last_calc_date

			INSERT INTO dbo.DOC_DETAILS_PERC (DOC_REC_ID, ACC_ID, ACCR_DATE, PREV_DATE, AMOUNT4)
			VALUES (@rec_id, @acc_id, @calc_date, @prev_date, @amount)
			IF @@ERROR<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 31 END

			IF @parent_rec_id <= 0
				SET @parent_rec_id = @rec_id
		
			IF @op_code = '*%AC*'	-- Accrual
			BEGIN
				IF @perc_type = 1
					UPDATE dbo.ACCOUNTS_DEB_PERC
					SET LAST_CALC_DATE = @calc_date, CALC_AMOUNT = ISNULL(CALC_AMOUNT, $0.0000) + @amount, TOTAL_CALC_AMOUNT = ISNULL(TOTAL_CALC_AMOUNT, $0.0000) + @amount2
					WHERE ACC_ID = @acc_id
				ELSE
				IF @perc_type = 0
					UPDATE dbo.ACCOUNTS_CRED_PERC
					SET LAST_CALC_DATE = @calc_date, CALC_AMOUNT = ISNULL(CALC_AMOUNT, $0.0000) + @amount, TOTAL_CALC_AMOUNT = ISNULL(TOTAL_CALC_AMOUNT, $0.0000) + @amount2
					WHERE ACC_ID = @acc_id
			END
			ELSE
			IF @op_code = '*%RL*'	-- Realization
			BEGIN
				IF @perc_type = 1
					UPDATE dbo.ACCOUNTS_DEB_PERC
					SET LAST_MOVE_DATE = @calc_date, TOTAL_PAYED_AMOUNT = ISNULL(TOTAL_PAYED_AMOUNT, $0.0000) + @amount2, CALC_AMOUNT = CASE WHEN @calc_type <> @pctNone THEN ISNULL(CALC_AMOUNT, $0.0000) - @amount ELSE CALC_AMOUNT END
					WHERE ACC_ID = @acc_id
				ELSE
				IF @perc_type = 0
					UPDATE dbo.ACCOUNTS_CRED_PERC
					SET LAST_MOVE_DATE = @calc_date, TOTAL_PAYED_AMOUNT = ISNULL(TOTAL_PAYED_AMOUNT, $0.0000) + @amount2, CALC_AMOUNT = CASE WHEN @calc_type <> @pctNone THEN ISNULL(CALC_AMOUNT, $0.0000) - @amount ELSE CALC_AMOUNT END
					WHERE ACC_ID = @acc_id
			END
			IF @@ERROR<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 1 END
		END

		FETCH NEXT FROM cc INTO @debit_id, @credit_id, @amount, @op_code, @descrip, @sign
	END
	
	CLOSE cc
	DEALLOCATE cc

	IF (@end_date_original = @calc_date) AND (@perc_type = 0) AND (@acc_id <> @realiz_acc_id)
	BEGIN
		DECLARE
			@depo_id int,
			@old_op_id int

		SELECT @depo_id = DEPO_ID, @old_op_id = OP_ID
		FROM dbo.DEPOS (NOLOCK)
		WHERE ACC_ID = @acc_id
		
		IF @depo_id IS NOT NULL
		BEGIN
			DECLARE
				@op_id int,
				@depo_amount money,
				@stupid_doc_rec_id int

			SET @depo_amount = - dbo.acc_get_balance(@acc_id, @calc_date, 0, 0, 1)
			
			INSERT INTO dbo.DEPO_OPS(DEPO_ID, DT, OP_TYPE, OWN_DATA, AMOUNT, SELF_EXEC, COMMIT_STATE, [OWNER], EXT_ACC_ID)
			VALUES(@depo_id, @doc_date, 220, 1, @depo_amount, 1, 255, @user_id, @realiz_acc_id)
			IF @@ERROR<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 1 END
			
			SET @op_id = SCOPE_IDENTITY()

			INSERT INTO dbo.DEPO_DATA (OP_ID, REC_STATE, AMOUNT, INT_RATE, ACCUMULATE, INC_AMOUNT, MAX_AMOUNT, OFFICER_ID, COMMENTS, END_DATE, MOVE_COUNT, MOVE_COUNT_TYPE, CALC_TYPE, FORMULA, CLIENT_ACCOUNT, PERC_CLIENT_ACCOUNT, PERC_BANK_ACCOUNT, DAYS_IN_YEAR, CALC_AMOUNT, TOTAL_CALC_AMOUNT, TOTAL_PAYED_AMOUNT, LAST_CALC_DATE, LAST_MOVE_DATE, PERC_FLAGS, PERC_TYPE, TAX_RATE, START_DATE_TYPE, START_DATE_DAYS, DATE_TYPE)			
			SELECT @op_id, REC_STATE, AMOUNT, INT_RATE, ACCUMULATE, INC_AMOUNT, MAX_AMOUNT, OFFICER_ID, COMMENTS, END_DATE, MOVE_COUNT, MOVE_COUNT_TYPE, CALC_TYPE, dbo.depo_get_formula(@op_id), CLIENT_ACCOUNT, PERC_CLIENT_ACCOUNT, PERC_BANK_ACCOUNT, DAYS_IN_YEAR, CALC_AMOUNT, TOTAL_CALC_AMOUNT, TOTAL_PAYED_AMOUNT, LAST_CALC_DATE, LAST_MOVE_DATE, PERC_FLAGS, PERC_TYPE, TAX_RATE, START_DATE_TYPE, START_DATE_DAYS, DATE_TYPE
			FROM dbo.DEPO_DATA
			WHERE OP_ID = @old_op_id 
			IF @@ERROR<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 1 END

			EXEC @r=dbo.depo_exec_op @stupid_doc_rec_id OUTPUT, @oid=@op_id, @user_id=@user_id
			IF @r <> 0 AND @@ERROR<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 1 END
		END
	END
END

IF @simulate = 1 
	SELECT @doc_date AS DOC_DATE, @calc_date AS CALC_DATE, @account AS ACCOUNT, dbo.acc_get_account(DEBIT_ID) AS DEBIT, dbo.acc_get_account(CREDIT_ID) AS CREDIT, *
	FROM #accruals

DROP TABLE #accruals

IF @simulate = 0 AND @internal_transaction=1 AND @@TRANCOUNT>0 
	COMMIT TRAN

GO
