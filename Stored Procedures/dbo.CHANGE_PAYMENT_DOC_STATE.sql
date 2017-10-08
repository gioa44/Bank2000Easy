SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[CHANGE_PAYMENT_DOC_STATE]
	@doc_rec_id int = 0,
	@rec_state int = 0,
	@lock_flag int = 0,
	@waiting_flag int = 0,
	@user_id int = 0,
	@descrip nvarchar (50) = null
AS

SET NOCOUNT ON

DECLARE 
	@r int,
	@e int,
	@old_rec_state int,
	@old_lock_flag int,
	@can_delete bit,
	@provider_id int,
	@service_alias  varchar(20),
	@dt_tm smalldatetime
	--@old_waiting_flag int

SELECT	@old_rec_state = REC_STATE, @old_lock_flag = LOCK_FLAG, --@old_waiting_flag = WAITING_FLAG
		@provider_id = PROVIDER_ID, @service_alias = SERVICE_ALIAS, @dt_tm = DT_TM
FROM	dbo.PENDING_PAYMENTS (NOLOCK)
WHERE	DOC_REC_ID = @doc_rec_id

IF @rec_state = 5
	SELECT	@can_delete = CAN_DELETE
	FROM	dbo.PAYMENT_PROVIDER_SERVICES (NOLOCK)
	WHERE	PROVIDER_ID = @provider_id AND SERVICE_ALIAS = @service_alias

DECLARE
	@internal_transaction bit

SET @internal_transaction = 0
IF @@TRANCOUNT = 0
BEGIN
	BEGIN TRAN
	SET @internal_transaction = 1
END

IF (@old_rec_state = 1) AND (@rec_state = 2) AND (@old_lock_flag = 1)-- AND (@old_waiting_flag = 1)
BEGIN
	-- საბუთი დაბრაკულია პროვაიდერის მიერ
	UPDATE dbo.PENDING_PAYMENTS
	SET	REC_STATE = @rec_state,
		LOCK_FLAG = 0,
		WAITING_FLAG = 0,
		DT_TM = GETDATE(),
		INFO = CAST(GETDATE() AS VARCHAR) + ': ' + @descrip,
		RESPONSE = 'ÓÀÁÖÈÉ ÃÀÁÒÀÊÖËÉÀ' -- საბუთი დაბრაკულია
	WHERE DOC_REC_ID = @doc_rec_id
	IF @@ERROR <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 100 END

	EXEC @r = dbo.ADD_CANCELED_PLAT @doc_rec_id
	IF @@ERROR<>0 OR @r <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN @r END
END
ELSE
IF (@old_rec_state = 5) AND (@rec_state = 4) AND (@old_lock_flag = 1)
BEGIN
	-- საბუთის გაუქმება
	UPDATE dbo.PENDING_PAYMENTS
	SET	REC_STATE = @rec_state,
		LOCK_FLAG = 0,
		WAITING_FLAG = 0,
		DT_TM = GETDATE(),
		INFO = CAST(GETDATE() AS VARCHAR) + ': ' + @descrip,
		RESPONSE = 'ÓÀÁÖÈÉ ÂÀÖØÌÄÁÖËÉÀ' -- საბუთი გაუქმებულია
	WHERE DOC_REC_ID = @doc_rec_id
	IF @@ERROR <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 101 END

	EXEC @r = dbo.ADD_CANCELED_PLAT @doc_rec_id
	IF @@ERROR<>0 OR @r <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN @r END
END
ELSE
IF (@old_rec_state = 3) AND (@rec_state = 4)
BEGIN
	IF @can_delete = 0
	BEGIN
		ROLLBACK
		RAISERROR ('ÀÌ ÓÄÒÅÉÓ ÀÒÀ ÀØÅÓ ÓÀÁÖÈÉÓ ÂÀÖØÌÄÁÉÓ ÛÄÓÀÞËÄÁËÏÁÀ!',16,1)
		RETURN 102
	END

	-- საბუთის გაუქმება
	UPDATE dbo.PENDING_PAYMENTS
	SET	REC_STATE = @rec_state,
		LOCK_FLAG = 0,
		WAITING_FLAG = 0,
		DT_TM = GETDATE(),
		INFO = CAST(GETDATE() AS VARCHAR) + ': ' + @descrip,
		RESPONSE = 'ÓÀÁÖÈÉ ÂÀÖØÌÄÁÖËÉÀ' -- საბუთი გაუქმებულია
	WHERE DOC_REC_ID = @doc_rec_id
	IF @@ERROR <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 103 END

	EXEC @r = dbo.ADD_CANCELED_PLAT @doc_rec_id
	IF @@ERROR<>0 OR @r <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN @r END
