SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[DELETE_DOC]
	@rec_id int,				-- საბუთის შიდა №
	@uid int = null,			-- საბუთის ბოლოს ცვლილების ნომერი. თუ ნულია, აღარ ვუყურებთ
	@user_id int,				-- ვინ შლის საბუთს

	-- სხვა პარამეტრები

	@check_saldo bit = 1,		-- შეამოწმოს თუ არა მინ. ნაშთი
	@dont_check_up bit = 0,		-- შეამოწმოს თუ არა კომ. გადასახადები
	@check_limits bit = 1,		-- შეამოწმოს თუ არა ლიმიტები
	@info bit = 0,				-- რეალურად გატარდეს, თუ მხოლოდ ინფორმაციაა
	@lat bit = 0				-- გამოიტანოს თუ არა შეცდომები ინგლისურად
AS

SET NOCOUNT ON

IF (@user_id >= 10) AND (SELECT VALS FROM dbo.INI_INT (NOLOCK) WHERE IDS = 'SERVER_STATE') <> 0
BEGIN
	RAISERROR ('ÌÉÌÃÉÍÀÒÄÏÁÓ ÃÙÉÓ ÃÀáÖÒÅÀ/ÂÀáÓÍÀ. ÂÈáÏÅÈ ÃÀÉÝÀÃÏÈ', 16, 1)	
	RETURN 1
END

DECLARE 
	@r int,
	@extra_params xml

DECLARE 
	@debit_id int,
	@credit_id int,
	@doc_date smalldatetime,
	@op_code TOPCODE,
	@amount money,
	@iso TISO,
	@parent_rec_id int,
	@relation_id int,
	@cash_amount money,
	@rec_state tinyint,
	@doc_type smallint,
	@doc_num int,
	@chk_serie varchar(4),
	@channel_id int,
	@owner int,
	@dept_no int,
	@account_extra TACCOUNT,
	@doc_date_in_doc smalldatetime,
	@prod_id int,
	@foreign_id int,
	@cashier int
	
SELECT @iso = ISO, @debit_id = DEBIT_ID, @credit_id = CREDIT_ID, @amount = AMOUNT, @op_code = OP_CODE, 
	@owner = [OWNER], @dept_no = DEPT_NO, @doc_num = DOC_NUM, @account_extra = ACCOUNT_EXTRA, @prod_id = PROD_ID, @foreign_id = FOREIGN_ID, @channel_id = CHANNEL_ID,
	@rec_state = REC_STATE, @parent_rec_id = PARENT_REC_ID, @doc_type = DOC_TYPE, @cash_amount = ISNULL(CASH_AMOUNT, $0.00),
	@doc_date = DOC_DATE, @doc_date_in_doc = DOC_DATE_IN_DOC, @relation_id = RELATION_ID, @cashier = CASHIER,
	@chk_serie = CHK_SERIE 
FROM dbo.OPS_0000 WITH (ROWLOCK, UPDLOCK)
WHERE REC_ID = @rec_id AND (@uid IS NULL OR UID = @uid)

IF @@ROWCOUNT = 0
BEGIN
  IF @lat = 0 
       RAISERROR ('<ERR>ÓÀÁÖÈÉ ÀÒ ÌÏÉÞÄÁÍÀ, ÀÍ ÛÄÝÅËÉËÉÀ ÓáÅÀ ÌÏÌáÌÀÒÄÁËÉÓ ÌÉÄÒ</ERR>',16,1)
  ELSE RAISERROR ('<ERR>Cannot find document or changed by another user</ERR>',16,1)
  RETURN 3
END

SET @extra_params = NULL

EXEC @r = dbo.ON_USER_BEFORE_DELETE_DOC @rec_id, @uid, @user_id OUTPUT,	@owner, 
	@parent_rec_id,	@dept_no, @doc_type, @doc_date, @doc_date_in_doc, @debit_id, @credit_id, @iso, @amount, @cash_amount,
	@op_code, @doc_num,	@account_extra, @prod_id, @foreign_id, @channel_id,	@relation_id, @cashier, 
	@check_saldo OUTPUT, @info, @lat, @extra_params OUTPUT
IF @@ERROR <> 0 OR @r <> 0 RETURN 1

IF @doc_date < dbo.bank_work_date () AND dbo.sys_has_right(@user_id, 100, 8) = 0
BEGIN
  IF @lat = 0 
       RAISERROR ('<ERR>ÞÅÄËÉ ÓÀÌÖÛÀÏ ÈÀÒÉÙÉÈ ÓÀÁÖÈÉÓ ßÀÛËÀ ÀÒ ÛÄÉÞËÄÁÀ</ERR>',16,1)
  ELSE RAISERROR ('<ERR>Cannot delete documets with an old working date</ERR>',16,1)
  RETURN 4
