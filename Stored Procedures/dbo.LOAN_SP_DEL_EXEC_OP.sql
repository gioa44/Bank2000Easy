SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[LOAN_SP_DEL_EXEC_OP]
  @op_id int,
  @user_id int
AS
SET NOCOUNT ON

DECLARE @e int, @r int

DECLARE
	@loan_id int, 
	@op_type smallint,
	@op_data_xml xml,
	@op_details_xml xml,
	@op_loan_details xml,
	@op_ext_xml_1 xml,
	@op_ext_xml_2 xml,
	@doc_rec_id int,
	@note_rec_id int,
	@loan_state tinyint,
	@op_date smalldatetime,
	@update_data bit,
	@update_schedule bit

    

SELECT  @loan_id=LOAN_ID,@op_type=OP_TYPE, @op_date=OP_DATE, @doc_rec_id=DOC_REC_ID, @note_rec_id=NOTE_REC_ID, @op_data_xml=OP_DATA, 
		@op_details_xml = OP_DETAILS, @op_ext_xml_1 = OP_EXT_XML_1, @op_ext_xml_2 = OP_EXT_XML_2, @op_loan_details = OP_LOAN_DETAILS, @update_data = UPDATE_DATA, @update_schedule = UPDATE_SCHEDULE
FROM dbo.LOAN_OPS WHERE OP_ID=@op_id
SELECT @r = @@ROWCOUNT, @e = @@ERROR
IF @e <> 0 BEGIN RAISERROR ('ÛÄÝÃÏÌÀ ÏÐÄÒÀÝÉÉÓ ÌÏÞÉÄÁÉÓÀÓ',16,1) RETURN(1) END
IF @r = 0 BEGIN RAISERROR('RECORD NOT FOUND',16,1) RETURN(1) END

IF @doc_rec_id IS NOT NULL
BEGIN
	EXEC @r = dbo.LOAN_SP_PROCESS_DELETE_OP_ACCOUNTING @doc_rec_id=@doc_rec_id, @op_id=@op_id, @user_id=@user_id
	IF @@ERROR<>0 OR @r<>0 RETURN(11)
END

IF @update_data = 1
BEGIN
	EXEC @r = dbo.LOAN_SP_RESTORE_LOAN_DATA @op_id = @op_id
	IF @@ERROR<>0 OR @r<>0 RETURN(1)
END

IF @update_schedule = 1
BEGIN
	EXEC @r = dbo.LOAN_SP_RESTORE_LOAN_SCHEDULE @op_id = @op_id, @loan_id = @loan_id
	IF @@ERROR<>0 OR @r<>0 RETURN(1)
END

IF @op_loan_details IS NOT NULL
BEGIN
	EXEC @r = dbo.LOAN_SP_RESTORE_OPS_LOAN_DETAILS @op_id = @op_id
	IF @@ERROR<>0 OR @r<>0 RETURN(1)
END


IF @op_type = dbo.loan_const_op_disburse()
BEGIN
	DELETE dbo.LOAN_DETAILS	WHERE LOAN_ID = @loan_id
	SELECT @r = @@ROWCOUNT, @e = @@ERROR
	IF @e <> 0 BEGIN RAISERROR ('ÛÄÝÃÏÌÀ.',16,1) RETURN(1) END
	IF @r = 0 BEGIN RAISERROR('RECORD NOT FOUND',16,1) RETURN(1) END

	GOTO end_op
END

  
DECLARE
	@overdue_percent_penalty money, 
	@overdue_principal_penalty money, 
	@overdue_percent money,
	@late_percent money, 
	@overdue_principal money, 
	@late_principal money, 
	@overdue_principal_interest money,
	@interest money,
	@principal money,
	@prepayment money,
	@prepayment_penalty money,
	@nu_interest money,
	@payment_type tinyint,
	@prev_step smalldatetime,
	@next_schedule_date smalldatetime
