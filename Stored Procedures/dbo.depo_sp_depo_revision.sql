SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[depo_sp_depo_revision]
	@date smalldatetime,
	@depo_id int,
	@prod_id int,
	@start_date smalldatetime,
	@end_date smalldatetime,
	@last_renew_date smalldatetime,
	@revision_schema int,
	@revision_type tinyint,
	@revision_count smallint,
	@revision_count_type tinyint,
	@revision_grace_items int,
	@revision_grace_date_type tinyint,
	@user_id int
AS
BEGIN
SET NOCOUNT ON;

IF @end_date <= @date
	RETURN 0
	
DECLARE
	@r int 	
	
DECLARE
	@depo_start_date smalldatetime
	
SET @depo_start_date = @start_date

IF @last_renew_date IS NOT NULL
	SET @start_date = @last_renew_date
	
IF @revision_grace_date_type <> 4 --ÒÄÅÉÆÉÉÓ ÛÄÙÀÅÀÈÉ ÀÒÀÓÏÃÄÓ
BEGIN
	IF @revision_grace_date_type = 1 -- ÃÙÄ
		SET @start_date = DATEADD(DAY, @revision_grace_items, @start_date)  
	ELSE
	IF @revision_grace_date_type = 2 -- ÈÅÄ
		SET @start_date = DATEADD(MONTH, @revision_grace_items, @start_date)  
	ELSE
	IF @revision_grace_date_type = 3 -- ßÄËÉ
		SET @start_date = DATEADD(YEAR, @revision_grace_items, @start_date)  
END

IF @start_date >= @date
	RETURN 0


DECLARE
	@need_revision bit
	
SET @need_revision = 0

DECLARE
	@date_tmp1 smalldatetime,
	@date_tmp2 smalldatetime,
	@month int

IF @revision_type = 1  -- ÚÏÅÄËÉ X ÐÄÒÉÏÃÉÓ ÛÄÌÃÄÂ
BEGIN
	IF @revision_count_type = 1 -- ÚÏÅÄËÉ X ÃÙÉÓ ÛÄÌÃÄÂ
	BEGIN
		IF @revision_count = 1
			SET @need_revision = 1
		ELSE
		IF DATEDIFF(day, @start_date, @date) % @revision_count = 0
			SET @need_revision = 1
	END
	ELSE
	IF @revision_count_type IN (2, 3) -- ÚÏÅÄËÉ X ÈÅÉÓ ÛÄÌÃÄÂ
	BEGIN
		SET @month = 1
		SET @date_tmp1 = @start_date
		WHILE @date_tmp1 < @end_date
		BEGIN
			SET @date_tmp1 = DATEADD(MONTH, @month * @revision_count, @start_date)
			IF @date_tmp1 = @date
			BEGIN
				SET @need_revision = 1
				GOTO _revision
			END 	
			SET @month = @month + 1
		END
	END
END
ELSE
IF @revision_type = 2 -- ÚÏÅÄËÉ X ÐÄÒÉÏÃÉÓ ÁÏËÏÓ
BEGIN
	IF @revision_count_type = 0 -- ÅÀÃÉÓ ÁÏËÏÓ
	  GOTO _revision
	ELSE
	IF @revision_count_type = 2 -- ÚÏÅÄËÉ X ÈÅÉÓ ÁÏËÏÓ
	BEGIN
		SET @month = 1
		SET @date_tmp2 = CONVERT(datetime, CONVERT(char(4), YEAR(@start_date)) + '0101')
		SET @date_tmp1 = DATEADD(DAY, -1, @date_tmp2)
		WHILE @date_tmp1 < @end_date
		BEGIN
			SET @date_tmp1 = DATEADD(month, @month * @revision_count, @date_tmp2) - 1
			IF @date_tmp1 = @date
			BEGIN
				SET @need_revision = 1
				GOTO _revision
			END 	
			SET @month = @month + 1
		END
	END
END


_revision:

IF @need_revision = 0
	RETURN 0
	
DECLARE
	@archive_deposit bit
	
SET @archive_deposit = 1

