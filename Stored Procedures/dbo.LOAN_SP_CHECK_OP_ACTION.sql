SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[LOAN_SP_CHECK_OP_ACTION]
	@loan_id int,
	@row_version int,
	@op_type int
AS
SET NOCOUNT ON

DECLARE
	@result int,
	@msg varchar(8000),
	@guarantee bit

SET @result = 0
SET @msg = ''

SELECT 
	@guarantee = GUARANTEE
FROM dbo.LOANS (NOLOCK)
WHERE LOAN_ID = @loan_id

IF NOT EXISTS(SELECT * FROM dbo.LOANS WHERE LOAN_ID = @loan_id AND ROW_VERSION = @row_version)
BEGIN
  SET @result = 1
  GOTO _check_end
END

IF EXISTS(SELECT * FROM dbo.LOAN_OPS WHERE LOAN_ID = @loan_id AND OP_TYPE = dbo.loan_const_op_close())
BEGIN
	SET @result = 2
	SET @msg = 'ÏÐÄÒÀÝÉÉÓ ÛÄÓÒÖËÄÁÀ ÛÄÖÞËÄÁÄËÉÀ, ÓÄÓáÉ ÃÀáÖÒÖËÉÀ !'
	IF @result <> 0 
		GOTO _check_end
END

IF @op_type = dbo.loan_const_op_approval()
BEGIN
	IF EXISTS(SELECT * FROM dbo.LOAN_OPS WHERE LOAN_ID = @loan_id AND OP_TYPE = dbo.loan_const_op_approval())
	BEGIN
		SET @result = 3
		SET @msg = 'ÏÐÄÒÀÝÉÀ ÓÄÓáÉÓ ÃÀÌÔÊÉÝÄÁÀ ÖÊÅÄ ÛÄÓÒÖËÄÁÖËÉÀ !'
	END
	GOTO _check_end
END

IF @guarantee = 0
BEGIN
	IF @op_type = dbo.loan_const_op_disburse()
	BEGIN
		IF NOT EXISTS(SELECT * FROM dbo.LOAN_OPS WHERE LOAN_ID = @loan_id AND OP_TYPE = dbo.loan_const_op_approval())
		BEGIN
			SET @result = 3
			SET @msg = 'ÓÄÓáÉ ÀÒ ÀÒÉÓ ÃÀÌÔÊÉÝÄÁÖËÉ !'
		END

		IF EXISTS(SELECT * FROM dbo.LOAN_OPS WHERE LOAN_ID = @loan_id AND OP_TYPE = dbo.loan_const_op_disburse())
		BEGIN
			SET @result = 3
			SET @msg = 'ÏÐÄÒÀÝÉÀ ÓÄÓáÉÓ ÂÀÝÄÌÀ ÖÊÅÄ ÛÄÓÒÖËÄÁÖËÉÀ !'
		END
		IF @result <> 0 
			GOTO _check_end
	END
	ELSE
	BEGIN
		IF NOT EXISTS(SELECT * FROM dbo.LOAN_OPS WHERE LOAN_ID = @loan_id AND OP_TYPE = dbo.loan_const_op_disburse())
		BEGIN
			SET @result = 4
			SET @msg = 'ÏÐÄÒÀÝÉÉÓ ÛÄÓÒÖËÄÁÀ ÛÄÖÞËÄÁÄËÉÀ, ÓÄÓáÉ ÂÀÝÄÌÖËÉ ÀÒ ÀÒÉÓ !'
			IF @result <> 0 
				GOTO _check_end
		END
	END
END
ELSE
BEGIN
	IF @op_type = dbo.loan_const_op_guar_disburse()
	BEGIN
		IF NOT EXISTS(SELECT * FROM dbo.LOAN_OPS WHERE LOAN_ID = @loan_id AND OP_TYPE = dbo.loan_const_op_approval())
		BEGIN
			SET @result = 3
			SET @msg = 'ÂÀÒÀÍÔÉÀ ÀÒ ÀÒÉÓ ÃÀÌÔÊÉÝÄÁÖËÉ !'
		END

		IF EXISTS(SELECT * FROM dbo.LOAN_OPS WHERE LOAN_ID = @loan_id AND OP_TYPE = dbo.loan_const_op_guar_disburse())
		BEGIN
			SET @result = 3
			SET @msg = 'ÏÐÄÒÀÝÉÀ ÂÀÒÀÍÔÉÉÓ ÂÀÝÄÌÀ ÖÊÅÄ ÛÄÓÒÖËÄÁÖËÉÀ !'
		END
		IF @result <> 0 
			GOTO _check_end
	END
	ELSE
	BEGIN
		IF NOT EXISTS(SELECT * FROM dbo.LOAN_OPS WHERE LOAN_ID = @loan_id AND OP_TYPE = dbo.loan_const_op_guar_disburse())
		BEGIN
			SET @result = 4
			SET @msg = 'ÏÐÄÒÀÝÉÉÓ ÛÄÓÒÖËÄÁÀ ÛÄÖÞËÄÁÄËÉÀ, ÂÀÒÀÍÔÉÀ ÂÀÝÄÌÖËÉ ÀÒ ÀÒÉÓ !'
			IF @result <> 0 
				GOTO _check_end
		END
	END
