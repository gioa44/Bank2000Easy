SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[depo_sp_check_op_action]
	@depo_id int,
	@row_version int,
	@op_type int
AS
SET NOCOUNT ON

DECLARE
	@result int,
	@msg varchar(8000)
	
DECLARE
	@prod_id int,
	@renewable bit,
	@prolongable bit
	
DECLARE
	@max_op_break_renew int,
	@max_op_resume_renew int
	

SET @result = 0
SET @msg = ''

IF NOT EXISTS(SELECT * FROM dbo.DEPO_DEPOSITS (NOLOCK) WHERE DEPO_ID = @depo_id AND ROW_VERSION = @row_version)
BEGIN
	SET @result = 1
	SET @msg = 'ÀÍÀÁÀÒÉ ÛÄÝÅËÉËÉÀ ÓáÅÀ ÌÏÌáÌÀÒÄÁËÉÓ ÌÉÄÒ, ÂÀÍÀÀáËÄÈ ÌÏÍÀÝÄÌÄÁÉ!'
	GOTO _check_end
END

IF EXISTS(SELECT * FROM dbo.DEPO_OP WHERE DEPO_ID = @depo_id AND OP_TYPE IN (dbo.depo_fn_const_op_annulment(), dbo.depo_fn_const_op_annulment_amount(), dbo.depo_fn_const_op_annulment_positive(), dbo.depo_fn_const_op_close()))
BEGIN
	SET @result = 2
	SET @msg = 'ÏÐÄÒÀÝÉÉÓ ÛÄÓÒÖËÄÁÀ ÛÄÖÞËÄÁÄËÉÀ, ÀÍÀÁÀÒÉ ÃÀáÖÒÖËÉÀ!'
	IF @result <> 0 
		GOTO _check_end
END

IF @op_type <> dbo.depo_fn_const_op_active()
BEGIN
	IF NOT EXISTS(SELECT * FROM dbo.DEPO_OP WHERE DEPO_ID = @depo_id AND OP_TYPE = dbo.depo_fn_const_op_active())
	BEGIN
		SET @result = 3
		SET @msg = 'ÏÐÄÒÀÝÉÉÓ ÛÄÓÒÖËÄÁÀ ÛÄÖÞËÄÁÄËÉÀ, ÓÀàÉÒÏÀ ÀÍÀÁÒÉÓ ÀØÔÉÅÉÆÀÝÉÀ!'
	END
END
ELSE
BEGIN
	IF EXISTS(SELECT * FROM dbo.DEPO_OP WHERE DEPO_ID = @depo_id AND OP_TYPE = dbo.depo_fn_const_op_active())
	BEGIN
		SET @result = 3
		SET @msg = 'ÏÐÄÒÀÝÉÉÓ ÛÄÓÒÖËÄÁÀ ÛÄÖÞËÄÁÄËÉÀ, ÀÍÀÁÀÒÉ ÖÊÅÄ ÀØÔÉÅÉÒÄÁÖËÉÀ!'
	END
END

IF @result <> 0 
	GOTO _check_end

IF @op_type = dbo.depo_fn_const_op_accumulate()
BEGIN
	DECLARE
		@accumulative bit

	SELECT @accumulative = ACCUMULATIVE
	FROM dbo.DEPO_DEPOSITS (NOLOCK)
	WHERE DEPO_ID = @depo_id

	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1
	BEGIN
		SET @result = 101
		SET @msg = 'DEPOSIT NOT FOUND!'
	END	

	IF @result <> 0 
		GOTO _check_end

	IF @accumulative = 0 
	BEGIN
		SET @result = 4
		SET @msg = 'ÀÍÀÁÀÒÆÄ ÈÀÍáÉÓ ÃÀÌÀÔÄÁÀ áÄËÛÄÊÒÖËÄÁÉÓ ÌÉáÄÃÅÉÈ ÃÀÖÛÅÄÁÄËÉÀ!'
	END	

	IF @result <> 0 
		GOTO _check_end
