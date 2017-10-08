SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[depo_sp_process_deposits]
	@user_id int,
	@dept_no int,
	@doc_date smalldatetime,
	@calc_date smalldatetime,
	@acc_id int,
	@depo_id int
AS

DECLARE
	@r int
DECLARE
	@state tinyint,	
	@prod_id int,
	@amount money,
	@iso char(3),
	@start_date smalldatetime,
	@last_renew_date smalldatetime,
	@end_date smalldatetime,
	@revision_schema int,
	@revision_type tinyint,
	@revision_count smallint,
	@revision_count_type tinyint,
	@revision_grace_items int,
	@revision_grace_date_type tinyint,
	@depo_realize_acc_id int
	
DECLARE
	@calc_amount money,
	@last_move_date smalldatetime,
	@total_calc_amount money,
	@total_payed_amount money
	
DECLARE
	@bonus_schema int,
	@analyze_schema int,
	@analyze_schema_annul bit
	
DECLARE
	@bonus_schema_proc varchar(128),
	@analyze_schema_proc varchar(128),
	@bonus_amount money,
	@deposit_default bit,
	@remark varchar(255)
	
DECLARE
	@depo_op_id int,
	@depo_op_type smallint,
	@op_amount money,
	@op_data XML,
	@depo_op_doc_rec_id int,
	@accrue_doc_rec_id int

DECLARE
	@sql nvarchar(2000)
	
SELECT @state = [STATE], @prod_id = PROD_ID, @amount = AMOUNT, @iso = ISO, @start_date = [START_DATE], @end_date = END_DATE, @last_renew_date = LAST_RENEW_DATE,
	@revision_schema = REVISION_SCHEMA,	@revision_type = REVISION_TYPE,	@revision_count = REVISION_COUNT, @revision_count_type = REVISION_COUNT_TYPE,
	@revision_grace_items = REVISION_GRACE_ITEMS, @revision_grace_date_type = REVISION_GRACE_DATE_TYPE,
	@depo_realize_acc_id = DEPO_REALIZE_ACC_ID,
	@deposit_default = DEPOSIT_DEFAULT
FROM dbo.DEPO_DEPOSITS (NOLOCK)
WHERE DEPO_ID = @depo_id

IF @state <= 40 OR @state >= 240
	GOTO _skip
	
SELECT @bonus_schema = BONUS_SCHEMA, @analyze_schema = ANALYZE_SCHEMA, @analyze_schema_annul = ANALYZE_SCHEMA_ANNUL
FROM dbo.DEPO_PRODUCT (NOLOCK) 
WHERE PROD_ID = @prod_id


SELECT @calc_amount = ISNULL(CALC_AMOUNT, $0.00), @last_move_date = LAST_MOVE_DATE,
	@total_calc_amount = ISNULL(TOTAL_CALC_AMOUNT, $0.00), @total_payed_amount = ISNULL(TOTAL_PAYED_AMOUNT, $0.00)
FROM dbo.ACCOUNTS_CRED_PERC (NOLOCK)
WHERE ACC_ID = @acc_id

/* Deposit Revision */
IF ISNULL(@revision_type, 0) IN (1, 2)
BEGIN
	EXEC @r = dbo.depo_sp_depo_revision
		@date = @calc_date,
		@depo_id = @depo_id,
		@prod_id = @prod_id,
		@start_date = @start_date,
		@end_date = @end_date,
		@last_renew_date = @last_renew_date,
		@revision_schema = @revision_schema,
		@revision_type = @revision_type,
		@revision_count = @revision_count,
		@revision_count_type = @revision_count_type,
		@revision_grace_items = @revision_grace_items,
		@revision_grace_date_type = @revision_grace_date_type,
		@user_id = @user_id
	IF @@ERROR <> 0 OR @r <> 0
		RETURN 103
END
/* End of Deposit Revision */

