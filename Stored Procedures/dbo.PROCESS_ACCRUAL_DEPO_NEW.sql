SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[PROCESS_ACCRUAL_DEPO_NEW]
	@perc_type tinyint,
	@acc_id int,
	@user_id int,
	@dept_no int,
	@doc_date smalldatetime,
	@calc_date smalldatetime,
	@force_calc bit = 0,
	@force_realization bit = 0,
	@simulate bit = 0,
	@recalc_option tinyint = 0,	-- 0x00 - Auto
								-- 0x01 - Calc as usual (last accrual)
								-- 0x02 - Recalc from last realize date
								-- 0x04 - Recalc from beginning
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

SET NOCOUNT ON;

IF ISNULL(@accrue_amount, $0.00) < $0.00
	RETURN 0

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
	@r int	

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
	@total_payed_amount money,
	@total_payed_amount_ money

DECLARE
	@account TACCOUNT,
	@iso char(3),
	@branch_id int,
    @realize_acc_id int,
    @prof_loss_acc_id int,
    @perc_calc_acc_id int,
	@prev_calc_amount money,
	@days_in_year int,
	@tax_rate money,
	@is_incasso bit,
	@client_no int

DECLARE
	@depo_id int,
	@recalculate_type tinyint,
	@depo_realize_acc_id int,
	@interest_realize_acc_id int,
	@depo_realize_amount money,
	@interest_realize_amount money,
	@advance_acc_id money,
	@advance_amount money,
	@min_processing_date smalldatetime,
	@min_processing_total_calc_amount money,
	@total_tax_payed_amount money,
	@total_tax_payed_amount_equ money

	
SELECT @branch_id = BRANCH_ID, @account = ACCOUNT, @iso = ISO, @is_incasso = IS_INCASSO, @client_no = CLIENT_NO
FROM dbo.ACCOUNTS (NOLOCK)
WHERE ACC_ID = @acc_id

IF @perc_type = 1	-- ÃÄÁÄÔÖÒÉ ÃÀÒÉÝáÅÀ
	SELECT @start_date = [START_DATE], @end_date = END_DATE, @perc_flags = PERC_FLAGS, 
		@prev_last_calc_date = LAST_CALC_DATE, @prev_last_move_date = LAST_MOVE_DATE,
		@last_calc_date = ISNULL(LAST_CALC_DATE, LAST_MOVE_DATE), @last_move_date = LAST_MOVE_DATE,
		@calc_type = CALC_TYPE, @move_type = PERC_TYPE, @move_num = MOVE_COUNT, @move_num_type = MOVE_COUNT_TYPE,
		@realize_acc_id = CLIENT_ACCOUNT, 
		@prof_loss_acc_id = PERC_BANK_ACCOUNT,
		@perc_calc_acc_id = PERC_CLIENT_ACCOUNT,
		@prev_calc_amount = ISNULL(CALC_AMOUNT, $0.00), 
		@formula = ISNULL(@formula, FORMULA), @days_in_year = DAYS_IN_YEAR, @tax_rate = $0.0000,
		@total_calc_amount = ISNULL(TOTAL_CALC_AMOUNT, $0.00), @total_payed_amount = ISNULL(TOTAL_PAYED_AMOUNT, $0.00),
		@depo_id = NULL, @recalculate_type = 7, @depo_realize_acc_id = NULL, @interest_realize_acc_id = NULL,
		@depo_realize_amount = NULL, @interest_realize_amount = NULL,
		@advance_acc_id = NULL, @advance_amount = $0.00,
		@min_processing_date = NULL, @min_processing_total_calc_amount = $0.00,
		@total_tax_payed_amount = NULL, @total_tax_payed_amount_equ = NULL
	FROM dbo.ACCOUNTS_DEB_PERC P
	WHERE ACC_ID = @acc_id
ELSE
IF @perc_type = 0	-- ÊÒÄÃÉÔÖËÉ ÃÀÒÉÝáÅÀ
	SELECT @start_date = [START_DATE], @end_date = END_DATE, @perc_flags = PERC_FLAGS, 
		@prev_last_calc_date = LAST_CALC_DATE, @prev_last_move_date = LAST_MOVE_DATE,
		@last_calc_date = ISNULL(LAST_CALC_DATE, LAST_MOVE_DATE), @last_move_date = LAST_MOVE_DATE,
		@calc_type = CALC_TYPE, @move_type = PERC_TYPE, @move_num = MOVE_COUNT, @move_num_type = MOVE_COUNT_TYPE,
		@realize_acc_id = CLIENT_ACCOUNT, 
		@prof_loss_acc_id = PERC_BANK_ACCOUNT,
		@perc_calc_acc_id = PERC_CLIENT_ACCOUNT,
		@prev_calc_amount = ISNULL(CALC_AMOUNT, $0.00), 
		@formula = ISNULL(@formula, FORMULA), @days_in_year = DAYS_IN_YEAR, @tax_rate = TAX_RATE,
		@total_calc_amount = ISNULL(TOTAL_CALC_AMOUNT, $0.00), @total_payed_amount = ISNULL(TOTAL_PAYED_AMOUNT, $0.00),
		@depo_id = DEPO_ID,	@recalculate_type = ISNULL(RECALCULATE_TYPE, 7), @depo_realize_acc_id = DEPO_REALIZE_ACC_ID, @interest_realize_acc_id = INTEREST_REALIZE_ACC_ID,
		@depo_realize_amount = DEPO_REALIZE_AMOUNT, @interest_realize_amount = INTEREST_REALIZE_AMOUNT,
		@advance_acc_id = ADVANCE_ACC_ID, @advance_amount = ISNULL(ADVANCE_AMOUNT, $0.00), 
		@min_processing_date = MIN_PROCESSING_DATE, @min_processing_total_calc_amount = ISNULL(MIN_PROCESSING_TOTAL_CALC_AMOUNT, $0.00),
		@total_tax_payed_amount = ISNULL(TOTAL_TAX_PAYED_AMOUNT, $0.00), @total_tax_payed_amount_equ = ROUND(ISNULL(TOTAL_TAX_PAYED_AMOUNT_EQU, $0.00), 2)
	FROM dbo.ACCOUNTS_CRED_PERC P
	WHERE ACC_ID = @acc_id
	
	
IF (@depo_op_type IS NULL) AND (@depo_op_id IS NOT NULL) AND EXISTS(SELECT * FROM dbo.DEPO_OP (NOLOCK) WHERE DEPO_ID = @depo_id AND OP_STATE = 0)
	RETURN 0 

IF (@depo_op_type IS NOT NULL) AND (@depo_op_id IS NOT NULL) AND (@depo_op_type IN (dbo.depo_fn_const_op_close(), dbo.depo_fn_const_op_close_default()))
BEGIN
	IF @depo_op_type = dbo.depo_fn_const_op_close()
		SELECT @interest_realize_acc_id = INTEREST_REALIZE_ACC_ID
		FROM dbo.DEPO_VW_OP_DATA_CLOSE
		WHERE OP_ID = @depo_op_id
	ELSE
	IF @depo_op_type = dbo.depo_fn_const_op_close_default()
		SELECT @interest_realize_acc_id = INTEREST_REALIZE_ACC_ID
		FROM dbo.DEPO_VW_OP_DATA_CLOSE_DEFAULT
		WHERE OP_ID = @depo_op_id
	
	IF  (@advance_amount = $0.00)
		SET @realize_acc_id = @interest_realize_acc_id 