END
ELSE
IF @op_type = dbo.depo_fn_const_op_withdraw()
BEGIN
	DECLARE
		@spend bit

	SELECT @spend = SPEND
	FROM dbo.DEPO_DEPOSITS (NOLOCK)
	WHERE DEPO_ID = @depo_id

	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1
	BEGIN
		SET @result = 101
		SET @msg = 'DEPOSIT NOT FOUND!'
	END	

	IF @result <> 0 
		GOTO _check_end

	IF @spend = 0 
	BEGIN
		SET @result = 4
		SET @msg = 'ÈÀÍáÉÓ ÂÀÔÀÍÀ ÀÍÀÁÒÉÃÀÍ áÄËÛÄÊÒÖËÄÁÉÓ ÌÉáÄÃÅÉÈ ÃÀÖÛÅÄÁÄËÉÀ!'
	END	

	IF @result <> 0 
		GOTO _check_end
END
ELSE
IF @op_type = dbo.depo_fn_const_op_withdraw_schedule()
BEGIN
	DECLARE
		@depo_realize_schema_amount money

	SELECT @depo_realize_schema_amount = DEPO_REALIZE_SCHEMA_AMOUNT
	FROM dbo.DEPO_DEPOSITS (NOLOCK)
	WHERE DEPO_ID = @depo_id

	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1
	BEGIN
		SET @result = 101
		SET @msg = 'DEPOSIT NOT FOUND!'
	END	

	IF @result <> 0 
		GOTO _check_end

	IF @depo_realize_schema_amount IS NULL
	BEGIN
		SET @result = 4
		SET @msg = 'ÃÀÂÄÂÌÉËÉ ÈÀÍáÉÓ ÂÀÔÀÍÀ ÀÍÀÁÒÉÃÀÍ áÄËÛÄÊÒÖËÄÁÉÓ ÌÉáÄÃÅÉÈ ÃÀÖÛÅÄÁÖËÉÀ!'
	END	

	IF @result <> 0 
		GOTO _check_end
END
ELSE
IF @op_type IN ( dbo.depo_fn_const_op_prolongation(), dbo.depo_fn_const_op_prolongation_intrate_change() )
BEGIN
	SELECT @prolongable = PROLONGABLE
	FROM dbo.DEPO_DEPOSITS (NOLOCK)
	WHERE DEPO_ID = @depo_id

	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1
	BEGIN
		SET @result = 101
		SET @msg = 'DEPOSIT NOT FOUND!'
	END	

	IF @result <> 0 
		GOTO _check_end

	IF @prolongable = 0 
	BEGIN
		SET @result = 4
		SET @msg = 'ÀÍÀÁÒÉÓ ÐÒÏËÏÍÂÀÝÉÀ áÄËÛÄÊÒÖËÄÁÉÓ ÌÉáÄÃÅÉÈ ÃÀÖÛÅÄÁÄËÉÀ!'
	END	

	IF @result <> 0 
		GOTO _check_end

END
ELSE
IF @op_type = dbo.depo_fn_const_op_change_depo_realize_account()
BEGIN
	DECLARE
		@depo_realize_type int

	SELECT @depo_realize_type = DEPO_REALIZE_TYPE
	FROM dbo.DEPO_DEPOSITS
	WHERE DEPO_ID = @depo_id

	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1
	BEGIN
		SET @result = 101
		SET @msg = 'DEPOSIT NOT FOUND!'
	END	
	
	IF @depo_realize_type = 2
	BEGIN
		SET @result = 2
		SET @msg = 'ÀÍÀÁÀÒÉ ÀÒÉÓ ÒÄÀËÉÆÀÝÉÉÓ ÂÀÒÄÛÄ!'
	END	