/* Deposit Analyze */
IF (@analyze_schema IS NOT NULL)
BEGIN
	IF (@deposit_default = 0)
	BEGIN
		SET @remark = ''
		
		SELECT @analyze_schema_proc = PROCEDURE_NAME
		FROM dbo.DEPO_PRODUCT_ANALYZE_SCHEMA (NOLOCK) 
		WHERE [SCHEMA_ID] = @analyze_schema

		SET @sql = 'EXEC @r=' + @analyze_schema_proc +
			' @depo_id=@depo_id,@user_id=@user_id,@dept_no=@dept_no,@analyze_date=@calc_date,@deposit_default=@deposit_default OUTPUT, @remark=@remark OUTPUT'
		EXEC sp_executesql @sql, N'@r int OUTPUT, @depo_id int,@user_id int,@dept_no int,@calc_date smalldatetime,@deposit_default bit OUTPUT,@remark varchar(255) OUTPUT',
			@r OUTPUT, @depo_id, @user_id, @dept_no, @calc_date, @deposit_default OUTPUT, @remark OUTPUT

		IF @@ERROR <> 0 OR @r <> 0
			RETURN 105
		
		IF (@deposit_default = 1)
		BEGIN

			SET @depo_op_type = dbo.depo_fn_const_op_mark2default()
			SET @op_data =
				(SELECT
					@deposit_default AS DEPOSIT_DEFAULT,
					@remark AS REMARK
				FOR XML RAW, TYPE)
				
			INSERT INTO dbo.DEPO_OP WITH (UPDLOCK)
				(DEPO_ID, OP_DATE, OP_TYPE, OP_STATE, AMOUNT, ISO, OP_DATA, [OWNER])
			VALUES
				(@depo_id, @doc_date, @depo_op_type, 0, NULL, NULL, @op_data, @user_id)
			IF @@ERROR <> 0
				RETURN 105
			
			SET @depo_op_id = SCOPE_IDENTITY()

			EXEC @r = dbo.depo_sp_add_op_action
				@op_id = @depo_op_id,
				@op_type = @depo_op_type,	
				@depo_id = @depo_id,
				@user_id = @user_id

			IF @@ERROR <> 0 OR @r <> 0
				RETURN 105
			
			SET @depo_op_doc_rec_id = NULL
			SET @accrue_doc_rec_id = NULL
		
			EXEC @r = dbo.depo_sp_add_op_accounting
				@doc_rec_id = @depo_op_doc_rec_id OUTPUT,
				@accrue_doc_rec_id = @accrue_doc_rec_id OUTPUT,
				@op_id = @depo_op_id,
				@user_id = @user_id

			IF @@ERROR <> 0 OR @r <> 0
				RETURN 105

			IF (@depo_op_doc_rec_id IS NOT NULL) OR (@accrue_doc_rec_id IS NOT NULL)
			BEGIN
				UPDATE dbo.DEPO_OP WITH (UPDLOCK)
				SET DOC_REC_ID = CASE WHEN @depo_op_doc_rec_id IS NOT NULL THEN @depo_op_doc_rec_id ELSE DOC_REC_ID END,
					ACCRUE_DOC_REC_ID = CASE WHEN @accrue_doc_rec_id IS NOT NULL THEN @accrue_doc_rec_id ELSE ACCRUE_DOC_REC_ID END
				WHERE OP_ID = @depo_op_id
				IF @@ERROR <> 0 OR @@ROWCOUNT <> 1
					RETURN 105
			END
 
			EXEC @r = dbo.depo_sp_exec_op @doc_rec_id = @depo_op_doc_rec_id OUTPUT, @accrue_doc_rec_id = @accrue_doc_rec_id OUTPUT, @op_id = @depo_op_id, @user_id = @user_id
			IF @@ERROR <> 0 OR @r <> 0
				RETURN 105

			EXEC @r = dbo.depo_sp_mark_default_on_user
				@depo_id,
				@calc_date,
				@user_id
			IF @@ERROR <> 0 OR @r <> 0
				RETURN 105

		END
	END
	
	IF (@deposit_default = 1) AND (@analyze_schema_annul = 1)
	BEGIN
		DECLARE
			@annul_amount money,
			@annul_intrate money
	
		SET @depo_op_type = dbo.depo_fn_const_op_annulment()
		
		SET @op_amount = - dbo.acc_get_balance(@acc_id, @calc_date, 0, 0, 1)
		
		EXEC @r = dbo.depo_sp_calc_annul_amount		
			@depo_id = @depo_id,
			@user_id = @user_id,
			@dept_no = @dept_no,
			@annul_date = @calc_date,
			@annul_amount = @annul_amount OUTPUT,
			@annul_intrate = @annul_intrate OUTPUT,
			@show_result = 0
		
		IF @@ERROR <> 0 OR @r <> 0
			RETURN 105
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
				0 AS ACC_ARC_REC_ID
			FOR XML RAW, TYPE)
		
		INSERT INTO dbo.DEPO_OP WITH (UPDLOCK)
			(DEPO_ID, OP_DATE, OP_TYPE, OP_STATE, AMOUNT, ISO, OP_DATA, [OWNER])
		VALUES
			(@depo_id, @doc_date, @depo_op_type, 0, @annul_amount, @iso, @op_data, @user_id)
		IF @@ERROR <> 0
			RETURN 105
		
		SET @depo_op_id = SCOPE_IDENTITY()

		EXEC @r = dbo.depo_sp_add_op_action
			@op_id = @depo_op_id,
			@op_type = @depo_op_type,	
			@depo_id = @depo_id,
			@user_id = @user_id

		IF @@ERROR <> 0 OR @r <> 0
			RETURN 105
		
		SET @depo_op_doc_rec_id = NULL
		SET @accrue_doc_rec_id = NULL
		
		EXEC @r = dbo.depo_sp_add_op_accounting
			@doc_rec_id = @depo_op_doc_rec_id OUTPUT,
			@accrue_doc_rec_id = @accrue_doc_rec_id OUTPUT,
			@op_id = @depo_op_id,
			@user_id = @user_id

		IF @@ERROR <> 0 OR @r <> 0
			RETURN 105

		IF (@depo_op_doc_rec_id IS NOT NULL) OR (@accrue_doc_rec_id IS NOT NULL)
		BEGIN
			UPDATE dbo.DEPO_OP WITH (UPDLOCK)
			SET DOC_REC_ID = CASE WHEN @depo_op_doc_rec_id IS NOT NULL THEN @depo_op_doc_rec_id ELSE DOC_REC_ID END,
				ACCRUE_DOC_REC_ID = CASE WHEN @accrue_doc_rec_id IS NOT NULL THEN @accrue_doc_rec_id ELSE ACCRUE_DOC_REC_ID END
			WHERE OP_ID = @depo_op_id
			IF @@ERROR <> 0 OR @@ROWCOUNT <> 1
				RETURN 105
		END

		EXEC @r = dbo.depo_sp_exec_op @doc_rec_id = @depo_op_doc_rec_id OUTPUT, @accrue_doc_rec_id = @accrue_doc_rec_id OUTPUT, @op_id = @depo_op_id, @user_id = @user_id
		IF @@ERROR <> 0 OR @r <> 0
			RETURN 105

	END