END	

IF (@depo_depo_id IS NULL) AND (@depo_id IS NOT NULL) AND (@simulate = 0) -- ÈÖ ÃÀÒÉÝáÅÀ ÂÀÌÏÞÀáÄÁÖËÉÀ ÀÒÀ ÃÄÐÏÆÔÄÁÉÓÈÅÉÓ ÌÀÛÉÍ ÀÒ ÛÄÓÒÖËÃÄÓ
	RETURN 0 

IF (ISNULL(@formula, '') = '') AND (@accrue_amount IS NULL)
	RETURN 0

DECLARE
	@prod_id int,
	@intrate money,
	@real_intrate TRATE,
	@spend_amount_intrate money,
	@accumulate_schema_intrate tinyint,
	@bonus_schema int,
	@bonus_schema_proc varchar(128),
	@bonus_amount money,
	@remark varchar(255)

SELECT @prod_id = PROD_ID, @intrate = INTRATE, @real_intrate = REAL_INTRATE, @spend_amount_intrate = SPEND_AMOUNT_INTRATE, @accumulate_schema_intrate = ACCUMULATE_SCHEMA_INTRATE
FROM dbo.DEPO_DEPOSITS (NOLOCK)
WHERE DEPO_ID = @depo_id

SELECT @bonus_schema = BONUS_SCHEMA
FROM dbo.DEPO_PRODUCT (NOLOCK) 
WHERE PROD_ID = @prod_id

SET @bonus_amount = $0.00 

IF ISNULL(@accumulate_schema_intrate, 0) = 5
BEGIN
	EXEC dbo.depo_sp_get_formula_month_min
		@acc_id = @acc_id,
		@date = @calc_date,
		@intrate = @intrate,
		@spend_intrate = @spend_amount_intrate,
		@schema_start_date = @start_date,
		@schema_end_date = @end_date,
		@formula = @formula OUTPUT
END
	
IF @end_date IS NULL 
	SET @end_date = '20500101'

SET @total_payed_amount_ = @total_payed_amount
SET @end_date_original = @end_date

IF @calc_date = @end_date
BEGIN
	IF (@bonus_schema IS NOT NULL) AND ((@depo_op_type IS NULL) OR (@depo_op_type NOT IN (dbo.depo_fn_const_op_annulment(),  dbo.depo_fn_const_op_annulment_amount(), dbo.depo_fn_const_op_annulment_positive())))
	BEGIN
		SET @remark = ''
	
		SELECT @bonus_schema_proc = PROCEDURE_NAME
		FROM dbo.DEPO_PRODUCT_BONUS_SCHEMA (NOLOCK) 
		WHERE [SCHEMA_ID] = @bonus_schema
		
		DECLARE
			@sql nvarchar(2000)
	
		SET @sql = 'EXEC @r=' + @bonus_schema_proc +
			' @depo_id=@depo_id,@user_id=@user_id,@dept_no=@dept_no,@analyze_date=@calc_date,@accrue_amount=@bonus_amount OUTPUT, @remark=@remark OUTPUT'
		EXEC sp_executesql @sql, N'@r int OUTPUT, @depo_id int,@user_id int,@dept_no int,@calc_date smalldatetime,@bonus_amount money OUTPUT,@remark varchar(255) OUTPUT',
			@r OUTPUT, @depo_id, @user_id, @dept_no, @calc_date, @bonus_amount OUTPUT, @remark OUTPUT
	END

	SET @bonus_amount = ISNULL(@bonus_amount, $0.00)
END

DECLARE 
	@need_move bit,
	@need_move_ bit,
	@need_calc bit,
	@need_calc_ bit,
	@need_trail bit,
	@cur_accrual money
	
SET @cur_accrual = $0.0000
	
IF @realize_acc_id IS NULL OR @realize_acc_id = @acc_id
BEGIN
	SET @realize_acc_id = @acc_id
	SET @perc_flags = @perc_flags & (~@pfLeaveTrail)
	SET @need_trail = 0
END
ELSE 
	SET @need_trail = (@perc_flags & @pfLeaveTrail)
	
SET @need_calc_ = 0

IF (ISNULL(@accumulate_schema_intrate, 0) = 3) AND (@accrue_amount IS NULL)
BEGIN
	SET @need_calc_ = 1
	
	EXEC @r = dbo.depo_sp_calc_accrual_by_amount_period
		@depo_id = @depo_id,
		@accrual_date = @calc_date,
		@accrual_amount = @accrue_amount OUTPUT,
		@result_type = 0
		
	IF @@ERROR <> 0 OR @r <> 0
	BEGIN
		RAISERROR ('ÛÄÝÃÏÌÀ ÃÀÓÀÒÉÝáÉ ÈÀÍáÉÓ ÃÀÀÍÂÀÒÉÛÄÁÉÓ ÃÒÏÓ', 16, 1)
		RETURN 1
	END
END

IF (@accrue_amount IS NULL) OR (@need_calc_ = 1) 
BEGIN
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

	IF @recalculate_type & @recalc_option = 0
	BEGIN
		IF @recalc_option <> 0
		BEGIN
			RAISERROR ('ÂÀÃÀÀÍÂÀÒÉÛÄÁÉÓ ÄÓ ÔÉÐÉ ÀÒ ÛÄÄÓÀÁÀÌÄÁÀ ÀÌ ÀÍÂÀÒÉÛÉÓ ÃÀÒÉÝáÅÉÓ ÓØÄÌÀÓ', 16, 1)
			RETURN 1
		END

		IF @recalculate_type & 0x01 <> 0
			SET @recalc_option = 0x01
		ELSE
		IF @recalculate_type & 0x02 <> 0
			SET @recalc_option = 0x02
		ELSE
		IF @recalculate_type & 0x04 <> 0
			SET @recalc_option = 0x04
	END
	
	IF @recalc_option = 0x04 -- Recalc from the beginning
	BEGIN
		SET @last_calc_date = @min_processing_date 
		SET @last_move_date = @min_processing_date
	END
	ELSE
	IF @recalc_option = 0x02 -- Recalc from last realiz. date
	BEGIN
		SET @last_calc_date = @last_move_date 
	END

	SET @need_move = @force_realization

	IF @need_move = 0
		SET @need_move = dbo.accruals_perc_need_move (@calc_date, @start_date, @end_date, @move_type, @move_num, @move_num_type, @perc_flags)
		
	SET @need_calc = @need_move | @force_calc

	IF @need_calc = 0
		SET @need_calc = dbo.accruals_perc_need_calc (@calc_date, @start_date, @end_date, @calc_type, @perc_flags)

	IF (@need_move = 0) AND (@need_calc = 1) AND (@move_type = 3)
		SET @need_move = 1 

	IF @need_calc = 0
		RETURN (0)

	IF @last_calc_date IS NULL OR @last_calc_date < @start_date
	BEGIN
		IF @perc_flags & @pfDontIncludeStartDate <> 0
			SET @start_date = @start_date + 1
	END
	ELSE
	BEGIN
		IF @restart_calc = 0
			SET @start_date = @last_calc_date + 1
	END		

	IF (@perc_flags & @pfDontIncludeEndDate <> 0) AND (@end_date = @calc_date)
		SET @end_date = @calc_date - 1
	ELSE
	IF @end_date > @calc_date 
		SET @end_date = @calc_date

	IF @start_date > @calc_date
		RETURN 0
