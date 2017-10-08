SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[LOAN_SP_GEN_AGREE_EXEC_OP]
	@doc_rec_id int OUTPUT,
	@op_id int,
	@user_id int
AS
SET NOCOUNT ON

DECLARE @e int, @r int

DECLARE
	@credit_line_id int,
	@op_date smalldatetime,
	@op_type smallint,
	@op_state tinyint,
	@amount money,
	@op_note varchar(255),
	@owner int,
	@auth_owner int,
	@note_rec_id int,
	@op_ext_xml xml

SELECT 
	@credit_line_id = CREDIT_LINE_ID, @op_date = OP_DATE, @op_type = OP_TYPE, @op_state = OP_STATE, @amount = AMOUNT, @op_note = OP_NOTE,
	@owner = [OWNER], @auth_owner=AUTH_OWNER, @op_ext_xml = OP_EXT_XML
FROM dbo.LOAN_GEN_AGREE_OPS WHERE OP_ID = @op_id

SELECT @r = @@ROWCOUNT, @e = @@ERROR
IF @e <> 0 BEGIN RAISERROR ('ÛÄÝÃÏÌÀ.',16,1) RETURN(1) END
IF @r = 0 BEGIN RAISERROR('RECORD NOT FOUND',16,1) RETURN(1) END

IF @op_state = 0xFF BEGIN RAISERROR ('ÏÐÄÒÀÝÉÀ ÛÄÓÒÖËÄÁÖËÉÀ ÓáÅÀ ÌÏÌáÌÀÒÄÁËÉÓ ÌÉÄÒ',16,1) RETURN (1) END


IF @op_type IN (dbo.loan_const_gen_agree_op_restructure(), dbo.loan_const_gen_agree_op_correct())
BEGIN
	UPDATE A
	SET 
		ISO = V.ISO,
		AMOUNT = V.AMOUNT,
		PERIOD = V.PERIOD,
		RESTRUCTURED = RESTRUCTURED + CASE WHEN @op_type = dbo.loan_const_gen_agree_op_correct() THEN 0 ELSE 1 END
	FROM dbo.LOAN_CREDIT_LINES A
		INNER JOIN dbo.LOAN_VW_GEN_AGREE_OP_RESTRUCTURE V ON A.CREDIT_LINE_ID = V.CREDIT_LINE_ID
	WHERE V.OP_ID = @op_id

	SELECT @r = @@ROWCOUNT, @e = @@ERROR
	IF @e <> 0 BEGIN RAISERROR ('ÛÄÝÃÏÌÀ.',16,1) RETURN(1) END
	IF @r = 0 BEGIN RAISERROR('RECORD NOT FOUND',16,1) RETURN(1) END

	INSERT INTO dbo.LOAN_GEN_AGREE_NOTES(CREDIT_LINE_ID, [OWNER], OP_TYPE)
	VALUES(@credit_line_id, @user_id, @op_type)
	SELECT @r = @@ROWCOUNT, @e = @@ERROR
	IF @e <> 0 BEGIN RAISERROR ('ÛÄÝÃÏÌÀ.',16,1) RETURN(1) END
	IF @r = 0 BEGIN RAISERROR('RECORD NOT FOUND',16,1) RETURN(1) END

	SET @note_rec_id = @@IDENTITY

	GOTO end_op
END

IF @op_type = dbo.loan_const_gen_agree_op_close()
BEGIN
	DECLARE
		@collat_list varchar(1000),
		@close_collat bit
		
	SET @collat_list = ''
	
	SELECT @close_collat = CLOSE_COLLAT, @collat_list = ISNULL(COLLATERAL_LIST, '') 
	FROM dbo.LOAN_VW_GEN_AGREE_OP_CLOSE WHERE OP_ID = @op_id
		
	IF (@close_collat = 1) AND (@collat_list <> '')
	BEGIN
		SET @op_ext_xml =
			(SELECT C.COLLATERAL_ID, C.ISO, C.COLLATERAL_TYPE, C.AMOUNT, 0 AS IS_LINKED
			 FROM dbo.fn_split_list_int(@collat_list, ',') L
					INNER JOIN dbo.LOAN_COLLATERALS C (NOLOCK) ON L.ID = C.COLLATERAL_ID
 			 FOR XML RAW, ROOT)
 	END

	UPDATE dbo.LOAN_CREDIT_LINES
	SET 
		STATE = dbo.loan_credit_line_const_state_closed()
	WHERE CREDIT_LINE_ID = @credit_line_id

	SELECT @r = @@ROWCOUNT, @e = @@ERROR
	IF @e <> 0 BEGIN RAISERROR ('ÛÄÝÃÏÌÀ.',16,1) RETURN(1) END
	IF @r = 0 BEGIN RAISERROR('RECORD NOT FOUND',16,1) RETURN(1) END

	INSERT INTO dbo.LOAN_GEN_AGREE_NOTES(CREDIT_LINE_ID, [OWNER], OP_TYPE)
	VALUES(@credit_line_id, @user_id, @op_type)
	SELECT @r = @@ROWCOUNT, @e = @@ERROR
	IF @e <> 0 BEGIN RAISERROR ('ÛÄÝÃÏÌÀ.',16,1) RETURN(1) END
	IF @r = 0 BEGIN RAISERROR('RECORD NOT FOUND',16,1) RETURN(1) END

	SET @note_rec_id = @@IDENTITY

	GOTO end_op
END

IF @op_type IN (dbo.loan_const_gen_agree_op_restruct_collat(), dbo.loan_const_gen_agree_op_correct_collat())
BEGIN
	EXEC @r = dbo.LOAN_SP_RESTORE_OP_LOAN_COLLATERALS2 @op_id, @credit_line_id, @op_ext_xml OUT
	IF @r <> 0 BEGIN RAISERROR ('ÛÄÝÃÏÌÀ.',16,1) RETURN(1) END
END


end_op:

UPDATE dbo.LOAN_GEN_AGREE_OPS 
SET 
	OP_STATE = 0xFF, AUTH_OWNER=@user_id, NOTE_REC_ID = @note_rec_id, OP_EXT_XML = @op_ext_xml
WHERE OP_ID = @op_id
SELECT @r = @@ROWCOUNT, @e = @@ERROR
IF @e <> 0 BEGIN RAISERROR ('ÛÄÝÃÏÌÀ.',16,1) RETURN(1) END
IF @r = 0 BEGIN RAISERROR('RECORD NOT FOUND',16,1) RETURN(1) END

SET @doc_rec_id = NULL
	
EXEC @r = dbo.LOAN_SP_PROCESS_OP_ACCOUNTING2
	@doc_rec_id			= @doc_rec_id OUTPUT,
	@op_id				= @op_id,
	@user_id			= @user_id,
	@doc_date			= @op_date,
	@by_processing		= 0,
	@simulate			= 0
IF @r <> 0 OR @@ERROR <> 0 BEGIN RAISERROR ('ÛÄÝÃÏÌÀ ÏÐÄÒÀÝÉÉÓ ÁÖÙÀËÔÒÖËÉ ÀÓÀáÅÉÓÀÓ!',16,1) RETURN(1) END

RETURN 0
GO
