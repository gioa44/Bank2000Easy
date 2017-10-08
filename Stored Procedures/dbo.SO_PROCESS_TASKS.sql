SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[SO_PROCESS_TASKS]
	@date datetime,								--პროცესინგის თარიღი
	@task_id int = NULL,						--დავალების ნომერი
	@processing_mode int = 1,					--დავალების შესრულების დრო: 1 - დღის ბოლო, 2 - დღის დასაწყისი
	@user_id int = NULL,						--დავალების შემსრულებელი
	@fixed_date datetime = NULL,				--მხოლოდ კონკრეტული თარიღის დავალებები
	@raise_exception bit = 0,					--სტატუსების შეცვლის მაგივრად აიწიოს შეცდომა (გამოიყენება მხოლოდ მაშინ როდესაც @task_id IS NOT NULL)
	@perform_debt_action int = NULL,			--შეასრულოს დავალება ამ ქმედების კოდით (გამოიყენება მხოლოდ მაშინ @task_id IS NOT NULL, არ შეიძლება იყოს "დაელოდოს შემდეგ ინსტრუქციას")
	@doc_rec_id int = NULL OUTPUT				--შესრულებული დავალებასთან დაკავშირებული საბუთის ნომერი
AS
		--TO DO გასათვალისწინებელია ოვერდრაფტში გასვლის ამბავი (მეორე იტერაციაზე რო ჩამოუაროს ოვერდრაფტზე გასასვლელებს)
DECLARE 
	@dept_no int,
	@processing_task_id int,
	@id int,
	@agreement_no varchar(50),
	@client_no int,
	@retry_count_per_pay int,
	@max_failure_count int,
	@debt_action int,				-- 0 სრული თანხა, 1 ნაწილობრივი თანხა, 2 იგნორირება, 3 დაძალება, 4 დაელოდოს შემდეგ ინსტრუქციას
	@priority int,
	@order_descrip varchar(max),
	@order_descrip_lat varchar(max),
	@fx_rate_type int,				-- 1 ოფიციალური, 2, კომერციული
	@task_state int,				-- 0 გაუქმებული, 10 მიმდინარე დაუავტორიზებელი, 20 დაავტორიზებული, 30 აქტიური, 255 დახურული
	@schedule_date smalldatetime,
	@schedule_state int,			-- 0 გაუქმებული, 10 გასააქტიურებელი, 20 აქტიური, 30 დაელოდოს მოქმედებას, 40 დასრულებული წარუმატებლად, 50 დასრულდა წარმატებით
	@fails_by_date int,
	@fault_message varchar(max),
	@fault_code int,
	@fee_recv_percent money,
	@fee_min money,
	@product_type int,				-- 1 გადარიცხვა, 2 შეგროვება, 3 განაწილება
	@product_state int,				-- 0 გაუქმებული, 10 მიმდინარე დაუავტორიზებელი, 20 დაავტორიზებული, 30 აქტიური
	@product_owner int,				-- 0 ბანკი, 1 კლიენტი
	@use_tariff bit,
	@op_code varchar(50),
	@doc_state int,
	@prod_doc_type int,
	@use_overdraft bit,
	@end_date datetime,
	
	@trigger_amount money,
	@min_balance_amount money,
	@transaction_amount money,
	@transaction_amount_equ money,
	@blocked_amount money,
	
	@debit_acc_id int,
	@credit_acc_id int,
	@debit_acc TACCOUNT,
	@credit_acc TACCOUNT,
	@debit_acc_type int,
	@debit_acc_sub_type int,
	@credit_acc_type int,
	@credit_acc_sub_type int,
	@current_debit_amount money,
	@current_credit_amount money,
	@debit_ccy TISO,
	@credit_ccy TISO,
	@is_percent bit,
	@equ_iso TISO,
	
	@descrip nvarchar(250),
	@descrip_lat nvarchar(250),
	@saxaz_code varchar(9),
	@tax_payer_name varchar(100),
	@tax_payer_code varchar(11),
	@cor_bank_code varchar(37),
	@cor_bank_name varchar(105),
	@intermed_bank_code varchar(37),
	@intermed_bank_name varchar(105),
	@extra_info varchar(255),
	@extra_info_descrip bit,
	@det_of_charg char(3),
	@receiver_acc varchar(37),
	@receiver_acc_name varchar(105),
	@sender_address_lat varchar(105),
	@receiver_address_lat varchar(105),
	@receiver_bank_code varchar(37),
	@receiver_bank_name varchar(105),
	@receiver_tax_code varchar(11),
	@lim_amount money,
	@is_master_acc bit,
	@is_helper_acc bit,
	@collect_amount money,
	@distribute_amount money,
	@is_partial bit,
	@ref_no int,
	@tariff_amount money,
	@already_used_amount money,

	@sender_bank_code varchar(37),
	@sender_bank_name varchar(105),
	@sender_acc varchar(37),
	@sender_acc_name varchar(105),
	@sender_acc_name_lat varchar(105),
	@sender_tax_code varchar(11),

	@period_type int,
	@add_tariff bit,
	@tariff_id int,
	@fx_credit_acc_id int,
	@rate money,
	@rate_items int,
	@is_reverse bit,
	@tmp_amount money,
	@check_saldo bit,
	@error_code int,
	@error_msg varchar(250),
	@error_msg_lat varchar(250),
	
	@our_bank_bic char(11),
	@our_bank_code9 TGEOBANKCODE,
	@our_bank_name_fx varchar(105),
	@our_bank_name varchar(105),
	@doc_type int,
	@parent_rec_id int,
	@relation_id int,
	@d_id int,
	@r int,
	@is_partially_done bit

IF (@task_id IS NOT NULL AND ISNULL(@perform_debt_action, 0) = 4)
BEGIN
	RAISERROR ('<ERR>ØÌÄÃÄÁÉÓ ÊÏÃÉ ÀÒ ÛÄÉÞËÄÁÀ ÉÚÏÓ "ÃÀÄËÏÃÏÓ ÛÄÌÃÄÂ ÉÍÓÔÒÖØÝÉÀÓ"!</ERR>', 16, 1)
	RETURN -255
END
			
SET @use_overdraft = 1

DECLARE @TRANSACTION_LIST TABLE 
   (ID INT identity(1, 1),
	DEBIT_ACC_ID int NULL, 
	CREDIT_ACC_ID int NULL, 
	AMOUNT money NULL, 
	AMOUNT_EQU money NULL, 
	DEBIT_CCY TISO NULL, 
	CREDIT_CCY TISO NULL, 
	BLOCKED_AMOUNT money NULL,
	REF_NO int NOT NULL,
	CHECK_SALDO bit NULL,
	DOC_TYPE int NULL,
	ADD_TARIFF bit,
	DESCRIP varchar(150) NULL,
	DESCRIP_LAT varchar(150) NULL,
	SAXAZKOD varchar(9) NULL,
	TAX_PAYER_NAME varchar(100) NULL,
	TAX_PAYER_TAX_CODE varchar(11) NULL,
	RECEIVER_BANK_CODE varchar(37) NULL,
	RECEIVER_BANK_NAME varchar(105) NULL,
	RECEIVER_ACC TINTACCOUNT NULL,
	RECEIVER_ACC_NAME varchar(105) NULL,
	RECEIVER_TAX_CODE varchar(11) NULL,
	RECEIVER_ADDRESS_LAT varchar(105) NULL,
	INTERMED_BANK_CODE dbo.TINTBANKCODE NULL,
	INTERMED_BANK_NAME varchar(105) NULL,
	EXTRA_INFO_DESCRIP bit NULL,
	EXTRA_INFO varchar(255) NULL,
	DET_OF_CHARG char(3) NULL,
	COR_BANK_CODE varchar(37) NULL,
	COR_BANK_NAME varchar(105) NULL,
	SENDER_ADDRESS_LAT varchar(105) NULL,
	SENDER_ACC TINTACCOUNT NULL,
	SENDER_ACC_NAME varchar(105) NULL,
	SENDER_ACC_NAME_LAT varchar(105) NULL,
	SENDER_TAX_CODE varchar(11) NULL,
	DOC_REC_ID int NULL)