END
ELSE
BEGIN
	SET @need_move = @force_realization

	IF @need_move = 0
		SET @need_move = dbo.accruals_perc_need_move (@calc_date, @start_date, @end_date, @move_type, @move_num, @move_num_type, @perc_flags)
		
	IF (@need_move = 0) AND (@need_calc = 1) AND (@move_type = 3)
		SET @need_move = 1
END

SET @need_move_ = @need_move

IF (@accrue_amount IS NOT NULL) OR (@need_calc <> 0) 
BEGIN 
	IF @accrue_amount IS NULL
	BEGIN 
		DECLARE
			@month_eq_30 bit
		
		IF @move_num_type = @pmtByMonth30
			SET @month_eq_30 = 1
		ELSE
			SET @month_eq_30 = 0

		EXEC dbo.calc_accrual_amount @acc_id, @start_date, @end_date, @formula, 1, @cur_accrual OUTPUT, @month_eq_30, @need_move, @days_in_year, @tax_rate, @recalc_option

		SET @cur_accrual = @cur_accrual + @bonus_amount
		
		IF @restart_calc = 0
		BEGIN
			IF @recalc_option = 0x4 -- beginning
				SET @cur_accrual = ROUND(@cur_accrual + @min_processing_total_calc_amount - @total_calc_amount, 2)
			ELSE
			IF @recalc_option = 0x2 -- last realization
				SET @cur_accrual = ROUND(@cur_accrual - @prev_calc_amount, 2)
		END
		ELSE
		BEGIN
			IF @recalc_option = 0x4 -- beginning
				SET @cur_accrual = @cur_accrual
			ELSE
			IF @recalc_option = 0x2 -- last realization
				SET @cur_accrual = ROUND(@cur_accrual - @prev_calc_amount, 2)
		END	
	END		
	ELSE
	BEGIN
		IF @restart_calc = 0
			SET @cur_accrual = ROUND(@accrue_amount - @prev_calc_amount, 2)
		ELSE
			SET @cur_accrual = @accrue_amount 	
	END			
END


DECLARE 
	@tax_acc_id int,
	@tax_gel_acc_id int,
	@tax_revert_acc_id int,
	@tax_revert_gel_acc_id int,
	@depo_tax_interest_type int

SET @depo_tax_interest_type = 0
	
IF @perc_type = 0
BEGIN
	EXEC dbo.GET_SETTING_INT 'DEPO_TAX_INTRST_TYPE', @depo_tax_interest_type OUTPUT
	
	EXEC dbo.depo_sp_get_tax_acc
		@iso = @iso,
		@client_no = @client_no,
		@tax_acc_id = @tax_acc_id OUTPUT
		
	IF @tax_acc_id IS NULL
	BEGIN
		RAISERROR ('ÌÉÙÄÁÖËÉ ÐÒÏÝÄÍÔÉÓ ÃÀÁÄÂÅÒÉÓ ÀÍÂÀÒÉÛÉ ÀÍÀÁÒÉÓ ÅÀËÖÔÀÛÉ ÀÒ ÌÏÉÞÄÁÍÀ', 16, 1)
		RETURN 1
	END

	EXEC dbo.depo_sp_get_tax_acc
		@iso = 'GEL',
		@client_no = @client_no,
		@tax_acc_id = @tax_gel_acc_id OUTPUT
		
	IF @tax_gel_acc_id IS NULL
	BEGIN
		RAISERROR ('ÌÉÙÄÁÖËÉ ÐÒÏÝÄÍÔÉÓ ÃÀÁÄÂÅÒÉÓ ÀÍÂÀÒÉÛÉ ËÀÒÛÉ ÀÒ ÌÏÉÞÄÁÍÀ', 16, 1)
		RETURN 1
	END
	
	EXEC dbo.depo_sp_get_tax_revert_acc
		@iso = @iso,
		@tax_revert_acc_id = @tax_revert_acc_id OUTPUT
		
	IF @tax_revert_acc_id IS NULL
	BEGIN
		RAISERROR ('ÆÄÃÌÄÔÀÃ ÂÀÃÀáÃÉËÉ ÃÀÁÄÂÒÉËÉ ÓÀÒÂÄÁËÉÓ ÃÀÁÒÖÍÄÁÉÓ ÀÍÂÀÒÉÛÉ ÀÍÀÁÒÉÓ ÅÀËÖÔÀÛÉ ÀÒ ÌÏÉÞÄÁÍÀ', 16, 1)
		RETURN 1
	END
	
	EXEC dbo.depo_sp_get_tax_revert_acc
		@iso = 'GEL',
		@tax_revert_acc_id = @tax_revert_gel_acc_id OUTPUT
		
	IF @tax_revert_gel_acc_id IS NULL
	BEGIN
		RAISERROR ('ÆÄÃÌÄÔÀÃ ÂÀÃÀáÃÉËÉ ÃÀÁÄÂÒÉËÉ ÓÀÒÂÄÁËÉÓ ÃÀÁÒÖÍÄÁÉÓ ÀÍÂÀÒÉÛÉ ËÀÒÛÉ ÀÒ ÌÏÉÞÄÁÍÀ', 16, 1)
		RETURN 1
	END
END
ELSE
IF @perc_type = 1	-- ÃÄÁÄÔÖÒÉ ÃÀÒÉÝáÅÀ
BEGIN
	IF @realize_acc_id <> @acc_id
		SELECT @is_incasso = IS_INCASSO
		FROM dbo.ACCOUNTS (NOLOCK)
		WHERE ACC_ID = @realize_acc_id
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

DECLARE
	@debit_id int,
	@credit_id int,
	@amount money,
	@descrip varchar(150)
	
IF (@restart_calc = 1) AND (@calc_type <> @pctNone)
BEGIN
	SET @amount = -@total_calc_amount

	EXEC @r = dbo._INTERNAL_ADD_DOC_PERC
		@perc_type = @perc_type, 
		@debit_id = @perc_calc_acc_id, 
		@credit_id = @prof_loss_acc_id, 
		@amount = @amount, 
		@op_code = '*%AC*', 
		@descrip = 'ÐÒÏÝÄÍÔÉÓ ÃÀÒÉÝáÅÉÓ ÛÄØÝÄÅÀ'
	IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 1 END
END

