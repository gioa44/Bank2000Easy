SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[depo_sp_sync_one_depo_b2000]
	@depo_id int,
	@user_id int
AS
SET NOCOUNT ON;

DECLARE
	@r int

DECLARE
	@external_transaction bit

SET @external_transaction = CASE WHEN @@TRANCOUNT > 0 THEN 1 ELSE 0 END;

IF EXISTS(SELECT * FROM dbo.DEPO_OP (NOLOCK) WHERE DEPO_ID = @depo_id AND OP_STATE = 0)
BEGIN
	RAISERROR('ÀÍÀÁÀÒÆÄ ÀÒÓÄÁÏÁÓ ÃÀÖÓÒÖËÄÁÄËÉ ÏÐÄÒÀÝÉÄÁÉ', 16, 1); RETURN (1);
END


DECLARE
	@alarm_state tinyint,
	@alarm_note varchar(255)

SET @alarm_state = 0
SET @alarm_note = NULL;

DECLARE
	@perc_flags int,
	@pfLeaveTrail int,
	@need_trail bit

SET @pfLeaveTrail = 4

DECLARE
	@client_no int,
	@client_type tinyint,
	@date_type tinyint,
	@depo_intrate money,
	@real_intrate decimal(32,12),
	@end_date smalldatetime,
	@agreement_amount money,
	@depo_amount money,
	@intrate_schema int,
	@accumulate_schema_intrate tinyint,
	
	@depo_acc_id int,
	@interest_realize_acc_id int,
	@depo_formula varchar(255)

DECLARE --Op Acumulate
	@depo_accumulate bit,
	@depo_accumulate_schema_intrate int,
	@accumulate_amount money,
	@accumulate_min	money,
	@accumulate_max money,
	@accumulate_max_amount money,
	@accumulate_max_amount_limit money

DECLARE --Op withdraw
	@depo_spend bit,
	@max_spend_amount money,
	@spend_amount money,
	@spend_const_amount money,
	@change_spend_const_amount bit,
	@change_formula bit



SELECT @depo_acc_id = DEPO_ACC_ID, @agreement_amount = AGREEMENT_AMOUNT, @depo_amount = AMOUNT, @client_no = CLIENT_NO,
	@date_type = DATE_TYPE, @end_date = END_DATE, @intrate_schema = INTRATE_SCHEMA,
	@accumulate_schema_intrate = ACCUMULATE_SCHEMA_INTRATE,
	@accumulate_amount = ACCUMULATE_AMOUNT, @accumulate_min = ACCUMULATE_MIN, @accumulate_max = ACCUMULATE_MAX, @accumulate_max_amount = ACCUMULATE_MAX_AMOUNT, @accumulate_max_amount_limit = ACCUMULATE_MAX_AMOUNT_LIMIT,
	@spend_amount = SPEND_AMOUNT, @spend_const_amount = SPEND_CONST_AMOUNT
FROM dbo.DEPO_DEPOSITS (NOLOCK)
WHERE DEPO_ID = @depo_id
IF @@ERROR <> 0 AND @@ROWCOUNT <> 1 BEGIN RAISERROR('ERROR: DEPOSIT NOT FOUND', 16, 1); RETURN (1); END

SELECT @interest_realize_acc_id = CLIENT_ACCOUNT, @perc_flags = PERC_FLAGS
FROM dbo.ACCOUNTS_CRED_PERC (NOLOCK)
WHERE ACC_ID = @depo_acc_id
IF @@ERROR <> 0 AND @@ROWCOUNT <> 1 BEGIN RAISERROR('ERROR: DEPOSIT CRED PERC NOT FOUND', 16, 1); RETURN (1); END

SET @need_trail = (@perc_flags & @pfLeaveTrail)

SELECT @client_type = CLIENT_TYPE
FROM dbo.CLIENTS (NOLOCK)
WHERE CLIENT_NO = @client_no
IF @@ERROR <> 0 AND @@ROWCOUNT <> 1 BEGIN RAISERROR('ERROR: CLIENT NOT FOUND', 16, 1); RETURN (1); END


DECLARE
	@op_id int,
	@op_type smallint,
	@op_date smalldatetime,
	@op_state bit,
	@op_amount money,
	@op_iso char(3),
	@op_data xml,
	@op_acc_data xml,
	@op_alarm_note varchar(255)