END

IF @op_type = dbo.loan_const_op_disburse_transh()
BEGIN
	DECLARE
		@end_date smalldatetime
	SELECT @end_date = END_DATE
	FROM dbo.LOANS (NOLOCK)
	WHERE LOAN_ID = @loan_id

	IF @end_date <= dbo.loan_open_date_for_loan(@loan_id)
	BEGIN
		SET @result = 4
		SET @msg = 'ÅÉÍÀÉÃÀÍ ÓÄÓáÓ ÂÀÖÅÉÃÀ ÅÀÃÀ, ÈÀÍáÉÓ ÂÀÝÄÌÀ ÛÄÖÞËÄÁÄËÉÀ !'
	END

	IF NOT EXISTS (SELECT * FROM dbo.LOAN_DETAILS WHERE LOAN_ID = @loan_id AND NU_PRINCIPAL > $0.00)
	BEGIN
		SET @result = 4
		SET @msg = 'ÀÓÀÈÅÉÓÄÁÄËÉ ÈÀÍáÀ ÛÄÀÃÂÄÍÓ ÍÖËÓ !'
	END

	IF @result <> 0 
		GOTO _check_end

END

IF @op_type IN (dbo.loan_const_op_disburse_transh(), dbo.loan_const_op_overdue_revert(), dbo.loan_const_op_calloff(), dbo.loan_const_op_writeoff(),
	dbo.loan_const_op_restructure(), dbo.loan_const_op_loan_correct(), dbo.loan_const_op_loan_correct2(), dbo.loan_const_op_restructure_schedule(), 
	dbo.loan_const_op_prolongation(), dbo.loan_const_op_penalty_stop(), dbo.loan_const_op_fine_accrue(), dbo.loan_const_op_fine_forgive(), 
	dbo.loan_const_op_restructure_risks(), dbo.loan_const_op_individual_risks(), dbo.loan_const_op_change_dept(), dbo.loan_const_op_close(), 
	dbo.loan_const_op_restructure_collateral(), dbo.loan_const_op_correct_collateral())
BEGIN
	IF (SELECT [STATE] FROM dbo.LOANS WHERE LOAN_ID = @loan_id) = dbo.loan_const_state_writedoff()
	BEGIN
		SET @result = 4
		SET @msg = 'ÀÌ ÏÐÄÒÀÝÉÉÓ ÛÄÓÒÖËÄÁÀ ÛÄÖÞËÄÁÄËÉÀ, ÓÄÓáÉ ÜÀÌÏßÄÒÉËÉÀ !'
	END
	IF @result <> 0 
		GOTO _check_end
END

--IF @op_type IN (dbo.loan_const_op_restructure(), dbo.loan_const_op_prolongation()) 
--BEGIN
--	IF dbo.LOAN_FN_LOAN_HAS_ILLEGAL_DEBT (@loan_id) = 1
--	BEGIN
--		SET @result = 5
--		SET @msg = 'ÓÄÓáÆÄ ÀÒÓÄÁÖËÉ ÅÀÃÀÂÀÃÀÝÉËÄÁÖËÉ ÃÀÅÀËÉÀÍÄÁÉÓ ÂÀÌÏ ÏÐÄÒÀÝÉÉÓ ÛÄÓÒÖËÄÁÀ ÛÄÖÞËÄÁÄËÉÀ !'
--	END
--
--/*	IF (@op_type = dbo.loan_const_op_prolongation()) AND (SELECT SCHEDULE_TYPE FROM dbo.LOANS WHERE LOAN_ID = @loan_id) IN (16, 32) -- ÉÍÃÉÅÉÃÖÀËÖÒÉ ÂÒÀ×ÉÊÉ ÀÍ ÓÄÓáÉÓ ËÉÌÉÔÉ
--	BEGIN
--		SET @result = 5
--		SET @msg = 'ÓÄÓáÉÓ ÂÒÀ×ÉÊÉÓ ÔÉÐÉÓ ÂÀÌÏ ÏÐÄÒÀÝÉÉÓ ÛÄÓÒÖËÄÁÀ ÛÄÖÞËÄÁÄËÉÀ !'
--	END*/
--
--	IF @result <> 0 
--		GOTO _check_end
--END