END
ELSE
IF (@old_rec_state = 1 AND @rec_state = 3 AND @old_lock_flag = 1)
BEGIN
	-- საბუთი დასრულებულია
	UPDATE dbo.PENDING_PAYMENTS
	SET	REC_STATE = @rec_state,
		LOCK_FLAG = 0,
		WAITING_FLAG = 0,
		DT_TM = GETDATE(),
		INFO = CAST(GETDATE() AS VARCHAR) + ': ' + @descrip,
		RESPONSE = 'ÃÀÓÒÖËÄÁÖËÉÀ' -- დასრულებულია
	WHERE DOC_REC_ID = @doc_rec_id
	IF @@ERROR <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 104 END

	EXEC @r = dbo.ADD_PAYMENT_PLAT @doc_rec_id
	IF @@ERROR<>0 OR @r <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN @r END
END
ELSE
IF (@old_rec_state = 1 AND @rec_state = 3 AND @old_lock_flag = 0)
BEGIN
	-- საბუთი დასრულებულია
	UPDATE dbo.PENDING_PAYMENTS
	SET	REC_STATE = @rec_state,
		LOCK_FLAG = 0,
		WAITING_FLAG = 0,
		DT_TM = GETDATE(),
		INFO = CAST(GETDATE() AS VARCHAR) + ': ' + @descrip,
		RESPONSE = 'ÃÀÓÒÖËÄÁÖËÉÀ ÃÀÞÀËÄÁÉÈ' -- დასრულებულია
	WHERE DOC_REC_ID = @doc_rec_id
	IF @@ERROR <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 105 END

	EXEC @r = dbo.ADD_PAYMENT_PLAT @doc_rec_id
	IF @@ERROR<>0 OR @r <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN @r END
END
ELSE
IF (@old_rec_state = 0 AND @rec_state = 3 AND @lock_flag = 0)
BEGIN
	-- საბუთი დასრულებულია
	UPDATE dbo.PENDING_PAYMENTS
	SET	REC_STATE = @rec_state,
		LOCK_FLAG = 0,
		WAITING_FLAG = 0,
		DT_TM = GETDATE(),
		INFO = CAST(GETDATE() AS VARCHAR) + ': ' + @descrip,
		RESPONSE = 'ÃÀÓÒÖËÄÁÖËÉÀ' -- დასრულებულია
	WHERE DOC_REC_ID = @doc_rec_id
	IF @@ERROR <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 106 END

	EXEC @r = dbo.ADD_PAYMENT_PLAT @doc_rec_id
	IF @@ERROR<>0 OR @r <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN @r END
END
ELSE
IF (@old_rec_state = 0 AND @rec_state = 1 AND @lock_flag = 0)
BEGIN
	-- საბუთი მზადაა გასაგზავნად
	UPDATE dbo.PENDING_PAYMENTS
	SET	REC_STATE = @rec_state,
		LOCK_FLAG = @lock_flag,
		WAITING_FLAG = @waiting_flag,
		DT_TM = CASE WHEN @dt_tm > GETDATE() THEN @dt_tm ELSE GETDATE() END,
		INFO = CAST(GETDATE() AS VARCHAR) + ': ' + @descrip,
		RESPONSE = 'ÌÆÀÃÀÀ ÂÀÓÀÂÆÀÅÍÀÃ' -- დასრულებულია
	WHERE DOC_REC_ID = @doc_rec_id
	IF @@ERROR <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 107 END
END
ELSE
IF (@old_rec_state = 1 AND @rec_state = 1 AND @old_lock_flag = 1 AND @lock_flag = 0)
BEGIN
	-- საბუთი მზადაა გასაგზავნად
	UPDATE dbo.PENDING_PAYMENTS
	SET	REC_STATE = @rec_state,
		LOCK_FLAG = @lock_flag,
		WAITING_FLAG = @waiting_flag,
		DT_TM = CASE WHEN @dt_tm > GETDATE() THEN @dt_tm ELSE GETDATE() END,
		INFO = CAST(GETDATE() AS VARCHAR) + ': ' + @descrip,
		RESPONSE = 'ÌÆÀÃÀÀ ÂÀÓÀÂÆÀÅÍÀÃ' -- დასრულებულია
	WHERE DOC_REC_ID = @doc_rec_id
	IF @@ERROR <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 108 END