DECLARE
	@doc_rec_id int,
	@accrue_doc_rec_id int,
	@doc_date smalldatetime,
	@iso char(3),
	@amount money,
	@op_code char(5),
	@debit_id int,
	@credit_id int,
	@doc_type smallint,
	@descrip varchar(150),
	@parent_rec_id int

SET @op_state = 0

DECLARE c_one_sync CURSOR
FOR	SELECT O.REC_ID, O.DOC_DATE, O.ISO, O.AMOUNT, O.OP_CODE, O.DEBIT_ID, O.CREDIT_ID, O.DOC_TYPE, O.DESCRIP, O.PARENT_REC_ID
FROM dbo.OPS_0000 (NOLOCK) O
	INNER JOIN #docs D ON O.REC_ID = D.REC_ID
WHERE D.DEPO_ID = @depo_id
ORDER BY O.DOC_DATE, O.REC_ID
IF @@ERROR <> 0 BEGIN RAISERROR('ERROR: GET DOCS', 16, 1); RETURN (1); END

OPEN c_one_sync

FETCH NEXT FROM c_one_sync
INTO @doc_rec_id, @doc_date, @iso, @amount, @op_code, @debit_id, @credit_id, @doc_type, @descrip, @parent_rec_id

WHILE @@FETCH_STATUS = 0
BEGIN
	IF (ISNULL(@op_code, '') IN ('*%TR*', '*%RL*')) AND (@need_trail = 1) GOTO skip_

	IF @external_transaction = 0
		BEGIN TRAN;
	
	IF @depo_acc_id = @debit_id
	BEGIN
		IF ISNULL(@op_code, '') = '*%TX*'
			SET @op_type = dbo.depo_fn_const_op_withdraw_interest_tax()
		ELSE
			SET @op_type = dbo.depo_fn_const_op_withdraw()
	END
	ELSE
	IF @depo_acc_id = @credit_id
	BEGIN
		IF ISNULL(@op_code, '') = '*%RL*'
			SET @op_type = dbo.depo_fn_const_op_realize_interest()
		ELSE
			SET @op_type = dbo.depo_fn_const_op_accumulate()
	END

	SET @op_date = @doc_date
	SET @op_amount = @amount
	SET @op_iso = @iso
	SET @op_data = NULL
	SET @op_alarm_note = NULL

	SELECT @depo_amount = AMOUNT, @depo_intrate = INTRATE, @real_intrate = REAL_INTRATE, @depo_formula = FORMULA
	FROM dbo.DEPO_DEPOSITS (NOLOCK)
	WHERE DEPO_ID = @depo_id
	IF @@ERROR <> 0 AND @@ROWCOUNT <> 1 BEGIN CLOSE c_one_sync; DEALLOCATE c_one_sync; IF @external_transaction = 0 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR('ERROR: GET DEPOSIT DATA', 16, 1); RETURN (1); END

	IF @op_type = dbo.depo_fn_const_op_withdraw()
	BEGIN		
		IF @spend_const_amount IS NOT NULL 
		BEGIN
			IF (@depo_amount - @op_amount) < @spend_amount
			BEGIN
				SET @alarm_state = 0xFF
				SET @op_alarm_note = 'ÈÀÍáÀ ÌÄÔÉÀ ÃÀÓÀÛÅÄÁ ÌÍÉÛÅÍÄËÏÁÀÆÄ!'
				SET @alarm_note = @op_alarm_note
			END
			
			SET @max_spend_amount = @depo_amount - @spend_amount

			IF (@depo_amount - @op_amount) < @spend_const_amount
				SET @change_spend_const_amount = 1
			ELSE SET @change_spend_const_amount = 0
			
			IF (@depo_spend = 1) AND (@depo_accumulate = 1) AND (@depo_accumulate_schema_intrate = 4) AND((@depo_amount - @op_amount) < @spend_const_amount )
				SET @change_formula = 1
			ELSE
				SET @change_formula = 0
			
			SET @op_data =
				(SELECT
					@credit_id AS DEPO_REALIZE_ACC_ID,
					@depo_amount AS PREV_AMOUNT,
					@max_spend_amount AS MAX_SPEND_AMOUNT,
					@change_spend_const_amount AS CHANGE_SPEND_CONST_AMOUNT, 
					@spend_const_amount AS PREV_SPEND_CONST_AMOUNT,
					@change_formula AS CHANGE_FORMULA,
					@depo_formula AS PREV_FORMULA
			FOR XML RAW, TYPE)
		END
		ELSE
		BEGIN
			SET @op_data =
				(SELECT
					@credit_id AS DEPO_REALIZE_ACC_ID,
					@depo_amount AS PREV_AMOUNT,
					@max_spend_amount AS MAX_SPEND_AMOUNT,
					CONVERT(bit, 0) AS CHANGE_SPEND_CONST_AMOUNT,
					CONVERT(bit, 0) AS CHANGE_FORMULA
			FOR XML RAW, TYPE)
		END
	END
	ELSE
	IF @op_type = dbo.depo_fn_const_op_withdraw_interest_tax()
	BEGIN
		SET @op_data =
			(SELECT
				@credit_id AS DEPO_REALIZE_ACC_ID,
				@depo_amount AS DEPO_AMOUNT
		FOR XML RAW, TYPE)	
	END
	IF @op_type = dbo.depo_fn_const_op_accumulate()
	BEGIN
		IF @accumulate_amount IS NULL
		BEGIN
			IF (@accumulate_min IS NOT NULL) AND (@op_amount < @accumulate_min)
			BEGIN
				SET @alarm_state = 0xFF
				SET @op_alarm_note = 'ÈÀÍáÀ ÍÀÊËÄÁÉÀ áÄËÛÄÊÒÖËÄÁÉÈ ÂÀÍÓÀÆÙÅÒÖËÉ ÃÀÂÒÏÅÄÁÉÓ ÌÉÍÉÌÀËÖÒ ÌÍÉÛÅÍÄËÏÁÀÆÄ!'
				SET @alarm_note = @op_alarm_note
			END
			IF (@accumulate_max IS NOT NULL) AND (@op_amount > @accumulate_max)
			BEGIN
				SET @alarm_state = 0xFF
				SET @op_alarm_note = 'ÈÀÍáÀ ÌÄÔÉÀ áÄËÛÄÊÒÖËÄÁÉÈ ÂÀÍÓÀÆÙÅÒÖËÉ ÃÀÂÒÏÅÄÁÉÓ ÌÀØÓÉÌÀËÖÒ ÌÍÉÛÅÍÄËÏÁÀÆÄ!'
				SET @alarm_note = @op_alarm_note
			END
		END
		ELSE
		BEGIN
			IF @accumulate_amount <> @op_amount
			BEGIN
				SET @alarm_state = 0xFF
				SET @op_alarm_note = 'ÈÀÍáÀ ÀÒ ÛÄÓÀÁÀÌÄÁÀ áÄËÛÄÊÒÖËÄÁÉÈ ÂÀÍÓÀÆÙÅÒÖËÉ ÃÀÂÒÏÅÄÁÉÓ ÌÍÉÛÅÍÄËÏÁÀÓ!'
				SET @alarm_note = @op_alarm_note
			END
		END

		IF (@accumulate_max_amount IS NOT NULL) AND (@depo_amount + @op_amount > @accumulate_max_amount)
		BEGIN
			SET @alarm_state = 0xFF
			SET @op_alarm_note = 'ÃÀÂÒÏÅÄÁÉÈ ÌÉÙÄÁÖËÉ ÈÀÍáÀ ÌÄÔÉÀ áÄËÛÄÊÒÖËÄÁÉÈ ÂÀÍÓÀÆÙÅÒÖËÉ ÌÀØÉÌÀËÖÒ ÃÀÂÒÏÅÄÁÀÆÄ!'
			SET @alarm_note = @op_alarm_note
		END

		IF (@accumulate_max_amount_limit IS NOT NULL) AND
			((@depo_amount + @op_amount) > ROUND(@agreement_amount * @accumulate_max_amount_limit / $100.00, 2))
		BEGIN
			SET @alarm_state = 0xFF
			SET @op_alarm_note = 'ÃÀÂÒÏÅÄÁÉÈ ÌÉÙÄÁÖËÉ ÈÀÍáÀ ÌÄÔÉÀ áÄËÛÄÊÒÖËÄÁÉÈ ÂÀÍÓÀÆÙÅÒÖËÉ ÌÀØÉÌÀËÖÒ ÃÀÂÒÏÅÄÁÀÆÄ!'
			SET @alarm_note = @op_alarm_note
		END

		DECLARE
			@period int,
			@intrate money,
			@change_interest int

		SET @change_interest = CASE WHEN @accumulate_schema_intrate = 2 THEN 1 ELSE 0 END
		
		IF @change_interest = 1
		BEGIN
			EXEC @r = dbo.depo_sp_get_deposit_accumulate_intrate
				@depo_id = @depo_id,
				@op_date = @op_date,
				@date_type = @date_type,
				@end_date = @end_date,
				@iso = @op_iso,
				@intrate_schema = @intrate_schema,
				@period = @period OUTPUT,
				@intrate = @intrate OUTPUT,
				@return_row = 0
			IF @@ERROR <> 0 AND @r = 0 BEGIN CLOSE c_one_sync; DEALLOCATE c_one_sync; IF @external_transaction = 0 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR('ERROR: GET NEW INTRATE!', 16, 1); RETURN (1); END
		END


		IF (@change_interest = 1) AND (ISNULL(@intrate, $0.00) <> ISNULL(@depo_intrate, $0.00))
			SET @change_formula = 1
		ELSE
		BEGIN
			SET @change_formula = 0
			SET @depo_formula = NULL
		END

		SET @op_data =
			(SELECT
				 @client_type AS CLIENT_TYPE,
				 @debit_id AS DEPO_FILL_ACC_ID,
				 @date_type AS DATE_TYPE,
				 @depo_intrate AS DEPO_INTRATE,
				 @real_intrate AS REAL_INTRATE,
				 @end_date AS END_DATE,
				 @period AS PERIOD,
				 @intrate AS INTRATE,
				 @depo_amount AS DEPO_AMOUNT,
				 @change_formula AS CHANGE_FORMULA,
				 @depo_formula AS PREV_FORMULA
		FOR XML RAW, TYPE)	
	END
	ELSE
	IF @op_type = dbo.depo_fn_const_op_realize_interest()
	BEGIN
		SET @op_data =
			(SELECT
				@debit_id AS DEPO_FILL_ACC_ID,
				@depo_amount AS DEPO_AMOUNT
		FOR XML RAW, TYPE)	
	END

	IF @doc_type = 14
		SET @doc_rec_id = @parent_rec_id
		
	INSERT INTO dbo.DEPO_OP(DEPO_ID, OP_DATE, OP_TYPE, OP_STATE, AMOUNT, ISO, OP_DATA, OP_NOTE, ALARM_NOTE, [OWNER], BY_PROCESSING, DOC_REC_ID)
	VALUES(@depo_id, @op_date, @op_type, @op_state, @op_amount, @op_iso, @op_data, @descrip, @op_alarm_note, @user_id, 1, @doc_rec_id)

	IF @@ERROR <> 0 AND @@ROWCOUNT <> 1 BEGIN CLOSE c_one_sync; DEALLOCATE c_one_sync; IF @external_transaction = 0 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR('ERROR: INSERT OP DATA!', 16, 1); RETURN (1); END

	SET @op_id = SCOPE_IDENTITY()

	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN CLOSE c_one_sync; DEALLOCATE c_one_sync; IF @external_transaction = 0 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('ERROR: DOCUMENT NOT FOUND!', 16, 1); RETURN (1); END

	EXEC @r = dbo.depo_sp_exec_op @doc_rec_id = @doc_rec_id OUTPUT, @accrue_doc_rec_id = @accrue_doc_rec_id OUTPUT, @op_id = @op_id, @user_id = @user_id
    IF @@ERROR <> 0 OR @r <> 0 BEGIN CLOSE c_one_sync; DEALLOCATE c_one_sync; IF @external_transaction = 0 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('ÛÄÝÃÏÌÀ ÏÐÄÒÀÝÉÉÓ ÛÄÓÒÖËÄÁÉÓ ÃÒÏÓ!', 16, 1); RETURN (1); END

	IF @external_transaction = 0 AND @@TRANCOUNT > 0
		COMMIT TRAN;
skip_:
	FETCH NEXT FROM c_one_sync
	INTO @doc_rec_id, @doc_date, @iso, @amount, @op_code, @debit_id, @credit_id, @doc_type, @descrip, @parent_rec_id
END

CLOSE c_one_sync
DEALLOCATE c_one_sync
IF @@ERROR <> 0 BEGIN RAISERROR('ERROR: EXEC SYNC!', 16, 1); RETURN (1); END

IF @alarm_state <> 0
BEGIN
	UPDATE dbo.DEPO_DEPOSITS
	SET ROW_VERSION = ROW_VERSION + 1, ALARM_STATE = @alarm_state, ALARM_NOTE = @alarm_note
	WHERE DEPO_ID = @depo_id
	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN RAISERROR ('ERROR: UPDATE DEPOSIT DATA!', 16, 1); RETURN (1); END
END

RETURN 0

GO