IF @op_type = dbo.loan_const_op_payment()
BEGIN
	IF (SELECT [STATE] FROM dbo.LOANS WHERE LOAN_ID = @loan_id) = dbo.loan_const_state_writedoff()	
	BEGIN
		SET @result = 5
		SET @msg = 'ÓÄÓáÉÓ ÜÀÌÏßÄÒÉËÉÀ !'
	END

	IF @result <> 0 
		GOTO _check_end
END


IF @op_type = dbo.loan_const_op_payment_writedoff()
BEGIN
	IF (SELECT [STATE] FROM dbo.LOANS WHERE LOAN_ID = @loan_id) <> dbo.loan_const_state_writedoff()	
	BEGIN
		SET @result = 5
		SET @msg = 'ÓÄÓáÉÓ ÀÒ ÀÒÉÓ ÜÀÌÏßÄÒÉËÉ !'
	END

	IF @result <> 0 
		GOTO _check_end
END

IF @op_type = dbo.loan_const_op_writedoff_forgive()
BEGIN
	IF NOT EXISTS (SELECT * FROM dbo.LOANS WHERE LOAN_ID = @loan_id AND [STATE] = dbo.loan_const_state_writedoff())
	BEGIN
		SET @result = 5
		SET @msg = 'ÓÄÓáÉÓ ÀÒ ÀÒÉÓ ÜÀÌÏßÄÒÉËÉ !'
	END

	IF @result <> 0 
		GOTO _check_end
END

IF @op_type = dbo.loan_const_op_writeoff()
BEGIN
	DECLARE
		@max_category_level tinyint,
		@category_1 money,
		@category_2 money,
		@category_3 money,
		@category_4 money,
		@category_5 money

	SELECT @max_category_level = MAX_CATEGORY_LEVEL, @category_1 = ISNULL(CATEGORY_1, $0.00), @category_2 = ISNULL(CATEGORY_2, $0.00), @category_3 = ISNULL(CATEGORY_3, $0.00), @category_4 = ISNULL(CATEGORY_4, $0.00), @category_5 = ISNULL(CATEGORY_5, $0.00)
	FROM dbo.LOAN_DETAILS (NOLOCK)
	WHERE LOAN_ID = @loan_id

	IF (@max_category_level < 5) OR (@category_1 + @category_2 + @category_3 + @category_4 <> $0.00)
	BEGIN
		SET @result = 5
		SET @msg = 'ÓÄÓáÉÓ ÒÄÆÄÒÅÉ ÖÍÃÀ ÛÄÀÃÂÄÍÃÄÓ 100%-Ó !'
	END	

	IF @result <> 0 
		GOTO _check_end
END

DECLARE
	@grace_finish_date smalldatetime,
	@schedule_type int

IF @op_type = dbo.loan_const_op_debt_defere()
BEGIN
	SELECT 
		@grace_finish_date = GRACE_FINISH_DATE,
		@schedule_type = SCHEDULE_TYPE
	FROM dbo.LOANS
	WHERE LOAN_ID = @loan_id

	IF (@schedule_type = 64) AND (dbo.loan_open_date_for_loan(@loan_id) <= @grace_finish_date)
	BEGIN
		SET @result = 6
		SET @msg = 'ÓÀÛÄÙÀÅÀÈÏ ÐÄÒÉÏÃÉÓ ÀÌÏßÖÒÅÀÌÃÄ, ÂÀÃÀÅÀÃÄÁÉÓ ÏÐÄÒÀÝÉÉÓ ÛÄÓÒÖËÄÁÀ ÓÔÖÃÄÍÔÖÒ ÓÄÓáÆÄ ÛÄÖÞËÄÁÄËÉÀ!'
	END

	IF @result <> 0 
		GOTO _check_end
END

_check_end:

	SELECT @result AS RESULT, @msg AS MSG

RETURN
GO