END
ELSE
IF (@old_rec_state = 1 AND @rec_state = 1 AND @old_lock_flag = 0 AND @lock_flag = 1)
BEGIN
	-- საბუთი მზადაა გასაგზავნად
	UPDATE dbo.PENDING_PAYMENTS
	SET	REC_STATE = @rec_state,
		LOCK_FLAG = @lock_flag,
		WAITING_FLAG = @waiting_flag,
		DT_TM = CASE WHEN @dt_tm > GETDATE() THEN @dt_tm ELSE GETDATE() END,
		INFO = CAST(GETDATE() AS VARCHAR) + ': ' + @descrip,
		RESPONSE = 'ÌÆÀÃÀÀ ÂÀÓÀÂÆÀÅÍÀÃ' -- დასრულებულია
	WHERE DOC_REC_ID = @doc_rec_id
	IF @@ERROR <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 109 END
END
ELSE
IF (@old_rec_state = 3 AND @rec_state = 5 AND @lock_flag = 0)
BEGIN
	-- საბუთი მზად არის გასაუქმებლად
	UPDATE dbo.PENDING_PAYMENTS
	SET	REC_STATE = @rec_state,
		LOCK_FLAG = @lock_flag,
		WAITING_FLAG = @waiting_flag,
		DT_TM = GETDATE(),
		INFO = CAST(GETDATE() AS VARCHAR) + ': ' + @descrip,
		RESPONSE = 'ÌÆÀÃ ÀÒÉÓ ÂÀÓÀÖØÌÄÁËÀÃ' -- დასრულებულია
	WHERE DOC_REC_ID = @doc_rec_id
	IF @@ERROR <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 110 END
END
ELSE
IF (@old_rec_state = 5 AND @rec_state = 5 AND @old_lock_flag = 0 AND @lock_flag = 1)
BEGIN
	-- საბუთი არის გაუქმების პროცეში
	UPDATE dbo.PENDING_PAYMENTS
	SET	REC_STATE = @rec_state,
		LOCK_FLAG = @lock_flag,
		WAITING_FLAG = @waiting_flag,
		DT_TM = GETDATE(),
		INFO = CAST(GETDATE() AS VARCHAR) + ': ' + @descrip,
		RESPONSE = 'ÂÀÖØÌÄÁÉÓ ÐÒÏÝÄÛÉÀ' -- დასრულებულია
	WHERE DOC_REC_ID = @doc_rec_id
	IF @@ERROR <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 111 END
END
ELSE
IF (@old_rec_state = 5 AND @rec_state = 5 AND @old_lock_flag = 1 AND @lock_flag = 0)
BEGIN
	-- საბუთი მზად არის გასაუქმებლად
	UPDATE dbo.PENDING_PAYMENTS
	SET	REC_STATE = @rec_state,
		LOCK_FLAG = @lock_flag,
		WAITING_FLAG = @waiting_flag,
		DT_TM = GETDATE(),
		INFO = CAST(GETDATE() AS VARCHAR) + ': ' + @descrip,
		RESPONSE = 'ÌÆÀÃ ÀÒÉÓ ÂÀÓÀÖØÌÄÁËÀÃ' -- დასრულებულია
	WHERE DOC_REC_ID = @doc_rec_id
	IF @@ERROR <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 112 END
END
ELSE
IF (@old_rec_state = 1 AND @rec_state = 0 AND @old_lock_flag = 0 AND @lock_flag = 0)
BEGIN
	-- საბუთი დამატებულია
	UPDATE dbo.PENDING_PAYMENTS
	SET	REC_STATE = @rec_state,
		LOCK_FLAG = @lock_flag,
		WAITING_FLAG = @waiting_flag,
		DT_TM = GETDATE(),
		INFO = CAST(GETDATE() AS VARCHAR) + ': ' + @descrip,
		RESPONSE = 'ÓÀÁÖÈÉ ÃÀÌÀÔÄÁÖËÉÀ' -- დასრულებულია
	WHERE DOC_REC_ID = @doc_rec_id
	IF @@ERROR <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 113 END
END
ELSE
IF (@old_rec_state = 3 AND @rec_state = 0 AND @lock_flag = 0)
BEGIN
	-- საბუთი დამატებულია
	UPDATE dbo.PENDING_PAYMENTS
	SET	REC_STATE = @rec_state,
		LOCK_FLAG = @lock_flag,
		WAITING_FLAG = @waiting_flag,
		DT_TM = GETDATE(),
		INFO = CAST(GETDATE() AS VARCHAR) + ': ' + @descrip,
		RESPONSE = 'ÌÆÀÃ ÀÒÉÓ ÂÀÓÀÖØÌÄÁËÀÃ' -- დასრულებულია
	WHERE DOC_REC_ID = @doc_rec_id
	IF @@ERROR <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 114 END

	UPDATE dbo.OPS_0000
	SET		CHANNEL_ID = 0
	WHERE	FOREIGN_ID = @doc_rec_id AND CHANNEL_ID = 778
	IF @@ERROR <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 115 END