IF @op_type = dbo.loan_const_op_payment()
BEGIN
	UPDATE dbo.LOAN_DETAIL_LATE
	SET LATE_PRINCIPAL = DL.LATE_PRINCIPAL,
		LATE_PERCENT = DL.LATE_PERCENT
	FROM dbo.LOAN_DETAIL_LATE L INNER JOIN
		dbo.LOAN_VW_OP_PAYMENT_DETAIL_LATE DL ON L.LATE_OP_ID = DL.LATE_OP_ID
	WHERE DL.OP_ID = @op_id

	UPDATE dbo.LOAN_DETAIL_OVERDUE
	SET OVERDUE_PRINCIPAL = DL.OVERDUE_PRINCIPAL,
		OVERDUE_PERCENT = DL.OVERDUE_PERCENT
	FROM dbo.LOAN_DETAIL_OVERDUE L INNER JOIN
		dbo.LOAN_VW_OP_PAYMENT_DETAIL_OVERDUE DL ON L.OVERDUE_OP_ID = DL.OVERDUE_OP_ID
	WHERE DL.OP_ID = @op_id

	SELECT @loan_state = STATE FROM dbo.LOAN_VW_LOAN_OP_PAYMENT_DETAILS
	WHERE OP_ID = @op_id

	UPDATE dbo.LOANS 
	SET
		STATE = @loan_state
	WHERE LOAN_ID = @loan_id 
	SELECT @r = @@ROWCOUNT, @e = @@ERROR
	IF (@e <> 0) OR (@r = 0) BEGIN RAISERROR ('ÛÄÝÃÏÌÀ ÓÄÓáÉÓ ÃÀáÖÒÅÉÓ ÏÐÄÒÀÝÉÉÓ ßÀÛËÉÓÀÓ !',16,1) RETURN(1) END

	GOTO end_op
END

IF @op_type = dbo.loan_const_op_overdue_revert()
BEGIN
	UPDATE dbo.LOANS
		SET [STATE] = dbo.loan_const_state_overdued()
	WHERE LOAN_ID = @loan_id	

	UPDATE dbo.LOAN_DETAIL_LATE
	SET LATE_PRINCIPAL = DL.LATE_PRINCIPAL,
		LATE_PERCENT = DL.LATE_PERCENT
	FROM dbo.LOAN_DETAIL_LATE L INNER JOIN
		dbo.LOAN_VW_OP_PAYMENT_DETAIL_LATE DL ON L.LATE_OP_ID = DL.LATE_OP_ID
	WHERE DL.OP_ID = @op_id

	UPDATE dbo.LOAN_DETAIL_OVERDUE
	SET OVERDUE_PRINCIPAL = DL.OVERDUE_PRINCIPAL,
		OVERDUE_PERCENT = DL.OVERDUE_PERCENT
	FROM dbo.LOAN_DETAIL_OVERDUE L INNER JOIN
		dbo.LOAN_VW_OP_PAYMENT_DETAIL_OVERDUE DL ON L.OVERDUE_OP_ID = DL.OVERDUE_OP_ID
	WHERE DL.OP_ID = @op_id

	GOTO end_op
END

DECLARE
	@last_date smalldatetime
IF @op_type IN (dbo.loan_const_op_close(), dbo.loan_const_op_guar_close())
BEGIN
	IF @op_type = dbo.loan_const_op_close()
		SELECT @loan_state = STATE FROM dbo.LOAN_VW_LOAN_OP_CLOSE
		WHERE OP_ID = @op_id
	ELSE 
		SET @loan_state = dbo.loan_const_state_current()

	UPDATE dbo.LOANS 
	SET
		STATE = @loan_state
	WHERE LOAN_ID = @loan_id 
	SELECT @r = @@ROWCOUNT, @e = @@ERROR
	IF (@e <> 0) OR (@r = 0) BEGIN RAISERROR ('ÛÄÝÃÏÌÀ ÓÄÓáÉÓ ÃÀáÖÒÅÉÓ ÏÐÄÒÀÝÉÉÓ ßÀÛËÉÓÀÓ !',16,1) RETURN(1) END

	SELECT @last_date = MAX(CALC_DATE) FROM dbo.LOAN_DETAILS_HISTORY WHERE LOAN_ID = @loan_id

	INSERT INTO dbo.LOAN_DETAILS 
	SELECT * FROM dbo.LOAN_DETAILS_HISTORY 
	WHERE (LOAN_ID = @loan_id) AND CALC_DATE = @last_date
	
	SELECT @r = @@ROWCOUNT, @e = @@ERROR
	IF (@e <> 0) OR (@r = 0) BEGIN RAISERROR ('ÛÄÝÃÏÌÀ ÓÄÓáÉÓ ÃÀáÖÒÅÉÓ ÏÐÄÒÀÝÉÉÓ ßÀÛËÉÓÀÓ !',16,1) RETURN(1) END

	DELETE FROM dbo.LOAN_DETAILS_HISTORY 
	WHERE (LOAN_ID = @loan_id) AND CALC_DATE = @last_date

	SELECT @r = @@ROWCOUNT, @e = @@ERROR
	IF (@e <> 0) OR (@r = 0) BEGIN RAISERROR ('ÛÄÝÃÏÌÀ ÓÄÓáÉÓ ÃÀáÖÒÅÉÓ ÏÐÄÒÀÝÉÉÓ ßÀÛËÉÓÀÓ !',16,1) RETURN(1) END

	GOTO end_op
END

DECLARE
	@penalty_flags int