IF (@cur_accrual <> $0.0000) AND (@calc_type <> @pctNone)
BEGIN
	IF (@end_date_original = @calc_date) AND (@perc_type = 0) AND (@acc_id <> @realize_acc_id) AND (@advance_amount > $0.00)
		SET @cur_accrual = @advance_amount - @total_calc_amount -- სარგებლის წინასწარი რეალიზაციის დროს

	IF @cur_accrual >= $0.0000
		SET @descrip = 'ÐÒÏÝÄÍÔÉÓ ÃÀÒÉÝáÅÀ'
	ELSE
		SET @descrip = 'ÐÒÏÝÄÍÔÉÓ ÃÀÒÉÝáÅÉÓ ÛÄØÝÄÅÀ'	
	-- დარიცხვის საბუთის დამატება

	EXEC @r = dbo._INTERNAL_ADD_DOC_PERC 
		@perc_type = @perc_type, 
		@debit_id = @perc_calc_acc_id, 
		@credit_id = @prof_loss_acc_id, 
		@amount = @cur_accrual, 
		@op_code = '*%AC*', 
		@descrip = @descrip
	IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 1 END

END

DECLARE
	@depo_need_move bit

SET @depo_need_move = 0

IF @depo_op_type = dbo.depo_fn_const_op_close()
BEGIN
	SELECT @depo_need_move = ANNULMENT_REALIZE 
	FROM dbo.DEPO_DEPOSITS (NOLOCK)
	WHERE DEPO_ID = @depo_id 
	IF @@ERROR<>0 OR @@ROWCOUNT<>1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 1 END
END

IF @need_move <> 0 OR @depo_need_move <> 0
BEGIN
	DECLARE
		@tax_payed money,
		@tax_payed_amount money,
		@tax_payed_amount_equ money,
		@calc_amount money
		
	SET @tax_payed = NULL
	
	IF (@restart_calc = 1) AND (@calc_type <> @pctNone)
	BEGIN
		IF @depo_tax_interest_type = 0
		BEGIN
			SET @calc_amount = -@total_payed_amount
			SET @tax_payed_amount = $0.00
		END	
		ELSE
		BEGIN
			SET @calc_amount = -(@total_payed_amount - @total_tax_payed_amount)
			SET @tax_payed_amount = -@total_tax_payed_amount
			SET @tax_payed_amount_equ = -@total_tax_payed_amount_equ
		END	
		
		SET @debit_id = @realize_acc_id
		
		IF (@calc_amount < $0.00) AND (@restore_acc_id IS NOT NULL)
			SET @debit_id = @restore_acc_id
			
		IF (@advance_amount > $0.00) AND (@calc_amount < $0.00)
			SET @advance_amount = @advance_amount + @calc_amount	

		EXEC @r = dbo._INTERNAL_ADD_DOC_PERC 
			@perc_type = @perc_type, 
			@debit_id = @debit_id,
			@credit_id = @perc_calc_acc_id,--@prof_loss_acc_id
			@amount = @calc_amount, 
			@op_code = '*%RL*', 
			@descrip = 'ÃÀÒÉÝáÖËÉ ÐÒÏÝÄÍÔÉÓ ÒÄÀËÉÆÀÝÉÉÓ ÛÄØÝÄÅÀ',
			@tax_rate = $0.00,
			@tax_acc_id = @tax_acc_id,
			@main_acc_id = @acc_id,
			@need_trail = @need_trail 
		IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 1 END
		
		IF @tax_payed_amount < $0.00
		BEGIN
			SET @credit_id = ISNULL(@restore_acc_id, @realize_acc_id)
			
			EXEC @r = dbo._INTERNAL_ADD_DOC_PERC 
				@perc_type = @perc_type, 
				--@debit_id = @tax_acc_id,
				@debit_id = @tax_revert_acc_id,
				@credit_id = @credit_id,
				@amount = @tax_payed_amount, 
				@op_code = '*%RL*', 
				@descrip = 'ÆÄÃÌÔÀÃ ÂÀÃÀáÃÉËÉ ÃÀÁÂÒÉËÉ ÓÀÒÂÄÁËÉÓ ÃÀÁÒÖÍÄÁÀ'
			IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 1 END
			
			SET @debit_id = ISNULL(@restore_acc_id, @realize_acc_id)
		
			EXEC @r = dbo._INTERNAL_ADD_DOC_PERC 
				@perc_type = @perc_type, 
				@debit_id = @debit_id,
				@credit_id = @perc_calc_acc_id,
				@amount = @tax_payed_amount, 
				@op_code = '*%TX*', 
				@descrip = 'ÆÄÃÌÔÀÃ ÂÀÃÀáÃÉËÉ ÃÀÁÂÒÉËÉ ÓÀÒÂÄÁËÉÓ ÃÀÁÒÖÍÄÁÀ'
			IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 1 END
		END
	END

	IF @calc_type <> @pctNone
		SET @credit_id = @perc_calc_acc_id
	ELSE
		SET @credit_id = @prof_loss_acc_id

	IF (@restart_calc = 1)
	BEGIN
		IF @depo_tax_interest_type = 0
			SET @tax_payed = @total_tax_payed_amount
		SET @calc_amount = @cur_accrual
	END 
	ELSE
		SET @calc_amount = ROUND(@prev_calc_amount + @cur_accrual, 2)
	

	IF (@calc_amount <= 0)
		SET @tax_rate = $0.00

	IF @calc_amount >= $0.00
	BEGIN 
		SET @descrip = 'ÃÀÒÉÝáÖËÉ ÐÒÏÝÄÍÔÉÓ ÒÄÀËÉÆÀÝÉÀ'
		IF (@advance_acc_id IS NOT NULL) AND (@accrue_amount IS NULL)
			SET @tax_rate = $0.00
	END
	ELSE
		SET @descrip = 'ÃÀÒÉÝáÖËÉ ÐÒÏÝÄÍÔÉÓ ÒÄÀËÉÆÀÝÉÉÓ ÛÄØÝÄÅÀ'	
		
	IF @restore_acc_id IS NOT NULL
		SET @debit_id = @restore_acc_id
	ELSE
		SET @debit_id = @realize_acc_id	
	
	EXEC @r = dbo._INTERNAL_ADD_DOC_PERC 
		@perc_type = @perc_type, 
		@debit_id = @debit_id,
		@credit_id = @credit_id,
		@amount = @calc_amount, 
		@op_code = '*%RL*', 
		@descrip = @descrip,
		@tax_rate = @tax_rate,
		@tax_acc_id = @tax_acc_id,
		@main_acc_id = @acc_id,
		@need_trail = @need_trail,
		@tax_payed = @tax_payed
	IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 1 END

END

DECLARE 
	@op_code TOPCODE,
	@doc_type smallint,
	@parent_rec_id int,
	@amount2 money,
	@sign smallint

SET @doc_type = CASE @perc_type WHEN 0 THEN 30 WHEN 1 THEN 32 WHEN 3 THEN 30 END

