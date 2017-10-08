SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[CHANGE_DOC_STATE]
	@rec_id int,				-- საბუთის შიდა №
	@uid int = null,			-- საბუთის ბოლოს ცვლილების ნომერი. თუ ნულია, აღარ ვუყურებთ
	@user_id int,				-- ვინ ცვლის საბუთს
	@new_rec_state tinyint,		-- საბუთის ახალი სტატუსი
	@check_saldo bit = 1,		-- შეამოწმოს თუ არა მინ. ნაშთი
	@check_limits bit = 1		-- შეამოწმოს თუ არა ლიმიტები
AS

SET NOCOUNT ON

IF (@user_id >= 10) AND (SELECT VALS FROM dbo.INI_INT (NOLOCK) WHERE IDS = 'SERVER_STATE') <> 0
BEGIN
	RAISERROR ('ÌÉÌÃÉÍÀÒÄÏÁÓ ÃÙÉÓ ÃÀáÖÒÅÀ/ÂÀáÓÍÀ. ÂÈáÏÅÈ ÃÀÉÝÀÃÏÈ', 16, 1)	
	RETURN 1
END

DECLARE @internal_transaction bit
SET @internal_transaction = 0
IF @@TRANCOUNT = 0
BEGIN
	BEGIN TRAN
	SET @internal_transaction = 1
END

DECLARE 
	@r int,
	@iso char(3),
	@debit_id int,
	@credit_id int,
	@op_code varchar(5),
	@amount money,
	@cash_amount money,
	@doc_type smallint,
	@doc_date smalldatetime,
	@doc_date_in_doc smalldatetime,
	@rec_date smalldatetime,
	@old_rec_state tinyint,
	@parent_rec_id int,
	@relation_id int,
	@cashier int,
	@owner int,
	@dept_no int,
	@doc_num int,
	@account_extra TACCOUNT,
	@prod_id int,
	@foreign_id int,
	@channel_id int

SELECT @iso = ISO, @debit_id = DEBIT_ID, @credit_id = CREDIT_ID, @amount = AMOUNT, @op_code = OP_CODE, 
	@owner = [OWNER], @dept_no = DEPT_NO, @doc_num = DOC_NUM, @account_extra = ACCOUNT_EXTRA, @prod_id = PROD_ID, @foreign_id = FOREIGN_ID, @channel_id = CHANNEL_ID,
	@old_rec_state = REC_STATE, @parent_rec_id = PARENT_REC_ID, @doc_type = DOC_TYPE, @cash_amount = ISNULL(CASH_AMOUNT, $0.00),
	@doc_date = DOC_DATE, @doc_date_in_doc = DOC_DATE_IN_DOC, @relation_id = RELATION_ID, @cashier = CASHIER
FROM dbo.OPS_0000 WITH (ROWLOCK, UPDLOCK)
WHERE REC_ID = @rec_id AND (@uid IS NULL OR UID = @uid)
IF @@ERROR<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 1 END

IF @old_rec_state IS NULL 
BEGIN
	IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK 
	RAISERROR ('ÓÀÁÖÈÉ ÀÒ ÌÏÉÞÄÁÍÀ.', 16, 1)
	RETURN 1
END

EXEC @r = dbo.ON_USER_BEFORE_AUTHORIZE_DOC @rec_id, @user_id, @owner, @new_rec_state, @old_rec_state,
		@parent_rec_id,	@dept_no, @doc_type, @doc_date, @doc_date_in_doc, @debit_id, @credit_id, @iso, @amount, @cash_amount,
		@op_code, @doc_num,	@account_extra, @prod_id, @foreign_id, @channel_id,	@relation_id, @cashier, 0, 0
IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 1 END

DECLARE	@op_type tinyint

SET @op_type = CASE WHEN @new_rec_state > @old_rec_state THEN 3 ELSE 4 END

IF @check_limits = 1
BEGIN
	EXEC @r = dbo.doc_check_user_limits @user_id, @iso, @amount, @doc_type, @op_type, @new_rec_state OUTPUT, 0
	IF @@ERROR <> 0 OR @r <> 0 RETURN 1
END

