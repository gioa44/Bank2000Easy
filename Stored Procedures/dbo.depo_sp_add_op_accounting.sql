SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[depo_sp_add_op_accounting]
	@doc_rec_id int OUTPUT,
	@accrue_doc_rec_id int OUTPUT,
	@op_id int,
	@user_id int
AS

SET NOCOUNT ON;

SET @doc_rec_id = NULL
SET @accrue_doc_rec_id = NULL

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
	@depo_id int,
	@op_date smalldatetime,
	@op_type smallint, 
	@amount money,
	@op_data XML,
	@op_acc_data XML

SELECT @depo_id = DEPO_ID, @op_date = OP_DATE, @op_type = OP_TYPE, @amount = AMOUNT, @op_data = OP_DATA, @op_acc_data = OP_ACC_DATA
FROM dbo.DEPO_OP (NOLOCK)
WHERE OP_ID = @op_id

IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('OPERATION NOT FOUND', 16, 1); RETURN (1); END

DECLARE
	@rec_state tinyint,
	@add_with_accounting bit,
	@accrue_before_add bit,
	@add_doc_rec_state tinyint,
	@add_doc_rec_state_cash tinyint

SELECT @add_with_accounting = ADD_WITH_ACCOUNTING, @add_doc_rec_state = ADD_DOC_REC_STATE, @add_doc_rec_state_cash = ADD_DOC_REC_STATE_CASH, @accrue_before_add = ACCRUE_BEFORE_ADD
FROM dbo.DEPO_OP_TYPES (NOLOCK)
WHERE [TYPE_ID] = @op_type
IF @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('OPERATION TYPE NOT FOUND', 16, 1); RETURN (1); END

DECLARE
	@dept_no int,
	@depo_acc_id int,
	@interest_realize_acc_id int,
	@accumulate_schema_intrate tinyint

SELECT  @dept_no = DEPT_NO, @depo_acc_id = DEPO_ACC_ID, @interest_realize_acc_id = INTEREST_REALIZE_ACC_ID, @accumulate_schema_intrate = ISNULL(ACCUMULATE_SCHEMA_INTRATE, 0)
FROM dbo.DEPO_DEPOSITS (NOLOCK)
WHERE DEPO_ID = @depo_id
IF @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('DEPOSIT CONTRACT NOT FOUND', 16, 1); RETURN (1); END

IF @op_type = dbo.depo_fn_const_op_accumulate() AND (@accumulate_schema_intrate <> 2)
	SET @accrue_before_add = 0

IF (@accrue_before_add = 1) AND (@depo_acc_id <> @interest_realize_acc_id)
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
	IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('ERROR PROCESS ACRRUAL', 16, 1); RETURN (1); END

	IF @accrue_doc_rec_id IS NOT NULL
	BEGIN
		UPDATE dbo.OPS_0000 WITH(UPDLOCK)
		SET [UID] = [UID] + 1, FLAGS = 1
		WHERE REC_ID = @accrue_doc_rec_id
		IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('ERROR PROCESS ACRRUAL DOC FLAGS CHANGE', 16, 1); RETURN (1); END
	END
END

IF @add_with_accounting = 0 GOTO _end

DECLARE
	@client_no int,
	@trust_client_no int,
	@agreement_no varchar(150),
	@iso TISO,
	@rec_id_tmp int,
	@parent_rec_id int,
	@tax_acc_id int,
	@tax_rate money

DECLARE
	@sender_bank_code varchar(37),
	@sender_bank_name varchar(105),
	@sender_acc varchar(37),
	@sender_acc_name varchar(105),
	@sender_tax_code varchar(11),

	@receiver_bank_code varchar(37),
	@receiver_bank_name varchar(105),
	@receiver_acc varchar(37),
	@receiver_acc_name varchar(105),
	@receiver_tax_code varchar(11)


SELECT @dept_no = DEPT_NO, @client_no = CLIENT_NO, @trust_client_no = TRUST_CLIENT_NO, @agreement_no = AGREEMENT_NO, @iso = ISO, @depo_acc_id = DEPO_ACC_ID
FROM dbo.DEPO_DEPOSITS (NOLOCK)
WHERE DEPO_ID = @depo_id
IF @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('DEPOSIT CONTRACT NOT FOUND', 16, 1); RETURN (1); END

DECLARE
	@transfer_doc_type int,
	@transfer_doc_type_adv int

DECLARE
	@depo_fill_acc_id int,
	@interest_realize_adv bit