END
ELSE
IF (@old_rec_state = 1 AND @rec_state = 4 AND @lock_flag = 0)
BEGIN
	-- საბუთი მზად არის გასაგზავნად და უნდა გავაუქმოთ
	UPDATE dbo.PENDING_PAYMENTS
	SET	REC_STATE = @rec_state,
		LOCK_FLAG = @lock_flag,
		WAITING_FLAG = @waiting_flag,
		DT_TM = GETDATE(),
		INFO = CAST(GETDATE() AS VARCHAR) + ': ' + @descrip,
		RESPONSE = 'ÂÀÖØÌÄÁÖËÉÀ áÄËÉÈ ' -- გაუქმებულია ხელით
	WHERE DOC_REC_ID = @doc_rec_id
	IF @@ERROR <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 116 END

	DECLARE
		@doc_date smalldatetime,
		@amount money,
		@op_code varchar(5),
		@debit_id int,
		@credit_id int,
		@doc_type smallint,
		@prod_id int,
		@foreign_id int,
		@channel_id int,
		@dept_no int,
		@sender_bank_code varchar(37),
		@sender_acc varchar(37),
		@sender_tax_code varchar(11),
		@receiver_bank_code varchar(37),
		@receiver_acc varchar(37),
		@receiver_tax_code varchar(11),
		@sender_bank_name varchar(105),
		@receiver_bank_name varchar(105),
		@sender_acc_name varchar(105),
		@receiver_acc_name varchar(105),
		@rec_id int,
		@today smalldatetime,
		@descr varchar(150),
		@in_arc bit

	SELECT	@doc_date=DOC_DATE, @amount=AMOUNT,@op_code=OP_CODE,@debit_id=DEBIT_ID,@credit_id=CREDIT_ID,@descr=DESCRIP,@doc_type=DOC_TYPE,
			@prod_id=PROD_ID,@foreign_id=FOREIGN_ID,@channel_id=CHANNEL_ID,@dept_no=DEPT_NO,@sender_bank_code=SENDER_BANK_CODE,
			@sender_acc=SENDER_ACC, @sender_tax_code=SENDER_TAX_CODE, @receiver_bank_code=RECEIVER_BANK_CODE, @receiver_acc=RECEIVER_ACC,
			@receiver_tax_code=RECEIVER_TAX_CODE, @sender_bank_name=SENDER_BANK_NAME, @receiver_bank_name=RECEIVER_BANK_NAME,
			@sender_acc_name=SENDER_ACC_NAME, @receiver_acc_name=RECEIVER_ACC_NAME, @receiver_acc_name=RECEIVER_ACC_NAME,
			@receiver_acc_name=RECEIVER_ACC_NAME,@rec_state=REC_STATE
	FROM dbo.DOCS_PLAT(NOLOCK)
	WHERE OP_NUM = @doc_rec_id

	IF ISNULL(@debit_id, 0) = 0
	BEGIN
	SELECT	@amount=AMOUNT,@op_code=OP_CODE,@debit_id=DEBIT_ID,@credit_id=CREDIT_ID,@descr=DESCRIP,@doc_type=DOC_TYPE,
			@prod_id=PROD_ID,@foreign_id=FOREIGN_ID,@channel_id=CHANNEL_ID,@dept_no=DEPT_NO,@sender_bank_code=SENDER_BANK_CODE,
			@sender_acc=SENDER_ACC, @sender_tax_code=SENDER_TAX_CODE, @receiver_bank_code=RECEIVER_BANK_CODE, @receiver_acc=RECEIVER_ACC,
			@receiver_tax_code=RECEIVER_TAX_CODE, @sender_bank_name=SENDER_BANK_NAME, @receiver_bank_name=RECEIVER_BANK_NAME,
			@sender_acc_name=SENDER_ACC_NAME, @receiver_acc_name=RECEIVER_ACC_NAME, @receiver_acc_name=RECEIVER_ACC_NAME,
			@receiver_acc_name=RECEIVER_ACC_NAME,@rec_state=REC_STATE
		FROM dbo.DOCS_ARC_PLAT(NOLOCK)
		WHERE OP_NUM = @doc_rec_id
	SET @doc_date = convert(smalldatetime,floor(convert(real,GETDATE())))
	END

	SET @today = convert(smalldatetime,floor(convert(real,GETDATE())))

	IF @today < @doc_date
		SET @today = @doc_date

	SET @descr = 'ÈÀÍáÉÓ ÖÊÀÍ ÃÀÁÒÖÍÄÁÀ (' + @descr + ') ' + CONVERT(VARCHAR(24), @doc_date, 104)

	IF ISNULL(@debit_id, 0) > 0
	BEGIN
		SET @rec_state = 20
		SET @receiver_bank_code = dbo.acc_get_bank_code(@credit_id)
		SELECT @receiver_acc = ACCOUNT, @receiver_acc_name = DESCRIP FROM dbo.ACCOUNTS(NOLOCK) WHERE ACC_ID = @credit_id
		SELECT @receiver_bank_name = DESCRIP FROM dbo.BANKS(NOLOCK) WHERE CODE9 = @receiver_bank_code

		EXEC @r = dbo.ADD_DOC4
			@rec_id OUTPUT,
			@user_id=@user_id,@dept_no=@dept_no,@doc_date=@today,@doc_date_in_doc=@today,@doc_type=@doc_type,
			@iso='GEL',@amount=@amount,@doc_num=1,@op_code=@op_code,
			@sender_acc=@receiver_acc,@sender_acc_name=@receiver_acc_name,@sender_tax_code=@receiver_tax_code,
			@debit_id=@credit_id, @credit_id=@debit_id, @sender_bank_code=@receiver_bank_code, @sender_bank_name=@receiver_bank_name,
			@receiver_bank_code=@sender_bank_code, @receiver_acc=@sender_acc, @receiver_acc_name=@sender_acc_name,
			@receiver_tax_code=@sender_tax_code, @receiver_bank_name=@sender_bank_name,
			@rec_state=@rec_state,@foreign_id=@foreign_id,@descrip=@descr,
			@channel_id=@channel_id,@prod_id=@prod_id,@add_tariff=0

		IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 117 END

		IF EXISTS(SELECT * FROM OPS_0000 (NOLOCK) WHERE PARENT_REC_ID = @doc_rec_id AND DOC_TYPE = 12)
		BEGIN
			SET @debit_id = 0
			SELECT @dept_no=DEPT_NO, @amount=AMOUNT, @op_code=OP_CODE, @debit_id=DEBIT_ID, @credit_id=CREDIT_ID, @rec_state=REC_STATE
			FROM OPS_0000 (NOLOCK)
			WHERE PARENT_REC_ID = @doc_rec_id AND DOC_TYPE = 12

			IF ISNULL(@debit_id, 0) = 0
			BEGIN
				SELECT @dept_no=DEPT_NO, @amount=AMOUNT, @op_code=OP_CODE, @debit_id=DEBIT_ID, @credit_id=CREDIT_ID, @rec_state=REC_STATE
				FROM OPS_ARC (NOLOCK)
				WHERE PARENT_REC_ID = @doc_rec_id AND DOC_TYPE = 12
			END

			IF ISNULL(@debit_id, 0) > 0
			BEGIN
				EXEC @r = dbo.ADD_DOC4
						@rec_id OUTPUT,
						@user_id=@user_id,@dept_no=@dept_no,@doc_date=@today,
						@iso='GEL',@amount=@amount,@doc_num=1,@op_code=@op_code,
						@debit_id=@credit_id,
						@credit_id=@debit_id,
						@rec_state=@rec_state, @parent_rec_id=@rec_id,
						@descrip='ÊÏÌÖÍÀËÖÒÉ ÂÀÃÀÓÀáÀÃÉÓ ÓÀÊÏÌÉÓÉÏÓ ÖÊÀÍ ÃÀÁÒÖÍÄÁÀ',@owner=@user_id,
						@doc_type=12,@add_tariff=0

				IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 118 END
			END
		END
	END
	ELSE
	BEGIN
		RAISERROR ('ÀÒÜÄÖËÉ ÊÏÌÖÍÀËÖÒÉ ÂÀÃÀÓÀáÀÃÉÓ ÛÄÓÀÁÀÌÉÓÉ ÂÀÔÀÒÄÁÄÁÉ ÀÒ ÌÏÉÞÄÁÍÀ!',16,1)
		ROLLBACK 
		RETURN 119
	END
	
END

IF @internal_transaction=1 AND @@TRANCOUNT>0 
	COMMIT TRAN
--ROLLBACK
RETURN 0
GO