IF @new_rec_state > @old_rec_state AND @doc_type BETWEEN 100 AND 110
BEGIN
	SELECT @rec_date = REC_DATE
	FROM dbo.DOC_DETAILS_PLAT
	WHERE DOC_REC_ID = @rec_id

	IF @doc_date_in_doc > @rec_date
	BEGIN
		IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK 
		RAISERROR ('ÓÀÁÖÈÉÓ ÈÀÒÉÙÉ ÀÒ ÛÄÉÞËÄÁÀ ÓÀÁÖÈÉÓ ÌÉÙÄÁÉÓ ÈÀÒÉÙÆÄ ÌÄÔÉ ÉÚÏÓ.', 16, 1)
		RETURN 1
	END

	IF @rec_date > @doc_date
	BEGIN
		IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK 
		RAISERROR ('ÓÀÁÖÈÉÓ ÌÉÙÄÁÉÓ ÈÀÒÉÙÉ ÀÒ ÛÄÉÞËÄÁÀ ÂÀÔÀÒÄÁÉÓ ÈÀÒÉÙÆÄ ÌÄÔÉ ÉÚÏÓ.', 16, 1)
		RETURN 1
	END
END

-- Related parent
IF @new_rec_state < @old_rec_state AND @new_rec_state < 10 AND @parent_rec_id = -2
BEGIN
	IF EXISTS(SELECT * FROM dbo.OPS_0000 (NOLOCK) WHERE RELATION_ID =  @rec_id AND REC_STATE >= 10)
	BEGIN
		IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK 
		RAISERROR ('ÀÒÓÄÁÏÁÓ ÀÅÔÏÒÉÆÄÁÖËÉ ÃÀÌÏÊÉÃÄÁÖËÉ ÓÀÁÖÈÉ.', 16, 1)
		RETURN 1
	END
END


-- Related Child
IF @new_rec_state > @old_rec_state AND @new_rec_state >= 10 AND @relation_id IS NOT NULL
BEGIN
	IF EXISTS(SELECT * FROM dbo.OPS_0000 (NOLOCK) WHERE REC_ID = @relation_id AND PARENT_REC_ID = -2 AND REC_STATE < 10)
	BEGIN
		IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK 
		RAISERROR ('ÓÀÁÖÈÉ, ÒÏÌÄËÆÄÝ ÃÀÌÏÊÉÃÄÁÖËÉÀ ÄÓ ÓÀÁÖÈÉ ÀÒ ÀÒÉÓ ÀÅÔÏÒÉÆÄÁÖËÉ.', 16, 1)
		RETURN 1
	END
END

-- ნაღდი ფულის კონტროლი

IF (@old_rec_state < @new_rec_state) AND (@doc_type BETWEEN 120 AND 149)
BEGIN
	IF @new_rec_state BETWEEN 10 AND 19
	BEGIN
		IF EXISTS(SELECT * FROM dbo.USERS (NOLOCK) WHERE [USER_ID] = @user_id AND (IS_OPERATOR_CASHIER = 1 OR IS_CASHIER = 1))
			SET @cashier = @user_id
	END
	ELSE
		IF @cashier IS NULL
			SET @cashier = @user_id
END

-- წაშლა

DECLARE 
	@cash_op_type tinyint

SET @cash_amount = ABS(@cash_amount)
SET @cash_op_type = dbo.ops_get_cash_op_type (@op_code, @doc_type)

IF @cash_op_type IN (1, 3)
BEGIN
	IF @cash_amount <> $0.00
	BEGIN
		UPDATE dbo.ACCOUNTS_DETAILS
		SET AMOUNT_KAS_DELTA = ISNULL(AMOUNT_KAS_DELTA, $0.000) + @cash_amount
		WHERE ACC_ID = @debit_id
		IF @@ERROR <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 1 END
	END
END

IF @cash_op_type IN (2, 3)
BEGIN
	IF (@old_rec_state >= 10) AND (@cash_amount <> $0.0000)
	BEGIN
		UPDATE dbo.ACCOUNTS_DETAILS
		SET AMOUNT_KAS_DELTA = ISNULL(AMOUNT_KAS_DELTA, $0.000) - @cash_amount
		WHERE ACC_ID = @credit_id
		IF @@ERROR <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 1 END
	END
END

-- დამატება

SET @cash_amount = $0.00

IF @cash_op_type IN (1, 3)
BEGIN
	UPDATE dbo.ACCOUNTS_DETAILS
	SET @cash_amount = CASE WHEN ISNULL(AMOUNT_KAS_DELTA, $0.000) > @amount THEN @amount ELSE ISNULL(AMOUNT_KAS_DELTA, $0.000) END,
		AMOUNT_KAS_DELTA = ISNULL(AMOUNT_KAS_DELTA, $0.000) - @cash_amount
	WHERE ACC_ID = @debit_id AND ISNULL(AMOUNT_KAS_DELTA, $0.000) <> $0.00
	IF @@ERROR <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 1 END