DECLARE cr CURSOR LOCAL FAST_FORWARD FOR
SELECT t.ID, t.SWEEP_IO_AMOUNT, t.SWEEP_IO_MIN_BALANCE, t.DEPT_NO, t.AGREEMENT_NO, t.CLIENT_NO, t.RETRY_COUNT_PER_PAY, t.MAX_FAILURE_COUNT, t.DEBT_ACTION, t.PRIORITY, t.ORDER_DESCRIP, t.ORDER_DESCRIP_LAT, t.FX_RATE_TYPE, t.[STATE], t.PERIOD_TYPE, t.END_DATE,
	ISNULL(s.[DATE], @date), ISNULL(s.FAIL_COUNTER, 0), ISNULL(s.[STATE], 20),
	p.CHARGE_TYPE, p.FEE_RECV_PERCENT, p.FEE_MIN, p.PRIORITY, p.[STATE], p.PRODUCT_OWNER, p.USE_TARIFF, p.OP_CODE, p.DOC_STATE, p.DOC_TYPE
FROM dbo.SO_TASKS (ROWLOCK) t
LEFT JOIN dbo.SO_SCHEDULES (ROWLOCK) s ON s.TASK_ID = t.ID OR (t.PERIOD_TYPE = 1 AND s.TASK_ID IS NULL)
JOIN dbo.SO_PRODUCTS (ROWLOCK) p ON p.ID = t.PRODUCT_ID
WHERE (@task_id IS NULL OR t.ID = @task_id) AND t.[STATE] = 30 AND (ISNULL(s.[STATE], 20) = 20 OR (@task_id IS NOT NULL AND s.[STATE] = 30)) AND t.SUSPENDED_BY_BANK IS NULL AND s.SUSPENDED_BY_BANK IS NULL AND ISNULL(s.[DATE], @date) <= @date AND ((@fixed_date IS NOT NULL AND s.[DATE] = @fixed_date) OR (@fixed_date IS NULL AND dbo.so_is_valid_proc_date(@date, s.[DATE], t.PERIOD_TYPE, t.HOLIDAY_SHIFTING, s.FAIL_COUNTER) = 1)) AND (@task_id IS NOT NULL OR p.EXECUTION_TIME = @processing_mode)
ORDER BY p.PRIORITY, t.CLIENT_NO, t.PRIORITY, t.REG_DATE, s.[DATE]

OPEN cr
FETCH NEXT FROM cr INTO
	@processing_task_id, @trigger_amount, @min_balance_amount, @dept_no, @agreement_no, @client_no, @retry_count_per_pay, @max_failure_count, @debt_action, @priority, @order_descrip, @order_descrip_lat, @fx_rate_type, @task_state, @period_type, @end_date,
	@schedule_date, @fails_by_date, @schedule_state,
	@product_type, @fee_recv_percent, @fee_min, @priority, @product_state, @product_owner, @use_tariff, @op_code, @doc_state, @prod_doc_type
	
