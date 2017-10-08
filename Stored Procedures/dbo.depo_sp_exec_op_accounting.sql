SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[depo_sp_exec_op_accounting]
	@doc_rec_id int OUTPUT,
	@accrue_doc_rec_id int OUTPUT,
	@user_id int,
	@op_id int
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
	@rec_id int,
	@parent_rec_id int,
	@doc_rec_id_tmp1 int,
	@doc_rec_id_tmp2 int	

DECLARE
	@depo_id int,
	@op_date smalldatetime,
	@op_type smallint,
	@op_amount money, 
	@op_data xml,
	@op_acc_data xml,
	@op_owner int

SELECT @depo_id = DEPO_ID, @op_date = OP_DATE, @op_type = OP_TYPE, @op_amount = AMOUNT, @op_data = OP_DATA, @doc_rec_id = DOC_REC_ID, @accrue_doc_rec_id = ACCRUE_DOC_REC_ID, @op_owner = [OWNER]
FROM dbo.DEPO_OP (NOLOCK)
WHERE OP_ID = @op_id
IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR('<ERR>OPERATION NOT FOUND</ERR>', 16, 1); RETURN (1); END

IF @doc_rec_id IS NOT NULL
BEGIN
	SELECT @parent_rec_id = PARENT_REC_ID
	FROM dbo.OPS_0000 (NOLOCK)
	WHERE REC_ID = @doc_rec_id
	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR READING DOC DATA</ERR>', 16, 1); RETURN (1); END

	IF (ISNULL(@parent_rec_id, 0) > 0)
	BEGIN
		UPDATE dbo.OPS_0000 WITH (UPDLOCK)
		SET [UID] = [UID] + 1, FLAGS = 0x15F4
		WHERE REC_ID = @parent_rec_id
		IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR UPDATING CHILD DOC FLAG</ERR>', 16, 1); RETURN (1); END
	END	

	UPDATE dbo.OPS_0000 WITH (UPDLOCK)
	SET [UID] = [UID] + 1, FLAGS = 0x15F4
	WHERE REC_ID = @doc_rec_id
	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR UPDATING DOC FLAG</ERR>', 16, 1); RETURN (1); END
END


DECLARE
	@add_with_accounting bit,
	@doc_rec_state tinyint,
	@doc_type smallint,
	@doc_user_id int,
	@op_doc_rec_state tinyint,
	@op_doc_rec_state_cash tinyint

SELECT @add_with_accounting = ADD_WITH_ACCOUNTING, @op_doc_rec_state = DOC_REC_STATE, @op_doc_rec_state_cash = DOC_REC_STATE_CASH
FROM dbo.DEPO_OP_TYPES (NOLOCK)
WHERE [TYPE_ID] = @op_type
IF @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>OPERATION TYPE NOT FOUND</ERR>', 16, 1); RETURN (1); END

DECLARE
	@depo_holiday_close bit,
	@transfer_doc_type int,
	@depo_doc_user int

EXEC @r = dbo.GET_SETTING_INT 'DEPO_HOLIDAY_CLOSE', @depo_holiday_close OUTPUT
IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR REAGING SETTING</ERR>' , 16, 1); RETURN (1); END

EXEC @r = dbo.GET_SETTING_INT 'DEPO_TRANSFER_TYPE', @transfer_doc_type OUTPUT
IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR REAGING SETTING</ERR>' , 16, 1); RETURN (1); END

EXEC @r = dbo.GET_SETTING_INT 'DEPO_DOC_OWNER_TYPE', @depo_doc_user OUTPUT
IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR REAGING SETTING</ERR>' , 16, 1); RETURN (1); END

IF @depo_doc_user = 1 -- ÓÀÁÖÈÉÓ ÀÅÔÏÒÉ ÀÒÉÓ ÃÄÐÏÆÉÔÆÄ ÏÐÄÒÀÝÉÉÓ ÃÀÌÀÔÄÁÉÓ ÀÅÔÏÒÉ
	SET @doc_user_id = @op_owner
ELSE -- ÓÀÁÖÈÉÓ ÀÅÔÏÒÉ ÀÒÉÓ ÃÄÐÏÆÉÔÆÄ ÏÐÄÒÀÝÉÉÓ ÛÄÓÒÖËÄÁÉÓ ÀÅÔÏÒÉ	
	SET @doc_user_id = @user_id;

DECLARE
	@amount money,
	@dept_no int,
	@client_no int,
	@agreement_no varchar(150),
	@iso TISO,
	@depo_acc_id int,
	@depo_realize_acc_id int,
	@loss_acc_id int,
	@accrual_acc_id int,
	@interest_realize_acc_id int

DECLARE
	@doc_date smalldatetime,
	@op_code char(5),
	@descrip varchar(150),

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
	
DECLARE
	@skip_realize bit,
	@close_account bit,
	@account_date_close smalldatetime,
	@account_rec_state tinyint,
	@account_blocked_amount money
	
SELECT @dept_no = DEPT_NO, @client_no = CLIENT_NO, @agreement_no = AGREEMENT_NO, @iso = ISO, @depo_acc_id = DEPO_ACC_ID, @depo_realize_acc_id = DEPO_REALIZE_ACC_ID, @accrual_acc_id = ACCRUAL_ACC_ID, @loss_acc_id = LOSS_ACC_ID, @interest_realize_acc_id = INTEREST_REALIZE_ACC_ID
FROM dbo.DEPO_DEPOSITS (NOLOCK)
WHERE DEPO_ID = @depo_id
IF @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>DEPOSIT CONTRACT NOT FOUND</ERR>', 16, 1); RETURN (1); END

IF @op_type = dbo.depo_fn_const_op_active()
BEGIN
	IF @doc_rec_id IS NOT NULL
	BEGIN
		SELECT @doc_type = DOC_TYPE, @doc_rec_state = REC_STATE
		FROM dbo.OPS_0000 (NOLOCK)
		WHERE REC_ID = @doc_rec_id
		IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR READING DOC DATA</ERR>', 16, 1); RETURN (1); END

		IF @doc_rec_state IS NOT NULL
		BEGIN
			IF @doc_type = 120 --Cash Order
				SET @op_doc_rec_state = @op_doc_rec_state_cash

			IF @doc_rec_state < @op_doc_rec_state
			BEGIN
				EXEC @r = dbo.CHANGE_DOC_STATE
					@rec_id = @doc_rec_id,
					@user_id = @user_id,
					@new_rec_state = @op_doc_rec_state
				IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ÛÄÝÃÏÌÀ ÏÐÄÒÀÝÉÀÓÈÀÍ ÃÀÊÀÅÛÉÒÄÁÖËÉ ÓÀÁÖÈÄÁÉÓ ÀÅÔÏÒÉÆÀÝÉÉÓÀÓ</ERR>', 16, 1); RETURN (1); END
			END
		END
	END
	
	SET @doc_rec_id = NULL
	SET @accrue_doc_rec_id = NULL
END
ELSE
IF @op_type = dbo.depo_fn_const_op_accumulate()
BEGIN
	IF @doc_rec_id IS NOT NULL
	BEGIN
		SELECT @doc_type = DOC_TYPE, @doc_rec_state = REC_STATE
		FROM dbo.OPS_0000 (NOLOCK)
		WHERE REC_ID = @doc_rec_id
		IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR READING DOC DATA</ERR>', 16, 1); RETURN (1); END

		IF @doc_rec_state IS NOT NULL
		BEGIN
			IF @doc_type = 120 --Cash Order
				SET @op_doc_rec_state = @op_doc_rec_state_cash

			IF @doc_rec_state < @op_doc_rec_state
			BEGIN
				EXEC @r = dbo.CHANGE_DOC_STATE
					@rec_id = @doc_rec_id,
					@user_id = @user_id,
					@new_rec_state = @op_doc_rec_state
				IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ÛÄÝÃÏÌÀ ÏÐÄÒÀÝÉÀÓÈÀÍ ÃÀÊÀÅÛÉÒÄÁÖËÉ ÓÀÁÖÈÄÁÉÓ ÀÅÔÏÒÉÆÀÝÉÉÓÀÓ</ERR>', 16, 1); RETURN (1); END
			END
		END
	END
	
	SET @doc_rec_id = NULL
	SET @accrue_doc_rec_id = NULL