END
IF @op_type = dbo.depo_fn_const_op_change_interest_realize_account()
BEGIN
	DECLARE
		@interest_realize_type int

	SELECT @interest_realize_type = INTEREST_REALIZE_TYPE
	FROM dbo.DEPO_DEPOSITS
	WHERE DEPO_ID = @depo_id

	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1
	BEGIN
		SET @result = 101
		SET @msg = 'DEPOSIT NOT FOUND!'
	END	
	
	IF @interest_realize_type = 2
	BEGIN
		SET @result = 2
		SET @msg = 'ÓÀÒÂÄÁËÉÓ ÒÄÀËÉÆÀÝÉÉÓ ÀÍÂÀÒÉÛÉÓ ÛÄÝÅËÀ ÃÀÖÛÅÄÁÄËÉÀ. ÓÀÒÂÄÁËÉÓ ÒÄÀËÉÆÀÝÉÀ áÃÄÁÀ ÀÍÀÁÒÉÓ ÒÄÀËÉÆÀÝÉÉÓ ÀÍÂÀÒÉÛÆÄ!'
	END	

	IF @interest_realize_type = 4
	BEGIN
		SET @result = 2
		SET @msg = 'ÓÀÒÂÄÁËÉÓ ÒÄÀËÉÆÀÝÉÉÓ ÀÍÂÀÒÉÛÉÓ ÛÄÝÅËÀ ÃÀÖÛÅÄÁÄËÉÀ. ÓÀÒÂÄÁËÉÓ ÒÄÀËÉÆÀÝÉÀ áÃÄÁÀ ÀÍÀÁÒÉÓ ÀÍÂÀÒÉÛÆÄ!'
	END	
END

IF @op_type = dbo.depo_fn_const_op_shareable_change()
BEGIN
	DECLARE
		@shareable bit,
		@prod_shareable int

	SELECT @shareable = D.SHAREABLE, @prod_shareable = P.SHAREABLE
	FROM dbo.DEPO_DEPOSITS (NOLOCK) D
		INNER JOIN dbo.DEPO_PRODUCT (NOLOCK) P ON D.PROD_ID = P.PROD_ID
	WHERE D.DEPO_ID = @depo_id

	IF @prod_shareable <> 1
	BEGIN
		SET @result = 2
		SET @msg = 'ÀÍÀÁÀÒÆÄ ÈÀÍÀÌ×ËÏÁÄËÏÁÀ ÀÊÒÞÀËÖËÉÀ ÐÒÏÃÖØÔÉÈ!'
	END

	IF @shareable = 1
	BEGIN
		SET @result = 4
		SET @msg = 'ÀÍÀÁÀÒÆÄ ÖÊÅÄ ÀÒÓÄÁÏÁÓ ÈÀÍÀÌ×ËÏÁÄËÏÁÀ!'
	END

	
END

ELSE
IF @op_type = dbo.depo_fn_const_op_renew()
BEGIN
	DECLARE
		@renew_max int,
		@renew_count int,
		@renew_last_prod_id int

	SELECT @renewable = RENEWABLE, @renew_max = RENEW_MAX, @renew_count = RENEW_COUNT, @renew_last_prod_id = RENEW_LAST_PROD_ID
	FROM dbo.DEPO_DEPOSITS (NOLOCK)
	WHERE DEPO_ID = @depo_id

	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1
	BEGIN
		SET @result = 101
		SET @msg = 'DEPOSIT NOT FOUND!'
	END	

	IF @result <> 0 
		GOTO _check_end

	IF @renewable = 0 
	BEGIN
		SET @result = 4
		SET @msg = 'ÀÍÀÁÒÉÓ ÂÀÍÀáËÄÁÀ áÄËÛÄÊÒÖËÄÁÉÓ ÌÉáÄÃÅÉÈ ÃÀÖÛÅÄÁÄËÉÀ!'
	END	

	IF (@renew_last_prod_id IS NOT NULL) AND (@renew_max = @renew_count + 1)
	BEGIN
		SET @result = 4
		SET @msg = 'ÀÍÀÁÒÉÓ ÂÀÍÀáËÄÁÀ ÛÄÓÀÞÄËÄÁËÉÀ ÌáÏËÏÃ ÓáÅÀ ÐÒÏÃÖØÔÉÈ!'
	END	


	IF (@renew_max IS NOT NULL) AND (@renew_max = @renew_count)
	BEGIN
		SET @result = 4
		SET @msg = 'ÀÍÀÁÒÉÓÈÅÉÓ ÂÀÌÏÚÄÍÄÁÖËÉÀ ÂÀÍÀáËÄÁÉÓ ÌÀØÓÉÌÀËÖÒÉ ÒÀÏÃÄÍÏÁÀ. ÛÄÌÃÄÂÉ ÂÀÍÀáËÄÁÀ áÄËÛÄÊÒÖËÄÁÉÓ ÌÉáÄÃÅÉÈ ÃÀÖÛÅÄÁÄËÉÀ!'
	END	

	IF @result <> 0 
		GOTO _check_end