WHILE @@FETCH_STATUS = 0
BEGIN
	DELETE FROM @TRANSACTION_LIST

	SELECT @our_bank_bic = BIC, @our_bank_code9 = CODE9
	FROM dbo.DEPTS (NOLOCK) d
	WHERE DATABASE_ID = dbo.sys_database_id() AND DEPT_NO = @dept_no

	SELECT @our_bank_name_fx = DESCRIP
	FROM dbo.BIC_CODES (NOLOCK)
	WHERE BIC = @our_bank_bic

	SELECT @our_bank_name = DESCRIP
	FROM dbo.BANKS (NOLOCK)
	WHERE CODE9 = @our_bank_code9

	IF @task_id IS NOT NULL
		SET @debt_action = ISNULL(@perform_debt_action, @debt_action)
	
	SET @parent_rec_id = 0
	SEt @relation_id = NULL
	SET @d_id = NULL
	SET @error_code = NULL
	SET @is_partial = NULL
	SET @error_code = NULL
	SET @error_msg = NULL
	SET @error_msg_lat = NULL
	SET @sender_tax_code = NULL
	SET @is_partially_done = NULL
	SET @check_saldo = CASE WHEN @debt_action = 3 THEN 0 ELSE 1 END

	IF (@period_type = 1) AND NOT EXISTS (SELECT * FROM dbo.SO_SCHEDULES (NOLOCK) WHERE TASK_ID = @processing_task_id AND [DATE] = @schedule_date)
		INSERT INTO dbo.SO_SCHEDULES (TASK_ID, [DATE], FAIL_COUNTER, [STATE], DOC_REC_ID)
			VALUES (@processing_task_id, @schedule_date, NULL, 20, NULL)

	IF (@product_type = 1) -- გადარიცხვა
	BEGIN
		SELECT
			@debit_acc_id = t.ACC_ID, 
			@debit_ccy = a.ISO,
			@lim_amount = t.AMOUNT, 
			@is_percent = ISNULL(t.IS_PERCENT, 0),
			@equ_iso = t.EQU_ISO, 
			@is_master_acc = t.IS_MASTER_ACC,
			@debit_acc = a.ACCOUNT,
			@debit_acc_type = a.ACC_TYPE,
			@debit_acc_sub_type = a.ACC_SUBTYPE,
			@tariff_id = CASE WHEN ISNULL(@use_tariff, 0) = 0 THEN NULL ELSE a.TARIFF END,
			@sender_acc = a.ACCOUNT,
			@sender_acc_name = a.DESCRIP,
			@sender_acc_name_lat = a.DESCRIP_LAT
		FROM dbo.SO_TASK_DEBIT_ACCOUNTS (NOLOCK) t
			JOIN dbo.ACCOUNTS (NOLOCK) a ON a.ACC_ID = t.ACC_ID
		WHERE TASK_ID = @processing_task_id AND t.IS_HELPER_ACC = 0
		
		SELECT TOP 1
			@credit_ccy = c.ISO,
			@credit_acc_id = c.ACC_ID,
			@credit_acc_type = a.ACC_TYPE,
			@credit_acc_sub_type = a.ACC_SUBTYPE,
			@descrip = c.DESCRIP,
			@descrip_lat = c.DESCRIP,
			@saxaz_code = c.SAXAZKOD,
			@tax_payer_name = c.TAX_PAYER_NAME,
			@tax_payer_code = c.TAX_PAYER_TAX_CODE,
			@cor_bank_code = c.COR_BANK_CODE,
			@cor_bank_name = c.COR_BANK_NAME,
			@intermed_bank_code = c.INTERMED_BANK_CODE,
			@intermed_bank_name = c.INTERMED_BANK_NAME,
			@extra_info = c.EXTRA_INFO,
			@extra_info_descrip = c.EXTRA_INFO_DESCRIP,
			@det_of_charg = c.DET_OF_CHARG,
			@receiver_acc = c.RECEIVER_ACC,
			@receiver_acc_name = c.RECEIVER_ACC_NAME,
			@sender_address_lat = c.SENDER_ADDRESS_LAT,
			@receiver_address_lat = c.RECEIVER_ADDRESS_LAT,
			@receiver_bank_code = c.RECEIVER_BANK_CODE,
			@receiver_bank_name = c.RECEIVER_BANK_NAME,
			@receiver_tax_code = c.RECEIVER_TAX_CODE
		FROM dbo.SO_TASK_CREDIT_ACCOUNTS (NOLOCK) c
			JOIN dbo.ACCOUNTS (NOLOCK) a ON a.ACC_ID  = c.ACC_ID
		WHERE c.TASK_ID = @processing_task_id
		
		IF (@prod_doc_type = 1 OR (@credit_ccy  <> 'GEL' AND @receiver_bank_code <> @our_bank_bic) OR (@credit_ccy  = 'GEL' AND @receiver_bank_code <> @our_bank_code9))
		BEGIN
			SET @doc_type = CASE WHEN @credit_ccy <> 'GEL' THEN 110 ELSE 100 END
			IF (@credit_ccy  <> 'GEL' AND @receiver_bank_code <> @our_bank_bic) OR (@credit_ccy  = 'GEL' AND @receiver_bank_code <> @our_bank_code9)
				SET @doc_type = @doc_type + 2
		END
		ELSE
			IF (@prod_doc_type = 2)
				SET @doc_type = 98
			ELSE
				IF (@prod_doc_type = 3)
					SET @doc_type = 200
					
		IF (@client_no IS NOT NULL AND (@doc_type BETWEEN 100 AND 119))
			SELECT @sender_tax_code = ISNULL(TAX_INSP_CODE, PERSONAL_ID) FROM dbo.CLIENTS (NOLOCK) WHERE CLIENT_NO = @client_no

		EXEC @r = dbo.so_prepare_transaction
				@task_id = @processing_task_id,
				@date = @date,
				@schedule_date = @schedule_date,
				@client_no = @client_no,
				@agreement_no = @agreement_no,
				@descrip = @descrip OUTPUT,
				@descrip_lat = @descrip_lat OUTPUT,
				
				@tariff_id = @tariff_id,
				@user_id = @user_id,
				@dept_no = @dept_no,
				@doc_type = @doc_type,
				@doc_date = @date,
				@receiver_bank_code = @receiver_bank_code,
				@det_of_charg = @det_of_charg,
				
				@debit_acc_id = @debit_acc_id,
				@debit_acc_type = @debit_acc_type,
				@debit_ccy = @debit_ccy,
				@debit_acc_sub_type = @debit_acc_sub_type,
				@debit_acc = @debit_acc,
				
				@credit_acc_id = @credit_acc_id,
				@credit_acc_type = @credit_acc_type,
				@credit_ccy  = @credit_ccy,
				@credit_acc_sub_type = @credit_acc_sub_type,
				@credit_acc = @receiver_acc,
				
				@use_overdraft = @use_overdraft,
				@lim_amount = @lim_amount,
				@is_percent = @is_percent,
				@equ_iso = @equ_iso,
				@debt_action = @debt_action,
				@fx_rate_type = @fx_rate_type,
				@check_saldo = @check_saldo,
				
				@transaction_amount = @transaction_amount OUTPUT,
				@transaction_amount_equ = @transaction_amount_equ OUTPUT,
				@blocked_amount = @blocked_amount OUTPUT,
				@is_partial = @is_partial OUTPUT,
				@error_code = @error_code OUTPUT,
				@error_msg = @error_msg OUTPUT,
				@error_msg_lat = @error_msg_lat OUTPUT,
				@ref_no = @ref_no OUTPUT

		IF ISNULL(@error_code, 0) = 0
		BEGIN
			IF ISNULL(@is_partially_done, 0) = 0 AND @is_partial = 1
				SET @is_partially_done = 1
				
			IF (@debit_ccy <> @credit_ccy)
			BEGIN
				SET @fx_credit_acc_id = (SELECT t.ACC_ID FROM SO_TASK_DEBIT_ACCOUNTS (NOLOCK) t JOIN dbo.ACCOUNTS (NOLOCK) a ON a.ACC_ID = t.ACC_ID WHERE t.TASK_ID = @processing_task_id AND a.ISO = @credit_ccy AND t.IS_MASTER_ACC = 1)
				IF (@fx_credit_acc_id IS NULL)
				BEGIN
					SET @error_code = -2
					SET @error_msg = '<ERR>ÃÀÅÀËÄÁÉÓ ÛÄÓÒÖËÄÁÉÓÀÈÅÉÓ ÓÀàÉÒÏ ÃÀÌáÌÀÒÄ ÊÏÍÅÄÒÔÀÝÉÉÓ ÀÍÂÀÒÉÛÉ (' + @credit_ccy + ') ÀÒ ÀÒÉÓ ÌÉÈÉÈÄÁÖËÉ!</ERR>'
					SET @error_msg_lat = '<ERR>Unable was to determine account for (' + @credit_ccy + ') FX conversion!</ERR>'

					INSERT INTO dbo.SO_SCHEDULE_CHANGES ([TASK_ID], [DATE], [USER_ID], [FIELD], OLD_VALUE, NEW_VALUE, OLD_DISPLAY_VALUE, NEW_DISPLAY_VALUE)
						VALUES (@processing_task_id, @schedule_date, @user_id, 'STATE', @error_code, NULL, @error_msg, @error_msg_lat)
				END
				ELSE
				BEGIN
					INSERT INTO @TRANSACTION_LIST VALUES (@debit_acc_id, @fx_credit_acc_id, @transaction_amount, @transaction_amount_equ, @debit_ccy, @credit_ccy, NULL, @ref_no, @check_saldo, NULL, 0, @descrip, @descrip_lat, NULL, NULL, NULL, @receiver_bank_code, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL)
					INSERT INTO @TRANSACTION_LIST VALUES (@fx_credit_acc_id, @credit_acc_id, @transaction_amount_equ, @transaction_amount_equ, @credit_ccy, @credit_ccy, @blocked_amount, @ref_no, @check_saldo, @doc_type, 1, @descrip, @descrip_lat, @saxaz_code, @tax_payer_name, @tax_payer_code, @receiver_bank_code, @receiver_bank_name, @receiver_acc, @receiver_acc_name, @receiver_tax_code, @receiver_address_lat, @intermed_bank_code, @intermed_bank_name, @extra_info_descrip, @extra_info, @det_of_charg, @cor_bank_code, @cor_bank_name, @sender_address_lat, @sender_acc, @sender_acc_name, @sender_acc_name_lat, @sender_tax_code, NULL)
				END
			END
			ELSE
				INSERT INTO @TRANSACTION_LIST VALUES (@debit_acc_id, @credit_acc_id, @transaction_amount, @transaction_amount, @debit_ccy, @credit_ccy, @blocked_amount, @ref_no, @check_saldo, @doc_type, 1, @descrip, @descrip_lat, @saxaz_code, @tax_payer_name, @tax_payer_code, @receiver_bank_code, @receiver_bank_name, @receiver_acc, @receiver_acc_name, @receiver_tax_code, @receiver_address_lat, @intermed_bank_code, @intermed_bank_name, @extra_info_descrip, @extra_info, @det_of_charg, @cor_bank_code, @cor_bank_name, @sender_address_lat, @sender_acc, @sender_acc_name, @sender_acc_name_lat, @sender_tax_code, NULL)
		END
		ELSE
		BEGIN
			INSERT INTO dbo.SO_SCHEDULE_CHANGES ([TASK_ID], [DATE], [USER_ID], [FIELD], OLD_VALUE, NEW_VALUE, OLD_DISPLAY_VALUE, NEW_DISPLAY_VALUE)
				VALUES (@processing_task_id, @schedule_date, @user_id, 'STATE', @error_code, NULL, @error_msg, @error_msg_lat)
		END
	END
	ELSE
	IF @product_type = 2 -- შეგროვება
	BEGIN	
		SELECT
			@transaction_amount = c.AMOUNT,
			@credit_ccy = c.ISO,
			@credit_acc_id = c.ACC_ID,
			@credit_acc_type = a.ACC_TYPE,
			@credit_acc_sub_type = a.ACC_SUBTYPE,
			@descrip = c.DESCRIP,
			@descrip_lat = c.DESCRIP,
			@saxaz_code = c.SAXAZKOD,
			@tax_payer_name = c.TAX_PAYER_NAME,
			@tax_payer_code = c.TAX_PAYER_TAX_CODE,
			@cor_bank_code = c.COR_BANK_CODE,
			@cor_bank_name = c.COR_BANK_NAME,
			@intermed_bank_code = c.INTERMED_BANK_CODE,
			@intermed_bank_name = c.INTERMED_BANK_NAME,
			@extra_info = c.EXTRA_INFO,
			@extra_info_descrip = c.EXTRA_INFO_DESCRIP,
			@det_of_charg = c.DET_OF_CHARG,
			@receiver_acc = c.RECEIVER_ACC,
			@receiver_acc_name = c.RECEIVER_ACC_NAME,
			@sender_address_lat = c.SENDER_ADDRESS_LAT,
			@receiver_address_lat = c.RECEIVER_ADDRESS_LAT,
			@receiver_bank_code = c.RECEIVER_BANK_CODE,
			@receiver_bank_name = c.RECEIVER_BANK_NAME,
			@receiver_tax_code = c.RECEIVER_TAX_CODE
		FROM dbo.SO_TASK_CREDIT_ACCOUNTS (NOLOCK) c
			JOIN dbo.ACCOUNTS (NOLOCK) a ON a.ACC_ID  = c.ACC_ID
		WHERE TASK_ID = @processing_task_id
			
		EXEC dbo.acc_get_usable_amount 
			@acc_id = @credit_acc_id,
			@usable_amount = @current_credit_amount OUTPUT,
			@use_overdraft = @use_overdraft

		EXEC dbo.so_get_ref_no @ref_no = @ref_no OUTPUT

		EXEC @r = dbo.so_get_acc_balance
			@date = @date,
			@client_no = @client_no,
			@acc_id = @credit_acc_id,
			@acc_type = @credit_acc_type,
			@acc_sub_type = @credit_acc_sub_type,
			@acc_no = @credit_acc,
			@is_debit = 0,
			@ccy = @credit_ccy,
			@ref_no = @ref_no,
			@block_amount = NULL,
			@cancel_operation = 0,
			@amount = @current_credit_amount OUTPUT,
			@check_saldo = @check_saldo OUTPUT,
			@error_code = @error_code OUTPUT,
			@error_msg = @error_msg OUTPUT,
			@error_msg_lat = @error_msg_lat OUTPUT

		IF (ISNULL(@error_code, 0) <> 0)
		BEGIN
			INSERT INTO dbo.SO_SCHEDULE_CHANGES ([TASK_ID], [DATE], [USER_ID], [FIELD], OLD_VALUE, NEW_VALUE, OLD_DISPLAY_VALUE, NEW_DISPLAY_VALUE)
				VALUES (@processing_task_id, @schedule_date, @user_id, 'STATE', @error_code, NULL, @error_msg, @error_msg_lat)
		END
		ELSE
		IF (@trigger_amount IS NULL OR @current_credit_amount <= @trigger_amount)
		BEGIN								
			SET @collect_amount = ISNULL(@min_balance_amount - @current_credit_amount, @transaction_amount) -- თუ  @min_balance_amount არ არის მითითებული შეავსე @transaction_amount-ით, თუ @transaction_amount-იც არ არის მითითებული მაშინ, უბრალოდ გადარიცხე თანხები არსებული ნაშთებით

			IF @collect_amount IS NULL OR @collect_amount > $0.00
			BEGIN
				DECLARE debit_cr CURSOR LOCAL FAST_FORWARD FOR
				
				SELECT t.ACC_ID, a.ISO, t.AMOUNT, ISNULL(t.IS_PERCENT, 0), t.EQU_ISO, t.IS_MASTER_ACC, t.IS_HELPER_ACC, t.PRIORITY, a.ACCOUNT, a.ACC_TYPE, a.ACC_SUBTYPE, a.DESCRIP, a.DESCRIP_LAT, NULL/*CASE WHEN ISNULL(@use_tariff, 0) = 0 THEN NULL ELSE a.TARIFF END*/
				FROM dbo.SO_TASK_DEBIT_ACCOUNTS (NOLOCK) t
					JOIN dbo.ACCOUNTS (NOLOCK) a ON a.ACC_ID = t.ACC_ID
				WHERE TASK_ID = @processing_task_id AND IS_HELPER_ACC = 0
				ORDER BY t.PRIORITY
				
				OPEN debit_cr
				FETCH NEXT FROM debit_cr
				INTO @debit_acc_id, @debit_ccy, @lim_amount, @is_percent, @equ_iso, @is_master_acc, @is_helper_acc, @priority, @debit_acc, @debit_acc_type, @debit_acc_sub_type, @sender_acc_name, @sender_acc_name_lat, @tariff_id
				
				WHILE (@collect_amount IS NULL OR @collect_amount >= $0.00) AND @@FETCH_STATUS = 0
				BEGIN				
					IF (@prod_doc_type = 1 OR (@credit_ccy  <> 'GEL' AND @receiver_bank_code <> @our_bank_bic) OR (@credit_ccy  = 'GEL' AND @receiver_bank_code <> @our_bank_code9))
					BEGIN
						SET @doc_type = CASE WHEN @credit_ccy <> 'GEL' THEN 110 ELSE 100 END
						IF (@credit_ccy  <> 'GEL' AND @receiver_bank_code <> @our_bank_bic) OR (@credit_ccy  = 'GEL' AND @receiver_bank_code <> @our_bank_code9)
							SET @doc_type = @doc_type + 2
					END
					ELSE
						IF (@prod_doc_type = 2)
							SET @doc_type = 98
						ELSE
							IF (@prod_doc_type = 3)
								SET @doc_type = 200
				
					IF (@client_no IS NOT NULL AND (@doc_type BETWEEN 100 AND 119))
						SELECT @sender_tax_code = ISNULL(TAX_INSP_CODE, PERSONAL_ID) FROM dbo.CLIENTS (NOLOCK) WHERE CLIENT_NO = @client_no

					EXEC @r = dbo.so_prepare_transaction
							@task_id = @processing_task_id,
							@date = @date,
							@schedule_date = @schedule_date,
							@client_no = @client_no,
							@agreement_no = @agreement_no,
							@descrip = @descrip OUTPUT,
							@descrip_lat = @descrip_lat OUTPUT,
							
							@tariff_id = @tariff_id,
							@user_id = @user_id,
							@dept_no = @dept_no,
							@doc_type = @doc_type,
							@doc_date = @date,
							@receiver_bank_code = @receiver_bank_code,
							@det_of_charg = @det_of_charg,
							
							@debit_acc_id = @debit_acc_id,
							@debit_acc_type = @debit_acc_type,
							@debit_ccy = @debit_ccy,
							@debit_acc_sub_type = @debit_acc_sub_type,
							@debit_acc = @debit_acc,
							
							@credit_acc_id = @credit_acc_id,
							@credit_acc_type = @credit_acc_type,
							@credit_ccy  = @credit_ccy,
							@credit_acc_sub_type = @credit_acc_sub_type,
							@credit_acc = @receiver_acc,
							
							@use_overdraft = @use_overdraft,
							@lim_amount = @lim_amount,
							@is_percent = @is_percent,
							@equ_iso = @equ_iso,
							@debt_action = @debt_action,
							@fx_rate_type = @fx_rate_type,
							@check_saldo = @check_saldo,
							
							@transaction_amount = @transaction_amount OUTPUT,
							@transaction_amount_equ = @transaction_amount_equ OUTPUT,
							@blocked_amount = @blocked_amount OUTPUT,
							@is_partial = @is_partial OUTPUT,
							@error_code = @error_code OUTPUT,
							@error_msg = @error_msg OUTPUT,
							@error_msg_lat = @error_msg_lat OUTPUT,
							@ref_no = @ref_no OUTPUT

					IF (ISNULL(@error_code, 0) = 0)
					BEGIN
						IF ISNULL(@is_partially_done, 0) = 0 AND @is_partial = 1
							SET @is_partially_done = 1

						IF (@collect_amount IS NULL OR @transaction_amount_equ <= @collect_amount)
							SET @collect_amount = @collect_amount - @transaction_amount_equ
						ELSE
						BEGIN
							SET @transaction_amount_equ = @collect_amount

							IF (@fx_rate_type = 1)
								SET @transaction_amount = dbo.get_cross_amount(@transaction_amount_equ, @credit_ccy, @debit_ccy, @date)
							ELSE
							BEGIN
								EXEC dbo.GET_CROSS_RATE 
									@rate_politics_id = NULL, 
									@iso1 = @debit_ccy, 
									@iso2 = @credit_ccy, 
									@look_buy = 1/*?*/, 
									@amount = @rate OUTPUT, 
									@items = @rate_items OUTPUT, 
									@reverse = @is_reverse OUTPUT, 
									@rate_type = 0
					  
								IF @is_reverse = 0
								BEGIN
									SET @tmp_amount = @transaction_amount_equ * @rate
									SET @transaction_amount = @tmp_amount / @rate_items
								END
								ELSE
								BEGIN
									SET @tmp_amount = @transaction_amount_equ * @rate_items
									SET @transaction_amount = @tmp_amount / @rate
								END
							END

							SET @collect_amount = $0.00
						END

						IF (@debit_ccy <> @credit_ccy)
						BEGIN
							SET @fx_credit_acc_id = (SELECT t.ACC_ID FROM SO_TASK_DEBIT_ACCOUNTS (NOLOCK) t JOIN dbo.ACCOUNTS (NOLOCK) a ON a.ACC_ID = t.ACC_ID WHERE t.TASK_ID = @processing_task_id AND a.ISO = @credit_ccy AND t.IS_MASTER_ACC = 1)
							IF (@fx_credit_acc_id IS NULL)
							BEGIN
								SET @error_code = -2
								SET @error_msg = '<ERR>ÃÀÅÀËÄÁÉÓ ÛÄÓÒÖËÄÁÉÓÀÈÅÉÓ ÓÀàÉÒÏ ÃÀÌáÌÀÒÄ ÊÏÍÅÄÒÔÀÝÉÉÓ ÀÍÂÀÒÉÛÉ (' + @credit_ccy + ') ÀÒ ÀÒÉÓ ÌÉÈÉÈÄÁÖËÉ!</ERR>'
								SET @error_msg_lat = '<ERR>Unable was to determine account for (' + @credit_ccy + ') FX conversion!</ERR>'

								INSERT INTO dbo.SO_SCHEDULE_CHANGES ([TASK_ID], [DATE], [USER_ID], [FIELD], OLD_VALUE, NEW_VALUE, OLD_DISPLAY_VALUE, NEW_DISPLAY_VALUE)
									VALUES (@processing_task_id, @schedule_date, @user_id, 'STATE', @error_code, NULL, @error_msg, @error_msg_lat)

								IF (@debt_action IN (0, 2))
									BREAK
							END
							ELSE
							BEGIN							
								INSERT INTO @TRANSACTION_LIST VALUES (@debit_acc_id, @fx_credit_acc_id, @transaction_amount, @transaction_amount_equ, @debit_ccy, @credit_ccy, NULL, @ref_no, @check_saldo, NULL, 0, @descrip, @descrip_lat, NULL, NULL, NULL, @receiver_bank_code, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL)
								INSERT INTO @TRANSACTION_LIST VALUES (@fx_credit_acc_id, @credit_acc_id, @transaction_amount_equ, @transaction_amount_equ, @credit_ccy, @credit_ccy, @blocked_amount, @ref_no, @check_saldo, @doc_type, 1, @descrip, @descrip_lat, @saxaz_code, @tax_payer_name, @tax_payer_code, @receiver_bank_code, @receiver_bank_name, @receiver_acc, @receiver_acc_name, @receiver_tax_code, @receiver_address_lat, @intermed_bank_code, @intermed_bank_name, @extra_info_descrip, @extra_info, @det_of_charg, @cor_bank_code, @cor_bank_name, @sender_address_lat, @debit_acc, @sender_acc_name, @sender_acc_name_lat, @sender_tax_code, NULL)
							END
						END
						ELSE
							INSERT INTO @TRANSACTION_LIST VALUES (@debit_acc_id, @credit_acc_id, @transaction_amount, @transaction_amount, @debit_ccy, @credit_ccy, @blocked_amount, @ref_no, @check_saldo, @doc_type, 1, @descrip, @descrip_lat, @saxaz_code, @tax_payer_name, @tax_payer_code, @receiver_bank_code, @receiver_bank_name, @receiver_acc, @receiver_acc_name, @receiver_tax_code, @receiver_address_lat, @intermed_bank_code, @intermed_bank_name, @extra_info_descrip, @extra_info, @det_of_charg, @cor_bank_code, @cor_bank_name, @sender_address_lat, @debit_acc, @debit_acc, @sender_acc_name_lat, @sender_tax_code, NULL)
					END
					ELSE
					BEGIN
						INSERT INTO dbo.SO_SCHEDULE_CHANGES ([TASK_ID], [DATE], [USER_ID], [FIELD], OLD_VALUE, NEW_VALUE, OLD_DISPLAY_VALUE, NEW_DISPLAY_VALUE)
							VALUES (@processing_task_id, @schedule_date, @user_id, 'STATE', @error_code, NULL, @error_msg, @error_msg_lat)
							
						IF (@debt_action IN (0, 2))
							BREAK
					END
					
					FETCH NEXT FROM debit_cr
					INTO @debit_acc_id, @debit_ccy, @lim_amount, @is_percent, @equ_iso, @is_master_acc, @is_helper_acc, @priority, @debit_acc, @debit_acc_type, @debit_acc_sub_type, @sender_acc_name, @sender_acc_name_lat, @tariff_id
				END
				CLOSE debit_cr
				DEALLOCATE debit_cr
			END
		END
	END
	ELSE
	IF @product_type = 3 -- განაწილება
	BEGIN
		SELECT 
			@debit_acc_id = t.ACC_ID, 
			@debit_ccy = a.ISO,
			@is_master_acc = t.IS_MASTER_ACC,
			@tariff_id = CASE WHEN ISNULL(@use_tariff, 0) = 0 THEN NULL ELSE a.TARIFF END,
			@sender_acc = a.ACCOUNT,
			@sender_acc_name = a.DESCRIP,
			@sender_acc_name_lat = a.DESCRIP_LAT,
			@debit_acc = a.ACCOUNT,
			@debit_acc_type = a.ACC_TYPE,
			@debit_acc_sub_type = a.ACC_SUBTYPE
		FROM dbo.SO_TASK_DEBIT_ACCOUNTS (NOLOCK) t
			JOIN dbo.ACCOUNTS (NOLOCK) a ON a.ACC_ID = t.ACC_ID
		WHERE TASK_ID = @processing_task_id AND t.IS_HELPER_ACC = 0

		EXEC dbo.acc_get_usable_amount 
			@acc_id = @debit_acc_id, 
			@usable_amount = @current_debit_amount OUTPUT, 
			@use_overdraft = @use_overdraft

		EXEC dbo.so_get_ref_no @ref_no = @ref_no OUTPUT

		EXEC dbo.so_get_acc_balance
			@date = @date,
			@client_no = @client_no,
			@acc_id = @debit_acc_id,
			@acc_type = @debit_acc_type,
			@acc_sub_type = @debit_acc_sub_type,
			@acc_no = @debit_acc,
			@is_debit = 0,
			@ccy = @debit_ccy,
			@ref_no = @ref_no,
			@block_amount = NULL,
			@cancel_operation = 0,
			@amount = @current_debit_amount OUTPUT,
			@check_saldo = @check_saldo OUTPUT,
			@error_code = @error_code OUTPUT,
			@error_msg = @error_msg OUTPUT,
			@error_msg_lat = @error_msg_lat OUTPUT

		SET @distribute_amount = @current_debit_amount - ISNULL(@min_balance_amount, $0.00)
		SET @already_used_amount = 0

		IF (ISNULL(@error_code, 0) <> 0)
		BEGIN
			INSERT INTO dbo.SO_SCHEDULE_CHANGES ([TASK_ID], [DATE], [USER_ID], [FIELD], OLD_VALUE, NEW_VALUE, OLD_DISPLAY_VALUE, NEW_DISPLAY_VALUE)
				VALUES (@processing_task_id, @schedule_date, @user_id, 'STATE', @error_code, NULL, @error_msg, @error_msg_lat)
		END
		ELSE
		IF (@current_debit_amount >= @trigger_amount AND @distribute_amount > $0.00)
		BEGIN
			DECLARE credit_cr CURSOR LOCAL FAST_FORWARD FOR

			SELECT 
				c.ACC_ID, 
				c.ISO, 
				c.AMOUNT, 
				ISNULL(c.IS_PERCENT, 0), 
				c.EQU_ISO, 
				c.DESCRIP, 
				c.SAXAZKOD, 
				c.TAX_PAYER_NAME, 
				c.TAX_PAYER_TAX_CODE, 
				c.COR_BANK_CODE,
				c.COR_BANK_NAME,
				c.INTERMED_BANK_CODE,
				c.INTERMED_BANK_NAME,
				c.EXTRA_INFO,
				c.EXTRA_INFO_DESCRIP,
				c.DET_OF_CHARG,
				c.RECEIVER_ACC,
				c.RECEIVER_ACC_NAME,
				c.SENDER_ADDRESS_LAT,
				c.RECEIVER_ADDRESS_LAT,
				c.RECEIVER_BANK_CODE,
				c.RECEIVER_BANK_NAME,
				c.RECEIVER_TAX_CODE,
				c.PRIORITY,
				a.[ACC_TYPE],
				a.[ACC_SUBTYPE]
			FROM dbo.SO_TASK_CREDIT_ACCOUNTS (NOLOCK) c
				JOIN dbo.ACCOUNTS (NOLOCK) a ON a.ACC_ID  = c.ACC_ID
			WHERE TASK_ID = @processing_task_id
			ORDER BY c.PRIORITY

			OPEN credit_cr
			FETCH NEXT FROM credit_cr
			INTO @credit_acc_id, @credit_ccy, @lim_amount, @is_percent, @equ_iso, @descrip, @saxaz_code, @tax_payer_name, @tax_payer_code, @cor_bank_code, @cor_bank_name, @intermed_bank_code, @intermed_bank_name, @extra_info, @extra_info_descrip, @det_of_charg, @receiver_acc, @receiver_acc_name, @sender_address_lat, @receiver_address_lat, @receiver_bank_code, @receiver_bank_name, @receiver_tax_code, @priority, @credit_acc_type, @credit_acc_sub_type

			WHILE @@FETCH_STATUS = 0 AND @distribute_amount > 0
			BEGIN
				IF (@prod_doc_type = 1 OR (@credit_ccy  <> 'GEL' AND @receiver_bank_code <> @our_bank_bic) OR (@credit_ccy  = 'GEL' AND @receiver_bank_code <> @our_bank_code9))
				BEGIN
					SET @doc_type = CASE WHEN @credit_ccy <> 'GEL' THEN 110 ELSE 100 END
					IF (@credit_ccy  <> 'GEL' AND @receiver_bank_code <> @our_bank_bic) OR (@credit_ccy  = 'GEL' AND @receiver_bank_code <> @our_bank_code9)
						SET @doc_type = @doc_type + 2
				END
				ELSE
					IF (@prod_doc_type = 2)
						SET @doc_type = 98
					ELSE
						IF (@prod_doc_type = 3)
							SET @doc_type = 200

				IF (@client_no IS NOT NULL AND (@doc_type BETWEEN 100 AND 119))
					SELECT @sender_tax_code = ISNULL(TAX_INSP_CODE, PERSONAL_ID) FROM dbo.CLIENTS (NOLOCK) WHERE CLIENT_NO = @client_no

				EXEC @r = dbo.so_prepare_transaction
						@task_id = @processing_task_id,
						@date = @date,
						@schedule_date = @schedule_date,
						@client_no = @client_no,
						@agreement_no = @agreement_no,
						@descrip = @descrip OUTPUT,
						@descrip_lat = @descrip_lat OUTPUT,
						
						@tariff_id = @tariff_id,
						@user_id = @user_id,
						@dept_no = @dept_no,
						@doc_type = @doc_type,
						@doc_date = @date,
						@receiver_bank_code = @receiver_bank_code,
						@det_of_charg = @det_of_charg,
						
						@debit_acc_id = @debit_acc_id,
						@debit_acc_type = @debit_acc_type,
						@debit_ccy = @debit_ccy,
						@debit_acc_sub_type = @debit_acc_sub_type,
						@debit_acc = @debit_acc,
						
						@credit_acc_id = @credit_acc_id,
						@credit_acc_type = @credit_acc_type,
						@credit_ccy  = @credit_ccy,
						@credit_acc_sub_type = @credit_acc_sub_type,
						@credit_acc = @credit_acc,
						
						@use_overdraft = @use_overdraft,
						@lim_amount = @lim_amount,
						@is_percent = @is_percent,
						@equ_iso = @equ_iso,
						@debt_action = @debt_action,
						@fx_rate_type = @fx_rate_type,
						@check_saldo = @check_saldo,
						
						@already_used_amount = @already_used_amount,
						@tariff_amount = @tariff_amount OUTPUT,
						@transaction_amount = @transaction_amount OUTPUT,
						@transaction_amount_equ = @transaction_amount_equ OUTPUT,
						@blocked_amount = @blocked_amount OUTPUT,
						@is_partial = @is_partial OUTPUT,
						@error_code = @error_code OUTPUT,
						@error_msg = @error_msg OUTPUT,
						@error_msg_lat = @error_msg_lat OUTPUT,
						@ref_no = @ref_no OUTPUT

				IF ISNULL(@is_partially_done, 0) = 0 AND @is_partial = 1
					SET @is_partially_done = 1

				IF (ISNULL(@error_code, 0) = 0)
				BEGIN
					IF (@transaction_amount <= @distribute_amount)
					BEGIN							
						SET @distribute_amount = @distribute_amount - @transaction_amount
						SET @already_used_amount = @already_used_amount + @transaction_amount + @tariff_amount

						IF (@debit_ccy <> @credit_ccy)
						BEGIN
							SET @fx_credit_acc_id = (SELECT t.ACC_ID FROM SO_TASK_DEBIT_ACCOUNTS (NOLOCK) t JOIN dbo.ACCOUNTS (NOLOCK) a ON a.ACC_ID = t.ACC_ID WHERE t.TASK_ID = @processing_task_id AND a.ISO = @credit_ccy AND t.IS_MASTER_ACC = 1)
							IF (@fx_credit_acc_id IS NULL)
							BEGIN
								SET @error_code = -2
								SET @error_msg = '<ERR>ÃÀÅÀËÄÁÉÓ ÛÄÓÒÖËÄÁÉÓÀÈÅÉÓ ÓÀàÉÒÏ ÃÀÌáÌÀÒÄ ÊÏÍÅÄÒÔÀÝÉÉÓ ÀÍÂÀÒÉÛÉ (' + @credit_ccy + ') ÀÒ ÀÒÉÓ ÌÉÈÉÈÄÁÖËÉ!</ERR>'
								SET @error_msg_lat = '<ERR>Unable was to determine account for (' + @credit_ccy + ') FX conversion!</ERR>'

								INSERT INTO dbo.SO_SCHEDULE_CHANGES ([TASK_ID], [DATE], [USER_ID], [FIELD], OLD_VALUE, NEW_VALUE, OLD_DISPLAY_VALUE, NEW_DISPLAY_VALUE)
									VALUES (@processing_task_id, @schedule_date, @user_id, 'STATE', @error_code, NULL, @error_msg, @error_msg_lat)

								IF (@debt_action IN (0, 2))
									BREAK
							END
							ELSE
							BEGIN							
								INSERT INTO @TRANSACTION_LIST VALUES (@debit_acc_id, @fx_credit_acc_id, @transaction_amount, @transaction_amount_equ, @debit_ccy, @credit_ccy, NULL, @ref_no, @check_saldo, NULL, 0, @descrip, @descrip_lat, NULL, NULL, NULL, @receiver_bank_code, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL)
								INSERT INTO @TRANSACTION_LIST VALUES (@fx_credit_acc_id, @credit_acc_id, @transaction_amount_equ, @transaction_amount_equ, @credit_ccy, @credit_ccy, @blocked_amount, @ref_no, @check_saldo, @doc_type, 1, @descrip, @descrip_lat, @saxaz_code, @tax_payer_name, @tax_payer_code, @receiver_bank_code, @receiver_bank_name, @receiver_acc, @receiver_acc_name, @receiver_tax_code, @receiver_address_lat, @intermed_bank_code, @intermed_bank_name, @extra_info_descrip, @extra_info, @det_of_charg, @cor_bank_code, @cor_bank_name, @sender_address_lat, @sender_acc, @sender_acc_name, @sender_acc_name_lat, @sender_tax_code, NULL)
							END
						END
						ELSE
							INSERT INTO @TRANSACTION_LIST VALUES (@debit_acc_id, @credit_acc_id, @transaction_amount, @transaction_amount, @debit_ccy, @credit_ccy, @blocked_amount, @ref_no, @check_saldo, @doc_type, 1, @descrip, @descrip_lat, @saxaz_code, @tax_payer_name, @tax_payer_code, @receiver_bank_code, @receiver_bank_name, @receiver_acc, @receiver_acc_name, @receiver_tax_code, @receiver_address_lat, @intermed_bank_code, @intermed_bank_name, @extra_info_descrip, @extra_info, @det_of_charg, @cor_bank_code, @cor_bank_name, @sender_address_lat, @sender_acc, @sender_acc_name, @sender_acc_name_lat, @sender_tax_code, NULL)
					END
					ELSE					
						SET @distribute_amount = $0.00	---<------- NOTE
				END
				ELSE
				BEGIN
					INSERT INTO dbo.SO_SCHEDULE_CHANGES ([TASK_ID], [DATE], [USER_ID], [FIELD], OLD_VALUE, NEW_VALUE, OLD_DISPLAY_VALUE, NEW_DISPLAY_VALUE)
						VALUES (@processing_task_id, @schedule_date, @user_id, 'STATE', @error_code, NULL, @error_msg, @error_msg_lat)

					IF (@debt_action IN (0, 2))
						BREAK
					ELSE
					BEGIN
						SET @error_code = 0
						SET @error_msg = NULL
						SET @error_msg_lat = NULL
					END
				END
				
				FETCH NEXT FROM credit_cr
				INTO @credit_acc_id, @credit_ccy, @lim_amount, @is_percent, @equ_iso, @descrip, @saxaz_code, @tax_payer_name, @tax_payer_code, @cor_bank_code, @cor_bank_name, @intermed_bank_code, @intermed_bank_name, @extra_info, @extra_info_descrip, @det_of_charg, @receiver_acc, @receiver_acc_name, @sender_address_lat, @receiver_address_lat, @receiver_bank_code, @receiver_bank_name, @receiver_tax_code, @priority, @credit_acc_type, @credit_acc_sub_type
			END

			CLOSE credit_cr
			DEALLOCATE credit_cr
		END
	END	

	IF ISNULL(@error_code, 0) = 0
	BEGIN		
		DECLARE tran_cr CURSOR LOCAL FAST_FORWARD FOR

		SELECT ID, DEBIT_ACC_ID, CREDIT_ACC_ID, AMOUNT, AMOUNT_EQU, DEBIT_CCY, CREDIT_CCY, BLOCKED_AMOUNT, REF_NO, CHECK_SALDO, DOC_TYPE, ADD_TARIFF, DESCRIP, DESCRIP_LAT, SAXAZKOD, TAX_PAYER_NAME, TAX_PAYER_TAX_CODE, RECEIVER_BANK_CODE, RECEIVER_BANK_NAME, RECEIVER_ACC, RECEIVER_ACC_NAME, RECEIVER_TAX_CODE, RECEIVER_ADDRESS_LAT, INTERMED_BANK_CODE, INTERMED_BANK_NAME, EXTRA_INFO_DESCRIP, EXTRA_INFO, DET_OF_CHARG, COR_BANK_CODE, COR_BANK_NAME, SENDER_ADDRESS_LAT, SENDER_ACC, SENDER_ACC_NAME, SENDER_ACC_NAME_LAT, SENDER_TAX_CODE
		FROM @TRANSACTION_LIST t
		WHERE t.AMOUNT > $0.00 AND t.AMOUNT_EQU > $0.00

		OPEN tran_cr

		FETCH NEXT FROM tran_cr
		INTO @id, @debit_acc_id, @credit_acc_id, @transaction_amount, @transaction_amount_equ, @debit_ccy, @credit_ccy, @blocked_amount, @ref_no, @check_saldo, @doc_type, @add_tariff, @descrip, @descrip_lat, @saxaz_code, @tax_payer_name, @tax_payer_code, @receiver_bank_code, @receiver_bank_name, @receiver_acc, @receiver_acc_name, @receiver_tax_code, @receiver_address_lat, @intermed_bank_code, @intermed_bank_name, @extra_info_descrip, @extra_info, @det_of_charg, @cor_bank_code, @cor_bank_name, @sender_address_lat, @sender_acc, @sender_acc_name, @sender_acc_name_lat, @sender_tax_code
		
		IF (SELECT COUNT(*) FROM @TRANSACTION_LIST WHERE DEBIT_CCY = CREDIT_CCY) > 1 
			SET @parent_rec_id = -1
			
		WHILE @@FETCH_STATUS = 0 AND ISNULL(@error_code, 0) = 0
		BEGIN
			BEGIN TRY
				IF (@debit_ccy <> @credit_ccy)
				BEGIN
					EXEC @r = dbo.ADD_CONV_DOC4
						@rec_id_1 = @d_id OUTPUT,        
						@rec_id_2 = @d_id,        
						@user_id = @user_id,                
						@iso_d = @debit_ccy,
						@iso_c = @credit_ccy,              
						@amount_d = @transaction_amount,
						@amount_c = @transaction_amount_equ,   
						@debit_id = @debit_acc_id,
						@credit_id = @credit_acc_id,
						@doc_date = @date,   
						@op_code = @op_code,
						@account_extra = @processing_task_id,
						@descrip1 = @descrip,
						@descrip2 = @descrip,   
						@rec_state = @doc_state,   
						@par_rec_id = @parent_rec_id,
						@dept_no = @dept_no,   
						@relation_id = @relation_id,
						@flags = 0x00000004,
	--					@lat_descrip = @descrip_lat,
						@client_no = @client_no,
	--					@doc_type1 smallint = null,
	--					@doc_type2 smallint = null,
						@check_saldo = @check_saldo,   
						@add_tariff = @add_tariff,
						@info = 0   
	--					@lat = 0
				END
				ELSE
				BEGIN	
					SET @sender_bank_code = CASE WHEN @doc_type BETWEEN 110 AND 119 THEN @our_bank_bic ELSE CONVERT(varchar(100), @our_bank_code9) END
					SET @sender_bank_name = CASE WHEN @doc_type BETWEEN 110 AND 119 THEN @our_bank_name_fx ELSE @our_bank_name END
					SET @descrip = CASE WHEN @doc_type BETWEEN 110 AND 119 THEN @descrip_lat ELSE @descrip END

					EXEC @r = dbo.ADD_DOC4
						@rec_id = @d_id OUTPUT,
						@user_id = @user_id,
						@doc_type = @doc_type,
						@doc_date = @date,
						@debit_id = @debit_acc_id,
						@credit_id = @credit_acc_id,
						@iso = @debit_ccy,
						@amount = @transaction_amount,
						@rec_state = @doc_state,
						@descrip = @descrip,
						@op_code = @op_code,
						@parent_rec_id = @parent_rec_id,
						@account_extra = @processing_task_id,
						@dept_no = @dept_no,
						@relation_id = @relation_id,
						@flags = 0x00000004,

						@sender_bank_code = @sender_bank_code,
						@sender_bank_name = @sender_bank_name,
						@sender_acc = @sender_acc,
						@sender_acc_name = @sender_acc_name,
						@sender_tax_code = @sender_tax_code,
						@receiver_bank_code = @receiver_bank_code,
						@receiver_bank_name = @receiver_bank_name,
						@receiver_acc = @receiver_acc,
						@receiver_acc_name = @receiver_acc_name,
						@receiver_tax_code = @receiver_tax_code,
						@extra_info = @extra_info,
						@ref_num = @ref_no,
						@rec_date = @date,
						@saxazkod = @saxaz_code,
						@tax_payer_tax_code = @tax_payer_code,
						@tax_payer_name = @tax_payer_name,
						@intermed_bank_code = @intermed_bank_code,
						@intermed_bank_name = @intermed_bank_name,
	--					@swift_text = @swift_text,
						@cor_bank_code = @cor_bank_code,
						@cor_bank_name = @cor_bank_name,
						@det_of_charg = @det_of_charg,
						@extra_info_descrip = @extra_info_descrip,  
						@sender_address_lat = @sender_address_lat,
						@receiver_address_lat = @receiver_address_lat,	
						@check_saldo = @check_saldo,
	--					@check_limits = 1,
	--					@lat = 0,
	--					@unblock = 0
						@add_tariff = @add_tariff
				END

				IF @r = 0
					UPDATE @TRANSACTION_LIST SET DOC_REC_ID = @d_id WHERE ID = @id

				IF @parent_rec_id = -1
					SET @parent_rec_id = @d_id
					
				IF @relation_id IS NULL
					SET @relation_id = @d_id
			END TRY
			BEGIN CATCH
				SET @error_msg = ERROR_MESSAGE()
				SET @error_code = ERROR_NUMBER()

				IF @relation_id IS NULL
					SET @relation_id = @d_id

				IF @debt_action = 1 -- თუ ნაწილობრივი შესრულებაა
				BEGIN
					SET @error_code = NULL
					SET @error_msg = NULL
				END
				ELSE
					BREAK
			END CATCH
			
			FETCH NEXT FROM tran_cr
			INTO @id, @debit_acc_id, @credit_acc_id, @transaction_amount, @transaction_amount_equ, @debit_ccy, @credit_ccy, @blocked_amount, @ref_no, @check_saldo, @doc_type, @add_tariff, @descrip, @descrip_lat, @saxaz_code, @tax_payer_name, @tax_payer_code, @receiver_bank_code, @receiver_bank_name, @receiver_acc, @receiver_acc_name, @receiver_tax_code, @receiver_address_lat, @intermed_bank_code, @intermed_bank_name, @extra_info_descrip, @extra_info, @det_of_charg, @cor_bank_code, @cor_bank_name, @sender_address_lat, @sender_acc, @sender_acc_name, @sender_acc_name_lat, @sender_tax_code
		END

		CLOSE tran_cr
		DEALLOCATE tran_cr
	END

	IF ISNULL(@error_code, 0) = 0
	BEGIN
		UPDATE dbo.SO_SCHEDULES SET [STATE] = 50, FAULT_MESSAGE = NULL, FAULT_CODE = NULL, DOC_REC_ID = @relation_id
		WHERE TASK_ID = @processing_task_id AND [DATE] = @schedule_date

		INSERT INTO dbo.SO_SCHEDULE_CHANGES ([TASK_ID], [DATE], [USER_ID], [FIELD], OLD_VALUE, NEW_VALUE, OLD_DISPLAY_VALUE, NEW_DISPLAY_VALUE)
			VALUES (@processing_task_id, @schedule_date, @user_id, 'STATE', @schedule_state, 50, 
				CASE WHEN @schedule_state = 20 THEN 'ÀØÔÉÖÒÉ'
					WHEN @schedule_state = 30 THEN 'ÃÀÄËÏÃÏÓ ÌÏØÌÄÃÄÁÀÓ'
					ELSE CONVERT(varchar(10), @schedule_state)
				END, 
				CASE WHEN ISNULL(@is_partially_done, 0) = 1 THEN 'ÃÀÓÒÖËÄÁÖËÉ ßÀÒÌÀÔÄÁÖËÀÃ (ÍÀßÉËÏÁÒÉÅÉ ÛÄÓÒÖËÄÁÀ)' ELSE 'ÃÀÓÒÖËÄÁÖËÉ ßÀÒÌÀÔÄÁÖËÀÃ' END)

		IF (@period_type = 1 AND @end_date <= ISNULL(@fixed_date, @date)) OR (@period_type <> 1 AND NOT EXISTS(SELECT * FROM SO_SCHEDULES (NOLOCK) WHERE TASK_ID = @processing_task_id AND [DATE] >= @schedule_date AND [STATE] IN (20, 30)))
		BEGIN
			UPDATE dbo.SO_TASKS WITH (ROWLOCK)
				SET [STATE] = 255 
			WHERE ID = @processing_task_id

			INSERT INTO dbo.SO_TASK_CHANGES ([TASK_ID], [USER_ID], [FIELD], OLD_VALUE, NEW_VALUE, OLD_DISPLAY_VALUE, NEW_DISPLAY_VALUE)
				VALUES (@processing_task_id, @user_id, 'STATE', @task_state, 255, 'ÀØÔÉÖÒÉ', 'ÃÀáÖÒÖËÉ')
		END
	END
	ELSE
	BEGIN
		DECLARE tran_cr CURSOR LOCAL FAST_FORWARD FOR

		SELECT t.DEBIT_ACC_ID, t.AMOUNT, t.DEBIT_CCY, t.BLOCKED_AMOUNT, t.REF_NO, a.ACCOUNT, a.ACC_TYPE, a.ACC_SUBTYPE, t.DOC_REC_ID
		FROM @TRANSACTION_LIST t
			JOIN dbo.ACCOUNTS a ON t.DEBIT_ACC_ID = a.ACC_ID
		WHERE t.AMOUNT > $0.00 AND t.AMOUNT_EQU > $0.00 AND (ISNULL(t.BLOCKED_AMOUNT, $0.00) <> $0.00 OR t.DOC_REC_ID IS NOT NULL)

		OPEN tran_cr

		FETCH NEXT FROM tran_cr
		INTO @debit_acc_id, @transaction_amount, @debit_ccy, @blocked_amount, @ref_no, @debit_acc, @debit_acc_type, @debit_acc_sub_type, @d_id
		
		WHILE @@FETCH_STATUS = 0
		BEGIN
			IF (ISNULL(@blocked_amount, $0.00) <> $0.00)
				EXEC dbo.so_get_acc_balance
					@date = @date,
					@client_no = @client_no,
					@acc_id = @debit_acc_id,
					@acc_type = @debit_acc_type,
					@acc_sub_type = @debit_acc_sub_type,
					@acc_no = @debit_acc,
					@is_debit = 1,
					@ccy = @debit_ccy,
					@ref_no = @ref_no,
					@block_amount = @blocked_amount,
					@cancel_operation = 1,
					@amount = NULL,
					@check_saldo = 0,
					@error_code = NULL,
					@error_msg = NULL,
					@error_msg_lat = NULL
				
			IF (ISNULL(@d_id, 0) = 1)
				EXEC @r = dbo.DELETE_DOC 
					@rec_id = @d_id,
					@user_id = @user_id,
					@check_saldo = 0,
					@dont_check_up = 0,
					@check_limits = 0,
					@info = 0,
					@lat = 0
			
			FETCH NEXT FROM tran_cr
			INTO @debit_acc_id, @transaction_amount, @debit_ccy, @blocked_amount, @ref_no, @debit_acc, @debit_acc_type, @debit_acc_sub_type, @d_id
		END
		
		CLOSE tran_cr
		DEALLOCATE tran_cr

		DECLARE
			@new_schedule_state int
			select @error_code, @error_msg
		UPDATE dbo.SO_SCHEDULES WITH (ROWLOCK)
			SET FAULT_MESSAGE = @error_msg, 
				FAULT_CODE = @error_code, 
				@new_schedule_state = 
				[STATE] = CASE WHEN ISNULL(FAIL_COUNTER, 0) = @retry_count_per_pay THEN 40 ELSE 
							CASE WHEN @debt_action = 0 THEN [STATE]
								WHEN @debt_action = 1 THEN [STATE]			--აქ მოხვდება მხოლოდ სისტემური შეცდომის დროს
								WHEN @debt_action = 2 THEN 40
								WHEN @debt_action = 3 THEN [STATE]			--აქ მოხვდება მხოლოდ სისტემური შეცდომის დროს
								WHEN @debt_action = 4 THEN 30
							END
						  END,
				@fails_by_date = @fails_by_date + 1,
				FAIL_COUNTER = CASE WHEN ISNULL(FAIL_COUNTER, 0) = @retry_count_per_pay AND @retry_count_per_pay > 0 THEN @retry_count_per_pay ELSE ISNULL(FAIL_COUNTER, 0) + 1 END
		WHERE TASK_ID = @processing_task_id AND [DATE] = @schedule_date

		IF (@schedule_state <> @new_schedule_state)
			INSERT INTO dbo.SO_SCHEDULE_CHANGES ([TASK_ID], [DATE], [USER_ID], [FIELD], OLD_VALUE, NEW_VALUE, OLD_DISPLAY_VALUE, NEW_DISPLAY_VALUE)
				VALUES (@processing_task_id, @schedule_date, @user_id, 'STATE', @schedule_state, @new_schedule_state, 
					CASE WHEN @schedule_state = 20 THEN 'ÀØÔÉÖÒÉ' 
						WHEN @schedule_state = 30 THEN 'ÃÀÄËÏÃÏÓ ÌÏØÌÄÃÄÁÀÓ' 
						ELSE CONVERT(varchar(10), @schedule_state)
					END, 
					CASE WHEN @new_schedule_state = 20 THEN 'ÀØÔÉÖÒÉ' 
						WHEN @new_schedule_state = 30 THEN 'ÃÀÄËÏÃÏÓ ÌÏØÌÄÃÄÁÀÓ' 
						WHEN @new_schedule_state = 40 THEN 'ÃÀÓÒÖËÄÁÖËÉ ßÀÒÖÌÀÔÄÁËÀÃ' 
						ELSE CONVERT(varchar(10), @new_schedule_state)
					END)

		IF @fails_by_date > @retry_count_per_pay AND ((@period_type = 1 AND @end_date <= ISNULL(@fixed_date, @date)) OR (@period_type <> 1 AND (SELECT COUNT(*) FROM dbo.SO_SCHEDULES (NOLOCK) WHERE [DATE] < @date AND TASK_ID = @processing_task_id AND [STATE] = 40) > @max_failure_count))
		BEGIN
			UPDATE dbo.SO_TASKS WITH (ROWLOCK)
				SET [STATE] = 255 
			WHERE ID = @processing_task_id

			INSERT INTO dbo.SO_TASK_CHANGES ([TASK_ID], [USER_ID], [FIELD], OLD_VALUE, NEW_VALUE, OLD_DISPLAY_VALUE, NEW_DISPLAY_VALUE)
				VALUES (@processing_task_id, @user_id, 'STATE', @task_state, 255, 'ÀØÔÉÖÒÉ', 'ÃÀáÖÒÖËÉ')
		END

		IF (@task_id IS NOT NULL) AND (ISNULL(@raise_exception, 0) <> 0)
		BEGIN
			IF (CHARINDEX('</ERR>', @error_msg) = 0)			
				SET @error_msg = '<ERR>' + @error_msg + '</ERR>'
			
			RAISERROR (@error_msg, 16, 1)
			RETURN -1
		END
	END

	--EXEC [dbo].[SO_GET_OPERATIONS]	@relation_id
	--SELECT * FROM @TRANSACTION_LIST
	--SELECT * FROM SO_SCHEDULES WHERE TASK_ID = @processing_task_id
	--SELECT * FROM SO_SCHEDULE_CHANGES WHERE TASK_ID = @processing_task_id

	FETCH NEXT FROM cr INTO
		@processing_task_id, @trigger_amount, @min_balance_amount, @dept_no, @agreement_no, @client_no, @retry_count_per_pay, @max_failure_count, @debt_action, @priority, @order_descrip, @order_descrip_lat, @fx_rate_type, @task_state, @period_type, @end_date,
		@schedule_date, @fails_by_date, @schedule_state,
		@product_type, @fee_recv_percent, @fee_min, @priority, @product_state, @product_owner, @use_tariff, @op_code, @doc_state, @prod_doc_type

	IF (@task_id IS NOT NULL)
		SET @doc_rec_id = @relation_id
END

CLOSE cr
DEALLOCATE cr
	
RETURN 0
GO