SET @parent_rec_id = 0
IF (SELECT COUNT(*) FROM #accruals WHERE ROUND(AMOUNT, 2) > $0.0000) > 1
	SET @parent_rec_id = -1
	
IF (@simulate = 0) AND (ISNULL(@accumulate_schema_intrate, 0) = 5) AND ((SELECT COUNT(*) FROM #accruals WHERE ROUND(AMOUNT, 2) > $0.0000) > 0)
BEGIN
	UPDATE dbo.ACCOUNTS_CRED_PERC
	SET FORMULA = @formula
	WHERE ACC_ID = @acc_id
	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RETURN (31); END
END

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
		IF @simulate = 0
		BEGIN
			SET @descrip = @descrip + ' - ' + CONVERT(varchar(34), @account) + '/' + @iso
			
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

				@check_saldo = 0,		-- შეამოწმოს თუ არა მინ. ნაშთი
				@add_tariff = 0,		-- დაამატოს თუ არა ტარიფის საბუთი
				@info = 0				-- რეალურად გატარდეს, თუ მხოლოდ ინფორმაციაა

			IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 31 END
		END
		
		SET @amount = @amount * @sign
		SET @amount2 = @amount2 * @sign
		IF @perc_type = 1
		BEGIN
			SET @amount = - @amount 
			SET @amount2 = - @amount2
		END

		DECLARE @prev_date smalldatetime

		IF @op_code = '*%RL*'	-- Realization
			SET @prev_date = @prev_last_move_date
		ELSE
			SET @prev_date = @prev_last_calc_date

		IF @simulate = 0
		BEGIN
			INSERT INTO dbo.DOC_DETAILS_PERC (DOC_REC_ID, ACC_ID, ID, ACCR_DATE, PREV_DATE, AMOUNT4, PREV_MIN_PROCESSING_DATE, PREV_MIN_PROCESSING_TOTAL_CALC_AMOUNT)
			VALUES (@rec_id, @acc_id, @depo_id, @calc_date, @prev_date, @amount, @min_processing_date, @min_processing_total_calc_amount)
			IF @@ERROR<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 31 END
			
			IF @parent_rec_id <= 0
				SET @parent_rec_id = @rec_id
		END 

		IF @op_code = '*%AC*'	-- Accrual
		BEGIN
			IF @simulate = 0
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
		END
		ELSE
		IF @op_code = '*%RL*'	-- Realization
		BEGIN
			IF @simulate = 0
			BEGIN
				IF @perc_type = 1
					UPDATE dbo.ACCOUNTS_DEB_PERC
					SET LAST_MOVE_DATE = @calc_date, TOTAL_PAYED_AMOUNT = ISNULL(TOTAL_PAYED_AMOUNT, $0.0000) + @amount2, CALC_AMOUNT = CASE WHEN @calc_type <> @pctNone THEN ISNULL(CALC_AMOUNT, $0.0000) - @amount ELSE CALC_AMOUNT END
					WHERE ACC_ID = @acc_id
				ELSE
				IF @perc_type = 0
				BEGIN
					UPDATE dbo.ACCOUNTS_CRED_PERC
					SET LAST_MOVE_DATE = @calc_date, TOTAL_PAYED_AMOUNT = ISNULL(TOTAL_PAYED_AMOUNT, $0.0000) + @amount2, CALC_AMOUNT = CASE WHEN @calc_type <> @pctNone THEN ISNULL(CALC_AMOUNT, $0.0000) - @amount ELSE CALC_AMOUNT END
					WHERE ACC_ID = @acc_id
				END
			END
			IF @perc_type = 0
				SET @total_payed_amount_ = ISNULL(@total_payed_amount_, $0.00) + @amount2
		END
		ELSE
		IF @op_code = '*%TX*'	-- Realization Tax
		BEGIN
			IF @simulate = 0
			BEGIN
				IF @perc_type = 0
				BEGIN
					UPDATE dbo.ACCOUNTS_CRED_PERC
					SET TOTAL_TAX_PAYED_AMOUNT = ISNULL(TOTAL_TAX_PAYED_AMOUNT, $0.0000) + @amount2,
						TOTAL_TAX_PAYED_AMOUNT_EQU = ISNULL(TOTAL_TAX_PAYED_AMOUNT_EQU, $0.0000) + ROUND(dbo.get_equ(@amount2, @iso, @doc_date), 2)
					WHERE ACC_ID = @acc_id
				END
			END
		END
		IF @@ERROR<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 1 END
	END

	FETCH NEXT FROM cc INTO @debit_id, @credit_id, @amount, @op_code, @descrip, @sign
END

CLOSE cc
DEALLOCATE cc

SET @rec_id = CASE WHEN @parent_rec_id = 0 THEN @rec_id ELSE @parent_rec_id END

IF (@simulate = 0) AND (@advance_amount > $0.00) AND (@accrue_amount IS NOT NULL) AND (@restart_calc = 1)
BEGIN
	DECLARE 
		@rec_id_tmp int
		
	SET @amount = @advance_amount + @tax_payed_amount
	SET @descrip = 'ßÉÍÀÓßÀÒ ÒÄÀËÉÆÄÁÖËÉ ÓÀÒÂÄÁËÉÓ ÃÀÁÒÖÍÄÁÀ'
		
	IF @amount > 0
	BEGIN
		EXEC @r = dbo.ADD_DOC4
			@rec_id = @rec_id_tmp OUTPUT,
			@user_id = @user_id,
			@doc_type = 98,
			@doc_date = @doc_date,
			@debit_id = @restore_acc_id,
			@credit_id = @realize_acc_id,
			@iso = @iso,
			@amount = @amount,
			@rec_state = 20,
			@descrip = @descrip,
			@op_code = '*%RL*',
			@account_extra = @acc_id,
			@dept_no = @dept_no,
			@channel_id = 800,
			@flags = 0x15F4,
			@parent_rec_id = @rec_id,
			@check_saldo = 0

		IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 31 END

		IF ISNULL(@rec_id, 0) = 0
			SET @rec_id = @rec_id_tmp
	END
END

IF (@simulate = 0) AND (@tax_payed_amount < $0.00)
BEGIN
	IF  @iso <> 'GEL'
	BEGIN
		DECLARE
			@conv_rec_id_1 int,
			@conv_rec_id_2 int
			
		SET @descrip = 'ÆÄÃÌÄÔÀÃ ÂÀÃÀáÉËÉ ÃÀÁÄÂÒÉËÉ ÓÀÒÂÄÁËÉÓ ÊÏÍÅÄÒÔÀÝÉÀ'
		SET @tax_payed_amount = ABS(@tax_payed_amount)
		SET @tax_payed_amount_equ = ABS(@tax_payed_amount_equ)
			
		EXEC @r = dbo.ADD_CONV_DOC4
			@rec_id_1			= @conv_rec_id_1 OUTPUT,
			@rec_id_2			= @conv_rec_id_2 OUTPUT,
			@user_id			= @user_id,
			@iso_d				= 'GEL',
			@iso_c				= @iso,
			@amount_d			= @tax_payed_amount_equ,          
			@amount_c			= @tax_payed_amount,
			@debit_id			= @tax_revert_gel_acc_id,
			@credit_id			= @tax_revert_acc_id,
			@doc_date			= @doc_date,
			@account_extra		= @acc_id,
			@descrip1			= @descrip,   
			@descrip2			= @descrip,   
			@rec_state			= 20,
			@par_rec_id			= @rec_id,
			@dept_no			= @dept_no,
			@check_saldo		= 0,
			@add_tariff			= 0,
			@info				= 0
		IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 31 END
	
		IF ISNULL(@rec_id, 0) = 0
			SET @rec_id = @rec_id_tmp
	END	

	/*SET @descrip = 'ÆÄÃÌÄÔÀÃ ÂÀÃÀáÉËÉ ÃÀÁÄÂÒÉËÉ ÓÀÒÂÄÁÄËÉ'
	SET @tax_payed_amount = ABS(@tax_payed_amount_equ)

	EXEC @r = dbo.ADD_DOC4
		@rec_id = @rec_id_tmp OUTPUT,
		@user_id = @user_id,
		@doc_type = 98,
		@doc_date = @doc_date,
		@debit_id = @tax_gel_acc_id,
		@credit_id = @tax_revert_gel_acc_id,
		@iso = 'GEL',
		@amount = @tax_payed_amount,
		@rec_state = 20,
		@descrip = @descrip,
		@op_code = '*%TX*',
		@account_extra = @acc_id,
		@dept_no = @dept_no,
		@channel_id = 800,
		@flags = 0x15F4,
		@parent_rec_id = @rec_id,
		@check_saldo = 0
	IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 31 END

	IF ISNULL(@rec_id, 0) = 0
		SET @rec_id = @rec_id_tmp*/
END


SET @interest_amount = @total_payed_amount_ - @total_payed_amount

IF @simulate = 0
BEGIN
	SET @need_move = @need_move_

	IF (@simulate = 0) AND (@depo_id IS NOT NULL) AND ((@need_move = 1) OR (@end_date_original = @calc_date) OR (@depo_op_type IS NOT NULL)) AND (@perc_type = 0)
	BEGIN
		IF (@depo_op_type IN (dbo.depo_fn_const_op_annulment(), dbo.depo_fn_const_op_annulment_amount(), dbo.depo_fn_const_op_close_default()))
			GOTO _end
		DECLARE
			@op_amount money,
			@op_data xml,
			@alarm_note varchar(255),
			@accrue_doc_rec_id int
		DECLARE
			@depo_realize_schema int,
			@interest_realize_adv bit,
			@prolongable bit,
			@renewable bit,
			@renew_capitalized bit,
			@depo_prev_start_date smalldatetime,
			@depo_prev_period int,
			@depo_prev_end_date smalldatetime,
			@depo_prev_agreement_amount money,
			@depo_prev_amount money,
			@depo_prev_intrate money,
			@depo_prev_real_intrate decimal(32, 12),
			@depo_prev_spend_const_amount money,
			@depo_prev_formula varchar(255),

			@depo_renew_start_date smalldatetime,
			@depo_renew_end_date smalldatetime,
			@depo_renew_agreement_amount money,
			@depo_interest_tax_amount money,
			@depo_renew_intrate money,
			@depo_date_type int,
			@renew_max int,
			@renew_count int,
			@renew_last_prod_id int,
			@deposit_default bit
			
		DECLARE
			@can_renew bit,
			@msg varchar(200)

		SET @alarm_note = NULL		

		SELECT @prod_id = PROD_ID, @iso = ISO, @interest_realize_adv = INTEREST_REALIZE_ADV, @depo_prev_agreement_amount = AGREEMENT_AMOUNT,
			@depo_prev_amount = AMOUNT, @depo_prev_intrate = INTRATE, @depo_prev_real_intrate = REAL_INTRATE,
			@depo_prev_spend_const_amount = SPEND_CONST_AMOUNT, @depo_realize_schema = DEPO_REALIZE_SCHEMA,
			@depo_prev_start_date = [START_DATE], @depo_prev_period = PERIOD, @depo_prev_end_date = END_DATE, @depo_date_type = DATE_TYPE,
			@prolongable = PROLONGABLE,
			@renewable = RENEWABLE, @renew_capitalized = RENEW_CAPITALIZED,	@renew_max = RENEW_MAX, @depo_prev_formula = FORMULA,
			@renew_count = ISNULL(RENEW_COUNT, 0), @renew_last_prod_id = RENEW_LAST_PROD_ID, @deposit_default = DEPOSIT_DEFAULT
		FROM dbo.DEPO_DEPOSITS (NOLOCK)
		WHERE DEPO_ID = @depo_id
		IF @@ERROR<>0 OR @@ROWCOUNT<>1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 31 END
			
		IF @depo_op_type IS NULL
		BEGIN
			IF @end_date_original = @calc_date
			BEGIN
				IF (@renewable = 1) AND (@deposit_default = 0)
				BEGIN
					IF @renew_max IS NULL
					BEGIN
						EXEC @r = dbo.depo_sp_check_renew_product
							@depo_id = @depo_id,
							@new_prod_id = NULL,
							@can_renew = @can_renew OUTPUT,
							@msg = @msg OUTPUT
						IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 51 END

						IF @can_renew = 1
							SET @depo_op_type = dbo.depo_fn_const_op_renew()
						ELSE
						BEGIN
							SET @alarm_note = @msg
							SET @depo_op_type = dbo.depo_fn_const_op_close()
						END	
					END	
					ELSE	
					BEGIN
						IF @renew_count >= @renew_max
						BEGIN
							IF @deposit_default = 1
								SET @depo_op_type = dbo.depo_fn_const_op_close_default()
							ELSE	
								SET @depo_op_type = dbo.depo_fn_const_op_close()
						END
						ELSE
						BEGIN				
							IF (@renew_last_prod_id IS NOT NULL) AND (@renew_max = @renew_count + 1) --'ÀÍÀÁÒÉÓ ÂÀÍÀáËÄÁÀ ÛÄÓÀÞÄËÄÁËÉÀ ÌáÏËÏÃ ÓáÅÀ ÐÒÏÃÖØÔÉÈ!'
							BEGIN
								EXEC @r = dbo.depo_sp_check_renew_product
									@depo_id = @depo_id,
									@new_prod_id = @renew_last_prod_id,
									@can_renew = @can_renew OUTPUT,
									@msg = @msg OUTPUT
								IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 51 END

								IF @can_renew = 1
									SET @depo_op_type = dbo.depo_fn_const_op_renew_by_product()
								ELSE
								BEGIN
									SET @alarm_note = @msg
									SET @depo_op_type = dbo.depo_fn_const_op_close()
								END	
							END	
							ELSE
							BEGIN
								EXEC @r = dbo.depo_sp_check_renew_product
									@depo_id = @depo_id,
									@new_prod_id = NULL,
									@can_renew = @can_renew OUTPUT,
									@msg = @msg OUTPUT
								IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 51 END

								IF @can_renew = 1
									SET @depo_op_type = dbo.depo_fn_const_op_renew()
								ELSE
								BEGIN
									SET @alarm_note = @msg
									SET @depo_op_type = dbo.depo_fn_const_op_close()
								END	
							END	
						END	
					END
				END
				ELSE
				BEGIN
					IF (@prolongable = 1) AND (@deposit_default = 0)
					BEGIN
						IF dbo.depo_fn_auto_prolongation(@depo_id) = 1
							SET @depo_op_type = dbo.depo_fn_const_op_prolongation_intrate_change()
					END
					IF @depo_op_type IS NULL
					BEGIN
						IF @deposit_default = 1
							SET @depo_op_type = dbo.depo_fn_const_op_close_default()
						ELSE	
							SET @depo_op_type = dbo.depo_fn_const_op_close()
					END		
				END	
			END
			ELSE
			BEGIN
				IF (@need_move = 1) AND (ISNULL(@depo_realize_amount, $0.00) > $0.00)
					SET @depo_op_type = dbo.depo_fn_const_op_withdraw_schedule()
			END		
		END

		DECLARE
			@state tinyint

		SELECT @state = [STATE]
		FROM dbo.DEPO_DEPOSITS
		WHERE DEPO_ID = @depo_id

		IF @depo_op_type = dbo.depo_fn_const_op_withdraw_schedule()
		BEGIN

			SET @op_amount = - dbo.acc_get_balance(@acc_id, @calc_date, 0, 0, 0)
			
			IF @depo_realize_schema = 4
				SET @depo_realize_amount = @depo_realize_amount - @interest_amount
			ELSE
			IF @depo_realize_schema = 5
				SET @depo_realize_amount = @depo_realize_amount - (@interest_amount - ROUND(@interest_amount * @tax_rate / $100.00, 2))

			IF @op_amount >= @depo_realize_amount
				SET @op_amount = @depo_realize_amount
			ELSE
				SET @depo_realize_amount = @op_amount
			
			SET @op_amount = @op_amount + @interest_amount

			SET @op_data =
				(SELECT
					@depo_realize_acc_id AS DEPO_REALIZE_ACC_ID,
					@depo_prev_amount AS PREV_AMOUNT,
					@depo_realize_amount AS DEPO_AMOUNT,
					@interest_amount AS INTEREST
			FOR XML RAW, TYPE)

		END
		ELSE
		IF @depo_op_type = dbo.depo_fn_const_op_renew()
		BEGIN
			SET @op_amount = @depo_prev_amount
			SET @depo_renew_start_date = @doc_date
			SET @depo_renew_agreement_amount = @depo_prev_amount
			
			DECLARE
				@day_correction int,			
				@generate_new_schedule bit,
				@realize_type int,
				@convertible bit,
				@spend bit,
				@accumulative bit,
				@child_deposit bit

			SELECT @depo_realize_schema = DEPO_REALIZE_SCHEMA, @realize_type = REALIZE_TYPE, @convertible = CONVERTIBLE,
					@spend = SPEND, @accumulative = ACCUMULATIVE, @child_deposit = CHILD_DEPOSIT
			FROM dbo.DEPO_DEPOSITS (NOLOCK)
			WHERE DEPO_ID = @depo_id

			SET @day_correction = 0
			
			IF @depo_date_type = 1
				SET @depo_renew_end_date = DATEADD (day, @depo_prev_period, @depo_renew_start_date)
			ELSE
				SET @depo_renew_end_date = DATEADD (month, @depo_prev_period, @depo_renew_start_date)

			IF dbo.date_is_holiday(@depo_renew_end_date) = 1
			BEGIN
				DECLARE
					@depo_holiday_type int,
					@depo_renew_end_date_org smalldatetime
				
				SET @depo_renew_end_date_org = @depo_renew_end_date
					
				EXEC dbo.GET_SETTING_INT 'OPT_D_HOLIDAY_TYPE', @depo_holiday_type OUTPUT

				IF @depo_holiday_type = 1
				BEGIN 
					SET @depo_renew_end_date = dbo.date_next_workday(@depo_renew_end_date)
					SET @day_correction = DATEDIFF(DAY, @depo_renew_end_date_org, @depo_renew_end_date) 
				END	
				ELSE
				IF @depo_holiday_type = 2 
				BEGIN
					SET @depo_renew_end_date = dbo.date_prev_workday(@depo_renew_end_date)
					SET @day_correction = DATEDIFF(DAY, @depo_renew_end_date, @depo_renew_end_date_org) 
				END	
			END
			
			EXEC @r = dbo.depo_sp_get_deposit_intrate
				@prod_id = @prod_id,
				@iso = @iso,
				@period = @depo_prev_period,
				@intrate = @depo_renew_intrate OUTPUT,
				@show_result = 0
				
			IF @@ERROR<>0 OR @r<>0 OR (@depo_renew_intrate IS NULL) BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 333 END

			
			IF @renew_capitalized = 1
			BEGIN 
				IF ISNULL(@tax_rate, $0.00) <> $0.00
				BEGIN
					SET @depo_interest_tax_amount = (ISNULL(@interest_amount, $0.00) - ROUND(ISNULL(@interest_amount, $0.00) * @tax_rate / $100.0, 2))
					SET @op_amount = @op_amount + @depo_interest_tax_amount
				END	
				ELSE
				BEGIN
					SET @depo_interest_tax_amount = ISNULL(@interest_amount, $0.00)
					SET @op_amount = @op_amount + ISNULL(@interest_amount, $0.00)
				END	
			END
			
			IF (@depo_realize_schema <> 2) AND (@realize_type IN (1, 2)) AND (@convertible <> 1) AND (@spend <> 1) AND (@accumulative <> 1) AND (@child_deposit <> 1)
				SET @generate_new_schedule = 1
			ELSE SET @generate_new_schedule = 0

			SET @op_data =
				(SELECT
					@renew_capitalized AS RENEW_CAPITALIZED,
					@depo_prev_start_date AS PREV_START_DATE,
					@depo_prev_period AS PREV_PERIOD,
					@depo_prev_end_date AS PREV_END_DATE,
					@depo_prev_agreement_amount AS PREV_AGREEMENT_AMOUNT,
					@depo_prev_amount AS PREV_DEPO_AMOUNT,
					@interest_amount AS INTEREST_AMOUNT,
					@depo_interest_tax_amount AS INTEREST_TAX_AMOUNT,
					@depo_prev_intrate AS PREV_INTRATE,
					@depo_prev_real_intrate AS PREV_REAL_INTRATE,
					@depo_prev_spend_const_amount AS PREV_SPEND_CONST_AMOUNT,
					@depo_prev_formula AS PREV_FORMULA,
					
					@depo_renew_start_date AS [START_DATE],
					@depo_prev_period AS PERIOD,
					@day_correction AS CORRECTION,
					@depo_renew_end_date AS END_DATE,
					@depo_renew_intrate AS INTRATE,
					@op_amount AS AGREEMENT_AMOUNT,
					
					@renew_count + 1 AS RENEW_COUNT,
					@renew_max AS MAX_RENEW_COUNT,
					CONVERT(bit, 1) AS ARCHIVE_DEPOSIT,
					@generate_new_schedule AS GENERATE_NEW_SCHEDULE
			FOR XML RAW, TYPE)
		END
		ELSE
		IF @depo_op_type = dbo.depo_fn_const_op_prolongation_intrate_change()
		BEGIN
			DECLARE
				@prolong_new_end_date smalldatetime,
				@prolong_new_intrate money,
				@prolong_change_intrate bit

			SET @prolong_change_intrate	= 0
				
			SET @op_amount = NULL
			
			EXEC @r = dbo.depo_sp_get_auto_prolongation_params_on_user
				@depo_id = @depo_id,
				@end_date = @calc_date,
				@intrate = @intrate,
				@new_end_date = @prolong_new_end_date OUTPUT,
				@new_intrate = @prolong_new_intrate OUTPUT
				
			IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 1 END
			
			IF @prolong_new_intrate <> @intrate
				SET @prolong_change_intrate	= 1
				
			SET @op_data =
				(SELECT
					CONVERT(bit, 1) AS ARCHIVE_DEPOSIT,
					@end_date_original AS PREV_END_DATE,
					@prolong_new_end_date AS NEW_END_DATE,
					@intrate AS PREV_INTRATE, 
					@prolong_new_intrate AS NEW_INTRATE,
					@prolong_change_intrate AS CHANGE_INTRATE
				FOR XML RAW, TYPE)
		END
		ELSE
		IF @depo_op_type = dbo.depo_fn_const_op_close()
		BEGIN
			IF @alarm_note IS NOT NULL
				SET @alarm_note = 'ÀÍÀÁÀÒÉÓ ÂÀÍÀáËÄÁÀ ÛÄÖÞËÄÁÄËÉÀ: ' + @alarm_note;
		
			SET @op_amount = - dbo.acc_get_balance(@acc_id, @calc_date, 0, 0, 0)
			IF @interest_realize_adv = 1
				SET @interest_amount = NULL

			IF @interest_realize_acc_id = @acc_id
				SET @depo_realize_amount = @op_amount - ISNULL(@interest_amount, $0.00)
			ELSE
			BEGIN
				SET @depo_realize_amount = @op_amount
				SET @op_amount = @op_amount + ISNULL(@interest_amount, $0.00)	
			END	
			
			SET @op_data =
				(SELECT
					@depo_realize_amount AS DEPO_REALIZE_AMOUNT,
					@interest_amount AS INTEREST_REALIZE_AMOUNT,
					@depo_realize_acc_id AS DEPO_REALIZE_ACC_ID, 
					@interest_realize_acc_id AS INTEREST_REALIZE_ACC_ID,
					@state AS DEPO_PREV_STATE
				FOR XML RAW, TYPE)
		END
		ELSE
		IF @depo_op_type = dbo.depo_fn_const_op_close_default()
		BEGIN
			DECLARE
				@annul_amount money,
				@annul_intrate money

			EXEC @r = dbo.depo_sp_calc_annul_amount		
				@depo_id = @depo_id,
				@user_id = @user_id,
				@dept_no = @dept_no,
				@annul_date = @calc_date,
				@annul_amount = @annul_amount OUTPUT,
				@annul_intrate = @annul_intrate OUTPUT,
				@show_result = 0

			SET @op_amount = - dbo.acc_get_balance(@acc_id, @calc_date, 0, 0, 0)
			
			SELECT @last_move_date = LAST_MOVE_DATE, @calc_amount = ISNULL(CALC_AMOUNT, $0.00),
				@total_calc_amount = ISNULL(TOTAL_CALC_AMOUNT, $0.00), @total_payed_amount = ISNULL(TOTAL_PAYED_AMOUNT, $0.00)
			FROM dbo.ACCOUNTS_CRED_PERC P
			WHERE ACC_ID = @acc_id
			
			SET @op_data =
				(SELECT
					@op_amount AS DEPO_REALIZE_AMOUNT,
					@total_payed_amount AS DEPO_REALIZE_INTEREST,
					@last_move_date AS LAST_REALIZE_DATE,
					@calc_amount AS CALC_AMOUNT,
					@total_calc_amount AS TOTAL_CALC_AMOUNT,
					@depo_realize_acc_id AS DEPO_REALIZE_ACC_ID,
					@depo_realize_acc_id AS INTEREST_REALIZE_ACC_ID,
					@state AS DEPO_PREV_STATE,
					@annul_intrate AS ANNUL_INTRATE,
					@total_tax_payed_amount AS TOTAL_TAX_PAYED_AMOUNT,
					@total_tax_payed_amount_equ AS TOTAL_TAX_PAYED_AMOUNT_EQU,
					0 AS ACC_ARC_REC_ID
				FOR XML RAW, TYPE)
				
			SET @op_amount = @annul_amount
		END		

		SET @accrue_doc_rec_id = CASE WHEN @parent_rec_id = 0 THEN @rec_id ELSE @parent_rec_id END

		IF (@depo_op_id IS NULL) AND (@depo_op_type IS NOT NULL)
		BEGIN
			INSERT INTO dbo.DEPO_OP WITH (UPDLOCK)
				(DEPO_ID, OP_DATE, OP_TYPE, OP_STATE, AMOUNT, ISO, OP_DATA, ALARM_NOTE, [OWNER], ACCRUE_DOC_REC_ID)
			VALUES
				(@depo_id, @doc_date, @depo_op_type, 0, @op_amount, @iso, @op_data, @alarm_note, @user_id, @accrue_doc_rec_id)
			IF @@ERROR <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 1 END
			
			SET @depo_op_id = SCOPE_IDENTITY()

			EXEC @r = dbo.depo_sp_add_op_action
				@op_id = @depo_op_id,
				@op_type = @depo_op_type,	
				@depo_id = @depo_id,
				@user_id = @user_id

			IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 1 END

			EXEC @r = dbo.depo_sp_add_op_accounting
				@doc_rec_id = @depo_op_doc_rec_id OUTPUT,
				@accrue_doc_rec_id = @accrue_doc_rec_id OUTPUT,
				@op_id = @depo_op_id,
				@user_id = @user_id

			IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 1 END

			IF (@depo_op_doc_rec_id IS NOT NULL) OR (@accrue_doc_rec_id IS NOT NULL)
			BEGIN
				UPDATE dbo.DEPO_OP WITH (UPDLOCK)
				SET DOC_REC_ID = CASE WHEN @depo_op_doc_rec_id IS NOT NULL THEN @depo_op_doc_rec_id ELSE DOC_REC_ID END,
					ACCRUE_DOC_REC_ID = CASE WHEN @accrue_doc_rec_id IS NOT NULL THEN @accrue_doc_rec_id ELSE ACCRUE_DOC_REC_ID END
				WHERE OP_ID = @depo_op_id
				IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 1 END
			END
 
			EXEC @r = dbo.depo_sp_exec_op @doc_rec_id = @depo_op_doc_rec_id OUTPUT, @accrue_doc_rec_id = @accrue_doc_rec_id OUTPUT, @op_id = @depo_op_id, @user_id = @user_id
			IF @r <> 0 AND @@ERROR <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 1 END
		END

		IF @depo_op_id IS NOT NULL
		BEGIN
			UPDATE dbo.DEPO_OP WITH (UPDLOCK)
			SET ACCRUE_DOC_REC_ID = CASE WHEN @accrue_doc_rec_id IS NOT NULL THEN @accrue_doc_rec_id ELSE ACCRUE_DOC_REC_ID END
			WHERE OP_ID = @depo_op_id
			IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 1 END

			IF @depo_op_type = dbo.depo_fn_const_op_close()
			BEGIN
				UPDATE dbo.DEPO_OP WITH (UPDLOCK)
				SET OP_DATA = @op_data
				WHERE OP_ID = @depo_op_id
				IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 1 END
			END
		END
	END
END

_end:

IF @simulate = 1 AND @show_result = 1
	SELECT @doc_date AS DOC_DATE, @calc_date AS CALC_DATE, @account AS ACCOUNT, dbo.acc_get_account(DEBIT_ID) AS DEBIT, dbo.acc_get_account(CREDIT_ID) AS CREDIT, *
	FROM #accruals

DROP TABLE #accruals

IF @simulate = 0 AND @internal_transaction=1 AND @@TRANCOUNT>0 
	COMMIT TRAN
GO