END
ELSE
IF @op_type = dbo.depo_fn_const_op_realize_interest()
BEGIN
	SET @doc_rec_id = NULL
	SET @accrue_doc_rec_id = NULL
END
ELSE
IF @op_type = dbo.depo_fn_const_op_withdraw()
BEGIN
	IF @doc_rec_id IS NOT NULL 
	BEGIN
		SELECT @doc_type = DOC_TYPE, @doc_rec_state = REC_STATE
		FROM dbo.OPS_0000 (NOLOCK)
		WHERE REC_ID = @doc_rec_id
		IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR READING DOC DATA</ERR>', 16, 1); RETURN (1); END
		
		IF @doc_rec_state IS NOT NULL
		BEGIN
			SET @doc_rec_id = NULL
			SET @accrue_doc_rec_id = NULL			
		END
	END
	ELSE
	BEGIN
		SELECT @depo_realize_acc_id = DEPO_REALIZE_ACC_ID
		FROM dbo.DEPO_VW_OP_DATA_WITHDRAW
		WHERE OP_ID = @op_id
		IF @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>OPERATION DATA NOT FOUND</ERR>', 16, 1); RETURN (1); END 

		SELECT @transfer_doc_type = CASE WHEN ACC_TYPE & 0x02 = 0x02 THEN -1 ELSE @transfer_doc_type END
		FROM dbo.ACCOUNTS (NOLOCK)
		WHERE ACC_ID = @depo_realize_acc_id

		IF @depo_holiday_close = 1
			SET @doc_date = dbo.date_next_workday(@op_date)
		ELSE
			SET @doc_date = @op_date

		IF @transfer_doc_type = -1 --Cash Order
		BEGIN
			SELECT @first_name = FIRST_NAME, @last_name = LAST_NAME, @fathers_name = FATHERS_NAME, @birth_date = BIRTH_DATE, @birth_place = BIRTH_PLACE, 
				@country = COUNTRY, @passport_type_id = PASSPORT_TYPE_ID, @passport = PASSPORT, @personal_id = PERSONAL_ID, @reg_organ = PASSPORT_REG_ORGAN,
				@passport_issue_dt = PASSPORT_ISSUE_DT, @passport_end_date = PASSPORT_END_DATE
			FROM dbo.CLIENTS (NOLOCK)
			WHERE CLIENT_NO = @client_no

			SET @address_jur = dbo.cli_get_cli_attribute(@client_no, '$ADDRESS_LEGAL')
			SET @address_lat = dbo.cli_get_cli_attribute(@client_no, '$ADDRESS_LAT')

			SET @op_code = CASE @iso WHEN 'GEL' THEN '44' ELSE '62' END
			SET @doc_type = 130
			SET @descrip = 'ÀÍÀÁÒÉÃÀÍ ÈÀÍáÉÓ ÂÀÔÀÍÀ (áÄËÛ. #' + @agreement_no + ')'

			EXEC @r = dbo.ADD_DOC4
				@rec_id = @doc_rec_id OUTPUT,
				@user_id = @doc_user_id,
				@doc_type = @doc_type, 
				@doc_date = @op_date,
				@debit_id = @depo_acc_id,
				@credit_id = @depo_realize_acc_id,
				@iso = @iso, 
				@amount = @op_amount,
				@rec_state = @op_doc_rec_state_cash,
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

			IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR ADD DOCUMENT</ERR>' , 16, 1); RETURN (1); END
		END
		ELSE
		IF @transfer_doc_type = 0 --Memorial Order
		BEGIN
			SET @op_code = '*DCA*'
			SET @doc_type = 98
			SET @descrip = 'ÀÍÀÁÒÉÃÀÍ ÈÀÍáÉÓ ÂÀÔÀÍÀ (áÄËÛ. #' + @agreement_no + ')'

			EXEC @r = dbo.ADD_DOC4
				@rec_id = @doc_rec_id OUTPUT,
				@user_id = @doc_user_id,
				@doc_type = @doc_type,
				@doc_date = @op_date,
				@doc_date_in_doc = @doc_date,
				@debit_id = @depo_acc_id,
				@credit_id = @depo_realize_acc_id,
				@iso = @iso,
				@amount = @op_amount,
				@rec_state = @op_doc_rec_state,
				@descrip = @descrip,
				@op_code = @op_code,
				@account_extra = @depo_acc_id,
				@channel_id = 800,
				@flags = 0x15F4

			IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR ADD DOCUMENT</ERR>' , 16, 1); RETURN (1); END
		END
		ELSE
		IF @transfer_doc_type = 1 --Transfer
		BEGIN
			IF @iso = 'GEL'
			BEGIN
				SET @sender_bank_code = dbo.acc_get_bank_code(@depo_acc_id)
				SELECT @sender_bank_name = DESCRIP FROM dbo.BANKS (NOLOCK) WHERE CODE9 = @sender_bank_code
				SET @sender_acc_name = dbo.acc_get_name(@depo_acc_id)
				SET @sender_acc = dbo.acc_get_account(@depo_acc_id)
				SELECT @sender_tax_code =  CASE WHEN ISNULL(C.TAX_INSP_CODE, '') <> '' THEN C.TAX_INSP_CODE ELSE C.PERSONAL_ID END FROM dbo.CLIENTS C(NOLOCK) WHERE C.CLIENT_NO = @client_no 
				
				SET @receiver_bank_code = dbo.acc_get_bank_code(@depo_realize_acc_id)
				SELECT @receiver_bank_name = DESCRIP FROM dbo.BANKS (NOLOCK) WHERE CODE9 = @receiver_bank_code
				SET @receiver_acc_name = dbo.acc_get_name(@depo_realize_acc_id)
				SET @receiver_acc = dbo.acc_get_account(@depo_realize_acc_id)
				SELECT @receiver_tax_code =  CASE WHEN ISNULL(C.TAX_INSP_CODE, '') <> '' THEN C.TAX_INSP_CODE ELSE C.PERSONAL_ID END FROM dbo.CLIENTS C(NOLOCK) WHERE C.CLIENT_NO = @client_no 
			END
			ELSE
			BEGIN
				SET @sender_bank_code = dbo.acc_get_bank_code_bic(@depo_acc_id)
				SELECT @sender_bank_name = DESCRIP FROM dbo.BIC_CODES (NOLOCK) WHERE BIC = @sender_bank_code
				SET @sender_acc_name = dbo.acc_get_name_lat(@depo_acc_id)
				SET @sender_acc = dbo.acc_get_account(@depo_acc_id)
				SELECT @sender_tax_code =  CASE WHEN ISNULL(C.TAX_INSP_CODE, '') <> '' THEN C.TAX_INSP_CODE ELSE C.PERSONAL_ID END FROM dbo.CLIENTS C(NOLOCK) WHERE C.CLIENT_NO = @client_no 
				
				SET @receiver_bank_code = dbo.acc_get_bank_code_bic(@depo_realize_acc_id)
				SELECT @receiver_bank_name = DESCRIP FROM dbo.BIC_CODES (NOLOCK) WHERE BIC = @receiver_bank_code
				SET @receiver_acc_name = dbo.acc_get_name_lat(@depo_realize_acc_id)
				SET @receiver_acc = dbo.acc_get_account(@depo_realize_acc_id)
				SELECT @receiver_tax_code =  CASE WHEN ISNULL(C.TAX_INSP_CODE, '') <> '' THEN C.TAX_INSP_CODE ELSE C.PERSONAL_ID END FROM dbo.CLIENTS C(NOLOCK) WHERE C.CLIENT_NO = @client_no 
			END

			SET @op_code = '*DCA*'
			SET @doc_type = CASE @iso WHEN 'GEL' THEN 100 ELSE 110 END
			SET @descrip = 'ÀÍÀÁÒÉÃÀÍ ÈÀÍáÉÓ ÂÀÔÀÍÀ (áÄËÛ. #' + @agreement_no + ')'

			EXEC @r = dbo.ADD_DOC4
				@rec_id = @doc_rec_id OUTPUT,
				@user_id = @doc_user_id,
				@doc_type = @doc_type,
				@doc_date = @op_date,
				@doc_date_in_doc = @doc_date,
				@debit_id = @depo_acc_id,
				@credit_id = @depo_realize_acc_id,
				@iso = @iso,
				@amount = @op_amount,
				@rec_state = @op_doc_rec_state,
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
				@receiver_acc_name = @receiver_acc_name,
				@rec_date = @op_date

			IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR ADD DOCUMENT</ERR>' , 16, 1) RETURN (1) END
		END
	END
