SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[depo_sp_process_deposits_before_accrual]
	@user_id int,
	@dept_no int,
	@doc_date smalldatetime,
	@calc_date smalldatetime,
	@acc_id int,
	@depo_id int
AS

SET NOCOUNT ON;

DECLARE
	@r int

DECLARE
	@sql nvarchar(2000)

DECLARE
	@state tinyint,
	@prod_id int

DECLARE
	@analyze_schema int,
	@analyze_schema_proc varchar(128),
	@deposit_default bit,
	@remark varchar(255)

DECLARE
	@depo_op_id int,
	@depo_op_type smallint,
	@op_amount money,
	@op_data XML,
	@depo_op_doc_rec_id int,
	@accrue_doc_rec_id int

SELECT @state = [STATE], @prod_id = PROD_ID, @deposit_default = DEPOSIT_DEFAULT
FROM dbo.DEPO_DEPOSITS (NOLOCK)
WHERE DEPO_ID = @depo_id

IF @state <= 40 OR @state >= 240
	GOTO _skip
	
SELECT @analyze_schema = ANALYZE_SCHEMA
FROM dbo.DEPO_PRODUCT (NOLOCK) 
WHERE PROD_ID = @prod_id

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
		IF @@ERROR <> 0 AND @r <> 0
			RETURN 105

		EXEC @r = dbo.depo_sp_mark_default_on_user
			@depo_id,
			@calc_date,
			@user_id
		IF @@ERROR <> 0 OR @r <> 0
			RETURN 105

	END
END

_skip:

RETURN 0
GO