END
/* End of Deposit Analyze */

/* Depsit Bonus */
IF (@bonus_schema IS NOT NULL)
BEGIN
	SET @remark = ''
	
	SELECT @bonus_schema_proc = PROCEDURE_NAME
	FROM dbo.DEPO_PRODUCT_BONUS_SCHEMA (NOLOCK) 
	WHERE [SCHEMA_ID] = @bonus_schema
	
	SET @sql = 'EXEC @r=' + @bonus_schema_proc +
		' @depo_id=@depo_id,@user_id=@user_id,@dept_no=@dept_no,@analyze_date=@calc_date,@accrue_amount=@bonus_amount OUTPUT, @remark=@remark OUTPUT'
	EXEC sp_executesql @sql, N'@r int OUTPUT, @depo_id int,@user_id int,@dept_no int,@calc_date smalldatetime,@bonus_amount money OUTPUT,@remark varchar(255) OUTPUT',
		@r OUTPUT, @depo_id, @user_id, @dept_no, @calc_date, @bonus_amount OUTPUT, @remark OUTPUT
	
	IF @@ERROR <> 0 OR @r <> 0
		RETURN 106

	IF (ISNULL(@bonus_amount, $0.00) > $0.00)
	BEGIN
		SET @depo_op_type = dbo.depo_fn_const_op_bonus()
		SET @op_data =
			(SELECT
				@bonus_amount AS BONUS_AMOUNT,
				@remark AS REMARK
			FOR XML RAW, TYPE)
			
		INSERT INTO dbo.DEPO_OP WITH (UPDLOCK)
			(DEPO_ID, OP_DATE, OP_TYPE, OP_STATE, AMOUNT, ISO, OP_DATA, [OWNER])
		VALUES
			(@depo_id, @doc_date, @depo_op_type, 0, @bonus_amount, @iso, @op_data, @user_id)
		IF @@ERROR <> 0
			RETURN 106
		
		SET @depo_op_id = SCOPE_IDENTITY()

		EXEC @r = dbo.depo_sp_add_op_action
			@op_id = @depo_op_id,
			@op_type = @depo_op_type,	
			@depo_id = @depo_id,
			@user_id = @user_id

		IF @@ERROR <> 0 OR @r <> 0
			RETURN 106
		
		SET @depo_op_doc_rec_id = NULL
		SET @accrue_doc_rec_id = NULL
		
		EXEC @r = dbo.depo_sp_add_op_accounting
			@doc_rec_id = @depo_op_doc_rec_id OUTPUT,
			@accrue_doc_rec_id = @accrue_doc_rec_id OUTPUT,
			@op_id = @depo_op_id,
			@user_id = @user_id

		IF @@ERROR <> 0 OR @r <> 0
			RETURN 106

		IF (@depo_op_doc_rec_id IS NOT NULL) OR (@accrue_doc_rec_id IS NOT NULL)
		BEGIN
			UPDATE dbo.DEPO_OP WITH (UPDLOCK)
			SET DOC_REC_ID = CASE WHEN @depo_op_doc_rec_id IS NOT NULL THEN @depo_op_doc_rec_id ELSE DOC_REC_ID END,
				ACCRUE_DOC_REC_ID = CASE WHEN @accrue_doc_rec_id IS NOT NULL THEN @accrue_doc_rec_id ELSE ACCRUE_DOC_REC_ID END
			WHERE OP_ID = @depo_op_id
			IF @@ERROR <> 0 OR @@ROWCOUNT <> 1
				RETURN 106
		END

		EXEC @r = dbo.depo_sp_exec_op @doc_rec_id = @depo_op_doc_rec_id OUTPUT, @accrue_doc_rec_id = @accrue_doc_rec_id OUTPUT, @op_id = @depo_op_id, @user_id = @user_id
		IF @@ERROR <> 0 OR @r <> 0
			RETURN 106
	END
END

/* End of Depsit Bonus */

_skip:

RETURN 0
GO