END
ELSE
IF @op_type = dbo.depo_fn_const_op_withdraw_schedule()
BEGIN
	DECLARE 
		@withdraw_depo_amount money

	IF @doc_rec_id IS NOT NULL 
	BEGIN
		SELECT @doc_type = DOC_TYPE, @doc_rec_state = REC_STATE
		FROM dbo.OPS_0000 (NOLOCK)
		WHERE REC_ID = @doc_rec_id
		IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR READING DOC DATA</ERR>', 16, 1); RETURN (1); END
		
		IF @doc_rec_state IS NOT NULL
		BEGIN
			SET @doc_rec_id = NULL
			SET @accrue_doc_rec_id = NULL			
		END
	END
	ELSE
	BEGIN		
		SELECT @depo_realize_acc_id = DEPO_REALIZE_ACC_ID, @withdraw_depo_amount = DEPO_AMOUNT
		FROM dbo.DEPO_VW_OP_DATA_WITHDRAW_SCHEDULE
		WHERE OP_ID = @op_id
		IF @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>OPERATION DATA NOT FOUND</ERR>', 16, 1); RETURN (1); END 

		SELECT @transfer_doc_type = CASE WHEN ACC_TYPE & 0x02 = 0x02 THEN -1 ELSE @transfer_doc_type END
		FROM dbo.ACCOUNTS (NOLOCK)
		WHERE ACC_ID = @depo_realize_acc_id

		IF @transfer_doc_type = -1 --Cash Order
		BEGIN
			SELECT @first_name = FIRST_NAME, @last_name = LAST_NAME, @fathers_name = FATHERS_NAME, @birth_date = BIRTH_DATE, @birth_place = BIRTH_PLACE, 
				@country = COUNTRY, @passport_type_id = PASSPORT_TYPE_ID, @passport = PASSPORT, @personal_id = PERSONAL_ID, @reg_organ = PASSPORT_REG_ORGAN,
				@passport_issue_dt = PASSPORT_ISSUE_DT, @passport_end_date = PASSPORT_END_DATE
			FROM dbo.CLIENTS (NOLOCK)
			WHERE CLIENT_NO = @client_no

			SET @address_jur = dbo.cli_get_cli_attribute(@client_no, '$ADDRESS_LEGAL')
			SET @address_lat = dbo.cli_get_cli_attribute(@client_no, '$ADDRESS_LAT')

			SET @op_code = CASE @iso WHEN 'GEL' THEN '44' ELSE '62' END
			SET @doc_type = 130
			SET @descrip = 'ÃÀÂÄÂÌÉËÉ ÈÀÍáÉÓ ÂÀÔÀÍÀ ÀÍÀÁÒÉÃÀÍ (áÄËÛ. #' + @agreement_no + ')'

			EXEC @r = dbo.ADD_DOC4
				@rec_id = @doc_rec_id OUTPUT,
				@user_id = @doc_user_id,
				@doc_type = @doc_type, 
				@doc_date = @op_date,
				@debit_id = @depo_acc_id,
				@credit_id = @depo_realize_acc_id,
				@iso = @iso, 
				@amount = @withdraw_depo_amount,
				@rec_state = @op_doc_rec_state_cash,
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

			IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR ADD DOCUMENT</ERR>' , 16, 1); RETURN (1); END
		END
		ELSE
		IF @transfer_doc_type = 0 --Memorial Order
		BEGIN
			SET @op_code = '*DCA*'
			SET @doc_type = 98
			SET @descrip = 'ÃÀÂÄÂÌÉËÉ ÈÀÍáÉÓ ÂÀÔÀÍÀ ÀÍÀÁÒÉÃÀÍ (áÄËÛ. #' + @agreement_no + ')'

			EXEC @r = dbo.ADD_DOC4
				@rec_id = @doc_rec_id OUTPUT,
				@user_id = @doc_user_id,
				@doc_type = @doc_type,
				@doc_date = @op_date,
				@debit_id = @depo_acc_id,
				@credit_id = @depo_realize_acc_id,
				@iso = @iso,
				@amount = @withdraw_depo_amount,
				@rec_state = @op_doc_rec_state,
				@descrip = @descrip,
				@op_code = @op_code,
				@account_extra = @depo_acc_id,
				@channel_id = 800,
				@flags = 0x15F4

			IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR ADD DOCUMENT</ERR>' , 16, 1); RETURN (1); END
		END
		ELSE
		IF @transfer_doc_type = 1 --Transfer
		BEGIN
			IF @iso = 'GEL'
			BEGIN
				SET @sender_bank_code = dbo.acc_get_bank_code(@depo_acc_id)
				SELECT @sender_bank_name = DESCRIP FROM dbo.BANKS (NOLOCK) WHERE CODE9 = @sender_bank_code
				SET @sender_acc_name = dbo.acc_get_name(@depo_acc_id)
				SET @sender_acc = dbo.acc_get_account(@depo_acc_id)
				SELECT @sender_tax_code =  CASE WHEN ISNULL(C.TAX_INSP_CODE, '') <> '' THEN C.TAX_INSP_CODE ELSE C.PERSONAL_ID END FROM dbo.CLIENTS C(NOLOCK) WHERE C.CLIENT_NO = @client_no 
				
				SET @receiver_bank_code = dbo.acc_get_bank_code(@depo_realize_acc_id)
				SELECT @receiver_bank_name = DESCRIP FROM dbo.BANKS (NOLOCK) WHERE CODE9 = @receiver_bank_code
				SET @receiver_acc_name = dbo.acc_get_name(@depo_realize_acc_id)
				SET @receiver_acc = dbo.acc_get_account(@depo_realize_acc_id)
				SELECT @receiver_tax_code =  CASE WHEN ISNULL(C.TAX_INSP_CODE, '') <> '' THEN C.TAX_INSP_CODE ELSE C.PERSONAL_ID END FROM dbo.CLIENTS C(NOLOCK) WHERE C.CLIENT_NO = @client_no 
			END
			ELSE
			BEGIN
				SET @sender_bank_code = dbo.acc_get_bank_code_bic(@depo_acc_id)
				SELECT @sender_bank_name = DESCRIP FROM dbo.BIC_CODES (NOLOCK) WHERE BIC = @sender_bank_code
				SET @sender_acc_name = dbo.acc_get_name_lat(@depo_acc_id)
				SET @sender_acc = dbo.acc_get_account(@depo_acc_id)
				SELECT @sender_tax_code =  CASE WHEN ISNULL(C.TAX_INSP_CODE, '') <> '' THEN C.TAX_INSP_CODE ELSE C.PERSONAL_ID END FROM dbo.CLIENTS C(NOLOCK) WHERE C.CLIENT_NO = @client_no 
				
				SET @receiver_bank_code = dbo.acc_get_bank_code_bic(@depo_realize_acc_id)
				SELECT @receiver_bank_name = DESCRIP FROM dbo.BIC_CODES (NOLOCK) WHERE BIC = @receiver_bank_code
				SET @receiver_acc_name = dbo.acc_get_name_lat(@depo_realize_acc_id)
				SET @receiver_acc = dbo.acc_get_account(@depo_realize_acc_id)
				SELECT @receiver_tax_code =  CASE WHEN ISNULL(C.TAX_INSP_CODE, '') <> '' THEN C.TAX_INSP_CODE ELSE C.PERSONAL_ID END FROM dbo.CLIENTS C(NOLOCK) WHERE C.CLIENT_NO = @client_no 
			END

			SET @op_code = '*DCA*'
			SET @doc_type = CASE @iso WHEN 'GEL' THEN 100 ELSE 110 END
			SET @descrip = 'ÃÀÂÄÂÌÉËÉ ÈÀÍáÉÓ ÂÀÔÀÍÀ ÀÍÀÁÒÉÃÀÍ (áÄËÛ. #' + @agreement_no + ')'

			EXEC @r = dbo.ADD_DOC4
				@rec_id = @doc_rec_id OUTPUT,
				@user_id = @doc_user_id,
				@doc_type = @doc_type,
				@doc_date = @op_date,
				@debit_id = @depo_acc_id,
				@credit_id = @depo_realize_acc_id,
				@iso = @iso,
				@amount = @withdraw_depo_amount,
				@rec_state = @op_doc_rec_state,
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
				@receiver_acc_name = @receiver_acc_name,
				@rec_date = @op_date

			IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR ADD DOCUMENT</ERR>' , 16, 1) RETURN (1) END
		END
	END