DECLARE
	@op_code char(5),
	@doc_type smallint,
	@descrip varchar(150)
DECLARE
	@first_name varchar(50),
	@last_name varchar(50), 
	@fathers_name varchar(50), 
	@birth_date smalldatetime, 
	@birth_place varchar(100), 
	@address_jur varchar(100), 
	@address_lat varchar(100),
	@country varchar(2), 
	@passport_type_id tinyint, 
	@passport varchar(50), 
	@personal_id varchar(20),
	@reg_organ varchar(50),
	@passport_issue_dt smalldatetime,
	@passport_end_date smalldatetime



IF @op_type = dbo.depo_fn_const_op_active()
BEGIN
	IF ISNULL(@amount, $0.00) = $0.00 GOTO _end 

	EXEC @r = dbo.GET_SETTING_INT 'DEPO_TRANSFER_TYPE', @transfer_doc_type OUTPUT
	IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('ERROR REAGING SETTING' , 16, 1); RETURN (1); END

	SELECT @depo_fill_acc_id = DEPO_FILL_ACC_ID, @interest_realize_adv = INTEREST_REALIZE_ADV 
	FROM dbo.DEPO_VW_OP_DATA_ACTIVE
	WHERE OP_ID = @op_id
	IF @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('OPERATION DATA NOT FOUND', 16, 1); RETURN (1); END 

	SELECT @transfer_doc_type_adv = @transfer_doc_type, @transfer_doc_type = CASE WHEN ACC_TYPE & 0x02 = 0x02 THEN -1 ELSE @transfer_doc_type END
	FROM dbo.ACCOUNTS (NOLOCK)
	WHERE ACC_ID = @depo_fill_acc_id

	SET @parent_rec_id = CASE WHEN @interest_realize_adv = 1 THEN -1 ELSE 0 END
	
	IF @transfer_doc_type = -1 --Cash Order
	BEGIN
		IF @trust_client_no IS NOT NULL
		BEGIN
			SELECT @first_name = FIRST_NAME, @last_name = LAST_NAME, @fathers_name = FATHERS_NAME, @birth_date = BIRTH_DATE, @birth_place = BIRTH_PLACE, 
				@country = COUNTRY, @passport_type_id = PASSPORT_TYPE_ID, @passport = PASSPORT, @personal_id = PERSONAL_ID, @reg_organ = PASSPORT_REG_ORGAN,
				@passport_issue_dt = PASSPORT_ISSUE_DT, @passport_end_date = PASSPORT_END_DATE
			FROM dbo.CLIENTS (NOLOCK)
			WHERE CLIENT_NO = @trust_client_no

			SET @address_jur = dbo.cli_get_cli_attribute(@trust_client_no, '$ADDRESS_LEGAL')
			SET @address_lat = dbo.cli_get_cli_attribute(@trust_client_no, '$ADDRESS_LAT')
		END
		ELSE
		BEGIN
			SELECT @first_name = FIRST_NAME, @last_name = LAST_NAME, @fathers_name = FATHERS_NAME, @birth_date = BIRTH_DATE, @birth_place = BIRTH_PLACE, 
				@country = COUNTRY, @passport_type_id = PASSPORT_TYPE_ID, @passport = PASSPORT, @personal_id = PERSONAL_ID, @reg_organ = PASSPORT_REG_ORGAN,
				@passport_issue_dt = PASSPORT_ISSUE_DT, @passport_end_date = PASSPORT_END_DATE
			FROM dbo.CLIENTS (NOLOCK)
			WHERE CLIENT_NO = @client_no

			SET @address_jur = dbo.cli_get_cli_attribute(@client_no, '$ADDRESS_LEGAL')
			SET @address_lat = dbo.cli_get_cli_attribute(@client_no, '$ADDRESS_LAT')
		END
		
		SET @op_code = CASE @iso WHEN 'GEL' THEN '07' ELSE '21' END
		SET @doc_type = 120
		SET @descrip = 'ÛÄÌÏÓÀÅËÄÁÉ ÌÏØÀËÀØÄÈÀ ÀÍÀÁÒÄÁÆÄ (áÄËÛ. #' + @agreement_no + ')'

		EXEC @r = dbo.ADD_DOC4
			@rec_id = @doc_rec_id OUTPUT,
			@user_id = @user_id,
			@doc_type = @doc_type, 
			@doc_date = @op_date,
			@doc_date_in_doc = @op_date,
			@debit_id = @depo_fill_acc_id,
			@credit_id = @depo_acc_id,
			@iso = @iso, 
			@amount = @amount,
			@rec_state = @add_doc_rec_state_cash,
			@descrip = @descrip,
			@op_code = @op_code,
			@first_name = @first_name,
			@last_name = @last_name,
			@fathers_name = @fathers_name,
			@birth_date = @birth_date,
			@birth_place = @birth_place,
			@address_jur = @address_jur,
			@address_lat = @address_lat,
			@country = @country,
			@passport_type_id = @passport_type_id,
			@passport = @passport,
			@personal_id = @personal_id,
			@reg_organ = @reg_organ,
			@passport_issue_dt = @passport_issue_dt,
			@passport_end_date = @passport_end_date,
			@account_extra = @depo_acc_id,
			@channel_id = 800,
			@flags = 0x15F4,
			@parent_rec_id = @parent_rec_id

		IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('ERROR ADD DOCUMENT' , 16, 1); RETURN (1); END
	END
	ELSE
	IF @transfer_doc_type = 0 --Memorial Order
	BEGIN
		SET @op_code = '*DAA*'
		SET @doc_type = 98
		SET @descrip = 'ÃÄÐÏÆÉÔÆÄ ÈÀÍáÉÓ ÂÀÃÀÔÀÍÀ (áÄËÛ. #' + @agreement_no + ')'

		EXEC @r = dbo.ADD_DOC4
			@rec_id = @doc_rec_id OUTPUT,
			@user_id = @user_id,
			@doc_type = @doc_type,
			@doc_date = @op_date,
			@debit_id = @depo_fill_acc_id,
			@credit_id = @depo_acc_id,
			@iso = @iso,
			@amount = @amount,
			@rec_state = @add_doc_rec_state,
			@descrip = @descrip,
			@op_code = @op_code,
			@account_extra = @depo_acc_id,
			@channel_id = 800,
			@flags = 0x15F4,
			@parent_rec_id = @parent_rec_id

		IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('ERROR ADD DOCUMENT' , 16, 1); RETURN (1); END
	END
	ELSE
	IF @transfer_doc_type = 1 --Transfer
	BEGIN
		IF @iso = 'GEL'
		BEGIN
			SET @sender_bank_code = dbo.acc_get_bank_code(@depo_fill_acc_id)
			SELECT @sender_bank_name = DESCRIP FROM dbo.BANKS (NOLOCK) WHERE CODE9 = @sender_bank_code
			SET @sender_acc_name = dbo.acc_get_name(@depo_fill_acc_id)

			SET @sender_acc = dbo.acc_get_account(@depo_fill_acc_id)
			SELECT @sender_tax_code =  CASE WHEN ISNULL(C.TAX_INSP_CODE, '') <> '' THEN C.TAX_INSP_CODE ELSE C.PERSONAL_ID END FROM dbo.CLIENTS C(NOLOCK) WHERE C.CLIENT_NO = @client_no 
			
			SET @receiver_bank_code = dbo.acc_get_bank_code(@depo_acc_id)
			SELECT @receiver_bank_name = DESCRIP FROM dbo.BANKS (NOLOCK) WHERE CODE9 = @receiver_bank_code
			SET @receiver_acc_name = dbo.acc_get_name(@depo_acc_id)
			SET @receiver_acc = dbo.acc_get_account(@depo_acc_id)
			SELECT @receiver_tax_code =  CASE WHEN ISNULL(C.TAX_INSP_CODE, '') <> '' THEN C.TAX_INSP_CODE ELSE C.PERSONAL_ID END FROM dbo.CLIENTS C(NOLOCK) WHERE C.CLIENT_NO = @client_no 
		END
		ELSE
		BEGIN
			SET @sender_bank_code = dbo.acc_get_bank_code_bic(@depo_fill_acc_id)
			SELECT @sender_bank_name = DESCRIP FROM dbo.BIC_CODES (NOLOCK) WHERE BIC = @sender_bank_code
			SET @sender_acc_name = dbo.acc_get_name_lat(@depo_fill_acc_id)

			SET @sender_acc = dbo.acc_get_account(@depo_fill_acc_id)
			SELECT @sender_tax_code =  CASE WHEN ISNULL(C.TAX_INSP_CODE, '') <> '' THEN C.TAX_INSP_CODE ELSE C.PERSONAL_ID END FROM dbo.CLIENTS C(NOLOCK) WHERE C.CLIENT_NO = @client_no 
			
			SET @receiver_bank_code = dbo.acc_get_bank_code_bic(@depo_acc_id)
			SELECT @receiver_bank_name = DESCRIP FROM dbo.BIC_CODES (NOLOCK) WHERE BIC = @receiver_bank_code
			SET @receiver_acc_name = dbo.acc_get_name_lat(@depo_acc_id)
			SET @receiver_acc = dbo.acc_get_account(@depo_acc_id)
			SELECT @receiver_tax_code =  CASE WHEN ISNULL(C.TAX_INSP_CODE, '') <> '' THEN C.TAX_INSP_CODE ELSE C.PERSONAL_ID END FROM dbo.CLIENTS C(NOLOCK) WHERE C.CLIENT_NO = @client_no 
		END
		
		SET @op_code = '*DAA*'
		SET @doc_type = CASE @iso WHEN 'GEL' THEN 100 ELSE 110 END
		SET @descrip = 'ÃÄÐÏÆÉÔÆÄ ÈÀÍáÉÓ ÜÀÒÉÝáÅÀ (áÄËÛ. #' + @agreement_no + ')'

		EXEC @r = dbo.ADD_DOC4
			@rec_id = @doc_rec_id OUTPUT,
			@user_id = @user_id,
			@doc_type = @doc_type,
			@doc_date = @op_date,
			@debit_id = @depo_fill_acc_id,
			@credit_id = @depo_acc_id,
			@iso = @iso,
			@amount = @amount,
			@rec_state = @add_doc_rec_state,
			@descrip = @descrip,
			@op_code = @op_code,
			@account_extra = @depo_acc_id,
			@channel_id = 800,
			@flags = 0x15F4,
			@parent_rec_id = @parent_rec_id,

			@sender_bank_code = @sender_bank_code,
			@sender_acc = @sender_acc,
			@sender_tax_code = @sender_tax_code,
			@receiver_bank_code = @receiver_bank_code,
			@receiver_acc = @receiver_acc,
			@receiver_tax_code = @receiver_tax_code,
			@sender_bank_name = @sender_bank_name,
			@receiver_bank_name = @receiver_bank_name,
			@sender_acc_name = @sender_acc_name,
			@receiver_acc_name = @receiver_acc_name


		IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('ERROR ADD DOCUMENT' , 16, 1) RETURN (1) END
	END

	DECLARE
		@depo_realize_acc_id int,
		@interest_realize_adv_amount money,
		@interest_realize_adv_tax_amount money,
		@interest_realize_adv_tax_amount_equ money,
		@interest_realize_adv_acc_id int

	SET @interest_realize_acc_id = NULL

	SELECT @depo_realize_acc_id = DEPO_REALIZE_ACC_ID,
		@interest_realize_acc_id = INTEREST_REALIZE_ACC_ID, @interest_realize_adv_amount = INTEREST_REALIZE_ADV_AMOUNT,
		@interest_realize_adv_acc_id = INTEREST_REALIZE_ADV_ACC_ID
	FROM dbo.DEPO_VW_OP_DATA_ACTIVE
	WHERE OP_ID = @op_id
	IF @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('OPERATION DATA NOT FOUND', 16, 1); RETURN (1); END 

	IF @interest_realize_adv = 1
	BEGIN
		SET @parent_rec_id = CASE WHEN @doc_rec_id IS NULL THEN 0 ELSE @doc_rec_id END
		IF @transfer_doc_type = -1
			SET @rec_state = @add_doc_rec_state_cash
		ELSE
			SET @rec_state = @add_doc_rec_state			

		SET @transfer_doc_type_adv = 0 --Republic Dokho & Imeda
		IF @transfer_doc_type_adv = 0 --Memorial Order
		BEGIN
			SET @op_code = '*%RL*'
			SET @doc_type = 98
			SET @descrip = 'ÀÍÀÁÀÒÆÄ ßÉÍÀÓßÀÒ ÂÀÝÄÌÖËÉ ÐÒÏÝÄÍÔÉ (áÄËÛ. #' + @agreement_no + ')'

			EXEC @r = dbo.ADD_DOC4
				@rec_id = @rec_id_tmp OUTPUT,
				@user_id = @user_id,
				@doc_type = @doc_type,
				@doc_date = @op_date,
				@debit_id = @interest_realize_adv_acc_id,
				@credit_id = @interest_realize_acc_id,
				@iso = @iso,
				@amount = @interest_realize_adv_amount,
				@rec_state = @rec_state,
				@descrip = @descrip,
				@op_code = @op_code,
				@account_extra = @depo_acc_id,
				@channel_id = 800,
				@flags = 0x15F4,
				@parent_rec_id = @parent_rec_id,
				@check_saldo = 0

			IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('ERROR ADD DOCUMENT', 16, 1); RETURN (1); END
		END
		ELSE
		IF @transfer_doc_type_adv = 1 --Transfer Order
		BEGIN
			IF @iso = 'GEL'
			BEGIN
				SET @sender_bank_code = dbo.acc_get_bank_code(@interest_realize_adv_acc_id)
				SELECT @sender_bank_name = DESCRIP FROM dbo.BANKS (NOLOCK) WHERE CODE9 = @sender_bank_code
				SET @sender_acc_name = dbo.acc_get_name(@interest_realize_adv_acc_id)
				SET @sender_acc = dbo.acc_get_account(@interest_realize_adv_acc_id)
				SELECT @sender_tax_code =  NULL
				
				SET @receiver_bank_code = dbo.acc_get_bank_code(@interest_realize_acc_id)
				SELECT @receiver_bank_name = DESCRIP FROM dbo.BANKS (NOLOCK) WHERE CODE9 = @receiver_bank_code
				SET @receiver_acc_name = dbo.acc_get_name(@interest_realize_acc_id)
				SET @receiver_acc = dbo.acc_get_account(@interest_realize_acc_id)
				SELECT @receiver_tax_code =  CASE WHEN ISNULL(C.TAX_INSP_CODE, '') <> '' THEN C.TAX_INSP_CODE ELSE C.PERSONAL_ID END FROM dbo.CLIENTS C(NOLOCK) WHERE C.CLIENT_NO = @client_no 
			END
			ELSE
			BEGIN
				SET @sender_bank_code = dbo.acc_get_bank_code_bic(@interest_realize_adv_acc_id)
				SELECT @sender_bank_name = DESCRIP FROM dbo.BIC_CODES (NOLOCK) WHERE BIC = @sender_bank_code
				SET @sender_acc_name = dbo.acc_get_name_lat(@interest_realize_adv_acc_id)
				SET @sender_acc = dbo.acc_get_account(@interest_realize_adv_acc_id)
				SELECT @sender_tax_code =  CASE WHEN ISNULL(C.TAX_INSP_CODE, '') <> '' THEN C.TAX_INSP_CODE ELSE C.PERSONAL_ID END FROM dbo.CLIENTS C(NOLOCK) WHERE C.CLIENT_NO = @client_no 
				
				SET @receiver_bank_code = dbo.acc_get_bank_code_bic(@interest_realize_acc_id)
				SELECT @receiver_bank_name = DESCRIP FROM dbo.BIC_CODES (NOLOCK) WHERE BIC = @receiver_bank_code
				SET @receiver_acc_name = dbo.acc_get_name_lat(@interest_realize_acc_id)
				SET @receiver_acc = dbo.acc_get_account(@interest_realize_acc_id)
				SELECT @receiver_tax_code =  CASE WHEN ISNULL(C.TAX_INSP_CODE, '') <> '' THEN C.TAX_INSP_CODE ELSE C.PERSONAL_ID END FROM dbo.CLIENTS C(NOLOCK) WHERE C.CLIENT_NO = @client_no 
			END

			SET @op_code = '*%RL*'
			SET @doc_type = CASE @iso WHEN 'GEL' THEN 100 ELSE 110 END
			SET @descrip = 'ÀÍÀÁÀÒÆÄ ßÉÍÀÓßÀÒ ÂÀÝÄÌÖËÉ ÐÒÏÝÄÍÔÉ (áÄËÛ. #' + @agreement_no + ')'

			EXEC @r = dbo.ADD_DOC4
				@rec_id = @rec_id_tmp OUTPUT,
				@user_id = @user_id,
				@doc_type = @doc_type,
				@doc_date = @op_date,
				@debit_id = @interest_realize_adv_acc_id,
				@credit_id = @interest_realize_acc_id,
				@iso = @iso,
				@amount = @interest_realize_adv_amount,
				@rec_state = @rec_state,
				@descrip = @descrip,
				@op_code = @op_code,
				@account_extra = @depo_acc_id,
				@channel_id = 800,
				@flags = 0x15F4,
				@parent_rec_id = @parent_rec_id,
				@check_saldo = 0,

				@sender_bank_code = @sender_bank_code,
				@sender_acc = @sender_acc,
				@sender_tax_code = @sender_tax_code,
				@receiver_bank_code = @receiver_bank_code,
				@receiver_acc = @receiver_acc,
				@receiver_tax_code = @receiver_tax_code,
				@sender_bank_name = @sender_bank_name,
				@receiver_bank_name = @receiver_bank_name,
				@sender_acc_name = @sender_acc_name,
				@receiver_acc_name = @receiver_acc_name

			IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('ERROR ADD DOCUMENT', 16, 1); RETURN (1); END
		END


		EXEC @r = dbo.depo_sp_get_tax_acc
			@client_no = @client_no,
			@iso = @iso,
			@tax_acc_id = @tax_acc_id OUTPUT
		IF @@ERROR <> 0 OR @r <> 0 BEGIN RAISERROR ('ERROR FINDING TAX ACCOUNT' ,16,1) RETURN END

		SELECT @tax_rate = convert(money, VALS)
		FROM dbo.INI_STR (NOLOCK)
		WHERE IDS = 'DEPOSIT_TAX_RATE'
		IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 OR @tax_rate IS NULL BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('ERROR FINDING TAX RATE', 16, 1); RETURN (1); END

		IF @tax_rate = $0.00
		BEGIN
			DECLARE
				@tax_rate_attribute varchar(1000)

			SELECT @tax_rate_attribute = ATTRIB_VALUE
			FROM dbo.CLIENT_ATTRIBUTES (NOLOCK)
			WHERE CLIENT_NO = @client_no AND ATTRIB_CODE = '$TAXABLE'

			IF @@ERROR <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR('ERROR READING SETTINGS (DEPOSIT_TAX_RATE)', 16, 1); RETURN (1); END

			IF ISNULL(@tax_rate_attribute, '') = '1'
				SET @tax_rate = $7.5
		END
		
		SET @op_code = '*%TX*'
		SET @doc_type = 30
		SET @descrip = 'ÓÀÛÄÌÏÓÀÅËÏ ÂÀÃÀÓÀáÀÃÉ ßÉÍÀÓßÀÒ ÂÀÃÀáÃÉËÉ ÐÒÏÝÄÍÔÉÓ ÈÀÍáÉÃÀÍ (áÄËÛ. #' + @agreement_no + ')'

		SET @interest_realize_adv_tax_amount = ROUND(@interest_realize_adv_amount / $100.00 * @tax_rate, 2)

		IF @interest_realize_adv_tax_amount > $0.00
		BEGIN
			EXEC @r = dbo.ADD_DOC4
				@rec_id = @rec_id_tmp OUTPUT,
				@user_id = @user_id,
				@doc_type = @doc_type,
				@doc_date = @op_date,
				@doc_date_in_doc = @op_date,
				@debit_id = @interest_realize_acc_id,
				@credit_id = @tax_acc_id,
				@iso = @iso,
				@amount = @interest_realize_adv_tax_amount,
				@rec_state = @rec_state,
				@descrip = @descrip,
				@op_code = @op_code,
				@account_extra = @depo_acc_id,
				@channel_id = 800,
				@flags = 0x15F4,
				@parent_rec_id = @parent_rec_id,
				@check_saldo = 0
			IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('ERROR ADD DOCUMENT', 16, 1); RETURN (1) END
		END

		SET @interest_realize_adv_tax_amount_equ = ROUND(dbo.get_equ(@interest_realize_adv_tax_amount, @iso, @op_date), 2)
		
		SET @op_acc_data =
			(SELECT
				@interest_realize_adv_tax_amount AS INTEREST_REALIZE_ADV_TAX_AMOUNT,
				@interest_realize_adv_tax_amount_equ AS INTEREST_REALIZE_ADV_TAX_AMOUNT_EQU
		FOR XML RAW, TYPE)	

		UPDATE dbo.DEPO_OP WITH (UPDLOCK)
		SET OP_ACC_DATA = @op_acc_data
		WHERE OP_ID = @op_id
		IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('ERROR UPDATE OP DATA', 16, 1); RETURN (1); END
	END

	GOTO _end; 