END
ELSE
IF @op_type = dbo.depo_fn_const_op_convert()
BEGIN
	DECLARE
		@convertible bit

	SELECT @convertible = CONVERTIBLE
	FROM dbo.DEPO_DEPOSITS (NOLOCK)
	WHERE DEPO_ID = @depo_id

	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1
	BEGIN
		SET @result = 101
		SET @msg = 'DEPOSIT NOT FOUND!'
	END	

	IF @result <> 0 
		GOTO _check_end

	IF @convertible = 0 
	BEGIN
		SET @result = 160
		SET @msg = 'ÀÍÀÁÀÒÉÓ ÊÏÍÅÄÒÔÉÒÄÁÀ ÓáÅÀ ÅÀËÖÔÀÛÉ áÄËÛÄÊÒÖËÄÁÉÓ ÌÉáÄÃÅÉÈ ÃÀÖÛÅÄÁÄËÉÀ!'
	END	

	IF @result <> 0 
		GOTO _check_end
END
ELSE
IF @op_type = dbo.depo_fn_const_op_break_renew()
BEGIN
	SELECT @renewable = RENEWABLE, @prolongable = PROLONGABLE
	FROM dbo.DEPO_DEPOSITS (NOLOCK)
	WHERE DEPO_ID = @depo_id

	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1
	BEGIN
		SET @result = 101
		SET @msg = 'DEPOSIT NOT FOUND!'
	END	

	IF @result <> 0 
		GOTO _check_end

	IF @renewable = 0 AND @prolongable = 0 
	BEGIN
		SET @result = 230
		SET @msg = 'ÀÍÀÁÒÉÓ ÂÀÍÀáËÄÁÀ/ÐÒÏËÏÍÂÀÝÉÀ áÄËÛÄÊÒÖËÄÁÉÓ ÌÉáÄÃÅÉÈ ÃÀÖÛÅÄÁÄËÉÀ ÀÍ ÛÄßÚÅÄÔÉËÉÀ ÏÐÄÒÀÝÉÉÈ!'
	END	

	IF @result <> 0 
		GOTO _check_end
END
ELSE
IF @op_type = dbo.depo_fn_const_op_resume_renew()
BEGIN
	SELECT @max_op_resume_renew = MAX(OP_ID)
	FROM dbo.DEPO_OP (NOLOCK)
	WHERE DEPO_ID = @depo_id AND OP_TYPE = dbo.depo_fn_const_op_resume_renew()
	
	IF NOT EXISTS(SELECT *
		FROM dbo.DEPO_OP (NOLOCK)
		WHERE DEPO_ID = @depo_id AND OP_ID > ISNULL(@max_op_resume_renew, 0) AND
			OP_TYPE = dbo.depo_fn_const_op_break_renew())
	BEGIN
		SET @result = 235
		SET @msg = 'ÀÍÀÁÀÒÆÄ ÀÒ ÌÏÉÞÄÁÍÀ ÏÐÄÒÀÝÉÀ "ÀÍÀÁÀÒÆÄ ÂÀÍÀáËÄÁÀ/ÐÒÏËÏÍÂÀÝÉÉÓ ÛÄßÚÅÄÔÀ"!'
	END
	
	IF @result <> 0 
		GOTO _check_end