IF @op_type = dbo.loan_const_op_penalty_stop()
BEGIN
	SELECT @penalty_flags = OLD_PENALTY_FLAGS FROM dbo.LOAN_VW_LOAN_OP_PENALTY_STOP WHERE OP_ID = @op_id

	UPDATE dbo.LOANS SET PENALTY_FLAGS = @penalty_flags
	WHERE LOAN_ID = @loan_id
	
	SELECT @r = @@ROWCOUNT, @e = @@ERROR
	IF @e <> 0 BEGIN RAISERROR ('ÛÄÝÃÏÌÀ.',16,1) RETURN(1) END
	IF @r = 0 BEGIN RAISERROR('RECORD NOT FOUND',16,1) RETURN(1) END

	GOTO end_op
END

DECLARE
	@old_resp_user_id int
IF @op_type = dbo.loan_const_op_officer_change()
BEGIN
	SELECT @old_resp_user_id = OLD_RESPONSIBLE_USER_ID FROM dbo.LOAN_VW_LOAN_OP_OFFICER_CHANGE
	WHERE OP_ID = @op_id

	UPDATE dbo.LOANS SET RESPONSIBLE_USER_ID = @old_resp_user_id
	WHERE LOAN_ID = @loan_id

	SELECT @r = @@ROWCOUNT, @e = @@ERROR
	IF @e <> 0 BEGIN RAISERROR ('ÛÄÝÃÏÌÀ.',16,1) RETURN(1) END
	IF @r = 0 BEGIN RAISERROR('RECORD NOT FOUND',16,1) RETURN(1) END

	GOTO end_op
END

--DECLARE
--	@fine_amount money
--IF @op_type = dbo.loan_const_op_fine_accrue()
--BEGIN 
--	SELECT @fine_amount = AMOUNT FROM dbo.LOAN_OPS
--	WHERE OP_ID = @op_id
--	
-- 	UPDATE dbo.LOAN_DETAILS 
--	SET 
--		DEFERED_AMOUNT = DEFERED_AMOUNT - @fine_amount
--	WHERE LOAN_ID = @loan_id
--
--	SELECT @r = @@ROWCOUNT, @e = @@ERROR
--	IF @e <> 0 BEGIN RAISERROR ('ÛÄÝÃÏÌÀ.',16,1) RETURN(1) END
--	IF @r = 0 BEGIN RAISERROR('RECORD NOT FOUND',16,1) RETURN(1) END
--
--	GOTO end_op
--END
--
--IF @op_type = dbo.loan_const_op_fine_forgive()
--BEGIN 
--	SELECT @fine_amount = AMOUNT FROM dbo.LOAN_OPS
--	WHERE OP_ID = @op_id
--	
-- 	UPDATE dbo.LOAN_DETAILS 
--	SET 
--		DEFERED_AMOUNT = ISNULL(DEFERED_AMOUNT, $0.00) + @fine_amount
--	WHERE LOAN_ID = @loan_id
--
--	SELECT @r = @@ROWCOUNT, @e = @@ERROR
--	IF @e <> 0 BEGIN RAISERROR ('ÛÄÝÃÏÌÀ.',16,1) RETURN(1) END
--	IF @r = 0 BEGIN RAISERROR('RECORD NOT FOUND',16,1) RETURN(1) END
--
--	GOTO end_op
--END

IF @op_type = dbo.loan_const_op_writeoff()
BEGIN
	UPDATE dbo.LOAN_DETAIL_LATE
	SET LATE_PRINCIPAL = DL.LATE_PRINCIPAL,
		LATE_PERCENT = DL.LATE_PERCENT
	FROM dbo.LOAN_DETAIL_LATE L INNER JOIN
		dbo.LOAN_VW_OP_PAYMENT_DETAIL_LATE DL ON L.LATE_OP_ID = DL.LATE_OP_ID
	WHERE DL.OP_ID = @op_id

	UPDATE dbo.LOAN_DETAIL_OVERDUE
	SET OVERDUE_PRINCIPAL = DL.OVERDUE_PRINCIPAL,
		OVERDUE_PERCENT = DL.OVERDUE_PERCENT
	FROM dbo.LOAN_DETAIL_OVERDUE L INNER JOIN
		dbo.LOAN_VW_OP_PAYMENT_DETAIL_OVERDUE DL ON L.OVERDUE_OP_ID = DL.OVERDUE_OP_ID
	WHERE DL.OP_ID = @op_id
END


IF @op_type = dbo.loan_const_op_payment_writedoff()
BEGIN
	UPDATE dbo.LOANS
		SET [STATE] = dbo.loan_const_state_writedoff()
	WHERE LOAN_ID = @loan_id	
END