END
ELSE
IF @op_type = dbo.depo_fn_const_op_withdraw_interest_tax()
BEGIN
	SET @doc_rec_id = NULL
	SET @accrue_doc_rec_id = NULL
END
ELSE
IF @op_type = dbo.depo_fn_const_op_renew()
BEGIN
	DECLARE
		@renew_capitalized bit,
		@interest_amount money

	SELECT  @renew_capitalized = RENEW_CAPITALIZED,
			@interest_amount = INTEREST_TAX_AMOUNT
	FROM dbo.DEPO_VW_OP_DATA_RENEW
	WHERE OP_ID = @op_id
	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR('<ERR>ERROR OP DATA NOT FOUND!</ERR>', 16, 1); RETURN (1); END
		
	IF @renew_capitalized = 1 AND @depo_acc_id <> @interest_realize_acc_id  
	BEGIN

		IF @transfer_doc_type = 0 --Memorial Order
		BEGIN
			SET @op_code = '*DAA*'
			SET @doc_type = 98
			SET @descrip = 'ÀÍÀÁÒÉÓ ÂÀÍÀáËÄÁÉÓÀÓ ÃÀÒÉÝáÖËÉ ÓÀÒÂÄÁËÉÓ ÂÀÃÀÔÀÍÀ (áÄËÛ. #' + @agreement_no + ')'

			EXEC @r = dbo.ADD_DOC4
				@rec_id = @doc_rec_id OUTPUT,
				@user_id = @doc_user_id,
				@doc_type = @doc_type,
				@doc_date = @op_date,
				@debit_id = @interest_realize_acc_id,
				@credit_id = @depo_acc_id,
				@iso = @iso,
				@amount = @interest_amount,
				@rec_state = 20,
				@descrip = @descrip,
				@op_code = @op_code,
				@account_extra = @depo_acc_id,
				@channel_id = 800,
				@flags = 0x15F4,
				@parent_rec_id = @parent_rec_id

			IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR ADD DOCUMENT</ERR>' , 16, 1); RETURN (1); END
		END
		ELSE
		IF @transfer_doc_type = 1 --Transfer
		BEGIN
			IF @iso = 'GEL'
			BEGIN
				SET @sender_bank_code = dbo.acc_get_bank_code(@interest_realize_acc_id)
				SELECT @sender_bank_name = DESCRIP FROM dbo.BANKS (NOLOCK) WHERE CODE9 = @sender_bank_code
				SET @sender_acc_name = dbo.acc_get_name(@interest_realize_acc_id)
				SET @sender_acc = dbo.acc_get_account(@interest_realize_acc_id)
				SELECT @sender_tax_code =  CASE WHEN ISNULL(C.TAX_INSP_CODE, '') <> '' THEN C.TAX_INSP_CODE ELSE C.PERSONAL_ID END FROM dbo.CLIENTS C(NOLOCK) WHERE C.CLIENT_NO = @client_no 
				
				SET @receiver_bank_code = dbo.acc_get_bank_code(@depo_acc_id)
				SELECT @receiver_bank_name = DESCRIP FROM dbo.BANKS (NOLOCK) WHERE CODE9 = @receiver_bank_code
				SET @receiver_acc_name = dbo.acc_get_name(@depo_acc_id)
				SET @receiver_acc = dbo.acc_get_account(@depo_acc_id)
				SELECT @receiver_tax_code =  CASE WHEN ISNULL(C.TAX_INSP_CODE, '') <> '' THEN C.TAX_INSP_CODE ELSE C.PERSONAL_ID END FROM dbo.CLIENTS C(NOLOCK) WHERE C.CLIENT_NO = @client_no 
			END
			ELSE
			BEGIN
				SET @sender_bank_code = dbo.acc_get_bank_code_bic(@depo_realize_acc_id)
				SELECT @sender_bank_name = DESCRIP FROM dbo.BIC_CODES (NOLOCK) WHERE BIC = @sender_bank_code
				SET @sender_acc_name = dbo.acc_get_name_lat(@depo_realize_acc_id)
				SET @sender_acc = dbo.acc_get_account(@depo_realize_acc_id)
				SELECT @sender_tax_code =  CASE WHEN ISNULL(C.TAX_INSP_CODE, '') <> '' THEN C.TAX_INSP_CODE ELSE C.PERSONAL_ID END FROM dbo.CLIENTS C(NOLOCK) WHERE C.CLIENT_NO = @client_no 
				
				SET @receiver_bank_code = dbo.acc_get_bank_code_bic(@depo_acc_id)
				SELECT @receiver_bank_name = DESCRIP FROM dbo.BIC_CODES (NOLOCK) WHERE BIC = @receiver_bank_code
				SET @receiver_acc_name = dbo.acc_get_name_lat(@depo_acc_id)
				SET @receiver_acc = dbo.acc_get_account(@depo_acc_id)
				SELECT @receiver_tax_code =  CASE WHEN ISNULL(C.TAX_INSP_CODE, '') <> '' THEN C.TAX_INSP_CODE ELSE C.PERSONAL_ID END FROM dbo.CLIENTS C(NOLOCK) WHERE C.CLIENT_NO = @client_no 
			END

			
			SET @op_code = '*DAA*'
			SET @doc_type = CASE @iso WHEN 'GEL' THEN 100 ELSE 110 END
			SET @descrip = 'ÀÍÀÁÒÉÓ ÂÀÍÀáËÄÁÉÓÀÓ ÃÀÒÉÝáÖËÉ ÓÀÒÂÄÁËÉÓ ÂÀÃÀÔÀÍÀ (áÄËÛ. #' + @agreement_no + ')'

			EXEC @r = dbo.ADD_DOC4
				@rec_id = @doc_rec_id OUTPUT,
				@user_id = @doc_user_id,
				@doc_type = @doc_type,
				@doc_date = @op_date,
				@debit_id = @interest_realize_acc_id,
				@credit_id = @depo_acc_id,
				@iso = @iso,
				@amount = @interest_amount,
				@rec_state = 20,
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
				@receiver_acc_name = @receiver_acc_name,
				@rec_date = @op_date

			IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR ADD DOCUMENT</ERR>' , 16, 1) RETURN (1) END
		END
	END