END

IF @check_limits = 1
BEGIN
	EXEC @r = dbo.doc_check_user_limits @user_id, @iso, @amount, @doc_type, 2, @rec_state OUTPUT, @lat
	IF @@ERROR <> 0 OR @r <> 0 RETURN 1
END


DECLARE @internal_transaction bit
SET @internal_transaction = 0
IF @@TRANCOUNT = 0
BEGIN
	BEGIN TRAN
	SET @internal_transaction = 1
END

IF @channel_id = 778		-- Utility Payment
	EXEC @r = dbo.ON_BEFORE_DELETE_DOC_UP @rec_id, @user_id, @check_saldo, @dont_check_up, @info, @lat
ELSE
IF @doc_type IN (30, 32)	-- Accruals
	EXEC @r = dbo.ON_BEFORE_DELETE_DOC_ACCRUAL @rec_id, @user_id,@check_saldo, @info, @lat
ELSE
IF @doc_type IN (40, 42, 240) -- Loan Accruals
	EXEC @r = dbo.ON_BEFORE_DELETE_DOC_LOAN_ACCRUAL @rec_id, @user_id, @check_saldo, @info, @lat

IF @doc_type IN (45, 245) -- Loan Op Docs
	EXEC @r = dbo.ON_BEFORE_DELETE_DOC_LOAN_OPS @rec_id, @user_id, @check_saldo, @info, @lat

IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 2 END

IF @op_code = '*BLK1' -- ბლოკირებული თანხიდან გატარებული საბუთი
BEGIN
	EXEC @r = dbo.acc_block_revert @acc_id = @debit_id,	@user_id = @user_id, @doc_rec_id = @rec_id
	IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 2 END
END

--  0: არ ყავს ზემდგომი, არ  ყავს შვილი
-- -1: ყავს შვილი (იშლება ერთად, ავტორიზდება ერთად)
-- -2: ყავს შვილი (იშლება ერთად, ავტორიზდება ცალ-ცალკე)
-- -3: ყავს შვილი (იშლება ცალ-ცალკე, ავტორიზდება ცალ-ცალკე)
DECLARE 
	@child_rec_id int,
	@child_doc_type smallint,
	@child_check_saldo bit

IF @parent_rec_id = -2 
BEGIN
	DECLARE @child_rec_state int
	DECLARE cc2 CURSOR LOCAL
	FOR 
	SELECT REC_ID, REC_STATE
	FROM dbo.OPS_0000
	WHERE RELATION_ID = @rec_id

	IF @@ERROR <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 2 END

	OPEN cc2
	IF @@ERROR <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 2 END

	FETCH NEXT FROM cc2 INTO @child_rec_id, @child_rec_state
	
	WHILE @@FETCH_STATUS = 0
	BEGIN
		IF @child_rec_state <> 0
		BEGIN
			IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK;
			IF @lat = 0 
				RAISERROR ('<ERR>ÃÀÌÏÊÉÃÄÁÖËÉ ÓÀÁÖÈÄÁÉ ÀÅÔÏÒÉÆÄÁÖËÉÀ!</ERR>',16,1)
			ELSE RAISERROR ('<ERR>Depended documents are autorized </ERR>',16,1)
			RETURN 9
		END

		EXEC @r = dbo.DELETE_DOC
			@rec_id = @child_rec_id,	-- საბუთის შიდა №
			@uid = null,				-- საბუთის ბოლოს ცვლილების ნომერი. თუ ნულია, აღარ ვუყურებთ
			@user_id = @user_id,		-- ვინ შლის საბუთს
			@check_saldo = 0,			-- შეამოწმოს თუ არა მინ. ნაშთი
			@dont_check_up = @dont_check_up,	-- შეამოწმოს თუ არა კომ. გადასახადები
			@info = @info,				-- რეალურად გატარდეს, თუ მხოლოდ ინფორმაციაა
			@lat = @lat					-- გამოიტანოს თუ არა შეცდომები ინგლისურად
		IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 2 END

		FETCH NEXT FROM cc2 INTO @child_rec_id, @child_rec_state
	END

	CLOSE cc2
	DEALLOCATE cc2
END

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

		EXEC @r = dbo.DELETE_DOC
			@rec_id = @child_rec_id,	-- საბუთის შიდა №
			@uid = null,				-- საბუთის ბოლოს ცვლილების ნომერი. თუ ნულია, აღარ ვუყურებთ
			@user_id = @user_id,		-- ვინ შლის საბუთს
			@check_saldo = @child_check_saldo,			-- შეამოწმოს თუ არა მინ. ნაშთი
			@dont_check_up = @dont_check_up,	-- შეამოწმოს თუ არა კომ. გადასახადები
			@info = @info,				-- რეალურად გატარდეს, თუ მხოლოდ ინფორმაციაა
			@lat = @lat					-- გამოიტანოს თუ არა შეცდომები ინგლისურად
		IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 2 END

		FETCH NEXT FROM cc INTO @child_rec_id, @child_doc_type
	END

	CLOSE cc
	DEALLOCATE cc
