SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[LOAN_SP_CHECK_GEN_AGREE_OP_ACTION]
	@credit_line_id int,
	@row_version int,
	@op_type int
AS
SET NOCOUNT ON

DECLARE
	@result int,
	@msg varchar(8000)

SET @result = 0
SET @msg = ''


IF NOT EXISTS(SELECT * FROM dbo.LOAN_CREDIT_LINES WHERE CREDIT_LINE_ID = @credit_line_id AND ROW_VERSION = @row_version)
BEGIN
  SET @result = 1
  GOTO _check_end
END

IF EXISTS(SELECT * FROM dbo.LOAN_GEN_AGREE_OPS WHERE CREDIT_LINE_ID = @credit_line_id AND OP_TYPE = dbo.loan_const_gen_agree_op_close())
BEGIN
	SET @result = 2
	SET @msg = 'ÏÐÄÒÀÝÉÉÓ ÛÄÓÒÖËÄÁÀ ÛÄÖÞËÄÁÄËÉÀ, ÂÄÍ. áÄËÛÄÊÒÖËÄÁÀ ÃÀáÖÒÖËÉÀ!'
	IF @result <> 0 
		GOTO _check_end
END


IF (@op_type = dbo.loan_const_gen_agree_op_close()) AND EXISTS(SELECT * FROM dbo.LOANS WHERE CREDIT_LINE_ID = @credit_line_id AND [STATE] <> dbo.loan_const_state_closed())
BEGIN
	SET @result = 3
	SET @msg = 'ÏÐÄÒÀÝÉÉÓ ÛÄÓÒÖËÄÁÀ ÛÄÖÞËÄÁÄËÉÀ, ÂÄÍ. áÄËÛÄÊÒÖËÄÁÉÓ ØÅÄÛ ÀÒÓÄÁÏÁÓ ÌÏØÌÄÃÉ ÓÄÓáÉ!'
	IF @result <> 0 
		GOTO _check_end
END


_check_end:

	SELECT @result AS RESULT, @msg AS MSG

RETURN

GO
