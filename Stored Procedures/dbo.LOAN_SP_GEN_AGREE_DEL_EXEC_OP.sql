SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[LOAN_SP_GEN_AGREE_DEL_EXEC_OP]
  @op_id int,
  @user_id int
AS
SET NOCOUNT ON

DECLARE @e int, @r int

DECLARE
	@credit_line_id int, 
	@op_type smallint,
	@op_data_xml xml,
	@op_details_xml xml,
	@op_loan_details xml,
	@doc_rec_id int,
	@note_rec_id int,
	@loan_state tinyint,
	@op_date smalldatetime,
	@update_data bit,
	@update_schedule bit

    

SELECT  
	@credit_line_id=CREDIT_LINE_ID,@op_type=OP_TYPE, @op_date=OP_DATE, @doc_rec_id=DOC_REC_ID, @note_rec_id=NOTE_REC_ID, @op_data_xml=OP_DATA
FROM dbo.LOAN_GEN_AGREE_OPS WHERE OP_ID = @op_id

SELECT @r = @@ROWCOUNT, @e = @@ERROR
IF @e <> 0 BEGIN RAISERROR ('ÛÄÝÃÏÌÀ ÏÐÄÒÀÝÉÉÓ ÌÏÞÉÄÁÉÓÀÓ',16,1) RETURN(1) END
IF @r = 0 BEGIN RAISERROR('RECORD NOT FOUND',16,1) RETURN(1) END

IF @doc_rec_id IS NOT NULL
BEGIN
	EXEC @r = dbo.LOAN_SP_PROCESS_DELETE_OP_ACCOUNTING @doc_rec_id=@doc_rec_id, @op_id=@op_id, @user_id=@user_id
	IF @@ERROR<>0 OR @r<>0 RETURN(11)
END

IF @op_type IN (dbo.loan_const_gen_agree_op_restructure(), dbo.loan_const_gen_agree_op_correct())
BEGIN
	UPDATE A
	SET 
		ISO = V.OLD_ISO,
		AMOUNT = V.OLD_AMOUNT,
		PERIOD = V.OLD_PERIOD,
		RESTRUCTURED = RESTRUCTURED - CASE WHEN @op_type = dbo.loan_const_gen_agree_op_correct() THEN 0 ELSE 1 END
	FROM dbo.LOAN_CREDIT_LINES A
		INNER JOIN dbo.LOAN_VW_GEN_AGREE_OP_RESTRUCTURE V ON A.CREDIT_LINE_ID = V.CREDIT_LINE_ID
	WHERE V.OP_ID = @op_id

	SELECT @r = @@ROWCOUNT, @e = @@ERROR
	IF @e <> 0 BEGIN RAISERROR ('ÛÄÝÃÏÌÀ.',16,1) RETURN(1) END
	IF @r = 0 BEGIN RAISERROR('RECORD NOT FOUND',16,1) RETURN(1) END

	GOTO end_op
END


IF @op_type = dbo.loan_const_gen_agree_op_close()
BEGIN
	UPDATE A
		SET STATE = V.STATE
	FROM dbo.LOAN_CREDIT_LINES A
		INNER JOIN dbo.LOAN_VW_GEN_AGREE_OP_CLOSE V ON A.CREDIT_LINE_ID = V.CREDIT_LINE_ID 
	WHERE V.OP_ID = @op_id

	SELECT @r = @@ROWCOUNT, @e = @@ERROR
	IF @e <> 0 BEGIN RAISERROR ('ÛÄÝÃÏÌÀ.',16,1) RETURN(1) END
	IF @r = 0 BEGIN RAISERROR('RECORD NOT FOUND',16,1) RETURN(1) END

	GOTO end_op
END


IF @op_type IN (dbo.loan_const_gen_agree_op_restruct_collat(), dbo.loan_const_gen_agree_op_correct_collat())
BEGIN
	EXEC @r = dbo.LOAN_SP_RESTORE_OP_LOAN_COLLATERALS_XML2 @op_id, @credit_line_id
	IF @r <> 0 BEGIN RAISERROR ('ÛÄÝÃÏÌÀ.',16,1) RETURN(1) END
END


end_op:

UPDATE dbo.LOAN_GEN_AGREE_OPS
SET 
	OP_STATE = 0, AUTH_OWNER = NULL, NOTE_REC_ID = NULL
WHERE OP_ID = @op_id

SELECT @r = @@ROWCOUNT, @e = @@ERROR
IF @e <> 0 BEGIN RAISERROR ('ÛÄÝÃÏÌÀ ÏÐÄÒÀÝÉÉÓ ÌÏÞÉÄÁÉÓÀÓ',16,1) RETURN(1) END
IF @r = 0 BEGIN RAISERROR('RECORD NOT FOUND',16,1) RETURN(1) END

UPDATE dbo.LOAN_CREDIT_LINES SET ROW_VERSION = ROW_VERSION + 1
WHERE CREDIT_LINE_ID = @credit_line_id

SELECT @r = @@ROWCOUNT, @e = @@ERROR
IF @e <> 0 BEGIN RAISERROR ('ÛÄÝÃÏÌÀ.',16,1) RETURN(1) END
IF @r = 0 BEGIN RAISERROR('RECORD NOT FOUND',16,1) RETURN(1) END


IF @note_rec_id IS NOT NULL
BEGIN 
	DELETE dbo.LOAN_GEN_AGREE_NOTES WHERE REC_ID = @note_rec_id
	
	SELECT @r = @@ROWCOUNT, @e = @@ERROR
	IF @e <> 0 BEGIN RAISERROR ('ÛÄÝÃÏÌÀ.',16,1) RETURN(1) END
	IF @r = 0 BEGIN RAISERROR('RECORD NOT FOUND',16,1) RETURN(1) END
END

RETURN (0)

GO