END

IF @doc_type BETWEEN 140 AND 149	-- სალაროს ჩეკი
BEGIN
	DECLARE @chk_id int, @chk_num int

	SET @chk_num = @doc_num

	SELECT @chk_id = CHK_ID 
	FROM dbo.CHK_BOOKS (NOLOCK)
	WHERE CHK_SERIE = @chk_serie AND CHK_NUM_FIRST <= @chk_num AND CHK_NUM_FIRST + CHK_COUNT > @chk_num
    IF @@ROWCOUNT = 0 
	BEGIN 
		IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK;
		RAISERROR('OLD CHECK BOOK NOT FOUND',16,1) 
		RETURN 5
	END

	IF NOT EXISTS(
		SELECT * 
		FROM dbo.OPS_0000 D (NOLOCK)
		WHERE D.DOC_DATE = @doc_date AND D.CHK_SERIE = @chk_serie AND D.DOC_NUM = @chk_num)
    BEGIN
        UPDATE dbo.CHK_BOOK_DETAILS 
		SET CHK_STATE = 0, /*CHK_USE_DATE = @doc_date,*/ [USER_ID] = @user_id
		WHERE CHK_ID = @chk_id AND CHK_NUM = @chk_num
		IF @@ERROR <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 7 END
        
		INSERT INTO dbo.CHK_BOOK_DET_CHANGES (CHK_ID,CHK_NUM,[USER_ID],DESCRIP,DOC_REC_ID) 
		VALUES (@chk_id,@chk_num,@user_id,'ÂÀÌÏÖÚÄÍÄÁÄËÉ',@rec_id);
		IF @@ERROR <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 8 END
	END
END

INSERT INTO dbo.DEL_DOCS (REC_ID,DOC_DATE,ISO,AMOUNT,DEBIT,CREDIT,BRANCH_ID,DEPT_NO)
SELECT D.REC_ID,D.DOC_DATE,D.ISO,D.AMOUNT,dbo.acc_get_account(D.DEBIT_ID),dbo.acc_get_account(D.CREDIT_ID),D.BRANCH_ID,D.DEPT_NO
FROM dbo.OPS_0000 D
WHERE REC_ID = @rec_id
IF @@ERROR <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 3 END

INSERT INTO dbo.DEL_DOC_CHANGES
SELECT * 
FROM dbo.DOC_CHANGES (NOLOCK)
WHERE DOC_REC_ID = @rec_id
IF @@ERROR <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 4 END

INSERT INTO dbo.DEL_DOC_CHANGES (DOC_REC_ID,REC_ID,[USER_ID],DESCRIP) 
VALUES (@rec_id, -1, @user_id, 'ÓÀÁÖÈÉÓ ßÀÛËÀ')
IF @@ERROR <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 5 END

DELETE
FROM dbo.OPS_0000
WHERE REC_ID = @rec_id
IF @@ERROR <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 6 END

-- ნაღდი ფულის კონტროლი

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
	IF (@rec_state >= 10) AND (@cash_amount <> $0.0000)
	BEGIN
		UPDATE dbo.ACCOUNTS_DETAILS
		SET AMOUNT_KAS_DELTA = ISNULL(AMOUNT_KAS_DELTA, $0.000) - @cash_amount
		WHERE ACC_ID = @credit_id
		IF @@ERROR <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 1 END
	END
END


IF @check_saldo <> 0 AND NOT @doc_type IN (30, 32)	-- Accruals
BEGIN
	IF dbo.acc_get_act_pas(@debit_id) = 2 /* Active account */
	BEGIN
		EXEC @r = dbo.CHECK_SALDO @debit_id, @doc_date, @op_code, @doc_type, @rec_id, @lat
		IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 53 END
	END

	IF dbo.acc_get_act_pas(@credit_id) <> 2 /* not Active account */
	BEGIN
		EXEC @r = dbo.CHECK_SALDO @credit_id, @doc_date, @op_code, @doc_type, @rec_id, @lat
		IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 53 END
	END
END

EXEC @r = dbo.ON_USER_AFTER_DELETE_DOC
	@rec_id = @rec_id,
	@uid = @uid,
	@user_id = @user_id,
	@check_saldo = @check_saldo,
	@info = @info,
	@lat = @lat,
	@extra_params = @extra_params
IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 1 END

IF @internal_transaction=1 AND @@TRANCOUNT>0 
	COMMIT TRAN

RETURN @@ERROR

GO