END
ELSE
IF @op_type = dbo.depo_fn_const_op_convert()
BEGIN
	DECLARE
		@old_depo_acc_id int,
		@new_depo_acc_id int
	DECLARE
		@iso_d char(3),
		@amount_c money,
		@amount_d money,
		@acc_id_c int,
		@acc_id_d int

	SELECT @iso_d = ISO, @amount_d = AMOUNT, @acc_id_d = DEPO_ACC_ID
	FROM dbo.DEPO_VW_OP_ACC_DATA_CONVERT
	WHERE OP_ID = @op_id
	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR OP DATA NOT FOUND!</ERR>', 16, 1); RETURN (1); END

	SET @old_depo_acc_id = @acc_id_d
	SET @new_depo_acc_id = @depo_acc_id

	SET @descrip = 'ÀÍÀÁÒÉÓ ÊÏÍÅÄÒÔÀÝÉÀ (áÄËÛ. #' + @agreement_no + ')'

	EXEC @r = dbo.ADD_CONV_DOC4
		@rec_id_1 = @doc_rec_id OUTPUT,
		@rec_id_2 = @doc_rec_id_tmp1 OUTPUT,
		@user_id = @user_id,
		@doc_num = NULL,
		@doc_date = @op_date,
		@iso_d = @iso_d,              
		@iso_c = @iso,              
		@amount_d = @amount_d,          
		@amount_c = @op_amount,
		@debit_id = @acc_id_d,
		@credit_id = @depo_acc_id,
		@account_extra = @depo_acc_id,
		@descrip1 = @descrip,   
		@descrip2 = @descrip,   
		@rec_state = @op_doc_rec_state,
		@channel_id = 800,
		@flags = 0x15F4,

		@check_saldo = 1,
		@add_tariff = 0,
		@info = 0
	IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR ADD DOCUMENT</ERR>',16,1); RETURN (1); END

	SELECT @amount_d = ACCRUE_AMOUNT, @amount_c = ACCRUE_AMOUNT_EQU, @acc_id_d = ACCRUAL_ACC_ID
	FROM dbo.DEPO_VW_OP_ACC_DATA_CONVERT
	WHERE OP_ID = @op_id
	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR OP DATA NOT FOUND!</ERR>', 16, 1); RETURN (1); END

	IF (ISNULL(@amount_d, $0.00) > $0.00) AND (ISNULL(@amount_c, $0.00) > $0.00)
	BEGIN
		SET @descrip = 'ÃÀÒÉÝáÖËÉ ÓÀÒÂÄÁËÉÓ ÊÏÍÅÄÒÔÀÝÉÀ (áÄËÛ. #' + @agreement_no + ')'

		EXEC @r = dbo.ADD_CONV_DOC4
			@rec_id_1 = @doc_rec_id_tmp1 OUTPUT,
			@rec_id_2 = @doc_rec_id_tmp2 OUTPUT,
			@user_id = @user_id,
			@doc_num = NULL,
			@doc_date = @op_date,
			@iso_d = @iso_d,              
			@iso_c = @iso,              
			@amount_d = @amount_d,          
			@amount_c = @amount_c,
			@debit_id = @acc_id_d,
			@credit_id = @accrual_acc_id,
			@account_extra = @depo_acc_id,
			@descrip1 = @descrip,   
			@descrip2 = @descrip,   
			@rec_state = @op_doc_rec_state,
			@channel_id = 800,
			@flags = 0x15F4,
			@par_rec_id = @doc_rec_id,

			@check_saldo = 1,
			@add_tariff = 0,
			@info = 0

		IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR ADD DOCUMENT</ERR>',16,1); RETURN (1); END
	END

	UPDATE dbo.ACCOUNTS_CRED_PERC
	SET CALC_AMOUNT = NULL,
		TOTAL_CALC_AMOUNT = NULL,
		MIN_PROCESSING_DATE = @op_date,
		MIN_PROCESSING_TOTAL_CALC_AMOUNT = NULL
	WHERE ACC_ID = @old_depo_acc_id
	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR UPDATE CRED PERC DATA OLD</ERR>',16,1); RETURN (1); END

	UPDATE dbo.ACCOUNTS_CRED_PERC
	SET CALC_AMOUNT = @amount_c,
		TOTAL_CALC_AMOUNT = @amount_c,
		LAST_CALC_DATE = @op_date,
		MIN_PROCESSING_DATE = @op_date,
		MIN_PROCESSING_TOTAL_CALC_AMOUNT = NULL
	WHERE ACC_ID = @new_depo_acc_id
	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR UPDATE CRED PERC DATA NEW</ERR>',16,1); RETURN (1); END

END
ELSE
IF @op_type IN (dbo.depo_fn_const_op_annulment(), dbo.depo_fn_const_op_annulment_amount(), dbo.depo_fn_const_op_close_default())
BEGIN
	DECLARE
		@depo_realize_interest money -- is TOTAL_PAYED_AMOUNT		
		
	DECLARE
		@debit_id int,
		@credit_id int		
		
	IF @op_type = dbo.depo_fn_const_op_annulment()
		SELECT @amount = DEPO_REALIZE_AMOUNT, @depo_realize_interest = ISNULL(DEPO_REALIZE_INTEREST, 2),
			@depo_realize_acc_id = DEPO_REALIZE_ACC_ID, @interest_realize_acc_id = INTEREST_REALIZE_ACC_ID
		FROM dbo.DEPO_VW_OP_DATA_ANNULMENT (NOLOCK)
		WHERE OP_ID = @op_id
	ELSE
	IF @op_type = dbo.depo_fn_const_op_annulment_amount()
		SELECT @amount = DEPO_REALIZE_AMOUNT, @depo_realize_interest = ISNULL(DEPO_REALIZE_INTEREST, 2),
			@depo_realize_acc_id = DEPO_REALIZE_ACC_ID, @interest_realize_acc_id = INTEREST_REALIZE_ACC_ID
		FROM dbo.DEPO_VW_OP_DATA_ANNULMENT_AMOUNT (NOLOCK)
		WHERE OP_ID = @op_id
	ELSE
	IF @op_type = dbo.depo_fn_const_op_close_default()
		SELECT @amount = DEPO_REALIZE_AMOUNT, @depo_realize_interest = ISNULL(DEPO_REALIZE_INTEREST, 2),
			@depo_realize_acc_id = DEPO_REALIZE_ACC_ID, @interest_realize_acc_id = INTEREST_REALIZE_ACC_ID
		FROM dbo.DEPO_VW_OP_DATA_CLOSE_DEFAULT (NOLOCK)
		WHERE OP_ID = @op_id

	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR OP DATA NOT FOUND!</ERR>', 16, 1); RETURN (1); END	
	
	SET @op_amount = ISNULL(@op_amount, $0.00)
	
	SET @close_account = 0
	SET @skip_realize = 1

	SELECT @account_rec_state = REC_STATE, @account_date_close = DATE_CLOSE, @account_blocked_amount = ISNULL(BLOCKED_AMOUNT, $0.00)
	FROM dbo.ACCOUNTS (NOLOCK)
	WHERE ACC_ID = @depo_acc_id
	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR DEPOSIT ACCOUNT DATA</ERR>', 16, 1); RETURN (1); END

	IF (ISNULL(@depo_realize_acc_id, @depo_acc_id) = @depo_acc_id) OR
	  (ISNULL(@amount, $0.00) <= $0.00) GOTO _skip_realize_annulment_amount
		
	/*IF @account_blocked_amount <> $0.00
		GOTO _skip_realize_annulment_amount*/
	
	IF @depo_holiday_close = 1
		SET @doc_date = dbo.date_next_workday(@op_date)
	ELSE
		SET @doc_date = @op_date
	
	IF @transfer_doc_type = 0 --Memorial Order
	BEGIN
		SET @op_code = '*DCA*'
		SET @descrip = 'ÈÀÍáÉÓ ÂÀÃÀÔÀÍÀ ÌÉÌÃÉÀÍÒÄ ÀÍÂÀÒÉÛÆÄ ÓÀÀÍÀÁÒÄ áÄËÛÄÊÒÖËÄÁÉÓ ÃÀÒÙÅÄÅÉÓ ÂÀÌÏ (áÄËÛ. #' + @agreement_no + ')'

		EXEC @r = dbo.ADD_DOC4
			@rec_id = @doc_rec_id OUTPUT,
			@user_id = @doc_user_id,
			@doc_type = 98,
			@doc_date = @doc_date,
			@doc_date_in_doc = @op_date,
			@debit_id = @depo_acc_id,
			@credit_id = @depo_realize_acc_id,
			@iso = @iso,
			@amount = @amount,
			@rec_state = @op_doc_rec_state,
			@descrip = @descrip,
			@op_code = @op_code,
			@account_extra = @depo_acc_id,
			@parent_rec_id = @parent_rec_id,
			@channel_id = 800,
			@flags = 0x15F4

		IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR ADD DOCUMENT</ERR>',16,1); RETURN (1); END
	END
	ELSE
	IF @transfer_doc_type = 1 --Transfer
	BEGIN
		IF @iso = 'GEL'
		BEGIN
			SET @sender_bank_code = dbo.acc_get_bank_code(@depo_acc_id)
			SELECT @sender_bank_name = DESCRIP FROM dbo.BANKS (NOLOCK) WHERE CODE9 = @sender_bank_code
			SET @sender_acc_name = dbo.acc_get_name(@depo_acc_id)
			SET @sender_acc = dbo.acc_get_account(@depo_acc_id)
			SELECT @sender_tax_code =  CASE WHEN ISNULL(C.TAX_INSP_CODE, '') <> '' THEN C.TAX_INSP_CODE ELSE C.PERSONAL_ID END FROM dbo.CLIENTS C(NOLOCK) WHERE C.CLIENT_NO = @client_no 
			
			SET @receiver_bank_code = dbo.acc_get_bank_code(@depo_realize_acc_id)
			SELECT @receiver_bank_name = DESCRIP FROM dbo.BANKS (NOLOCK) WHERE CODE9 = @receiver_bank_code
			SET @receiver_acc_name = dbo.acc_get_name(@depo_realize_acc_id)
			SET @receiver_acc = dbo.acc_get_account(@depo_realize_acc_id)
			SELECT @receiver_tax_code =  CASE WHEN ISNULL(C.TAX_INSP_CODE, '') <> '' THEN C.TAX_INSP_CODE ELSE C.PERSONAL_ID END FROM dbo.CLIENTS C(NOLOCK) WHERE C.CLIENT_NO = @client_no 
		END
		ELSE
		BEGIN
			SET @sender_bank_code = dbo.acc_get_bank_code_bic(@depo_acc_id)
			SELECT @sender_bank_name = DESCRIP FROM dbo.BIC_CODES (NOLOCK) WHERE BIC = @sender_bank_code
			SET @sender_acc_name = dbo.acc_get_name_lat(@depo_acc_id)
			SET @sender_acc = dbo.acc_get_account(@depo_acc_id)
			SELECT @sender_tax_code =  CASE WHEN ISNULL(C.TAX_INSP_CODE, '') <> '' THEN C.TAX_INSP_CODE ELSE C.PERSONAL_ID END FROM dbo.CLIENTS C(NOLOCK) WHERE C.CLIENT_NO = @client_no 
			
			SET @receiver_bank_code = dbo.acc_get_bank_code_bic(@depo_realize_acc_id)
			SELECT @receiver_bank_name = DESCRIP FROM dbo.BIC_CODES (NOLOCK) WHERE BIC = @receiver_bank_code
			SET @receiver_acc_name = dbo.acc_get_name_lat(@depo_realize_acc_id)
			SET @receiver_acc = dbo.acc_get_account(@depo_realize_acc_id)
			SELECT @receiver_tax_code =  CASE WHEN ISNULL(C.TAX_INSP_CODE, '') <> '' THEN C.TAX_INSP_CODE ELSE C.PERSONAL_ID END FROM dbo.CLIENTS C(NOLOCK) WHERE C.CLIENT_NO = @client_no 
		END

		SET @op_code = '*DCA*'
		SET @doc_type = CASE @iso WHEN 'GEL' THEN 100 ELSE 110 END
		SET @descrip = 'ÈÀÍáÉÓ ÜÀÒÉÝáÅÀ ÌÉÌÃÉÀÍÒÄ ÀÍÂÀÒÉÛÆÄ ÓÀÀÍÀÁÒÄ áÄËÛÄÊÒÖËÄÁÉÓ ÃÀÒÙÅÄÅÉÓ ÂÀÌÏ (áÄËÛ. #' + @agreement_no + ')'

		EXEC @r = dbo.ADD_DOC4
			@rec_id = @doc_rec_id OUTPUT,
			@user_id = @doc_user_id,
			@doc_type = @doc_type,
			@doc_date = @doc_date,
			@doc_date_in_doc = @op_date,
			@debit_id = @depo_acc_id,
			@credit_id = @depo_realize_acc_id,
			@iso = @iso,
			@amount = @amount,
			@rec_state = @op_doc_rec_state,
			@descrip = @descrip,
			@op_code = @op_code,
			@account_extra = @depo_acc_id,
			@parent_rec_id = @parent_rec_id,
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
			@receiver_acc_name = @receiver_acc_name,
			@rec_date = @op_date

		IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR ADD DOCUMENT</ERR>' ,16,1); RETURN (1); END
	END
	
	IF @parent_rec_id > 0 SET @doc_rec_id = @parent_rec_id

	SET @close_account = 1
	SET @skip_realize = 0
	