END

IF @cash_op_type IN (2, 3)
BEGIN
	IF @cash_op_type = 2 
		SET @cash_amount = @amount 
	
	IF (@new_rec_state >= 10) AND (@cash_amount <> $0.0000)
	BEGIN
		UPDATE dbo.ACCOUNTS_DETAILS
		SET AMOUNT_KAS_DELTA = ISNULL(AMOUNT_KAS_DELTA, $0.000) + @cash_amount
		WHERE ACC_ID = @credit_id
		IF @@ERROR <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 1 END
	END
END

-- ნაღდი ფულის კონტროლი

UPDATE dbo.OPS_0000
SET UID = UID + 1, REC_STATE = @new_rec_state,
	CASH_AMOUNT = @cash_amount,
	CASHIER = @cashier
WHERE REC_ID = @rec_id 
IF @@ERROR<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 2 END

DECLARE 
	@child_rec_id int,
	@child_doc_type smallint,
	@child_check_saldo bit

IF @parent_rec_id IN (-1, -2)
BEGIN
	DECLARE cc CURSOR LOCAL 
	FOR 
	SELECT REC_ID, DOC_TYPE
	FROM dbo.OPS_0000
	WHERE PARENT_REC_ID = @rec_id

	IF @@ERROR <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 2 END

	OPEN cc
	IF @@ERROR <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 2 END

	FETCH NEXT FROM cc INTO @child_rec_id, @child_doc_type
	
	WHILE @@FETCH_STATUS = 0
	BEGIN
		SET @child_check_saldo = 0
		IF @check_saldo <> 0 AND @child_doc_type = 14 -- Conversion 2nd document
			SET @child_check_saldo = 1

		EXEC @r = dbo.CHANGE_DOC_STATE
			@rec_id = @child_rec_id,	-- საბუთის შიდა №
			@uid = null,				-- საბუთის ბოლოს ცვლილების ნომერი. თუ ნულია, აღარ ვუყურებთ
			@user_id = @user_id,		-- ვინ შლის საბუთს
			@new_rec_state = @new_rec_state,	-- საბუთის ახალი სტატუსი
			@check_saldo = @child_check_saldo		-- შეამოწმოს თუ არა მინ. ნაშთი
		IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 2 END

		FETCH NEXT FROM cc INTO @child_rec_id, @child_doc_type
	END

	CLOSE cc
	DEALLOCATE cc
END

--IF @parent_rec_id = -1
--BEGIN
--	UPDATE dbo.OPS_0000
--	SET UID = UID + 1, REC_STATE = @new_rec_state,
--		CASHIER = CASE WHEN @old_rec_state < 10 AND @new_rec_state >= 10 AND DOC_TYPE BETWEEN 120 AND 149 THEN @user_id ELSE CASHIER END
--    WHERE PARENT_REC_ID = @rec_id
--	IF @@ERROR<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 3 END
--END
--
IF @child_check_saldo <> 0 AND @new_rec_state < 10 AND @old_rec_state >= 10
BEGIN
	IF dbo.acc_get_act_pas(@debit_id) = 2 /* Active account */
	BEGIN
		EXEC @r = dbo.CHECK_SALDO @debit_id, @doc_date, @op_code, @doc_type, @rec_id, 0
		IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 53 END
	END

	IF dbo.acc_get_act_pas(@debit_id) <> 2 /* not Active account */
	BEGIN
		EXEC @r = dbo.CHECK_SALDO @credit_id, @doc_date, @op_code, @doc_type, @rec_id, 0
		IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 53 END
	END
END

EXEC @r = dbo.ON_AFTER_AUTHORIZE_DOC @rec_id, @user_id, @new_rec_state, @old_rec_state
IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 4 END

DECLARE @descrip varchar(100)
SET @descrip = 'ÓÀÁÖÈÉÓ ÀÅÔÏÒÉÆÀÝÉÀ : ' + convert(varchar(1), @old_rec_state / 10 + 1) + ' -> ' + convert(varchar(1), @new_rec_state / 10 + 1)

INSERT INTO dbo.DOC_CHANGES (DOC_REC_ID, [USER_ID], DESCRIP)
VALUES ( @rec_id, @user_id, @descrip)
IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 3 END

IF @internal_transaction=1 AND @@TRANCOUNT>0 
	COMMIT TRAN
RETURN 0
GO