END
ELSE
IF @op_type = dbo.depo_fn_const_op_allow_prolongation()
BEGIN
	SELECT @prod_id = PROD_ID, @prolongable = PROLONGABLE
	FROM dbo.DEPO_DEPOSITS (NOLOCK)
	WHERE DEPO_ID = @depo_id

	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1
	BEGIN
		SET @result = 101
		SET @msg = 'DEPOSIT NOT FOUND!'
	END	

	IF @result <> 0 
		GOTO _check_end

	IF @prolongable = 1 
	BEGIN
		SET @result = 238
		SET @msg = 'ÀÍÀÁÒÆÄ áÄËÛÄÊÒÖËÄÁÉÓ ÌÉáÄÃÅÉÈ ÃÀÛÅÄÁÄËÉÀ ÐÒÏËÏÍÂÀÝÉÀ!'
	END
	
	IF @result <> 0 
		GOTO _check_end
	
	DECLARE
		@prod_prolongable tinyint
		
	SELECT @prod_prolongable = PROLONGABLE 
	FROM dbo.DEPO_PRODUCT (NOLOCK)
	WHERE PROD_ID = @prod_id	
	
	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1
	BEGIN
		SET @result = 101
		SET @msg = 'DEPOSIT PRODUCT NOT FOUND!'
	END
	
	IF @result <> 0 
		GOTO _check_end
	
	IF @prod_prolongable = 3	
	BEGIN
		SET @result = 238
		SET @msg = 'ÀÍÀÁÒÆÄ ÐÒÏÃÖØÔÉÓ ÌÉáÄÃÅÉÈ ÐÒÏËÏÍÂÀÝÉÀ ÃÀÖÛÅÄÁÄËÉÀ!'
	END
	
	IF @result <> 0 
		GOTO _check_end
		
	SELECT @max_op_break_renew = MAX(OP_ID)
	FROM dbo.DEPO_OP (NOLOCK)
	WHERE DEPO_ID = @depo_id AND OP_TYPE = dbo.depo_fn_const_op_break_renew()
	
	IF @max_op_break_renew IS NOT NULL AND NOT EXISTS(SELECT *
		FROM dbo.DEPO_OP (NOLOCK)
		WHERE DEPO_ID = @depo_id AND OP_ID > ISNULL(@max_op_break_renew, 0) AND
			OP_TYPE = dbo.depo_fn_const_op_resume_renew())
	BEGIN
		SET @result = 238
		SET @msg = 'ÀÍÀÁÀÒÆÄ ÐÒÏËÏÍÂÀÝÉÀ ÛÄßÚÅÄÔÉËÉÀ "ÀÍÀÁÀÒÆÄ ÂÀÍÀáËÄÁÀ/ÐÒÏËÏÍÂÀÝÉÉÓ ÛÄßÚÅÄÔÀ" ÏÐÄÒÀÝÉÉÈ!'
	END
	
	IF @result <> 0 
		GOTO _check_end		