_skip_realize_annulment_amount:

	IF @close_account = 1
	BEGIN
		INSERT INTO dbo.ACC_CHANGES (ACC_ID, [USER_ID], DESCRIP)
		VALUES (@depo_acc_id, @user_id, 'ÀÍÂÀÒÉÛÉÓ ÛÄÝÅËÀ : UID REC_STATE DATE_CLOSE (ÀÍÀÁÒÉÓ ÃÀáÖÒÅÀ ÃÀÒÙÅÄÅÉÈ)')
		IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR UPDATE ACCOUNT CHANGES</ERR>', 16, 1); RETURN (1); END

		SET @rec_id = SCOPE_IDENTITY()

		INSERT INTO dbo.ACCOUNTS_ARC
		SELECT @rec_id, *
		FROM dbo.ACCOUNTS
		WHERE ACC_ID = @depo_acc_id
		IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR UPDATE ACCOUNT ARC</ERR>', 16, 1); RETURN (1); END

		UPDATE dbo.ACCOUNTS WITH (UPDLOCK)
		SET [UID] = [UID] + 1, REC_STATE = 2, DATE_CLOSE = @op_date
		WHERE ACC_ID = @depo_acc_id
		IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR UPDATE ACCOUNT DATA</ERR>', 16, 1); RETURN (1); END
	END
	ELSE
	BEGIN
		IF @account_rec_state <> 1
		BEGIN
			INSERT INTO dbo.ACC_CHANGES (ACC_ID, [USER_ID], DESCRIP)
			VALUES (@depo_acc_id, @user_id, 'ÀÍÂÀÒÉÛÉÓ ÛÄÝÅËÀ : UID REC_STATE (ÀÍÀÁÒÉÓ ÃÀáÖÒÅÀ ÃÀÒÙÅÄÅÉÈ)')
			IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR UPDATE ACCOUNT CHANGES</ERR>', 16, 1); RETURN (1); END

			SET @rec_id = SCOPE_IDENTITY()
		
			INSERT INTO dbo.ACCOUNTS_ARC
			SELECT @rec_id, *
			FROM dbo.ACCOUNTS
			WHERE ACC_ID = @depo_acc_id
			IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR UPDATE ACCOUNT ARC</ERR>', 16, 1); RETURN (1); END

			UPDATE dbo.ACCOUNTS WITH (UPDLOCK)
			SET [UID] = [UID] + 1, REC_STATE = 1
			WHERE ACC_ID = @depo_acc_id
			IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR UPDATE ACCOUNT DATA</ERR>', 16, 1); RETURN (1); END
		END
		ELSE
		BEGIN
			INSERT INTO dbo.ACC_CHANGES (ACC_ID, [USER_ID], DESCRIP)
			VALUES (@depo_acc_id, @user_id, 'ÀÍÂÀÒÉÛÉÓ ÛÄÝÅËÀ : UID (ÀÍÀÁÒÉÓ ÃÀáÖÒÅÀ ÃÀÒÙÅÄÅÉÈ)')
			IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR UPDATE ACCOUNT CHANGES</ERR>', 16, 1); RETURN (1); END

			SET @rec_id = SCOPE_IDENTITY()

			INSERT INTO dbo.ACCOUNTS_ARC
			SELECT @rec_id, *
			FROM dbo.ACCOUNTS
			WHERE ACC_ID = @depo_acc_id
			IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR UPDATE ACCOUNT ARC</ERR>', 16, 1); RETURN (1); END

			UPDATE dbo.ACCOUNTS WITH (UPDLOCK)
			SET [UID] = [UID] + 1
			WHERE ACC_ID = @depo_acc_id
			IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR UPDATE ACCOUNT DATA</ERR>', 16, 1); RETURN (1); END
		END
	END
	
	EXEC @r = dbo.PROCESS_ACCRUAL
		@perc_type = 0,
		@acc_id = @depo_acc_id,
		@user_id = @user_id,
		@dept_no = @dept_no,
		@doc_date = @op_date,
		@calc_date = @op_date,
		@force_calc = 1,
		@force_realization = 1,
		@simulate = 0,
		@recalc_option  = 0,
		@accrue_amount = @op_amount,
		@restore_acc_id = @depo_realize_acc_id,
		@depo_op_type = @op_type,
		@depo_depo_id = @depo_id,
		@restart_calc = 1,		
		@rec_id  = @accrue_doc_rec_id OUTPUT
	IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR PROCESS ACRRUAL</ERR>', 16, 1); RETURN (1); END

	IF @accrue_doc_rec_id IS NOT NULL
	BEGIN
		UPDATE dbo.OPS_0000 WITH(UPDLOCK)
		SET [UID] = [UID] + 1, FLAGS = 1
		WHERE REC_ID = @accrue_doc_rec_id
		IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR PROCESS ACRRUAL DOC FLAGS CHANGE</ERR>', 16, 1); RETURN (1); END
	END
	
	INSERT INTO dbo.ACCOUNTS_CRED_PERC_ARC
	SELECT @rec_id, *
	FROM dbo.ACCOUNTS_CRED_PERC
	WHERE ACC_ID = @depo_acc_id
	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR UPDATE ACCOUNT CRED PERC ARC</ERR>', 16, 1); RETURN (1); END
	
	UPDATE dbo.ACCOUNTS_CRED_PERC WITH (UPDLOCK)
	SET END_DATE = @op_date
	WHERE ACC_ID = @depo_acc_id 
	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR UPDATE ACCOUNT CRED PERC ARC</ERR>', 16, 1); RETURN (1); END

	SET @op_data.modify('delete (//@ACC_ARC_REC_ID)[1]')

	SET @op_data.modify('insert (attribute ACC_ARC_REC_ID {sql:variable("@rec_id")}) as last into (/row)[1]')