END
ELSE
IF @op_type = dbo.depo_fn_const_op_accumulate()
BEGIN
	IF ISNULL(@amount, $0.00) = $0.00 GOTO _end;

	EXEC @r = dbo.GET_SETTING_INT 'DEPO_TRANSFER_TYPE', @transfer_doc_type OUTPUT
	IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('ERROR REAGING SETTING' , 16, 1); RETURN (1); END

	SELECT @depo_fill_acc_id = DEPO_FILL_ACC_ID
	FROM dbo.DEPO_VW_OP_DATA_ACCUMULATE
	WHERE OP_ID = @op_id
	IF @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('OPERATION DATA NOT FOUND', 16, 1); RETURN (1); END 

	SELECT @transfer_doc_type_adv = @transfer_doc_type, @transfer_doc_type = CASE WHEN ACC_TYPE & 0x02 = 0x02 THEN -1 ELSE @transfer_doc_type END
	FROM dbo.ACCOUNTS (NOLOCK)
	WHERE ACC_ID = @depo_fill_acc_id

	IF @transfer_doc_type = -1 --Cash Order
	BEGIN
		SELECT @first_name = FIRST_NAME, @last_name = LAST_NAME, @fathers_name = FATHERS_NAME, @birth_date = BIRTH_DATE, @birth_place = BIRTH_PLACE, 
			@country = COUNTRY, @passport_type_id = PASSPORT_TYPE_ID, @passport = PASSPORT, @personal_id = PERSONAL_ID, @reg_organ = PASSPORT_REG_ORGAN,
			@passport_issue_dt = PASSPORT_ISSUE_DT, @passport_end_date = PASSPORT_END_DATE
		FROM dbo.CLIENTS (NOLOCK)
		WHERE CLIENT_NO = @client_no

		SET @address_jur = dbo.cli_get_cli_attribute(@client_no, '$ADDRESS_LEGAL')
		SET @address_lat = dbo.cli_get_cli_attribute(@client_no, '$ADDRESS_LAT')

		SET @op_code = CASE @iso WHEN 'GEL' THEN '07' ELSE '21' END
		SET @doc_type = 120
		SET @descrip = 'ÛÄÌÏÓÀÅËÄÁÉ ÌÏØÀËÀØÄÈÀ ÀÍÀÁÒÄÁÆÄ (áÄËÛ. #' + @agreement_no + ')'

		EXEC @r = dbo.ADD_DOC4
			@rec_id = @doc_rec_id OUTPUT,
			@user_id = @user_id,
			@doc_type = @doc_type, 
			@doc_date = @op_date,
			@debit_id = @depo_fill_acc_id,
			@credit_id = @depo_acc_id,
			@iso = @iso, 
			@amount = @amount,
			@rec_state = @add_doc_rec_state_cash,
			@descrip = @descrip,
			@op_code = @op_code,
			@first_name = @first_name,
			@last_name = @last_name,
			@fathers_name = @fathers_name,
			@birth_date = @birth_date,
			@birth_place = @birth_place,
			@address_jur = @address_jur,
			@address_lat = @address_lat,
			@country = @country,
			@passport_type_id = @passport_type_id,
			@passport = @passport,
			@personal_id = @personal_id,
			@reg_organ = @reg_organ,
			@passport_issue_dt = @passport_issue_dt,
			@passport_end_date = @passport_end_date,
			@account_extra = @depo_acc_id,
			@channel_id = 800,
			@flags = 0x15F4

		IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('ERROR ADD DOCUMENT' , 16, 1); RETURN (1); END
	END
	ELSE
	IF @transfer_doc_type = 0 --Memorial Order
	BEGIN
		SET @op_code = '*DAA*'
		SET @doc_type = 98
		SET @descrip = 'ÃÄÐÏÆÉÔÆÄ ÈÀÍáÉÓ ÂÀÃÀÔÀÍÀ (áÄËÛ. #' + @agreement_no + ')'

		EXEC @r = dbo.ADD_DOC4
			@rec_id = @doc_rec_id OUTPUT,
			@user_id = @user_id,
			@doc_type = @doc_type,
			@doc_date = @op_date,
			@debit_id = @depo_fill_acc_id,
			@credit_id = @depo_acc_id,
			@iso = @iso,
			@amount = @amount,
			@rec_state = @add_doc_rec_state,
			@descrip = @descrip,
			@op_code = @op_code,
			@account_extra = @depo_acc_id,
			@channel_id = 800,
			@flags = 0x15F4

		IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('ERROR ADD DOCUMENT' , 16, 1); RETURN (1); END
	END
	ELSE
	IF @transfer_doc_type = 1 --Transfer
	BEGIN
		IF @iso = 'GEL'
		BEGIN
			SET @sender_bank_code = dbo.acc_get_bank_code(@depo_fill_acc_id)
			SELECT @sender_bank_name = DESCRIP FROM dbo.BANKS (NOLOCK) WHERE CODE9 = @sender_bank_code
			SET @sender_acc_name = dbo.acc_get_name(@depo_fill_acc_id)

			SET @sender_acc = dbo.acc_get_account(@depo_fill_acc_id)
			SELECT @sender_tax_code =  CASE WHEN ISNULL(C.TAX_INSP_CODE, '') <> '' THEN C.TAX_INSP_CODE ELSE C.PERSONAL_ID END FROM dbo.CLIENTS C(NOLOCK) WHERE C.CLIENT_NO = @client_no 
			
			SET @receiver_bank_code = dbo.acc_get_bank_code(@depo_acc_id)
			SELECT @receiver_bank_name = DESCRIP FROM dbo.BANKS (NOLOCK) WHERE CODE9 = @receiver_bank_code
			SET @receiver_acc_name = dbo.acc_get_name(@depo_acc_id)
			SET @receiver_acc = dbo.acc_get_account(@depo_acc_id)
			SELECT @receiver_tax_code =  CASE WHEN ISNULL(C.TAX_INSP_CODE, '') <> '' THEN C.TAX_INSP_CODE ELSE C.PERSONAL_ID END FROM dbo.CLIENTS C(NOLOCK) WHERE C.CLIENT_NO = @client_no 
		END
		ELSE
		BEGIN
			SET @sender_bank_code = dbo.acc_get_bank_code_bic(@depo_fill_acc_id)
			SELECT @sender_bank_name = DESCRIP FROM dbo.BIC_CODES (NOLOCK) WHERE BIC = @sender_bank_code
			SET @sender_acc_name = dbo.acc_get_name_lat(@depo_fill_acc_id)
			SET @sender_acc = dbo.acc_get_account(@depo_fill_acc_id)
			SELECT @sender_tax_code =  CASE WHEN ISNULL(C.TAX_INSP_CODE, '') <> '' THEN C.TAX_INSP_CODE ELSE C.PERSONAL_ID END FROM dbo.CLIENTS C(NOLOCK) WHERE C.CLIENT_NO = @client_no 
			
			SET @receiver_bank_code = dbo.acc_get_bank_code_bic(@depo_acc_id)
			SELECT @receiver_bank_name = DESCRIP FROM dbo.BIC_CODES (NOLOCK) WHERE BIC = @receiver_bank_code
			SET @receiver_acc_name = dbo.acc_get_name_lat(@depo_acc_id)
			SET @receiver_acc = dbo.acc_get_account(@depo_acc_id)
			SELECT @receiver_tax_code =  CASE WHEN ISNULL(C.TAX_INSP_CODE, '') <> '' THEN C.TAX_INSP_CODE ELSE C.PERSONAL_ID END FROM dbo.CLIENTS C(NOLOCK) WHERE C.CLIENT_NO = @client_no 
		END

		
		SET @op_code = '*DAA*'
		SET @doc_type = CASE @iso WHEN 'GEL' THEN 100 ELSE 110 END
		SET @descrip = 'ÃÄÐÏÆÉÔÆÄ ÈÀÍáÉÓ ÜÀÒÉÝáÅÀ (áÄËÛ. #' + @agreement_no + ')'

		EXEC @r = dbo.ADD_DOC4
			@rec_id = @doc_rec_id OUTPUT,
			@user_id = @user_id,
			@doc_type = @doc_type,
			@doc_date = @op_date,
			@debit_id = @depo_fill_acc_id,
			@credit_id = @depo_acc_id,
			@iso = @iso,
			@amount = @amount,
			@rec_state = @add_doc_rec_state,
			@descrip = @descrip,
			@op_code = @op_code,
			@account_extra = @depo_acc_id,
			@channel_id = 800,
			@flags = 0x15F4,

			@sender_bank_code = @sender_bank_code,
			@sender_acc = @sender_acc,
			@sender_tax_code = @sender_tax_code,
			@receiver_bank_code = @receiver_bank_code,
			@receiver_acc = @receiver_acc,
			@receiver_tax_code = @receiver_tax_code,
			@sender_bank_name = @sender_bank_name,
			@receiver_bank_name = @receiver_bank_name,
			@sender_acc_name = @sender_acc_name,
			@receiver_acc_name = @receiver_acc_name


		IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('ERROR ADD DOCUMENT' , 16, 1) RETURN (1) END
	END

	GOTO _end;
END

_end:
IF @internal_transaction=1 AND @@TRANCOUNT>0 
	COMMIT TRAN

RETURN (0)
GO