DECLARE
	@depo_op_id int,
	@depo_op_type smallint,
	@op_data XML,
	@depo_op_doc_rec_id	int,
	@accrue_doc_rec_id int
	
DECLARE
	@iso CHAR(3)
	
DECLARE
	@old_intrate money,
	@old_spend_amount_intrate money,
	@old_formula varchar(255),
	@new_intrate money,
	@new_spend_amount_intrate money
	
SELECT @iso = ISO, @old_intrate = INTRATE, @old_spend_amount_intrate = SPEND_AMOUNT_INTRATE,
	@old_formula = FORMULA
FROM dbo.DEPO_DEPOSITS
WHERE DEPO_ID = @depo_id
IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 RETURN 1;

EXEC @r = dbo.depo_sp_depo_revision_on_user
	@depo_id = @depo_id,
	@new_intrate = @new_intrate OUTPUT
	IF @@ERROR <> 0 OR @r <> 0 RETURN 1;

SELECT @new_spend_amount_intrate = SPEND_INTRATE
FROM dbo.DEPO_PRODUCT_PROPERTIES (NOLOCK)
WHERE PROD_ID = @prod_id AND ISO = @iso
IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 RETURN 1;

IF (@old_intrate = @new_intrate) AND (ISNULL(@old_spend_amount_intrate, 0.00) = ISNULL(@new_spend_amount_intrate, 0.00))
	GOTO _skip;

SET @op_data =
	(SELECT
		@archive_deposit AS ARCHIVE_DEPOSIT,
		@old_intrate AS OLD_INTRATE,
		@old_spend_amount_intrate AS OLD_SPEND_AMOUNT_INTRATE,
		@old_formula AS OLD_FORMULA,
		@new_intrate AS NEW_INTRATE,
		@new_spend_amount_intrate AS NEW_SPEND_AMOUNT_INTRATE
	FOR XML RAW, TYPE)
	
	
SET @depo_op_type = dbo.depo_fn_const_op_revision() 
	
INSERT INTO dbo.DEPO_OP WITH (UPDLOCK)
	(DEPO_ID, OP_DATE, OP_TYPE, OP_STATE, AMOUNT, ISO, OP_DATA, [OWNER])
VALUES
	(@depo_id, @date, @depo_op_type, 0, NULL, NULL, @op_data, @user_id)
IF @@ERROR <> 0 RETURN 1;

SET @depo_op_id = SCOPE_IDENTITY()

EXEC @r = dbo.depo_sp_add_op_action
	@op_id = @depo_op_id,
	@op_type = @depo_op_type,	
	@depo_id = @depo_id,
	@user_id = @user_id

IF @@ERROR <> 0 OR @r <> 0 RETURN 1;

EXEC @r = dbo.depo_sp_add_op_accounting
	@doc_rec_id = @depo_op_doc_rec_id OUTPUT,
	@accrue_doc_rec_id = @accrue_doc_rec_id OUTPUT,
	@op_id = @depo_op_id,
	@user_id = @user_id

IF @@ERROR <> 0 OR @r <> 0 RETURN 1;

IF (@depo_op_doc_rec_id IS NOT NULL) OR (@accrue_doc_rec_id IS NOT NULL)
BEGIN
	UPDATE dbo.DEPO_OP WITH (UPDLOCK)
	SET DOC_REC_ID = CASE WHEN @depo_op_doc_rec_id IS NOT NULL THEN @depo_op_doc_rec_id ELSE DOC_REC_ID END,
		ACCRUE_DOC_REC_ID = CASE WHEN @accrue_doc_rec_id IS NOT NULL THEN @accrue_doc_rec_id ELSE ACCRUE_DOC_REC_ID END
	WHERE OP_ID = @depo_op_id
	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 RETURN 1;
END

EXEC @r = dbo.depo_sp_exec_op @doc_rec_id = @depo_op_doc_rec_id OUTPUT, @accrue_doc_rec_id = @accrue_doc_rec_id OUTPUT, @op_id = @depo_op_id, @user_id = @user_id
IF @r <> 0 AND @@ERROR <> 0 RETURN 1;

_skip:

RETURN 0
END


GO