/*	DELETE FROM dbo.ACCOUNTS_CRED_PERC
	WHERE ACC_ID = @depo_acc_id
	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR UPDATE ACCOUNT CRED PERC ARC</ERR>', 16, 1); RETURN (1); END
	*/ -- ÀÍÂÀÒÉÛÉÓ ÃÀáÖÒÅÉÓ ÃÒÏÓ ÀÒ ßÀÅÛÀËÏÈ ÊÒÄÃÉÔÖË ÍÀÛÈÆÄ ÃÀÒÉÝáÅÉÓ ÓØÄÌÀ

	EXEC @r = dbo.ON_USER_AFTER_EDIT_ACC @depo_acc_id, @user_id
	IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR PROC: ON_USER_AFTER_EDIT_ACC</ERR>', 16, 1); RETURN (1); END

	SET @op_acc_data =
		(SELECT
			@rec_id AS ACC_ARC_REC_ID,
			@skip_realize AS SKIP_REALIZE,
			@account_rec_state AS ACCOUNT_REC_STATE,
			@account_date_close AS ACCOUNT_DATE_CLOSE
		FOR XML RAW, TYPE)	

	UPDATE dbo.DEPO_OP WITH (UPDLOCK)
	SET OP_DATA = @op_data, OP_ACC_DATA = @op_acc_data
	WHERE OP_ID = @op_id
	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR UPDATE OP DATA</ERR>', 16, 1); RETURN (1); END
END
ELSE
IF @op_type IN (dbo.depo_fn_const_op_close(), dbo.depo_fn_const_op_annulment_positive())
BEGIN
	DECLARE
		@interest_realize_amount money

	SET @close_account = 0
	SET @skip_realize = 1
	
	SELECT @account_rec_state = REC_STATE, @account_date_close = DATE_CLOSE, @account_blocked_amount = ISNULL(BLOCKED_AMOUNT, $0.00)
	FROM dbo.ACCOUNTS (NOLOCK)
	WHERE ACC_ID = @depo_acc_id
	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR DEPOSIT ACCOUNT DATA</ERR>', 16, 1); RETURN (1); END
	
	IF ISNULL(@depo_realize_acc_id, @depo_acc_id) = @depo_acc_id
		GOTO _skip_realize_close
	
	IF @op_type = dbo.depo_fn_const_op_close()
		SELECT @amount = DEPO_REALIZE_AMOUNT, @interest_realize_acc_id = INTEREST_REALIZE_ACC_ID, @interest_realize_amount = INTEREST_REALIZE_AMOUNT
		FROM dbo.DEPO_VW_OP_DATA_CLOSE
		WHERE OP_ID = @op_id
	ELSE	
	IF @op_type = dbo.depo_fn_const_op_annulment_positive()
		SELECT @amount = DEPO_REALIZE_AMOUNT, @interest_realize_acc_id = INTEREST_REALIZE_ACC_ID, @interest_realize_amount = DEPO_REALIZE_INTEREST
		FROM dbo.DEPO_VW_OP_DATA_ANNULMENT_POSITIVE
		WHERE OP_ID = @op_id
	
	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR OP DATA NOT FOUND!</ERR>', 16, 1); RETURN (1); END

	IF @interest_realize_acc_id = @depo_acc_id
		SET @amount = @amount + ISNULL(@interest_realize_amount, $0.00) 
	
	IF ISNULL(@amount, $0.00) <= $0.00 GOTO _skip_realize_close

	IF @account_blocked_amount <> $0.00
		GOTO _skip_realize_close

	IF @depo_holiday_close = 1
		SET @doc_date = dbo.date_next_workday(@op_date)
	ELSE
		SET @doc_date = @op_date

	IF @transfer_doc_type = 0 --Memorial Order
	BEGIN
		SET @op_code = '*DCA*'
		SET @descrip = 
			CASE @op_type
				WHEN dbo.depo_fn_const_op_annulment_positive() THEN 'ÓÀÀÍÀÁÒÄ áÄËÛÄÊÒÖËÄÁÉÓ ÛÄßÚÅÄÔÀ (áÄËÛ. #' + @agreement_no + ')'
				WHEN dbo.depo_fn_const_op_close() THEN 'ÓÀÀÍÀÁÒÄ áÄËÛÄÊÒÖËÄÁÉÓ ÅÀÃÉÓ ÂÀÓÅËÀ (áÄËÛ. #' + @agreement_no + ')'
				ELSE NULL
			END	
		
		EXEC @r = dbo.ADD_DOC4
			@rec_id = @doc_rec_id OUTPUT,
			@user_id = @doc_user_id,
			@doc_type = 98,
			@doc_date = @doc_date,
			@doc_date_in_doc = @op_date,
			@debit_id = @depo_acc_id,
			@credit_id = @depo_realize_acc_id,
			@iso = @iso,
			@amount = @amount,
			@rec_state = @op_doc_rec_state,
			@descrip = @descrip,
			@op_code = @op_code,
			@account_extra = @depo_acc_id,
			@channel_id = 800,
			@flags = 0x15F4

		IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR ADD DOCUMENT</ERR>',16,1); RETURN (1); END
	END
	ELSE
	IF @transfer_doc_type = 1 --Transfer
	BEGIN
		IF @iso = 'GEL'
		BEGIN
			SET @sender_bank_code = dbo.acc_get_bank_code(@depo_acc_id)
			SELECT @sender_bank_name = DESCRIP FROM dbo.BANKS (NOLOCK) WHERE CODE9 = @sender_bank_code
			SET @sender_acc_name = dbo.acc_get_name(@depo_acc_id)
			SET @sender_acc = dbo.acc_get_account(@depo_acc_id)
			SELECT @sender_tax_code =  CASE WHEN ISNULL(C.TAX_INSP_CODE, '') <> '' THEN C.TAX_INSP_CODE ELSE C.PERSONAL_ID END FROM dbo.CLIENTS C(NOLOCK) WHERE C.CLIENT_NO = @client_no 
			
			SET @receiver_bank_code = dbo.acc_get_bank_code(@depo_realize_acc_id)
			SELECT @receiver_bank_name = DESCRIP FROM dbo.BANKS (NOLOCK) WHERE CODE9 = @receiver_bank_code
			SET @receiver_acc_name = dbo.acc_get_name(@depo_realize_acc_id)
			SET @receiver_acc = dbo.acc_get_account(@depo_realize_acc_id)
			SELECT @receiver_tax_code =  CASE WHEN ISNULL(C.TAX_INSP_CODE, '') <> '' THEN C.TAX_INSP_CODE ELSE C.PERSONAL_ID END FROM dbo.CLIENTS C(NOLOCK) WHERE C.CLIENT_NO = @client_no 
		END
		ELSE
		BEGIN
			SET @sender_bank_code = dbo.acc_get_bank_code_bic(@depo_acc_id)
			SELECT @sender_bank_name = DESCRIP FROM dbo.BIC_CODES (NOLOCK) WHERE BIC = @sender_bank_code
			SET @sender_acc_name = dbo.acc_get_name_lat(@depo_acc_id)
			SET @sender_acc = dbo.acc_get_account(@depo_acc_id)
			SELECT @sender_tax_code =  CASE WHEN ISNULL(C.TAX_INSP_CODE, '') <> '' THEN C.TAX_INSP_CODE ELSE C.PERSONAL_ID END FROM dbo.CLIENTS C(NOLOCK) WHERE C.CLIENT_NO = @client_no 
			
			SET @receiver_bank_code = dbo.acc_get_bank_code_bic(@depo_realize_acc_id)
			SELECT @receiver_bank_name = DESCRIP FROM dbo.BIC_CODES (NOLOCK) WHERE BIC = @receiver_bank_code
			SET @receiver_acc_name = dbo.acc_get_name_lat(@depo_realize_acc_id)
			SET @receiver_acc = dbo.acc_get_account(@depo_realize_acc_id)
			SELECT @receiver_tax_code =  CASE WHEN ISNULL(C.TAX_INSP_CODE, '') <> '' THEN C.TAX_INSP_CODE ELSE C.PERSONAL_ID END FROM dbo.CLIENTS C(NOLOCK) WHERE C.CLIENT_NO = @client_no 
		END

		SET @op_code = '*DCA*'
		SET @doc_type = CASE @iso WHEN 'GEL' THEN 100 ELSE 110 END
		SET @descrip = 
			CASE @op_type
				WHEN dbo.depo_fn_const_op_annulment_positive() THEN 'ÓÀÀÍÀÁÒÄ áÄËÛÄÊÒÖËÄÁÉÓ ÛÄßÚÅÄÔÀ (áÄËÛ. #' + @agreement_no + ')'
				WHEN dbo.depo_fn_const_op_close() THEN 'ÓÀÀÍÀÁÒÄ áÄËÛÄÊÒÖËÄÁÉÓ ÅÀÃÉÓ ÂÀÓÅËÀ (áÄËÛ. #' + @agreement_no + ')'
				ELSE NULL
			END	

		EXEC @r = dbo.ADD_DOC4
			@rec_id = @doc_rec_id OUTPUT,
			@user_id = @doc_user_id,
			@doc_type = @doc_type,
			@doc_date = @doc_date,
			@doc_date_in_doc = @op_date,
			@debit_id = @depo_acc_id,
			@credit_id = @depo_realize_acc_id,
			@iso = @iso,
			@amount = @amount,
			@rec_state = @op_doc_rec_state,
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
			@receiver_acc_name = @receiver_acc_name,
			@rec_date = @op_date

		IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR ADD DOCUMENT</ERR>' ,16,1); RETURN (1); END
	END

	SET @skip_realize = 0
	SET @close_account = 1