END
ELSE
IF @op_type = dbo.depo_fn_const_op_allow_renew()
BEGIN
	SELECT @prod_id = PROD_ID, @renewable = RENEWABLE
	FROM dbo.DEPO_DEPOSITS (NOLOCK)
	WHERE DEPO_ID = @depo_id

	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1
	BEGIN
		SET @result = 101
		SET @msg = 'DEPOSIT NOT FOUND!'
	END	

	IF @result <> 0 
		GOTO _check_end

	IF @renewable = 1 
	BEGIN
		SET @result = 237
		SET @msg = 'ÀÍÀÁÒÆÄ áÄËÛÄÊÒÖËÄÁÉÓ ÌÉáÄÃÅÉÈ ÃÀÛÅÄÁÖËÉÀ ÂÀÍÀáËÄÁÀ!'
	END
	
	IF @result <> 0 
		GOTO _check_end
	
	DECLARE
		@prod_renewable tinyint
		
	SELECT @prod_renewable = RENEWABLE
	FROM dbo.DEPO_PRODUCT (NOLOCK)
	WHERE PROD_ID = @prod_id	
	
	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1
	BEGIN
		SET @result = 101
		SET @msg = 'DEPOSIT PRODUCT NOT FOUND!'
	END
	
	IF @result <> 0 
		GOTO _check_end
	
	IF @prod_renewable = 3	
	BEGIN
		SET @result = 238
		SET @msg = 'ÀÍÀÁÒÆÄ ÐÒÏÃÖØÔÉÓ ÌÉáÄÃÅÉÈ ÂÀÍÀáËÄÁÀ ÃÀÖÛÅÄÁÄËÉÀ!'
	END
	
	IF @result <> 0 
		GOTO _check_end
		
	SELECT @max_op_break_renew = MAX(OP_ID)
	FROM dbo.DEPO_OP (NOLOCK)
	WHERE DEPO_ID = @depo_id AND OP_TYPE = dbo.depo_fn_const_op_break_renew()
	
	IF @max_op_break_renew IS NOT NULL AND NOT EXISTS(SELECT *
		FROM dbo.DEPO_OP (NOLOCK)
		WHERE DEPO_ID = @depo_id AND OP_ID > ISNULL(@max_op_break_renew, 0) AND
			OP_TYPE = dbo.depo_fn_const_op_resume_renew())
	BEGIN
		SET @result = 238
		SET @msg = 'ÀÍÀÁÀÒÆÄ ÂÀÍÀáËÄÁÀ ÛÄßÚÅÄÔÉËÉÀ "ÀÍÀÁÀÒÆÄ ÂÀÍÀáËÄÁÀ/ÐÒÏËÏÍÂÀÝÉÉÓ ÛÄßÚÅÄÔÀ" ÏÐÄÒÀÝÉÉÈ!'
	END
	
	IF @result <> 0 
		GOTO _check_end		
END
ELSE
IF @op_type IN (dbo.depo_fn_const_op_annulment(), dbo.depo_fn_const_op_annulment_amount(), dbo.depo_fn_const_op_annulment_positive())
BEGIN
	DECLARE
		@end_date smalldatetime, 
		@annulmented bit,
		@annulment_realize bit

	SELECT @end_date = END_DATE, @annulmented = ANNULMENTED, @annulment_realize = ANNULMENT_REALIZE
	FROM dbo.DEPO_DEPOSITS (NOLOCK)
	WHERE DEPO_ID = @depo_id

	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1
	BEGIN
		SET @result = 101
		SET @msg = 'DEPOSIT NOT FOUND!'
	END	

	IF @result <> 0 
		GOTO _check_end

	IF (@annulmented = 0) OR (@end_date IS NULL)
	BEGIN
		SET @result = 160
		SET @msg = 'ÀÍÀÁÀÒÉÓ ÃÀÒÙÅÄÅÀ áÄËÛÄÊÒÖËÄÁÉÓ ÌÉáÄÃÅÉÈ ÃÀÖÛÅÄÁÄËÉÀ!'
	END	
	
	IF @result <> 0 
		GOTO _check_end

	IF (@op_type = dbo.depo_fn_const_op_annulment_positive()) AND (@annulment_realize = 0) 
	BEGIN
		SET @result = 160
		SET @msg = 'ÀÍÀÁÀÒÉÓ ÃÀÒÙÅÄÅÀ-ÐÏÆÉÔÉÅÉ áÄËÛÄÊÒÖËÄÁÉÓ ÌÉáÄÃÅÉÈ ÃÀÖÛÅÄÁÄËÉÀ!'
	END	

	IF @result <> 0 
		GOTO _check_end
END


_check_end:

	SELECT @result AS RESULT, @msg AS MSG

RETURN 0
GO