IF @op_type = dbo.loan_const_op_penalty_forgive()
BEGIN
	UPDATE dbo.LOANS
		SET [STATE] = (SELECT [STATE] FROM dbo.LOAN_VW_LOAN_OP_PENALTY_FORGIVE WHERE OP_ID = @op_id)
	WHERE LOAN_ID = @loan_id	
END

IF @op_type IN (dbo.loan_const_op_restructure_collateral(), dbo.loan_const_op_correct_collateral())
BEGIN
	EXEC @r = dbo.LOAN_SP_RESTORE_OP_LOAN_COLLATERALS_XML @op_id, @loan_id
	IF @r <> 0 BEGIN RAISERROR ('ÛÄÝÃÏÌÀ.',16,1) RETURN(1) END
END


IF @op_type = dbo.loan_const_op_guar_disburse()
BEGIN
	DELETE dbo.LOAN_DETAILS	WHERE LOAN_ID = @loan_id
	SELECT @r = @@ROWCOUNT, @e = @@ERROR
	IF @e <> 0 BEGIN RAISERROR ('ÛÄÝÃÏÌÀ.',16,1) RETURN(1) END
	IF @r = 0 BEGIN RAISERROR('RECORD NOT FOUND',16,1) RETURN(1) END

	GOTO end_op
END

IF @op_type = dbo.loan_const_op_guar_payment()
BEGIN
	UPDATE dbo.LOAN_DETAIL_OVERDUE
	SET 
		OVERDUE_PERCENT = DL.OVERDUE_PERCENT
	FROM dbo.LOAN_DETAIL_OVERDUE L INNER JOIN
		dbo.LOAN_VW_OP_PAYMENT_DETAIL_OVERDUE DL ON L.OVERDUE_OP_ID = DL.OVERDUE_OP_ID
	WHERE DL.OP_ID = @op_id

	SELECT @loan_state = [STATE] FROM dbo.LOAN_VW_GUARANTEE_OP_PAYMENT
	WHERE OP_ID = @op_id

	UPDATE dbo.LOANS 
	SET
		[STATE] = @loan_state
	WHERE LOAN_ID = @loan_id 

	SELECT @r = @@ROWCOUNT, @e = @@ERROR
	IF (@e <> 0) OR (@r = 0) BEGIN RAISERROR ('ÛÄÝÃÏÌÀ ÂÀÒÀÍÔÉÉÓ ÃÀ×ÀÒÅÉÓ ÏÐÄÒÀÝÉÉÓ ßÀÛËÉÓÀÓ !',16,1) RETURN(1) END

	GOTO end_op
END


end_op:

UPDATE dbo.LOAN_OPS
SET OP_STATE=0,AUTH_OWNER=NULL,DOC_REC_ID=NULL,NOTE_REC_ID=NULL,OP_LOAN_DETAILS=NULL
WHERE OP_ID=@op_id
SELECT @r = @@ROWCOUNT, @e = @@ERROR
IF @e <> 0 BEGIN RAISERROR ('ÛÄÝÃÏÌÀ ÏÐÄÒÀÝÉÉÓ ÌÏÞÉÄÁÉÓÀÓ',16,1) RETURN(1) END
IF @r = 0 BEGIN RAISERROR('RECORD NOT FOUND',16,1) RETURN(1) END

UPDATE dbo.LOANS SET ROW_VERSION = ROW_VERSION + 1
WHERE LOAN_ID = @loan_id
SELECT @r = @@ROWCOUNT, @e = @@ERROR
IF @e <> 0 BEGIN RAISERROR ('ÛÄÝÃÏÌÀ.',16,1) RETURN(1) END
IF @r = 0 BEGIN RAISERROR('RECORD NOT FOUND',16,1) RETURN(1) END


IF @note_rec_id IS NOT NULL
BEGIN 
	DELETE dbo.LOAN_NOTES WHERE REC_ID = @note_rec_id
	
	SELECT @r = @@ROWCOUNT, @e = @@ERROR
	IF @e <> 0 BEGIN RAISERROR ('ÛÄÝÃÏÌÀ.',16,1) RETURN(1) END
	IF @r = 0 BEGIN RAISERROR('RECORD NOT FOUND',16,1) RETURN(1) END
END

IF @op_type = dbo.loan_const_op_approval()
BEGIN 
	DELETE dbo.LOAN_ACCOUNT_BALANCE WHERE LOAN_ID = @loan_id
	
	SELECT @r = @@ROWCOUNT, @e = @@ERROR
	IF @e <> 0 BEGIN RAISERROR ('ÛÄÝÃÏÌÀ.',16,1) RETURN(1) END
	IF @r = 0 BEGIN RAISERROR('RECORD NOT FOUND',16,1) RETURN(1) END
END

RETURN (0)


GO