_skip_realize_close:

	IF @close_account = 1
	BEGIN
		INSERT INTO dbo.ACC_CHANGES (ACC_ID, [USER_ID], DESCRIP)
		VALUES (@depo_acc_id, @user_id, 'ÀÍÂÀÒÉÛÉÓ ÛÄÝÅËÀ : UID REC_STATE DATE_CLOSE (ÀÍÀÁÒÉÓ ÃÀáÖÒÅÀ)')
		IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR UPDATE ACCOUNT CHANGES</ERR>', 16, 1); RETURN (1); END

		SET @rec_id = SCOPE_IDENTITY()

		INSERT INTO dbo.ACCOUNTS_ARC
		SELECT @rec_id, *
		FROM dbo.ACCOUNTS
		WHERE ACC_ID = @depo_acc_id
		IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR UPDATE ACCOUNT ARC</ERR>', 16, 1); RETURN (1); END

		UPDATE dbo.ACCOUNTS WITH (UPDLOCK)
		SET [UID] = [UID] + 1, REC_STATE = 2, DATE_CLOSE = @op_date
		WHERE ACC_ID = @depo_acc_id
		IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR UPDATE ACCOUNT DATA</ERR>', 16, 1); RETURN (1); END
	END
	ELSE
	BEGIN
		IF @account_rec_state <> 1
		BEGIN
			INSERT INTO dbo.ACC_CHANGES (ACC_ID, [USER_ID], DESCRIP)
			VALUES (@depo_acc_id, @user_id, 'ÀÍÂÀÒÉÛÉÓ ÛÄÝÅËÀ : UID REC_STATE (ÀÍÀÁÒÉÓ ÃÀáÖÒÅÀ)')
			IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR UPDATE ACCOUNT CHANGES</ERR>', 16, 1); RETURN (1); END

			SET @rec_id = SCOPE_IDENTITY()
		
			INSERT INTO dbo.ACCOUNTS_ARC
			SELECT @rec_id, *
			FROM dbo.ACCOUNTS
			WHERE ACC_ID = @depo_acc_id
			IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR UPDATE ACCOUNT ARC</ERR>', 16, 1); RETURN (1); END

			UPDATE dbo.ACCOUNTS WITH (UPDLOCK)
			SET [UID] = [UID] + 1, REC_STATE = 1
			WHERE ACC_ID = @depo_acc_id
			IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR UPDATE ACCOUNT DATA</ERR>', 16, 1); RETURN (1); END
		END
		ELSE
		BEGIN
			INSERT INTO dbo.ACC_CHANGES (ACC_ID, [USER_ID], DESCRIP)
			VALUES (@depo_acc_id, @user_id, 'ÀÍÂÀÒÉÛÉÓ ÛÄÝÅËÀ : UID (ÀÍÀÁÒÉÓ ÃÀáÖÒÅÀ)')
			IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR UPDATE ACCOUNT CHANGES</ERR>', 16, 1); RETURN (1); END

			SET @rec_id = SCOPE_IDENTITY()

			INSERT INTO dbo.ACCOUNTS_ARC
			SELECT @rec_id, *
			FROM dbo.ACCOUNTS
			WHERE ACC_ID = @depo_acc_id
			IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR UPDATE ACCOUNT ARC</ERR>', 16, 1); RETURN (1); END

			UPDATE dbo.ACCOUNTS WITH (UPDLOCK)
			SET [UID] = [UID] + 1
			WHERE ACC_ID = @depo_acc_id
			IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR UPDATE ACCOUNT DATA</ERR>', 16, 1); RETURN (1); END
		END
	END

	INSERT INTO dbo.ACCOUNTS_CRED_PERC_ARC
	SELECT @rec_id, *
	FROM dbo.ACCOUNTS_CRED_PERC
	WHERE ACC_ID = @depo_acc_id
	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR UPDATE ACCOUNT CRED PERC ARC</ERR>', 16, 1); RETURN (1); END

	UPDATE dbo.ACCOUNTS_CRED_PERC WITH (UPDLOCK)
	SET END_DATE = @op_date
	WHERE ACC_ID = @depo_acc_id 
	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR UPDATE ACCOUNT CRED PERC ARC</ERR>', 16, 1); RETURN (1); END
	
	SET @op_data.modify('delete (//@ACC_ARC_REC_ID)[1]')

	SET @op_data.modify('insert (attribute ACC_ARC_REC_ID {sql:variable("@rec_id")}) as last into (/row)[1]')

	/*DELETE FROM dbo.ACCOUNTS_CRED_PERC
	WHERE ACC_ID = @depo_acc_id
	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR UPDATE ACCOUNT CRED PERC ARC</ERR>', 16, 1); RETURN (1); END
	*/ -- ÀÍÂÀÒÉÛÉÓ ÃÀáÖÒÅÉÓ ÃÒÏÓ ÀÒ ßÀÅÛÀËÏÈ ÊÒÄÃÉÔÖË ÍÀÛÈÆÄ ÃÀÒÉÝáÅÉÓ ÓØÄÌÀ

	EXEC @r = dbo.ON_USER_AFTER_EDIT_ACC @depo_acc_id, @user_id
	IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR PROC: ON_USER_AFTER_EDIT_ACC</ERR>', 16, 1); RETURN (1); END

	SET @op_acc_data =
		(SELECT
			@rec_id AS ACC_ARC_REC_ID,
			@skip_realize AS SKIP_REALIZE,
			@account_rec_state AS ACCOUNT_REC_STATE,
			@account_date_close AS ACCOUNT_DATE_CLOSE
		FOR XML RAW, TYPE)	

	UPDATE dbo.DEPO_OP WITH (UPDLOCK)
	SET OP_DATA = @op_data, OP_ACC_DATA = @op_acc_data
	WHERE OP_ID = @op_id
	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('<ERR>ERROR UPDATE OP DATA</ERR>', 16, 1); RETURN (1); END
END

IF @internal_transaction=1 AND @@TRANCOUNT>0 
	COMMIT TRAN

RETURN(0)
GO
